<?php

namespace App\Models;

use Database\Factories\AssignmentNoteFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

/**
 * @property int $id
 * @property int $assignment_id
 * @property string $content
 * @property Carbon|null $created_at
 * @property Carbon|null $updated_at
 * @property-read Assignment $assignment
 */
#[Fillable([
    'assignment_id',
    'content',
])]
class AssignmentNote extends Model
{
    /** @use HasFactory<AssignmentNoteFactory> */
    use HasFactory;

    /**
     * The assignment to which the note belongs.
     *
     * @return BelongsTo<Assignment, $this>
     */
    public function assignment(): BelongsTo
    {
        return $this->belongsTo(Assignment::class);
    }
}
