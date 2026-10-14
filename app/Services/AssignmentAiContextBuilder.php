<?php

namespace App\Services;

use App\Models\Assignment;
use App\Models\Resource;
use App\Models\User;
use Illuminate\Support\Collection;

class AssignmentAiContextBuilder
{
    /**
     * Maximum characters of extracted text to include per resource to keep prompt compact.
     */
    public const MAX_RESOURCE_CHARS = 12000;

    /**
     * Build the context prompt and list of context sources for an assignment.
     *
     * @return array{system_instruction: string, context_sources: array<string>}
     */
    public function build(Assignment $assignment): array
    {
        $assignment->loadMissing(['courseClass.resources', 'notes', 'resources']);

        $contextSources = [];

        // 1. Core Assignment metadata
        $courseClass = $assignment->courseClass;
        $className = $courseClass?->course_name ?? 'General Course';
        $teacherName = $courseClass?->teacher_name;

        $urgency = $assignment->urgency;
        $urgencyLabel = $urgency['label'] ?? 'Pending';
        $humanDeadline = $assignment->deadline?->toDayDateTimeString() ?? 'No deadline set';

        $promptParts = [];
        $promptParts[] = "### ASSIGNMENT OVERVIEW\n"
            ."- Title: {$assignment->title}\n"
            ."- Course: {$className}".($teacherName ? " (Instructor: {$teacherName})" : '')."\n"
            ."- Deadline: {$humanDeadline} [Urgency: {$urgencyLabel}]\n"
            .'- Current Status: '.ucfirst($assignment->status->value)."\n"
            .'- Description: '.($assignment->description ? trim($assignment->description) : 'No description provided by student.');

        $contextSources[] = 'Assignment Details';

        // 2. Student Notes
        $notes = $assignment->notes;
        if ($notes->isNotEmpty()) {
            $notesList = [];
            foreach ($notes as $idx => $note) {
                $num = $idx + 1;
                $date = $note->created_at?->format('M d') ?? '';
                $notesList[] = "  [Note #{$num} ({$date})]: ".trim($note->content);
            }
            $promptParts[] = "### STUDENT'S ATTACHED NOTES\n".implode("\n", $notesList);
            $contextSources[] = "{$notes->count()} Assignment ".($notes->count() === 1 ? 'Note' : 'Notes');
        }

        // 3. Assignment & Class Resources
        $allResources = $assignment->resources->concat($courseClass?->resources ?? collect());
        /** @var Collection<int, resource> $uniqueResources */
        $uniqueResources = $allResources->unique('id');

        if ($uniqueResources->isNotEmpty()) {
            $resourceSnippets = [];
            foreach ($uniqueResources as $resource) {
                $sourceLabel = $resource->file_name;
                $contextSources[] = $sourceLabel;

                if (! empty($resource->extracted_text)) {
                    $truncatedText = mb_substr(trim($resource->extracted_text), 0, self::MAX_RESOURCE_CHARS);
                    $hasMore = mb_strlen(trim($resource->extracted_text)) > self::MAX_RESOURCE_CHARS ? '... [Content truncated for brevity]' : '';
                    $resourceSnippets[] = "- File '{$resource->file_name}' ({$resource->mime_type}, {$resource->formattedSize()}):\n"
                        ."```text\n{$truncatedText}{$hasMore}\n```";
                } else {
                    $resourceSnippets[] = "- File '{$resource->file_name}' ({$resource->mime_type}, {$resource->formattedSize()}) [Binary/Media file attached]";
                }
            }
            $promptParts[] = "### ATTACHED STUDY MATERIALS & EXTRACTED TEXT\n".implode("\n\n", $resourceSnippets);
        }

        $contextBlock = implode("\n\n", $promptParts);

        $systemInstruction = <<<INSTRUCTION
You are Due Copilot, an elite academic tutor and study assistant integrated into the Due academic coursework platform.
Your mission is to help the student thoroughly understand, plan, break down, and successfully complete their assignment.

ACADEMIC & SOCRATIC TUTORING GUIDELINES:
1. Socratic Teaching: Guide the student with questions, conceptual explanations, architectural frameworks, step-by-step roadmaps, and checklist milestones.
2. Academic Integrity: Do NOT write complete copy-paste final solutions for essays, code labs, or problem sets that promote academic dishonesty. Instead, explain the underlying logic, provide illustrative pseudocode or minimal syntax examples, and critique the student's own thought process.
3. Grounding & Citations: Base your answers specifically on the attached assignment details, student notes, and extracted resource texts provided below. When referring to facts or requirements from attached files, cite the specific filename (e.g. "According to syllabus.pdf...").
4. Tone & Style: Be encouraging, concise, highly structured, and intellectually rigorous. Use Markdown formatting, bullet points, and code syntax highlighting where appropriate.
5. Action-Oriented: Whenever helpful, suggest the next concrete step or milestone the student should work on.

CURRENT ASSIGNMENT CONTEXT:
{$contextBlock}
INSTRUCTION;

        return [
            'system_instruction' => $systemInstruction,
            'context_sources' => array_values(array_unique($contextSources)),
        ];
    }

