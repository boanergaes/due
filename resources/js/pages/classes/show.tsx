import { Head, Link, useForm } from '@inertiajs/react';
import {
    ArrowLeft,
    Calendar,
    CheckCircle2,
    Clock,
    FileText,
    GraduationCap,
    Mail,
    Pencil,
    Plus,
    Trash2,
    User,
} from 'lucide-react';
import { useState } from 'react';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { ResourceSection } from '@/components/resources/resource-section';
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
import type { Assignment, CourseClass } from '@/types';

interface PageProps {
    courseClass: CourseClass;
    errors?: Record<string, string>;
}

export default function ClassesShow({ courseClass, errors }: PageProps) {
    const [confirmDelete, setConfirmDelete] = useState(false);
    const { delete: destroy, processing } = useForm();

    const assignments = courseClass.assignments ?? [];

    const handleDelete = () => {
        destroy(classesRoutes.destroy(courseClass).url, {
            onSuccess: () => setConfirmDelete(false),
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

    return (
        <>
            <Head title={courseClass.course_name} />

            <div className="flex flex-1 flex-col gap-6 p-6 md:p-8">
                {/* Back link & Header */}
                <div className="flex flex-col justify-between gap-4 border-b border-border pb-6 sm:flex-row sm:items-center">
                    <div>
                        <Link
                            href={classesRoutes.index()}
                            className="inline-flex items-center gap-1.5 text-xs font-mono text-muted-foreground hover:text-foreground transition-colors mb-2"
                        >
                            <ArrowLeft className="size-3.5" />
                            Back to Courses
                        </Link>
                        <div className="flex items-center gap-2 text-xs font-mono text-muted-foreground uppercase tracking-widest">
                            <GraduationCap className="size-4 text-primary" />
                            Course Overview
                        </div>
                        <h1 className="mt-1 text-2xl font-bold tracking-tight text-foreground sm:text-3xl">
                            {courseClass.course_name}
                        </h1>
                    </div>

                    <div className="flex items-center gap-2">
                        <Button variant="outline" asChild className="rounded-none">
                            <Link href={classesRoutes.edit(courseClass)}>
                                <Pencil className="size-3.5 mr-1.5" />
                                Edit Course
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

                {errors?.delete && (
                    <Alert className="rounded-none border-destructive/50 bg-destructive/10 text-destructive-foreground">
                        <AlertDescription>{errors.delete}</AlertDescription>
                    </Alert>
                )}

                {/* Course Metadata Cards */}
                <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
                    <div className="border border-border bg-card p-5">
                        <div className="flex items-center gap-2 text-xs font-mono text-muted-foreground uppercase">
                            <User className="size-3.5 text-primary" />
                            Instructor
                        </div>
                        <div className="mt-2 text-base font-semibold text-foreground">
                            {courseClass.teacher_name || 'Not specified'}
                        </div>
                        {courseClass.teacher_contact && (
                            <div className="mt-1 flex items-center gap-1 text-xs text-muted-foreground font-mono">
                                <Mail className="size-3" />
                                {courseClass.teacher_contact}
                            </div>
                        )}
                    </div>

                    <div className="border border-border bg-card p-5">
                        <div className="flex items-center gap-2 text-xs font-mono text-muted-foreground uppercase">
                            <GraduationCap className="size-3.5 text-primary" />
                            Credit Hours
                        </div>
                        <div className="mt-2 text-base font-semibold font-mono text-foreground">
                            {courseClass.credit_hours !== null ? `${courseClass.credit_hours} CH` : '—'}
                        </div>
                        <div className="mt-1 text-xs text-muted-foreground">Standard semester units</div>
                    </div>

                    <div className="border border-border bg-card p-5">
                        <div className="flex items-center gap-2 text-xs font-mono text-muted-foreground uppercase">
                            <GraduationCap className="size-3.5 text-primary" />
                            ECTS Weight
                        </div>
                        <div className="mt-2 text-base font-semibold font-mono text-foreground">
                            {courseClass.ects !== null ? `${courseClass.ects} ECTS` : '—'}
                        </div>
                        <div className="mt-1 text-xs text-muted-foreground">European credit equivalence</div>
                    </div>

                    <div className="border border-border bg-card p-5">
                        <div className="flex items-center gap-2 text-xs font-mono text-muted-foreground uppercase">
                            <FileText className="size-3.5 text-primary" />
                            Linked Tasks
                        </div>
                        <div className="mt-2 text-base font-semibold font-mono text-foreground">
                            {assignments.length} {assignments.length === 1 ? 'Task' : 'Tasks'}
                        </div>
                        <div className="mt-1 text-xs text-muted-foreground">Total assignments registered</div>
                    </div>
                </div>

                {/* Associated Assignments Section */}
                <div className="border border-border bg-card">
                    <div className="flex items-center justify-between border-b border-border p-5">
                        <div>
                            <h2 className="text-base font-semibold text-foreground">Course Assignments</h2>
                            <p className="text-xs text-muted-foreground">
                                All coursework and deadlines registered for {courseClass.course_name}.
                            </p>
                        </div>

                        <Button asChild size="sm" className="rounded-none bg-primary text-primary-foreground hover:bg-primary/90">
                            <Link href={`${assignmentsRoutes.create().url}?class_id=${courseClass.id}`}>
                                <Plus className="size-3.5 mr-1" />
                                Add Assignment
                            </Link>
                        </Button>
                    </div>

                    {assignments.length === 0 ? (
                        <div className="p-8 text-center text-sm text-muted-foreground">
                            No assignments currently scheduled for this course.
                        </div>
                    ) : (
                        <div className="divide-y divide-border">
                            {assignments.map((assignment) => (
                                <div
                                    key={assignment.id}
                                    className="flex flex-col justify-between gap-3 p-5 sm:flex-row sm:items-center hover:bg-muted/10 transition-colors"
                                >
                                    <div>
                                        <Link
                                            href={assignmentsRoutes.show(assignment)}
                                            className="font-medium text-foreground hover:text-primary transition-colors hover:underline"
                                        >
                                            {assignment.title}
                                        </Link>
                                        <div className="mt-1 flex flex-wrap items-center gap-3 text-xs text-muted-foreground">
                                            <span className="flex items-center gap-1 font-mono">
                                                <Calendar className="size-3 text-primary" />
                                                Due: {new Date(assignment.deadline).toLocaleString()}
                                            </span>
                                            {assignment.description && (
                                                <span className="truncate max-w-md">
                                                    {assignment.description}
                                                </span>
                                            )}
                                        </div>
                                    </div>

                                    <div className="flex items-center gap-3">
                                        {getStatusBadge(assignment.status)}
                                        <Button
                                            variant="ghost"
                                            size="sm"
                                            asChild
                                            className="h-8 rounded-none text-xs"
                                        >
                                            <Link href={assignmentsRoutes.show(assignment)}>
                                                View Task
                                            </Link>
                                        </Button>
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </div>

                {/* Course Study Resources */}
                <div className="border border-border bg-card p-5">
                    <ResourceSection
                        resourceableType="class"
                        resourceableId={courseClass.id}
                        resources={courseClass.resources ?? []}
                        title="Course Resources & Materials"
                        description="Upload syllabi, lecture slides, textbooks, and review papers for this class."
                    />
                </div>
            </div>

            {/* Delete Confirmation Modal */}
            <Dialog open={confirmDelete} onOpenChange={setConfirmDelete}>
                <DialogContent className="rounded-none sm:max-w-md border-border bg-card">
                    <DialogHeader>
                        <DialogTitle className="text-lg font-bold">Delete Course</DialogTitle>
                        <DialogDescription className="text-sm text-muted-foreground">
                            Are you sure you want to delete <span className="font-semibold text-foreground">{courseClass.course_name}</span>?
                            {assignments.length > 0 && (
                                <span className="mt-2 block text-destructive font-medium">
                                    Warning: This course has {assignments.length} assigned task(s). The database restricts deleting courses that have active assignments.
                                </span>
                            )}
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

ClassesShow.layout = {
    breadcrumbs: [
        {
            title: 'Dashboard',
            href: dashboard(),
        },
        {
            title: 'Classes',
            href: classesRoutes.index(),
        },
        {
            title: 'Course Details',
            href: '#',
        },
    ],
};
