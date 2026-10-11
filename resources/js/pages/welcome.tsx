import { Head, Link, usePage } from '@inertiajs/react';
import {
    ArrowRight,
    BarChart3,
    BookOpen,
    Calendar,
    CheckCircle2,
    CheckSquare,
    Clock,
    FileText,
    Sparkles,
} from 'lucide-react';

import AppLogoIcon from '@/components/app-logo-icon';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { dashboard, login, register } from '@/routes';

export default function Welcome() {
    const { auth } = usePage().props;

    return (
        <>
            <Head title="Due — Assignment & Coursework Tracker" />

            <div className="min-h-screen bg-background text-foreground flex flex-col selection:bg-primary selection:text-primary-foreground">
                {/* Top architectural border accent */}
                <div className="h-1 w-full bg-primary" />

                {/* Navigation */}
                <header className="border-b border-border bg-background/80 backdrop-blur-md sticky top-0 z-50">
                    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
                        <Link href="/" className="flex items-center gap-3 group">
                            <div className="size-8 bg-primary text-primary-foreground flex items-center justify-center rounded-none shadow-xs group-hover:opacity-90 transition-opacity">
                                <AppLogoIcon className="size-5" />
                            </div>
                            <span className="font-semibold text-lg tracking-tight flex items-center">
                                due<span className="text-primary font-bold">.</span>
                            </span>
                        </Link>

                        <nav className="flex items-center gap-3">
                            {auth.user ? (
                                <Button asChild variant="default" size="sm" className="rounded-none">
                                    <Link href={dashboard()}>
                                        Dashboard <ArrowRight className="size-4" />
                                    </Link>
                                </Button>
                            ) : (
                                <>
                                    <Button asChild variant="ghost" size="sm" className="rounded-none">
                                        <Link href={login()}>Log in</Link>
                                    </Button>
                                    <Button asChild variant="default" size="sm" className="rounded-none">
                                        <Link href={register()}>
                                            Get Started <ArrowRight className="size-4" />
                                        </Link>
                                    </Button>
                                </>
                            )}
                        </nav>
                    </div>
                </header>

                {/* Hero Section */}
                <main className="flex-1">
                    <section className="relative border-b border-border py-20 md:py-28 overflow-hidden">
                        {/* Subtle background grid pattern */}
                        <div
                            aria-hidden="true"
                            className="absolute inset-0 opacity-[0.03] dark:opacity-[0.07] pointer-events-none"
                            style={{
                                backgroundImage: `linear-gradient(to right, currentColor 1px, transparent 1px), linear-gradient(to bottom, currentColor 1px, transparent 1px)`,
                                backgroundSize: '40px 40px',
                            }}
                        />

                        <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 relative">
                            <div className="flex flex-col items-start gap-6">
                                <Badge variant="outline" className="border-primary/40 bg-primary/10 text-primary py-1 px-3">
                                    <Sparkles className="size-3 text-primary" />
                                    ACADEMIC WORKSPACE
                                </Badge>

                                <h1 className="text-4xl sm:text-6xl font-bold tracking-tight max-w-3xl leading-[1.1]">
                                    Stay ahead of every assignment and deadline<span className="text-primary">.</span>
                                </h1>

                                <p className="text-lg sm:text-xl text-muted-foreground max-w-2xl leading-relaxed">
                                    The focused coursework tracker built for university students. Organize your classes, track upcoming deadlines, keep study notes, and master your academic workload.
                                </p>

                                <div className="flex flex-wrap items-center gap-4 pt-2">
                                    {auth.user ? (
                                        <Button asChild size="lg" className="rounded-none text-base px-8 h-12">
                                            <Link href={dashboard()}>
                                                Go to Dashboard <ArrowRight className="size-5" />
                                            </Link>
                                        </Button>
                                    ) : (
                                        <>
                                            <Button asChild size="lg" className="rounded-none text-base px-8 h-12">
                                                <Link href={register()}>
                                                    Get Started Free <ArrowRight className="size-5" />
                                                </Link>
                                            </Button>
                                            <Button asChild variant="outline" size="lg" className="rounded-none text-base px-8 h-12">
                                                <Link href={login()}>Log in</Link>
                                            </Button>
                                        </>
                                    )}
                                </div>
                            </div>

                            {/* Live Preview Card */}
                            <div className="mt-16 border border-border bg-card p-6 shadow-sm">
                                <div className="flex items-center justify-between pb-4 mb-4 border-b border-border">
                                    <div className="flex items-center gap-2">
                                        <Calendar className="size-4 text-primary" />
                                        <span className="text-sm font-semibold tracking-tight">Active Coursework</span>
                                    </div>
                                    <span className="text-xs text-muted-foreground font-mono">3 Tasks Listed</span>
                                </div>

                                <div className="space-y-3 font-mono text-xs">
                                    <div className="p-3 bg-background border border-border flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                                        <div>
                                            <div className="font-semibold text-foreground text-sm font-sans">Database Systems — Normalization Project</div>
                                            <div className="text-muted-foreground">CS304 • 6 ECTS Credits</div>
                                        </div>
                                        <div className="flex items-center gap-3">
                                            <span className="text-primary font-semibold">Due Today • 4:00 PM</span>
                                            <span className="px-2 py-0.5 bg-primary/10 text-primary border border-primary/20">IN PROGRESS</span>
                                        </div>
                                    </div>

                                    <div className="p-3 bg-background border border-border flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                                        <div>
                                            <div className="font-semibold text-foreground text-sm font-sans">Operating Systems — Memory Management Lab</div>
                                            <div className="text-muted-foreground">CS310 • Prof. Miller</div>
                                        </div>
                                        <div className="flex items-center gap-3">
                                            <span className="text-muted-foreground">Due in 3 days</span>
                                            <span className="px-2 py-0.5 bg-muted text-muted-foreground border border-border">PENDING</span>
                                        </div>
                                    </div>

                                    <div className="p-3 bg-background border border-border flex flex-col sm:flex-row sm:items-center justify-between gap-2 opacity-75">
                                        <div>
                                            <div className="font-semibold text-foreground text-sm font-sans line-through">Algorithms — Problem Set 3</div>
                                            <div className="text-muted-foreground">CS201 • Completed on time</div>
                                        </div>
                                        <div className="flex items-center gap-3">
                                            <span className="text-muted-foreground">Finished</span>
                                            <span className="px-2 py-0.5 bg-background text-foreground border border-border flex items-center gap-1">
                                                <CheckCircle2 className="size-3 text-primary" /> COMPLETED
                                            </span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </section>

                    {/* Features Grid */}
                    <section className="py-20 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                        <div className="mb-12 border-b border-border pb-6 flex flex-col sm:flex-row sm:items-end justify-between gap-4">
                            <div>
                                <p className="font-mono text-xs uppercase tracking-wider text-primary mb-1">
                                    CORE CAPABILITIES
                                </p>
                                <h2 className="text-2xl sm:text-3xl font-semibold tracking-tight">
                                    Everything you need to master your coursework
                                </h2>
                            </div>
                            <span className="font-mono text-xs text-muted-foreground">
                                DESIGNED FOR STUDENTS
                            </span>
                        </div>

                        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                            <Card className="rounded-none border-border bg-card hover:border-primary/50 transition-colors">
                                <CardHeader className="space-y-3">
                                    <div className="size-10 bg-primary/10 border border-primary/20 flex items-center justify-center text-primary rounded-none">
                                        <Clock className="size-5" />
                                    </div>
                                    <Badge variant="outline" className="w-fit text-[10px]">
                                        DEADLINE TRACKING
                                    </Badge>
                                    <CardTitle className="text-lg">Smart Deadlines</CardTitle>
                                </CardHeader>
                                <CardContent>
                                    <CardDescription className="text-sm leading-relaxed">
                                        Never miss a submission. Clear countdowns and urgency alerts (Due Today, Due Soon, Overdue) keep you focused on what matters most.
                                    </CardDescription>
                                </CardContent>
                            </Card>

                            <Card className="rounded-none border-border bg-card hover:border-primary/50 transition-colors">
                                <CardHeader className="space-y-3">
                                    <div className="size-10 bg-primary/10 border border-primary/20 flex items-center justify-center text-primary rounded-none">
                                        <BookOpen className="size-5" />
                                    </div>
                                    <Badge variant="outline" className="w-fit text-[10px]">
                                        COURSE MANAGEMENT
                                    </Badge>
                                    <CardTitle className="text-lg">Classes & Courses</CardTitle>
                                </CardHeader>
                                <CardContent>
                                    <CardDescription className="text-sm leading-relaxed">
                                        Organize coursework by course. Track professor details, contact info, credit hours, and ECTS points in one structured space.
                                    </CardDescription>
                                </CardContent>
                            </Card>

                            <Card className="rounded-none border-border bg-card hover:border-primary/50 transition-colors">
                                <CardHeader className="space-y-3">
                                    <div className="size-10 bg-primary/10 border border-primary/20 flex items-center justify-center text-primary rounded-none">
                                        <FileText className="size-5" />
                                    </div>
                                    <Badge variant="outline" className="w-fit text-[10px]">
                                        ATTACHED CONTEXT
                                    </Badge>
                                    <CardTitle className="text-lg">Assignment Notes</CardTitle>
                                </CardHeader>
                                <CardContent>
                                    <CardDescription className="text-sm leading-relaxed">
                                        Attach research notes, submission requirements, and draft links directly to each assignment to keep all your context together.
                                    </CardDescription>
                                </CardContent>
                            </Card>

                            <Card className="rounded-none border-border bg-card hover:border-primary/50 transition-colors">
                                <CardHeader className="space-y-3">
                                    <div className="size-10 bg-primary/10 border border-primary/20 flex items-center justify-center text-primary rounded-none">
                                        <BarChart3 className="size-5" />
                                    </div>
                                    <Badge variant="outline" className="w-fit text-[10px]">
                                        OVERVIEW
                                    </Badge>
                                    <CardTitle className="text-lg">Workload Insights</CardTitle>
                                </CardHeader>
                                <CardContent>
                                    <CardDescription className="text-sm leading-relaxed">
                                        View real-time workload statistics, upcoming tasks, and completion rates so you can plan your study sessions effectively.
                                    </CardDescription>
                                </CardContent>
                            </Card>
                        </div>
                    </section>

                    {/* Product Value Banner */}
                    <section className="border-t border-border bg-card/40 py-16">
                        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                            <div className="grid grid-cols-2 md:grid-cols-4 gap-6 text-center divide-y md:divide-y-0 md:divide-x divide-border">
                                <div className="p-4">
                                    <span className="font-mono text-2xl sm:text-3xl font-bold text-primary block">
                                        Real-Time
                                    </span>
                                    <span className="text-xs uppercase font-mono tracking-wider text-muted-foreground mt-1 block">
                                        Deadline Countdowns
                                    </span>
                                </div>
                                <div className="p-4">
                                    <span className="font-mono text-2xl sm:text-3xl font-bold text-foreground block">
                                        Organized
                                    </span>
                                    <span className="text-xs uppercase font-mono tracking-wider text-muted-foreground mt-1 block">
                                        All Courses In One Place
                                    </span>
                                </div>
                                <div className="p-4">
                                    <span className="font-mono text-2xl sm:text-3xl font-bold text-foreground block">
                                        Focused
                                    </span>
                                    <span className="text-xs uppercase font-mono tracking-wider text-muted-foreground mt-1 block">
                                        Zero Clutter or Distractions
                                    </span>
                                </div>
                                <div className="p-4">
                                    <span className="font-mono text-2xl sm:text-3xl font-bold text-primary block">
                                        Private
                                    </span>
                                    <span className="text-xs uppercase font-mono tracking-wider text-muted-foreground mt-1 block">
                                        Your Data Belongs To You
                                    </span>
                                </div>
                            </div>
                        </div>
                    </section>

                    {/* Call to action section */}
                    <section className="border-t border-border py-16 bg-background">
                        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center flex flex-col items-center gap-6">
                            <h2 className="text-3xl sm:text-4xl font-bold tracking-tight">
                                Ready to take control of your semester?
                            </h2>
                            <p className="text-muted-foreground max-w-xl text-base sm:text-lg">
                                Join students who use Due to manage deadlines, track assignments, and eliminate academic stress.
                            </p>
                            <Button asChild size="lg" className="rounded-none text-base px-8 h-12">
                                <Link href={auth.user ? dashboard() : register()}>
                                    {auth.user ? 'Go to Dashboard' : 'Create Free Account'} <ArrowRight className="size-5" />
                                </Link>
                            </Button>
                        </div>
                    </section>
                </main>

                {/* Footer */}
                <footer className="border-t border-border py-8 bg-background">
                    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-muted-foreground">
                        <div className="flex items-center gap-2">
                            <CheckSquare className="size-4 text-primary" />
                            <span className="font-semibold text-foreground">due.</span>
                            <span>— Assignment & Coursework Tracker</span>
                        </div>
                        <p className="font-mono">
                            Designed for focus and clarity.
                        </p>
                    </div>
                </footer>
            </div>
        </>
    );
}
