<?php

namespace App\Models;

use App\Enums\SubscriptionTier;
use App\Enums\UserRole;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Carbon;
use Laravel\Fortify\Contracts\PasskeyUser;
use Laravel\Fortify\PasskeyAuthenticatable;
use Laravel\Fortify\TwoFactorAuthenticatable;
use Laravel\Sanctum\HasApiTokens;

/**
 * @property int $id
 * @property string $name
 * @property string $email
 * @property string $appearance
 * @property UserRole $role
 * @property SubscriptionTier $subscription_tier
 * @property Carbon|null $subscription_expires_at
 * @property int $storage_used_bytes
 * @property Carbon|null $email_verified_at
 * @property string $password
 * @property string|null $two_factor_secret
 * @property string|null $two_factor_recovery_codes
 * @property Carbon|null $two_factor_confirmed_at
 * @property string|null $remember_token
 * @property Carbon|null $created_at
 * @property Carbon|null $updated_at
 * @property-read Collection<int, CourseClass> $classes
 * @property-read Collection<int, Assignment> $assignments
 * @property-read Collection<int, Subscription> $subscriptions
 * @property-read Subscription|null $activeSubscription
 * @property-read Collection<int, \App\Models\Resource> $resources
 * @property-read Collection<int, AiConversation> $aiConversations
 */
#[Fillable([
    'name',
    'email',
    'password',
    'appearance',
    'role',
    'subscription_tier',
    'subscription_expires_at',
    'storage_used_bytes',
])]
#[Hidden(['password', 'two_factor_secret', 'two_factor_recovery_codes', 'remember_token'])]
class User extends Authenticatable implements PasskeyUser
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable, PasskeyAuthenticatable, TwoFactorAuthenticatable;

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'two_factor_confirmed_at' => 'datetime',
            'role' => UserRole::class,
            'subscription_tier' => SubscriptionTier::class,
            'subscription_expires_at' => 'datetime',
            'storage_used_bytes' => 'integer',
        ];
    }

    /**
     * The classes created by the user.
     *
     * @return HasMany<CourseClass, $this>
     */
    public function classes(): HasMany
    {
        return $this->hasMany(CourseClass::class);
    }

    /**
     * The assignments belonging to the user.
     *
     * @return HasMany<Assignment, $this>
     */
    public function assignments(): HasMany
    {
        return $this->hasMany(Assignment::class);
    }

    /**
     * The subscriptions purchased by the user.
     *
     * @return HasMany<Subscription, $this>
     */
    public function subscriptions(): HasMany
    {
        return $this->hasMany(Subscription::class)->orderBy('created_at', 'desc');
    }

    /**
     * The currently active subscription.
     *
     * @return HasOne<Subscription, $this>
     */
    public function activeSubscription(): HasOne
    {
        return $this->hasOne(Subscription::class)->ofMany([
            'id' => 'max',
        ], function ($query) {
            $query->where('status', 'active');
        });
    }

    /**
     * The study resources uploaded by the user.
     *
     * @return HasMany<\App\Models\Resource, $this>
     */
    public function resources(): HasMany
    {
        return $this->hasMany(Resource::class)->orderBy('created_at', 'desc');
    }

    /**
     * The AI study conversations created by the user.
     *
     * @return HasMany<AiConversation, $this>
     */
    public function aiConversations(): HasMany
    {
        return $this->hasMany(AiConversation::class)->orderBy('created_at', 'desc');
    }

    /**
     * Check if user is an Administrator.
     */
    public function isAdmin(): bool
    {
        return $this->role === UserRole::Admin;
    }

    /**
     * Backward-compatible alias for isAdmin.
     */
    public function isSuperAdmin(): bool
    {
        return $this->isAdmin();
    }

    /**
     * Check if user has access to a specific feature flag.
     */
    public function hasFeature(string $feature): bool
    {
        if ($this->isAdmin()) {
            return true;
        }

        return $this->subscription_tier->hasFeature($feature);
    }

    /**
     * Total storage limit quota in bytes.
     */
    public function storageLimitBytes(): int
    {
        if ($this->isAdmin()) {
            return PHP_INT_MAX;
        }

        return $this->subscription_tier->storageLimitBytes();
    }

    /**
     * Check if user has enough quota to upload incoming file bytes.
     */
    public function canUploadResource(int $incomingBytes = 0): bool
    {
        if (! $this->hasFeature(SubscriptionTier::FEATURE_RESOURCES)) {
            return false;
        }

        if ($this->isAdmin()) {
            return true;
        }

        return ($this->storage_used_bytes + $incomingBytes) <= $this->storageLimitBytes();
    }

    /**
     * Recalculate total storage consumed by user resources and persist.
     */
    public function recalculateStorageUsed(): int
    {
        $totalBytes = (int) $this->resources()->sum('file_size_bytes');
        $this->update(['storage_used_bytes' => $totalBytes]);

        return $totalBytes;
    }
}
