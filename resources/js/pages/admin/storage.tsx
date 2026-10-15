import { Head, router, useForm } from '@inertiajs/react';
import {
    FileCheck,
    FileText,
    HardDrive,
    Trash2,
} from 'lucide-react';
import React, { useState } from 'react';
import { AdminLayout } from '@/layouts/admin/admin-layout';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
} from '@/components/ui/dialog';

interface StorageCategory {
    name: string;
    bytes: number;
    count: number;
    formatted: string;
}

interface LargestFile {
    id: number;
    title: string;
    file_name: string;
    file_size_bytes: number;
    formatted_size: string;
    mime_type: string;
    owner_name: string;
    owner_email: string;
    created_at?: string;
}

interface StoragePageProps {
    breakdown: {
        categories: StorageCategory[];
        largest_files: LargestFile[];
    };
    overview: {
        total_storage_bytes: number;
        total_storage_formatted: string;
        total_resources_count: number;
    };
}

export default function AdminStorage({ breakdown, overview }: StoragePageProps) {
    const [deletingFile, setDeletingFile] = useState<LargestFile | null>(null);
    const deleteForm = useForm({});

    const nominalCapBytes = 10 * 1024 * 1024 * 1024; // 10 GB nominal pool
    const poolPercentage = Math.min(
        100,
        Math.max(1, (overview.total_storage_bytes / nominalCapBytes) * 100)
    );

    const avgFileSize =
        overview.total_resources_count > 0
            ? Math.round(overview.total_storage_bytes / overview.total_resources_count)
            : 0;

    const formatBytes = (bytes: number): string => {
        if (bytes <= 0) return '0 B';
        const units = ['B', 'KB', 'MB', 'GB'];
        const base = Math.floor(Math.log(bytes) / Math.log(1024));
        return `${(bytes / Math.pow(1024, base)).toFixed(1)} ${units[base]}`;
    };

    const handleDeleteResource = (e: React.FormEvent) => {
        e.preventDefault();
        if (!deletingFile) return;

        deleteForm.delete(`/admin/resources/${deletingFile.id}`, {
            onSuccess: () => setDeletingFile(null),
        });
    };

    return (
        <AdminLayout title="Storage">
            <div className="space-y-6">
                {/* Header */}
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-border pb-5">
                    <div>
                        <h1 className="text-2xl font-bold tracking-tight text-foreground">
                            Storage Management
                        </h1>
                        <p className="mt-1 text-sm text-muted-foreground">
                            Monitor file storage usage, file categories, and uploaded assets.
                        </p>
                    </div>
                </div>

                {/* Storage Pool KPI */}
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                    <Card className="rounded-lg border-border bg-card shadow-xs">
                        <CardHeader className="flex flex-row items-center justify-between pb-2">
                            <CardTitle className="text-xs font-medium text-muted-foreground">
                                Total Storage Used
                            </CardTitle>
                            <HardDrive className="size-4 text-muted-foreground" />
                        </CardHeader>
                        <CardContent className="space-y-1">
                            <div className="text-2xl font-bold text-foreground">
                                {overview.total_storage_formatted}
                            </div>
                            <p className="text-xs text-muted-foreground">
                                {poolPercentage.toFixed(2)}% of 10 GB nominal allocation
                            </p>
                        </CardContent>
                    </Card>

                    <Card className="rounded-lg border-border bg-card shadow-xs">
                        <CardHeader className="flex flex-row items-center justify-between pb-2">
                            <CardTitle className="text-xs font-medium text-muted-foreground">
                                Total Files
                            </CardTitle>
                            <FileText className="size-4 text-muted-foreground" />
                        </CardHeader>
                        <CardContent className="space-y-1">
                            <div className="text-2xl font-bold text-foreground">
                                {overview.total_resources_count}
                            </div>
                            <p className="text-xs text-muted-foreground">
                                Attached to enrolled courses and assignments
                            </p>
                        </CardContent>
                    </Card>

                    <Card className="rounded-lg border-border bg-card shadow-xs">
                        <CardHeader className="flex flex-row items-center justify-between pb-2">
                            <CardTitle className="text-xs font-medium text-muted-foreground">
                                Average File Size
                            </CardTitle>
                            <FileCheck className="size-4 text-muted-foreground" />
                        </CardHeader>
                        <CardContent className="space-y-1">
                            <div className="text-2xl font-bold text-foreground">
                                {formatBytes(avgFileSize)}
                            </div>
                            <p className="text-xs text-muted-foreground">
                                Average size across student attachments
                            </p>
                        </CardContent>
                    </Card>
                </div>

                {/* Categories Breakdown */}
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                    {breakdown.categories.map((cat) => (
                        <Card key={cat.name} className="rounded-lg border-border bg-card shadow-xs">
                            <CardContent className="p-4 space-y-1.5">
                                <div className="text-xs font-medium text-muted-foreground">
                                    {cat.name}
                                </div>
                                <div className="text-xl font-bold text-foreground">
                                    {cat.formatted}
                                </div>
                                <div className="text-xs text-muted-foreground">
                                    {cat.count} files uploaded
                                </div>
                            </CardContent>
                        </Card>
                    ))}
                </div>

                {/* Largest Files Table */}
                <Card className="rounded-lg border-border bg-card shadow-xs">
                    <CardHeader className="border-b border-border/60 pb-3 flex flex-row items-center justify-between">
                        <CardTitle className="text-sm font-semibold flex items-center gap-2">
                            <HardDrive className="size-4 text-muted-foreground" />
                            Largest Platform Uploads
                        </CardTitle>
                    </CardHeader>
                    <CardContent className="p-0">
                        {breakdown.largest_files.length === 0 ? (
                            <div className="py-12 text-center text-sm text-muted-foreground">
                                No uploaded resources found.
                            </div>
                        ) : (
                            <div className="overflow-x-auto">
                                <table className="w-full text-left text-xs">
                                    <thead className="bg-muted/50 border-b border-border/80 text-[11px] text-muted-foreground uppercase tracking-wider">
                                        <tr>
                                            <th className="p-3.5">Asset Title & Name</th>
                                            <th className="p-3.5">Type</th>
                                            <th className="p-3.5">Size</th>
                                            <th className="p-3.5">Owner</th>
                                            <th className="p-3.5">Uploaded</th>
                                            <th className="p-3.5 text-right">Actions</th>
                                        </tr>
                                    </thead>
                                    <tbody className="divide-y divide-border/40">
                                        {breakdown.largest_files.map((file) => (
                                            <tr key={file.id} className="hover:bg-muted/30 transition-colors">
                                                {/* File Details */}
                                                <td className="p-3.5">
                                                    <div className="font-semibold text-foreground">
                                                        {file.title}
                                                    </div>
                                                    <div className="text-[11px] text-muted-foreground truncate max-w-[220px]">
                                                        {file.file_name}
                                                    </div>
                                                </td>

                                                {/* Type */}
                                                <td className="p-3.5">
                                                    <Badge
                                                        variant="outline"
                                                        className="border-border text-[10px] text-muted-foreground"
                                                    >
                                                        {file.mime_type}
                                                    </Badge>
                                                </td>

                                                {/* Size */}
                                                <td className="p-3.5 font-medium text-foreground">
                                                    {file.formatted_size}
                                                </td>

                                                {/* Owner */}
                                                <td className="p-3.5">
                                                    <div className="font-medium text-foreground">
                                                        {file.owner_name}
                                                    </div>
                                                    <div className="text-[11px] text-muted-foreground">
                                                        {file.owner_email}
                                                    </div>
                                                </td>

                                                {/* Date */}
                                                <td className="p-3.5 text-muted-foreground">
                                                    {file.created_at ? new Date(file.created_at).toLocaleDateString() : 'N/A'}
                                                </td>

                                                {/* Action */}
                                                <td className="p-3.5 text-right">
                                                    <Button
                                                        variant="outline"
                                                        size="sm"
                                                        onClick={() => setDeletingFile(file)}
                                                        className="h-7 px-2.5 text-xs text-muted-foreground hover:text-destructive hover:border-destructive/40"
                                                        title="Delete File"
                                                    >
                                                        <Trash2 className="size-3 mr-1" />
                                                        Delete
                                                    </Button>
                                                </td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        )}
                    </CardContent>
                </Card>
            </div>

            {/* Confirm Delete Dialog */}
            <Dialog open={!!deletingFile} onOpenChange={(open) => !open && setDeletingFile(null)}>
                <DialogContent className="sm:max-w-md">
                    <DialogHeader>
                        <DialogTitle className="text-base font-semibold flex items-center gap-2 text-destructive">
                            <Trash2 className="size-4" />
                            Delete Uploaded Resource
                        </DialogTitle>
                        <DialogDescription className="text-xs text-muted-foreground">
                            Are you sure you want to delete{' '}
                            <span className="text-foreground font-semibold">"{deletingFile?.title}"</span> ({deletingFile?.formatted_size})?
                            The file will be removed from storage and the user's quota will be restored.
                        </DialogDescription>
                    </DialogHeader>

                    <form onSubmit={handleDeleteResource}>
                        <DialogFooter className="gap-2 sm:justify-end pt-3">
                            <Button
                                type="button"
                                variant="outline"
                                onClick={() => setDeletingFile(null)}
                            >
                                Cancel
                            </Button>
                            <Button
                                type="submit"
                                variant="destructive"
                                disabled={deleteForm.processing}
                            >
                                {deleteForm.processing ? 'Deleting...' : 'Delete File'}
                            </Button>
                        </DialogFooter>
                    </form>
                </DialogContent>
            </Dialog>
        </AdminLayout>
    );
}
