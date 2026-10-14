import { Link, usePage } from '@inertiajs/react';
import {
    AlertCircle,
    ArrowUp,
    BotMessageSquare,
    ChevronDown,
    ChevronUp,
    Database,
    FileText,
    Lock,
    RefreshCw,
    RotateCcw,
    Send,
    Trash2,
    User as UserIcon,
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
import { FormattedMarkdown } from './formatted-markdown';
import type { AiMessage, Auth } from '@/types';

interface AssignmentAiAssistantProps {
    assignmentId: number;
    assignmentTitle: string;
    courseName?: string;
}

export function AssignmentAiAssistant({
    assignmentId,
    assignmentTitle,
    courseName,
}: AssignmentAiAssistantProps) {
    const pageProps = usePage().props as { auth?: Auth };
    const auth = pageProps.auth;

    const isGenius =
        auth?.user?.subscription_tier === 'premium' ||
        auth?.user?.role === 'super_admin' ||
        auth?.subscription?.is_super_admin === true ||
        (auth?.subscription?.features && auth.subscription.features.includes('feature:ai'));

    const [messages, setMessages] = useState<AiMessage[]>([]);
    const [contextSources, setContextSources] = useState<string[]>([]);
    const [totalTokens, setTotalTokens] = useState<number>(0);
    const [loading, setLoading] = useState<boolean>(false);
    const [fetchingHistory, setFetchingHistory] = useState<boolean>(false);
    const [inputValue, setInputValue] = useState<string>('');
    const [error, setError] = useState<string | null>(null);
    const [confirmClearOpen, setConfirmClearOpen] = useState<boolean>(false);
    const [clearing, setClearing] = useState<boolean>(false);
    const [sourcesExpanded, setSourcesExpanded] = useState<boolean>(false);

    const messagesEndRef = useRef<HTMLDivElement>(null);
    const textareaRef = useRef<HTMLTextAreaElement>(null);

    // Scroll chat to bottom
    const scrollToBottom = (smooth = true) => {
        messagesEndRef.current?.scrollIntoView({ behavior: smooth ? 'smooth' : 'auto' });
    };

    // Load initial conversation history if user has access
    useEffect(() => {
        if (!isGenius) return;

        let isMounted = true;
        setFetchingHistory(true);
        setError(null);

        fetch(`/assignments/${assignmentId}/ai/messages`, {
            headers: {
                Accept: 'application/json',
                'X-Requested-With': 'XMLHttpRequest',
            },
        })
            .then(async (res) => {
                if (!res.ok) {
                    throw new Error(`Failed to load messages (Status: ${res.status})`);
                }
                return res.json();
            })
            .then((data) => {
                if (!isMounted) return;
                setMessages(data.messages || []);
                setContextSources(data.context_sources || []);
                setTotalTokens(data.total_tokens || 0);
            })
            .catch((err) => {
                if (!isMounted) return;
                console.error('Error fetching AI history:', err);
                setError('Could not load AI study history. Please try again.');
            })
            .finally(() => {
                if (isMounted) setFetchingHistory(false);
            });

        return () => {
            isMounted = false;
        };
    }, [assignmentId, isGenius]);

    useEffect(() => {
        if (messages.length > 0) {
            scrollToBottom(false);
        }
    }, [messages.length]);

    // Handle send message
    const handleSendMessage = async (textToSend?: string) => {
        const query = (textToSend || inputValue).trim();
        if (!query || loading) return;

        setError(null);
        setInputValue('');

        // Optimistic user message
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

            const res = await fetch(`/assignments/${assignmentId}/ai/chat`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    Accept: 'application/json',
                    'X-CSRF-TOKEN': csrfToken,
                    'X-Requested-With': 'XMLHttpRequest',
                },
                body: JSON.stringify({ message: query }),
            });

            if (!res.ok) {
                const errData = await res.json().catch(() => ({}));
                throw new Error(errData.message || `AI query failed with status ${res.status}`);
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

    const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            handleSendMessage();
        }
    };

    const handleClearHistory = async () => {
        setClearing(true);
        try {
            const csrfToken =
                (document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement)?.content || '';

            const res = await fetch(`/assignments/${assignmentId}/ai/history`, {
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

    const suggestedPrompts = [
        { label: 'Summarize Requirements', prompt: 'Summarize the core assignment requirements and key submission deliverables.' },
        { label: 'Milestone Roadmap', prompt: 'Break this assignment down into 3-4 sequential milestone steps with mini-checklists.' },
        { label: 'Explain Attached Slides', prompt: 'Explain the core theoretical concepts described in my attached course resources and lecture slides.' },
        { label: 'Check for Edge Cases', prompt: 'Based on my notes and requirements, what edge cases or common pitfalls should I be aware of?' },
    ];

    // ==========================================
    // 1. LOCKED TIER GATE (Free & Scholar tiers)
    // ==========================================
    if (!isGenius) {
        return (
            <div className="border border-border/80 bg-card p-6 md:p-8 rounded-none relative overflow-hidden shadow-xs">
                {/* Glow accent */}
                <div className="absolute top-0 right-0 w-80 h-80 bg-primary/5 blur-3xl pointer-events-none" />

                <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-6 relative z-10">
                    <div className="space-y-3 max-w-2xl">
                        <div className="flex items-center gap-2">
                            <div className="size-8 rounded-none bg-primary/10 border border-primary/30 flex items-center justify-center text-primary">
                                <BotMessageSquare className="size-4" />
                            </div>
                            <span className="text-xs font-mono uppercase tracking-wider text-primary font-semibold">
                                Genius Tier Exclusive
                            </span>
                            <Badge variant="outline" className="rounded-none border-border font-mono text-[10px]">
                                Gemini 1.5 Flash
                            </Badge>
                        </div>

                        <h3 className="text-lg md:text-xl font-bold tracking-tight text-foreground">
                            Unlock Due Copilot AI Study Assistant
                        </h3>

                        <p className="text-sm text-muted-foreground leading-relaxed">
                            Upgrade to <strong className="text-foreground">Genius</strong> to get a context-aware 24/7 personal academic tutor attached to this assignment. Due Copilot reads your notes, rubrics, and slides to explain difficult concepts, highlight edge cases, and guide you Socratic-style through your coursework.
                        </p>

                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 pt-2 text-xs text-zinc-300 font-mono">
                            <div className="flex items-center gap-2">
                                <span className="text-primary font-bold">✓</span> Real-time context from attached notes & PDFs
                            </div>
                            <div className="flex items-center gap-2">
                                <span className="text-primary font-bold">✓</span> Socratic conceptual tutor & breakdown milestones
                            </div>
                            <div className="flex items-center gap-2">
                                <span className="text-primary font-bold">✓</span> Unlimited queries per assignment
                            </div>
                            <div className="flex items-center gap-2">
                                <span className="text-primary font-bold">✓</span> 5 GB study storage quota included
                            </div>
                        </div>
                    </div>

                    <div className="flex flex-col sm:flex-row md:flex-col gap-2.5 w-full md:w-auto shrink-0">
                        <Link href="/pricing" className="w-full">
                            <Button className="w-full rounded-none bg-primary text-primary-foreground hover:bg-primary/90 font-semibold cursor-pointer gap-2">
                                <Lock className="size-4" />
                                Upgrade to Genius ($9.99/mo)
                            </Button>
                        </Link>
                        <p className="text-[11px] text-center text-muted-foreground font-mono">
                            Instant access • Simulated mock checkout
                        </p>
                    </div>
                </div>
            </div>
        );
    }

    // ==========================================
    // 2. ACTIVE GENIUS AI ASSISTANT CHAT
    // ==========================================
    return (
        <div className="border border-border bg-card rounded-none overflow-hidden flex flex-col shadow-xs">
            {/* Top Toolbar */}
            <div className="border-b border-border p-4 bg-muted/30 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                <div className="flex items-center gap-2.5">
                    <div className="size-8 rounded-none bg-primary/10 border border-primary/30 flex items-center justify-center text-primary">
                        <BotMessageSquare className="size-4" />
                    </div>
                    <div>
                        <div className="flex items-center gap-2">
                            <h3 className="text-sm font-bold tracking-tight text-foreground flex items-center gap-1.5">
                                Due Copilot
                            </h3>
                            <Badge variant="outline" className="rounded-none border-primary/30 bg-primary/5 text-primary font-mono text-[10px] px-1.5 py-0">
                                Gemini 1.5 Flash
                            </Badge>
                        </div>
                        <p className="text-[11px] text-muted-foreground font-mono">
                            Assignment Study Partner & Concept Explainer
                        </p>
                    </div>
                </div>

                <div className="flex items-center gap-2 text-xs font-mono">
                    {totalTokens > 0 && (
                        <div className="border border-border bg-background px-2 py-1 text-muted-foreground text-[11px] flex items-center gap-1.5">
                            <Database className="size-3 text-zinc-500" />
                            <span>{totalTokens.toLocaleString()} tokens</span>
                        </div>
                    )}

                    {messages.length > 0 && (
                        <Button
                            type="button"
                            variant="outline"
                            size="sm"
                            onClick={() => setConfirmClearOpen(true)}
                            className="rounded-none h-7 px-2 text-xs border-border text-muted-foreground hover:text-destructive cursor-pointer gap-1.5"
                            title="Clear conversation history"
                        >
                            <Trash2 className="size-3" />
                            <span className="hidden sm:inline">Clear Chat</span>
                        </Button>
                    )}
                </div>
            </div>

            {/* Context Sources Pill Banner */}
            <div className="border-b border-border/60 bg-background/50 px-4 py-2 flex items-center justify-between gap-2 text-xs font-mono text-muted-foreground">
                <div className="flex items-center gap-2 flex-wrap overflow-hidden">
                    <span className="text-[11px] uppercase tracking-wider text-zinc-400 font-semibold flex items-center gap-1">
                        Active Context:
                    </span>
                    {contextSources.length > 0 ? (
                        contextSources.slice(0, sourcesExpanded ? undefined : 3).map((source, sIdx) => (
                            <span
                                key={sIdx}
                                className="inline-flex items-center gap-1 border border-border/80 bg-muted/60 px-2 py-0.5 text-[10px] text-foreground"
                            >
                                <FileText className="size-2.5 text-primary" />
                                {source}
                            </span>
                        ))
                    ) : (
                        <span className="text-[11px] text-zinc-500 italic">Reading assignment details...</span>
                    )}

                    {contextSources.length > 3 && (
                        <button
                            type="button"
                            onClick={() => setSourcesExpanded(!sourcesExpanded)}
                            className="text-[10px] text-primary hover:underline cursor-pointer inline-flex items-center gap-0.5"
                        >
                            {sourcesExpanded ? 'Show less' : `+${contextSources.length - 3} more`}
                        </button>
                    )}
                </div>
            </div>

            {/* Messages Area */}
            <div className="p-4 md:p-6 space-y-4 min-h-[300px] max-h-[550px] overflow-y-auto bg-zinc-950/40">
                {fetchingHistory ? (
                    <div className="py-12 text-center space-y-3 font-mono text-xs text-muted-foreground">
                        <RefreshCw className="size-5 animate-spin mx-auto text-primary" />
                        <p>Loading your study session...</p>
                    </div>
                ) : messages.length === 0 ? (
                    <div className="py-8 text-center space-y-4 max-w-lg mx-auto">
                        <div className="size-12 mx-auto rounded-none bg-muted/50 border border-border flex items-center justify-center text-primary">
                            <BotMessageSquare className="size-6" />
                        </div>
                        <div className="space-y-1">
                            <h4 className="text-sm font-bold text-foreground">
                                How can I help you with {assignmentTitle}?
                            </h4>
                            <p className="text-xs text-muted-foreground leading-relaxed">
                                I'm primed with your notes, instructions, and uploaded study resources for{' '}
                                <span className="font-semibold text-zinc-200">{courseName || 'this course'}</span>. Ask me anything, or choose a quick prompt below:
                            </p>
                        </div>

                        {/* Quick Prompts */}
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 pt-2 text-left">
                            {suggestedPrompts.map((item, idx) => (
                                <button
                                    key={idx}
                                    type="button"
                                    onClick={() => handleSendMessage(item.prompt)}
                                    className="border border-border/80 bg-card hover:bg-muted/60 hover:border-primary/50 p-3 rounded-none text-xs transition-colors cursor-pointer space-y-1 group"
                                >
                                    <div className="font-semibold text-foreground group-hover:text-primary transition-colors">
                                        {item.label}
                                    </div>
                                    <div className="text-[11px] text-muted-foreground line-clamp-1">
                                        {item.prompt}
                                    </div>
                                </button>
                            ))}
                        </div>
                    </div>
                ) : (
                    messages.map((msg, idx) => (
                        <div
                            key={msg.id || idx}
                            className={`flex items-start gap-3 ${
                                msg.role === 'user' ? 'justify-end' : 'justify-start'
                            }`}
                        >
                            {msg.role === 'assistant' && (
                                <div className="size-7 rounded-none bg-primary/10 border border-primary/30 flex items-center justify-center text-primary shrink-0 mt-0.5">
                                    <BotMessageSquare className="size-3.5" />
                                </div>
                            )}

                            <div
                                className={`max-w-[85%] md:max-w-[80%] rounded-none p-3.5 space-y-2 ${
                                    msg.role === 'user'
                                        ? 'bg-zinc-900 border border-zinc-700 text-foreground font-sans'
                                        : 'bg-card border border-border text-foreground font-sans'
                                }`}
                            >
                                <div className="flex items-center justify-between gap-3 text-[10px] font-mono text-muted-foreground border-b border-border/40 pb-1.5 mb-1.5">
                                    <span className="font-semibold uppercase tracking-wider text-zinc-400">
                                        {msg.role === 'user' ? 'You' : 'Due Copilot'}
                                    </span>
                                    {msg.tokens_used > 0 && (
                                        <span>{msg.tokens_used} tokens</span>
                                    )}
                                </div>

                                {msg.role === 'user' ? (
                                    <p className="text-sm whitespace-pre-wrap leading-relaxed">{msg.content}</p>
                                ) : (
                                    <FormattedMarkdown content={msg.content} />
                                )}
                            </div>

                            {msg.role === 'user' && (
                                <div className="size-7 rounded-none bg-muted border border-border flex items-center justify-center text-muted-foreground shrink-0 mt-0.5">
                                    <UserIcon className="size-3.5" />
                                </div>
                            )}
                        </div>
                    ))
                )}

                {/* Thinking Indicator */}
                {loading && (
                    <div className="flex items-start gap-3">
                        <div className="size-7 rounded-none bg-primary/10 border border-primary/30 flex items-center justify-center text-primary shrink-0 mt-0.5">
                            <BotMessageSquare className="size-3.5 animate-pulse" />
                        </div>
                        <div className="border border-primary/30 bg-primary/5 p-3.5 rounded-none font-mono text-xs text-primary flex items-center gap-2">
                            <RefreshCw className="size-3.5 animate-spin" />
                            <span>Due Copilot is reading assignment resources & generating study guidance...</span>
                        </div>
                    </div>
                )}

                {error && (
                    <div className="border border-destructive/60 bg-destructive/10 p-3 rounded-none text-xs text-destructive flex items-center gap-2">
                        <AlertCircle className="size-4 shrink-0" />
                        <span>{error}</span>
                    </div>
                )}

                <div ref={messagesEndRef} />
            </div>

            {/* Input Composer */}
            <div className="border-t border-border p-3 md:p-4 bg-muted/20">
                <form
                    onSubmit={(e) => {
                        e.preventDefault();
                        handleSendMessage();
                    }}
                    className="space-y-2"
                >
                    <div className="flex items-end gap-2">
                        <textarea
                            ref={textareaRef}
                            value={inputValue}
                            onChange={(e) => setInputValue(e.target.value)}
                            onKeyDown={handleKeyDown}
                            placeholder="Ask a question about this assignment or request an outline..."
                            rows={2}
                            disabled={loading}
                            className="flex-1 resize-none bg-background border border-input p-3 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:border-primary rounded-none font-sans"
                        />
                        <Button
                            type="submit"
                            disabled={loading || !inputValue.trim()}
                            className="rounded-none h-[68px] px-5 bg-primary text-primary-foreground hover:bg-primary/90 cursor-pointer disabled:opacity-50 shrink-0 flex flex-col items-center justify-center gap-1"
                        >
                            <Send className="size-4" />
                            <span className="text-[10px] font-mono uppercase tracking-wider">Send</span>
                        </Button>
                    </div>

                    <div className="flex items-center justify-between text-[11px] font-mono text-muted-foreground px-1">
                        <span>Press <kbd className="border border-border/80 bg-background px-1 py-0.5 text-zinc-300">Enter</kbd> to send, <kbd className="border border-border/80 bg-background px-1 py-0.5 text-zinc-300">Shift + Enter</kbd> for newline</span>
                        <span className="hidden sm:inline">Grounding: Notes & Resources active</span>
                    </div>
                </form>
            </div>

            {/* Clear History Modal */}
            <Dialog open={confirmClearOpen} onOpenChange={setConfirmClearOpen}>
                <DialogContent className="rounded-none border-border bg-card sm:max-w-md">
                    <DialogHeader>
                        <DialogTitle className="text-base font-bold text-foreground">
                            Clear Study Session History
                        </DialogTitle>
                        <DialogDescription className="text-xs text-muted-foreground">
                            Are you sure you want to clear your AI chat history for <strong className="text-foreground">{assignmentTitle}</strong>? This action cannot be undone.
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
        </div>
    );
}
