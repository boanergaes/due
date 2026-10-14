import { Check, Copy } from 'lucide-react';
import React, { useState } from 'react';

interface FormattedMarkdownProps {
    content: string;
    className?: string;
}

export function FormattedMarkdown({ content, className = '' }: FormattedMarkdownProps) {
    const [copiedIndex, setCopiedIndex] = useState<number | null>(null);

    const handleCopy = (code: string, index: number) => {
        navigator.clipboard.writeText(code);
        setCopiedIndex(index);
        setTimeout(() => setCopiedIndex(null), 2000);
    };

    // Split content by code blocks ```lang ... ```
    const codeBlockRegex = /```([a-zA-Z0-9_-]*)\n([\s\S]*?)```/g;
    const parts: Array<{ type: 'text' | 'code'; lang?: string; content: string }> = [];
    let lastIndex = 0;
    let match: RegExpExecArray | null;

    while ((match = codeBlockRegex.exec(content)) !== null) {
        if (match.index > lastIndex) {
            parts.push({
                type: 'text',
                content: content.substring(lastIndex, match.index),
            });
        }
        parts.push({
            type: 'code',
            lang: match[1] || 'code',
            content: match[2].trimEnd(),
        });
        lastIndex = match.index + match[0].length;
    }

    if (lastIndex < content.length) {
        parts.push({
            type: 'text',
            content: content.substring(lastIndex),
        });
    }

    return (
        <div className={`space-y-3 text-sm leading-relaxed text-foreground font-sans ${className}`}>
            {parts.map((part, pIdx) => {
                if (part.type === 'code') {
                    return (
                        <div
                            key={pIdx}
                            className="border border-border bg-zinc-950 rounded-none overflow-hidden my-3 shadow-xs"
                        >
                            <div className="flex items-center justify-between px-3 py-1.5 bg-zinc-900 border-b border-border/60 text-xs font-mono text-muted-foreground">
                                <span className="uppercase text-[11px] tracking-wider font-semibold text-zinc-400">
                                    {part.lang}
                                </span>
                                <button
                                    type="button"
                                    onClick={() => handleCopy(part.content, pIdx)}
                                    className="flex items-center gap-1.5 text-xs text-muted-foreground hover:text-foreground transition-colors cursor-pointer"
                                >
                                    {copiedIndex === pIdx ? (
                                        <>
                                            <Check className="size-3 text-emerald-400" />
                                            <span className="text-emerald-400 text-[11px]">Copied</span>
                                        </>
                                    ) : (
                                        <>
                                            <Copy className="size-3" />
                                            <span className="text-[11px]">Copy Code</span>
                                        </>
                                    )}
                                </button>
                            </div>
                            <pre className="p-3 text-xs font-mono text-zinc-200 overflow-x-auto whitespace-pre leading-relaxed">
                                <code>{part.content}</code>
                            </pre>
                        </div>
                    );
                }

                return (
                    <div key={pIdx} className="space-y-2">
                        {renderTextParagraphs(part.content)}
                    </div>
                );
            })}
        </div>
    );
}

function renderTextParagraphs(text: string) {
    const lines = text.split('\n');
    const elements: React.ReactNode[] = [];
    let currentList: string[] = [];
    let isNumbered = false;

    const flushList = () => {
        if (currentList.length === 0) return;
        const listItems = currentList.map((item, idx) => (
            <li key={idx} className="pl-1">
                {renderInlineFormatting(item)}
            </li>
        ));

        if (isNumbered) {
            elements.push(
                <ol key={`ol-${elements.length}`} className="list-decimal list-inside space-y-1 my-2 pl-2 text-zinc-300">
                    {listItems}
                </ol>
            );
        } else {
            elements.push(
                <ul key={`ul-${elements.length}`} className="list-disc list-inside space-y-1 my-2 pl-2 text-zinc-300">
                    {listItems}
                </ul>
            );
        }
        currentList = [];
    };

    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        const trimmed = line.trim();

        if (trimmed === '') {
            flushList();
            continue;
        }

        // Headers
        if (trimmed.startsWith('### ')) {
            flushList();
            elements.push(
                <h4 key={i} className="text-sm font-bold text-foreground mt-3 mb-1">
                    {renderInlineFormatting(trimmed.substring(4))}
                </h4>
            );
            continue;
        }
        if (trimmed.startsWith('## ')) {
            flushList();
            elements.push(
                <h3 key={i} className="text-base font-bold text-foreground mt-4 mb-1 border-b border-border/40 pb-1">
                    {renderInlineFormatting(trimmed.substring(3))}
                </h3>
            );
            continue;
        }
        if (trimmed.startsWith('# ')) {
            flushList();
            elements.push(
                <h2 key={i} className="text-lg font-bold text-foreground mt-4 mb-2">
                    {renderInlineFormatting(trimmed.substring(2))}
                </h2>
            );
            continue;
        }

        // Horizontal rule
        if (trimmed === '---' || trimmed === '***') {
            flushList();
            elements.push(<hr key={i} className="border-border/60 my-3" />);
            continue;
        }

        // Blockquotes
        if (trimmed.startsWith('> ')) {
            flushList();
            elements.push(
                <blockquote
                    key={i}
                    className="border-l-2 border-primary/60 bg-muted/30 pl-3 py-1 my-2 italic text-zinc-400 text-xs"
                >
                    {renderInlineFormatting(trimmed.substring(2))}
                </blockquote>
            );
            continue;
        }

        // Bullet lists
        if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
            if (isNumbered && currentList.length > 0) flushList();
            isNumbered = false;
            currentList.push(trimmed.substring(2));
            continue;
        }

        // Numbered lists (e.g. "1. ")
        const numberedMatch = trimmed.match(/^(\d+)\.\s+(.*)/);
        if (numberedMatch) {
            if (!isNumbered && currentList.length > 0) flushList();
            isNumbered = true;
            currentList.push(numberedMatch[2]);
            continue;
        }

        // Standard paragraph
        flushList();
        elements.push(
            <p key={i} className="leading-relaxed">
                {renderInlineFormatting(line)}
            </p>
        );
    }

    flushList();
    return elements;
}

function renderInlineFormatting(text: string): React.ReactNode {
    // Split by inline code `...`
    const parts = text.split(/(`[^`]+`)/g);

    return parts.map((part, idx) => {
        if (part.startsWith('`') && part.endsWith('`') && part.length > 1) {
            return (
                <code
                    key={idx}
                    className="font-mono text-xs bg-muted/80 text-primary border border-border/60 px-1 py-0.5 rounded-none"
                >
                    {part.slice(1, -1)}
                </code>
            );
        }

        // Bold formatting **text**
        const boldParts = part.split(/(\*\*[^*]+\*\*)/g);
        return (
            <React.Fragment key={idx}>
                {boldParts.map((bPart, bIdx) => {
                    if (bPart.startsWith('**') && bPart.endsWith('**')) {
                        return <strong key={bIdx} className="font-semibold text-foreground">{bPart.slice(2, -2)}</strong>;
                    }
                    // Italic formatting *text*
                    const italicParts = bPart.split(/(\*[^*]+\*)/g);
                    return (
                        <React.Fragment key={bIdx}>
                            {italicParts.map((iPart, iIdx) => {
                                if (iPart.startsWith('*') && iPart.endsWith('*') && !iPart.startsWith('**')) {
                                    return <em key={iIdx} className="italic text-zinc-300">{iPart.slice(1, -1)}</em>;
                                }
                                return iPart;
                            })}
                        </React.Fragment>
                    );
                })}
            </React.Fragment>
        );
    });
}
