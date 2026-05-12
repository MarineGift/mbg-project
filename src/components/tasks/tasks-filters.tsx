'use client';

import { useRouter, usePathname, useSearchParams } from 'next/navigation';
import { useTransition } from 'react';
import { useTranslations } from 'next-intl';
import { RotateCcw } from 'lucide-react';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Checkbox } from '@/components/ui/checkbox';
import { Label } from '@/components/ui/label';
import { Button } from '@/components/ui/button';
import type { TaskFilters, TaskSort, TaskPriority, TaskStatus } from '@/types/task';

interface Props {
  filters: TaskFilters;
  sort: TaskSort;
}

const STATUS_VALUES: readonly (TaskStatus | 'open')[] = [
  'open',
  'todo',
  'in_progress',
  'blocked',
  'done',
  'cancelled',
] as const;

const PRIORITIES: readonly TaskPriority[] = ['urgent', 'high', 'medium', 'low'] as const;
const SORTS: readonly TaskSort[] = ['due_soonest', 'priority', 'newest', 'oldest'] as const;

export function TasksFilters({ filters, sort }: Props) {
  const t = useTranslations('tasks.filters');
  const tStatus = useTranslations('tasks.status');
  const tPriority = useTranslations('tasks.priority');
  const tSort = useTranslations('tasks.sort');
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const [isPending, startTransition] = useTransition();

  const setParam = (key: string, value: string | null) => {
    const next = new URLSearchParams(searchParams.toString());
    if (value === null || value === '' || value === 'all') {
      next.delete(key);
    } else {
      next.set(key, value);
    }
    next.delete('page');
    startTransition(() => router.replace(`${pathname}?${next.toString()}`));
  };

  const reset = () => {
    startTransition(() => router.replace(pathname));
  };

  const isDirty =
    filters.status !== 'open' ||
    filters.priority !== 'all' ||
    filters.module !== 'all' ||
    filters.overdueOnly ||
    filters.partyId !== null ||
    sort !== 'due_soonest';

  return (
    <div
      className="flex flex-wrap items-end gap-3 px-4 py-3 border-b bg-muted/30"
      aria-busy={isPending}
    >
      <div className="space-y-1 min-w-[140px]">
        <Label className="text-xs text-muted-foreground">{t('status')}</Label>
        <Select
          value={filters.status}
          onValueChange={(v) => setParam('status', v === 'open' ? null : v)}
        >
          <SelectTrigger>
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {STATUS_VALUES.map((s) => (
              <SelectItem key={s} value={s}>
                {tStatus(s)}
              </SelectItem>
            ))}
            <SelectItem value="all">{t('allStatuses')}</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <div className="space-y-1 min-w-[140px]">
        <Label className="text-xs text-muted-foreground">{t('priority')}</Label>
        <Select
          value={filters.priority}
          onValueChange={(v) => setParam('priority', v)}
        >
          <SelectTrigger>
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">{t('allPriorities')}</SelectItem>
            {PRIORITIES.map((p) => (
              <SelectItem key={p} value={p}>
                {tPriority(p)}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div className="space-y-1 min-w-[160px]">
        <Label className="text-xs text-muted-foreground">{t('sort')}</Label>
        <Select value={sort} onValueChange={(v) => setParam('sort', v === 'due_soonest' ? null : v)}>
          <SelectTrigger>
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {SORTS.map((s) => (
              <SelectItem key={s} value={s}>
                {tSort(s)}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div className="flex items-center gap-2 h-10 pb-0.5">
        <Checkbox
          id="task-overdue"
          checked={filters.overdueOnly}
          onCheckedChange={(v) => setParam('overdue', v === true ? '1' : null)}
        />
        <Label htmlFor="task-overdue" className="cursor-pointer">
          {t('overdueOnly')}
        </Label>
      </div>

      {isDirty && (
        <Button variant="ghost" size="sm" onClick={reset} className="ml-auto">
          <RotateCcw className="h-3.5 w-3.5" />
          {t('reset')}
        </Button>
      )}
    </div>
  );
}
