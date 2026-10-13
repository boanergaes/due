<?php

namespace App\Models;

use Database\Factories\ResourceFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;
use Illuminate\Support\Carbon;

/**
 * @property int $id
 * @property int $user_id
 * @property string $resourceable_type
 * @property int $resourceable_id
 * @property string $title
 * @property string $file_name
 * @property string $file_path
 * @property string $mime_type
 * @property int $file_size_bytes
 * @property string|null $extracted_text
 * @property Carbon|null $created_at
 * @property Carbon|null $updated_at
 * @property-read User $user
 * @property-read Model $resourceable
 */
#[Fillable([
    'user_id',
    'resourceable_type',
    'resourceable_id',
    'title',
    'file_name',
    'file_path',
    'mime_type',
    'file_size_bytes',
    'extracted_text',
])]
class Resource extends Model
{
    /** @use HasFactory<ResourceFactory> */
    use HasFactory;

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'file_size_bytes' => 'integer',
        ];
    }

    /**
     * Get the owning resourceable model (CourseClass or Assignment).
     *
     * @return MorphTo<Model, $this>
     */
    public function resourceable(): MorphTo
    {
        return $this->morphTo();
    }

    /**
     * The student who uploaded this resource.
     *
     * @return BelongsTo<User, $this>
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Check if resource is an image.
     */
    public function isImage(): bool
    {
        return str_starts_with($this->mime_type, 'image/');
    }

    /**
     * Check if resource is a PDF.
     */
    public function isPdf(): bool
    {
        return $this->mime_type === 'application/pdf';
    }

    /**
     * Check if resource is a plain text or markdown file.
     */
    public function isText(): bool
    {
        return in_array($this->mime_type, [
            'text/plain',
            'text/markdown',
            'application/json',
            'text/x-c',
            'text/x-python',
            'text/x-java-source',
        ], true) || str_starts_with($this->mime_type, 'text/');
    }

    /**
     * Human-readable file size string.
     */
    public function formattedSize(): string
    {
        $bytes = $this->file_size_bytes;
        if ($bytes >= 1_073_741_824) {
            return number_format($bytes / 1_073_741_824, 2).' GB';
        }
        if ($bytes >= 1_048_576) {
            return number_format($bytes / 1_048_576, 1).' MB';
        }
        if ($bytes >= 1024) {
            return number_format($bytes / 1024, 0).' KB';
        }

        return $bytes.' B';
    }
}
