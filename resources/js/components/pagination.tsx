import { Link } from '@inertiajs/react';
import type { PaginationLink } from '@/types';

interface PaginationProps {
    links: PaginationLink[];
    className?: string;
}

export function Pagination({ links, className = '' }: PaginationProps) {
    if (links.length <= 3) {
        return null;
    }

    return (
        <nav
            aria-label="Pagination"
            className={`flex flex-wrap items-center justify-center gap-1 py-4 ${className}`}
        >
            {links.map((link, index) => {
                const label = link.label
                    .replace('&laquo;', '«')
                    .replace('&raquo;', '»');

                if (!link.url) {
                    return (
                        <span
                            key={index}
                            className="inline-flex h-9 items-center justify-center border border-border/40 bg-muted/20 px-3 text-xs text-muted-foreground opacity-50 cursor-not-allowed select-none"
                            dangerouslySetInnerHTML={{ __html: label }}
                        />
                    );
                }

                return (
                    <Link
                        key={index}
                        href={link.url}
                        preserveScroll
                        className={`inline-flex h-9 items-center justify-center border px-3 text-xs font-mono transition-colors ${
                            link.active
                                ? 'border-primary bg-primary text-primary-foreground font-semibold'
                                : 'border-border bg-card text-foreground hover:bg-accent hover:text-accent-foreground'
                        }`}
                        dangerouslySetInnerHTML={{ __html: label }}
                    />
                );
            })}
        </nav>
    );
}