    /**
     * Build system context for global chat, supporting @mentioned courses and assignments.
     *
     * @param  array<int, array{type: string, id: int, name?: string}>  $mentions
     * @return array{system_instruction: string, context_sources: array<string>}
     */
    public function buildForWorkspace(User $user, ?Assignment $currentAssignment = null, array $mentions = []): array
    {
        $contextSources = [];
        $promptParts = [];

        // 1. Current active assignment context (if on an assignment page)
        if ($currentAssignment && $currentAssignment->user_id === $user->id) {
            $currentAssignment->loadMissing(['courseClass.resources', 'notes', 'resources']);
            $urgency = $currentAssignment->urgency;
            $urgencyLabel = $urgency['label'] ?? 'Pending';
            $humanDeadline = $currentAssignment->deadline?->toDayDateTimeString() ?? 'No deadline set';
            $className = $currentAssignment->courseClass?->course_name ?? 'General Course';

            $promptParts[] = "### CURRENT VIEWED ASSIGNMENT\n"
                ."- Title: {$currentAssignment->title}\n"
                ."- Course: {$className}\n"
                ."- Deadline: {$humanDeadline} [Urgency: {$urgencyLabel}]\n"
                .'- Status: '.ucfirst($currentAssignment->status->value)."\n"
                .'- Description: '.($currentAssignment->description ? trim($currentAssignment->description) : 'No description.');

            $contextSources[] = "Current: {$currentAssignment->title}";

            // Add notes
            if ($currentAssignment->notes->isNotEmpty()) {
                $noteLines = $currentAssignment->notes->map(fn ($n) => "  - {$n->content}")->all();
                $promptParts[] = "### CURRENT ASSIGNMENT NOTES\n".implode("\n", $noteLines);
                $contextSources[] = "{$currentAssignment->notes->count()} Notes";
            }

            // Add resources
            foreach ($currentAssignment->resources as $res) {
                $contextSources[] = $res->file_name;
                if (! empty($res->extracted_text)) {
                    $truncated = mb_substr(trim($res->extracted_text), 0, self::MAX_RESOURCE_CHARS);
                    $promptParts[] = "### RESOURCE: {$res->file_name}\n```text\n{$truncated}\n```";
                }
            }
        }

        // 2. Resolve @mentioned courses
        $mentionedCourseIds = collect($mentions)
            ->filter(fn ($m) => ($m['type'] ?? '') === 'course' || ($m['type'] ?? '') === 'class')
            ->pluck('id')
            ->unique()
            ->all();

        if (! empty($mentionedCourseIds)) {
            $courses = $user->classes()
                ->whereIn('id', $mentionedCourseIds)
                ->with(['resources', 'assignments'])
                ->get();

            foreach ($courses as $course) {
                $contextSources[] = "@Course: {$course->course_name}";
                $courseAssignments = $course->assignments->map(fn ($a) => "  - [{$a->status->value}] {$a->title} (Due: ".($a->deadline?->toFormattedDateString() ?? 'N/A').')')->all();
                $assignmentsBlock = ! empty($courseAssignments) ? implode("\n", $courseAssignments) : '  None';

                $cBlock = "### @MENTIONED COURSE: {$course->course_name}\n"
                    .($course->teacher_name ? "- Instructor: {$course->teacher_name}\n" : '')
                    .($course->credit_hours ? "- Credit Hours: {$course->credit_hours}\n" : '')
                    ."- Active Assignments:\n{$assignmentsBlock}";

                // Course resources
                if ($course->resources->isNotEmpty()) {
                    $resList = [];
                    foreach ($course->resources as $cRes) {
                        $contextSources[] = $cRes->file_name;
                        if (! empty($cRes->extracted_text)) {
                            $cText = mb_substr(trim($cRes->extracted_text), 0, self::MAX_RESOURCE_CHARS);
                            $resList[] = "  * File '{$cRes->file_name}' ({$cRes->mime_type}):\n```text\n{$cText}\n```";
                        } else {
                            $resList[] = "  * File '{$cRes->file_name}' ({$cRes->mime_type})";
                        }
                    }
                    $cBlock .= "\n- Course Syllabus & Attached Study Materials:\n".implode("\n", $resList);
                }

                $promptParts[] = $cBlock;
            }
        }

        // 3. Resolve @mentioned assignments
        $mentionedAssignmentIds = collect($mentions)
            ->filter(fn ($m) => ($m['type'] ?? '') === 'assignment')
            ->pluck('id')
            ->unique()
            ->all();

        if (! empty($mentionedAssignmentIds)) {
            $assignments = $user->assignments()
                ->whereIn('id', $mentionedAssignmentIds)
                ->with(['courseClass', 'notes', 'resources'])
                ->get();

            foreach ($assignments as $asgn) {
                $contextSources[] = "@Assignment: {$asgn->title}";
                $aUrgency = $asgn->urgency;
                $aBlock = "### @MENTIONED ASSIGNMENT: {$asgn->title}\n"
                    .'- Course: '.($asgn->courseClass?->course_name ?? 'N/A')."\n"
                    .'- Status: '.ucfirst($asgn->status->value)."\n"
                    .'- Deadline: '.($asgn->deadline?->toDayDateTimeString() ?? 'N/A')." [{$aUrgency['label']}]\n"
                    .'- Description: '.($asgn->description ? trim($asgn->description) : 'None');

                if ($asgn->notes->isNotEmpty()) {
                    $aNotes = $asgn->notes->map(fn ($n) => "  - {$n->content}")->all();
                    $aBlock .= "\n- Attached Notes:\n".implode("\n", $aNotes);
                }

                if ($asgn->resources->isNotEmpty()) {
                    $aResList = [];
                    foreach ($asgn->resources as $aRes) {
                        $contextSources[] = $aRes->file_name;
                        if (! empty($aRes->extracted_text)) {
                            $aText = mb_substr(trim($aRes->extracted_text), 0, self::MAX_RESOURCE_CHARS);
                            $aResList[] = "  * File '{$aRes->file_name}':\n```text\n{$aText}\n```";
                        } else {
                            $aResList[] = "  * File '{$aRes->file_name}' ({$aRes->mime_type})";
                        }
                    }
                    $aBlock .= "\n- Attached Resources:\n".implode("\n", $aResList);
                }

                $promptParts[] = $aBlock;
            }
        }

        // 4. Default General Academic Workspace Overview (if no specific assignment/mentions)
        if (empty($promptParts)) {
            $totalClasses = $user->classes()->count();
            $pendingAssignments = $user->assignments()->pending()->take(5)->get();
            $tasksList = $pendingAssignments->map(fn ($a) => "- {$a->title} (Due: ".($a->deadline?->toFormattedDateString() ?? 'N/A').')')->all();
            $tasksBlock = ! empty($tasksList) ? implode("\n", $tasksList) : 'None';

            $promptParts[] = "### STUDENT'S OVERALL WORKSPACE OVERVIEW\n"
                ."- Enrolled Courses: {$totalClasses}\n"
                ."- Next Pending Coursework:\n{$tasksBlock}\n"
                .'- Note: The student can mention specific courses or assignments by typing @ before their name.';

            $contextSources[] = 'Workspace Overview';
        }

        $contextBlock = implode("\n\n", $promptParts);

        $systemInstruction = <<<INSTRUCTION
You are Due Copilot, an elite academic tutor and coursework copilot integrated into the Due student platform.
You are running as a side-by-side study assistant accessible across the student's entire workspace.

ACADEMIC & SOCRATIC TUTORING GUIDELINES:
1. Socratic Teaching: Guide the student with questions, conceptual explanations, architectural frameworks, step-by-step roadmaps, and checklist milestones.
2. Academic Integrity: Do NOT write complete copy-paste final solutions for essays, code labs, or problem sets that promote academic dishonesty. Instead, explain the underlying logic, provide illustrative pseudocode or minimal syntax examples, and critique the student's own thought process.
3. @Mentions & Grounding: The student can mention specific courses or assignments by typing @ before their name. Ground your answers specifically in the details, notes, and study resources of the mentioned items provided below. Always cite relevant files (e.g. "According to syllabus.pdf...").
4. Tone & Style: Be encouraging, concise, highly structured, and intellectually rigorous. Use Markdown formatting, bullet points, and code syntax highlighting where appropriate.
5. Action-Oriented: Suggest concrete next steps or study milestones to keep the student on track before deadlines.

CURRENT ACADEMIC CONTEXT:
{$contextBlock}
INSTRUCTION;

        return [
            'system_instruction' => $systemInstruction,
            'context_sources' => array_values(array_unique($contextSources)),
        ];
    }
}
