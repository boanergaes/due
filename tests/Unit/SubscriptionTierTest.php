<?php

use App\Enums\SubscriptionTier;
use App\Enums\UserRole;

test('subscription tier has expected labels and prices', function () {
    expect(SubscriptionTier::Free->label())->toBe('Free');
    expect(SubscriptionTier::Basic->label())->toBe('Scholar');
    expect(SubscriptionTier::Premium->label())->toBe('Genius');

    expect(SubscriptionTier::Free->monthlyPrice())->toBe(0.00);
    expect(SubscriptionTier::Basic->monthlyPrice())->toBe(4.99);
    expect(SubscriptionTier::Premium->monthlyPrice())->toBe(9.99);

    expect(SubscriptionTier::Free->annualPrice())->toBe(0.00);
    expect(SubscriptionTier::Basic->annualPrice())->toBe(49.00);
    expect(SubscriptionTier::Premium->annualPrice())->toBe(99.00);
});

test('free tier only has core feature', function () {
    $tier = SubscriptionTier::Free;

    expect($tier->hasFeature(SubscriptionTier::FEATURE_CORE))->toBeTrue();
    expect($tier->hasFeature(SubscriptionTier::FEATURE_RESOURCES))->toBeFalse();
    expect($tier->hasFeature(SubscriptionTier::FEATURE_AI))->toBeFalse();
    expect($tier->storageLimitBytes())->toBe(0);
    expect($tier->maxFileSizeBytes())->toBe(0);
});

test('scholar tier has resources feature and 500MB quota', function () {
    $tier = SubscriptionTier::Basic;

    expect($tier->hasFeature(SubscriptionTier::FEATURE_CORE))->toBeTrue();
    expect($tier->hasFeature(SubscriptionTier::FEATURE_RESOURCES))->toBeTrue();
    expect($tier->hasFeature(SubscriptionTier::FEATURE_AI))->toBeFalse();
    expect($tier->storageLimitBytes())->toBe(524_288_000); // 500 MB
    expect($tier->maxFileSizeBytes())->toBe(26_214_400);   // 25 MB
});

test('genius tier has resources and ai features and 5GB quota', function () {
    $tier = SubscriptionTier::Premium;

    expect($tier->hasFeature(SubscriptionTier::FEATURE_CORE))->toBeTrue();
    expect($tier->hasFeature(SubscriptionTier::FEATURE_RESOURCES))->toBeTrue();
    expect($tier->hasFeature(SubscriptionTier::FEATURE_AI))->toBeTrue();
    expect($tier->storageLimitBytes())->toBe(5_368_709_120); // 5 GB
    expect($tier->maxFileSizeBytes())->toBe(104_857_600);    // 100 MB
});

test('user role enum checks super admin correctly', function () {
    expect(UserRole::Student->isSuperAdmin())->toBeFalse();
    expect(UserRole::SuperAdmin->isSuperAdmin())->toBeTrue();
    expect(UserRole::Student->label())->toBe('Student');
    expect(UserRole::SuperAdmin->label())->toBe('Super Administrator');
});
