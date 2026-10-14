<?php

namespace App\Enums;

enum SubscriptionTier: string
{
    case Free = 'free';
    case Basic = 'basic';
    case Premium = 'premium';

    public const FEATURE_CORE = 'feature:core';

    public const FEATURE_RESOURCES = 'feature:resources';

    public const FEATURE_AI = 'feature:ai';

    public function label(): string
    {
        return match ($this) {
            self::Free => 'Free',
            self::Basic => 'Scholar',
            self::Premium => 'Genius',
        };
    }

    public function monthlyPrice(): float
    {
        return match ($this) {
            self::Free => 0.00,
            self::Basic => 4.99,
            self::Premium => 9.99,
        };
    }

    public function annualPrice(): float
    {
        return match ($this) {
            self::Free => 0.00,
            self::Basic => 49.00,
            self::Premium => 99.00,
        };
    }

    /**
     * @return array<string>
     */
    public function features(): array
    {
        return match ($this) {
            self::Free => [
                self::FEATURE_CORE,
            ],
            self::Basic => [
                self::FEATURE_CORE,
                self::FEATURE_RESOURCES,
            ],
            self::Premium => [
                self::FEATURE_CORE,
                self::FEATURE_RESOURCES,
                self::FEATURE_AI,
            ],
        };
    }

    public function hasFeature(string $feature): bool
    {
        return in_array($feature, $this->features(), true);
    }

    /**
     * Storage quota in bytes.
     */
    public function storageLimitBytes(): int
    {
        return match ($this) {
            self::Free => 0,
            self::Basic => 524_288_000,      // 500 MB
            self::Premium => 5_368_709_120,   // 5 GB
        };
    }

    /**
     * Max single file upload size in megabytes.
     */
    public function maxFileSizeMb(): int
    {
        return match ($this) {
            self::Free => 0,
            self::Basic => 25,
            self::Premium => 100,
        };
    }

    /**
     * Max single file upload size in bytes.
     */
    public function maxFileSizeBytes(): int
    {
        return match ($this) {
            self::Free => 0,
            self::Basic => 26_214_400,       // 25 MB
            self::Premium => 104_857_600,    // 100 MB
        };
    }

    /**
     * @return array<string>
     */
    public static function values(): array
    {
        return array_column(self::cases(), 'value');
    }
}
