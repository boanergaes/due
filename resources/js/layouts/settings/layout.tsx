import { Link } from '@inertiajs/react';
import type { PropsWithChildren } from 'react';
import Heading from '@/components/heading';
import { Button } from '@/components/ui/button';
import { useCurrentUrl } from '@/hooks/use-current-url';
import { cn, toUrl } from '@/lib/utils';
import { edit as editAppearance } from '@/routes/appearance';
import { edit } from '@/routes/profile';
import { edit as editSecurity } from '@/routes/security';
import { edit as editSessions } from '@/routes/sessions';
import type { NavItem } from '@/types';

const sidebarNavItems: NavItem[] = [
    {
        title: 'Profile',
        href: edit(),
        icon: null,
    },
    {
        title: 'Security',
        href: editSecurity(),
        icon: null,
    },
    {
        title: 'Appearance',
        href: editAppearance(),
        icon: null,
    },
    {
        title: 'Subscription & Plan',
        href: '/settings/subscription',
        icon: null,
    },
    {
        title: 'Sessions & Devices',
        href: editSessions(),
        icon: null,
    },
];

export default function SettingsLayout({ children }: PropsWithChildren) {
    const { isCurrentOrParentUrl } = useCurrentUrl();

    return (
        <div className="px-4 py-6">
            <Heading
                title="Settings"
                description="Manage your profile and account settings"
            />

            <div className="flex flex-col lg:flex-row lg:space-x-10">
                <aside className="w-full lg:w-56 shrink-0 mb-6 lg:mb-0">
                    {/* Responsive navigation: clean horizontal scroll on mobile/tablet, vertical sidebar on desktop */}
                    <div className="border-b border-border/60 pb-2 mb-2 lg:border-b-0 lg:pb-0 lg:mb-0">
                        <nav
                            className="flex flex-row lg:flex-col gap-1.5 overflow-x-auto no-scrollbar py-0.5 -mx-4 px-4 sm:mx-0 sm:px-0"
                            aria-label="Settings navigation"
                        >
                            {sidebarNavItems.map((item, index) => {
                                const active = isCurrentOrParentUrl(item.href);

                                return (
                                    <Button
                                        key={`${toUrl(item.href)}-${index}`}
                                        size="sm"
                                        variant="ghost"
                                        asChild
                                        className={cn(
                                            'rounded-none shrink-0 text-xs font-mono transition-colors justify-start h-9 px-3',
                                            active
                                                ? 'bg-muted text-foreground border border-border font-semibold shadow-xs'
                                                : 'text-muted-foreground hover:text-foreground hover:bg-muted/40 border border-transparent'
                                        )}
                                    >
                                        <Link href={item.href}>
                                            <span className="whitespace-nowrap">{item.title}</span>
                                        </Link>
                                    </Button>
                                );
                            })}
                        </nav>
                    </div>
                </aside>

                <div className="flex-1 min-w-0 max-w-full lg:max-w-2xl">
                    <section className="space-y-12">
                        {children}
                    </section>
                </div>
            </div>
        </div>
    );
}
