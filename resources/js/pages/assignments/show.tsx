import { Head, Link, router, useForm } from '@inertiajs/react';
import {
    ArrowLeft,
    Calendar,
    CheckCircle2,
    CheckSquare,
    Clock,
    FileText,
    GraduationCap,
    Pencil,
    Trash2,
} from 'lucide-react';
import { useState } from 'react';
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
import { dashboard } from '@/routes';
import * as assignmentsRoutes from '@/routes/assignments';
import * as classesRoutes from '@/routes/classes';
import type { Assignment } from '@/types';

interface PageProps {
    assignment: Assignment;
}

export default function AssignmentsShow({ assignment }: PageProps) {
    const [confirmDelete, setConfirmDelete] = useState(false);
    const { delete: destroy, processing } = useForm();

    const handleDelete = () => {
        destroy(assignmentsRoutes.destroy(assignment).url, {
            onSuccess: () => setConfirmDelete(false),
        });
    };

    const handleStatusQuickChange = (newStatus: Assignment['status']) => {
        router.patch(
            `/assignments/${assignment.id}/status`,
            { status: newStatus },
            { preserveScroll: true }
        );
    };

    const getStatusBadge = (status: Assignment['status']) => {
        switch (status) {
            case 'completed':
                return (
                    <Badge className="rounded-none bg-emerald-500/10 text-emerald-400 border border-emerald-500/30 font-mono text-xs">
                        Completed
                    </Badge>
                );
            case 'in_progress':
                return (
                    <Badge className="rounded-none bg-amber-500/10 text-amber-400 border border-amber-500/30 font-mono text-xs">
                        In Progress
                    </Badge>
                );
            default:
                return (
                    <Badge className="rounded-none bg-blue-500/10 text-blue-400 border border-blue-500/30 font-mono text-xs">
                        Pending
                    </Badge>
                );
        }
    };

    return (
        <>
            <Head title={assignment.title} />

            <div className="flex flex-1 flex-col gap-6 p-6 md:p-8 max-w-4xl">
                {/* Back link & Header */}
                <div className="flex flex-col justify-between gap-4 border-b border-border pb-6 sm:flex-row sm:items-center">
                    <div>
                        <Link
                            href={assignmentsRoutes.index()}
                            className="inline-flex items-center gap-1.5 text-xs font-mono text-muted-foreground hover:text-foreground transition-colors mb-2"
                        >
                            <ArrowLeft className="size-3.5" />
                            Back to Assignments
                        </Link>
                        <div className="flex items-center gap-2 text-xs font-mono text-muted-foreground uppercase tracking-widest">
                            <CheckSquare className="size-4 text-primary" />
                            Assignment Details
                        </div>
                        <h1 className="mt-1 text-2xl font-bold tracking-tight text-foreground sm:text-3xl">
                            {assignment.title}
                        </h1>
                    </div>

                    <div className="flex items-center gap-2">
                        <Button variant="outline" asChild className="rounded-none">
                            <Link href={assignmentsRoutes.edit(assignment)}>
                                <Pencil className="size-3.5 mr-1.5" />
                                Edit Task
                            </Link>
                        </Button>
                        <Button
                            variant="destructive"
                            onClick={() => setConfirmDelete(true)}
                            className="rounded-none"
                        >
                            <Trash2 className="size-3.5 mr-1.5" />
                            Delete
                        </Button>
                    </div>
                </div>

                {/* Key Overview Cards */}
                <div className="grid gap-4 sm:grid-cols-3">
                    <div className="border border-border bg-card p-5">
                        <div className="flex items-center gap-2 text-xs font-mono text-muted-foreground uppercase">
                            <GraduationCap className="size-3.5 text-primary" />
                            Academic Course
                        </div>
                        <div className="mt-2 text-base font-semibold text-foreground">
                            {assignment.course_class ? (
                                <Link
                                    href={classesRoutes.show(assignment.course_class)}
                                    className="hover:text-primary transition-colors hover:underline"
                                >
                                    {assignment.course_class.course_name}
                                </Link>
                            ) : (
                                '—'
                            )}
                        </div>
                        {assignment.course_class?.teacher_name && (
                            <div className="mt-1 text-xs text-muted-foreground">
                                Prof: {assignment.course_class.teacher_name}
                            </div>
                        )}
                    </div>

                    <div className="border border-border bg-card p-5">
                        <div className="flex items-center gap-2 text-xs font-mono text-muted-foreground uppercase">
                            <Calendar className="size-3.5 text-primary" />
                            Due Date & Time
                        </div>
                        <div className="mt-2 text-base font-semibold font-mono text-foreground">
                            {new Date(assignment.deadline).toLocaleString([], {
                                year: 'numeric',
                                month: 'short',
                                day: 'numeric',
                                hour: '2-digit',
                                minute: '2-digit',
                            })}
                        </div>
                        <div className="mt-1 text-xs text-muted-foreground">Local submission cutoff</div>
                    </div>

                    <div className="border border-border bg-card p-5">
                        <div className="flex items-center justify-between">
                            <div className="flex items-center gap-2 text-xs font-mono text-muted-foreground uppercase">
                                <Clock className="size-3.5 text-primary" />
                                Current Status
                            </div>
                            {getStatusBadge(assignment.status)}
                        </div>

                        {/* Quick Status Buttons */}
                        <div className="mt-3 flex items-center gap-1 border border-border bg-background p-1">
                            <button
                                type="button"
                                onClick={() => handleStatusQuickChange('pending')}
                                className={`flex-1 py-1 text-[11px] font-mono transition-colors ${
                                    assignment.status === 'pending'
                                        ? 'bg-primary text-primary-foreground font-semibold'
                                        : 'text-muted-foreground hover:text-foreground'
                                }`}
                            >
                                Pending
                            </button>
                            <button
                                type="button"
                                onClick={() => handleStatusQuickChange('in_progress')}
                                className={`flex-1 py-1 text-[11px] font-mono transition-colors ${
                                    assignment.status === 'in_progress'
                                        ? 'bg-primary text-primary-foreground font-semibold'
                                        : 'text-muted-foreground hover:text-foreground'
                                }`}
                            >
                                In Progress
                            </button>
                            <button
                                type="button"
                                onClick={() => handleStatusQuickChange('completed')}
                                className={`flex-1 py-1 text-[11px] font-mono transition-colors ${
                                    assignment.status === 'completed'
                                        ? 'bg-emerald-600 text-white font-semibold'
                                        : 'text-muted-foreground hover:text-foreground'
                                }`}
                            >
                                Done
                            </button>
                        </div>

                        {assignment.completed_at && (
                            <div className="mt-2 text-[11px] font-mono text-emerald-400">
                                Completed: {new Date(assignment.completed_at).toLocaleString()}
                            </div>
                        )}
                    </div>
                </div>

                {/* Instructions & Description */}
                <div className="border border-border bg-card p-6 md:p-8 space-y-4">
                    <div className="flex items-center gap-2 text-xs font-mono text-muted-foreground uppercase tracking-wider border-b border-border pb-3">
                        <FileText className="size-4 text-primary" />
                        Task Description & Requirements
                    </div>

                    {assignment.description ? (
                        <div className="prose dark:prose-invert max-w-none text-sm text-foreground whitespace-pre-wrap leading-relaxed">
                            {assignment.description}
                        </div>
                    ) : (
                        <p className="text-sm italic text-muted-foreground">
                            No additional description or rubric notes provided for this assignment.
                        </p>
                    )}
                </div>
            </div>

            {/* Delete Confirmation Modal */}
            <Dialog open={confirmDelete} onOpenChange={setConfirmDelete}>
                <DialogContent className="rounded-none sm:max-w-md border-border bg-card">
                    <DialogHeader>
                        <DialogTitle className="text-lg font-bold">Delete Assignment</DialogTitle>
                        <DialogDescription className="text-sm text-muted-foreground">
                            Are you sure you want to delete <span className="font-semibold text-foreground">{assignment.title}</span>? This action cannot be undone.
                        </DialogDescription>
                    </DialogHeader>
                    <DialogFooter className="gap-2 sm:justify-end">
                        <Button
                            type="button"
                            variant="outline"
                            onClick={() => setConfirmDelete(false)}
                            disabled={processing}
                            className="rounded-none"
                        >
                            Cancel
                        </Button>
                        <Button
                            type="button"
                            variant="destructive"
                            onClick={handleDelete}
                            disabled={processing}
                            className="rounded-none"
                        >
                            {processing ? 'Deleting...' : 'Confirm Delete'}
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </>
    );
}

AssignmentsShow.layout = {
    breadcrumbs: [
        {
            title: 'Dashboard',
            href: dashboard(),
        },
        {
            title: 'Assignments',
            href: assignmentsRoutes.index(),
        },
        {
            title: 'Task Details',
            href: '#',
        },
    ],
};
