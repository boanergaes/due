<?php

namespace App\Http\Requests\Assignments;

use App\Enums\AssignmentStatus;
use App\Models\Assignment;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Enum;

class UpdateAssignmentRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        $assignment = $this->route('assignment');

        return $assignment instanceof Assignment
            ? $this->user()?->can('update', $assignment) ?? false
            : true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'class_id' => [
                'required',
                'integer',
                Rule::exists('classes', 'id')->where('user_id', $this->user()?->id),
            ],
            'title' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string', 'max:5000'],
            'status' => ['required', new Enum(AssignmentStatus::class)],
            'deadline' => ['required', 'date'],
        ];
    }

    /**
     * Custom message for class_id validation.
     *
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'class_id.exists' => 'The selected class is invalid or does not belong to you.',
        ];
    }
}
