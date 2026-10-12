import { AlertCircle, AlertTriangle, Calendar, CheckCircle2, Clock } from 'lucide-react';
import type { UrgencyData } from '@/types';

interface UrgencyBadgeProps {
    urgency?: UrgencyData;
    showRemark?: boolean;
    className?: string;
}

export function UrgencyBadge({ urgency, showRemark = false, className = '' }: UrgencyBadgeProps) {
    if (!urgency) {
        return null;
    }

    const { urgency_level, remaining_time_human, remark } = urgency;

    const config = {
        overdue: {
            container: 'border-red-500/40 bg-red-500/10 text-red-400',
            icon: AlertCircle,
            pulse: true,
        },
        due_today: {
            container: 'border-amber-500/40 bg-amber-500/10 text-amber-400',
            icon: AlertTriangle,
            pulse: true,
        },
        due_soon: {
            container: 'border-amber-500/30 bg-amber-500/5 text-amber-300',
            icon: Clock,
            pulse: false,
        },
        upcoming: {
            container: 'border-blue-500/30 bg-blue-500/10 text-blue-400',
            icon: Calendar,
            pulse: false,
        },
        completed: {
            container: 'border-emerald-500/30 bg-emerald-500/10 text-emerald-400',
            icon: CheckCircle2,
            pulse: false,
        },
    }[urgency_level];

    const Icon = config.icon;

    return (
        <div className={`inline-flex flex-col gap-0.5 ${className}`}>
            <span
                className={`inline-flex items-center gap-1.5 border px-2 py-0.5 font-mono text-xs font-medium rounded-none ${config.container}`}
                title={remark}
            >
                <Icon className={`size-3 ${config.pulse ? 'animate-pulse' : ''}`} />
                {remaining_time_human}
            </span>
            {showRemark && (
                <span className="text-[11px] text-muted-foreground font-mono">
                    {remark}
                </span>
            )}
        </div>
    );
}
