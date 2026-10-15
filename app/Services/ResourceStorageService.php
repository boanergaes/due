<?php

namespace App\Services;

use App\Enums\SubscriptionTier;
use App\Models\Resource;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Process;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\StreamedResponse;
use Symfony\Component\HttpKernel\Exception\HttpException;

class ResourceStorageService
{
    public const DISK = 'local';

    /**
     * Store an uploaded file, extract text if eligible, and create a Resource model.
     */
    public function store(User $user, Model $resourceable, UploadedFile $file, ?string $customTitle = null): Resource
    {
        // 1. Feature gate check
        if (! $user->hasFeature(SubscriptionTier::FEATURE_RESOURCES)) {
            throw new HttpException(403, 'Your current subscription plan does not allow uploading study resources.');
        }

        // 2. File size limit check based on tier
        $fileSize = $file->getSize();
        $maxSizeBytes = $user->isAdmin()
            ? PHP_INT_MAX
            : $user->subscription_tier->maxFileSizeMb() * 1024 * 1024;

        if ($fileSize > $maxSizeBytes) {
            $limitMb = $user->subscription_tier->maxFileSizeMb();
            throw new HttpException(422, "File exceeds your plan's maximum single file size limit of {$limitMb} MB.");
        }

        // 3. Storage quota check
        if (! $user->canUploadResource($fileSize)) {
            throw new HttpException(422, 'Insufficient storage quota. Uploading this file would exceed your storage limit.');
        }

        // 4. Save file to private user directory
        $originalName = $file->getClientOriginalName();
        $extension = $file->getClientOriginalExtension() ?: 'bin';
        $safeExtension = strtolower($extension);
        $fileName = Str::uuid()->toString().'.'.$safeExtension;
        $folderPath = "resources/{$user->id}";

        $storedPath = $file->storeAs($folderPath, $fileName, self::DISK);

        if (! $storedPath) {
            throw new HttpException(500, 'Failed to write file to secure storage disk.');
        }

        $mimeType = $file->getClientMimeType() ?: 'application/octet-stream';
        $fullDiskPath = Storage::disk(self::DISK)->path($storedPath);

        // 5. Extract text for PDF and plain text / code files
        $extractedText = $this->extractText($fullDiskPath, $mimeType, $safeExtension);

        // 6. Title
        $title = $customTitle ?: pathinfo($originalName, PATHINFO_FILENAME);

        // 7. Persist Resource record
        /** @var resource $resource */
        $resource = Resource::create([
            'user_id' => $user->id,
            'resourceable_type' => $resourceable->getMorphClass(),
            'resourceable_id' => $resourceable->getKey(),
            'title' => $title,
            'file_name' => $originalName,
            'file_path' => $storedPath,
            'mime_type' => $mimeType,
            'file_size_bytes' => $fileSize,
            'extracted_text' => $extractedText,
        ]);

        // 8. Update user storage used bytes
        $user->recalculateStorageUsed();

        return $resource;
    }

    /**
     * Delete a resource file and database record.
     */
    public function delete(Resource $resource): bool
    {
        if (Storage::disk(self::DISK)->exists($resource->file_path)) {
            Storage::disk(self::DISK)->delete($resource->file_path);
        }

        $user = $resource->user;
        $deleted = $resource->delete();

        if ($user) {
            $user->recalculateStorageUsed();
        }

        return (bool) $deleted;
    }

    /**
     * Stream a resource inline (e.g. for PDF viewer, image lightbox) or as download attachment.
     */
    public function stream(Resource $resource, bool $inline = true): StreamedResponse
    {
        if (! Storage::disk(self::DISK)->exists($resource->file_path)) {
            abort(404, 'File not found on storage disk.');
        }

        $disposition = $inline ? 'inline' : 'attachment';

        return Storage::disk(self::DISK)->response(
            $resource->file_path,
            $resource->file_name,
            [
                'Content-Type' => $resource->mime_type,
                'Content-Disposition' => "{$disposition}; filename=\"{$resource->file_name}\"",
                'Cache-Control' => 'private, no-cache, must-revalidate',
            ]
        );
    }

    /**
     * Extract plain text content from file if supported.
     */
    public function extractText(string $absolutePath, string $mimeType, string $extension): ?string
    {
        // 1. Text & Code files
        $textExtensions = ['txt', 'md', 'markdown', 'json', 'csv', 'py', 'c', 'cpp', 'h', 'java', 'js', 'ts', 'html', 'css', 'sql'];
        if (in_array($extension, $textExtensions, true) || str_starts_with($mimeType, 'text/')) {
            if (file_exists($absolutePath) && is_readable($absolutePath)) {
                $content = file_get_contents($absolutePath);
                if ($content !== false) {
                    return mb_substr($content, 0, 50000, 'UTF-8');
                }
            }
        }

        // 2. PDF extraction via pdftotext CLI
        if ($extension === 'pdf' || $mimeType === 'application/pdf') {
            if (file_exists('/usr/bin/pdftotext') && file_exists($absolutePath)) {
                try {
                    $result = Process::run(['pdftotext', '-layout', '-enc', 'UTF-8', $absolutePath, '-']);
                    if ($result->successful()) {
                        $output = trim($result->output());
                        if (! empty($output)) {
                            return mb_substr($output, 0, 50000, 'UTF-8');
                        }
                    }
                } catch (\Throwable $e) {
                    // Non-critical, fallback to null
                }
            }
        }

        return null;
    }
}
