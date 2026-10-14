<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\AiConversation;
use App\Models\AiMessage;
use App\Services\AssignmentAiContextBuilder;
use App\Services\GeminiApiService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AiChatApiController extends Controller
{
    public function __construct(
        protected AssignmentAiContextBuilder $contextBuilder,
        protected GeminiApiService $geminiService
    ) {}

    /**
     * Get searchable courses and assignments for @ mentions autocomplete.
     */
    public function mentionables(Request $request): JsonResponse
    {
        $user = $request->user();

        $courses = $user->classes()
            ->select(['id', 'course_name', 'teacher_name', 'credit_hours'])
            ->withCount('assignments')
            ->orderBy('course_name')
            ->get()
            ->map(fn ($c) => [
                'id' => $c->id,
                'type' => 'course',
                'name' => $c->course_name,
                'detail' => $c->teacher_name ? "Instructor: {$c->teacher_name} • {$c->assignments_count} tasks" : "{$c->assignments_count} tasks",
            ]);

        $assignments = $user->assignments()
            ->with('courseClass:id,course_name')
            ->select(['id', 'class_id', 'title', 'status', 'deadline'])
            ->orderBy('deadline', 'asc')
            ->get()
            ->map(fn ($a) => [
                'id' => $a->id,
                'type' => 'assignment',
                'name' => $a->title,
                'detail' => ($a->courseClass?->course_name ?? 'Assignment').' • Due '.($a->deadline?->format('M d') ?? 'N/A'),
                'course_name' => $a->courseClass?->course_name,
            ]);

        return response()->json([
            'courses' => $courses,
            'assignments' => $assignments,
        ]);
    }

    /**
     * Get conversation history and context sources.
     */
    public function messages(Request $request): JsonResponse
    {
        $user = $request->user();
        $assignmentId = $request->integer('assignment_id') ?: null;

        $conversation = AiConversation::firstOrCreate([
            'user_id' => $user->id,
            'assignment_id' => $assignmentId,
        ], [
            'title' => $assignmentId ? "Study session for assignment #{$assignmentId}" : 'Global Workspace Copilot',
        ]);

        $messages = $conversation->messages()
            ->select(['id', 'role', 'content', 'tokens_used', 'created_at'])
            ->get();

        $assignment = $assignmentId ? $user->assignments()->find($assignmentId) : null;
        $context = $this->contextBuilder->buildForWorkspace($user, $assignment, []);

        return response()->json([
            'conversation_id' => $conversation->id,
            'context_sources' => $context['context_sources'],
            'total_tokens' => (int) $conversation->messages()->sum('tokens_used'),
            'messages' => $messages,
        ]);
    }

    /**
     * Send a query to Due Copilot with optional @mentions.
     */
    public function chat(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'message' => ['required', 'string', 'min:1', 'max:5000'],
            'assignment_id' => ['nullable', 'integer'],
            'mentions' => ['nullable', 'array'],
            'mentions.*.type' => ['required', 'string', 'in:course,class,assignment'],
            'mentions.*.id' => ['required', 'integer'],
        ]);

        $user = $request->user();
        $assignmentId = $validated['assignment_id'] ?? null;
        $assignment = $assignmentId ? $user->assignments()->find($assignmentId) : null;
        $mentions = $validated['mentions'] ?? [];

        $conversation = AiConversation::firstOrCreate([
            'user_id' => $user->id,
            'assignment_id' => $assignment?->id,
        ], [
            'title' => $assignment ? "Study session for {$assignment->title}" : 'Global Workspace Copilot',
        ]);

        // Build context with @mentions
        $context = $this->contextBuilder->buildForWorkspace($user, $assignment, $mentions);

        // Load recent history (last 12 messages)
        $previousMessages = $conversation->messages()
            ->orderBy('created_at', 'asc')
            ->take(12)
            ->get()
            ->map(fn (AiMessage $m) => [
                'role' => $m->role,
                'content' => $m->content,
            ])
            ->all();

        // Save user message
        $userMessage = $conversation->messages()->create([
            'role' => 'user',
            'content' => $validated['message'],
            'tokens_used' => (int) ceil(mb_strlen($validated['message']) / 4),
        ]);

        // Query Gemini API
        $result = $this->geminiService->chat(
            systemInstruction: $context['system_instruction'],
            history: $previousMessages,
            userMessage: $validated['message']
        );

        // Save assistant message
        $assistantMessage = $conversation->messages()->create([
            'role' => 'assistant',
            'content' => $result['reply'],
            'tokens_used' => $result['tokens_used'],
        ]);

        return response()->json([
            'reply' => $result['reply'],
            'tokens_used' => $result['tokens_used'],
            'model' => $result['model'],
            'context_sources' => $context['context_sources'],
            'user_message' => $userMessage,
            'assistant_message' => $assistantMessage,
        ]);
    }

    /**
     * Clear conversation history.
     */
    public function clear(Request $request): JsonResponse
    {
        $user = $request->user();
        $assignmentId = $request->integer('assignment_id') ?: null;

        $conversation = AiConversation::where('user_id', $user->id)
            ->where('assignment_id', $assignmentId)
            ->first();

        if ($conversation) {
            $conversation->messages()->delete();
        }

        return response()->json([
            'message' => 'Conversation history cleared.',
        ]);
    }
}
