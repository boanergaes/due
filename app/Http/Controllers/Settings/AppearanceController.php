<?php

namespace App\Http\Controllers\Settings;

use App\Http\Controllers\Controller;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Inertia\Inertia;
use Inertia\Response;

class AppearanceController extends Controller
{
    /**
     * Show the user appearance settings page.
     */
    public function edit(Request $request): Response
    {
        return Inertia::render('settings/appearance');
    }

    /**
     * Update and persist the user's appearance preference.
     */
    public function update(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'appearance' => ['required', 'string', Rule::in(['light', 'dark', 'system'])],
        ]);

        $request->user()->update([
            'appearance' => $validated['appearance'],
        ]);

        return back()->withCookie(cookie()->forever('appearance', $validated['appearance']));
    }
}
