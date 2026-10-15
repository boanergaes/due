export type User = {
    id: number;
    name: string;
    email: string;
    avatar?: string;
    email_verified_at: string | null;
    appearance?: 'light' | 'dark' | 'system';
    role?: 'student' | 'admin';
    subscription_tier?: 'free' | 'basic' | 'premium';
    subscription_expires_at?: string | null;
    storage_used_bytes?: number;
    two_factor_enabled?: boolean;
    created_at: string;
    updated_at: string;
    [key: string]: unknown;
};

export type UserSubscriptionInfo = {
    tier: 'free' | 'basic' | 'premium';
    tier_label: string;
    role: 'student' | 'admin';
    is_admin?: boolean;
    is_super_admin?: boolean;
    features: string[];
    storage_used_bytes: number;
    storage_limit_bytes: number;
    expires_at: string | null;
};

export type Auth = {
    user: User;
    subscription?: UserSubscriptionInfo | null;
};

export type Passkey = {
    id: number;
    name: string;
    authenticator: string | null;
    created_at_diff: string;
    last_used_at_diff: string | null;
};

export type TwoFactorSetupData = {
    svg: string;
    url: string;
};

export type TwoFactorSecretKey = {
    secretKey: string;
};
