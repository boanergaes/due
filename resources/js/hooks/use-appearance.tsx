import { router } from '@inertiajs/react';
import { useSyncExternalStore } from 'react';

export type ResolvedAppearance = 'light' | 'dark';
export type Appearance = ResolvedAppearance | 'system';

export type UseAppearanceReturn = {
    readonly appearance: Appearance;
    readonly resolvedAppearance: ResolvedAppearance;
    readonly updateAppearance: (mode: Appearance) => void;
};

const listeners = new Set<() => void>();
let currentAppearance: Appearance = 'dark';

const prefersDark = (): boolean => {
    if (typeof window === 'undefined') {
        return true;
    }

    return window.matchMedia('(prefers-color-scheme: dark)').matches;
};

const setCookie = (name: string, value: string, days = 365): void => {
    if (typeof document === 'undefined') {
        return;
    }

    const maxAge = days * 24 * 60 * 60;
    document.cookie = `${name}=${value};path=/;max-age=${maxAge};SameSite=Lax`;
};

const getCookie = (name: string): string | null => {
    if (typeof document === 'undefined') {
        return null;
    }

    const value = `; ${document.cookie}`;
    const parts = value.split(`; ${name}=`);
    if (parts.length === 2) {
        return parts.pop()?.split(';').shift() ?? null;
    }

    return null;
};

const getInitialAppearance = (): Appearance => {
    if (typeof window === 'undefined') {
        return 'dark';
    }

    // Read cookie preference - NO localStorage used!
    const cookieVal = getCookie('appearance');
    if (cookieVal === 'light' || cookieVal === 'dark' || cookieVal === 'system') {
        return cookieVal;
    }

    // Fall back to server-rendered HTML class
    if (document.documentElement.classList.contains('dark')) {
        return 'dark';
    }

    return 'dark';
};

const isDarkMode = (appearance: Appearance): boolean => {
    return appearance === 'dark' || (appearance === 'system' && prefersDark());
};

const applyTheme = (appearance: Appearance): void => {
    if (typeof document === 'undefined') {
        return;
    }

    const isDark = isDarkMode(appearance);

    document.documentElement.classList.toggle('dark', isDark);
    document.documentElement.style.colorScheme = isDark ? 'dark' : 'light';
};

const subscribe = (callback: () => void) => {
    listeners.add(callback);

    return () => listeners.delete(callback);
};

const notify = (): void => listeners.forEach((listener) => listener());

const mediaQuery = (): MediaQueryList | null => {
    if (typeof window === 'undefined') {
        return null;
    }

    return window.matchMedia('(prefers-color-scheme: dark)');
};

const handleSystemThemeChange = (): void => applyTheme(currentAppearance);

export function initializeTheme(): void {
    if (typeof window === 'undefined') {
        return;
    }

    // Clean up any legacy localStorage entry
    try {
        localStorage.removeItem('appearance');
    } catch {
        // Ignore in restricted environments
    }

    currentAppearance = getInitialAppearance();
    applyTheme(currentAppearance);

    // Set up system theme change listener
    mediaQuery()?.addEventListener('change', handleSystemThemeChange);

    // Keep appearance synchronized when navigating between Inertia pages
    try {
        router.on('success', (event) => {
            const serverAppearance = (event.detail.page.props as { appearance?: Appearance })?.appearance;
            if (
                serverAppearance &&
                (serverAppearance === 'light' || serverAppearance === 'dark' || serverAppearance === 'system') &&
                serverAppearance !== currentAppearance
            ) {
                currentAppearance = serverAppearance;
                applyTheme(currentAppearance);
                notify();
            }
        });
    } catch {
        // Ignore outside Inertia environment
    }
}

export function useAppearance(): UseAppearanceReturn {
    const appearance: Appearance = useSyncExternalStore(
        subscribe,
        () => currentAppearance,
        () => 'dark',
    );

    const resolvedAppearance: ResolvedAppearance = isDarkMode(appearance)
        ? 'dark'
        : 'light';

    const updateAppearance = (mode: Appearance): void => {
        currentAppearance = mode;

        // Persist via cookie for SSR & server sessions (no localStorage)
        setCookie('appearance', mode);

        applyTheme(mode);
        notify();

        // Persist to user record in database if authenticated
        try {
            router.patch(
                '/settings/appearance',
                { appearance: mode },
                {
                    preserveScroll: true,
                    preserveState: true,
                },
            );
        } catch {
            // Silently fallback if router is not mounted yet
        }
    };

    return { appearance, resolvedAppearance, updateAppearance } as const;
}
