import { Head, Link, useForm } from '@inertiajs/react';
import { useState } from 'react';
import {
    ArrowLeft,
    CheckCircle2,
    CreditCard,
    Lock,
    Shield,
    Sparkles,
    Zap,
} from 'lucide-react';
import AppLogoIcon from '@/components/app-logo-icon';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';

interface CheckoutProps {
    plan: 'basic' | 'premium';
    planName: string;
    interval: 'monthly' | 'annual';
    price: number;
    monthlyEquivalent: number;
    features: string[];
    storageLimit: number;
}

export default function Checkout({
    plan,
    planName,
    interval,
    price,
    monthlyEquivalent,
    features,
}: CheckoutProps) {
    const [submittingStep, setSubmittingStep] = useState<string | null>(null);

    const { data, setData, post, processing, errors } = useForm({
        tier: plan,
        interval,
        cardholder_name: '',
        card_number: '',
        exp_month: '',
        exp_year: '',
        cvc: '',
        postal_code: '',
    });

    // Detect card brand from the card number string
    const detectBrand = (num: string): string => {
        const clean = num.replace(/\D/g, '');
        if (clean.startsWith('4')) return 'VISA';
        if (/^5[1-5]/.test(clean) || /^2(22[1-9]|2[3-9][0-9]|[3-6][0-9]{2}|7[01][0-9]|720)/.test(clean)) return 'MASTERCARD';
        if (/^3[47]/.test(clean)) return 'AMEX';
        if (/^6(011|5|4[4-9])/.test(clean)) return 'DISCOVER';
        return 'GENERIC';
    };

    const cardBrand = detectBrand(data.card_number);

    // Format card number with spaces (#### #### #### ####)
    const handleCardNumberChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const raw = e.target.value.replace(/\D/g, '').slice(0, 16);
        const formatted = raw.replace(/(\d{4})(?=\d)/g, '$1 ');
        setData('card_number', formatted);
    };

    // Format Expiry (MM/YY)
    const handleExpiryChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const raw = e.target.value.replace(/\D/g, '').slice(0, 4);
        let month = raw.slice(0, 2);
        let year = raw.slice(2, 4);

        if (month.length === 2 && parseInt(month, 10) > 12) {
            month = '12';
        }

        setData('exp_month', month);
        setData('exp_year', year);
    };

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();

        // Multi-stage simulated feedback before submitting to Laravel
        setSubmittingStep('Authorizing Card...');
        setTimeout(() => {
            setSubmittingStep('Creating Secure Token...');
            setTimeout(() => {
                setSubmittingStep('Activating Plan...');
                post('/checkout', {
                    onFinish: () => setSubmittingStep(null),
                });
            }, 400);
        }, 400);
    };

    const formattedDisplayNumber = data.card_number
        ? data.card_number + ' •••• •••• •••• ••••'.slice(data.card_number.length)
        : '•••• •••• •••• ••••';

    return (
        <div className="min-h-screen bg-background text-foreground flex flex-col font-sans selection:bg-primary selection:text-primary-foreground">
            <Head title={`Checkout — ${planName} Plan`} />

            {/* Top accent */}
            <div className="h-1 w-full bg-primary" />

            {/* Header */}
            <header className="border-b border-border bg-background/80 backdrop-blur-md sticky top-0 z-50">
                <div className="max-w-6xl mx-auto px-4 sm:px-6 h-16 flex items-center justify-between">
                    <Link href="/pricing" className="inline-flex items-center gap-2 text-xs font-mono uppercase tracking-wider text-muted-foreground hover:text-foreground transition-colors">
                        <ArrowLeft className="size-4" />
                        Back to Plans
                    </Link>

                    <div className="flex items-center gap-2">
                        <div className="size-7 bg-primary text-primary-foreground flex items-center justify-center rounded-none shadow-xs">
                            <AppLogoIcon className="size-4" />
                        </div>
                        <span className="font-semibold tracking-tight text-sm">
                            due<span className="text-primary font-bold">.</span>checkout
                        </span>
                    </div>

                    <div className="flex items-center gap-1.5 text-xs text-muted-foreground font-mono">
                        <Lock className="size-3.5 text-emerald-400" />
                        <span>Mock Sandbox</span>
                    </div>
                </div>
            </header>

            <main className="flex-1 max-w-6xl mx-auto px-4 sm:px-6 py-10 w-full">
                <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
                    {/* Left: Payment Form & Visual Card */}
                    <div className="lg:col-span-7 space-y-6">
                        {/* Visual Card Widget (Zero Radius, High-Tech Look) */}
                        <div className="border border-border bg-gradient-to-br from-zinc-900 via-zinc-950 to-black p-6 rounded-none relative overflow-hidden shadow-md">
                            <div className="absolute top-0 right-0 p-4 opacity-10">
                                <AppLogoIcon className="size-36 text-primary" />
                            </div>

                            <div className="flex items-center justify-between mb-8">
                                <div className="flex items-center gap-2">
                                    <div className="size-7 bg-amber-400/20 border border-amber-400/40 rounded-none flex items-center justify-center">
                                        <div className="size-4 bg-amber-400/40 border border-amber-400/60" />
                                    </div>
                                    <span className="text-[10px] font-mono tracking-widest uppercase text-muted-foreground">
                                        SIMULATED CHIP
                                    </span>
                                </div>
                                <span className="font-mono text-xs font-extrabold tracking-widest text-primary border border-primary/30 px-2 py-0.5 bg-primary/10">
                                    {cardBrand}
                                </span>
                            </div>

                            <div className="font-mono text-lg sm:text-xl tracking-[0.25em] text-foreground font-semibold mb-6 select-none">
                                {formattedDisplayNumber}
                            </div>

                            <div className="flex items-end justify-between text-xs font-mono">
                                <div>
                                    <div className="text-[9px] uppercase tracking-wider text-muted-foreground">
                                        Cardholder Name
                                    </div>
                                    <div className="text-sm font-semibold tracking-wide uppercase truncate max-w-[200px]">
                                        {data.cardholder_name || 'STUDENT NAME'}
                                    </div>
                                </div>

                                <div className="text-right">
                                    <div className="text-[9px] uppercase tracking-wider text-muted-foreground">
                                        Expires
                                    </div>
                                    <div className="text-sm font-semibold tracking-wider">
                                        {data.exp_month && data.exp_year
                                            ? `${data.exp_month}/${data.exp_year}`
                                            : 'MM/YY'}
                                    </div>
                                </div>
                            </div>
                        </div>

                        {/* Payment Inputs Form */}
                        <Card className="rounded-none border-border bg-card">
                            <CardHeader className="pb-4">
                                <div className="flex items-center gap-2">
                                    <CreditCard className="size-5 text-primary" />
                                    <CardTitle className="text-lg font-bold tracking-tight">
                                        Payment Method
                                    </CardTitle>
                                </div>
                                <CardDescription className="text-xs">
                                    Enter test credit card information. No real financial charges occur.
                                </CardDescription>
                            </CardHeader>

                            <form onSubmit={handleSubmit}>
                                <CardContent className="space-y-4">
                                    {/* Cardholder Name */}
                                    <div className="space-y-1.5">
                                        <Label htmlFor="cardholder_name" className="text-xs font-mono uppercase tracking-wider">
                                            Cardholder Name
                                        </Label>
                                        <Input
                                            id="cardholder_name"
                                            name="cardholder_name"
                                            value={data.cardholder_name}
                                            onChange={(e) => setData('cardholder_name', e.target.value)}
                                            placeholder="Jane Doe"
                                            required
                                            className="rounded-none font-mono text-sm"
                                        />
                                        {errors.cardholder_name && (
                                            <p className="text-xs text-destructive">{errors.cardholder_name}</p>
                                        )}
                                    </div>

                                    {/* Card Number */}
                                    <div className="space-y-1.5">
                                        <div className="flex items-center justify-between">
                                            <Label htmlFor="card_number" className="text-xs font-mono uppercase tracking-wider">
                                                Card Number
                                            </Label>
                                            <span className="text-[10px] font-mono text-muted-foreground">
                                                Test: Any 16 digits (e.g. 4242 4242...)
                                            </span>
                                        </div>
                                        <Input
                                            id="card_number"
                                            name="card_number"
                                            value={data.card_number}
                                            onChange={handleCardNumberChange}
                                            placeholder="4242 4242 4242 4242"
                                            required
                                            className="rounded-none font-mono text-sm tracking-wider"
                                        />
                                        {errors.card_number && (
                                            <p className="text-xs text-destructive">{errors.card_number}</p>
                                        )}
                                    </div>

                                    {/* Expiry & CVC & Zip Grid */}
                                    <div className="grid grid-cols-3 gap-3">
                                        <div className="space-y-1.5">
                                            <Label htmlFor="expiry" className="text-xs font-mono uppercase tracking-wider">
                                                Expires (MM/YY)
                                            </Label>
                                            <Input
                                                id="expiry"
                                                name="expiry"
                                                value={
                                                    data.exp_month
                                                        ? `${data.exp_month}${data.exp_year ? `/${data.exp_year}` : ''}`
                                                        : ''
                                                }
                                                onChange={handleExpiryChange}
                                                placeholder="12/28"
                                                required
                                                className="rounded-none font-mono text-sm text-center"
                                            />
                                            {(errors.exp_month || errors.exp_year) && (
                                                <p className="text-xs text-destructive">Invalid expiry</p>
                                            )}
                                        </div>

                                        <div className="space-y-1.5">
                                            <Label htmlFor="cvc" className="text-xs font-mono uppercase tracking-wider">
                                                CVC / CVV
                                            </Label>
                                            <Input
                                                id="cvc"
                                                name="cvc"
                                                value={data.cvc}
                                                onChange={(e) => setData('cvc', e.target.value.replace(/\D/g, '').slice(0, 4))}
                                                placeholder="123"
                                                required
                                                className="rounded-none font-mono text-sm text-center"
                                            />
                                            {errors.cvc && (
                                                <p className="text-xs text-destructive">{errors.cvc}</p>
                                            )}
                                        </div>

                                        <div className="space-y-1.5">
                                            <Label htmlFor="postal_code" className="text-xs font-mono uppercase tracking-wider">
                                                Postal Code
                                            </Label>
                                            <Input
                                                id="postal_code"
                                                name="postal_code"
                                                value={data.postal_code}
                                                onChange={(e) => setData('postal_code', e.target.value)}
                                                placeholder="90210"
                                                className="rounded-none font-mono text-sm text-center"
                                            />
                                            {errors.postal_code && (
                                                <p className="text-xs text-destructive">{errors.postal_code}</p>
                                            )}
                                        </div>
                                    </div>
                                </CardContent>

                                <CardFooter className="pt-2 pb-6 flex flex-col gap-3">
                                    <Button
                                        type="submit"
                                        disabled={processing || submittingStep !== null}
                                        className="w-full rounded-none font-semibold text-sm h-11 tracking-wide uppercase font-mono cursor-pointer"
                                    >
                                        {submittingStep ? (
                                            <span className="flex items-center gap-2">
                                                <span className="size-2 rounded-none bg-primary-foreground animate-ping" />
                                                {submittingStep}
                                            </span>
                                        ) : (
                                            <span>
                                                Confirm & Subscribe (${price} {interval === 'annual' ? '/yr' : '/mo'})
                                            </span>
                                        )}
                                    </Button>

                                    <p className="text-[11px] text-center text-muted-foreground flex items-center justify-center gap-1">
                                        <Shield className="size-3 text-emerald-400 shrink-0" />
                                        Simulated Sandbox: Immediate instant activation with 0 real charges.
                                    </p>
                                </CardFooter>
                            </form>
                        </Card>
                    </div>

                    {/* Right: Order Summary */}
                    <div className="lg:col-span-5 space-y-6">
                        <Card className="rounded-none border-border bg-card">
                            <CardHeader className="pb-4 border-b border-border">
                                <div className="flex items-center justify-between">
                                    <CardTitle className="text-lg font-bold tracking-tight">
                                        Order Summary
                                    </CardTitle>
                                    <Badge variant="outline" className="rounded-none border-primary text-primary font-mono text-[10px] uppercase">
                                        {interval} billing
                                    </Badge>
                                </div>
                            </CardHeader>

                            <CardContent className="space-y-4 pt-4">
                                <div className="flex items-start justify-between pb-4 border-b border-border">
                                    <div>
                                        <div className="font-semibold text-base">{planName} Tier Plan</div>
                                        <div className="text-xs text-muted-foreground mt-0.5">
                                            {interval === 'annual' ? 'Billed annually ($' + price + '/year)' : 'Billed monthly'}
                                        </div>
                                    </div>
                                    <div className="text-right">
                                        <div className="font-mono font-bold text-lg">${price}</div>
                                        {interval === 'annual' && (
                                            <div className="text-[10px] text-muted-foreground font-mono">
                                                ~${monthlyEquivalent}/mo
                                            </div>
                                        )}
                                    </div>
                                </div>

                                <div className="space-y-2 text-xs">
                                    <div className="flex justify-between text-muted-foreground">
                                        <span>Subtotal</span>
                                        <span className="font-mono text-foreground">${price}</span>
                                    </div>
                                    <div className="flex justify-between text-muted-foreground">
                                        <span>Simulated Taxes (0%)</span>
                                        <span className="font-mono text-foreground">$0.00</span>
                                    </div>
                                    <div className="flex justify-between font-semibold text-sm pt-2 border-t border-border">
                                        <span>Total Due Today</span>
                                        <span className="font-mono text-primary text-base">${price}</span>
                                    </div>
                                </div>

                                <div className="pt-4 border-t border-border space-y-2.5">
                                    <div className="text-xs font-mono uppercase tracking-wider text-muted-foreground">
                                        Features you will unlock:
                                    </div>
                                    <ul className="space-y-2 text-xs">
                                        {plan === 'basic' && (
                                            <>
                                                <li className="flex items-center gap-2">
                                                    <CheckCircle2 className="size-3.5 text-primary shrink-0" />
                                                    <span>Class & assignment study file uploads</span>
                                                </li>
                                                <li className="flex items-center gap-2">
                                                    <CheckCircle2 className="size-3.5 text-primary shrink-0" />
                                                    <span>In-browser PDF reader & image lightbox</span>
                                                </li>
                                                <li className="flex items-center gap-2">
                                                    <CheckCircle2 className="size-3.5 text-primary shrink-0" />
                                                    <span>500 MB cloud storage quota</span>
                                                </li>
                                            </>
                                        )}
                                        {plan === 'premium' && (
                                            <>
                                                <li className="flex items-center gap-2">
                                                    <CheckCircle2 className="size-3.5 text-primary shrink-0" />
                                                    <span>Everything in Scholar plan</span>
                                                </li>
                                                <li className="flex items-center gap-2">
                                                    <CheckCircle2 className="size-3.5 text-primary shrink-0" />
                                                    <span>Gemini AI Study Assistant per assignment</span>
                                                </li>
                                                <li className="flex items-center gap-2">
                                                    <CheckCircle2 className="size-3.5 text-primary shrink-0" />
                                                    <span>AI reads your notes & uploaded files as context</span>
                                                </li>
                                                <li className="flex items-center gap-2">
                                                    <CheckCircle2 className="size-3.5 text-primary shrink-0" />
                                                    <span>5 GB total cloud storage quota</span>
                                                </li>
                                            </>
                                        )}
                                    </ul>
                                </div>
                            </CardContent>
                        </Card>
                    </div>
                </div>
            </main>
        </div>
    );
}
