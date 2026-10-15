import { Link, usePage } from '@inertiajs/react';
import {
    AlertCircle,
    BotMessageSquare,
    Database,
    FileText,
    GripVertical,
    Lock,
    Minimize2,
    RefreshCw,
    Send,
    Sparkles,
    Trash2,
    User as UserIcon,
    X,
} from 'lucide-react';
import React, { useEffect, useRef, useState } from 'react';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
} from '@/components/ui/dialog';
import { MentionItem, useAiCopilot } from '@/contexts/ai-copilot-context';
import { AiMentionAutocomplete } from './ai-mention-autocomplete';
import { FormattedMarkdown } from './formatted-markdown';
import type { AiMessage, Auth } from '@/types';

export function AiCopilotSidebar() {
    const {
        isOpen,
        closeCopilot,
        sidebarWidth,
        setSidebarWidth,
        activeAssignment,
        setActiveAssignment,
        pendingPrompt,
        setPendingPrompt,
    } = useAiCopilot();

    const pageProps = usePage().props as { auth?: Auth };
    const auth = pageProps.auth;

    const isGenius =
        auth?.user?.subscription_tier === 'premium' ||
        auth?.user?.role === 'admin' ||
        auth?.user?.role === 'super_admin' ||
        auth?.subscription?.is_admin === true ||
        auth?.subscription?.is_super_admin === true ||
        (auth?.subscription?.features && auth.subscription.features.includes('feature:ai'));

    const [messages, setMessages] = useState<AiMessage[]>([]);
    const [contextSources, setContextSources] = useState<string[]>([]);
    const [totalTokens, setTotalTokens] = useState<number>(0);
    const [loading, setLoading] = useState<boolean>(false);
    const [fetchingHistory, setFetchingHistory] = useState<boolean>(false);
    const [inputValue, setInputValue] = useState<string>('');
    const [mentions, setMentions] = useState<MentionItem[]>([]);
    const [error, setError] = useState<string | null>(null);
    const [confirmClearOpen, setConfirmClearOpen] = useState<boolean>(false);
    const [clearing, setClearing] = useState<boolean>(false);
    const [sourcesExpanded, setSourcesExpanded] = useState<boolean>(false);
    const [isResizing, setIsResizing] = useState<boolean>(false);

    const messagesEndRef = useRef<HTMLDivElement>(null);
    const textareaRef = useRef<HTMLTextAreaElement>(null);

    // Resizing logic
    const handleMouseDown = (e: React.MouseEvent) => {
        e.preventDefault();
        setIsResizing(true);

        const onMouseMove = (moveEvent: MouseEvent) => {
            const newWidth = window.innerWidth - moveEvent.clientX;
            setSidebarWidth(newWidth);
        };

        const onMouseUp = () => {
            setIsResizing(false);
            window.removeEventListener('mousemove', onMouseMove);
            window.removeEventListener('mouseup', onMouseUp);
        };

        window.addEventListener('mousemove', onMouseMove);
        window.addEventListener('mouseup', onMouseUp);
    };

    const scrollToBottom = (smooth = true) => {
        messagesEndRef.current?.scrollIntoView({ behavior: smooth ? 'smooth' : 'auto' });
    };

    // Load message history on open or active assignment change
    useEffect(() => {
        if (!isOpen || !isGenius) return;

        let isMounted = true;
        setFetchingHistory(true);
        setError(null);

        const queryParam = activeAssignment ? `?assignment_id=${activeAssignment.id}` : '';

        fetch(`/ai/messages${queryParam}`, {
            headers: {
                Accept: 'application/json',
                'X-Requested-With': 'XMLHttpRequest',
            },
        })
            .then(async (res) => {
                if (!res.ok) throw new Error(`HTTP ${res.status}`);
                return res.json();
            })
            .then((data) => {
                if (!isMounted) return;
                setMessages(data.messages || []);
                setContextSources(data.context_sources || []);
                setTotalTokens(data.total_tokens || 0);
            })
            .catch(() => {
                if (!isMounted) return;
                setError('Could not load AI messages. Please try again.');
            })
            .finally(() => {
                if (isMounted) setFetchingHistory(false);
            });

        return () => {
            isMounted = false;
        };
    }, [isOpen, activeAssignment?.id, isGenius]);

    useEffect(() => {
        if (messages.length > 0) {
            scrollToBottom(false);
        }
    }, [messages.length]);

    // Handle pending prompt if opened with a pre-filled prompt
    useEffect(() => {
        if (pendingPrompt && isOpen) {
            setInputValue(pendingPrompt);
            setPendingPrompt(null);
            setTimeout(() => textareaRef.current?.focus(), 50);
        }
    }, [pendingPrompt, isOpen, setPendingPrompt]);

    const handleAddMention = (item: MentionItem) => {
        setMentions((prev) => {
            if (prev.some((m) => m.id === item.id && m.type === item.type)) {
                return prev;
            }
            return [...prev, item];
        });
    };

    const handleRemoveMention = (id: number, type: 'course' | 'assignment') => {
        setMentions((prev) => prev.filter((m) => !(m.id === id && m.type === type)));
    };

    // Send chat message
    const handleSendMessage = async (textOverride?: string) => {
        const query = (textOverride || inputValue).trim();
        if (!query || loading) return;

        setError(null);
        setInputValue('');

        const optimisticMsg: AiMessage = {
            id: Date.now(),
            role: 'user',
            content: query,
            tokens_used: Math.ceil(query.length / 4),
            created_at: new Date().toISOString(),
        };

        setMessages((prev) => [...prev, optimisticMsg]);
        setLoading(true);

        try {
            const csrfToken =
                (document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement)?.content || '';

            const res = await fetch('/ai/chat', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    Accept: 'application/json',
                    'X-CSRF-TOKEN': csrfToken,
                    'X-Requested-With': 'XMLHttpRequest',
                },
                body: JSON.stringify({
                    message: query,
                    assignment_id: activeAssignment?.id || null,
                    mentions: mentions.map((m) => ({ type: m.type, id: m.id, name: m.name })),
                }),
            });

            if (!res.ok) {
                const errData = await res.json().catch(() => ({}));
                throw new Error(errData.message || `AI query failed (Status: ${res.status})`);
            }

            const data = await res.json();

            setMessages((prev) => [
                ...prev,
                {
                    id: data.assistant_message?.id || Date.now() + 1,
                    role: 'assistant',
                    content: data.reply,
                    tokens_used: data.tokens_used || 0,
                    created_at: new Date().toISOString(),
                },
            ]);

            if (data.context_sources) {
                setContextSources(data.context_sources);
            }
            setTotalTokens((prev) => prev + (data.tokens_used || 0));
        } catch (err: unknown) {
            console.error('AI chat error:', err);
            const errorMsg = err instanceof Error ? err.message : 'Failed to receive reply from Due Copilot.';
            setError(errorMsg);
        } finally {
            setLoading(false);
            setTimeout(() => textareaRef.current?.focus(), 50);
        }
    };

    const handleClearHistory = async () => {
        setClearing(true);
        try {
            const csrfToken =
                (document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement)?.content || '';

            const queryParam = activeAssignment ? `?assignment_id=${activeAssignment.id}` : '';

            const res = await fetch(`/ai/history${queryParam}`, {
                method: 'DELETE',
                headers: {
                    Accept: 'application/json',
                    'X-CSRF-TOKEN': csrfToken,
                    'X-Requested-With': 'XMLHttpRequest',
                },
            });

            if (res.ok) {
                setMessages([]);
                setTotalTokens(0);
                setConfirmClearOpen(false);
            }
        } catch (err) {
            console.error('Failed to clear history:', err);
        } finally {
            setClearing(false);
        }
    };

    if (!isOpen) return null;

    const quickChips = [
        { label: 'Summarize Tasks', prompt: 'Summarize my upcoming coursework assignments and imminent deadlines.' },
        { label: 'Weekly Study Plan', prompt: 'Create a structured study roadmap for this week based on my active courses and tasks.' },
        { label: 'Exam Prep Tips', prompt: 'What are the most effective Socratic methods to review concept notes for my classes?' },
    ];

    return (
        <aside
            style={{ width: `${sidebarWidth}px` }}
            className={`fixed top-0 right-0 bottom-0 z-40 bg-zinc-950 border-l border-border flex flex-col shadow-2xl transition-[width] ease-out duration-75 select-text ${
                isResizing ? 'transition-none select-none' : ''
            }`}
        >
            {/* Draggable Resize Handle on Left Border */}
            <div
                onMouseDown={handleMouseDown}
                title="Drag to resize sidebar width"
                className="absolute top-0 bottom-0 -left-1.5 w-3 cursor-ew-resize group z-50 flex items-center justify-center"
            >
                <div className="w-[3px] h-12 bg-border group-hover:bg-primary transition-colors flex items-center justify-center">
                    <GripVertical className="size-2 text-muted-foreground opacity-0 group-hover:opacity-100" />
                </div>
            </div>

            {/* Header Toolbar */}
            <div className="border-b border-border p-3.5 bg-zinc-900/80 flex items-center justify-between gap-2 shrink-0">
                <div className="flex items-center gap-2 min-w-0">
                    <div className="size-7 rounded-none bg-primary/10 border border-primary/30 flex items-center justify-center text-primary shrink-0">
                        <BotMessageSquare className="size-3.5" />
                    </div>
                    <div className="min-w-0">
                        <div className="flex items-center gap-1.5">
                            <span className="text-xs font-bold text-foreground truncate">Due Copilot</span>
                            <Badge variant="outline" className="rounded-none border-primary/30 bg-primary/5 text-primary font-mono text-[9px] px-1 py-0">
                                Gemini 2.5 Flash
                            </Badge>
                        </div>
                        <p className="text-[10px] font-mono text-muted-foreground truncate">
                            {activeAssignment ? `Focused: ${activeAssignment.title}` : 'Workspace Study Partner'}
                        </p>
                    </div>
                </div>

                <div className="flex items-center gap-1 text-xs font-mono shrink-0">
                    {totalTokens > 0 && (
                        <div className="border border-border/80 bg-zinc-900 px-1.5 py-0.5 text-[10px] text-muted-foreground flex items-center gap-1 hidden sm:flex">
                            <Database className="size-2.5 text-zinc-500" />
                            <span>{totalTokens}t</span>
                        </div>
                    )}

                    {messages.length > 0 && (
                        <Button
                            type="button"
                            variant="ghost"
                            size="sm"
                            onClick={() => setConfirmClearOpen(true)}
                            className="rounded-none size-7 p-0 text-muted-foreground hover:text-destructive cursor-pointer"
                            title="Clear conversation"
                        >
                            <Trash2 className="size-3.5" />
                        </Button>
                    )}

                    <Button
                        type="button"
                        variant="ghost"
                        size="sm"
                        onClick={closeCopilot}
                        className="rounded-none size-7 p-0 text-muted-foreground hover:text-foreground cursor-pointer"
                        title="Close Copilot (Ctrl+J)"
                    >
                        <X className="size-4" />
                    </Button>
                </div>
            </div>

            {/* Active Assignment Focus Pill (if viewing an assignment) */}
            {activeAssignment && (
                <div className="border-b border-border/60 bg-primary/5 px-3 py-1.5 flex items-center justify-between gap-2 text-xs font-mono">
                    <span className="text-[11px] text-primary truncate flex items-center gap-1.5">
                        <span className="size-1.5 bg-primary animate-pulse" />
                        Focused on: <strong className="text-foreground">{activeAssignment.title}</strong>
                    </span>
                    <button
                        type="button"
                        onClick={() => setActiveAssignment(null)}
                        className="text-[10px] text-muted-foreground hover:text-foreground cursor-pointer"
                        title="Switch to general workspace context"
                    >
                        Unfocus
                    </button>
                </div>
            )}

            {/* Active Context Sources Bar */}
            <div className="border-b border-border/60 bg-zinc-950 px-3 py-1.5 text-[11px] font-mono text-muted-foreground flex items-center justify-between gap-2 shrink-0">
                <div className="flex items-center gap-1.5 flex-wrap overflow-hidden">
                    <span className="text-[10px] uppercase text-zinc-500 font-semibold">Context:</span>
                    {contextSources.length > 0 ? (
                        contextSources.slice(0, sourcesExpanded ? undefined : 2).map((src, i) => (
                            <span
                                key={i}
                                className="inline-flex items-center gap-1 border border-border/60 bg-muted/40 px-1.5 py-0.2 text-[10px] text-zinc-300"
                            >
                                <FileText className="size-2.5 text-primary" />
                                <span className="max-w-[120px] truncate">{src}</span>
                            </span>
                        ))
                    ) : (
                        <span className="text-[10px] italic text-zinc-600">Workspace overview</span>
                    )}

                    {contextSources.length > 2 && (
                        <button
                            type="button"
                            onClick={() => setSourcesExpanded(!sourcesExpanded)}
                            className="text-[10px] text-primary hover:underline cursor-pointer"
                        >
                            {sourcesExpanded ? 'less' : `+${contextSources.length - 2}`}
                        </button>
                    )}
                </div>
            </div>

            {/* Main Content / Chat Body */}
            <div className="flex-1 overflow-y-auto p-4 space-y-4 bg-zinc-950/70">
                {/* Free / Scholar Locked Upgrade Banner */}
                {!isGenius ? (
                    <div className="py-8 px-4 text-center space-y-4 max-w-sm mx-auto">
                        <div className="size-12 mx-auto rounded-none bg-primary/10 border border-primary/30 flex items-center justify-center text-primary">
                            <Lock className="size-5" />
                        </div>
                        <div className="space-y-1">
                            <h4 className="text-sm font-bold text-foreground">
                                Due Copilot requires Genius
                            </h4>
                            <p className="text-xs text-muted-foreground leading-relaxed">
                                Upgrade your subscription to unlock our 24/7 personal academic copilot. Mention any course or assignment using <code className="text-primary font-mono bg-muted px-1">@</code> to get instant Socratic guidance, summaries, and outlines.
                            </p>
                        </div>
                        <Link href="/pricing" className="block w-full">
                            <Button className="w-full rounded-none bg-primary text-primary-foreground hover:bg-primary/90 font-semibold text-xs cursor-pointer gap-2">
                                <Sparkles className="size-3.5" />
                                Upgrade to Genius ($9.99/mo)
                            </Button>
                        </Link>
                    </div>
                ) : fetchingHistory ? (
                    <div className="py-16 text-center space-y-3 font-mono text-xs text-muted-foreground">
                        <RefreshCw className="size-5 animate-spin mx-auto text-primary" />
                        <p>Loading your study assistant...</p>
                    </div>
                ) : messages.length === 0 ? (
                    <div className="py-8 text-center space-y-4">
                        <div className="size-10 mx-auto rounded-none bg-muted/60 border border-border flex items-center justify-center text-primary">
                            <BotMessageSquare className="size-5" />
                        </div>
                        <div className="space-y-1">
                            <h4 className="text-xs font-bold text-foreground">
                                How can I help you today?
                            </h4>
                            <p className="text-[11px] text-muted-foreground leading-relaxed max-w-xs mx-auto">
                                Type <code className="text-primary font-mono bg-muted/80 px-1">@</code> to reference any of your courses or assignments directly in your question!
                            </p>
                        </div>

                        {/* Quick Prompts */}
                        <div className="space-y-1.5 text-left pt-2">
                            {quickChips.map((c, i) => (
                                <button
                                    key={i}
                                    type="button"
                                    onClick={() => handleSendMessage(c.prompt)}
                                    className="w-full border border-border/80 bg-zinc-900/60 hover:bg-muted/60 hover:border-primary/50 p-2.5 rounded-none text-xs transition-colors cursor-pointer text-left group"
                                >
                                    <div className="font-semibold text-foreground text-xs group-hover:text-primary transition-colors">
                                        {c.label}
                                    </div>
                                    <div className="text-[11px] text-muted-foreground line-clamp-1 font-mono">
                                        {c.prompt}
                                    </div>
                                </button>
                            ))}
                        </div>
                    </div>
                ) : (
                    messages.map((msg, idx) => (
                        <div
                            key={msg.id || idx}
                            className={`flex items-start gap-2.5 ${
                                msg.role === 'user' ? 'justify-end' : 'justify-start'
                            }`}
                        >
                            {msg.role === 'assistant' && (
                                <div className="size-6 rounded-none bg-primary/10 border border-primary/30 flex items-center justify-center text-primary shrink-0 mt-0.5">
                                    <BotMessageSquare className="size-3" />
                                </div>
                            )}

                            <div
                                className={`max-w-[88%] rounded-none p-3 space-y-1.5 ${
                                    msg.role === 'user'
                                        ? 'bg-zinc-900 border border-zinc-700 text-foreground text-xs font-sans'
                                        : 'bg-card border border-border text-foreground text-xs font-sans'
                                }`}
                            >
                                <div className="flex items-center justify-between gap-2 text-[9px] font-mono text-muted-foreground border-b border-border/40 pb-1">
                                    <span className="font-semibold uppercase tracking-wider text-zinc-400">
                                        {msg.role === 'user' ? 'You' : 'Due Copilot'}
                                    </span>
                                    {msg.tokens_used > 0 && <span>{msg.tokens_used}t</span>}
                                </div>

                                {msg.role === 'user' ? (
                                    <p className="whitespace-pre-wrap leading-relaxed">{msg.content}</p>
                                ) : (
                                    <FormattedMarkdown content={msg.content} />
                                )}
                            </div>

                            {msg.role === 'user' && (
                                <div className="size-6 rounded-none bg-muted border border-border flex items-center justify-center text-muted-foreground shrink-0 mt-0.5">
                                    <UserIcon className="size-3" />
                                </div>
                            )}
                        </div>
                    ))
                )}

                {/* Thinking Indicator */}
                {loading && (
                    <div className="flex items-start gap-2.5">
                        <div className="size-6 rounded-none bg-primary/10 border border-primary/30 flex items-center justify-center text-primary shrink-0 mt-0.5">
                            <BotMessageSquare className="size-3 animate-pulse" />
                        </div>
                        <div className="border border-primary/30 bg-primary/5 p-2.5 rounded-none font-mono text-xs text-primary flex items-center gap-2">
                            <RefreshCw className="size-3 animate-spin shrink-0" />
                            <span>Thinking & analyzing context...</span>
                        </div>
                    </div>
                )}

                {error && (
                    <div className="border border-destructive/60 bg-destructive/10 p-2.5 rounded-none text-xs text-destructive flex items-center gap-2">
                        <AlertCircle className="size-4 shrink-0" />
                        <span>{error}</span>
                    </div>
                )}

                <div ref={messagesEndRef} />
            </div>

            {/* Footer Input Composer (Only if Genius) */}
            {isGenius && (
                <div className="border-t border-border p-3 bg-zinc-900/90 shrink-0">
                    <form
                        onSubmit={(e) => {
                            e.preventDefault();
                            handleSendMessage();
                        }}
                        className="space-y-2"
                    >
                        <AiMentionAutocomplete
                            value={inputValue}
                            onChange={setInputValue}
                            onSubmit={handleSendMessage}
                            disabled={loading}
                            mentions={mentions}
                            onAddMention={handleAddMention}
                            onRemoveMention={handleRemoveMention}
                            textareaRef={textareaRef}
                        />

                        <div className="flex items-center justify-between">
                            <span className="text-[10px] font-mono text-muted-foreground">
                                Press <kbd className="border border-border/80 bg-background px-1 py-0.2 text-zinc-300">Enter</kbd> to send, <kbd className="border border-border/80 bg-background px-1 py-0.2 text-zinc-300">@</kbd> to mention
                            </span>

                            <Button
                                type="submit"
                                size="sm"
                                disabled={loading || !inputValue.trim()}
                                className="rounded-none bg-primary text-primary-foreground hover:bg-primary/90 h-7 px-3 text-xs cursor-pointer gap-1.5 shrink-0"
                            >
                                <Send className="size-3" />
                                <span>Send</span>
                            </Button>
                        </div>
                    </form>
                </div>
            )}

            {/* Clear History Modal */}
            <Dialog open={confirmClearOpen} onOpenChange={setConfirmClearOpen}>
                <DialogContent className="rounded-none border-border bg-card sm:max-w-md">
                    <DialogHeader>
                        <DialogTitle className="text-sm font-bold text-foreground">
                            Clear Copilot Conversation
                        </DialogTitle>
                        <DialogDescription className="text-xs text-muted-foreground">
                            Are you sure you want to clear this study conversation? All active context will be reset.
                        </DialogDescription>
                    </DialogHeader>
                    <DialogFooter className="gap-2 sm:justify-end">
                        <Button
                            type="button"
                            variant="outline"
                            onClick={() => setConfirmClearOpen(false)}
                            disabled={clearing}
                            className="rounded-none text-xs border-border"
                        >
                            Cancel
                        </Button>
                        <Button
                            type="button"
                            variant="destructive"
                            onClick={handleClearHistory}
                            disabled={clearing}
                            className="rounded-none text-xs cursor-pointer"
                        >
                            {clearing ? 'Clearing...' : 'Clear History'}
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </aside>
    );
}
