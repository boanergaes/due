import { usePage } from '@inertiajs/react';

import AppLogoIcon from '@/components/app-logo-icon';

export default function AppLogo() {
    const { name } = usePage().props;

    return (
        <>
            <div className="flex aspect-square size-8 items-center justify-center rounded-none bg-primary text-primary-foreground">
                <AppLogoIcon className="size-5" />
            </div>
            <div className="ml-2 grid flex-1 text-left text-sm">
                <span className="truncate font-semibold tracking-tight">
                    {name ?? 'Due'}
                </span>
            </div>
        </>
    );
}
