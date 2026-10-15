import {
    CheckCircle2,
    CreditCard,
    DollarSign,
    TrendingUp,
    XCircle,
} from 'lucide-react';
import React from 'react';
import { AdminLayout } from '@/layouts/admin/admin-layout';
import { Pagination } from '@/components/pagination';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import type { PaginationLink } from '@/types';

interface SubscriptionItem {
    id: number;
    user?: {
        id: number;
        name: string;
        email: string;
    } | null;
    tier: string;
    price: number;
    interval: string;
    status: 'active' | 'cancelled' | 'expired';
    card_brand: string;
    card_last_four: string;
    mock_transaction_id: string;
    starts_at: string;
    ends_at?: string | null;
    created_at: string;
}

interface SubscriptionsPageProps {
    metrics: {
        active_count: number;
        cancelled_count: number;
        expired_count: number;
    };
    overview: {
        simulated_mrr: number;
        simulated_arr: number;
        total_users: number;
        genius_users: number;
    };
    subscriptions: {
        data: SubscriptionItem[];
        links: PaginationLink[];
        total: number;
    };
}

export default function AdminSubscriptions({
    metrics,
    overview,
    subscriptions,
}: SubscriptionsPageProps) {
    return (
        <AdminLayout title="Subscriptions & MRR">
            <div className="space-y-6">
                {/* Header */}
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-border pb-5">
                    <div>
                        <h1 className="text-2xl font-bold tracking-tight text-foreground">
                            Subscriptions & Revenue
                        </h1>
                        <p className="mt-1 text-sm text-muted-foreground">
                            Platform revenue telemetry and active user subscriptions.
                        </p>
                    </div>
                </div>

                {/* Financial KPI Cards */}
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                    <Card className="rounded-lg border-border bg-card shadow-xs">
                        <CardHeader className="flex flex-row items-center justify-between pb-2">
                            <CardTitle className="text-xs font-medium text-muted-foreground">
                                Monthly Recurring Revenue
                            </CardTitle>
                            <DollarSign className="size-4 text-emerald-500" />
                        </CardHeader>
                        <CardContent className="space-y-1">
                            <div className="text-2xl font-bold text-emerald-600 dark:text-emerald-400">
                                ${overview.simulated_mrr.toFixed(2)}
                            </div>
                            <p className="text-xs text-muted-foreground">
                                Based on active monthly & yearly subs
                            </p>
                        </CardContent>
                    </Card>

                    <Card className="rounded-lg border-border bg-card shadow-xs">
                        <CardHeader className="flex flex-row items-center justify-between pb-2">
                            <CardTitle className="text-xs font-medium text-muted-foreground">
                                Annual Run-Rate (ARR)
                            </CardTitle>
                            <TrendingUp className="size-4 text-emerald-500" />
                        </CardHeader>
                        <CardContent className="space-y-1">
                            <div className="text-2xl font-bold text-foreground">
                                ${overview.simulated_arr.toFixed(2)}
                            </div>
                            <p className="text-xs text-muted-foreground">
                                Projected 12-month baseline
                            </p>
                        </CardContent>
                    </Card>

                    <Card className="rounded-lg border-border bg-card shadow-xs">
                        <CardHeader className="flex flex-row items-center justify-between pb-2">
                            <CardTitle className="text-xs font-medium text-muted-foreground">
                                Active Subscribers
                            </CardTitle>
                            <CheckCircle2 className="size-4 text-emerald-500" />
                        </CardHeader>
                        <CardContent className="space-y-1">
                            <div className="text-2xl font-bold text-foreground">
                                {metrics.active_count}
                            </div>
                            <p className="text-xs text-muted-foreground">
                                {overview.genius_users} total Genius tier users
                            </p>
                        </CardContent>
                    </Card>

                    <Card className="rounded-lg border-border bg-card shadow-xs">
                        <CardHeader className="flex flex-row items-center justify-between pb-2">
                            <CardTitle className="text-xs font-medium text-muted-foreground">
                                Cancelled / Inactive
                            </CardTitle>
                            <XCircle className="size-4 text-muted-foreground" />
                        </CardHeader>
                        <CardContent className="space-y-1">
                            <div className="text-2xl font-bold text-muted-foreground">
                                {metrics.cancelled_count}
                            </div>
                            <p className="text-xs text-muted-foreground">
                                {metrics.expired_count} expired records
                            </p>
                        </CardContent>
                    </Card>
                </div>

                {/* Subscriptions Table */}
                <Card className="rounded-lg border-border bg-card shadow-xs">
                    <CardHeader className="border-b border-border/60 pb-3 flex flex-row items-center justify-between">
                        <CardTitle className="text-sm font-semibold flex items-center gap-2">
                            <CreditCard className="size-4 text-muted-foreground" />
                            Recent Subscriptions & Transactions ({subscriptions.total})
                        </CardTitle>
                    </CardHeader>
                    <CardContent className="p-0">
                        {subscriptions.data.length === 0 ? (
                            <div className="py-12 text-center text-sm text-muted-foreground">
                                No subscription transactions recorded yet.
                            </div>
                        ) : (
                            <div className="overflow-x-auto">
                                <table className="w-full text-left text-xs">
                                    <thead className="bg-muted/50 border-b border-border/80 text-[11px] text-muted-foreground uppercase tracking-wider">
                                        <tr>
                                            <th className="p-3.5">Subscriber</th>
                                            <th className="p-3.5">Plan / Tier</th>
                                            <th className="p-3.5">Rate & Interval</th>
                                            <th className="p-3.5">Payment Method</th>
                                            <th className="p-3.5">Transaction Ref</th>
                                            <th className="p-3.5">Status</th>
                                            <th className="p-3.5 text-right">Renewal Date</th>
                                        </tr>
                                    </thead>
                                    <tbody className="divide-y divide-border/40">
                                        {subscriptions.data.map((sub) => (
                                            <tr key={sub.id} className="hover:bg-muted/30 transition-colors">
                                                {/* Subscriber */}
                                                <td className="p-3.5">
                                                    <div className="font-semibold text-foreground">
                                                        {sub.user?.name || 'Unknown User'}
                                                    </div>
                                                    <div className="text-[11px] text-muted-foreground">
                                                        {sub.user?.email || 'N/A'}
                                                    </div>
                                                </td>

                                                {/* Plan */}
                                                <td className="p-3.5">
                                                    <Badge
                                                        variant="outline"
                                                        className="border-primary/40 bg-primary/10 text-primary text-[10px] uppercase font-medium"
                                                    >
                                                        {sub.tier}
                                                    </Badge>
                                                </td>

                                                {/* Rate */}
                                                <td className="p-3.5">
                                                    <div className="font-medium text-foreground">
                                                        ${sub.price.toFixed(2)}
                                                    </div>
                                                    <div className="text-[10px] text-muted-foreground capitalize">
                                                        {sub.interval}
                                                    </div>
                                                </td>

                                                {/* Card */}
                                                <td className="p-3.5 text-muted-foreground">
                                                    <span className="capitalize">{sub.card_brand}</span> &bull;&bull;&bull;&bull; {sub.card_last_four}
                                                </td>

                                                {/* Transaction ID */}
                                                <td className="p-3.5 text-xs text-muted-foreground font-mono">
                                                    {sub.mock_transaction_id}
                                                </td>

                                                {/* Status */}
                                                <td className="p-3.5">
                                                    {sub.status === 'active' ? (
                                                        <Badge
                                                            variant="secondary"
                                                            className="text-emerald-600 dark:text-emerald-400 text-[10px] font-medium"
                                                        >
                                                            Active
                                                        </Badge>
                                                    ) : sub.status === 'cancelled' ? (
                                                        <Badge
                                                            variant="outline"
                                                            className="text-amber-600 dark:text-amber-400 text-[10px]"
                                                        >
                                                            Cancelled
                                                        </Badge>
                                                    ) : (
                                                        <Badge
                                                            variant="outline"
                                                            className="text-muted-foreground text-[10px]"
                                                        >
                                                            Expired
                                                        </Badge>
                                                    )}
                                                </td>

                                                {/* Renewal */}
                                                <td className="p-3.5 text-right text-muted-foreground">
                                                    {sub.ends_at ? new Date(sub.ends_at).toLocaleDateString() : 'Continuous'}
                                                </td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        )}
                    </CardContent>
                </Card>

                {/* Pagination */}
                {subscriptions.total > 15 && (
                    <div className="flex justify-center pt-2">
                        <Pagination links={subscriptions.links} />
                    </div>
                )}
            </div>
        </AdminLayout>
    );
}
