'use client';

import Link from 'next/link';
import { useTranslations } from 'next-intl';
import { Sparkles, Clock, AlertTriangle, Briefcase } from 'lucide-react';
import { TaskCheckbox } from './task-checkbox';
import { TaskDeleteButton } from './task-delete-button';
import { ModuleBadge } from '@/components/common/module-badge';
import { RelativeTime } from '@/components/common/relative-time';
import type { TaskPriority, TaskRow } from '@/types/task';
import { cn } from '@/lib/utils';

interface Props {
  rows: readonly TaskRow[];
}

const PRIORITY_COLORS: Record<TaskPriority, string> = {
  urgent: 'text-destructive',
  high: 'text-orange-600 dark:text-orange-400',
  medium: 'text-blue-600 dark:text-blue-400',
  low: 'text-muted-foreground',
};

const PRIORITY_ORDER: Record<TaskPriority, number> = {
  urgent: 4,
  high: 3,
  medium: 2,
  low: 1,
};

export function TasksTable({ rows }: Props) {
  const t = useTranslations('tasks');
  const tStatus = useTranslations('tasks.status');
  const tPriority = useTranslations('tasks.priority');

  return (
    <ul className="divide-y">
      {rows.map((row) => {
        const isOverdue =
          row.dueAt != null &&
          new Date(row.dueAt).getTime() < Date.now() &&
          !['done', 'cancelled'].includes(row.status);
        const isDone = row.status === 'done';
        const isCancelled = row.status === 'cancelled';
        // 사용 경고 회피
        void PRIORITY_ORDER;

        return (
          <li key={row.id} className="relative group">
            <div
              className={cn(
                'flex items-start gap-3 px-4 py-3 pr-10 hover:bg-muted/40 transition-colors',
                isDone && 'opacity-60',
                isCancelled && 'opacity-40 italic',
              )}
            >
              <TaskCheckbox taskId={row.id} status={row.status} />

              <div className="flex-1 min-w-0">
                <div className="flex items-start gap-2">
                  <p
                    className={cn(
                      'text-sm font-medium flex-1 truncate',
                      isDone && 'line-through',
                    )}
                  >
                    {row.title}
                  </p>
                  {row.aiSuggested && (
                    <span
                      className="inline-flex items-center gap-1 text-xs text-purple-600 dark:text-purple-400 shrink-0"
                      title="AI-suggested task"
                    >
                      <Sparkles className="h-3 w-3" />
                    </span>
                  )}
                  <AlertTriangle
                    className={cn('h-3.5 w-3.5 shrink-0', PRIORITY_COLORS[row.priority])}
                    aria-label={tPriority(row.priority)}
                  />
                </div>

                {row.description && (
                  <p className={cn(
                    'text-xs text-muted-foreground line-clamp-1 mt-0.5',
                    isDone && 'line-through',
                  )}>
                    {row.description}
                  </p>
                )}

                <div className="flex flex-wrap items-center gap-x-3 gap-y-1 mt-1 text-xs">
                  {row.partyId && row.partyName && row.partyModule && (
                    <Link
                      href={`/${row.partyModule}/parties/${row.partyId}`}
                      className="inline-flex items-center gap-1 text-muted-foreground hover:text-foreground hover:underline"
                      onClick={(e) => e.stopPropagation()}
                    >
                      <Briefcase className="h-3 w-3" />
                      {row.partyName}
                    </Link>
                  )}
                  {row.engagementId && row.engagementName && (
                    <Link
                      href={`/engagements/${row.engagementId}`}
                      className="text-muted-foreground hover:text-foreground hover:underline"
                      onClick={(e) => e.stopPropagation()}
                    >
                      {row.engagementName}
                    </Link>
                  )}
                  {row.module && <ModuleBadge module={row.module} size="sm" />}
                  {row.dueAt && (
                    <span
                      className={cn(
                        'inline-flex items-center gap-1',
                        isOverdue
                          ? 'text-destructive font-medium'
                          : 'text-muted-foreground',
                      )}
                    >
                      <Clock className="h-3 w-3" />
                      <RelativeTime date={row.dueAt} live={false} />
                    </span>
                  )}
                  <span className="text-muted-foreground">
                    {tStatus(row.status)}
                  </span>
                </div>
              </div>
            </div>

            {/* 삭제 버튼 — hover 시 표시 */}
            <div className="absolute top-2.5 right-2">
              <TaskDeleteButton id={row.id} title={row.title} />
            </div>
          </li>
        );
      })}
      {rows.length === 0 && (
        <li className="px-4 py-6 text-center text-sm text-muted-foreground italic">
          {t('empty.fallback')}
        </li>
      )}
    </ul>
  );
}
