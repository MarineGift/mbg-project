'use client';

import { useTranslations } from 'next-intl';
import { AlertTriangle, Clock } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { RelativeTime } from '@/components/common/relative-time';
import type { PartyTask } from '@/types/party-detail';
import { cn } from '@/lib/utils';

interface Props {
  tasks: readonly PartyTask[];
}

const PRIORITY_COLORS: Record<string, string> = {
  urgent: 'text-destructive',
  high: 'text-orange-600 dark:text-orange-400',
  medium: 'text-muted-foreground',
  low: 'text-muted-foreground',
};

export function PartyTasksList({ tasks }: Props) {
  const t = useTranslations('partyDetail.tasks');

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="text-sm">{t('title')}</CardTitle>
      </CardHeader>
      <CardContent>
        {tasks.length === 0 ? (
          <p className="text-xs text-muted-foreground italic">{t('empty')}</p>
        ) : (
          <ul className="space-y-2">
            {tasks.map((task) => {
              const isOverdue =
                task.dueAt != null &&
                new Date(task.dueAt).getTime() < Date.now() &&
                !['done', 'cancelled'].includes(task.status);
              return (
                <li key={task.id} className="flex items-start gap-2">
                  {task.priority && (
                    <AlertTriangle
                      className={cn('h-3.5 w-3.5 mt-1 shrink-0', PRIORITY_COLORS[task.priority] ?? 'text-muted-foreground')}
                    />
                  )}
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-sm truncate">{task.title}</p>
                    <div className="flex items-center gap-2 mt-0.5 text-xs text-muted-foreground">
                      <span>{task.status}</span>
                      {task.dueAt && (
                        <>
                          <span>·</span>
                          <span
                            className={cn(
                              'inline-flex items-center gap-1',
                              isOverdue && 'text-destructive font-medium',
                            )}
                          >
                            <Clock className="h-3 w-3" />
                            <RelativeTime date={task.dueAt} live={false} />
                          </span>
                        </>
                      )}
                    </div>
                  </div>
                </li>
              );
            })}
          </ul>
        )}
      </CardContent>
    </Card>
  );
}
