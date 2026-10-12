import { Head, Link, router } from '@inertiajs/react';
import {
    AlertTriangle,
    ArrowRight,
    BarChart3,
    Calendar,
    CheckCircle2,
    CheckSquare,
    Clock,
    GraduationCap,
    Plus,
    RotateCcw,
    Sparkles,
    TrendingUp,
} from 'lucide-react';
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { Button } from '@/components/ui/button';
import { UrgencyBadge } from '@/components/urgency-badge';
import { dashboard } from '@/routes';
import * as assignmentsRoutes from '@/routes/assignments';
import * as classesRoutes from '@/routes/classes';
import type { Assignment, DashboardPageProps } from '@/types';

export default function Dashboard({
    metrics,
    upcoming_assignments,
    overdue_assignments,
    workload_by_class,
}: DashboardPageProps) {
    const handleQuickStatus = (assignment: Assignment, status: Assignment['status']) => {
        router.patch(
            `/assignments/${assignment.id}/status`,
            { status },
            { preserveScroll: true }
        );
    };

    const hasAnyAssignments = metrics.total > 0;
    const hasAnyClasses = workload_by_class.length > 0;

    return (
        <>
            <Head title="Academic Dashboard" />

            <div className="flex flex-1 flex-col gap-8 p-6 md:p-8">
                {/* Header */}
                <div className="flex flex-col justify-between gap-4 border-b border-border pb-6 sm:flex-row sm:items-center">
                    <div>
                        <div className="flex items-center gap-2 text-xs font-mono text-muted-foreground uppercase tracking-widest">
                            <GraduationCap className="size-4 text-primary" />
                            Academic Overview
                        </div>
                        <h1 className="mt-1 text-2xl font-bold tracking-tight text-foreground sm:text-3xl">
                            Dashboard
                        </h1>
                        <p className="mt-1 text-sm text-muted-foreground">
                            Real-time coursework analytics, deadline urgency tracking, and progress metrics.
                        </p>
                    </div>

                    <div className="flex items-center gap-2.5">
                        <Button asChild variant="outline" className="rounded-none font-mono text-xs">
                            <Link href={classesRoutes.create()}>
                                <Plus className="size-3.5 mr-1.5" />
                                New Course
                            </Link>
                        </Button>
                        <Button asChild className="rounded-none bg-primary text-primary-foreground hover:bg-primary/90 font-mono text-xs font-semibold">
                            <Link href={assignmentsRoutes.create()}>
                                <Plus className="size-3.5 mr-1.5" />
                                New Assignment
                            </Link>
                        </Button>
                    </div>
                </div>

                {/* Overdue Urgent Alert Banner */}
                {metrics.overdue > 0 && (
                    <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 border border-destructive/60 bg-destructive/10 p-4 text-destructive">
                        <div className="flex items-start sm:items-center gap-3">
                            <AlertTriangle className="size-5 shrink-0 mt-0.5 sm:mt-0 text-destructive" />
                            <div>
                                <span className="font-semibold text-sm">
                                    Attention Needed: {metrics.overdue} {metrics.overdue === 1 ? 'assignment is' : 'assignments are'} overdue.
                                </span>
                                <p className="text-xs text-destructive/80 mt-0.5 font-mono">
                                    Incomplete deadlines that passed require immediate submission or status update.
                                </p>
                            </div>
                        </div>
                        <Button
                            asChild
                            variant="destructive"
                            size="sm"
                            className="rounded-none font-mono text-xs shrink-0"
                        >
                            <Link href={`${assignmentsRoutes.index().url}?urgency=overdue`}>
                                View Overdue Tasks
                                <ArrowRight className="size-3.5 ml-1.5" />
                            </Link>
                        </Button>
                    </div>
                )}

                {/* Numerical Summary Metric Cards */}
                <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-5">
                    {/* Total */}
                    <div className="border border-border bg-card p-4 transition-colors hover:border-border/80">
                        <div className="flex items-center justify-between text-xs font-mono text-muted-foreground uppercase">
                            <span>Total Tasks</span>
                            <CheckSquare className="size-4 text-muted-foreground" />
                        </div>
                        <div className="mt-3 font-mono text-3xl font-bold tracking-tight text-foreground">
                            {metrics.total}
                        </div>
                        <div className="mt-1 text-xs text-muted-foreground font-mono">
                            {metrics.total === 1 ? '1 registered task' : `${metrics.total} registered tasks`}
                        </div>
                    </div>

                    {/* Pending */}
                    <div className="border border-border bg-card p-4 transition-colors hover:border-border/80">
                        <div className="flex items-center justify-between text-xs font-mono text-blue-400 uppercase">
                            <span>Pending</span>
                            <Clock className="size-4 text-blue-400" />
                        </div>
                        <div className="mt-3 font-mono text-3xl font-bold tracking-tight text-foreground">
                            {metrics.pending}
                        </div>
                        <div className="mt-1 text-xs text-muted-foreground font-mono">
                            Not yet initiated
                        </div>
                    </div>

                    {/* In Progress */}
                    <div className="border border-border bg-card p-4 transition-colors hover:border-border/80">
                        <div className="flex items-center justify-between text-xs font-mono text-amber-400 uppercase">
                            <span>In Progress</span>
                            <Clock className="size-4 text-amber-400" />
                        </div>
                        <div className="mt-3 font-mono text-3xl font-bold tracking-tight text-foreground">
                            {metrics.in_progress}
                        </div>
                        <div className="mt-1 text-xs text-muted-foreground font-mono">
                            Actively being worked
                        </div>
                    </div>

                    {/* Completed */}
                    <div className="border border-border bg-card p-4 transition-colors hover:border-border/80">
                        <div className="flex items-center justify-between text-xs font-mono text-emerald-400 uppercase">
                            <span>Completed</span>
                            <CheckCircle2 className="size-4 text-emerald-400" />
                        </div>
                        <div className="mt-3 font-mono text-3xl font-bold tracking-tight text-foreground">
                            {metrics.completed}
                        </div>
                        <div className="mt-1 text-xs text-muted-foreground font-mono">
                            {metrics.completed_recently > 0
                                ? `+${metrics.completed_recently} this week`
                                : 'Finished coursework'}
                        </div>
                    </div>

                    {/* Overdue */}
                    <div className={`border p-4 transition-colors ${
                        metrics.overdue > 0
                            ? 'border-destructive/60 bg-destructive/5'
                            : 'border-border bg-card'
                    }`}>
                        <div className="flex items-center justify-between text-xs font-mono uppercase text-destructive">
                            <span>Overdue</span>
                            <AlertTriangle className="size-4" />
                        </div>
                        <div className="mt-3 font-mono text-3xl font-bold tracking-tight text-destructive">
                            {metrics.overdue}
                        </div>
                        <div className="mt-1 text-xs text-muted-foreground font-mono">
                            {metrics.due_today > 0 ? `${metrics.due_today} due today` : 'Missed deadlines'}
                        </div>
                    </div>
                </div>

                {/* Performance Analysis & Workload by Course */}
                <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
                    {/* Performance Analysis Card */}
                    <div className="border border-border bg-card p-5">
                        <div className="flex items-center justify-between border-b border-border pb-3">
                            <div className="flex items-center gap-2">
                                <TrendingUp className="size-4 text-primary" />
                                <h2 className="text-sm font-semibold tracking-wide uppercase font-mono text-foreground">
                                    Performance Analysis
                                </h2>
                            </div>
                            <span className="text-xs font-mono text-muted-foreground">
                                Database Aggregates
                            </span>
                        </div>

                        <div className="mt-5 space-y-6">
                            {/* Completion Rate */}
                            <div>
                                <div className="flex items-center justify-between text-xs font-mono">
                                    <span className="text-muted-foreground uppercase">Completion Rate</span>
                                    <span className="font-bold text-foreground">{metrics.completion_rate}%</span>
                                </div>
                                <div className="mt-2 h-2.5 w-full bg-muted/40 border border-border">
                                    <div
                                        className="h-full bg-primary transition-all duration-300"
                                        style={{ width: `${Math.min(metrics.completion_rate, 100)}%` }}
                                    />
                                </div>
                                <div className="mt-1.5 flex justify-between text-[11px] font-mono text-muted-foreground">
                                    <span>{metrics.completed} finished</span>
                                    <span>{metrics.total - metrics.completed} remaining</span>
                                </div>
                            </div>

                            {/* On-Time Completion Rate */}
                            <div className="border-t border-border/60 pt-4">
                                <div className="flex items-center justify-between">
                                    <div>
                                        <div className="text-xs font-mono uppercase text-muted-foreground">
                                            On-Time Rate
                                        </div>
                                        <p className="text-xs text-muted-foreground mt-0.5">
                                            Submissions finished prior to the scheduled deadline.
                                        </p>
                                    </div>
                                    <div className="text-right">
                                        {metrics.on_time_rate !== null ? (
                                            <span className="inline-flex items-center border border-emerald-500/40 bg-emerald-500/10 px-2.5 py-1 font-mono text-xs font-bold text-emerald-400">
                                                {metrics.on_time_rate}% On-Time
                                            </span>
                                        ) : (
                                            <span className="inline-flex items-center border border-border bg-muted/20 px-2 py-0.5 font-mono text-xs text-muted-foreground">
                                                No completed tasks
                                            </span>
                                        )}
                                    </div>
                                </div>
                            </div>

                            {/* Velocity & Momentum */}
                            <div className="border-t border-border/60 pt-4 flex items-center justify-between text-xs font-mono">
                                <span className="text-muted-foreground">7-Day Completion Velocity</span>
                                <span className="font-bold text-foreground">
                                    {metrics.completed_recently} {metrics.completed_recently === 1 ? 'task' : 'tasks'}
                                </span>
                            </div>
                        </div>
                    </div>

                    {/* Workload by Course */}
                    <div className="border border-border bg-card p-5">
                        <div className="flex items-center justify-between border-b border-border pb-3">
                            <div className="flex items-center gap-2">
                                <BarChart3 className="size-4 text-primary" />
                                <h2 className="text-sm font-semibold tracking-wide uppercase font-mono text-foreground">
                                    Workload by Course
                                </h2>
                            </div>
                            <Button asChild variant="ghost" size="sm" className="h-6 px-2 text-xs font-mono text-muted-foreground hover:text-foreground">
                                <Link href={classesRoutes.index()}>
                                    All Courses ({workload_by_class.length})
                                </Link>
                            </Button>
                        </div>

                        <div className="mt-5 space-y-4">
                            {workload_by_class.length === 0 ? (
                                <div className="flex flex-col items-center justify-center p-8 text-center text-muted-foreground border border-dashed border-border">
                                    <GraduationCap className="size-8 opacity-40" />
                                    <p className="mt-2 text-xs font-mono">No courses registered yet.</p>
                                    <Button asChild variant="outline" size="sm" className="mt-4 rounded-none font-mono text-xs">
                                        <Link href={classesRoutes.create()}>
                                            <Plus className="size-3 mr-1" />
                                            Add First Course
                                        </Link>
                                    </Button>
                                </div>
                            ) : (
                                workload_by_class.map((c) => {
                                    const percent = c.total_assignments > 0
                                        ? Math.round((c.completed_assignments / c.total_assignments) * 100)
                                        : 0;

                                    return (
                                        <div key={c.id} className="space-y-1.5 border-b border-border/50 pb-3 last:border-0 last:pb-0">
                                            <div className="flex items-center justify-between">
                                                <Link
                                                    href={classesRoutes.show(c)}
                                                    className="font-medium text-xs text-foreground hover:text-primary transition-colors hover:underline flex items-center gap-1.5"
                                                >
                                                    <span className="size-1.5 bg-primary" />
                                                    {c.course_name}
                                                </Link>
                                                <span className="font-mono text-xs text-muted-foreground">
                                                    <span className="text-foreground font-semibold">{c.active_assignments}</span> active / {c.total_assignments} total
                                                </span>
                                            </div>
                                            <div className="h-1.5 w-full bg-muted/40 border border-border">
                                                <div
                                                    className="h-full bg-primary"
                                                    style={{ width: `${percent}%` }}
                                                />
                                            </div>
                                        </div>
                                    );
                                })
                            )}
                        </div>
                    </div>
                </div>

                {/* Upcoming Assignments Feed */}
                <div className="border border-border bg-card">
                    <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 border-b border-border p-5">
                        <div>
                            <div className="flex items-center gap-2">
                                <Clock className="size-4 text-primary" />
                                <h2 className="text-base font-bold text-foreground">
                                    Upcoming Deadlines
                                </h2>
                            </div>
                            <p className="mt-0.5 text-xs text-muted-foreground font-mono">
                                Nearest incomplete tasks requiring student action, ordered by target deadline.
                            </p>
                        </div>

                        <Button asChild variant="outline" size="sm" className="rounded-none font-mono text-xs shrink-0">
                            <Link href={assignmentsRoutes.index()}>
                                View All Assignments
                                <ArrowRight className="size-3.5 ml-1.5" />
                            </Link>
                        </Button>
                    </div>

                    {upcoming_assignments.length === 0 ? (
                        <div className="flex flex-col items-center justify-center p-12 text-center">
                            <CheckCircle2 className="size-10 text-emerald-400/60" />
                            <h3 className="mt-3 text-sm font-semibold text-foreground">
                                No upcoming deadlines
                            </h3>
                            <p className="mt-1 text-xs text-muted-foreground font-mono max-w-sm">
                                {metrics.total === 0
                                    ? 'You have not registered any assignments yet. Create your first assignment to get started.'
                                    : 'All scheduled assignments have been completed or there are no pending future deadlines!'}
                            </p>
                            <Button asChild className="mt-5 rounded-none font-mono text-xs">
                                <Link href={assignmentsRoutes.create()}>
                                    <Plus className="size-3.5 mr-1.5" />
                                    Create Assignment
                                </Link>
                            </Button>
                        </div>
                    ) : (
                        <div className="overflow-x-auto">
                            <table className="w-full text-left text-sm">
                                <thead className="border-b border-border bg-muted/30 font-mono text-xs uppercase text-muted-foreground">
                                    <tr>
                                        <th scope="col" className="px-5 py-3 font-semibold">Assignment</th>
                                        <th scope="col" className="px-5 py-3 font-semibold">Course</th>
                                        <th scope="col" className="px-5 py-3 font-semibold">Deadline</th>
                                        <th scope="col" className="px-5 py-3 font-semibold">Urgency</th>
                                        <th scope="col" className="px-5 py-3 text-right font-semibold">Action</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-border">
                                    {upcoming_assignments.map((assignment) => (
                                        <tr key={assignment.id} className="transition-colors hover:bg-muted/15">
                                            <td className="px-5 py-3.5">
                                                <Link
                                                    href={assignmentsRoutes.show(assignment)}
                                                    className="font-medium text-foreground hover:text-primary transition-colors hover:underline block text-xs sm:text-sm"
                                                >
                                                    {assignment.title}
                                                </Link>
                                                {assignment.description && (
                                                    <span className="mt-0.5 line-clamp-1 text-xs text-muted-foreground max-w-md">
                                                        {assignment.description}
                                                    </span>
                                                )}
                                            </td>

                                            <td className="px-5 py-3.5">
                                                {assignment.course_class ? (
                                                    <Link
                                                        href={classesRoutes.show(assignment.course_class)}
                                                        className="inline-flex items-center gap-1 font-mono text-xs text-muted-foreground hover:text-foreground"
                                                    >
                                                        <GraduationCap className="size-3 text-primary" />
                                                        {assignment.course_class.course_name}
                                                    </Link>
                                                ) : (
                                                    <span className="text-muted-foreground text-xs">—</span>
                                                )}
                                            </td>

                                            <td className="px-5 py-3.5 font-mono text-xs text-muted-foreground whitespace-nowrap">
                                                <div className="flex items-center gap-1.5">
                                                    <Calendar className="size-3 text-primary" />
                                                    {new Date(assignment.deadline).toLocaleString([], {
                                                        month: 'short',
                                                        day: 'numeric',
                                                        hour: '2-digit',
                                                        minute: '2-digit',
                                                    })}
                                                </div>
                                            </td>

                                            <td className="px-5 py-3.5">
                                                <UrgencyBadge urgency={assignment.urgency} />
                                            </td>

                                            <td className="px-5 py-3.5 text-right">
                                                <div className="flex items-center justify-end gap-1.5">
                                                    <DropdownMenu>
                                                        <DropdownMenuTrigger asChild>
                                                            <Button
                                                                variant="ghost"
                                                                size="sm"
                                                                className="h-7 rounded-none px-2 text-xs font-mono text-muted-foreground hover:text-foreground"
                                                            >
                                                                Status
                                                            </Button>
                                                        </DropdownMenuTrigger>
                                                        <DropdownMenuContent className="rounded-none border-border bg-card">
                                                            <DropdownMenuItem
                                                                onClick={() => handleQuickStatus(assignment, 'pending')}
                                                                className="text-xs font-mono"
                                                            >
                                                                Pending
                                                            </DropdownMenuItem>
                                                            <DropdownMenuItem
                                                                onClick={() => handleQuickStatus(assignment, 'in_progress')}
                                                                className="text-xs font-mono"
                                                            >
                                                                In Progress
                                                            </DropdownMenuItem>
                                                            <DropdownMenuItem
                                                                onClick={() => handleQuickStatus(assignment, 'completed')}
                                                                className="text-xs font-mono text-emerald-400 font-semibold"
                                                            >
                                                                Completed
                                                            </DropdownMenuItem>
                                                        </DropdownMenuContent>
                                                    </DropdownMenu>

                                                    <Button
                                                        asChild
                                                        variant="ghost"
                                                        size="sm"
                                                        className="h-7 rounded-none px-2 text-xs font-mono"
                                                    >
                                                        <Link href={assignmentsRoutes.show(assignment)}>
                                                            View
                                                        </Link>
                                                    </Button>
                                                </div>
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    )}
                </div>

                {/* Overdue Attention List (if any exist) */}
                {overdue_assignments.length > 0 && (
                    <div className="border border-destructive/40 bg-card">
                        <div className="flex items-center justify-between border-b border-destructive/30 bg-destructive/5 p-4">
                            <div className="flex items-center gap-2">
                                <AlertTriangle className="size-4 text-destructive" />
                                <h3 className="text-sm font-bold text-destructive font-mono uppercase tracking-wide">
                                    Overdue Assignments Requiring Attention ({overdue_assignments.length})
                                </h3>
                            </div>
                            <Button asChild variant="outline" size="sm" className="h-7 rounded-none border-destructive/40 text-xs font-mono text-destructive hover:bg-destructive/10">
                                <Link href={`${assignmentsRoutes.index().url}?urgency=overdue`}>
                                    Filter All Overdue
                                </Link>
                            </Button>
                        </div>
                        <div className="divide-y divide-border/60">
                            {overdue_assignments.map((assignment) => (
                                <div
                                    key={assignment.id}
                                    className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 p-4 transition-colors hover:bg-destructive/5"
                                >
                                    <div>
                                        <Link
                                            href={assignmentsRoutes.show(assignment)}
                                            className="font-medium text-foreground hover:text-destructive text-sm"
                                        >
                                            {assignment.title}
                                        </Link>
                                        <div className="mt-1 flex items-center gap-3 text-xs font-mono text-muted-foreground">
                                            {assignment.course_class && (
                                                <span className="flex items-center gap-1">
                                                    <GraduationCap className="size-3 text-primary" />
                                                    {assignment.course_class.course_name}
                                                </span>
                                            )}
                                            <span>
                                                Deadline: {new Date(assignment.deadline).toLocaleString([], {
                                                    month: 'short',
                                                    day: 'numeric',
                                                    hour: '2-digit',
                                                    minute: '2-digit',
                                                })}
                                            </span>
                                        </div>
                                    </div>

                                    <div className="flex items-center gap-2">
                                        <UrgencyBadge urgency={assignment.urgency} />
                                        <Button
                                            size="sm"
                                            onClick={() => handleQuickStatus(assignment, 'completed')}
                                            className="h-7 rounded-none bg-emerald-600 hover:bg-emerald-500 text-white font-mono text-xs"
                                        >
                                            Mark Done
                                        </Button>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                )}
            </div>
        </>
    );
}

Dashboard.layout = {
    breadcrumbs: [
        {
            title: 'Dashboard',
            href: dashboard(),
        },
    ],
};
