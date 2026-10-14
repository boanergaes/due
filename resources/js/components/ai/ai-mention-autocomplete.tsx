import { CheckSquare, GraduationCap, X } from 'lucide-react';
import React, { useEffect, useRef, useState } from 'react';
import { Badge } from '@/components/ui/badge';
import type { MentionItem } from '@/contexts/ai-copilot-context';

interface AiMentionAutocompleteProps {
    value: string;
    onChange: (value: string) => void;
    onSubmit: () => void;
    disabled?: boolean;
    mentions: MentionItem[];
    onAddMention: (item: MentionItem) => void;
    onRemoveMention: (id: number, type: 'course' | 'assignment') => void;
    textareaRef?: React.RefObject<HTMLTextAreaElement | null>;
}

export function AiMentionAutocomplete({
    value,
    onChange,
    onSubmit,
    disabled = false,
    mentions,
    onAddMention,
    onRemoveMention,
    textareaRef,
}: AiMentionAutocompleteProps) {
    const [allCourses, setAllCourses] = useState<MentionItem[]>([]);
    const [allAssignments, setAllAssignments] = useState<MentionItem[]>([]);
    const [showDropdown, setShowDropdown] = useState<boolean>(false);
    const [mentionQuery, setMentionQuery] = useState<string>('');
    const [selectedIndex, setSelectedIndex] = useState<number>(0);
    const [mentionStartPos, setMentionStartPos] = useState<number>(-1);

    const dropdownRef = useRef<HTMLDivElement>(null);

    // Fetch mentionables on mount
    useEffect(() => {
        fetch('/ai/mentionables', {
            headers: {
                Accept: 'application/json',
                'X-Requested-With': 'XMLHttpRequest',
            },
        })
            .then((res) => (res.ok ? res.json() : { courses: [], assignments: [] }))
            .then((data) => {
                setAllCourses(data.courses || []);
                setAllAssignments(data.assignments || []);
            })
            .catch(() => {});
    }, []);

    // Filter items based on mentionQuery
    const filteredCourses = allCourses.filter((c) =>
        c.name.toLowerCase().includes(mentionQuery.toLowerCase())
    );
    const filteredAssignments = allAssignments.filter((a) =>
        a.name.toLowerCase().includes(mentionQuery.toLowerCase()) ||
        (a.course_name && a.course_name.toLowerCase().includes(mentionQuery.toLowerCase()))
    );

    const combinedItems = [...filteredCourses, ...filteredAssignments];

    // Detect @ trigger in textarea
    const handleTextChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
        const newValue = e.target.value;
        const cursor = e.target.selectionStart || 0;
        onChange(newValue);

        // Find last @ before or at cursor
        const textBeforeCursor = newValue.slice(0, cursor);
        const atIndex = textBeforeCursor.lastIndexOf('@');

        if (atIndex !== -1) {
            // Check if there is no space between @ and cursor (or if it's a current query)
            const query = textBeforeCursor.slice(atIndex + 1);
            // Don't show if there's a newline or too long
            if (!query.includes('\n') && query.length <= 40) {
                setMentionStartPos(atIndex);
                setMentionQuery(query);
                setShowDropdown(true);
                setSelectedIndex(0);
                return;
            }
        }

        setShowDropdown(false);
    };

    const selectItem = (item: MentionItem) => {
        if (mentionStartPos === -1) return;

        const cursor = textareaRef?.current?.selectionStart || value.length;
        const beforeAt = value.slice(0, mentionStartPos);
        const afterCursor = value.slice(cursor);

        const replacement = `@${item.name} `;
        const updated = beforeAt + replacement + afterCursor;

        onChange(updated);
        onAddMention(item);
        setShowDropdown(false);

        // Focus back on textarea
        setTimeout(() => {
            if (textareaRef?.current) {
                const newPos = beforeAt.length + replacement.length;
                textareaRef.current.focus();
                textareaRef.current.setSelectionRange(newPos, newPos);
            }
        }, 10);
    };

    const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
        if (showDropdown && combinedItems.length > 0) {
            if (e.key === 'ArrowDown') {
                e.preventDefault();
                setSelectedIndex((prev) => (prev + 1) % combinedItems.length);
                return;
            }
            if (e.key === 'ArrowUp') {
                e.preventDefault();
                setSelectedIndex((prev) => (prev - 1 + combinedItems.length) % combinedItems.length);
                return;
            }
            if (e.key === 'Enter' || e.key === 'Tab') {
                e.preventDefault();
                const selected = combinedItems[selectedIndex];
                if (selected) {
                    selectItem(selected);
                }
                return;
            }
            if (e.key === 'Escape') {
                e.preventDefault();
                setShowDropdown(false);
                return;
            }
        }

        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            onSubmit();
        }
    };

    return (
        <div className="relative space-y-2">
            {/* Active Mention Chips Banner */}
            {mentions.length > 0 && (
                <div className="flex flex-wrap items-center gap-1.5 pb-1">
                    <span className="text-[10px] font-mono uppercase tracking-wider text-muted-foreground mr-1">
                        Referenced:
                    </span>
                    {mentions.map((m) => (
                        <span
                            key={`${m.type}-${m.id}`}
                            className="inline-flex items-center gap-1 border border-primary/40 bg-primary/10 text-primary font-mono text-[11px] px-2 py-0.5 rounded-none"
                        >
                            {m.type === 'course' ? (
                                <GraduationCap className="size-3" />
                            ) : (
                                <CheckSquare className="size-3" />
                            )}
                            <span className="font-medium max-w-[150px] truncate">{m.name}</span>
                            <button
                                type="button"
                                onClick={() => onRemoveMention(m.id, m.type)}
                                className="hover:text-destructive transition-colors ml-0.5 cursor-pointer"
                                title="Remove reference"
                            >
                                <X className="size-3" />
                            </button>
                        </span>
                    ))}
                </div>
            )}

            {/* Autocomplete Floating Dropdown */}
            {showDropdown && combinedItems.length > 0 && (
                <div
                    ref={dropdownRef}
                    className="absolute bottom-full left-0 right-0 mb-1 z-50 border border-border bg-zinc-950 shadow-2xl rounded-none overflow-hidden max-h-60 overflow-y-auto"
                >
                    <div className="px-3 py-1.5 bg-zinc-900 border-b border-border/60 text-[10px] font-mono uppercase tracking-wider text-muted-foreground flex items-center justify-between">
                        <span>Mention Course or Assignment (@)</span>
                        <span>Use ↑↓ to navigate, Enter to select</span>
                    </div>

                    <div className="divide-y divide-border/40">
                        {combinedItems.slice(0, 10).map((item, idx) => {
                            const isSelected = idx === selectedIndex;
                            return (
                                <button
                                    key={`${item.type}-${item.id}`}
                                    type="button"
                                    onClick={() => selectItem(item)}
                                    className={`w-full p-2.5 text-left flex items-start gap-2.5 transition-colors cursor-pointer rounded-none ${
                                        isSelected
                                            ? 'bg-primary/15 border-l-2 border-primary text-foreground'
                                            : 'hover:bg-muted/40 text-zinc-300'
                                    }`}
                                >
                                    <div className="size-6 rounded-none bg-muted border border-border flex items-center justify-center shrink-0 mt-0.5 text-primary">
                                        {item.type === 'course' ? (
                                            <GraduationCap className="size-3.5" />
                                        ) : (
                                            <CheckSquare className="size-3.5" />
                                        )}
                                    </div>
                                    <div className="flex-1 min-w-0">
                                        <div className="flex items-center gap-1.5">
                                            <Badge
                                                variant="outline"
                                                className={`rounded-none text-[9px] font-mono px-1 py-0 ${
                                                    item.type === 'course'
                                                        ? 'border-sky-500/40 text-sky-400 bg-sky-500/10'
                                                        : 'border-emerald-500/40 text-emerald-400 bg-emerald-500/10'
                                                }`}
                                            >
                                                {item.type === 'course' ? 'COURSE' : 'TASK'}
                                            </Badge>
                                            <span className="text-xs font-semibold text-foreground truncate">
                                                {item.name}
                                            </span>
                                        </div>
                                        {item.detail && (
                                            <p className="text-[11px] text-muted-foreground truncate font-mono mt-0.5">
                                                {item.detail}
                                            </p>
                                        )}
                                    </div>
                                </button>
                            );
                        })}
                    </div>
                </div>
            )}

            {/* Textarea */}
            <textarea
                ref={textareaRef}
                value={value}
                onChange={handleTextChange}
                onKeyDown={handleKeyDown}
                placeholder="Ask Due Copilot anything... Type @ to mention a course or assignment"
                rows={3}
                disabled={disabled}
                className="w-full resize-none bg-background border border-input p-3 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:border-primary rounded-none font-sans"
            />
        </div>
    );
}
