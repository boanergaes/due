<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\View;
use Symfony\Component\HttpFoundation\Response;

class HandleAppearance
{
    /**
     * Handle an incoming request.
     *
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $appearance = $request->user()?->appearance ?? $request->cookie('appearance') ?? 'dark';

        View::share('appearance', $appearance);

        $response = $next($request);

        // Synchronize cookie with the authenticated user's persisted database preference
        if ($request->user() && $request->cookie('appearance') !== $request->user()->appearance) {
            $appearanceCookie = cookie()->forever('appearance', $request->user()->appearance);
            if (method_exists($response, 'cookie')) {
                $response->cookie($appearanceCookie);
            } else {
                $response->headers->setCookie($appearanceCookie);
            }
        }

        return $response;
    }
}
