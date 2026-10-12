import { Head, Link, useForm, usePage } from '@inertiajs/react';
import {
    BookOpen,
    GraduationCap,
    MoreHorizontal,
    Pencil,
    Plus,
    Trash2,
    Users,
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
import { dashboard } from '@/routes';
import * as classesRoutes from '@/routes/classes';
import type { CourseClass, PaginatedData } from '@/types';

interface PageProps {
    [key: string]: unknown;
    classes: PaginatedData<CourseClass>;
    flash?: {
        success?: string | null;
        error?: string | null;
    };
    errors?: Record<string, string>;
}

export default function ClassesIndex({ classes }: PageProps) {
    const { flash, errors } = usePage<PageProps>().props;
    const [deletingClass, setDeletingClass] = useState<CourseClass | null>(null);

    const { delete: destroy, processing } = useForm();

    const handleDelete = () => {
        if (!deletingClass) return;
        destroy(classesRoutes.destroy(deletingClass).url, {
            preserveScroll: true,
            onSuccess: () => setDeletingClass(null),
        });
    };

    return (
        <>
            <Head title="Classes & Courses" />

            <div className="flex flex-1 flex-col gap-6 p-6 md:p-8">
                {/* Header */}
                <div className="flex flex-col justify-between gap-4 border-b border-border pb-6 sm:flex-row sm:items-center">
                    <div>
                        <div className="flex items-center gap-2 text-xs font-mono text-muted-foreground uppercase tracking-widest">
                            <GraduationCap className="size-4 text-primary" />
                            Academic Directory
                        </div>
                        <h1 className="mt-1 text-2xl font-bold tracking-tight text-foreground sm:text-3xl">
                            Courses & Classes
                        </h1>
                        <p className="mt-1 text-sm text-muted-foreground">
                            Manage your registered subjects, credit weights, and assigned professors.
                        </p>
                    </div>

                    <Button asChild className="rounded-none bg-primary text-primary-foreground hover:bg-primary/90 font-medium">
                        <Link href={classesRoutes.create()}>
                            <Plus className="size-4 mr-1.5" />
                            Add Course
                        </Link>
                    </Button>
                </div>

                {/* Notifications & Flash Messages */}
                {flash?.success && (
                    <Alert className="rounded-none border-emerald-500/50 bg-emerald-500/10 text-emerald-300">
                        <AlertDescription>{flash.success}</AlertDescription>
                    </Alert>
                )}

                {errors?.delete && (
                    <Alert className="rounded-none border-destructive/50 bg-destructive/10 text-destructive-foreground">
                        <AlertDescription>{errors.delete}</AlertDescription>
                    </Alert>
                )}

                {/* Course Grid / Table */}
                {classes.data.length === 0 ? (
                    <div className="flex flex-col items-center justify-center border border-dashed border-border bg-card/40 p-12 text-center">
                        <div className="flex size-12 items-center justify-center border border-border bg-muted/20 text-muted-foreground">
                            <BookOpen className="size-6" />
                        </div>
                        <h3 className="mt-4 text-base font-semibold text-foreground">
                            No courses registered yet
                        </h3>
                        <p className="mt-1 max-w-sm text-sm text-muted-foreground">
                            Add the classes you are currently taking this semester to start organizing your assignments.
                        </p>
                        <Button asChild className="mt-6 rounded-none">
                            <Link href={classesRoutes.create()}>
                                <Plus className="size-4 mr-1.5" />
                                Create Your First Course
                            </Link>
                        </Button>
                    </div>
                ) : (
                    <div className="space-y-4">
                        <div className="overflow-x-auto border border-border bg-card">
                            <table className="w-full text-left text-sm">
                                <thead className="border-b border-border bg-muted/40 font-mono text-xs uppercase tracking-wider text-muted-foreground">
                                    <tr>
                                        <th scope="col" className="px-5 py-3.5 font-semibold">Course</th>
                                        <th scope="col" className="px-5 py-3.5 font-semibold">Instructor</th>
                                        <th scope="col" className="px-5 py-3.5 font-semibold">Credits / ECTS</th>
                                        <th scope="col" className="px-5 py-3.5 font-semibold">Assignments</th>
                                        <th scope="col" className="px-5 py-3.5 text-right font-semibold">Actions</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-border">
                                    {classes.data.map((course) => (
                                        <tr
                                            key={course.id}
                                            className="transition-colors hover:bg-muted/20"
                                        >
                                            <td className="px-5 py-4 font-medium text-foreground">
                                                <Link
                                                    href={classesRoutes.show(course)}
                                                    className="hover:text-primary transition-colors hover:underline"
                                                >
                                                    {course.course_name}
                                                </Link>
                                            </td>
                                            <td className="px-5 py-4 text-muted-foreground">
                                                {course.teacher_name ? (
                                                    <div>
                                                        <div className="text-foreground">{course.teacher_name}</div>
                                                        {course.teacher_contact && (
                                                            <div className="text-xs text-muted-foreground font-mono">
                                                                {course.teacher_contact}
                                                            </div>
                                                        )}
                                                    </div>
                                                ) : (
                                                    <span className="text-muted-foreground/50">—</span>
                                                )}
                                            </td>
                                            <td className="px-5 py-4 font-mono text-xs text-muted-foreground">
                                                <div className="flex items-center gap-1.5">
                                                    {course.credit_hours !== null && (
                                                        <span className="border border-border/80 bg-background px-1.5 py-0.5">
                                                            {course.credit_hours} CH
                                                        </span>
                                                    )}
                                                    {course.ects !== null && (
                                                        <span className="border border-border/80 bg-background px-1.5 py-0.5">
                                                            {course.ects} ECTS
                                                        </span>
                                                    )}
                                                    {course.credit_hours === null && course.ects === null && (
                                                        <span className="text-muted-foreground/50">—</span>
                                                    )}
                                                </div>
                                            </td>
                                            <td className="px-5 py-4">
                                                <Badge
                                                    variant="secondary"
                                                    className="rounded-none border border-border font-mono text-xs"
                                                >
                                                    {course.assignments_count ?? 0} {course.assignments_count === 1 ? 'assignment' : 'assignments'}
                                                </Badge>
                                            </td>
                                            <td className="px-5 py-4 text-right">
                                                <div className="flex items-center justify-end gap-1">
                                                    <Button
                                                        variant="ghost"
                                                        size="sm"
                                                        asChild
                                                        className="h-8 rounded-none text-muted-foreground hover:text-foreground"
                                                    >
                                                        <Link href={classesRoutes.show(course)}>
                                                            View
                                                        </Link>
                                                    </Button>
                                                    <Button
                                                        variant="ghost"
                                                        size="sm"
                                                        asChild
                                                        className="h-8 rounded-none text-muted-foreground hover:text-foreground"
                                                    >
                                                        <Link href={classesRoutes.edit(course)}>
                                                            <Pencil className="size-3.5" />
                                                            <span className="sr-only">Edit</span>
                                                        </Link>
                                                    </Button>
                                                    <Button
                                                        variant="ghost"
                                                        size="sm"
                                                        onClick={() => setDeletingClass(course)}
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

                        <Pagination links={classes.links} />
                    </div>
                )}
            </div>

            {/* Delete Confirmation Modal */}
            <Dialog open={!!deletingClass} onOpenChange={(open) => !open && setDeletingClass(null)}>
                <DialogContent className="rounded-none sm:max-w-md border-border bg-card">
                    <DialogHeader>
                        <DialogTitle className="text-lg font-bold">Delete Course</DialogTitle>
                        <DialogDescription className="text-sm text-muted-foreground">
                            Are you sure you want to delete <span className="font-semibold text-foreground">{deletingClass?.course_name}</span>?
                            {deletingClass?.assignments_count && deletingClass.assignments_count > 0 ? (
                                <span className="mt-2 block text-destructive font-medium">
                                    Notice: This course currently has {deletingClass.assignments_count} assigned task(s). Course deletion is restricted while assignments exist.
                                </span>
                            ) : null}
                        </DialogDescription>
                    </DialogHeader>
                    <DialogFooter className="gap-2 sm:justify-end">
                        <Button
                            type="button"
                            variant="outline"
                            onClick={() => setDeletingClass(null)}
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

ClassesIndex.layout = {
    breadcrumbs: [
        {
            title: 'Dashboard',
            href: dashboard(),
        },
        {
            title: 'Classes',
            href: classesRoutes.index(),
        },
    ],
};
