<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureAdmin
{
    /**
     * Handle an incoming request.
     *
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        // 1. If guest, redirect to dedicated admin login
        if (! $user) {
            return redirect()->guest(route('admin.login'));
        }

        // 2. If authenticated as regular student, return 404 (Stealth mode)
        if (! $user->isAdmin()) {
            abort(404);
        }

        return $next($request);
    }
}
