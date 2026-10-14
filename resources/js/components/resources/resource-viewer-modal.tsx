import { useState } from 'react';
import {
    Check,
    Copy,
    Download,
    ExternalLink,
    FileCode,
    FileText,
    ImageIcon,
    Maximize2,
    X,
} from 'lucide-react';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogHeader,
    DialogTitle,
} from '@/components/ui/dialog';
import type { StudyResource } from '@/types/models';

interface ResourceViewerModalProps {
    resource: StudyResource | null;
    open: boolean;
    onOpenChange: (open: boolean) => void;
}

export function ResourceViewerModal({
    resource,
    open,
    onOpenChange,
}: ResourceViewerModalProps) {
    const [copied, setCopied] = useState(false);
    const [isFullscreen, setIsFullscreen] = useState(false);

    if (!resource) return null;

    const isImage = resource.mime_type.startsWith('image/');
    const isPdf = resource.mime_type === 'application/pdf';
    const isText =
        resource.mime_type.startsWith('text/') ||
        ['application/json', 'text/markdown', 'text/x-c', 'text/x-python'].includes(
            resource.mime_type
        );

    const viewUrl = `/resources/${resource.id}/view`;
    const downloadUrl = `/resources/${resource.id}/download`;

    const handleCopyText = () => {
        if (!resource.extracted_text) return;
        navigator.clipboard.writeText(resource.extracted_text);
        setCopied(true);
        setTimeout(() => setCopied(false), 2000);
    };

    const getFormatBadge = () => {
        if (isPdf) {
            return (
                <Badge
                    variant="outline"
                    className="rounded-none border-primary/40 bg-primary/10 text-primary font-mono text-[10px]"
                >
                    PDF Document
                </Badge>
            );
        }
        if (isImage) {
            return (
                <Badge
                    variant="outline"
                    className="rounded-none border-sky-500/40 bg-sky-500/10 text-sky-400 font-mono text-[10px]"
                >
                    Image Asset
                </Badge>
            );
        }
        if (isText) {
            return (
                <Badge
                    variant="outline"
                    className="rounded-none border-emerald-500/40 bg-emerald-500/10 text-emerald-400 font-mono text-[10px]"
                >
                    Source / Text
                </Badge>
            );
        }
        return (
            <Badge
                variant="outline"
                className="rounded-none border-border bg-muted font-mono text-[10px]"
            >
                Binary Attachment
            </Badge>
        );
    };

    return (
        <Dialog open={open} onOpenChange={onOpenChange}>
            <DialogContent
                className={`rounded-none border-border bg-card p-0 gap-0 transition-all duration-200 overflow-hidden ${
                    isFullscreen
                        ? 'max-w-[96vw] h-[95vh] flex flex-col'
                        : 'max-w-4xl max-h-[90vh] flex flex-col'
                }`}
            >
                {/* Header */}
                <DialogHeader className="p-4 border-b border-border bg-muted/40 flex flex-row items-center justify-between space-y-0 shrink-0">
                    <div className="flex items-center gap-3 min-w-0 pr-4">
                        <div className="size-8 rounded-none bg-background border border-border flex items-center justify-center shrink-0">
                            {isPdf && <FileText className="size-4 text-primary" />}
                            {isImage && <ImageIcon className="size-4 text-sky-400" />}
                            {isText && <FileCode className="size-4 text-emerald-400" />}
                            {!isPdf && !isImage && !isText && (
                                <FileText className="size-4 text-muted-foreground" />
                            )}
                        </div>
                        <div className="min-w-0">
                            <div className="flex items-center gap-2">
                                <DialogTitle className="text-sm font-semibold truncate tracking-tight">
                                    {resource.title}
                                </DialogTitle>
                                {getFormatBadge()}
                            </div>
                            <DialogDescription className="text-xs text-muted-foreground font-mono truncate mt-0.5">
                                {resource.file_name} •{' '}
                                {resource.formatted_size ||
                                    `${Math.round(resource.file_size_bytes / 1024)} KB`}
                            </DialogDescription>
                        </div>
                    </div>

                    {/* Actions */}
                    <div className="flex items-center gap-1.5 shrink-0">
                        {resource.extracted_text && (
                            <Button
                                type="button"
                                variant="outline"
                                size="sm"
                                onClick={handleCopyText}
                                className="rounded-none h-7 px-2 text-xs border-border cursor-pointer hidden sm:inline-flex"
                                title="Copy Extracted Text"
                            >
                                {copied ? (
                                    <>
                                        <Check className="size-3.5 text-emerald-400 mr-1" />
                                        <span className="text-[11px] text-emerald-400">Copied</span>
                                    </>
                                ) : (
                                    <>
                                        <Copy className="size-3.5 mr-1" />
                                        <span className="text-[11px]">Copy Text</span>
                                    </>
                                )}
                            </Button>
                        )}

                        <Button
                            asChild
                            variant="outline"
                            size="sm"
                            className="rounded-none h-7 px-2 text-xs border-border"
                            title="Open in new window"
                        >
                            <a href={viewUrl} target="_blank" rel="noopener noreferrer">
                                <ExternalLink className="size-3.5" />
                            </a>
                        </Button>

                        <Button
                            asChild
                            variant="outline"
                            size="sm"
                            className="rounded-none h-7 px-2 text-xs border-border"
                            title="Download file"
                        >
                            <a href={downloadUrl} download>
                                <Download className="size-3.5" />
                            </a>
                        </Button>

                        <Button
                            type="button"
                            variant="outline"
                            size="sm"
                            onClick={() => setIsFullscreen(!isFullscreen)}
                            className="rounded-none h-7 px-2 text-xs border-border cursor-pointer hidden md:inline-flex"
                            title={isFullscreen ? 'Exit Fullscreen' : 'Fullscreen'}
                        >
                            <Maximize2 className="size-3.5" />
                        </Button>

                        <Button
                            type="button"
                            variant="ghost"
                            size="sm"
                            onClick={() => onOpenChange(false)}
                            className="rounded-none h-7 w-7 p-0 cursor-pointer"
                        >
                            <X className="size-4" />
                        </Button>
                    </div>
                </DialogHeader>

                {/* Body Content */}
                <div className="flex-1 overflow-auto bg-zinc-950 flex flex-col justify-center items-center min-h-[400px]">
                    {/* PDF Viewer */}
                    {isPdf && (
                        <iframe
                            src={viewUrl}
                            title={resource.title}
                            className="w-full h-full min-h-[500px] border-0 rounded-none bg-zinc-950"
                        />
                    )}

                    {/* Image Viewer */}
                    {isImage && (
                        <div className="p-4 w-full h-full flex items-center justify-center">
                            <img
                                src={viewUrl}
                                alt={resource.title}
                                className="max-w-full max-h-[75vh] object-contain rounded-none border border-border/40 shadow-lg"
                            />
                        </div>
                    )}

                    {/* Text Reader */}
                    {isText && (
                        <div className="w-full h-full p-4 overflow-auto">
                            {resource.extracted_text ? (
                                <pre className="font-mono text-xs text-zinc-300 whitespace-pre-wrap break-words leading-relaxed select-text p-4 bg-zinc-900 border border-border">
                                    {resource.extracted_text}
                                </pre>
                            ) : (
                                <iframe
                                    src={viewUrl}
                                    title={resource.title}
                                    className="w-full h-full min-h-[450px] border-0 rounded-none bg-zinc-900 font-mono text-xs"
                                />
                            )}
                        </div>
                    )}

                    {/* Fallback for binary / document files */}
                    {!isPdf && !isImage && !isText && (
                        <div className="text-center p-8 max-w-md space-y-4">
                            <div className="size-16 mx-auto rounded-none bg-muted border border-border flex items-center justify-center text-primary">
                                <FileText className="size-8" />
                            </div>
                            <div>
                                <h4 className="font-semibold text-base">{resource.title}</h4>
                                <p className="text-xs text-muted-foreground font-mono mt-1">
                                    This file type ({resource.mime_type}) does not support in-browser preview.
                                </p>
                            </div>
                            <Button
                                asChild
                                variant="default"
                                size="sm"
                                className="rounded-none cursor-pointer"
                            >
                                <a href={downloadUrl} download>
                                    <Download className="size-4 mr-2" />
                                    Download to View ({resource.formatted_size || 'Download'})
                                </a>
                            </Button>
                        </div>
                    )}
                </div>
            </DialogContent>
        </Dialog>
    );
}
