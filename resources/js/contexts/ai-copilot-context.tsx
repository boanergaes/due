import React, { createContext, useContext, useEffect, useState } from 'react';
import type { Assignment } from '@/types';

export interface MentionItem {
    id: number;
    type: 'course' | 'assignment';
    name: string;
    detail?: string;
    course_name?: string;
}

interface AiCopilotContextType {
    isOpen: boolean;
    toggleCopilot: () => void;
    openCopilot: (options?: { activeAssignment?: Assignment | null; defaultPrompt?: string }) => void;
    closeCopilot: () => void;
    sidebarWidth: number;
    setSidebarWidth: (width: number) => void;
    activeAssignment: Assignment | null;
    setActiveAssignment: (assignment: Assignment | null) => void;
    pendingPrompt: string | null;
    setPendingPrompt: (prompt: string | null) => void;
}

const AiCopilotContext = createContext<AiCopilotContextType | undefined>(undefined);

export function AiCopilotProvider({ children }: { children: React.ReactNode }) {
    const [isOpen, setIsOpen] = useState<boolean>(() => {
        if (typeof window !== 'undefined') {
            return localStorage.getItem('due_copilot_open') === 'true';
        }
        return false;
    });

    const [sidebarWidth, setSidebarWidthState] = useState<number>(() => {
        if (typeof window !== 'undefined') {
            const saved = localStorage.getItem('due_copilot_sidebar_width');
            if (saved) {
                const parsed = parseInt(saved, 10);
                if (!isNaN(parsed) && parsed >= 320 && parsed <= 900) {
                    return parsed;
                }
            }
        }
        return 440;
    });

    const [activeAssignment, setActiveAssignment] = useState<Assignment | null>(null);
    const [pendingPrompt, setPendingPrompt] = useState<string | null>(null);

    const setSidebarWidth = (width: number) => {
        const clamped = Math.min(Math.max(width, 320), Math.min(900, window.innerWidth - 64));
        setSidebarWidthState(clamped);
        localStorage.setItem('due_copilot_sidebar_width', String(clamped));
    };

    const toggleCopilot = () => {
        setIsOpen((prev) => {
            const next = !prev;
            localStorage.setItem('due_copilot_open', String(next));
            return next;
        });
    };

    const openCopilot = (options?: { activeAssignment?: Assignment | null; defaultPrompt?: string }) => {
        if (options?.activeAssignment !== undefined) {
            setActiveAssignment(options.activeAssignment);
        }
        if (options?.defaultPrompt) {
            setPendingPrompt(options.defaultPrompt);
        }
        setIsOpen(true);
        localStorage.setItem('due_copilot_open', 'true');
    };

    const closeCopilot = () => {
        setIsOpen(false);
        localStorage.setItem('due_copilot_open', 'false');
    };

    // Global keyboard shortcut: Ctrl+J or Cmd+J
    useEffect(() => {
        const handleKeyDown = (e: KeyboardEvent) => {
            if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'j') {
                e.preventDefault();
                toggleCopilot();
            }
        };

        window.addEventListener('keydown', handleKeyDown);
        return () => window.removeEventListener('keydown', handleKeyDown);
    }, []);

    return (
        <AiCopilotContext.Provider
            value={{
                isOpen,
                toggleCopilot,
                openCopilot,
                closeCopilot,
                sidebarWidth,
                setSidebarWidth,
                activeAssignment,
                setActiveAssignment,
                pendingPrompt,
                setPendingPrompt,
            }}
        >
            {children}
        </AiCopilotContext.Provider>
    );
}

export function useAiCopilot() {
    const context = useContext(AiCopilotContext);
    if (!context) {
        throw new Error('useAiCopilot must be used within an AiCopilotProvider');
    }
    return context;
}
