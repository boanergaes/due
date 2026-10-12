import { Head, router, useForm, usePage } from '@inertiajs/react';
import {
    AlertTriangle,
    CheckCircle2,
    Laptop,
    LogOut,
    Shield,
    Smartphone,
    Trash2,
} from 'lucide-react';
import { useState } from 'react';
import Heading from '@/components/heading';
import InputError from '@/components/input-error';
import PasswordInput from '@/components/password-input';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Button } from '@/components/ui/button';
import {
    Dialog,
    DialogClose,
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

interface PageProps {
    [key: string]: unknown;
    sessions: DeviceSession[];
    sessionDriver: string;
    flash?: {
        success?: string | null;
        error?: string | null;
    };
    errors: Record<string, string>;
}

export default function Sessions({ sessions, sessionDriver }: PageProps) {
    const { flash, errors } = usePage<PageProps>().props;
    const [confirmingLogout, setConfirmingLogout] = useState(false);
    const [revokingSessionId, setRevokingSessionId] = useState<string | null>(null);

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

    const handleLogoutOtherSessions = (e: React.FormEvent) => {
        e.preventDefault();

        destroyOthers('/settings/sessions/others', {
            preserveScroll: true,
            onSuccess: () => {
                setConfirmingLogout(false);
                reset();
            },
            onError: () => {},
        });
    };

    const handleRevokeSingle = (sessionId: string) => {
        setRevokingSessionId(sessionId);
        router.delete(`/settings/sessions/${sessionId}`, {
            preserveScroll: true,
            onFinish: () => setRevokingSessionId(null),
        });
    };

    return (
        <>
            <Head title="Sessions & Devices" />

            <div className="space-y-6">
                <Heading
                    variant="small"
                    title="Active Sessions & Devices"
                    description="View and manage authenticated browser sessions associated with your student account."
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

                {/* Sessions list */}
                <div className="space-y-3">
                    {sessions.length === 0 ? (
                        <div className="border border-border bg-card p-4 text-xs font-mono text-muted-foreground">
                            <p>
                                Session storage driver: <span className="text-foreground font-semibold">{sessionDriver}</span>.
                            </p>
                            <p className="mt-1">
                                Your current browser session is active. Database-backed session inspection displays records when using the database driver.
                            </p>
                        </div>
                    ) : (
                        sessions.map((session) => (
                            <div
                                key={session.id}
                                className={`flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 border p-4 transition-colors ${
                                    session.is_current_device
                                        ? 'border-border bg-card'
                                        : 'border-border/70 bg-card/60'
                                }`}
                            >
                                <div className="flex items-start gap-3.5">
                                    <div className="mt-0.5 flex size-9 shrink-0 items-center justify-center border border-border bg-muted/30 text-muted-foreground">
                                        {session.agent.is_desktop ? (
                                            <Laptop className="size-4 text-primary" />
                                        ) : (
                                            <Smartphone className="size-4 text-primary" />
                                        )}
                                    </div>

                                    <div>
                                        <div className="flex items-center gap-2">
                                            <span className="font-semibold text-sm text-foreground">
                                                {session.agent.platform} — {session.agent.browser}
                                            </span>
                                            {session.is_current_device && (
                                                <span className="inline-flex items-center gap-1 border border-emerald-500/40 bg-emerald-500/10 px-2 py-0.5 font-mono text-[10px] uppercase font-semibold text-emerald-400">
                                                    <CheckCircle2 className="size-2.5" />
                                                    This Device
                                                </span>
                                            )}
                                        </div>

                                        <div className="mt-1 flex flex-wrap items-center gap-3 text-xs font-mono text-muted-foreground">
                                            <span>IP: {session.ip_address ?? 'Unknown IP'}</span>
                                            <span>•</span>
                                            <span>
                                                {session.is_current_device
                                                    ? 'Active now'
                                                    : `Last active ${session.last_active}`}
                                            </span>
                                        </div>
                                    </div>
                                </div>

                                {!session.is_current_device && (
                                    <Button
                                        variant="outline"
                                        size="sm"
                                        onClick={() => handleRevokeSingle(session.id)}
                                        disabled={revokingSessionId === session.id}
                                        className="rounded-none font-mono text-xs text-destructive border-destructive/30 hover:bg-destructive/10 shrink-0"
                                    >
                                        <Trash2 className="size-3 mr-1" />
                                        Revoke Session
                                    </Button>
                                )}
                            </div>
                        ))
                    )}
                </div>

                {/* Bulk Terminate Other Sessions Action */}
                <div className="border border-border bg-card p-5 space-y-4">
                    <div className="flex items-start gap-3">
                        <Shield className="size-5 text-primary shrink-0 mt-0.5" />
                        <div>
                            <h3 className="text-sm font-bold text-foreground font-mono uppercase tracking-wide">
                                Session Invalidation & Security
                            </h3>
                            <p className="mt-1 text-xs text-muted-foreground">
                                If you suspect unauthorized access or have signed in on public laboratory computers, you may securely invalidate all other browser sessions across your devices.
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
                            Log Out Other Device Sessions
                        </Button>
                    </div>
                </div>
            </div>

            {/* Password Confirmation Modal */}
            <Dialog open={confirmingLogout} onOpenChange={(open) => !open && setConfirmingLogout(false)}>
                <DialogContent className="rounded-none border-border bg-card sm:max-w-md">
                    <DialogHeader>
                        <DialogTitle className="text-base font-bold">
                            Log Out Other Device Sessions
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
