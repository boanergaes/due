import { AiCopilotSidebar } from '@/components/ai/ai-copilot-sidebar';
import { AppContent } from '@/components/app-content';
import { AppShell } from '@/components/app-shell';
import { AppSidebar } from '@/components/app-sidebar';
import { AppSidebarHeader } from '@/components/app-sidebar-header';
import { AiCopilotProvider } from '@/contexts/ai-copilot-context';
import type { AppLayoutProps } from '@/types';

export default function AppSidebarLayout({
    children,
    breadcrumbs = [],
}: AppLayoutProps) {
    return (
        <AiCopilotProvider>
            <AppShell variant="sidebar">
                <AppSidebar />
                <AppContent variant="sidebar" className="min-w-0 overflow-x-clip">
                    <AppSidebarHeader breadcrumbs={breadcrumbs} />
                    {children}
                </AppContent>
                <AiCopilotSidebar />
            </AppShell>
        </AiCopilotProvider>
    );
}
