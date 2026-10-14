import { Head, Link, router, usePage } from '@inertiajs/react';
import { useState } from 'react';
import {
    ArrowLeft,
    ArrowRight,
    Check,
    Zap,
} from 'lucide-react';
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

    const handleBack = () => {
        if (typeof window !== 'undefined') {
            const referrer = document.referrer;
            const isFromSameOrigin = referrer && referrer.startsWith(window.location.origin);
            const isFromRegister = referrer && referrer.includes('/register');

            if (isFromSameOrigin && !isFromRegister && window.history.length > 1) {
                window.history.back();
                return;
            }
        }

        router.visit(auth?.user ? '/dashboard' : '/');
    };

    return (
        <div className="min-h-screen bg-background text-foreground flex flex-col selection:bg-primary selection:text-primary-foreground font-sans">
            <Head title="Plans & Pricing — Due" />

            {/* Back Navigation (Non-primary styling) */}
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-8 w-full">
                <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    onClick={handleBack}
                    className="rounded-none border-border text-muted-foreground hover:text-foreground hover:bg-muted cursor-pointer font-mono text-xs inline-flex items-center gap-2 shadow-xs"
                >
                    <ArrowLeft className="size-3.5" />
                    <span>Back</span>
                </Button>
            </div>

            {/* Hero Section */}
            <main className="flex-1 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-6 pb-20 w-full">
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
                                        tier.key === 'free' ? (
                                            <Button
                                                asChild
                                                variant="outline"
                                                className="w-full rounded-none border-border hover:bg-muted"
                                            >
                                                <Link href="/dashboard">
                                                    Continue with Free Plan
                                                </Link>
                                            </Button>
                                        ) : (
                                            <Button
                                                disabled
                                                className="w-full rounded-none bg-muted text-muted-foreground cursor-not-allowed"
                                            >
                                                Current Active Plan
                                            </Button>
                                        )
                                    ) : tier.key === 'free' ? (
                                        <Button
                                            asChild
                                            variant="outline"
                                            className="w-full rounded-none border-border hover:bg-muted"
                                        >
                                            <Link href={auth?.user ? '/dashboard' : '/register'}>
                                                {auth?.user ? 'Continue Free' : 'Get Started Free'}
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
                                                    auth?.user
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
            </main>
        </div>
    );
}
