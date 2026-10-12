import { Head, Link, router, useForm, usePage } from '@inertiajs/react';
import {
    Calendar,
    CheckCircle2,
    CheckSquare,
    Clock,
    Filter,
    GraduationCap,
    MoreHorizontal,
    Pencil,
    Plus,
    RotateCcw,
    Trash2,
} from 'lucide-react';
import { useState } from 'react';
import { Pagination } from '@/components/pagination';
import { Alert, AlertDescription } from '@/components/ui/alert';
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
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { dashboard } from '@/routes';
import * as assignmentsRoutes from '@/routes/assignments';
import * as classesRoutes from '@/routes/classes';
import type { Assignment, CourseClass, PaginatedData } from '@/types';

interface PageProps {
    [key: string]: unknown;
    assignments: PaginatedData<Assignment>;
    classes: Array<{ id: number; course_name: string }>;
    filters: {
        status: string | null;
        class_id: string | null;
    };
    flash?: {
        success?: string | null;
        error?: string | null;
    };
}

export default function AssignmentsIndex({
    assignments,
    classes,
    filters,
}: PageProps) {
    const { flash } = usePage<PageProps>().props;
    const [deletingAssignment, setDeletingAssignment] = useState<Assignment | null>(null);

    const { delete: destroy, processing: deleting } = useForm();

    const handleDelete = () => {
        if (!deletingAssignment) return;
        destroy(assignmentsRoutes.destroy(deletingAssignment).url, {
            preserveScroll: true,
            onSuccess: () => setDeletingAssignment(null),
        });
    };

    const handleFilterChange = (key: 'status' | 'class_id', value: string | null) => {
        const query: Record<string, string> = {};

        if (filters.status && key !== 'status') {
            query.status = filters.status;
        }
        if (filters.class_id && key !== 'class_id') {
            query.class_id = filters.class_id;
        }

        if (value) {
            query[key] = value;
        }

        router.get(assignmentsRoutes.index().url, query, {
            preserveState: true,
            preserveScroll: true,
        });
    };

    const handleStatusQuickChange = (assignment: Assignment, newStatus: Assignment['status']) => {
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
                    <span className="inline-flex items-center gap-1.5 border border-emerald-500/40 bg-emerald-500/10 px-2 py-0.5 font-mono text-xs text-emerald-400">
                        <CheckCircle2 className="size-3" />
                        Completed
                    </span>
                );
            case 'in_progress':
                return (
                    <span className="inline-flex items-center gap-1.5 border border-amber-500/40 bg-amber-500/10 px-2 py-0.5 font-mono text-xs text-amber-400">
                        <Clock className="size-3" />
                        In Progress
                    </span>
                );
            default:
                return (
                    <span className="inline-flex items-center gap-1.5 border border-blue-500/40 bg-blue-500/10 px-2 py-0.5 font-mono text-xs text-blue-400">
                        Pending
                    </span>
                );
        }
    };

    const hasActiveFilters = !!(filters.status || filters.class_id);

    return (
        <>
            <Head title="Assignments" />

            <div className="flex flex-1 flex-col gap-6 p-6 md:p-8">
                {/* Header */}
                <div className="flex flex-col justify-between gap-4 border-b border-border pb-6 sm:flex-row sm:items-center">
                    <div>
                        <div className="flex items-center gap-2 text-xs font-mono text-muted-foreground uppercase tracking-widest">
                            <CheckSquare className="size-4 text-primary" />
                            Academic Tasks
                        </div>
                        <h1 className="mt-1 text-2xl font-bold tracking-tight text-foreground sm:text-3xl">
                            Assignments
                        </h1>
                        <p className="mt-1 text-sm text-muted-foreground">
                            Track coursework, deadlines, requirements, and submission statuses.
                        </p>
                    </div>

                    <Button asChild className="rounded-none bg-primary text-primary-foreground hover:bg-primary/90 font-medium">
                        <Link href={assignmentsRoutes.create()}>
                            <Plus className="size-4 mr-1.5" />
                            New Assignment
                        </Link>
                    </Button>
                </div>

                {/* Notifications & Flash Messages */}
                {flash?.success && (
                    <Alert className="rounded-none border-emerald-500/50 bg-emerald-500/10 text-emerald-300">
                        <AlertDescription>{flash.success}</AlertDescription>
                    </Alert>
                )}

                {/* Filter Toolbar */}
                <div className="flex flex-wrap items-center justify-between gap-4 border border-border bg-card p-4">
                    <div className="flex flex-wrap items-center gap-2">
                        <span className="text-xs font-mono text-muted-foreground uppercase mr-1 flex items-center gap-1">
                            <Filter className="size-3" />
                            Filters:
                        </span>

                        {/* Status filters */}
                        <div className="inline-flex border border-border bg-background p-0.5">
                            {(['all', 'pending', 'in_progress', 'completed'] as const).map((s) => {
                                const isActive = s === 'all' ? !filters.status : filters.status === s;
                                const label = s === 'in_progress' ? 'In Progress' : s.charAt(0).toUpperCase() + s.slice(1);
                                return (
                                    <button
                                        key={s}
                                        type="button"
                                        onClick={() => handleFilterChange('status', s === 'all' ? null : s)}
                                        className={`px-2.5 py-1 text-xs font-mono transition-colors ${
                                            isActive
                                                ? 'bg-primary text-primary-foreground font-semibold'
                                                : 'text-muted-foreground hover:text-foreground hover:bg-muted/30'
                                        }`}
                                    >
                                        {label}
                                    </button>
                                );
                            })}
                        </div>

                        {/* Class Filter dropdown */}
                        <select
                            value={filters.class_id ?? ''}
                            onChange={(e) => handleFilterChange('class_id', e.target.value || null)}
                            className="h-8 border border-border bg-background px-2.5 text-xs font-mono text-foreground outline-none focus:border-primary"
                        >
                            <option value="">All Courses ({classes.length})</option>
                            {classes.map((c) => (
                                <option key={c.id} value={c.id}>
                                    {c.course_name}
                                </option>
                            ))}
                        </select>
                    </div>

                    {hasActiveFilters && (
                        <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => router.get(assignmentsRoutes.index().url)}
                            className="h-8 text-xs font-mono text-muted-foreground hover:text-foreground"
                        >
                            <RotateCcw className="size-3 mr-1" />
                            Reset Filters
                        </Button>
                    )}
                </div>

                {/* Table or Empty State */}
                {assignments.data.length === 0 ? (
                    <div className="flex flex-col items-center justify-center border border-dashed border-border bg-card/40 p-12 text-center">
                        <div className="flex size-12 items-center justify-center border border-border bg-muted/20 text-muted-foreground">
                            <CheckSquare className="size-6" />
                        </div>
                        <h3 className="mt-4 text-base font-semibold text-foreground">
                            {hasActiveFilters ? 'No assignments match the filters' : 'No assignments yet'}
                        </h3>
                        <p className="mt-1 max-w-sm text-sm text-muted-foreground">
                            {hasActiveFilters
                                ? 'Try adjusting your course or status criteria to see other tasks.'
                                : 'Add your upcoming coursework tasks to stay on top of deadlines.'}
                        </p>
                        {hasActiveFilters ? (
                            <Button
                                variant="outline"
                                onClick={() => router.get(assignmentsRoutes.index().url)}
                                className="mt-6 rounded-none font-mono text-xs"
                            >
                                Clear All Filters
                            </Button>
                        ) : (
                            <Button asChild className="mt-6 rounded-none">
                                <Link href={assignmentsRoutes.create()}>
                                    <Plus className="size-4 mr-1.5" />
                                    Create First Assignment
                                </Link>
                            </Button>
                        )}
                    </div>
                ) : (
                    <div className="space-y-4">
                        <div className="overflow-x-auto border border-border bg-card">
                            <table className="w-full text-left text-sm">
                                <thead className="border-b border-border bg-muted/40 font-mono text-xs uppercase tracking-wider text-muted-foreground">
                                    <tr>
                                        <th scope="col" className="px-5 py-3.5 font-semibold">Title</th>
                                        <th scope="col" className="px-5 py-3.5 font-semibold">Course</th>
                                        <th scope="col" className="px-5 py-3.5 font-semibold">Deadline</th>
                                        <th scope="col" className="px-5 py-3.5 font-semibold">Status</th>
                                        <th scope="col" className="px-5 py-3.5 text-right font-semibold">Actions</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-border">
                                    {assignments.data.map((assignment) => (
                                        <tr
                                            key={assignment.id}
                                            className="transition-colors hover:bg-muted/20"
                                        >
                                            <td className="px-5 py-4">
                                                <Link
                                                    href={assignmentsRoutes.show(assignment)}
                                                    className="font-medium text-foreground hover:text-primary transition-colors hover:underline block"
                                                >
                                                    {assignment.title}
                                                </Link>
                                                {assignment.description && (
                                                    <span className="mt-0.5 line-clamp-1 text-xs text-muted-foreground max-w-md">
                                                        {assignment.description}
                                                    </span>
                                                )}
                                            </td>

                                            <td className="px-5 py-4">
                                                {assignment.course_class ? (
                                                    <Link
                                                        href={classesRoutes.show(assignment.course_class)}
                                                        className="inline-flex items-center gap-1 text-xs font-mono text-muted-foreground hover:text-foreground transition-colors"
                                                    >
                                                        <GraduationCap className="size-3 text-primary" />
                                                        {assignment.course_class.course_name}
                                                    </Link>
                                                ) : (
                                                    <span className="text-muted-foreground/50 text-xs">—</span>
                                                )}
                                            </td>

                                            <td className="px-5 py-4 font-mono text-xs text-muted-foreground">
                                                <span className="flex items-center gap-1.5">
                                                    <Calendar className="size-3 text-primary" />
                                                    {new Date(assignment.deadline).toLocaleString([], {
                                                        year: 'numeric',
                                                        month: 'short',
                                                        day: 'numeric',
                                                        hour: '2-digit',
                                                        minute: '2-digit',
                                                    })}
                                                </span>
                                            </td>

                                            <td className="px-5 py-4">
                                                <DropdownMenu>
                                                    <DropdownMenuTrigger asChild>
                                                        <button
                                                            type="button"
                                                            className="cursor-pointer hover:opacity-80 transition-opacity outline-none"
                                                            title="Click to quick toggle status"
                                                        >
                                                            {getStatusBadge(assignment.status)}
                                                        </button>
                                                    </DropdownMenuTrigger>
                                                    <DropdownMenuContent className="rounded-none border-border bg-card">
                                                        <DropdownMenuItem
                                                            onClick={() => handleStatusQuickChange(assignment, 'pending')}
                                                            className="text-xs font-mono"
                                                        >
                                                            Mark as Pending
                                                        </DropdownMenuItem>
                                                        <DropdownMenuItem
                                                            onClick={() => handleStatusQuickChange(assignment, 'in_progress')}
                                                            className="text-xs font-mono"
                                                        >
                                                            Mark as In Progress
                                                        </DropdownMenuItem>
                                                        <DropdownMenuItem
                                                            onClick={() => handleStatusQuickChange(assignment, 'completed')}
                                                            className="text-xs font-mono text-emerald-400"
                                                        >
                                                            Mark as Completed
                                                        </DropdownMenuItem>
                                                    </DropdownMenuContent>
                                                </DropdownMenu>
                                            </td>

                                            <td className="px-5 py-4 text-right">
                                                <div className="flex items-center justify-end gap-1">
                                                    <Button
                                                        variant="ghost"
                                                        size="sm"
                                                        asChild
                                                        className="h-8 rounded-none text-muted-foreground hover:text-foreground text-xs"
                                                    >
                                                        <Link href={assignmentsRoutes.show(assignment)}>
                                                            View
                                                        </Link>
                                                    </Button>
                                                    <Button
                                                        variant="ghost"
                                                        size="sm"
                                                        asChild
                                                        className="h-8 rounded-none text-muted-foreground hover:text-foreground"
                                                    >
                                                        <Link href={assignmentsRoutes.edit(assignment)}>
                                                            <Pencil className="size-3.5" />
                                                            <span className="sr-only">Edit</span>
                                                        </Link>
                                                    </Button>
                                                    <Button
                                                        variant="ghost"
                                                        size="sm"
                                                        onClick={() => setDeletingAssignment(assignment)}
                                                        className="h-8 rounded-none text-destructive/80 hover:bg-destructive/10 hover:text-destructive"
                                                    >
                                                        <Trash2 className="size-3.5" />
                                                        <span className="sr-only">Delete</span>
                                                    </Button>
                                                </div>
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>

                        <Pagination links={assignments.links} />
                    </div>
                )}
            </div>

            {/* Delete Confirmation Modal */}
            <Dialog open={!!deletingAssignment} onOpenChange={(open) => !open && setDeletingAssignment(null)}>
                <DialogContent className="rounded-none sm:max-w-md border-border bg-card">
                    <DialogHeader>
                        <DialogTitle className="text-lg font-bold">Delete Assignment</DialogTitle>
                        <DialogDescription className="text-sm text-muted-foreground">
                            Are you sure you want to delete <span className="font-semibold text-foreground">{deletingAssignment?.title}</span>? This action cannot be undone.
                        </DialogDescription>
                    </DialogHeader>
                    <DialogFooter className="gap-2 sm:justify-end">
                        <Button
                            type="button"
                            variant="outline"
                            onClick={() => setDeletingAssignment(null)}
                            disabled={deleting}
                            className="rounded-none"
                        >
                            Cancel
                        </Button>
                        <Button
                            type="button"
                            variant="destructive"
                            onClick={handleDelete}
                            disabled={deleting}
                            className="rounded-none"
                        >
                            {deleting ? 'Deleting...' : 'Confirm Delete'}
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </>
    );
}

AssignmentsIndex.layout = {
    breadcrumbs: [
        {
            title: 'Dashboard',
            href: dashboard(),
        },
        {
            title: 'Assignments',
            href: assignmentsRoutes.index(),
        },
    ],
};
