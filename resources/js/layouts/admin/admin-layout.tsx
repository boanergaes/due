import { Head, Link, router, usePage } from '@inertiajs/react';
import {
    ArrowLeft,
    CreditCard,
    HardDrive,
    LayoutDashboard,
    LogOut,
    Menu,
    Users,
    X,
} from 'lucide-react';
import React, { useState } from 'react';
import AppLogoIcon from '@/components/app-logo-icon';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import type { Auth } from '@/types';

interface AdminLayoutProps {
    children: React.ReactNode;
    title?: string;
}

export function AdminLayout({ children, title }: AdminLayoutProps) {
    const page = usePage();
    const currentUrl = page.url;
    const auth = (page.props as { auth?: Auth }).auth;
    const flash = (page.props as { flash?: { success?: string | null; error?: string | null } }).flash;
    const [mobileOpen, setMobileOpen] = useState(false);

    const navItems = [
        {
            name: 'Overview',
            href: '/admin/dashboard',
            icon: LayoutDashboard,
            active: currentUrl === '/admin/dashboard' || currentUrl === '/admin',
        },
        {
            name: 'Users & Access',
            href: '/admin/users',
            icon: Users,
            active: currentUrl.startsWith('/admin/users'),
        },
        {
            name: 'Subscriptions & MRR',
            href: '/admin/subscriptions',
            icon: CreditCard,
            active: currentUrl.startsWith('/admin/subscriptions'),
        },
        {
            name: 'Storage Telemetry',
            href: '/admin/storage',
            icon: HardDrive,
            active: currentUrl.startsWith('/admin/storage'),
        },
    ];

    const handleLogout = () => {
        router.post('/admin/logout');
    };

    return (
        <div className="min-h-screen bg-background text-foreground flex flex-col md:flex-row font-sans">
            {title && <Head title={`Admin: ${title}`} />}

            {/* Mobile Top Bar */}
            <div className="md:hidden border-b border-border bg-card px-4 py-3 flex items-center justify-between sticky top-0 z-40">
                <div className="flex items-center gap-2.5">
                    <div className="flex aspect-square size-7 items-center justify-center rounded-md bg-primary text-primary-foreground">
                        <AppLogoIcon className="size-4" />
                    </div>
                    <span className="font-semibold text-sm">Due</span>
                    <Badge variant="secondary" className="text-[10px] px-1.5 py-0 font-normal">
                        Admin
                    </Badge>
                </div>

                <div className="flex items-center gap-2">
                    <Link
                        href="/dashboard"
                        className="inline-flex items-center gap-1 text-xs text-muted-foreground hover:text-foreground px-2 py-1 rounded-md border border-border"
                        title="Return to student application"
                    >
                        <ArrowLeft className="size-3.5" />
                        <span>Exit Admin</span>
                    </Link>
                    <button
                        type="button"
                        onClick={() => setMobileOpen(!mobileOpen)}
                        className="p-1.5 rounded-md hover:bg-muted text-muted-foreground hover:text-foreground"
                        aria-label="Toggle Navigation"
                    >
                        {mobileOpen ? <X className="size-5" /> : <Menu className="size-5" />}
                    </button>
                </div>
            </div>

            {/* Mobile Navigation Drawer */}
            {mobileOpen && (
                <div className="md:hidden border-b border-border bg-card px-4 py-3 space-y-3">
                    <nav className="space-y-1">
                        {navItems.map((item) => {
                            const Icon = item.icon;
                            return (
                                <Link
                                    key={item.href}
                                    href={item.href}
                                    onClick={() => setMobileOpen(false)}
                                    className={`flex items-center gap-2.5 px-3 py-2 text-sm rounded-md transition-colors ${
                                        item.active
                                            ? 'bg-accent text-accent-foreground font-medium'
                                            : 'text-muted-foreground hover:text-foreground hover:bg-muted/60'
                                    }`}
                                >
                                    <Icon className="size-4" />
                                    <span>{item.name}</span>
                                </Link>
                            );
                        })}
                    </nav>

                    <div className="border-t border-border pt-3 flex items-center justify-between">
                        <div className="text-xs truncate max-w-[180px]">
                            <p className="font-medium text-foreground truncate">{auth?.user?.name || 'Administrator'}</p>
                            <p className="text-muted-foreground truncate">{auth?.user?.email}</p>
                        </div>
                        <Button
                            variant="ghost"
                            size="sm"
                            onClick={handleLogout}
                            className="text-xs text-muted-foreground hover:text-foreground h-8 px-2"
                        >
                            <LogOut className="size-3.5 mr-1" />
                            Logout
                        </Button>
                    </div>
                </div>
            )}

            {/* Dedicated Desktop Admin Sidebar */}
            <aside className="hidden md:flex flex-col w-64 border-r border-border bg-card/60 shrink-0 sticky top-0 h-screen">
                {/* Brand Header */}
                <div className="h-14 px-4 border-b border-border flex items-center justify-between">
                    <Link href="/admin/dashboard" className="flex items-center gap-2.5">
                        <div className="flex aspect-square size-7 items-center justify-center rounded-md bg-primary text-primary-foreground">
                            <AppLogoIcon className="size-4" />
                        </div>
                        <span className="font-semibold text-base tracking-tight text-foreground">Due</span>
                        <Badge variant="secondary" className="text-[10px] font-medium px-1.5 py-0">
                            Admin
                        </Badge>
                    </Link>
                </div>

                {/* Navigation Links */}
                <div className="flex-1 px-3 py-4 space-y-6 overflow-y-auto">
                    <div className="space-y-1">
                        <p className="px-3 text-[11px] font-medium text-muted-foreground tracking-wider uppercase mb-2">
                            Management
                        </p>
                        {navItems.map((item) => {
                            const Icon = item.icon;
                            return (
                                <Link
                                    key={item.href}
                                    href={item.href}
                                    className={`flex items-center gap-2.5 px-3 py-2 text-sm rounded-md transition-colors ${
                                        item.active
                                            ? 'bg-accent text-accent-foreground font-medium'
                                            : 'text-muted-foreground hover:text-foreground hover:bg-muted/50'
                                    }`}
                                >
                                    <Icon className="size-4 shrink-0" />
                                    <span>{item.name}</span>
                                </Link>
                            );
                        })}
                    </div>

                    {/* Exit Admin Section */}
                    <div className="space-y-1 pt-2 border-t border-border/60">
                        <p className="px-3 text-[11px] font-medium text-muted-foreground tracking-wider uppercase mb-2">
                            Navigation
                        </p>
                        <Link
                            href="/dashboard"
                            className="flex items-center gap-2.5 px-3 py-2 text-sm text-muted-foreground hover:text-foreground hover:bg-muted/50 rounded-md transition-colors group"
                            title="Return to the main application"
                        >
                            <ArrowLeft className="size-4 shrink-0 text-muted-foreground group-hover:-translate-x-0.5 transition-transform" />
                            <span>Exit Admin</span>
                        </Link>
                    </div>
                </div>

                {/* Admin User Profile & Sign Out Footer */}
                <div className="p-3 border-t border-border bg-card/40">
                    <div className="flex items-center justify-between gap-2 p-1">
                        <div className="flex items-center gap-2 min-w-0">
                            <div className="size-8 rounded-full bg-muted flex items-center justify-center text-xs font-semibold text-foreground shrink-0 border border-border">
                                {(auth?.user?.name || 'A').slice(0, 2).toUpperCase()}
                            </div>
                            <div className="min-w-0 flex-1">
                                <p className="text-xs font-medium text-foreground truncate">
                                    {auth?.user?.name || 'Administrator'}
                                </p>
                                <p className="text-[11px] text-muted-foreground truncate">
                                    {auth?.user?.email}
                                </p>
                            </div>
                        </div>

                        <Button
                            variant="ghost"
                            size="icon"
                            onClick={handleLogout}
                            className="size-8 text-muted-foreground hover:text-foreground hover:bg-muted shrink-0"
                            title="Sign out of Admin"
                        >
                            <LogOut className="size-4" />
                            <span className="sr-only">Logout</span>
                        </Button>
                    </div>
                </div>
            </aside>

            {/* Main Content Area */}
            <div className="flex-1 min-w-0 flex flex-col min-h-screen">
                {/* Flash Messages */}
                {flash?.success && (
                    <div className="bg-emerald-500/10 border-b border-emerald-500/20 text-emerald-600 dark:text-emerald-400 px-6 py-2.5 text-xs text-center font-medium">
                        {flash.success}
                    </div>
                )}
                {flash?.error && (
                    <div className="bg-destructive/10 border-b border-destructive/20 text-destructive px-6 py-2.5 text-xs text-center font-medium">
                        {flash.error}
                    </div>
                )}

                {/* Main View Children */}
                <main className="flex-1 p-4 sm:p-6 lg:p-8 max-w-7xl w-full mx-auto">
                    {children}
                </main>
            </div>
        </div>
    );
}
