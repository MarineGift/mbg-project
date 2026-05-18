'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import { AlertTriangle, Clock, Plus } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { RelativeTime } from '@/components/common/relative-time';
import { TaskFormDialog } from '@/components/tasks/task-form-dialog';
import type { ModuleType } from '@/types/ai';
import type { PartyTask } from '@/types/party-detail';
import { cn } from '@/lib/utils';

interface Props {
  tasks: readonly PartyTask[];
  /** Add Task 다이얼로그에서 자동 연결할 party */
  partyId: string;
  /** Task에 자동 채울 module */
  module: ModuleType;
}

const PRIORITY_COLORS: Record<string, string> = {
  urgent: 'text-destructive',
  high: 'text-orange-600 dark:text-orange-400',
  medium: 'text-muted-foreground',
  low: 'text-muted-foreground',
};

export function PartyTasksList({ tasks, partyId, module }: Props) {
  const t = useTranslations('partyDetail.tasks');
  const [dialogOpen, setDialogOpen] = useState(false);

  return (
    <>
      <Card>
        <CardHeader className="pb-3 flex flex-row items-center justify-between space-y-0">
          <CardTitle className="text-sm">{t('title')}</CardTitle>
          <Button
            size="sm"
            className="gap-1 bg-blue-600 hover:bg-blue-700 text-white"
            onClick={() => setDialogOpen(true)}
            aria-label={t('addTask')}
          >
            <Plus className="h-4 w-4" />
            <span className="text-xs">{t('addTask')}</span>
          </Button>
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
                        className={cn(
                          'h-3.5 w-3.5 mt-1 shrink-0',
                          PRIORITY_COLORS[task.priority] ?? 'text-muted-foreground',
                        )}
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

      <TaskFormDialog
        open={dialogOpen}
        onOpenChange={setDialogOpen}
        partyId={partyId}
        module={module}
      />
    </>
  );
}
