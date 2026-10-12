<?php

namespace App\Models;

use App\Enums\AssignmentStatus;
use App\Services\DeadlineUrgencyService;
use Database\Factories\AssignmentFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Carbon;

/**
 * @property int $id
 * @property int $user_id
 * @property int $class_id
 * @property string $title
 * @property string|null $description
 * @property AssignmentStatus $status
 * @property Carbon $deadline
 * @property Carbon|null $completed_at
 * @property Carbon|null $created_at
 * @property Carbon|null $updated_at
 * @property-read User $user
 * @property-read CourseClass $class
 * @property-read Collection<int, AssignmentNote> $notes
 */
#[Fillable([
    'user_id',
    'class_id',
    'title',
    'description',
    'status',
    'deadline',
    'completed_at',
])]
class Assignment extends Model
{
    /** @use HasFactory<AssignmentFactory> */
    use HasFactory;

    /**
     * The accessors to append to the model's array form.
     *
     * @var list<string>
     */
    protected $appends = ['urgency'];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'status' => AssignmentStatus::class,
            'deadline' => 'datetime',
            'completed_at' => 'datetime',
        ];
    }

    /**
     * Get the calculated deadline urgency metrics for the assignment.
     *
     * @return array<string, mixed>
     */
    public function getUrgencyAttribute(): array
    {
        return app(DeadlineUrgencyService::class)->calculate($this);
    }

    /**
     * The user that owns the assignment.
     *
     * @return BelongsTo<User, $this>
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * The class to which the assignment belongs.
     *
     * @return BelongsTo<CourseClass, $this>
     */
    public function class(): BelongsTo
    {
        return $this->belongsTo(CourseClass::class, 'class_id');
    }

    /**
     * Alias for class() relationship.
     *
     * @return BelongsTo<CourseClass, $this>
     */
    public function courseClass(): BelongsTo
    {
        return $this->class();
    }

    /**
     * The notes associated with this assignment.
     *
     * @return HasMany<AssignmentNote, $this>
     */
    public function notes(): HasMany
    {
        return $this->hasMany(AssignmentNote::class);
    }

    /**
     * Scope a query to only include pending assignments.
     *
     * @param  Builder<$this>  $query
     */
    public function scopePending(Builder $query): Builder
    {
        return $query->where('status', AssignmentStatus::Pending);
    }

    /**
     * Scope a query to only include in-progress assignments.
     *
     * @param  Builder<$this>  $query
     */
    public function scopeInProgress(Builder $query): Builder
    {
        return $query->where('status', AssignmentStatus::InProgress);
    }

    /**
     * Scope a query to only include completed assignments.
     *
     * @param  Builder<$this>  $query
     */
    public function scopeCompleted(Builder $query): Builder
    {
        return $query->where('status', AssignmentStatus::Completed);
    }
}
