<?php

namespace App\Services;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;

class GeminiApiService
{
    /**
     * Send a conversation with system instructions to Gemini API.
     *
     * @param  array<int, array{role: string, content: string}>  $history
     * @return array{reply: string, tokens_used: int, model: string}
     */
    public function chat(string $systemInstruction, array $history, string $userMessage): array
    {
        $apiKey = (string) config('services.gemini.api_key', '');
        $model = (string) config('services.gemini.model', 'gemini-1.5-flash');
        $baseUrl = rtrim((string) config('services.gemini.base_url', 'https://generativelanguage.googleapis.com/v1beta'), '/');

        // Build contents payload
        $contents = [];

        foreach ($history as $msg) {
            $role = ($msg['role'] === 'assistant' || $msg['role'] === 'model') ? 'model' : 'user';
            $contents[] = [
                'role' => $role,
                'parts' => [
                    ['text' => $msg['content']],
                ],
            ];
        }

        // Add latest user message
        $contents[] = [
            'role' => 'user',
            'parts' => [
                ['text' => $userMessage],
            ],
        ];

        $payload = [
            'system_instruction' => [
                'parts' => [
                    ['text' => $systemInstruction],
                ],
            ],
            'contents' => $contents,
            'generationConfig' => [
                'temperature' => 0.7,
                'maxOutputTokens' => 2048,
            ],
        ];

        // If no API key is configured (local dev sandbox or testing without live key)
        if (empty($apiKey) || $apiKey === 'mock' || $apiKey === 'test') {
            return $this->generateSimulatedResponse($userMessage, $model);
        }

        try {
            $endpoint = "{$baseUrl}/models/{$model}:generateContent?key={$apiKey}";
            $response = Http::timeout(35)->post($endpoint, $payload);

            if (! $response->successful()) {
                // If legacy 1.5-flash is configured and returns 404, automatically retry with 2.5-flash
                if ($response->status() === 404 && $model === 'gemini-1.5-flash') {
                    Log::info('Gemini model gemini-1.5-flash returned 404, automatically retrying with gemini-2.5-flash');
                    $model = 'gemini-2.5-flash';
                    $endpoint = "{$baseUrl}/models/{$model}:generateContent?key={$apiKey}";
                    $response = Http::timeout(35)->post($endpoint, $payload);
                }
            }

            if (! $response->successful()) {
                Log::warning('Gemini API Error Response', [
                    'status' => $response->status(),
                    'body' => $response->json(),
                ]);

                $errorMessage = $response->json('error.message') ?? 'Unknown error from Gemini service.';
                throw new RuntimeException("Gemini API Error ({$response->status()}): {$errorMessage}");
            }

            $data = $response->json();
            $reply = $data['candidates'][0]['content']['parts'][0]['text'] ?? '';
            $tokensUsed = (int) ($data['usageMetadata']['totalTokenCount'] ?? $this->estimateTokens($userMessage, $reply));

            return [
                'reply' => trim($reply),
                'tokens_used' => $tokensUsed,
                'model' => $model,
            ];
        } catch (ConnectionException $e) {
            Log::warning('Gemini API connection error (DNS resolution failure or offline host)', [
                'exception' => $e->getMessage(),
                'model' => $model,
            ]);

            return $this->generateOfflineFallbackResponse($userMessage, $model, $e->getMessage());
        } catch (\Throwable $e) {
            Log::error('Gemini API request failed', [
                'exception' => $e->getMessage(),
            ]);

            throw $e;
        }
    }

    /**
     * Generate an informative fallback response when network connection / DNS resolution fails.
     *
     * @return array{reply: string, tokens_used: int, model: string}
     */
    protected function generateOfflineFallbackResponse(string $userMessage, string $model, string $reason): array
    {
        $previewQuery = mb_substr($userMessage, 0, 100);

        $reply = "> ⚠️ **Network Notice:** Due Copilot could not reach Google Generative AI services (`{$reason}`). Operating in offline study mode based on your indexed coursework.\n\n"
            ."### Coursework Study Guidance\n\n"
            ."**Topic:** *\"{$previewQuery}\"*\n\n"
            ."1. **Clarify Objectives**: Begin by re-reading the prompt requirements and checking the deadline milestones.\n"
            ."2. **Analyze Context**: Cross-reference any edge cases mentioned in your lecture notes with the course syllabus or lab specifications.\n"
            ."3. **Structure Your Approach**: Break the implementation into small, testable increments before attempting the final deliverable.\n\n"
            .'*💡 Please check your local network connection, VPN, or DNS configuration (`generativelanguage.googleapis.com`) to restore live AI responses.*';

        return [
            'reply' => $reply,
            'tokens_used' => $this->estimateTokens($userMessage, $reply),
            'model' => "{$model}-offline",
        ];
    }

    /**
     * Generate an intelligent fallback simulated response when running without live Gemini credentials.
     *
     * @return array{reply: string, tokens_used: int, model: string}
     */
    protected function generateSimulatedResponse(string $userMessage, string $model): array
    {
        $previewQuery = mb_substr($userMessage, 0, 100);

        $reply = "### Due Copilot Academic Assistant\n\n"
            ."I have reviewed your assignment requirements, attached notes, and study resources.\n\n"
            ."**Guidance regarding:** *\"{$previewQuery}\"*\n\n"
            ."1. **Clarify Objectives**: Begin by re-reading the prompt requirements and checking the deadline milestones.\n"
            ."2. **Analyze Context**: Cross-reference any edge cases mentioned in your lecture notes with the course syllabus or lab specifications.\n"
            ."3. **Structure Your Approach**: Break the implementation into small, testable increments before attempting the final deliverable.\n\n"
            .'*💡 Tip: To connect with live Gemini 2.5 Flash in real-time, add your `GEMINI_API_KEY` to the `.env` file.*';

        $tokensUsed = $this->estimateTokens($userMessage, $reply);

        return [
            'reply' => $reply,
            'tokens_used' => $tokensUsed,
            'model' => "{$model}-simulated",
        ];
    }

    /**
     * Fallback estimation of token count (~4 characters per token).
     */
    protected function estimateTokens(string $prompt, string $completion): int
    {
        return (int) ceil((mb_strlen($prompt) + mb_strlen($completion)) / 4);
    }
}
