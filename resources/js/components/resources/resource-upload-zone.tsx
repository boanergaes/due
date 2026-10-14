import { Link, useForm } from '@inertiajs/react';
import { useRef, useState } from 'react';
import {
    ArrowRight,
    FileUp,
    Lock,
    Upload,
    X,
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';

interface ResourceUploadZoneProps {
    resourceableType: 'class' | 'assignment';
    resourceableId: number;
    canUpload: boolean;
    maxFileSizeMb?: number;
}

export function ResourceUploadZone({
    resourceableType,
    resourceableId,
    canUpload,
    maxFileSizeMb = 25,
}: ResourceUploadZoneProps) {
    const [isDragging, setIsDragging] = useState(false);
    const [selectedFile, setSelectedFile] = useState<File | null>(null);
    const [showForm, setShowForm] = useState(false);
    const fileInputRef = useRef<HTMLInputElement>(null);

    const form = useForm({
        resourceable_type: resourceableType,
        resourceable_id: resourceableId,
        title: '',
        file: null as File | null,
    });

    const handleFileSelect = (file: File) => {
        setSelectedFile(file);
        form.setData((data) => ({
            ...data,
            file,
            title: data.title || file.name.replace(/\.[^/.]+$/, ''),
        }));
        setShowForm(true);
    };

    const handleDrop = (e: React.DragEvent) => {
        e.preventDefault();
        setIsDragging(false);

        if (!canUpload) return;

        if (e.dataTransfer.files && e.dataTransfer.files[0]) {
            handleFileSelect(e.dataTransfer.files[0]);
        }
    };

    const handleDragOver = (e: React.DragEvent) => {
        e.preventDefault();
        if (canUpload) setIsDragging(true);
    };

    const handleDragLeave = () => {
        setIsDragging(false);
    };

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        form.post('/resources/upload', {
            forceFormData: true,
            preserveScroll: true,
            onSuccess: () => {
                form.reset();
                setSelectedFile(null);
                setShowForm(false);
                if (fileInputRef.current) fileInputRef.current.value = '';
            },
        });
    };

    const handleCancel = () => {
        form.reset();
        setSelectedFile(null);
        setShowForm(false);
        if (fileInputRef.current) fileInputRef.current.value = '';
    };

    // If student cannot upload (Free plan gate)
    if (!canUpload) {
        return (
            <div className="border border-border/70 bg-card p-6 rounded-none relative overflow-hidden">
                <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                    <div className="flex items-start gap-3">
                        <div className="size-10 rounded-none bg-muted border border-border flex items-center justify-center text-muted-foreground shrink-0 mt-0.5">
                            <Lock className="size-5 text-amber-400" />
                        </div>
                        <div className="space-y-1">
                            <div className="flex items-center gap-2">
                                <h4 className="text-sm font-semibold tracking-tight">
                                    Study Resources Feature Locked
                                </h4>
                                <span className="text-[10px] font-mono uppercase px-1.5 py-0.5 bg-amber-400/10 text-amber-400 border border-amber-400/30">
                                    Scholar / Genius Tier
                                </span>
                            </div>
                            <p className="text-xs text-muted-foreground max-w-xl">
                                Upload class notes, syllabi, PDF slide decks, diagrams, and code snippets.
                                Resources are automatically indexed by Gemini AI to provide context-aware help on your assignments.
                            </p>
                        </div>
                    </div>

                    <Button
                        asChild
                        variant="default"
                        size="sm"
                        className="rounded-none shrink-0 cursor-pointer"
                    >
                        <Link href="/pricing">
                            <span>Upgrade to Unlock</span>
                            <ArrowRight className="size-3.5 ml-1.5" />
                        </Link>
                    </Button>
                </div>
            </div>
        );
    }

    return (
        <div className="space-y-4">
            {!showForm ? (
                /* Dropzone Area */
                <div
                    onDragOver={handleDragOver}
                    onDragLeave={handleDragLeave}
                    onDrop={handleDrop}
                    onClick={() => fileInputRef.current?.click()}
                    className={`border-2 border-dashed rounded-none p-6 text-center cursor-pointer transition-colors ${
                        isDragging
                            ? 'border-primary bg-primary/5'
                            : 'border-border hover:border-zinc-500 bg-card/60 hover:bg-card'
                    }`}
                >
                    <input
                        ref={fileInputRef}
                        type="file"
                        className="hidden"
                        accept=".pdf,.png,.jpg,.jpeg,.webp,.txt,.md,.json,.csv,.doc,.docx,.zip"
                        onChange={(e) => {
                            if (e.target.files && e.target.files[0]) {
                                handleFileSelect(e.target.files[0]);
                            }
                        }}
                    />

                    <div className="flex flex-col items-center justify-center space-y-2">
                        <div className="size-10 rounded-none bg-muted border border-border flex items-center justify-center text-primary shadow-xs">
                            <FileUp className="size-5" />
                        </div>
                        <div>
                            <p className="text-sm font-semibold">
                                Drop study resource here or <span className="text-primary underline underline-offset-2">browse files</span>
                            </p>
                            <p className="text-xs text-muted-foreground font-mono mt-1">
                                PDF, Images (PNG, JPG, WebP), Code, Text, Documents (up to {maxFileSizeMb} MB)
                            </p>
                        </div>
                    </div>
                </div>
            ) : (
                /* Upload Confirmation Form */
                <form
                    onSubmit={handleSubmit}
                    className="border border-border bg-card p-4 rounded-none space-y-4"
                >
                    <div className="flex items-center justify-between pb-3 border-b border-border">
                        <div className="flex items-center gap-2">
                            <Upload className="size-4 text-primary" />
                            <span className="text-xs font-mono uppercase tracking-wider font-semibold">
                                Confirm Resource Upload
                            </span>
                        </div>
                        <Button
                            type="button"
                            variant="ghost"
                            size="sm"
                            onClick={handleCancel}
                            className="rounded-none h-6 w-6 p-0 text-muted-foreground hover:text-foreground cursor-pointer"
                        >
                            <X className="size-3.5" />
                        </Button>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div className="space-y-1.5">
                            <Label htmlFor="resource_title" className="text-xs">
                                Title / Label
                            </Label>
                            <Input
                                id="resource_title"
                                type="text"
                                value={form.data.title}
                                onChange={(e) => form.setData('title', e.target.value)}
                                placeholder="e.g. Chapter 4 Lecture Slides"
                                className="rounded-none text-xs"
                                required
                            />
                            {form.errors.title && (
                                <p className="text-xs text-destructive">{form.errors.title}</p>
                            )}
                        </div>

                        <div className="space-y-1.5">
                            <Label className="text-xs">Selected File</Label>
                            <div className="h-9 px-3 border border-border bg-muted/30 flex items-center justify-between text-xs font-mono text-muted-foreground">
                                <span className="truncate max-w-[200px]">
                                    {selectedFile?.name}
                                </span>
                                <span>
                                    {selectedFile && Math.round(selectedFile.size / 1024) > 1024
                                        ? `${(selectedFile.size / (1024 * 1024)).toFixed(1)} MB`
                                        : `${Math.round((selectedFile?.size || 0) / 1024)} KB`}
                                </span>
                            </div>
                            {form.errors.file && (
                                <p className="text-xs text-destructive">{form.errors.file}</p>
                            )}
                        </div>
                    </div>

                    {form.progress && (
                        <div className="w-full bg-muted h-1.5 rounded-none overflow-hidden">
                            <div
                                className="bg-primary h-full transition-all duration-150"
                                style={{ width: `${form.progress.percentage}%` }}
                            />
                        </div>
                    )}

                    <div className="flex items-center justify-end gap-2 pt-2">
                        <Button
                            type="button"
                            variant="outline"
                            size="sm"
                            onClick={handleCancel}
                            className="rounded-none border-border cursor-pointer text-xs"
                            disabled={form.processing}
                        >
                            Cancel
                        </Button>
                        <Button
                            type="submit"
                            size="sm"
                            className="rounded-none cursor-pointer text-xs"
                            disabled={form.processing}
                        >
                            {form.processing ? 'Uploading & Indexing...' : 'Upload Resource'}
                        </Button>
                    </div>
                </form>
            )}
        </div>
    );
}
