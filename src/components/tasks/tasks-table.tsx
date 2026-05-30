'use client';

import { useState, useTransition } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { Sparkles, Clock, AlertTriangle, Briefcase, Trash2, Loader2 } from 'lucide-react';
import { toast } from 'sonner';
import { TaskCheckbox } from './task-checkbox';
import { TaskDeleteButton } from './task-delete-button';
import { PartyTypeBadge } from '@/components/common/party-type-badge';
import { RelativeTime } from '@/components/common/relative-time';
import { Checkbox } from '@/components/ui/checkbox';
import { Button } from '@/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { deleteTasksBulk } from '@/app/actions/delete-task';
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
  const router = useRouter();

  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [bulkDialogOpen, setBulkDialogOpen] = useState(false);
  const [isPending, startTransition] = useTransition();

  void PRIORITY_ORDER;

  const allSelected = rows.length > 0 && selected.size === rows.length;
  const someSelected = selected.size > 0 && !allSelected;

  function toggleRow(id: string) {
    setSelected((prev) => {
      const next = new Set(prev);
      next.has(id) ? next.delete(id) : next.add(id);
      return next;
    });
  }

  function toggleAll() {
    setSelected(allSelected ? new Set() : new Set(rows.map((r) => r.id)));
  }

  function handleBulkDelete() {
    const ids = Array.from(selected);
    startTransition(async () => {
      const { deleted, errors } = await deleteTasksBulk(ids);
      if (deleted > 0) toast.success(`${deleted} task${deleted > 1 ? 's' : ''} deleted`);
      if (errors.length > 0) toast.error(`${errors.length} failed to delete`);
      setSelected(new Set());
      setBulkDialogOpen(false);
      router.refresh();
    });
  }

  return (
    <>
      {/* 선택 액션바 */}
      {selected.size > 0 && (
        <div className="sticky top-0 z-10 flex items-center gap-3 px-4 py-2 border-b bg-primary/5">
          <Checkbox checked={allSelected} onCheckedChange={toggleAll} aria-label="Select all" />
          <span className="text-sm font-medium">{selected.size} selected</span>
          <Button
            variant="destructive"
            size="sm"
            className="gap-1.5 ml-1"
            onClick={() => setBulkDialogOpen(true)}
            disabled={isPending}
          >
            <Trash2 className="h-3.5 w-3.5" />
            Delete Selected
          </Button>
          <Button variant="ghost" size="sm" onClick={() => setSelected(new Set())} disabled={isPending}>
            Cancel
          </Button>
        </div>
      )}

      {/* 헤더 선택줄 */}
      <div className="flex items-center gap-3 px-4 py-2 border-b bg-muted/30">
        <Checkbox
          checked={allSelected}
          onCheckedChange={toggleAll}
          aria-label="Select all tasks"
          className={someSelected ? 'opacity-50' : ''}
        />
        <span className="text-xs text-muted-foreground">
          {someSelected ? `${selected.size} of ${rows.length} selected` : 'Select all'}
        </span>
      </div>

      {/* 태스크 목록 */}
      <ul className="divide-y">
        {rows.map((row) => {
          const isOverdue =
            row.dueAt != null &&
            new Date(row.dueAt).getTime() < Date.now() &&
            !['done', 'cancelled'].includes(row.status);
          const isDone = row.status === 'done';
          const isCancelled = row.status === 'cancelled';
          const isSelected = selected.has(row.id);

          return (
            <li
              key={row.id}
              className={cn(
                'relative group flex items-stretch',
                isSelected && 'bg-primary/5',
              )}
            >
              {/* 선택 체크박스 */}
              <div
                className="flex items-start pt-3.5 px-3 cursor-pointer shrink-0 hover:bg-muted/30"
                onClick={(e: React.MouseEvent) => {
                  e.preventDefault();
                  e.stopPropagation();
                  toggleRow(row.id);
                }}
              >
                <Checkbox
                  checked={isSelected}
                  onCheckedChange={() => toggleRow(row.id)}
                  aria-label={`Select: ${row.title}`}
                  onClick={(e: React.MouseEvent) => e.stopPropagation()}
                />
              </div>

              {/* 메인 콘텐츠 */}
              <div
                className={cn(
                  'flex items-start gap-3 px-2 py-3 pr-10 hover:bg-muted/40 transition-colors flex-1 min-w-0',
                  isDone && 'opacity-60',
                  isCancelled && 'opacity-40 italic',
                )}
              >
                <TaskCheckbox taskId={row.id} status={row.status} />

                <div className="flex-1 min-w-0">
                  <div className="flex items-start gap-2">
                    <p className={cn('text-sm font-medium flex-1 truncate', isDone && 'line-through')}>
                      {row.title}
                    </p>
                    {row.aiSuggested && (
                      <span className="inline-flex items-center gap-1 text-xs text-purple-600 dark:text-purple-400 shrink-0">
                        <Sparkles className="h-3 w-3" />
                      </span>
                    )}
                    <AlertTriangle
                      className={cn('h-3.5 w-3.5 shrink-0', PRIORITY_COLORS[row.priority])}
                      aria-label={tPriority(row.priority)}
                    />
                  </div>

                  {row.description && (
                    <p className={cn('text-xs text-muted-foreground line-clamp-1 mt-0.5', isDone && 'line-through')}>
                      {row.description}
                    </p>
                  )}

                  <div className="flex flex-wrap items-center gap-x-3 gap-y-1 mt-1 text-xs">
                    {row.partyId && row.partyName && row.partyTypeCode && (
                      <Link
                        href={`/${row.partyTypeCode}/parties/${row.partyId}`}
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
                    {row.partyType && <PartyTypeBadge partyType={row.partyType} size="sm" />}
                    {row.dueAt && (
                      <span className={cn('inline-flex items-center gap-1', isOverdue ? 'text-destructive font-medium' : 'text-muted-foreground')}>
                        <Clock className="h-3 w-3" />
                        <RelativeTime date={row.dueAt} live={false} />
                      </span>
                    )}
                    <span className="text-muted-foreground">{tStatus(row.status)}</span>
                  </div>
                </div>
              </div>

              {/* 단건 삭제 버튼 */}
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

      {/* 일괄 삭제 확인 다이얼로그 */}
      <Dialog open={bulkDialogOpen} onOpenChange={setBulkDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <AlertTriangle className="h-5 w-5 text-destructive" />
              Delete {selected.size} task{selected.size > 1 ? 's' : ''}?
            </DialogTitle>
            <DialogDescription asChild>
              <div>
                <span className="block text-sm">
                  Permanently deletes <strong>{selected.size}</strong> task{selected.size > 1 ? 's' : ''}.
                </span>
                <span className="block mt-2 text-sm text-destructive font-medium">
                  This action cannot be undone.
                </span>
              </div>
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setBulkDialogOpen(false)} disabled={isPending}>
              Cancel
            </Button>
            <Button variant="destructive" onClick={handleBulkDelete} disabled={isPending}>
              {isPending
                ? <><Loader2 className="h-4 w-4 animate-spin mr-2" />Deleting…</>
                : `Delete ${selected.size}`}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
