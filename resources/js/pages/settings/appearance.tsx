import { Head } from '@inertiajs/react';
import AppearanceTabs from '@/components/appearance-tabs';
import Heading from '@/components/heading';
import { edit as editAppearance } from '@/routes/appearance';

export default function Appearance() {
    return (
        <>
            <Head title="Appearance settings" />

            <h1 className="sr-only">Appearance settings</h1>

            <div className="space-y-6">
                <Heading
                    variant="small"
                    title="Appearance & Theme"
                    description="Customize the visual theme of the Due workspace. Your selection persists across browser refreshes and sessions."
                />

                <div className="border border-border bg-card p-5 space-y-4">
                    <div>
                        <h3 className="text-sm font-semibold text-foreground font-mono uppercase tracking-wide">
                            Interface Color Mode
                        </h3>
                        <p className="mt-0.5 text-xs text-muted-foreground">
                            Due is designed with an architectural dark theme by default, featuring high-contrast borders and sharp edges.
                        </p>
                    </div>

                    <AppearanceTabs />
                </div>
            </div>
        </>
    );
}

Appearance.layout = {
    breadcrumbs: [
        {
            title: 'Appearance settings',
            href: editAppearance(),
        },
    ],
};
