// src/components/tasks/task-activity-timeline.tsx
'use client';

import {
  Plus, ArrowRightLeft, Flag, CalendarClock, UserCog,
  CheckCircle2, RotateCcw, FileEdit, MessageSquare, Trash2, History,
} from 'lucide-react';
import type { TaskActivityEvent, TaskActivityKind } from '@/lib/queries/task-activity';
import { cn } from '@/lib/utils';

const ICONS: Record<TaskActivityKind, typeof Plus> = {
  created: Plus,
  status_change: ArrowRightLeft,
  priority_change: Flag,
  due_change: CalendarClock,
  assignee_change: UserCog,
  completed: CheckCircle2,
  reopened: RotateCcw,
  field_change: FileEdit,
  comment: MessageSquare,
  deleted: Trash2,
};

const TONE: Partial<Record<TaskActivityKind, string>> = {
  completed: 'text-emerald-600 dark:text-emerald-400',
  reopened: 'text-orange-600 dark:text-orange-400',
  deleted: 'text-destructive',
  comment: 'text-blue-600 dark:text-blue-400',
};

function relTime(iso: string): string {
  const then = new Date(iso).getTime();
  const diff = Date.now() - then;
  const min = Math.round(diff / 60000);
  if (min < 1) return 'just now';
  if (min < 60) return `${min}m ago`;
  const hr = Math.round(min / 60);
  if (hr < 24) return `${hr}h ago`;
  const day = Math.round(hr / 24);
  if (day < 30) return `${day}d ago`;
  return new Date(iso).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
}

export function TaskActivityTimeline({ events }: { events: TaskActivityEvent[] }) {
  if (events.length === 0) {
    return (
      <div className="rounded-lg border bg-muted/30 px-4 py-6 text-center text-sm text-muted-foreground">
        <History className="mx-auto mb-2 h-5 w-5 opacity-50" />
        No activity recorded yet. Status changes and edits will appear here.
      </div>
    );
  }

  return (
    <ol className="relative space-y-0 border-l pl-0">
      {events.map((e) => {
        const Icon = ICONS[e.kind] ?? FileEdit;
        const tone = TONE[e.kind] ?? 'text-muted-foreground';
        return (
          <li key={e.id} className="relative flex gap-3 pb-4 pl-4 last:pb-0">
            <span
              className={cn(
                'absolute -left-[9px] flex h-4 w-4 items-center justify-center rounded-full border bg-background',
                tone,
              )}
            >
              <Icon className="h-2.5 w-2.5" />
            </span>
            <div className="min-w-0 flex-1">
              <div className="flex flex-wrap items-baseline gap-x-2">
                <span className={cn('text-sm', tone)}>{e.summary}</span>
                {e.actorName && (
                  <span className="text-xs text-muted-foreground">by {e.actorName}</span>
                )}
                <span className="text-xs text-muted-foreground">{relTime(e.occurredAt)}</span>
              </div>
              {e.detail && (
                <p className="mt-0.5 whitespace-pre-wrap rounded-md border bg-muted/30 px-2.5 py-1.5 text-xs text-muted-foreground">
                  {e.detail}
                </p>
              )}
            </div>
          </li>
        );
      })}
    </ol>
  );
}
