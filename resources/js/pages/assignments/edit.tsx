import { Head, Link, useForm } from '@inertiajs/react';
import { ArrowLeft, CheckSquare } from 'lucide-react';
import type { FormEventHandler } from 'react';
import InputError from '@/components/input-error';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { dashboard } from '@/routes';
import * as assignmentsRoutes from '@/routes/assignments';
import type { Assignment } from '@/types';

interface PageProps {
    assignment: Assignment;
    classes: Array<{ id: number; course_name: string }>;
}

export default function AssignmentsEdit({ assignment, classes }: PageProps) {
    // Format deadline for datetime-local input (YYYY-MM-DDTHH:mm)
    const formattedDeadline = assignment.deadline
        ? new Date(assignment.deadline).toISOString().slice(0, 16)
        : '';

    const { data, setData, put, processing, errors } = useForm({
        title: assignment.title,
        class_id: String(assignment.class_id),
        description: assignment.description ?? '',
        status: assignment.status,
        deadline: formattedDeadline,
    });

    const submit: FormEventHandler = (e) => {
        e.preventDefault();
        put(assignmentsRoutes.update(assignment).url);
    };

    return (
        <>
            <Head title={`Edit ${assignment.title}`} />

            <div className="flex flex-1 flex-col gap-6 p-6 md:p-8 max-w-3xl">
                {/* Back link & Header */}
                <div className="flex flex-col gap-2 border-b border-border pb-6">
                    <Link
                        href={assignmentsRoutes.index()}
                        className="inline-flex items-center gap-1.5 text-xs font-mono text-muted-foreground hover:text-foreground transition-colors w-fit"
                    >
                        <ArrowLeft className="size-3.5" />
                        Back to Assignments
                    </Link>
                    <div className="flex items-center gap-2 text-xs font-mono text-muted-foreground uppercase tracking-widest mt-2">
                        <CheckSquare className="size-4 text-primary" />
                        Modify Task
                    </div>
                    <h1 className="text-2xl font-bold tracking-tight text-foreground sm:text-3xl">
                        Edit Assignment
                    </h1>
                    <p className="text-sm text-muted-foreground">
                        Update task requirements, target class, or reschedule deadlines.
                    </p>
                </div>

                {/* Form Card */}
                <form onSubmit={submit} className="border border-border bg-card p-6 md:p-8 space-y-6">
                    <div className="space-y-2">
                        <Label htmlFor="title" className="text-sm font-medium">
                            Assignment Title <span className="text-primary">*</span>
                        </Label>
                        <Input
                            id="title"
                            name="title"
                            value={data.title}
                            onChange={(e) => setData('title', e.target.value)}
                            placeholder="e.g. Midterm Lab Report"
                            className="rounded-none bg-background"
                            required
                        />
                        <InputError message={errors.title} />
                    </div>

                    <div className="grid gap-6 sm:grid-cols-2">
                        <div className="space-y-2">
                            <Label htmlFor="class_id" className="text-sm font-medium">
                                Linked Course <span className="text-primary">*</span>
                            </Label>
                            <select
                                id="class_id"
                                name="class_id"
                                value={data.class_id}
                                onChange={(e) => setData('class_id', e.target.value)}
                                className="w-full h-9 border border-input bg-background px-3 py-1 text-sm text-foreground outline-none focus:border-ring rounded-none"
                                required
                            >
                                {classes.map((c) => (
                                    <option key={c.id} value={c.id}>
                                        {c.course_name}
                                    </option>
                                ))}
                            </select>
                            <InputError message={errors.class_id} />
                        </div>

                        <div className="space-y-2">
                            <Label htmlFor="status" className="text-sm font-medium">
                                Status <span className="text-primary">*</span>
                            </Label>
                            <select
                                id="status"
                                name="status"
                                value={data.status}
                                onChange={(e) => setData('status', e.target.value as Assignment['status'])}
                                className="w-full h-9 border border-input bg-background px-3 py-1 text-sm text-foreground outline-none focus:border-ring rounded-none font-mono"
                                required
                            >
                                <option value="pending">Pending</option>
                                <option value="in_progress">In Progress</option>
                                <option value="completed">Completed</option>
                            </select>
                            <InputError message={errors.status} />
                        </div>
                    </div>

                    <div className="space-y-2">
                        <Label htmlFor="deadline" className="text-sm font-medium">
                            Due Date & Time <span className="text-primary">*</span>
                        </Label>
                        <Input
                            id="deadline"
                            name="deadline"
                            type="datetime-local"
                            value={data.deadline}
                            onChange={(e) => setData('deadline', e.target.value)}
                            className="rounded-none bg-background font-mono"
                            required
                        />
                        <InputError message={errors.deadline} />
                    </div>

                    <div className="space-y-2">
                        <Label htmlFor="description" className="text-sm font-medium">
                            Instructions / Description (Optional)
                        </Label>
                        <textarea
                            id="description"
                            name="description"
                            rows={4}
                            value={data.description}
                            onChange={(e) => setData('description', e.target.value)}
                            className="w-full border border-input bg-background p-3 text-sm text-foreground outline-none focus:border-ring rounded-none"
                        />
                        <InputError message={errors.description} />
                    </div>

                    <div className="flex items-center justify-end gap-3 pt-4 border-t border-border">
                        <Button
                            type="button"
                            variant="outline"
                            asChild
                            className="rounded-none"
                        >
                            <Link href={assignmentsRoutes.index()}>Cancel</Link>
                        </Button>
                        <Button
                            type="submit"
                            disabled={processing}
                            className="rounded-none bg-primary text-primary-foreground hover:bg-primary/90 font-medium"
                        >
                            {processing ? 'Saving Changes...' : 'Save Changes'}
                        </Button>
                    </div>
                </form>
            </div>
        </>
    );
}

AssignmentsEdit.layout = {
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
            title: 'Edit Assignment',
            href: '#',
        },
    ],
};
