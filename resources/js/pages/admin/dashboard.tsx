import { Link } from '@inertiajs/react';
import {
    Activity,
    ArrowUpRight,
    BotMessageSquare,
    DollarSign,
    HardDrive,
    TrendingUp,
    Users,
} from 'lucide-react';
import React from 'react';
import { AdminLayout } from '@/layouts/admin/admin-layout';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';

interface OverviewStats {
    total_users: number;
    genius_users: number;
    free_users: number;
    admins?: number;
    super_admins?: number;
    total_storage_bytes: number;
    total_storage_formatted: string;
    total_resources_count: number;
    total_ai_queries: number;
    total_ai_tokens: number;
    simulated_mrr: number;
    simulated_arr: number;
}

interface StorageCategory {
    name: string;
    bytes: number;
    count: number;
    formatted: string;
}

interface LargestFile {
    id: number;
    title: string;
    file_name: string;
    file_size_bytes: number;
    formatted_size: string;
    mime_type: string;
    owner_name: string;
    owner_email: string;
    created_at?: string;
}

interface DailyAiStat {
    date: string;
    label: string;
    tokens: number;
    queries: number;
}

interface TopAiUser {
    id: number;
    name: string;
    email: string;
    tier: string;
    conversations_count: number;
    tokens_used: number;
}

interface DashboardProps {
    overview: OverviewStats;
    storage: {
        categories: StorageCategory[];
        largest_files: LargestFile[];
    };
    ai: {
        total_queries: number;
        total_tokens: number;
        avg_tokens_per_query: number;
        daily_stats: DailyAiStat[];
        top_users: TopAiUser[];
    };
    subscriptions: {
        active_count: number;
        cancelled_count: number;
        expired_count: number;
        recent_transactions: Array<{
            id: number;
            user_name: string;
            user_email: string;
            tier: string;
            price: number;
            interval: string;
            status: string;
            mock_transaction_id: string;
            created_at: string;
        }>;
    };
}

