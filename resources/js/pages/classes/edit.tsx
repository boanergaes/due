import { Head, Link, useForm } from '@inertiajs/react';
import { ArrowLeft, GraduationCap } from 'lucide-react';
import type { FormEventHandler } from 'react';
import InputError from '@/components/input-error';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { dashboard } from '@/routes';
import * as classesRoutes from '@/routes/classes';
import type { CourseClass } from '@/types';

interface PageProps {
    courseClass: CourseClass;
}

export default function ClassesEdit({ courseClass }: PageProps) {
    const { data, setData, put, processing, errors } = useForm({
        course_name: courseClass.course_name,
        teacher_name: courseClass.teacher_name ?? '',
        teacher_contact: courseClass.teacher_contact ?? '',
        credit_hours: courseClass.credit_hours !== null ? String(courseClass.credit_hours) : '',
        ects: courseClass.ects !== null ? String(courseClass.ects) : '',
    });

    const submit: FormEventHandler = (e) => {
        e.preventDefault();
        put(classesRoutes.update(courseClass).url);
    };

    return (
        <>
            <Head title={`Edit ${courseClass.course_name}`} />

            <div className="flex flex-1 flex-col gap-6 p-6 md:p-8 max-w-3xl">
                {/* Back link & Header */}
                <div className="flex flex-col gap-2 border-b border-border pb-6">
                    <Link
                        href={classesRoutes.index()}
                        className="inline-flex items-center gap-1.5 text-xs font-mono text-muted-foreground hover:text-foreground transition-colors w-fit"
                    >
                        <ArrowLeft className="size-3.5" />
                        Back to Courses
                    </Link>
                    <div className="flex items-center gap-2 text-xs font-mono text-muted-foreground uppercase tracking-widest mt-2">
                        <GraduationCap className="size-4 text-primary" />
                        Modify Course
                    </div>
                    <h1 className="text-2xl font-bold tracking-tight text-foreground sm:text-3xl">
                        Edit Course Details
                    </h1>
                    <p className="text-sm text-muted-foreground">
                        Update instructor, credits, or course name for {courseClass.course_name}.
                    </p>
                </div>

                {/* Form Card */}
                <form onSubmit={submit} className="border border-border bg-card p-6 md:p-8 space-y-6">
                    <div className="space-y-2">
                        <Label htmlFor="course_name" className="text-sm font-medium">
                            Course Name <span className="text-primary">*</span>
                        </Label>
                        <Input
                            id="course_name"
                            name="course_name"
                            value={data.course_name}
                            onChange={(e) => setData('course_name', e.target.value)}
                            placeholder="e.g. Distributed Systems, Organic Chemistry"
                            className="rounded-none bg-background"
                            required
                        />
                        <InputError message={errors.course_name} />
                    </div>

                    <div className="grid gap-6 sm:grid-cols-2">
                        <div className="space-y-2">
                            <Label htmlFor="teacher_name" className="text-sm font-medium">
                                Instructor Name
                            </Label>
                            <Input
                                id="teacher_name"
                                name="teacher_name"
                                value={data.teacher_name}
                                onChange={(e) => setData('teacher_name', e.target.value)}
                                placeholder="e.g. Dr. Jane Smith"
                                className="rounded-none bg-background"
                            />
                            <InputError message={errors.teacher_name} />
                        </div>

                        <div className="space-y-2">
                            <Label htmlFor="teacher_contact" className="text-sm font-medium">
                                Instructor Contact
                            </Label>
                            <Input
                                id="teacher_contact"
                                name="teacher_contact"
                                value={data.teacher_contact}
                                onChange={(e) => setData('teacher_contact', e.target.value)}
                                placeholder="e.g. j.smith@university.edu"
                                className="rounded-none bg-background"
                            />
                            <InputError message={errors.teacher_contact} />
                        </div>
                    </div>

                    <div className="grid gap-6 sm:grid-cols-2">
                        <div className="space-y-2">
                            <Label htmlFor="credit_hours" className="text-sm font-medium">
                                Credit Hours (CH)
                            </Label>
                            <Input
                                id="credit_hours"
                                name="credit_hours"
                                type="number"
                                min="0"
                                max="100"
                                value={data.credit_hours}
                                onChange={(e) => setData('credit_hours', e.target.value)}
                                placeholder="e.g. 4"
                                className="rounded-none bg-background font-mono"
                            />
                            <InputError message={errors.credit_hours} />
                        </div>

                        <div className="space-y-2">
                            <Label htmlFor="ects" className="text-sm font-medium">
                                ECTS Credits
                            </Label>
                            <Input
                                id="ects"
                                name="ects"
                                type="number"
                                step="0.1"
                                min="0"
                                max="100"
                                value={data.ects}
                                onChange={(e) => setData('ects', e.target.value)}
                                placeholder="e.g. 6.0"
                                className="rounded-none bg-background font-mono"
                            />
                            <InputError message={errors.ects} />
                        </div>
                    </div>

                    <div className="flex items-center justify-end gap-3 pt-4 border-t border-border">
                        <Button
                            type="button"
                            variant="outline"
                            asChild
                            className="rounded-none"
                        >
                            <Link href={classesRoutes.index()}>Cancel</Link>
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

ClassesEdit.layout = {
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
            title: 'Edit Course',
            href: '#',
        },
    ],
};
