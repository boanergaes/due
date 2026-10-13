import { Head, Link, usePage } from '@inertiajs/react';
import { useState } from 'react';
import {
    ArrowRight,
    Check,
    CreditCard,
    FileText,
    HelpCircle,
    ShieldCheck,
    Sparkles,
    Zap,
} from 'lucide-react';
import AppLogoIcon from '@/components/app-logo-icon';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';

interface PlanTier {
    key: string;
    name: string;
    tagline: string;
    monthlyPrice: number;
    annualPrice: number;
    popular?: boolean;
    features: string[];
    storageQuota: string;
    fileUploads: boolean;
    aiAssistant: boolean;
}

interface PricingProps {
    currentTier: string;
    isSuperAdmin: boolean;
    tiers: PlanTier[];
}

export default function Pricing({ currentTier, isSuperAdmin, tiers }: PricingProps) {
    const { auth } = usePage<{ auth: { user: { id: number; name: string } | null } }>().props;
    const [interval, setInterval] = useState<'monthly' | 'annual'>('monthly');

    return (
        <div className="min-h-screen bg-background text-foreground flex flex-col selection:bg-primary selection:text-primary-foreground font-sans">
            <Head title="Plans & Pricing — Due" />

            {/* Top architectural border accent */}
            <div className="h-1 w-full bg-primary" />

            {/* Navigation Header */}
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
                            <>
                                <Button asChild variant="ghost" size="sm" className="rounded-none">
                                    <Link href="/dashboard">Dashboard</Link>
                                </Button>
                                <Button asChild variant="outline" size="sm" className="rounded-none border-border">
                                    <Link href="/settings/subscription">My Plan</Link>
                                </Button>
                            </>
                        ) : (
                            <>
                                <Button asChild variant="ghost" size="sm" className="rounded-none">
                                    <Link href="/login">Log in</Link>
                                </Button>
                                <Button asChild variant="default" size="sm" className="rounded-none">
                                    <Link href="/register">Get Started</Link>
                                </Button>
                            </>
                        )}
                    </nav>
                </div>
            </header>

            {/* Hero Section */}
            <main className="flex-1 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16 w-full">
                <div className="text-center max-w-3xl mx-auto space-y-4 mb-12">
                    <div className="inline-flex items-center gap-2 px-3 py-1 bg-muted border border-border text-xs font-mono tracking-wider uppercase text-muted-foreground">
                        <Zap className="size-3.5 text-primary" />
                        Academic Subscriptions & Upgrades
                    </div>
                    <h1 className="text-4xl sm:text-5xl font-bold tracking-tight">
                        Power up your semester with study resources & Gemini AI
                    </h1>
                    <p className="text-muted-foreground text-base sm:text-lg">
                        Start completely free, or unlock in-browser PDF/image study resources and our context-aware assignment copilot.
                    </p>

                    {/* Monthly / Annual Toggle (Zero Radius) */}
                    <div className="pt-4 flex items-center justify-center">
                        <div className="inline-flex items-center border border-border bg-card p-1">
                            <button
                                type="button"
                                onClick={() => setInterval('monthly')}
                                className={`px-4 py-1.5 text-xs font-mono uppercase tracking-wider transition-all cursor-pointer ${
                                    interval === 'monthly'
                                        ? 'bg-primary text-primary-foreground font-semibold shadow-xs'
                                        : 'text-muted-foreground hover:text-foreground'
                                }`}
                            >
                                Monthly Billing
                            </button>
                            <button
                                type="button"
                                onClick={() => setInterval('annual')}
                                className={`px-4 py-1.5 text-xs font-mono uppercase tracking-wider transition-all flex items-center gap-1.5 cursor-pointer ${
                                    interval === 'annual'
                                        ? 'bg-primary text-primary-foreground font-semibold shadow-xs'
                                        : 'text-muted-foreground hover:text-foreground'
                                }`}
                            >
                                Annual Billing
                                <span className="text-[10px] bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 px-1 py-0.5">
                                    Save ~17%
                                </span>
                            </button>
                        </div>
                    </div>
                </div>

                {/* Plan Cards Grid */}
                <div className="grid grid-cols-1 md:grid-cols-3 gap-8 items-stretch">
                    {tiers.map((tier) => {
                        const isCurrent = currentTier === tier.key && !isSuperAdmin;
                        const price = interval === 'annual' ? tier.annualPrice : tier.monthlyPrice;
                        const periodLabel = interval === 'annual' ? '/ year' : '/ month';

                        return (
                            <Card
                                key={tier.key}
                                className={`rounded-none flex flex-col justify-between transition-all relative ${
                                    tier.popular
                                        ? 'border-primary ring-1 ring-primary bg-card/90 shadow-md'
                                        : 'border-border bg-card hover:border-zinc-500'
                                }`}
                            >
                                {tier.popular && (
                                    <div className="absolute -top-3 left-1/2 -translate-x-1/2 bg-primary text-primary-foreground px-3 py-0.5 text-[11px] font-mono tracking-wider uppercase font-semibold">
                                        Most Popular
                                    </div>
                                )}

                                <div>
                                    <CardHeader className="space-y-2 pb-4">
                                        <div className="flex items-center justify-between">
                                            <CardTitle className="text-2xl font-bold tracking-tight">
                                                {tier.name}
                                            </CardTitle>
                                            {isCurrent && (
                                                <Badge variant="outline" className="rounded-none border-primary text-primary font-mono text-[10px]">
                                                    Current Plan
                                                </Badge>
                                            )}
                                        </div>
                                        <CardDescription className="text-xs text-muted-foreground min-h-[36px]">
                                            {tier.tagline}
                                        </CardDescription>

                                        {/* Price */}
                                        <div className="pt-4 pb-2 border-b border-border">
                                            <div className="flex items-baseline gap-1">
                                                <span className="text-4xl font-extrabold tracking-tight font-mono">
                                                    ${price}
                                                </span>
                                                <span className="text-xs text-muted-foreground font-mono">
                                                    {periodLabel}
                                                </span>
                                            </div>
                                            {interval === 'annual' && tier.annualPrice > 0 && (
                                                <p className="text-[11px] text-muted-foreground font-mono mt-1">
                                                    Equivalent to ${(tier.annualPrice / 12).toFixed(2)}/mo
                                                </p>
                                            )}
                                        </div>
                                    </CardHeader>

                                    <CardContent className="space-y-4">
                                        <div className="text-xs font-mono uppercase tracking-wider text-muted-foreground">
                                            Included Features:
                                        </div>
                                        <ul className="space-y-2.5 text-sm">
                                            {tier.features.map((feature, i) => (
                                                <li key={i} className="flex items-start gap-2.5">
                                                    <div className="size-4 shrink-0 rounded-none bg-primary/10 text-primary flex items-center justify-center mt-0.5">
                                                        <Check className="size-3" />
                                                    </div>
                                                    <span className="text-xs text-foreground/90 leading-tight">
                                                        {feature}
                                                    </span>
                                                </li>
                                            ))}
                                        </ul>
                                    </CardContent>
                                </div>

                                <CardFooter className="pt-6 border-t border-border">
                                    {isCurrent ? (
                                        <Button
                                            disabled
                                            className="w-full rounded-none bg-muted text-muted-foreground cursor-not-allowed"
                                        >
                                            Current Active Plan
                                        </Button>
                                    ) : tier.key === 'free' ? (
                                        <Button
                                            asChild
                                            variant="outline"
                                            className="w-full rounded-none border-border hover:bg-muted"
                                        >
                                            <Link href={auth.user ? '/dashboard' : '/register'}>
                                                {auth.user ? 'Continue Free' : 'Get Started Free'}
                                            </Link>
                                        </Button>
                                    ) : (
                                        <Button
                                            asChild
                                            variant={tier.popular ? 'default' : 'outline'}
                                            className="w-full rounded-none group cursor-pointer"
                                        >
                                            <Link
                                                href={
                                                    auth.user
                                                        ? `/checkout?plan=${tier.key}&interval=${interval}`
                                                        : `/register?redirect=/checkout?plan=${tier.key}`
                                                }
                                            >
                                                <span>Upgrade to {tier.name}</span>
                                                <ArrowRight className="size-4 ml-1.5 transition-transform group-hover:translate-x-1" />
                                            </Link>
                                        </Button>
                                    )}
                                </CardFooter>
                            </Card>
                        );
                    })}
                </div>

                {/* Simulated Payment Notice Banner */}
                <div className="mt-16 border border-border bg-card p-6 rounded-none flex flex-col md:flex-row items-center gap-4 justify-between">
                    <div className="flex items-start gap-3">
                        <div className="size-10 bg-muted text-primary flex items-center justify-center shrink-0 border border-border">
                            <CreditCard className="size-5" />
                        </div>
                        <div>
                            <h3 className="font-semibold text-sm">Simulated Sandbox Checkout</h3>
                            <p className="text-xs text-muted-foreground mt-0.5">
                                Real payment charges are mocked for learning and internship evaluation. You can enter mock card details to experience end-to-end tokenized subscription provisioning!
                            </p>
                        </div>
                    </div>
                    <div className="flex items-center gap-2 shrink-0">
                        <Badge variant="outline" className="rounded-none border-emerald-500/40 text-emerald-400 font-mono text-[11px] px-2.5 py-1">
                            <ShieldCheck className="size-3.5 mr-1 text-emerald-400 inline" />
                            Zero Risk Sandbox
                        </Badge>
                    </div>
                </div>

                {/* Feature Comparison Matrix */}
                <div className="mt-20">
                    <div className="text-center max-w-2xl mx-auto mb-10">
                        <h2 className="text-2xl font-bold tracking-tight">Detailed Feature Breakdown</h2>
                        <p className="text-xs text-muted-foreground mt-1">
                            Everything you need to know about capabilities per tier.
                        </p>
                    </div>

                    <div className="border border-border overflow-x-auto bg-card">
                        <table className="w-full text-left text-xs border-collapse">
                            <thead>
                                <tr className="border-b border-border bg-muted/40 font-mono">
                                    <th className="py-3 px-4 font-semibold">Capability</th>
                                    <th className="py-3 px-4 font-semibold text-center">Free</th>
                                    <th className="py-3 px-4 font-semibold text-center text-primary">Scholar</th>
                                    <th className="py-3 px-4 font-semibold text-center text-primary">Genius</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-border">
                                <tr>
                                    <td className="py-3 px-4 font-medium">Courses & Assignment Tracking</td>
                                    <td className="py-3 px-4 text-center font-mono text-emerald-400">Unlimited</td>
                                    <td className="py-3 px-4 text-center font-mono text-emerald-400">Unlimited</td>
                                    <td className="py-3 px-4 text-center font-mono text-emerald-400">Unlimited</td>
                                </tr>
                                <tr>
                                    <td className="py-3 px-4 font-medium">Urgency Engine & Overdue Alerts</td>
                                    <td className="py-3 px-4 text-center font-mono text-emerald-400">Included</td>
                                    <td className="py-3 px-4 text-center font-mono text-emerald-400">Included</td>
                                    <td className="py-3 px-4 text-center font-mono text-emerald-400">Included</td>
                                </tr>
                                <tr>
                                    <td className="py-3 px-4 font-medium">Class & Assignment File Uploads</td>
                                    <td className="py-3 px-4 text-center text-muted-foreground font-mono">—</td>
                                    <td className="py-3 px-4 text-center font-mono text-emerald-400">Included</td>
                                    <td className="py-3 px-4 text-center font-mono text-emerald-400">Included</td>
                                </tr>
                                <tr>
                                    <td className="py-3 px-4 font-medium">Total Cloud Storage Quota</td>
                                    <td className="py-3 px-4 text-center font-mono text-muted-foreground">0 MB</td>
                                    <td className="py-3 px-4 text-center font-mono font-semibold">500 MB</td>
                                    <td className="py-3 px-4 text-center font-mono font-semibold text-primary">5 GB</td>
                                </tr>
                                <tr>
                                    <td className="py-3 px-4 font-medium">Max Single File Size</td>
                                    <td className="py-3 px-4 text-center font-mono text-muted-foreground">—</td>
                                    <td className="py-3 px-4 text-center font-mono">25 MB</td>
                                    <td className="py-3 px-4 text-center font-mono">100 MB</td>
                                </tr>
                                <tr>
                                    <td className="py-3 px-4 font-medium">In-Browser PDF & Image Lightbox</td>
                                    <td className="py-3 px-4 text-center text-muted-foreground font-mono">—</td>
                                    <td className="py-3 px-4 text-center font-mono text-emerald-400">Included</td>
                                    <td className="py-3 px-4 text-center font-mono text-emerald-400">Included</td>
                                </tr>
                                <tr>
                                    <td className="py-3 px-4 font-medium">Gemini AI Study Copilot</td>
                                    <td className="py-3 px-4 text-center text-muted-foreground font-mono">—</td>
                                    <td className="py-3 px-4 text-center text-muted-foreground font-mono">—</td>
                                    <td className="py-3 px-4 text-center font-mono text-emerald-400">Unlimited</td>
                                </tr>
                                <tr>
                                    <td className="py-3 px-4 font-medium">AI Reads Notes & File Context</td>
                                    <td className="py-3 px-4 text-center text-muted-foreground font-mono">—</td>
                                    <td className="py-3 px-4 text-center text-muted-foreground font-mono">—</td>
                                    <td className="py-3 px-4 text-center font-mono text-emerald-400">Included</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </main>

            {/* Footer */}
            <footer className="border-t border-border py-8 bg-card text-muted-foreground text-xs mt-20">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex flex-col sm:flex-row items-center justify-between gap-4">
                    <div className="flex items-center gap-2">
                        <div className="size-5 bg-primary text-primary-foreground flex items-center justify-center rounded-none text-xs font-bold">
                            d
                        </div>
                        <span>Due Academic Platform — Modern Full-Stack Architecture</span>
                    </div>
                    <div className="flex items-center gap-6">
                        <Link href="/pricing" className="hover:text-foreground transition-colors">
                            Pricing
                        </Link>
                        <Link href="/dashboard" className="hover:text-foreground transition-colors">
                            Dashboard
                        </Link>
                    </div>
                </div>
            </footer>
        </div>
    );
}
