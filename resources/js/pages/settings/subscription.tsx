import { Head, Link, useForm } from '@inertiajs/react';
import { useState } from 'react';
import {
    AlertTriangle,
    ArrowUpRight,
    CheckCircle2,
    CreditCard,
    HardDrive,
    Shield,
    Sparkles,
    Zap,
} from 'lucide-react';
import Heading from '@/components/heading';
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

interface SubscriptionData {
    id: number;
    tier: 'basic' | 'premium';
    status: string;
    price: number;
    interval: 'monthly' | 'annual';
    card_brand: string;
    card_last_four: string;
    starts_at: string;
    ends_at: string | null;
}

interface SubscriptionSettingsProps {
    currentTier: 'free' | 'basic' | 'premium';
    tierLabel: string;
    isSuperAdmin: boolean;
    subscription: SubscriptionData | null;
    storageUsedBytes: number;
    storageLimitBytes: number;
    storageFormatted: {
        used: string;
        limit: string;
        percentage: number;
    };
    expiresAt: string | null;
}

export default function SubscriptionSettings({
    currentTier,
    tierLabel,
    isSuperAdmin,
    subscription,
    storageFormatted,
    expiresAt,
}: SubscriptionSettingsProps) {
    const [cancelModalOpen, setCancelModalOpen] = useState(false);
    const { post, processing } = useForm({});

    const handleCancel = () => {
        post('/settings/subscription/cancel', {
            onSuccess: () => setCancelModalOpen(false),
        });
    };

    return (
        <>
            <Head title="Subscription & Plan settings" />

            <h1 className="sr-only">Subscription & Plan settings</h1>

            <div className="space-y-6">
                <Heading
                    variant="small"
                    title="Subscription & Plan"
                    description="View your active tier, manage your subscription, and monitor storage quota usage."
                />

                {/* Plan Overview Card (Zero Radius) */}
                <div className="border border-border bg-card p-5 space-y-4 rounded-none">
                    <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-4 border-b border-border">
                        <div className="space-y-1">
                            <div className="flex items-center gap-2">
                                <span className="text-sm font-semibold font-mono uppercase tracking-wide">
                                    Current Plan
                                </span>
                                <Badge
                                    variant="outline"
                                    className={`rounded-none font-mono text-xs font-semibold ${
                                        currentTier === 'premium'
                                            ? 'border-primary text-primary bg-primary/10'
                                            : currentTier === 'basic'
                                              ? 'border-blue-400 text-blue-400 bg-blue-400/10'
                                              : 'border-muted-foreground text-muted-foreground'
                                    }`}
                                >
                                    {isSuperAdmin ? 'SUPER ADMIN (UNLIMITED)' : `${tierLabel.toUpperCase()} TIER`}
                                </Badge>
                            </div>
                            <p className="text-xs text-muted-foreground">
                                {currentTier === 'free' && 'Core assignment and deadline tracking without file storage or AI.'}
                                {currentTier === 'basic' && 'Scholar plan with class & assignment file uploads and in-browser previewers.'}
                                {currentTier === 'premium' && 'Genius plan with full Gemini AI study assistant and 5 GB storage.'}
                                {isSuperAdmin && 'System-level administrator account with unrestricted access to all features.'}
                            </p>
                        </div>

                        <div>
                            {currentTier === 'free' ? (
                                <Button asChild size="sm" className="rounded-none cursor-pointer">
                                    <Link href="/pricing">
                                        <span>Upgrade Plan</span>
                                        <ArrowUpRight className="size-3.5 ml-1" />
                                    </Link>
                                </Button>
                            ) : (
                                <Button asChild variant="outline" size="sm" className="rounded-none border-border hover:bg-muted cursor-pointer">
                                    <Link href="/pricing">
                                        <span>Change Plan</span>
                                    </Link>
                                </Button>
                            )}
                        </div>
                    </div>

                    {/* Subscription & Billing Details (if paid tier) */}
                    {subscription && (
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs font-mono pt-1">
                            <div className="space-y-1 p-3 bg-muted/30 border border-border">
                                <span className="text-[10px] uppercase text-muted-foreground">Billing Rate</span>
                                <div className="font-semibold text-foreground text-sm">
                                    ${subscription.price} / {subscription.interval}
                                </div>
                                {expiresAt && (
                                    <div className="text-[11px] text-muted-foreground">
                                        Renews on {new Date(expiresAt).toLocaleDateString()}
                                    </div>
                                )}
                            </div>

                            <div className="space-y-1 p-3 bg-muted/30 border border-border">
                                <span className="text-[10px] uppercase text-muted-foreground">Payment Method On File</span>
                                <div className="font-semibold text-foreground flex items-center gap-2 text-sm">
                                    <CreditCard className="size-4 text-primary" />
                                    <span className="uppercase">{subscription.card_brand}</span>
                                    <span>•••• {subscription.card_last_four}</span>
                                </div>
                                <div className="text-[11px] text-muted-foreground">
                                    Mock Sandbox Credit Card
                                </div>
                            </div>
                        </div>
                    )}
                </div>

                {/* Cloud Storage Quota Card */}
                <div className="border border-border bg-card p-5 space-y-4 rounded-none">
                    <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                            <HardDrive className="size-4 text-primary" />
                            <h3 className="text-sm font-semibold font-mono uppercase tracking-wide">
                                Storage Quota
                            </h3>
                        </div>
                        <span className="font-mono text-xs text-muted-foreground">
                            {storageFormatted.used} of {storageFormatted.limit} ({storageFormatted.percentage}%)
                        </span>
                    </div>

                    {/* Architectural Progress Meter */}
                    <div className="h-2 w-full bg-muted border border-border rounded-none overflow-hidden">
                        <div
                            className={`h-full transition-all duration-500 ${
                                storageFormatted.percentage > 85 ? 'bg-destructive' : 'bg-primary'
                            }`}
                            style={{ width: `${Math.max(2, storageFormatted.percentage)}%` }}
                        />
                    </div>

                    <p className="text-xs text-muted-foreground">
                        {currentTier === 'free'
                            ? 'Free accounts do not have storage allocation. Upgrade to Scholar (500 MB) or Genius (5 GB) to upload class slides, PDFs, and assignment attachments.'
                            : `You have used ${storageFormatted.used} of your ${storageFormatted.limit} cloud storage capacity for PDFs, study slides, and assignment files.`}
                    </p>
                </div>

                {/* Cancel Plan Section (Only if paid) */}
                {subscription && currentTier !== 'free' && (
                    <div className="border border-destructive/30 bg-destructive/5 p-5 space-y-3 rounded-none">
                        <div className="flex items-center gap-2 text-destructive">
                            <AlertTriangle className="size-4" />
                            <h3 className="text-sm font-semibold font-mono uppercase tracking-wide">
                                Cancel Subscription
                            </h3>
                        </div>
                        <p className="text-xs text-muted-foreground">
                            Cancelling will immediately return your account to the Free tier. You will retain your assignments, but access to uploaded resources and the Gemini AI assistant will be locked.
                        </p>
                        <Button
                            type="button"
                            variant="destructive"
                            size="sm"
                            onClick={() => setCancelModalOpen(true)}
                            className="rounded-none cursor-pointer"
                        >
                            Cancel Subscription
                        </Button>
                    </div>
                )}
            </div>

            {/* Cancel Confirmation Dialog (Strict Zero Radius) */}
            <Dialog open={cancelModalOpen} onOpenChange={setCancelModalOpen}>
                <DialogContent className="rounded-none border-border bg-card max-w-md">
                    <DialogHeader>
                        <DialogTitle className="text-base font-bold tracking-tight">
                            Confirm Subscription Cancellation
                        </DialogTitle>
                        <DialogDescription className="text-xs text-muted-foreground">
                            Are you sure you want to cancel your {tierLabel} plan? Your account will return to the Free plan and access to study resources & Gemini AI will be paused.
                        </DialogDescription>
                    </DialogHeader>

                    <DialogFooter className="gap-2 sm:gap-0">
                        <Button
                            type="button"
                            variant="outline"
                            size="sm"
                            onClick={() => setCancelModalOpen(false)}
                            className="rounded-none border-border"
                        >
                            Keep Subscription
                        </Button>
                        <Button
                            type="button"
                            variant="destructive"
                            size="sm"
                            disabled={processing}
                            onClick={handleCancel}
                            className="rounded-none"
                        >
                            {processing ? 'Cancelling...' : 'Confirm Cancellation'}
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </>
    );
}

SubscriptionSettings.layout = {
    breadcrumbs: [
        {
            title: 'Subscription & Plan',
            href: '/settings/subscription',
        },
    ],
};
