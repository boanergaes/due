<?php

namespace App\Http\Controllers;

use App\Models\Assignment;
use App\Models\Resource;
use App\Services\ResourceStorageService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Symfony\Component\HttpFoundation\StreamedResponse;

class ResourceController extends Controller
{
    public function __construct(
        protected ResourceStorageService $storageService
    ) {}

    /**
     * Upload and attach a new resource to a class or assignment.
     */
    public function store(Request $request): RedirectResponse
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

        // Enforce ownership: students can only attach resources to their own classes or assignments
        $resourceable = match ($validated['resourceable_type']) {
            'class' => $user->classes()->findOrFail($validated['resourceable_id']),
            'assignment' => $user->assignments()->findOrFail($validated['resourceable_id']),
        };

        $this->storageService->store(
            user: $user,
            resourceable: $resourceable,
            file: $request->file('file'),
            customTitle: $validated['title'] ?? null
        );

        return back()->with('success', 'Resource uploaded successfully.');
    }

    /**
     * Stream a resource inline (e.g. for in-browser PDF, image lightbox, or text view).
     */
    public function view(Resource $resource): StreamedResponse
    {
        Gate::authorize('view', $resource);

        return $this->storageService->stream($resource, inline: true);
    }

    /**
     * Download a resource file as an attachment.
     */
    public function download(Resource $resource): StreamedResponse
    {
        Gate::authorize('download', $resource);

        return $this->storageService->stream($resource, inline: false);
    }

    /**
     * Delete an uploaded resource and free up storage quota.
     */
    public function destroy(Resource $resource): RedirectResponse
    {
        Gate::authorize('delete', $resource);

        $this->storageService->delete($resource);

        return back()->with('success', 'Resource deleted successfully.');
    }
}
