// src/components/tasks/task-detail-client.tsx
'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import {
  ArrowLeft, Pencil, Trash2, Sparkles, Clock,
  Briefcase, AlertTriangle, CheckCircle2, Loader2,
} from 'lucide-react';
import { toast } from 'sonner';
import { Button } from '@/components/ui/button';
import { PartyTypeBadge } from '@/components/common/party-type-badge';
import { TaskFormDialog } from './task-form-dialog';
import { updateTaskStatus, deleteTask } from '@/lib/actions/tasks';
import type { TaskRow, TaskStatus, TaskPriority } from '@/types/task';
import { cn } from '@/lib/utils';

const STATUS_LABELS: Record<TaskStatus, string> = {
  todo:        'To Do',
  in_progress: 'In Progress',
  blocked:     'Blocked',
  done:        'Done',
  cancelled:   'Cancelled',
};

const STATUS_COLORS: Record<TaskStatus, string> = {
  todo:        'bg-slate-100 text-slate-700 border-slate-200',
  in_progress: 'bg-blue-100 text-blue-700 border-blue-200',
  blocked:     'bg-orange-100 text-orange-700 border-orange-200',
  done:        'bg-green-100 text-green-700 border-green-200',
  cancelled:   'bg-gray-100 text-gray-500 border-gray-200',
};

const PRIORITY_LABELS: Record<TaskPriority, string> = {
  urgent: 'Urgent',
  high:   'High',
  medium: 'Medium',
  low:    'Low',
};

const PRIORITY_COLORS: Record<TaskPriority, string> = {
  urgent: 'text-destructive',
  high:   'text-orange-600 dark:text-orange-400',
  medium: 'text-blue-600 dark:text-blue-400',
  low:    'text-muted-foreground',
};

const ALL_STATUSES: readonly TaskStatus[] = [
  'todo', 'in_progress', 'blocked', 'done', 'cancelled',
] as const;

interface Props {
  task: TaskRow;
}