export default function AdminDashboard({ overview, storage, ai, subscriptions }: DashboardProps) {
    // Nominal infrastructure cap for storage meter (10 GB)
    const nominalCapBytes = 10 * 1024 * 1024 * 1024;
    const storagePercent = Math.min(
        100,
        Math.max(1, (overview.total_storage_bytes / nominalCapBytes) * 100)
    );

    const paidPercent =
        overview.total_users > 0
            ? Math.round((overview.genius_users / overview.total_users) * 100)
            : 0;

    return (
        <AdminLayout title="Overview">
            <div className="space-y-6">
                {/* Header Welcome */}
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-border pb-5">
                    <div>
                        <h1 className="text-2xl font-bold tracking-tight text-foreground">
                            Admin Overview
                        </h1>
                        <p className="mt-1 text-sm text-muted-foreground">
                            System metrics, storage consumption, and active user analytics.
                        </p>
                    </div>

                    <div className="flex items-center gap-2">
                        <Button asChild variant="outline" size="sm">
                            <Link href="/admin/users">
                                <Users className="size-4 mr-1.5 text-muted-foreground" />
                                Manage Users
                            </Link>
                        </Button>
                        <Button asChild variant="outline" size="sm">
                            <Link href="/admin/storage">
                                <HardDrive className="size-4 mr-1.5 text-muted-foreground" />
                                View Storage
                            </Link>
                        </Button>
                    </div>
                </div>

                {/* Primary Metric KPI Cards */}
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                    {/* Storage Meter */}
                    <Card className="rounded-lg border-border bg-card shadow-xs">
                        <CardHeader className="flex flex-row items-center justify-between pb-2">
                            <CardTitle className="text-xs font-medium text-muted-foreground">
                                Storage Used
                            </CardTitle>
                            <HardDrive className="size-4 text-muted-foreground" />
                        </CardHeader>
                        <CardContent className="space-y-2">
                            <div className="text-2xl font-bold text-foreground">
                                {overview.total_storage_formatted}
                            </div>
                            <div className="space-y-1">
                                <div className="h-1.5 w-full bg-muted rounded-full overflow-hidden">
                                    <div
                                        className="h-full bg-primary transition-all duration-500 rounded-full"
                                        style={{ width: `${storagePercent}%` }}
                                    />
                                </div>
                                <div className="flex items-center justify-between text-xs text-muted-foreground">
                                    <span>{overview.total_resources_count} uploaded files</span>
                                    <span>{storagePercent.toFixed(1)}% of 10GB</span>
                                </div>
                            </div>
                        </CardContent>
                    </Card>

                    {/* Gemini AI Telemetry */}
                    <Card className="rounded-lg border-border bg-card shadow-xs">
                        <CardHeader className="flex flex-row items-center justify-between pb-2">
                            <CardTitle className="text-xs font-medium text-muted-foreground">
                                AI Assistant Activity
                            </CardTitle>
                            <BotMessageSquare className="size-4 text-muted-foreground" />
                        </CardHeader>
                        <CardContent className="space-y-2">
                            <div className="text-2xl font-bold text-foreground">
                                {overview.total_ai_tokens.toLocaleString()} <span className="text-xs text-muted-foreground font-normal">tokens</span>
                            </div>
                            <div className="flex items-center justify-between text-xs text-muted-foreground pt-1">
                                <span>{overview.total_ai_queries} queries</span>
                                <span className="text-foreground font-medium">~{ai.avg_tokens_per_query}t / query</span>
                            </div>
                        </CardContent>
                    </Card>

                    {/* User Directory */}
                    <Card className="rounded-lg border-border bg-card shadow-xs">
                        <CardHeader className="flex flex-row items-center justify-between pb-2">
                            <CardTitle className="text-xs font-medium text-muted-foreground">
                                Registered Users
                            </CardTitle>
                            <Users className="size-4 text-muted-foreground" />
                        </CardHeader>
                        <CardContent className="space-y-2">
                            <div className="text-2xl font-bold text-foreground">
                                {overview.total_users} <span className="text-xs text-muted-foreground font-normal">total</span>
                            </div>
                            <div className="flex items-center justify-between text-xs text-muted-foreground pt-1">
                                <span className="text-primary font-medium">{overview.genius_users} Genius</span>
                                <span>{overview.free_users} Free</span>
                                <span>{paidPercent}% Paid</span>
                            </div>
                        </CardContent>
                    </Card>

                    {/* Simulated Revenue */}
                    <Card className="rounded-lg border-border bg-card shadow-xs">
                        <CardHeader className="flex flex-row items-center justify-between pb-2">
                            <CardTitle className="text-xs font-medium text-muted-foreground">
                                Simulated MRR / ARR
                            </CardTitle>
                            <DollarSign className="size-4 text-emerald-500" />
                        </CardHeader>
                        <CardContent className="space-y-2">
                            <div className="text-2xl font-bold text-emerald-600 dark:text-emerald-400">
                                ${overview.simulated_mrr.toFixed(2)} <span className="text-xs text-muted-foreground font-normal">/ mo</span>
                            </div>
                            <div className="flex items-center justify-between text-xs text-muted-foreground pt-1">
                                <span>${overview.simulated_arr.toFixed(2)} ARR</span>
                                <span className="text-emerald-600 dark:text-emerald-400 font-medium">{subscriptions.active_count} active</span>
                            </div>
                        </CardContent>
                    </Card>
                </div>

                {/* Middle Two-Column Grid: Storage Breakdown & AI Activity Trend */}
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                    {/* Storage Categories */}
                    <Card className="rounded-lg border-border bg-card">
                        <CardHeader className="border-b border-border/60 pb-3 flex flex-row items-center justify-between">
                            <CardTitle className="text-sm font-semibold flex items-center gap-2">
                                <HardDrive className="size-4 text-muted-foreground" />
                                Storage by Category
                            </CardTitle>
                            <Link
                                href="/admin/storage"
                                className="text-xs text-primary hover:underline flex items-center gap-1"
                            >
                                Details <ArrowUpRight className="size-3" />
                            </Link>
                        </CardHeader>
                        <CardContent className="p-4 space-y-4">
                            {storage.categories.map((cat) => {
                                const percent =
                                    overview.total_storage_bytes > 0
                                        ? Math.round((cat.bytes / overview.total_storage_bytes) * 100)
                                        : 0;
                                return (
                                    <div key={cat.name} className="space-y-1.5">
                                        <div className="flex items-center justify-between text-xs">
                                            <span className="font-medium text-foreground">{cat.name}</span>
                                            <span className="text-muted-foreground">
                                                {cat.formatted} ({cat.count} files &bull; {percent}%)
                                            </span>
                                        </div>
                                        <div className="h-1.5 w-full bg-muted rounded-full overflow-hidden">
                                            <div
                                                className="h-full bg-primary/80 transition-all duration-300 rounded-full"
                                                style={{ width: `${percent}%` }}
                                            />
                                        </div>
                                    </div>
                                );
                            })}
                        </CardContent>
                    </Card>

                    {/* AI Activity 14-Day Trend */}
                    <Card className="rounded-lg border-border bg-card">
                        <CardHeader className="border-b border-border/60 pb-3 flex flex-row items-center justify-between">
                            <CardTitle className="text-sm font-semibold flex items-center gap-2">
                                <Activity className="size-4 text-muted-foreground" />
                                14-Day Query Volume
                            </CardTitle>
                            <Badge variant="secondary" className="text-[10px] font-normal">
                                Gemini 2.5 Flash
                            </Badge>
                        </CardHeader>
                        <CardContent className="p-4 space-y-4">
                            <div className="grid grid-cols-7 sm:grid-cols-14 gap-1 items-end h-36 pt-4">
                                {ai.daily_stats.map((day) => {
                                    const maxQueries = Math.max(...ai.daily_stats.map((d) => d.queries), 1);
                                    const barHeight = Math.max(8, Math.round((day.queries / maxQueries) * 100));

                                    return (
                                        <div key={day.date} className="flex flex-col items-center gap-1 group">
                                            <div className="w-full bg-muted rounded-sm flex items-end h-24 overflow-hidden relative">
                                                <div
                                                    className="w-full bg-primary/80 group-hover:bg-primary transition-all rounded-sm"
                                                    style={{ height: `${barHeight}%` }}
                                                    title={`${day.label}: ${day.queries} queries`}
                                                />
                                            </div>
                                            <span className="text-[10px] text-muted-foreground truncate w-full text-center">
                                                {day.label.slice(0, 3)}
                                            </span>
                                        </div>
                                    );
                                })}
                            </div>

                            <div className="flex items-center justify-between text-xs text-muted-foreground border-t border-border/40 pt-3">
                                <span>14-day queries: {ai.daily_stats.reduce((acc, d) => acc + d.queries, 0)}</span>
                                <span>Tokens used: {ai.daily_stats.reduce((acc, d) => acc + d.tokens, 0).toLocaleString()}</span>
                            </div>
                        </CardContent>
                    </Card>
                </div>

                {/* Bottom Snapshot: Largest Storage Files */}
                <Card className="rounded-lg border-border bg-card">
                    <CardHeader className="border-b border-border/60 pb-3 flex flex-row items-center justify-between">
                        <CardTitle className="text-sm font-semibold flex items-center gap-2">
                            <HardDrive className="size-4 text-muted-foreground" />
                            Recent Large Uploads
                        </CardTitle>
                        <Link
                            href="/admin/storage"
                            className="text-xs text-primary hover:underline flex items-center gap-1"
                        >
                            Storage Manager <ArrowUpRight className="size-3" />
                        </Link>
                    </CardHeader>
                    <CardContent className="p-0">
                        {storage.largest_files.length === 0 ? (
                            <div className="py-8 text-center text-xs text-muted-foreground">
                                No files uploaded yet.
                            </div>
                        ) : (
                            <div className="overflow-x-auto">
                                <table className="w-full text-left text-xs">
                                    <thead className="bg-muted/50 border-b border-border/80 text-[11px] text-muted-foreground uppercase tracking-wider">
                                        <tr>
                                            <th className="p-3">File Title</th>
                                            <th className="p-3">Type</th>
                                            <th className="p-3">Size</th>
                                            <th className="p-3">Owner</th>
                                            <th className="p-3 text-right">Uploaded</th>
                                        </tr>
                                    </thead>
                                    <tbody className="divide-y divide-border/40">
                                        {storage.largest_files.slice(0, 5).map((file) => (
                                            <tr key={file.id} className="hover:bg-muted/30 transition-colors">
                                                <td className="p-3 font-medium text-foreground max-w-[200px] truncate">
                                                    {file.title}
                                                </td>
                                                <td className="p-3 text-muted-foreground">
                                                    <span className="border border-border px-1.5 py-0.5 text-[10px] rounded-md bg-muted/40">
                                                        {file.mime_type}
                                                    </span>
                                                </td>
                                                <td className="p-3 font-medium text-foreground">
                                                    {file.formatted_size}
                                                </td>
                                                <td className="p-3 text-muted-foreground truncate max-w-[150px]">
                                                    {file.owner_name} ({file.owner_email})
                                                </td>
                                                <td className="p-3 text-right text-muted-foreground">
                                                    {file.created_at ? new Date(file.created_at).toLocaleDateString() : 'N/A'}
                                                </td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        )}
                    </CardContent>
                </Card>
            </div>
        </AdminLayout>
    );
}
