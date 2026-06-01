'use client';

import { useEffect, useState, useTransition } from 'react';
import { useRouter, usePathname, useSearchParams } from 'next/navigation';
import { Search, X, Loader2 } from 'lucide-react';
import { useTranslations } from 'next-intl';
import { Input } from '@/components/ui/input';
import { cn } from '@/lib/utils';

interface Props {
  initialQuery: string;
  className?: string;
}

/**
 * Debounced search input.
 * if there's no further keystroke for 350ms after typing, update URL ?q=... -> re-run the server component.
 */
export function InboxSearchBar({ initialQuery, className }: Props) {
  const t = useTranslations('inbox');
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const [value, setValue] = useState(initialQuery);
  const [isPending, startTransition] = useTransition();

  // sync when initialQuery changes externally (e.g. filter reset)
  useEffect(() => {
    setValue(initialQuery);
  }, [initialQuery]);

  // debounce - update URL after 350ms of inactivity following a value change
  useEffect(() => {
    const handler = setTimeout(() => {
      if (value === initialQuery) return;
      const next = new URLSearchParams(searchParams.toString());
      if (value.trim().length === 0) {
        next.delete('q');
      } else {
        next.set('q', value.trim());
      }
      next.delete('page');
      startTransition(() => {
        router.replace(`${pathname}?${next.toString()}`);
      });
    }, 350);
    return () => clearTimeout(handler);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [value]);

  return (
    <div className={cn('relative', className)}>
      {isPending ? (
        <Loader2 className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 animate-spin text-muted-foreground" />
      ) : (
        <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
      )}
      <Input
        type="search"
        value={value}
        onChange={(e) => setValue(e.target.value)}
        placeholder={t('searchPlaceholder')}
        className="pl-9 pr-9"
        aria-label={t('search')}
      />
      {value.length > 0 && (
        <button
          type="button"
          onClick={() => setValue('')}
          className="absolute right-2 top-1/2 -translate-y-1/2 rounded-sm p-1 text-muted-foreground hover:bg-accent"
          aria-label="Clear search"
        >
          <X className="h-3 w-3" />
        </button>
      )}
    </div>
  );
}