export function TaskDetailClient({ task: initial }: Props) {
  const router = useRouter();
  const [task, setTask] = useState<TaskRow>(initial);
  const [editOpen, setEditOpen] = useState(false);
  const [isPending, startTransition] = useTransition();

  const isOverdue =
    task.dueAt != null &&
    new Date(task.dueAt).getTime() < Date.now() &&
    !['done', 'cancelled'].includes(task.status);

  function handleStatusChange(status: TaskStatus) {
    if (status === task.status || isPending) return;
    startTransition(async () => {
      const result = await updateTaskStatus({ taskId: task.id, status });
      if (result.ok) {
        setTask(prev => ({
          ...prev,
          status,
          completedAt:
            status === 'done'
              ? new Date().toISOString()
              : status === 'todo'
              ? null
              : prev.completedAt,
        }));
        toast.success(`Status set to ${STATUS_LABELS[status]}`);
      } else {
        toast.error(result.errorMessage ?? 'Failed to update status');
      }
    });
  }

  function handleDelete() {
    if (!confirm('Delete this task? This action cannot be undone.')) return;
    startTransition(async () => {
      const result = await deleteTask({ taskId: task.id });
      if (result.ok) {
        toast.success('Task deleted');
        router.push('/tasks');
      } else {
        toast.error(result.errorMessage ?? 'Failed to delete task');
      }
    });
  }

  function fmt(iso: string | null): string | null {
    if (!iso) return null;
    return new Date(iso).toLocaleString('en-US', {
      year: 'numeric', month: 'short', day: 'numeric',
      hour: '2-digit', minute: '2-digit',
    });
  }

  return (
    <div className="flex flex-col h-full">
      {/* ── Header ── */}
      <header className="px-6 py-4 border-b bg-background flex items-center gap-3">
        <Button variant="ghost" size="icon" className="h-8 w-8 shrink-0" asChild>
          <Link href="/tasks">
            <ArrowLeft className="h-4 w-4" />
          </Link>
        </Button>

        <h1
          className={cn(
            'flex-1 min-w-0 text-lg font-semibold truncate',
            task.status === 'done' && 'line-through opacity-60',
            task.status === 'cancelled' && 'line-through opacity-40 italic',
          )}
        >
          {task.title}
        </h1>

        <div className="flex items-center gap-2 shrink-0">
          {task.aiSuggested && (
            <span
              className="inline-flex items-center gap-1 text-xs text-purple-600 dark:text-purple-400"
              title="AI-suggested task"
            >
              <Sparkles className="h-3.5 w-3.5" />
              AI
            </span>
          )}
          <Button
            variant="outline"
            size="sm"
            className="h-8"
            onClick={() => setEditOpen(true)}
            disabled={isPending}
          >
            <Pencil className="h-3.5 w-3.5 mr-1" />
            Edit
          </Button>
          <Button
            variant="ghost"
            size="sm"
            className="h-8 text-destructive hover:text-destructive hover:bg-destructive/10"
            onClick={handleDelete}
            disabled={isPending}
          >
            {isPending
              ? <Loader2 className="h-3.5 w-3.5 animate-spin" />
              : <Trash2 className="h-3.5 w-3.5" />}
          </Button>
        </div>
      </header>

      {/* ── Body ── */}
      <div className="flex-1 overflow-y-auto p-6">
        <div className="max-w-2xl mx-auto space-y-6">

          {/* Status + Priority badges */}
          <div className="flex flex-wrap items-center gap-2">
            <span
              className={cn(
                'inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border',
                STATUS_COLORS[task.status],
              )}
            >
              {STATUS_LABELS[task.status]}
            </span>
            <span
              className={cn(
                'inline-flex items-center gap-1 text-xs font-medium',
                PRIORITY_COLORS[task.priority],
              )}
            >
              <AlertTriangle className="h-3.5 w-3.5" />
              {PRIORITY_LABELS[task.priority]}
            </span>
            {isOverdue && (
              <span className="inline-flex items-center gap-1 text-xs font-medium text-destructive">
                <Clock className="h-3.5 w-3.5" />
                Overdue
              </span>
            )}
            {task.partyType && <PartyTypeBadge partyType={task.partyType} size="sm" />}
          </div>

          {/* Status change */}
          <div className="space-y-2">
            <p className="text-xs font-medium text-muted-foreground uppercase tracking-wide">
              Change Status
            </p>
            <div className="flex flex-wrap gap-1.5">
              {ALL_STATUSES.map(s => (
                <Button
                  key={s}
                  size="sm"
                  variant={task.status === s ? 'default' : 'outline'}
                  className="h-7 text-xs"
                  disabled={isPending || task.status === s}
                  onClick={() => handleStatusChange(s)}
                >
                  {task.status === s && (
                    <CheckCircle2 className="h-3 w-3 mr-1" />
                  )}
                  {STATUS_LABELS[s]}
                </Button>
              ))}
            </div>
          </div>

          {/* Description */}
          {task.description && (
            <div className="space-y-2">
              <p className="text-xs font-medium text-muted-foreground uppercase tracking-wide">
                Description
              </p>
              <div className="rounded-lg border bg-muted/30 px-4 py-3 text-sm whitespace-pre-wrap">
                {task.description}
              </div>
            </div>
          )}

          {/* Details */}
          <div className="space-y-2">
            <p className="text-xs font-medium text-muted-foreground uppercase tracking-wide">
              Details
            </p>
            <dl className="rounded-lg border divide-y text-sm">
              {task.partyId && task.partyName && task.partyTypeCode && (
                <div className="flex items-center px-4 py-2.5 gap-3">
                  <dt className="w-28 shrink-0 text-muted-foreground">Party</dt>
                  <dd>
                    <Link
                      href={`/${task.partyTypeCode}/parties/${task.partyId}`}
                      className="inline-flex items-center gap-1.5 text-primary hover:underline"
                    >
                      <Briefcase className="h-3.5 w-3.5" />
                      {task.partyName}
                    </Link>
                  </dd>
                </div>
              )}
              {task.engagementId && task.engagementName && (
                <div className="flex items-center px-4 py-2.5 gap-3">
                  <dt className="w-28 shrink-0 text-muted-foreground">Engagement</dt>
                  <dd>
                    <Link
                      href={`/engagements/${task.engagementId}`}
                      className="text-primary hover:underline"
                    >
                      {task.engagementName}
                    </Link>
                  </dd>
                </div>
              )}
              {task.dueAt && (
                <div className="flex items-center px-4 py-2.5 gap-3">
                  <dt className="w-28 shrink-0 text-muted-foreground">Due</dt>
                  <dd className={cn(isOverdue && 'text-destructive font-medium')}>
                    {fmt(task.dueAt)}
                  </dd>
                </div>
              )}
              {task.completedAt && (
                <div className="flex items-center px-4 py-2.5 gap-3">
                  <dt className="w-28 shrink-0 text-muted-foreground">Completed</dt>
                  <dd>{fmt(task.completedAt)}</dd>
                </div>
              )}
              <div className="flex items-center px-4 py-2.5 gap-3">
                <dt className="w-28 shrink-0 text-muted-foreground">Created</dt>
                <dd className="text-muted-foreground">{fmt(task.createdAt)}</dd>
              </div>
            </dl>
          </div>

        </div>
      </div>

      {/* Edit dialog */}
      <TaskFormDialog
        open={editOpen}
        onOpenChange={setEditOpen}
        existing={task}
      />
    </div>
  );
}
