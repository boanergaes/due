import { useForm } from '@inertiajs/react';
import { useState } from 'react';
import {
    Download,
    Eye,
    FileArchive,
    FileCode,
    FileSpreadsheet,
    FileText,
    ImageIcon,
    Sparkles,
    Trash2,
} from 'lucide-react';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
} from '@/components/ui/dialog';
import type { StudyResource } from '@/types/models';

interface ResourceListProps {
    resources: StudyResource[];
    onViewResource: (resource: StudyResource) => void;
}

export function ResourceList({ resources, onViewResource }: ResourceListProps) {
    const [deletingResource, setDeletingResource] = useState<StudyResource | null>(null);
    const { delete: destroy, processing } = useForm();

    const handleDelete = () => {
        if (!deletingResource) return;
        destroy(`/resources/${deletingResource.id}`, {
            preserveScroll: true,
            onSuccess: () => setDeletingResource(null),
        });
    };

    const getFileIcon = (mimeType: string) => {
        if (mimeType.startsWith('image/')) {
            return <ImageIcon className="size-4 text-sky-400" />;
        }
        if (mimeType === 'application/pdf') {
            return <FileText className="size-4 text-primary" />;
        }
        if (
            mimeType.startsWith('text/') ||
            ['application/json', 'text/markdown', 'text/x-c', 'text/x-python'].includes(mimeType)
        ) {
            return <FileCode className="size-4 text-emerald-400" />;
        }
        if (mimeType.includes('zip') || mimeType.includes('tar') || mimeType.includes('archive')) {
            return <FileArchive className="size-4 text-purple-400" />;
        }
        if (mimeType.includes('csv') || mimeType.includes('sheet')) {
            return <FileSpreadsheet className="size-4 text-teal-400" />;
        }
        return <FileText className="size-4 text-muted-foreground" />;
    };

    if (resources.length === 0) {
        return (
            <div className="border border-border/60 bg-card/40 p-8 text-center rounded-none">
                <FileText className="size-8 mx-auto text-muted-foreground/60 mb-2" />
                <h4 className="text-sm font-semibold">No study resources attached</h4>
                <p className="text-xs text-muted-foreground mt-1 max-w-sm mx-auto">
                    Upload slide decks, notes, syllabus PDFs, or code to keep coursework organized in one place.
                </p>
            </div>
        );
    }

    return (
        <div className="space-y-2">
            <div className="grid grid-cols-1 gap-2">
                {resources.map((resource) => (
                    <div
                        key={resource.id}
                        className="group border border-border bg-card hover:border-zinc-500/80 p-3.5 rounded-none flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 transition-colors"
                    >
                        {/* File Details */}
                        <div className="flex items-start gap-3 min-w-0 flex-1">
                            <div className="size-9 rounded-none bg-muted/60 border border-border flex items-center justify-center shrink-0 mt-0.5 group-hover:border-zinc-400 transition-colors">
                                {getFileIcon(resource.mime_type)}
                            </div>

                            <div className="min-w-0 flex-1">
                                <div className="flex items-center gap-2 flex-wrap">
                                    <span className="text-sm font-semibold tracking-tight truncate">
                                        {resource.title}
                                    </span>

                                    {resource.extracted_text && (
                                        <Badge
                                            variant="outline"
                                            className="rounded-none border-primary/30 bg-primary/5 text-primary font-mono text-[9px] px-1.5 py-0 inline-flex items-center gap-1"
                                            title="Text extracted and indexed for Gemini AI tutor"
                                        >
                                            <Sparkles className="size-2.5 text-primary" />
                                            <span>AI Context Ready</span>
                                        </Badge>
                                    )}
                                </div>

                                <div className="text-xs text-muted-foreground font-mono truncate mt-0.5 flex items-center gap-2">
                                    <span className="truncate">{resource.file_name}</span>
                                    <span>•</span>
                                    <span>
                                        {resource.formatted_size ||
                                            `${Math.round(resource.file_size_bytes / 1024)} KB`}
                                    </span>
                                </div>
                            </div>
                        </div>

                        {/* Action Buttons */}
                        <div className="flex items-center gap-1.5 shrink-0 self-end sm:self-center">
                            <Button
                                type="button"
                                variant="outline"
                                size="sm"
                                onClick={() => onViewResource(resource)}
                                className="rounded-none h-8 px-2.5 text-xs border-border hover:bg-muted cursor-pointer inline-flex items-center gap-1.5"
                            >
                                <Eye className="size-3.5" />
                                <span className="hidden sm:inline">Preview</span>
                            </Button>

                            <Button
                                asChild
                                variant="outline"
                                size="sm"
                                className="rounded-none h-8 px-2 text-xs border-border hover:bg-muted"
                                title="Download File"
                            >
                                <a href={`/resources/${resource.id}/download`} download>
                                    <Download className="size-3.5" />
                                </a>
                            </Button>

                            <Button
                                type="button"
                                variant="ghost"
                                size="sm"
                                onClick={() => setDeletingResource(resource)}
                                className="rounded-none h-8 px-2 text-xs text-muted-foreground hover:text-destructive cursor-pointer"
                                title="Delete Resource"
                            >
                                <Trash2 className="size-3.5" />
                            </Button>
                        </div>
                    </div>
                ))}
            </div>

            {/* Delete Confirmation Modal */}
            <Dialog
                open={deletingResource !== null}
                onOpenChange={(open) => !open && setDeletingResource(null)}
            >
                <DialogContent className="rounded-none border-border bg-card sm:max-w-md">
                    <DialogHeader>
                        <DialogTitle className="text-base font-bold">
                            Delete Study Resource
                        </DialogTitle>
                        <DialogDescription className="text-xs text-muted-foreground">
                            Are you sure you want to remove &quot;{deletingResource?.title}&quot;? The file will be
                            permanently removed from your storage quota.
                        </DialogDescription>
                    </DialogHeader>

                    <DialogFooter className="gap-2 sm:gap-0">
                        <Button
                            type="button"
                            variant="outline"
                            size="sm"
                            onClick={() => setDeletingResource(null)}
                            className="rounded-none border-border text-xs"
                            disabled={processing}
                        >
                            Cancel
                        </Button>
                        <Button
                            type="button"
                            variant="destructive"
                            size="sm"
                            onClick={handleDelete}
                            className="rounded-none text-xs cursor-pointer"
                            disabled={processing}
                        >
                            {processing ? 'Deleting...' : 'Delete Permanently'}
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </div>
    );
}
