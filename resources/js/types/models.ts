export type AssignmentStatus = 'pending' | 'in_progress' | 'completed';

export type UrgencyLevel = 'completed' | 'overdue' | 'due_today' | 'due_soon' | 'upcoming';

export interface UrgencyData {
    urgency_level: UrgencyLevel;
    label: string;
    badge_color: 'emerald' | 'red' | 'amber' | 'blue';
    remaining_time_human: string;
    remark: string;
    hours_remaining: number | null;
    is_overdue: boolean;
    is_due_today: boolean;
    is_due_soon: boolean;
    is_upcoming: boolean;
    is_completed: boolean;
    is_completed_on_time: boolean | null;
}

export interface AssignmentNote {
    id: number;
    assignment_id: number;
    content: string;
    created_at: string;
    updated_at: string;
}

export interface StudyResource {
    id: number;
    user_id: number;
    resourceable_type: string;
    resourceable_id: number;
    title: string;
    file_name: string;
    file_path: string;
    mime_type: string;
    file_size_bytes: number;
    formatted_size?: string;
    extracted_text?: string | null;
    created_at: string;
    updated_at: string;
}

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
    resources?: StudyResource[];
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
    urgency?: UrgencyData;
    notes?: AssignmentNote[];
    resources?: StudyResource[];
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

export interface DashboardMetrics {
    total: number;
    pending: number;
    in_progress: number;
    completed: number;
    overdue: number;
    due_today: number;
    completion_rate: number;
    completed_on_time: number;
    on_time_rate: number | null;
    completed_recently: number;
}

export interface ClassWorkload {
    id: number;
    course_name: string;
    total_assignments: number;
    active_assignments: number;
    completed_assignments: number;
}

export interface DashboardPageProps {
    [key: string]: unknown;
    metrics: DashboardMetrics;
    upcoming_assignments: Assignment[];
    overdue_assignments: Assignment[];
    workload_by_class: ClassWorkload[];
}

export type SubscriptionTier = 'free' | 'basic' | 'premium';
export type SubscriptionStatus = 'active' | 'cancelled' | 'past_due';

export interface Subscription {
    id: number;
    user_id: number;
    tier: SubscriptionTier;
    status: SubscriptionStatus;
    price: number;
    interval: 'monthly' | 'annual';
    card_brand: string;
    card_last_four: string;
    mock_transaction_id?: string;
    starts_at: string;
    ends_at: string | null;
}


