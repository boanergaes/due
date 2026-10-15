import { Head, router, useForm } from '@inertiajs/react';
import {
    Filter,
    Search,
    Sparkles,
    Trash2,
    UserCog,
    Users as UsersIcon,
    X,
} from 'lucide-react';
import React, { useState } from 'react';
import { AdminLayout } from '@/layouts/admin/admin-layout';
import { Pagination } from '@/components/pagination';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
} from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import type { PaginationLink } from '@/types';

interface AdminUserItem {
    id: number;
    name: string;
    email: string;
    role: 'student' | 'admin';
    subscription_tier: 'free' | 'basic' | 'premium';
    subscription_expires_at?: string | null;
    storage_used_bytes: number;
    classes_count: number;
    assignments_count: number;
    resources_count: number;
    ai_conversations_count: number;
    created_at: string;
}

interface UsersPageProps {
    users: {
        data: AdminUserItem[];
        links: PaginationLink[];
        total: number;
        from: number;
        to: number;
    };
    filters: {
        search?: string;
        tier?: string;
        role?: string;
    };
    tiers: Array<{ value: string; label: string }>;
    roles: Array<{ value: string; label: string }>;
}

export default function AdminUsers({ users, filters }: UsersPageProps) {
    const [searchTerm, setSearchTerm] = useState<string>(filters.search || '');
    const [selectedTier, setSelectedTier] = useState<string>(filters.tier || '');
    const [selectedRole, setSelectedRole] = useState<string>(filters.role || '');

    // Override Tier Modal State
    const [tierModalUser, setTierModalUser] = useState<AdminUserItem | null>(null);
    const tierForm = useForm({
        tier: 'premium',
        interval: 'monthly',
    });

    // Role Modal State
    const [roleModalUser, setRoleModalUser] = useState<AdminUserItem | null>(null);
    const roleForm = useForm({
        role: 'admin',
    });

    // Clear AI Modal State
    const [clearAiUser, setClearAiUser] = useState<AdminUserItem | null>(null);
    const clearAiForm = useForm({});

    const handleSearch = (e: React.FormEvent) => {
        e.preventDefault();
        router.get(
            '/admin/users',
            {
                search: searchTerm || undefined,
                tier: selectedTier || undefined,
                role: selectedRole || undefined,
            },
            { preserveState: true }
        );
    };

    const handleResetFilters = () => {
        setSearchTerm('');
        setSelectedTier('');
        setSelectedRole('');
        router.get('/admin/users');
    };

    const handleOpenTierModal = (user: AdminUserItem) => {
        setTierModalUser(user);
        tierForm.setData({
            tier: user.subscription_tier === 'premium' ? 'free' : 'premium',
            interval: 'monthly',
        });
    };

    const submitTierOverride = (e: React.FormEvent) => {
        e.preventDefault();
        if (!tierModalUser) return;

        tierForm.patch(`/admin/users/${tierModalUser.id}/tier`, {
            onSuccess: () => setTierModalUser(null),
        });
    };

    const handleOpenRoleModal = (user: AdminUserItem) => {
        setRoleModalUser(user);
        roleForm.setData({
            role: user.role === 'admin' ? 'student' : 'admin',
        });
    };

    const submitRoleUpdate = (e: React.FormEvent) => {
        e.preventDefault();
        if (!roleModalUser) return;

        roleForm.patch(`/admin/users/${roleModalUser.id}/role`, {
            onSuccess: () => setRoleModalUser(null),
        });
    };

    const submitClearAi = (e: React.FormEvent) => {
        e.preventDefault();
        if (!clearAiUser) return;

        clearAiForm.delete(`/admin/users/${clearAiUser.id}/ai`, {
            onSuccess: () => setClearAiUser(null),
        });
    };

    const formatBytes = (bytes: number): string => {
        if (bytes <= 0) return '0 B';
        const units = ['B', 'KB', 'MB', 'GB'];
        const base = Math.floor(Math.log(bytes) / Math.log(1024));
        return `${(bytes / Math.pow(1024, base)).toFixed(1)} ${units[base]}`;
    };

    return (
        <AdminLayout title="Users & Access">
            <div className="space-y-6">
                {/* Header */}
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-border pb-5">
                    <div>
                        <h1 className="text-2xl font-bold tracking-tight text-foreground">
                            Users & Access
                        </h1>
                        <p className="mt-1 text-sm text-muted-foreground">
                            Manage user accounts, subscriptions, and system roles ({users.total} total).
                        </p>
                    </div>
                </div>

                {/* Filter and Search Bar */}
                <Card className="rounded-lg border-border bg-card shadow-xs">
                    <CardContent className="p-4">
                        <form onSubmit={handleSearch} className="flex flex-col sm:flex-row items-center gap-3">
                            <div className="relative flex-1 w-full">
                                <Search className="size-4 absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" />
                                <Input
                                    value={searchTerm}
                                    onChange={(e) => setSearchTerm(e.target.value)}
                                    placeholder="Search by student name or email..."
                                    className="pl-9 w-full text-sm"
                                />
                            </div>

                            <div className="flex items-center gap-2 w-full sm:w-auto">
                                <select
                                    value={selectedTier}
                                    onChange={(e) => setSelectedTier(e.target.value)}
                                    className="h-9 px-3 rounded-md bg-background border border-input text-xs text-foreground focus:outline-none focus:ring-1 focus:ring-primary"
                                >
                                    <option value="">All Tiers</option>
                                    <option value="free">Free Tier</option>
                                    <option value="premium">Genius ($9.99/mo)</option>
                                </select>

                                <select
                                    value={selectedRole}
                                    onChange={(e) => setSelectedRole(e.target.value)}
                                    className="h-9 px-3 rounded-md bg-background border border-input text-xs text-foreground focus:outline-none focus:ring-1 focus:ring-primary"
                                >
                                    <option value="">All Roles</option>
                                    <option value="student">Student</option>
                                    <option value="admin">Admin</option>
                                </select>

                                <Button type="submit" size="sm" className="cursor-pointer">
                                    <Filter className="size-3.5 mr-1" />
                                    Filter
                                </Button>

                                {(filters.search || filters.tier || filters.role) && (
                                    <Button
                                        type="button"
                                        variant="outline"
                                        size="sm"
                                        onClick={handleResetFilters}
                                        title="Clear filters"
                                    >
                                        <X className="size-3.5" />
                                    </Button>
                                )}
                            </div>
                        </form>
                    </CardContent>
                </Card>

                {/* Users Table */}
                <Card className="rounded-lg border-border bg-card shadow-xs">
                    <CardContent className="p-0">
                        {users.data.length === 0 ? (
                            <div className="py-12 text-center text-sm text-muted-foreground">
                                No users matched your search criteria.
                            </div>
                        ) : (
                            <div className="overflow-x-auto">
                                <table className="w-full text-left text-xs">
                                    <thead className="bg-muted/50 border-b border-border/80 text-[11px] text-muted-foreground uppercase tracking-wider">
                                        <tr>
                                            <th className="p-3.5">User</th>
                                            <th className="p-3.5">Role</th>
                                            <th className="p-3.5">Tier & Expiration</th>
                                            <th className="p-3.5">Storage</th>
                                            <th className="p-3.5">Activity</th>
                                            <th className="p-3.5">Joined</th>
                                            <th className="p-3.5 text-right">Actions</th>
                                        </tr>
                                    </thead>
                                    <tbody className="divide-y divide-border/40">
                                        {users.data.map((user) => {
                                            const isAdmin = user.role === 'admin';
                                            const storageLimit = isAdmin
                                                ? 'Unlimited'
                                                : user.subscription_tier === 'premium'
                                                ? '1 GB'
                                                : '50 MB';

                                            return (
                                                <tr key={user.id} className="hover:bg-muted/30 transition-colors">
                                                    {/* User Details */}
                                                    <td className="p-3.5">
                                                        <div className="font-semibold text-foreground">
                                                            {user.name}
                                                        </div>
                                                        <div className="text-[11px] text-muted-foreground">
                                                            {user.email}
                                                        </div>
                                                    </td>

                                                    {/* Role */}
                                                    <td className="p-3.5">
                                                        {isAdmin ? (
                                                            <Badge variant="secondary" className="text-[10px] font-medium">
                                                                Admin
                                                            </Badge>
                                                        ) : (
                                                            <Badge variant="outline" className="text-[10px] text-muted-foreground">
                                                                Student
                                                            </Badge>
                                                        )}
                                                    </td>

                                                    {/* Tier */}
                                                    <td className="p-3.5">
                                                        <div className="flex items-center gap-1.5">
                                                            {user.subscription_tier === 'premium' ? (
                                                                <Badge
                                                                    variant="outline"
                                                                    className="border-primary/40 bg-primary/10 text-primary text-[10px] flex items-center gap-1 font-medium"
                                                                >
                                                                    <Sparkles className="size-3" />
                                                                    GENIUS
                                                                </Badge>
                                                            ) : (
                                                                <Badge
                                                                    variant="outline"
                                                                    className="border-border text-muted-foreground text-[10px]"
                                                                >
                                                                    FREE
                                                                </Badge>
                                                            )}
                                                        </div>
                                                        {user.subscription_expires_at && (
                                                            <div className="text-[10px] text-muted-foreground mt-0.5">
                                                                Exp: {new Date(user.subscription_expires_at).toLocaleDateString()}
                                                            </div>
                                                        )}
                                                    </td>

                                                    {/* Storage */}
                                                    <td className="p-3.5">
                                                        <div className="font-medium text-foreground">
                                                            {formatBytes(user.storage_used_bytes)}
                                                        </div>
                                                        <div className="text-[10px] text-muted-foreground">
                                                            Limit: {storageLimit}
                                                        </div>
                                                    </td>

                                                    {/* Activity */}
                                                    <td className="p-3.5 text-muted-foreground">
                                                        <div>{user.classes_count} classes &bull; {user.assignments_count} tasks</div>
                                                        <div className="text-[10px]">{user.resources_count} files &bull; {user.ai_conversations_count} AI sessions</div>
                                                    </td>

                                                    {/* Joined */}
                                                    <td className="p-3.5 text-muted-foreground">
                                                        {new Date(user.created_at).toLocaleDateString()}
                                                    </td>

                                                    {/* Actions */}
                                                    <td className="p-3.5 text-right">
                                                        <div className="flex items-center justify-end gap-1.5">
                                                            <Button
                                                                variant="outline"
                                                                size="sm"
                                                                onClick={() => handleOpenTierModal(user)}
                                                                className="h-7 px-2 text-xs"
                                                                title="Override Subscription Tier"
                                                            >
                                                                <Sparkles className="size-3 mr-1" />
                                                                Tier
                                                            </Button>

                                                            <Button
                                                                variant="outline"
                                                                size="sm"
                                                                onClick={() => handleOpenRoleModal(user)}
                                                                className="h-7 px-2 text-xs"
                                                                title="Change Role"
                                                            >
                                                                <UserCog className="size-3 mr-1" />
                                                                Role
                                                            </Button>

                                                            <Button
                                                                variant="ghost"
                                                                size="sm"
                                                                onClick={() => setClearAiUser(user)}
                                                                className="h-7 px-2 text-xs text-muted-foreground hover:text-destructive"
                                                                title="Clear AI Conversations"
                                                            >
                                                                <Trash2 className="size-3" />
                                                            </Button>
                                                        </div>
                                                    </td>
                                                </tr>
                                            );
                                        })}
                                    </tbody>
                                </table>
                            </div>
                        )}
                    </CardContent>
                </Card>

                {/* Pagination */}
                {users.total > 15 && (
                    <div className="flex justify-center pt-2">
                        <Pagination links={users.links} />
                    </div>
                )}
            </div>

            {/* Override Tier Dialog */}
            <Dialog open={!!tierModalUser} onOpenChange={(open) => !open && setTierModalUser(null)}>
                <DialogContent className="sm:max-w-md">
                    <DialogHeader>
                        <DialogTitle className="text-base font-semibold flex items-center gap-2">
                            <Sparkles className="size-4 text-primary" />
                            Update Subscription Tier
                        </DialogTitle>
                        <DialogDescription className="text-xs text-muted-foreground">
                            Update access tier for <span className="text-foreground font-semibold">{tierModalUser?.name}</span> ({tierModalUser?.email}).
                        </DialogDescription>
                    </DialogHeader>

                    <form onSubmit={submitTierOverride} className="space-y-4 pt-2">
                        <div className="space-y-1.5">
                            <Label className="text-xs font-medium text-foreground">
                                Subscription Tier
                            </Label>
                            <select
                                value={tierForm.data.tier}
                                onChange={(e) => tierForm.setData('tier', e.target.value)}
                                className="w-full h-9 px-3 rounded-md bg-background border border-input text-xs text-foreground focus:outline-none focus:ring-1 focus:ring-primary"
                            >
                                <option value="free">Free Tier (50MB storage, no AI)</option>
                                <option value="premium">Genius Tier (1GB storage, Gemini AI assistant)</option>
                            </select>
                        </div>

                        {tierForm.data.tier === 'premium' && (
                            <div className="space-y-1.5">
                                <Label className="text-xs font-medium text-foreground">
                                    Simulated Billing Interval
                                </Label>
                                <select
                                    value={tierForm.data.interval}
                                    onChange={(e) => tierForm.setData('interval', e.target.value)}
                                    className="w-full h-9 px-3 rounded-md bg-background border border-input text-xs text-foreground focus:outline-none focus:ring-1 focus:ring-primary"
                                >
                                    <option value="monthly">Monthly ($9.99/mo)</option>
                                    <option value="yearly">Yearly ($99.99/yr)</option>
                                </select>
                            </div>
                        )}

                        <DialogFooter className="gap-2 sm:justify-end pt-3">
                            <Button
                                type="button"
                                variant="outline"
                                onClick={() => setTierModalUser(null)}
                            >
                                Cancel
                            </Button>
                            <Button
                                type="submit"
                                disabled={tierForm.processing}
                            >
                                {tierForm.processing ? 'Saving...' : 'Apply Tier'}
                            </Button>
                        </DialogFooter>
                    </form>
                </DialogContent>
            </Dialog>

            {/* Change Role Dialog */}
            <Dialog open={!!roleModalUser} onOpenChange={(open) => !open && setRoleModalUser(null)}>
                <DialogContent className="sm:max-w-md">
                    <DialogHeader>
                        <DialogTitle className="text-base font-semibold flex items-center gap-2">
                            <UserCog className="size-4 text-foreground" />
                            Change User Role
                        </DialogTitle>
                        <DialogDescription className="text-xs text-muted-foreground">
                            Update permissions for <span className="text-foreground font-semibold">{roleModalUser?.name}</span>.
                        </DialogDescription>
                    </DialogHeader>

                    <form onSubmit={submitRoleUpdate} className="space-y-4 pt-2">
                        <div className="space-y-1.5">
                            <Label className="text-xs font-medium text-foreground">
                                Role
                            </Label>
                            <select
                                value={roleForm.data.role}
                                onChange={(e) => roleForm.setData('role', e.target.value)}
                                className="w-full h-9 px-3 rounded-md bg-background border border-input text-xs text-foreground focus:outline-none focus:ring-1 focus:ring-primary"
                            >
                                <option value="student">Student (Standard user)</option>
                                <option value="admin">Admin (Full administrative access)</option>
                            </select>
                        </div>

                        <DialogFooter className="gap-2 sm:justify-end pt-3">
                            <Button
                                type="button"
                                variant="outline"
                                onClick={() => setRoleModalUser(null)}
                            >
                                Cancel
                            </Button>
                            <Button
                                type="submit"
                                disabled={roleForm.processing}
                            >
                                {roleForm.processing ? 'Saving...' : 'Save Role'}
                            </Button>
                        </DialogFooter>
                    </form>
                </DialogContent>
            </Dialog>

            {/* Clear AI Dialog */}
            <Dialog open={!!clearAiUser} onOpenChange={(open) => !open && setClearAiUser(null)}>
                <DialogContent className="sm:max-w-md">
                    <DialogHeader>
                        <DialogTitle className="text-base font-semibold flex items-center gap-2 text-destructive">
                            <Trash2 className="size-4" />
                            Clear AI Conversations
                        </DialogTitle>
                        <DialogDescription className="text-xs text-muted-foreground">
                            Delete all AI study conversations for{' '}
                            <span className="text-foreground font-semibold">{clearAiUser?.name}</span>? This action cannot be undone.
                        </DialogDescription>
                    </DialogHeader>

                    <form onSubmit={submitClearAi}>
                        <DialogFooter className="gap-2 sm:justify-end pt-3">
                            <Button
                                type="button"
                                variant="outline"
                                onClick={() => setClearAiUser(null)}
                            >
                                Cancel
                            </Button>
                            <Button
                                type="submit"
                                variant="destructive"
                                disabled={clearAiForm.processing}
                            >
                                {clearAiForm.processing ? 'Clearing...' : 'Clear Conversations'}
                            </Button>
                        </DialogFooter>
                    </form>
                </DialogContent>
            </Dialog>
        </AdminLayout>
    );
}
