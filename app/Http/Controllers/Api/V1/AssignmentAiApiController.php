<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\AiConversation;
use App\Models\AiMessage;
use App\Models\Assignment;
use App\Services\AssignmentAiContextBuilder;
use App\Services\GeminiApiService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AssignmentAiApiController extends Controller
{
    public function __construct(
        protected AssignmentAiContextBuilder $contextBuilder,
        protected GeminiApiService $geminiService
    ) {}

    /**
     * Fetch chat history and active context sources for an assignment.
     */
    public function messages(Request $request, Assignment $assignment): JsonResponse
    {
        $user = $request->user();
        $assignment = $user->assignments()->findOrFail($assignment->id);

        $conversation = AiConversation::firstOrCreate([
            'user_id' => $user->id,
            'assignment_id' => $assignment->id,
        ], [
            'title' => "Study session for {$assignment->title}",
        ]);

        $messages = $conversation->messages()
            ->select(['id', 'role', 'content', 'tokens_used', 'created_at'])
            ->get();

        $context = $this->contextBuilder->build($assignment);

        return response()->json([
            'conversation_id' => $conversation->id,
            'context_sources' => $context['context_sources'],
            'total_tokens' => (int) $conversation->messages()->sum('tokens_used'),
            'messages' => $messages,
        ]);
    }

    /**
     * Send a query to the Gemini study assistant.
     */
    public function chat(Request $request, Assignment $assignment): JsonResponse
    {
        $validated = $request->validate([
            'message' => ['required', 'string', 'min:1', 'max:5000'],
        ]);

        $user = $request->user();
        $assignment = $user->assignments()->findOrFail($assignment->id);

        $conversation = AiConversation::firstOrCreate([
            'user_id' => $user->id,
            'assignment_id' => $assignment->id,
        ], [
            'title' => "Study session for {$assignment->title}",
        ]);

        // 1. Build prompt context from assignment metadata, notes, and uploaded resource texts
        $context = $this->contextBuilder->build($assignment);

        // 2. Load previous conversation history (last 12 messages for continuity)
        $previousMessages = $conversation->messages()
            ->orderBy('created_at', 'asc')
            ->take(12)
            ->get()
            ->map(fn (AiMessage $m) => [
                'role' => $m->role,
                'content' => $m->content,
            ])
            ->all();

        // 3. Save student message
        $userMessage = $conversation->messages()->create([
            'role' => 'user',
            'content' => $validated['message'],
            'tokens_used' => (int) ceil(mb_strlen($validated['message']) / 4),
        ]);

        // 4. Query Gemini
        $result = $this->geminiService->chat(
            systemInstruction: $context['system_instruction'],
            history: $previousMessages,
            userMessage: $validated['message']
        );

        // 5. Save assistant reply
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
     * Clear AI conversation history for this assignment.
     */
    public function clear(Request $request, Assignment $assignment): JsonResponse
    {
        $user = $request->user();
        $assignment = $user->assignments()->findOrFail($assignment->id);

        $conversation = AiConversation::where('user_id', $user->id)
            ->where('assignment_id', $assignment->id)
            ->first();

        if ($conversation) {
            $conversation->messages()->delete();
        }

        return response()->json([
            'message' => 'Conversation history cleared.',
        ]);
    }
}
