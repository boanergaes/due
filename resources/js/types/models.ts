export type AssignmentStatus = 'pending' | 'in_progress' | 'completed';

export interface CourseClass {
    id: number;
    user_id: number;
    course_name: string;
    teacher_name: string | null;
    teacher_contact: string | null;
    credit_hours: number | null;
    ects: number | null;
    created_at: string;
    updated_at: string;
    assignments_count?: number;
    assignments?: Assignment[];
}

export interface Assignment {
    id: number;
    user_id: number;
    class_id: number;
    title: string;
    description: string | null;
    status: AssignmentStatus;
    deadline: string;
    completed_at: string | null;
    created_at: string;
    updated_at: string;
    course_class?: CourseClass;
}

export interface PaginationLink {
    url: string | null;
    label: string;
    active: boolean;
}

export interface PaginatedData<T> {
    data: T[];
    current_page: number;
    first_page_url: string;
    from: number | null;
    last_page: number;
    last_page_url: string;
    links: PaginationLink[];
    next_page_url: string | null;
    path: string;
    per_page: number;
    prev_page_url: string | null;
    to: number | null;
    total: number;
}
