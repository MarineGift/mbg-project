'use client';

import { useEffect, useState, useTransition } from 'react';
import { useRouter, usePathname, useSearchParams } from 'next/navigation';
import { Search, X, Loader2 } from 'lucide-react';
import { useTranslations } from 'next-intl';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { cn } from '@/lib/utils';
import type { InboxSearchField } from '@/types/inbox';

interface Props {
  initialQuery: string;
  /** current search scope (from URL); defaults to 'all' */
  initialField?: InboxSearchField;
  className?: string;
}

const FIELD_OPTIONS: Array<{ value: InboxSearchField; label: string }> = [
  { value: 'all', label: 'All' },
  { value: 'from', label: 'From (sender)' },
  { value: 'to', label: 'To (recipient)' },
  { value: 'subject', label: 'Subject' },
];

/**
 * Debounced search input.
 * if there's no further keystroke for 350ms after typing, update URL ?q=... -> re-run the server component.
 */
export function InboxSearchBar({ initialQuery, initialField = 'all', className }: Props) {
  const t = useTranslations('inbox');
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const [value, setValue] = useState(initialQuery);
  const [field, setField] = useState<InboxSearchField>(initialField);
  const [isPending, startTransition] = useTransition();

  // sync when initialQuery changes externally (e.g. filter reset)
  useEffect(() => {
    setValue(initialQuery);
  }, [initialQuery]);
  useEffect(() => {
    setField(initialField);
  }, [initialField]);

  // Changing the scope updates the URL right away (only meaningful with a term).
  function onFieldChange(next: InboxSearchField) {
    setField(next);
    const params = new URLSearchParams(searchParams.toString());
    if (next === 'all') {
      params.delete('field');
    } else {
      params.set('field', next);
    }
    params.delete('page');
    startTransition(() => {
      router.replace(`${pathname}?${params.toString()}`);
    });
  }

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
      // keep the current scope in the URL alongside the term
      if (field === 'all') {
        next.delete('field');
      } else {
        next.set('field', field);
      }
      next.delete('page');
      startTransition(() => {
        router.replace(`${pathname}?${next.toString()}`);
      });
    }, 350);
    return () => clearTimeout(handler);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [value]);

  // Immediate search (Enter key / Search button) - bypasses the 350ms debounce.
  function runSearch() {
    const next = new URLSearchParams(searchParams.toString());
    if (value.trim().length === 0) {
      next.delete('q');
    } else {
      next.set('q', value.trim());
    }
    if (field === 'all') {
      next.delete('field');
    } else {
      next.set('field', field);
    }
    next.delete('page');
    startTransition(() => {
      router.replace(`${pathname}?${next.toString()}`);
    });
  }

  return (
    <div className={cn('flex gap-2', className)}>
      <Select value={field} onValueChange={(v) => onFieldChange(v as InboxSearchField)}>
        <SelectTrigger className="w-[150px] shrink-0" aria-label="Search field">
          <SelectValue />
        </SelectTrigger>
        <SelectContent>
          {FIELD_OPTIONS.map((opt) => (
            <SelectItem key={opt.value} value={opt.value}>
              {opt.label}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
      <div className="relative flex-1">
        {isPending ? (
          <Loader2 className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 animate-spin text-muted-foreground" />
        ) : (
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        )}
        <Input
          type="search"
          value={value}
          onChange={(e) => setValue(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === 'Enter') {
              e.preventDefault();
              runSearch();
            }
          }}
          placeholder={
            field === 'to'
              ? 'Search by recipient address...'
              : field === 'from'
                ? 'Search by sender...'
                : field === 'subject'
                  ? 'Search by subject...'
                  : t('searchPlaceholder')
          }
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
      <Button type="button" onClick={runSearch} className="shrink-0 gap-2">
        <Search className="h-4 w-4" />
        Search
      </Button>
    </div>
  );
}
