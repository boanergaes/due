import { Head, Link, useForm } from '@inertiajs/react';
import { AlertCircle, ArrowLeft } from 'lucide-react';
import React from 'react';
import AppLogoIcon from '@/components/app-logo-icon';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Checkbox } from '@/components/ui/checkbox';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';

export default function AdminLogin() {
    const { data, setData, post, processing, errors, reset } = useForm({
        email: '',
        password: '',
        remember: false,
    });

    const submit = (e: React.FormEvent) => {
        e.preventDefault();
        post('/admin/login', {
            onFinish: () => reset('password'),
        });
    };

    return (
        <div className="min-h-screen bg-background text-foreground flex flex-col justify-center items-center p-4">
            <Head title="Admin Login" />

            <div className="w-full max-w-sm space-y-6">
                {/* Header Brand */}
                <div className="text-center space-y-2">
                    <div className="flex aspect-square size-10 items-center justify-center rounded-lg bg-primary text-primary-foreground mx-auto mb-3 shadow-xs">
                        <AppLogoIcon className="size-5" />
                    </div>
                    <div className="flex items-center justify-center gap-2">
                        <span className="text-xl font-bold tracking-tight text-foreground">
                            Due
                        </span>
                        <Badge variant="secondary" className="text-xs font-medium">
                            Admin
                        </Badge>
                    </div>
                    <p className="text-sm text-muted-foreground">
                        Sign in with your administrator account
                    </p>
                </div>

                {/* Login Card */}
                <div className="border border-border bg-card p-6 rounded-lg shadow-xs space-y-5">
                    {errors.email && (
                        <Alert variant="destructive" className="text-xs">
                            <AlertCircle className="size-4" />
                            <AlertDescription>{errors.email}</AlertDescription>
                        </Alert>
                    )}

                    <form onSubmit={submit} className="space-y-4">
                        <div className="space-y-1.5">
                            <Label htmlFor="email" className="text-xs font-medium text-foreground">
                                Email Address
                            </Label>
                            <Input
                                id="email"
                                type="email"
                                value={data.email}
                                onChange={(e) => setData('email', e.target.value)}
                                placeholder="admin@example.com"
                                required
                                autoFocus
                                autoComplete="username"
                                className="text-sm"
                            />
                        </div>

                        <div className="space-y-1.5">
                            <Label htmlFor="password" className="text-xs font-medium text-foreground">
                                Password
                            </Label>
                            <Input
                                id="password"
                                type="password"
                                value={data.password}
                                onChange={(e) => setData('password', e.target.value)}
                                placeholder="••••••••"
                                required
                                autoComplete="current-password"
                                className="text-sm"
                            />
                            {errors.password && (
                                <p className="text-xs text-destructive">
                                    {errors.password}
                                </p>
                            )}
                        </div>

                        <div className="flex items-center space-x-2 pt-1">
                            <Checkbox
                                id="remember"
                                checked={data.remember}
                                onCheckedChange={(checked) => setData('remember', checked === true)}
                            />
                            <Label
                                htmlFor="remember"
                                className="text-xs text-muted-foreground cursor-pointer select-none"
                            >
                                Remember this device
                            </Label>
                        </div>

                        <Button
                            type="submit"
                            disabled={processing}
                            className="w-full text-sm font-medium py-2 mt-2 cursor-pointer"
                        >
                            {processing ? 'Signing in...' : 'Sign In'}
                        </Button>
                    </form>
                </div>

                {/* Back to App Link */}
                <div className="text-center">
                    <Link
                        href="/"
                        className="inline-flex items-center gap-1.5 text-xs text-muted-foreground hover:text-foreground transition-colors"
                    >
                        <ArrowLeft className="size-3.5" />
                        <span>Return to application</span>
                    </Link>
                </div>
            </div>
        </div>
    );
}
