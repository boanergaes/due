<?php

namespace App\Policies;

use App\Enums\SubscriptionTier;
use App\Models\Resource;
use App\Models\User;

class ResourcePolicy
{
    /**
     * Determine whether the user can view the resource.
     */
    public function view(User $user, Resource $resource): bool
    {
        return $user->isSuperAdmin() || $user->id === $resource->user_id;
    }

    /**
     * Determine whether the user can create resources.
     */
    public function create(User $user): bool
    {
        return $user->isSuperAdmin() || $user->hasFeature(SubscriptionTier::FEATURE_RESOURCES);
    }

    /**
     * Determine whether the user can delete the resource.
     */
    public function delete(User $user, Resource $resource): bool
    {
        return $user->isSuperAdmin() || $user->id === $resource->user_id;
    }

    /**
     * Determine whether the user can download the resource.
     */
    public function download(User $user, Resource $resource): bool
    {
        return $user->isSuperAdmin() || $user->id === $resource->user_id;
    }
}
