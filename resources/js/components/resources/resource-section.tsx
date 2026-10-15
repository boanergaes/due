import { usePage } from '@inertiajs/react';
import { useState } from 'react';
import { FolderGit2 } from 'lucide-react';
import { Badge } from '@/components/ui/badge';
import { ResourceList } from '@/components/resources/resource-list';
import { ResourceUploadZone } from '@/components/resources/resource-upload-zone';
import { ResourceViewerModal } from '@/components/resources/resource-viewer-modal';
import type { StudyResource } from '@/types/models';

interface ResourceSectionProps {
    resourceableType: 'class' | 'assignment';
    resourceableId: number;
    resources: StudyResource[];
    title?: string;
    description?: string;
}

export function ResourceSection({
    resourceableType,
    resourceableId,
    resources = [],
    title = 'Study Resources & Files',
    description = 'Attach lecture slides, readings, problem sets, and references.',
}: ResourceSectionProps) {
    const [viewerResource, setViewerResource] = useState<StudyResource | null>(null);
    const { subscription, auth } = usePage<{
        subscription?: {
            features: string[];
            tier: string;
            storage_used_bytes: number;
            storage_limit_bytes: number;
        } | null;
        auth: {
            user: {
                role?: string;
                subscription_tier?: string;
            } | null;
        };
    }>().props;

    const isAdmin = auth?.user?.role === 'admin' || auth?.user?.role === 'super_admin';
    const hasResourceFeature =
        isAdmin ||
        (subscription?.features?.includes('feature:resources') ??
            ['basic', 'premium'].includes(auth?.user?.subscription_tier || ''));

    const maxFileSizeMb = auth?.user?.subscription_tier === 'premium' ? 100 : 25;

    return (
        <div className="space-y-6">
            {/* Section Header */}
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-2 pb-3 border-b border-border">
                <div className="flex items-center gap-2">
                    <FolderGit2 className="size-4 text-primary" />
                    <h3 className="text-base font-bold tracking-tight">{title}</h3>
                    <Badge
                        variant="outline"
                        className="rounded-none border-border font-mono text-[11px] px-1.5 py-0"
                    >
                        {resources.length}
                    </Badge>
                </div>
                <p className="text-xs text-muted-foreground">{description}</p>
            </div>

            {/* Upload Zone */}
            <ResourceUploadZone
                resourceableType={resourceableType}
                resourceableId={resourceableId}
                canUpload={hasResourceFeature}
                maxFileSizeMb={maxFileSizeMb}
            />

            {/* Resource List */}
            <ResourceList
                resources={resources}
                onViewResource={(res) => setViewerResource(res)}
            />

            {/* In-Browser Viewer & Lightbox Modal */}
            <ResourceViewerModal
                resource={viewerResource}
                open={viewerResource !== null}
                onOpenChange={(open) => !open && setViewerResource(null)}
            />
        </div>
    );
}
