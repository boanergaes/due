import { Head, Link, router, useForm, usePage } from '@inertiajs/react';
import {
    AlertCircle,
    ArrowLeft,
    Calendar,
    CheckCircle2,
    CheckSquare,
    Clock,
    FileText,
    GraduationCap,
    MessageSquare,
    Pencil,
    Plus,
    Trash2,
} from 'lucide-react';
import { useState } from 'react';
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
import { ResourceSection } from '@/components/resources/resource-section';
import { UrgencyBadge } from '@/components/urgency-badge';
import { dashboard } from '@/routes';
import * as assignmentsRoutes from '@/routes/assignments';
import * as classesRoutes from '@/routes/classes';
import type { Assignment, AssignmentNote } from '@/types';

interface PageProps {
    [key: string]: unknown;
    assignment: Assignment;
    flash?: {
        success?: string | null;
        error?: string | null;
    };
    errors?: Record<string, string>;
}

export default function AssignmentsShow({ assignment }: PageProps) {
    const { flash, errors: pageErrors } = usePage<PageProps>().props;

    // Delete assignment dialog state
    const [confirmDelete, setConfirmDelete] = useState(false);
    const { delete: destroyAssignment, processing: deletingAssignment } = useForm();

    // Notes state
    const [editingNote, setEditingNote] = useState<AssignmentNote | null>(null);
    const [deletingNote, setDeletingNote] = useState<AssignmentNote | null>(null);

    // Add note form
    const addNoteForm = useForm({
        content: '',
    });

    // Edit note form
    const editNoteForm = useForm({
        content: '',
    });

    const handleDeleteAssignment = () => {
        destroyAssignment(assignmentsRoutes.destroy(assignment).url, {
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

    const handleAddNote = (e: React.FormEvent) => {
        e.preventDefault();
        addNoteForm.post(`/assignments/${assignment.id}/notes`, {
            preserveScroll: true,
            onSuccess: () => addNoteForm.reset('content'),
        });
    };

    const handleStartEditNote = (note: AssignmentNote) => {
        setEditingNote(note);
        editNoteForm.setData('content', note.content);
    };

    const handleUpdateNote = (e: React.FormEvent) => {
        e.preventDefault();
        if (!editingNote) return;

        editNoteForm.put(`/assignments/${assignment.id}/notes/${editingNote.id}`, {
            preserveScroll: true,
            onSuccess: () => setEditingNote(null),
        });
    };

    const handleDeleteNote = () => {
        if (!deletingNote) return;

        router.delete(`/assignments/${assignment.id}/notes/${deletingNote.id}`, {
            preserveScroll: true,
            onSuccess: () => setDeletingNote(null),
        });
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

    const notes = assignment.notes ?? [];

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

                {/* Notifications & Flash Messages */}
                {flash?.success && (
                    <Alert className="rounded-none border-emerald-500/50 bg-emerald-500/10 text-emerald-300">
                        <AlertDescription>{flash.success}</AlertDescription>
                    </Alert>
                )}

                {/* Urgency Highlight Banner (Overdue Warning) */}
                {assignment.urgency?.is_overdue && (
                    <div className="border border-red-500/50 bg-red-500/10 p-4 text-red-400">
                        <div className="flex items-center gap-2 font-mono text-xs font-semibold uppercase tracking-wider">
                            <AlertCircle className="size-4 animate-pulse text-red-500" />
                            Urgent Warning
                        </div>
                        <p className="mt-1 text-sm font-medium">
                            {assignment.urgency.remark} (Cutoff passed: {assignment.urgency.remaining_time_human}).
                        </p>
                    </div>
                )}

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
                        <div className="flex items-center justify-between">
                            <div className="flex items-center gap-2 text-xs font-mono text-muted-foreground uppercase">
                                <Calendar className="size-3.5 text-primary" />
                                Submission Deadline
                            </div>
                            <UrgencyBadge urgency={assignment.urgency} />
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
                        <div className="mt-1 text-xs text-muted-foreground font-mono">
                            {assignment.urgency?.remark}
                        </div>
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
                                {assignment.urgency?.is_completed_on_time === false && (
                                    <span className="block text-red-400">(Submitted late)</span>
                                )}
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

                {/* Multiple Notes Section */}
                <div className="border border-border bg-card p-6 md:p-8 space-y-6">
                    <div className="flex items-center justify-between border-b border-border pb-4">
                        <div className="flex items-center gap-2">
                            <MessageSquare className="size-4 text-primary" />
                            <h2 className="text-base font-semibold text-foreground">
                                Assignment Notes
                            </h2>
                            <span className="border border-border bg-background px-2 py-0.5 font-mono text-xs text-muted-foreground">
                                {notes.length}
                            </span>
                        </div>
                        <span className="text-xs text-muted-foreground">
                            Quick notes, references, and task logs
                        </span>
                    </div>

                    {/* Add New Note Form */}
                    <form onSubmit={handleAddNote} className="space-y-3">
                        <textarea
                            value={addNoteForm.data.content}
                            onChange={(e) => addNoteForm.setData('content', e.target.value)}
                            placeholder="Add a new note (e.g. key reference links, reminder on professor feedback, teammate tasks)..."
                            aria-label="Add a note"
                            rows={3}
                            className="w-full border border-input bg-background p-3 text-sm text-foreground outline-none focus:border-ring rounded-none"
                            required
                        />
                        {addNoteForm.errors.content && (
                            <p className="text-xs text-red-400 font-mono">
                                {addNoteForm.errors.content}
                            </p>
                        )}
                        <div className="flex justify-end">
                            <Button
                                type="submit"
                                size="sm"
                                disabled={addNoteForm.processing || !addNoteForm.data.content.trim()}
                                className="rounded-none bg-primary text-primary-foreground hover:bg-primary/90"
                            >
                                <Plus className="size-3.5 mr-1" />
                                {addNoteForm.processing ? 'Saving Note...' : 'Add Note'}
                            </Button>
                        </div>
                    </form>

                    {/* Notes List */}
                    {notes.length === 0 ? (
                        <div className="border border-dashed border-border p-6 text-center text-xs text-muted-foreground">
                            No notes added yet. Use the field above to record study links, questions, or progress.
                        </div>
                    ) : (
                        <div className="divide-y divide-border border-t border-border">
                            {notes.map((note) => (
                                <div key={note.id} className="py-4 first:pt-4 last:pb-0 flex flex-col gap-2">
                                    <div className="flex items-center justify-between text-xs text-muted-foreground font-mono">
                                        <span>
                                            Created: {new Date(note.created_at).toLocaleString([], {
                                                month: 'short',
                                                day: 'numeric',
                                                hour: '2-digit',
                                                minute: '2-digit',
                                            })}
                                        </span>
                                        <div className="flex items-center gap-2">
                                            <button
                                                type="button"
                                                onClick={() => handleStartEditNote(note)}
                                                className="text-muted-foreground hover:text-foreground transition-colors p-1"
                                                title="Edit note"
                                            >
                                                <Pencil className="size-3.5" />
                                                <span className="sr-only">Edit note</span>
                                            </button>
                                            <button
                                                type="button"
                                                onClick={() => setDeletingNote(note)}
                                                className="text-destructive/80 hover:text-destructive transition-colors p-1"
                                                title="Delete note"
                                            >
                                                <Trash2 className="size-3.5" />
                                                <span className="sr-only">Delete note</span>
                                            </button>
                                        </div>
                                    </div>
                                    <p className="text-sm text-foreground whitespace-pre-wrap leading-relaxed">
                                        {note.content}
                                    </p>
                                </div>
                            ))}
                        </div>
                    )}
                </div>

                {/* Assignment Study Resources */}
                <div className="border border-border bg-card p-6 rounded-none">
                    <ResourceSection
                        resourceableType="assignment"
                        resourceableId={assignment.id}
                        resources={assignment.resources ?? []}
                        title="Attached Study Resources"
                        description="Upload assignment briefs, problem sets, rubrics, slide decks, or starter code."
                    />
                </div>
            </div>

            {/* Edit Note Modal */}
            <Dialog open={!!editingNote} onOpenChange={(open) => !open && setEditingNote(null)}>
                <DialogContent className="rounded-none sm:max-w-md border-border bg-card">
                    <DialogHeader>
                        <DialogTitle className="text-lg font-bold">Edit Note</DialogTitle>
                        <DialogDescription className="text-sm text-muted-foreground">
                            Update your coursework note content.
                        </DialogDescription>
                    </DialogHeader>
                    <form onSubmit={handleUpdateNote} className="space-y-4">
                        <textarea
                            value={editNoteForm.data.content}
                            onChange={(e) => editNoteForm.setData('content', e.target.value)}
                            aria-label="Edit note content"
                            rows={4}
                            className="w-full border border-input bg-background p-3 text-sm text-foreground outline-none focus:border-ring rounded-none"
                            required
                        />
                        {editNoteForm.errors.content && (
                            <p className="text-xs text-red-400 font-mono">
                                {editNoteForm.errors.content}
                            </p>
                        )}
                        <DialogFooter className="gap-2 sm:justify-end">
                            <Button
                                type="button"
                                variant="outline"
                                onClick={() => setEditingNote(null)}
                                className="rounded-none"
                            >
                                Cancel
                            </Button>
                            <Button
                                type="submit"
                                disabled={editNoteForm.processing}
                                className="rounded-none bg-primary text-primary-foreground"
                            >
                                {editNoteForm.processing ? 'Saving...' : 'Save Changes'}
                            </Button>
                        </DialogFooter>
                    </form>
                </DialogContent>
            </Dialog>

            {/* Delete Note Confirmation Modal */}
            <Dialog open={!!deletingNote} onOpenChange={(open) => !open && setDeletingNote(null)}>
                <DialogContent className="rounded-none sm:max-w-md border-border bg-card">
                    <DialogHeader>
                        <DialogTitle className="text-lg font-bold">Delete Note</DialogTitle>
                        <DialogDescription className="text-sm text-muted-foreground">
                            Are you sure you want to delete this note? This action cannot be undone.
                        </DialogDescription>
                    </DialogHeader>
                    <DialogFooter className="gap-2 sm:justify-end">
                        <Button
                            type="button"
                            variant="outline"
                            onClick={() => setDeletingNote(null)}
                            className="rounded-none"
                        >
                            Cancel
                        </Button>
                        <Button
                            type="button"
                            variant="destructive"
                            onClick={handleDeleteNote}
                            className="rounded-none"
                        >
                            Delete Note
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>

            {/* Delete Assignment Confirmation Modal */}
            <Dialog open={confirmDelete} onOpenChange={setConfirmDelete}>
                <DialogContent className="rounded-none sm:max-w-md border-border bg-card">
                    <DialogHeader>
                        <DialogTitle className="text-lg font-bold">Delete Assignment</DialogTitle>
                        <DialogDescription className="text-sm text-muted-foreground">
                            Are you sure you want to delete <span className="font-semibold text-foreground">{assignment.title}</span>? This will permanently delete the assignment and all associated notes.
                        </DialogDescription>
                    </DialogHeader>
                    <DialogFooter className="gap-2 sm:justify-end">
                        <Button
                            type="button"
                            variant="outline"
                            onClick={() => setConfirmDelete(false)}
                            disabled={deletingAssignment}
                            className="rounded-none"
                        >
                            Cancel
                        </Button>
                        <Button
                            type="button"
                            variant="destructive"
                            onClick={handleDeleteAssignment}
                            disabled={deletingAssignment}
                            className="rounded-none"
                        >
                            {deletingAssignment ? 'Deleting...' : 'Confirm Delete'}
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
