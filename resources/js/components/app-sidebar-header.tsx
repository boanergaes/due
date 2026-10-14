import { Breadcrumbs } from '@/components/breadcrumbs';
import { Button } from '@/components/ui/button';
import { SidebarTrigger } from '@/components/ui/sidebar';
import { useAiCopilot } from '@/contexts/ai-copilot-context';
import type { BreadcrumbItem as BreadcrumbItemType } from '@/types';
import { BotMessageSquare } from 'lucide-react';

export function AppSidebarHeader({
    breadcrumbs = [],
}: {
    breadcrumbs?: BreadcrumbItemType[];
}) {
    const { toggleCopilot, isOpen } = useAiCopilot();

    return (
        <header className="flex h-16 shrink-0 items-center justify-between gap-2 border-b border-sidebar-border/50 px-6 transition-[width,height] ease-linear group-has-data-[collapsible=icon]/sidebar-wrapper:h-12 md:px-4">
            <div className="flex items-center gap-2">
                <SidebarTrigger className="-ml-1" />
                <Breadcrumbs breadcrumbs={breadcrumbs} />
            </div>

            <div className="flex items-center gap-2">
                <Button
                    type="button"
                    variant={isOpen ? 'default' : 'outline'}
                    size="icon"
                    onClick={toggleCopilot}
                    className={`rounded-none size-8 cursor-pointer transition-colors ${
                        isOpen
                            ? 'bg-primary text-primary-foreground shadow-xs'
                            : 'border-primary/40 bg-primary/5 text-primary hover:bg-primary/10'
                    }`}
                    title="Toggle Due Copilot (Ctrl+J)"
                    aria-label="Toggle Due Copilot"
                >
                    <BotMessageSquare className="size-4" />
                </Button>
            </div>
        </header>
    );
}

