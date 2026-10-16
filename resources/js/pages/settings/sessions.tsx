import { Head, router, useForm, usePage } from '@inertiajs/react';
import {
    Check,
    CheckCircle2,
    Copy,
    Key,
    Laptop,
    LogOut,
    Shield,
    Smartphone,
    Sparkles,
    Trash2,
} from 'lucide-react';
import { useMemo, useState } from 'react';
import Heading from '@/components/heading';
import InputError from '@/components/input-error';
import PasswordInput from '@/components/password-input';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Button } from '@/components/ui/button';
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
} from '@/components/ui/dialog';
import { Label } from '@/components/ui/label';
import { edit as editSessions } from '@/routes/sessions';

interface DeviceSession {
    id: string;
    agent: {
        is_desktop: boolean;
        platform: string;
        browser: string;
    };
    ip_address: string | null;
    is_current_device: boolean;
    last_active: string;
}

interface DeviceToken {
    id: number;
    name: string;
    type?: 'mobile';
    is_mobile: boolean;
    subscription_tier: string;
    subscription_tier_label: string;
    token_masked?: string | null;
    token_full?: string | null;
    abilities?: string[];
    last_used_at: string;
    created_at: string;
}

interface UnifiedSessionItem {
    id: string;
    device_token_id?: number;
    name: string;
    type: 'browser' | 'mobile';
    is_current_device: boolean;
    subscription_tier: string;
    subscription_tier_label: string;
    token_masked?: string | null;
    token_full?: string | null;
    ip_address: string | null;
    last_active: string;
    created_at?: string | null;
    agent?: {
        is_desktop: boolean;
        platform: string;
        browser: string;
    };
}

interface PageProps {
    [key: string]: unknown;
    sessions?: DeviceSession[];
    devices?: DeviceToken[];
    allSessions?: UnifiedSessionItem[];
    sessionDriver?: string;
    flash?: {
        success?: string | null;
        error?: string | null;
    };
    errors: Record<string, string>;
}

