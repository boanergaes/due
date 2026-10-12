<?php

namespace App\Http\Requests\Classes;

use Illuminate\Foundation\Http\FormRequest;

class StoreCourseClassRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'course_name' => ['required', 'string', 'max:255'],
            'teacher_name' => ['nullable', 'string', 'max:255'],
            'teacher_contact' => ['nullable', 'string', 'max:255'],
            'credit_hours' => ['nullable', 'integer', 'min:0', 'max:100'],
            'ects' => ['nullable', 'numeric', 'min:0', 'max:100'],
        ];
    }
}
