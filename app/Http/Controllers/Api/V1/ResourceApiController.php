<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Assignment;
use App\Models\CourseClass;
use App\Models\Resource;
use App\Services\ResourceStorageService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Symfony\Component\HttpFoundation\StreamedResponse;

class ResourceApiController extends Controller
{
    public function __construct(
        protected ResourceStorageService $storageService
    ) {}

    /**
     * List resources belonging to the authenticated student.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $query = $user->resources();

        if ($request->filled('resourceable_type') && $request->filled('resourceable_id')) {
            $type = match ($request->string('resourceable_type')->toString()) {
                'class' => CourseClass::class,
                'assignment' => Assignment::class,
                default => null,
            };

            if ($type) {
                $query->where('resourceable_type', $type)
                    ->where('resourceable_id', $request->integer('resourceable_id'));
            }
        }

        $resources = $query->get()->map(fn (Resource $resource) => $this->formatResource($resource));

        return response()->json([
            'resources' => $resources,
            'storage_used_bytes' => $user->storage_used_bytes,
            'storage_limit_bytes' => $user->storageLimitBytes(),
        ]);
    }

    /**
     * Upload and attach a new resource.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'resourceable_type' => ['required', 'string', 'in:class,assignment'],
            'resourceable_id' => ['required', 'integer'],
            'title' => ['nullable', 'string', 'max:255'],
            'file' => [
                'required',
                'file',
                'mimes:pdf,png,jpg,jpeg,webp,txt,md,json,csv,doc,docx,zip',
            ],
        ]);

        $user = $request->user();

        $resourceable = match ($validated['resourceable_type']) {
            'class' => $user->classes()->findOrFail($validated['resourceable_id']),
            'assignment' => $user->assignments()->findOrFail($validated['resourceable_id']),
        };

        $resource = $this->storageService->store(
            user: $user,
            resourceable: $resourceable,
            file: $request->file('file'),
            customTitle: $validated['title'] ?? null
        );

        return response()->json([
            'message' => 'Resource uploaded successfully.',
            'resource' => $this->formatResource($resource),
        ], 201);
    }

    /**
     * Show resource details and metadata.
     */
    public function show(Resource $resource): JsonResponse
    {
        Gate::authorize('view', $resource);

        return response()->json([
            'resource' => $this->formatResource($resource, includeExtractedText: true),
        ]);
    }

    /**
     * Stream a resource inline.
     */
    public function view(Resource $resource): StreamedResponse
    {
        Gate::authorize('view', $resource);

        return $this->storageService->stream($resource, inline: true);
    }

    /**
     * Download a resource file.
     */
    public function download(Resource $resource): StreamedResponse
    {
        Gate::authorize('download', $resource);

        return $this->storageService->stream($resource, inline: false);
    }

    /**
     * Delete an uploaded resource.
     */
    public function destroy(Resource $resource): JsonResponse
    {
        Gate::authorize('delete', $resource);

        $this->storageService->delete($resource);

        return response()->json([
            'message' => 'Resource deleted successfully.',
        ]);
    }

    /**
     * Format resource model into JSON representation.
     *
     * @return array<string, mixed>
     */
    protected function formatResource(Resource $resource, bool $includeExtractedText = false): array
    {
        return [
            'id' => $resource->id,
            'title' => $resource->title,
            'file_name' => $resource->file_name,
            'mime_type' => $resource->mime_type,
            'file_size_bytes' => $resource->file_size_bytes,
            'formatted_size' => $resource->formattedSize(),
            'is_image' => $resource->isImage(),
            'is_pdf' => $resource->isPdf(),
            'is_text' => $resource->isText(),
            'has_extracted_text' => ! empty($resource->extracted_text),
            'extracted_text' => $includeExtractedText ? $resource->extracted_text : null,
            'view_url' => route('resources.view', $resource),
            'download_url' => route('resources.download', $resource),
            'created_at' => $resource->created_at?->toISOString(),
        ];
    }
}
