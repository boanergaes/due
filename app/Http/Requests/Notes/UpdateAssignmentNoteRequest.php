<?php

namespace App\Http\Requests\Notes;

use App\Models\Assignment;
use App\Models\AssignmentNote;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class UpdateAssignmentNoteRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        $assignment = $this->route('assignment');
        $note = $this->route('note');

        if (! $assignment instanceof Assignment || ! $note instanceof AssignmentNote) {
            return false;
        }

        if ($note->assignment_id !== $assignment->id) {
            return false;
        }

        return $this->user()?->can('update', $note) ?? false;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'content' => ['required', 'string', 'max:5000'],
        ];
    }
}