export default function Sessions({
    sessions = [],
    devices = [],
    allSessions = [],
    sessionDriver,
}: PageProps) {
    const { flash, errors } = usePage<PageProps>().props;
    const [confirmingLogout, setConfirmingLogout] = useState(false);
    const [revokingId, setRevokingId] = useState<string | number | null>(null);
    const [revokingAllDevices, setRevokingAllDevices] = useState(false);
    const [copiedTokenId, setCopiedTokenId] = useState<string | number | null>(null);

    const {
        data,
        setData,
        delete: destroyOthers,
        processing,
        reset,
        clearErrors,
        errors: formErrors,
    } = useForm({
        password: '',
    });

    // Consolidate all sessions and devices into one unified list if allSessions is not provided directly
    const items: UnifiedSessionItem[] = useMemo(() => {
        if (allSessions && allSessions.length > 0) {
            return allSessions;
        }

        const list: UnifiedSessionItem[] = [];

        // Add web sessions
        sessions.forEach((s) => {
            list.push({
                id: s.id,
                name: `${s.agent.platform} — ${s.agent.browser}`,
                type: 'browser',
                is_current_device: s.is_current_device,
                subscription_tier: 'free',
                subscription_tier_label: 'Free Plan',
                ip_address: s.ip_address,
                last_active: s.is_current_device ? 'Active now' : s.last_active,
                agent: s.agent,
            });
        });

        // Add mobile devices
        devices.forEach((d) => {
            list.push({
                id: String(d.id),
                device_token_id: d.id,
                name: d.name || 'Due Mobile',
                type: 'mobile',
                is_current_device: false,
                subscription_tier: d.subscription_tier,
                subscription_tier_label: d.subscription_tier_label,
                token_masked: d.token_masked ?? `${d.id}|••••...••••`,
                token_full: d.token_full ?? '',
                ip_address: null,
                last_active: d.last_used_at,
                created_at: d.created_at,
                agent: {
                    is_desktop: false,
                    platform: 'Mobile',
                    browser: 'Mobile App',
                },
            });
        });

        // Sort current device to the top
        return list.sort((a, b) => {
            if (a.is_current_device) return -1;
            if (b.is_current_device) return 1;
            return 0;
        });
    }, [allSessions, sessions, devices]);

    const handleCopyToken = async (token: string, itemId: string | number) => {
        if (!token) return;
        try {
            await navigator.clipboard.writeText(token);
            setCopiedTokenId(itemId);
            setTimeout(() => setCopiedTokenId(null), 2000);
        } catch {
            // Fallback for clipboard API restrictions
            const textarea = document.createElement('textarea');
            textarea.value = token;
            document.body.appendChild(textarea);
            textarea.select();
            document.execCommand('copy');
            document.body.removeChild(textarea);
            setCopiedTokenId(itemId);
            setTimeout(() => setCopiedTokenId(null), 2000);
        }
    };

    const handleLogoutOtherSessions = (e: React.FormEvent) => {
        e.preventDefault();

        destroyOthers('/settings/sessions/others', {
            preserveScroll: true,
            onSuccess: () => {
                setConfirmingLogout(false);
                reset();
            },
        });
    };

    const handleRevokeSingleSession = (sessionId: string) => {
        setRevokingId(sessionId);
        router.delete(`/settings/sessions/${sessionId}`, {
            preserveScroll: true,
            onFinish: () => setRevokingId(null),
        });
    };

    const handleRevokeDevice = (tokenId: number) => {
        setRevokingId(tokenId);
        router.delete(`/settings/devices/${tokenId}`, {
            preserveScroll: true,
            onFinish: () => setRevokingId(null),
        });
    };

    const handleRevokeAllDevices = () => {
        if (!confirm('Are you sure you want to revoke all mobile devices? You will need to log in again on those devices.')) {
            return;
        }

        setRevokingAllDevices(true);
        router.delete('/settings/devices/all', {
            preserveScroll: true,
            onFinish: () => setRevokingAllDevices(false),
        });
    };

    const renderTierBadge = (tier: string, label: string) => {
        const lowerTier = (tier || '').toLowerCase();
        let displayLabel = label;
        if (!displayLabel) {
            displayLabel = lowerTier === 'premium' ? 'Genius Plan' : lowerTier === 'basic' ? 'Scholar Plan' : 'Free Plan';
        }
        if (!displayLabel.toLowerCase().endsWith('plan')) {
            displayLabel = `${displayLabel} Plan`;
        }

        switch (lowerTier) {
            case 'premium':
            case 'genius':
                return (
                    <span className="inline-flex items-center gap-1 border border-purple-500/40 bg-purple-500/10 px-2 py-0.5 font-mono text-[10px] uppercase font-semibold text-purple-400">
                        <Sparkles className="size-2.5" />
                        {displayLabel}
                    </span>
                );
            case 'basic':
            case 'scholar':
                return (
                    <span className="inline-flex items-center gap-1 border border-blue-500/40 bg-blue-500/10 px-2 py-0.5 font-mono text-[10px] uppercase font-semibold text-blue-400">
                        <Key className="size-2.5" />
                        {displayLabel}
                    </span>
                );
            default:
                return (
                    <span className="inline-flex items-center gap-1 border border-border bg-muted/40 px-2 py-0.5 font-mono text-[10px] uppercase font-semibold text-muted-foreground">
                        {displayLabel}
                    </span>
                );
        }
    };

    const hasOtherBrowserSessions = items.some(
        (item) => item.type === 'browser' && !item.is_current_device
    );
    const hasMobileDevices = items.some((item) => item.type === 'mobile');

    return (
        <>
            <Head title="Sessions & Devices" />

            <div className="space-y-8">
                <Heading
                    variant="small"
                    title="Active Sessions & Devices"
                    description="View, audit, and manage active web browser sessions and connected devices authenticated to your account."
                />

                {/* Notifications & Flash Messages */}
                {flash?.success && (
                    <Alert className="rounded-none border-emerald-500/50 bg-emerald-500/10 text-emerald-300 font-mono text-xs">
                        <AlertDescription>{flash.success}</AlertDescription>
                    </Alert>
                )}

                {flash?.error && (
                    <Alert className="rounded-none border-destructive/50 bg-destructive/10 text-destructive font-mono text-xs">
                        <AlertDescription>{flash.error}</AlertDescription>
                    </Alert>
                )}

                {/* Unified Section: All Sessions and Devices in One List */}
                <div className="space-y-4">
                    <div className="flex items-center justify-between border-b border-border/60 pb-2">
                        <div className="flex items-center gap-2">
                            <Laptop className="size-4 text-primary" />
                            <h3 className="text-sm font-bold uppercase tracking-wider font-mono text-foreground">
                                Active Sign-ins & Devices ({items.length})
                            </h3>
                        </div>

                        {hasMobileDevices && (
                            <Button
                                variant="outline"
                                size="sm"
                                onClick={handleRevokeAllDevices}
                                disabled={revokingAllDevices}
                                className="rounded-none font-mono text-xs text-destructive border-destructive/40 hover:bg-destructive/10 h-7 px-2.5"
                            >
                                <Trash2 className="size-3 mr-1" />
                                {revokingAllDevices ? 'Revoking All...' : 'Revoke All Devices'}
                            </Button>
                        )}
                    </div>

                    <div className="space-y-3">
                        {items.length === 0 ? (
                            <div className="border border-border/70 bg-card p-4 text-xs font-mono text-muted-foreground">
                                <p className="text-foreground font-semibold">No active sessions or devices found</p>
                                <p className="mt-1">
                                    When you log in on the web or the mobile app, your authenticated sessions will appear here.
                                </p>
                            </div>
                        ) : (
                            items.map((item) => {
                                const isMobile = item.type === 'mobile';
                                const isCurrent = item.is_current_device;
                                const deviceId = item.device_token_id ?? Number(item.id);
                                const isRevokingThis =
                                    revokingId === item.id || revokingId === deviceId;

                                return (
                                    <div
                                        key={`${item.type}-${item.id}`}
                                        className={`flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 border p-4 transition-colors ${
                                            isCurrent
                                                ? 'border-primary/40 bg-card'
                                                : 'border-border/80 bg-card hover:border-border'
                                        }`}
                                    >
                                        <div className="flex items-start gap-3.5 min-w-0 flex-1">
                                            <div className="mt-0.5 flex size-9 shrink-0 items-center justify-center border border-border bg-muted/40 text-muted-foreground">
                                                {isMobile ? (
                                                    <Smartphone className="size-4 text-primary" />
                                                ) : (
                                                    <Laptop className="size-4 text-primary" />
                                                )}
                                            </div>

                                            <div className="min-w-0 flex-1">
                                                <div className="flex flex-wrap items-center gap-2">
                                                    <span className="font-semibold text-sm text-foreground truncate max-w-[280px]">
                                                        {item.name}
                                                    </span>

                                                    {/* Subscription Plan Badge */}
                                                    {renderTierBadge(
                                                        item.subscription_tier,
                                                        item.subscription_tier_label
                                                    )}

                                                    {/* Device Type Tag */}
                                                    <span className="inline-flex items-center border border-border px-1.5 py-0.2 font-mono text-[9px] uppercase text-muted-foreground">
                                                        {isMobile ? 'Mobile App' : 'Web Browser'}
                                                    </span>

                                                    {/* Current Device Indicator */}
                                                    {isCurrent && (
                                                        <span className="inline-flex items-center gap-1 border border-emerald-500/40 bg-emerald-500/10 px-2 py-0.5 font-mono text-[10px] uppercase font-semibold text-emerald-400">
                                                            <CheckCircle2 className="size-2.5" />
                                                            This Device
                                                        </span>
                                                    )}
                                                </div>

                                                {/* Token Display with Copy Button */}
                                                {isMobile && item.token_masked && (
                                                    <div className="mt-2 flex flex-wrap items-center gap-2 font-mono text-xs text-muted-foreground">
                                                        <span className="text-foreground/90 font-semibold text-[11px]">
                                                            Token:
                                                        </span>
                                                        <code className="bg-muted/60 px-2 py-0.5 border border-border/70 text-foreground font-mono text-[11px] tracking-wide select-all">
                                                            {item.token_masked}
                                                        </code>

                                                        <Button
                                                            type="button"
                                                            variant="outline"
                                                            size="sm"
                                                            onClick={() =>
                                                                handleCopyToken(
                                                                    item.token_full || item.token_masked || '',
                                                                    item.id
                                                                )
                                                            }
                                                            className="h-6 px-2 text-[10px] font-mono rounded-none border-border hover:bg-muted"
                                                            title="Copy token to clipboard"
                                                        >
                                                            {copiedTokenId === item.id ? (
                                                                <>
                                                                    <Check className="size-2.5 mr-1 text-emerald-400" />
                                                                    Copied!
                                                                </>
                                                            ) : (
                                                                <>
                                                                    <Copy className="size-2.5 mr-1" />
                                                                    Copy
                                                                </>
                                                            )}
                                                        </Button>
                                                    </div>
                                                )}

                                                {/* Activity & Network Timestamps */}
                                                <div className="mt-1.5 flex flex-wrap items-center gap-3 text-xs font-mono text-muted-foreground">
                                                    {isMobile ? (
                                                        <>
                                                            {item.created_at && (
                                                                <span>Added: {item.created_at}</span>
                                                            )}
                                                            {item.created_at && <span>•</span>}
                                                            <span>Last active: {item.last_active}</span>
                                                        </>
                                                    ) : (
                                                        <>
                                                            <span>IP: {item.ip_address ?? 'Unknown IP'}</span>
                                                            <span>•</span>
                                                            <span>
                                                                {isCurrent
                                                                    ? 'Active now'
                                                                    : `Last active ${item.last_active}`}
                                                            </span>
                                                        </>
                                                    )}
                                                </div>
                                            </div>
                                        </div>

                                        {/* Revoke Action */}
                                        {!isCurrent && (
                                            <Button
                                                variant="outline"
                                                size="sm"
                                                onClick={() => {
                                                    if (isMobile) {
                                                        handleRevokeDevice(deviceId);
                                                    } else {
                                                        handleRevokeSingleSession(item.id);
                                                    }
                                                }}
                                                disabled={Boolean(isRevokingThis)}
                                                className="rounded-none font-mono text-xs text-destructive border-destructive/30 hover:bg-destructive/10 shrink-0"
                                            >
                                                <Trash2 className="size-3 mr-1" />
                                                {isRevokingThis
                                                    ? 'Revoking...'
                                                    : isMobile
                                                      ? 'Revoke Device'
                                                      : 'Revoke Session'}
                                            </Button>
                                        )}
                                    </div>
                                );
                            })
                        )}
                    </div>
                </div>

                {/* Bulk Session Management / Invalidation */}
                {hasOtherBrowserSessions && (
                    <div className="border border-border bg-card p-5 space-y-4">
                        <div className="flex items-start gap-3">
                            <Shield className="size-5 text-primary shrink-0 mt-0.5" />
                            <div>
                                <h4 className="text-sm font-bold text-foreground font-mono uppercase tracking-wide">
                                    Browser Session Invalidation
                                </h4>
                                <p className="mt-1 text-xs text-muted-foreground">
                                    If you suspect unauthorized browser access or logged in on public computers, securely invalidate all other active browser sessions across your devices.
                                </p>
                            </div>
                        </div>

                        <div className="pt-2">
                            <Button
                                type="button"
                                variant="destructive"
                                onClick={() => {
                                    clearErrors();
                                    reset();
                                    setConfirmingLogout(true);
                                }}
                                className="rounded-none font-mono text-xs"
                            >
                                <LogOut className="size-3.5 mr-1.5" />
                                Log Out Other Browser Sessions
                            </Button>
                        </div>
                    </div>
                )}
            </div>

            {/* Password Confirmation Modal for Logging Out Other Sessions */}
            <Dialog open={confirmingLogout} onOpenChange={(open) => !open && setConfirmingLogout(false)}>
                <DialogContent className="rounded-none border-border bg-card sm:max-w-md">
                    <DialogHeader>
                        <DialogTitle className="text-base font-bold">
                            Log Out Other Browser Sessions
                        </DialogTitle>
                        <DialogDescription className="text-xs text-muted-foreground">
                            Please enter your current password to confirm that you want to log out of all other browser sessions across your devices.
                        </DialogDescription>
                    </DialogHeader>

                    <form onSubmit={handleLogoutOtherSessions} className="space-y-4 mt-2">
                        <div className="grid gap-2">
                            <Label htmlFor="session_password" className="text-xs font-mono">
                                Current Password
                            </Label>
                            <PasswordInput
                                id="session_password"
                                name="password"
                                value={data.password}
                                onChange={(e) => setData('password', e.target.value)}
                                placeholder="Enter password to verify"
                                autoComplete="current-password"
                                autoFocus
                            />
                            <InputError message={formErrors.password || errors.password} />
                        </div>

                        <DialogFooter className="gap-2 sm:justify-end">
                            <Button
                                type="button"
                                variant="outline"
                                onClick={() => setConfirmingLogout(false)}
                                disabled={processing}
                                className="rounded-none font-mono text-xs"
                            >
                                Cancel
                            </Button>
                            <Button
                                type="submit"
                                variant="destructive"
                                disabled={processing || !data.password}
                                className="rounded-none font-mono text-xs"
                            >
                                {processing ? 'Invalidating Sessions...' : 'Confirm Session Invalidation'}
                            </Button>
                        </DialogFooter>
                    </form>
                </DialogContent>
            </Dialog>
        </>
    );
}

Sessions.layout = {
    breadcrumbs: [
        {
            title: 'Sessions & Devices',
            href: editSessions(),
        },
    ],
};
