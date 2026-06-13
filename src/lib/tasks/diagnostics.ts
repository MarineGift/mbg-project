// src/lib/tasks/diagnostics.ts
//
// Why isn't this task done yet? — data-driven completion diagnostics.
//
// A CRM cannot know the human reason a task stalled, but it can surface signals
// from the row itself: overdue, no owner, no due date, blocked status with no
// recorded reason, long-stalled in progress, missing reference material.
// The user records the real reason via the blocker notes field.

import type { TaskRow } from '@/types/task';

export type DiagnosticLevel = 'blocker' | 'warning' | 'info';

export interface TaskDiagnostic {
  level: DiagnosticLevel;
  /** short label shown as a chip */
  label: string;
  /** one-line explanation */
  detail: string;
}

const DAY_MS = 24 * 60 * 60 * 1000;

function daysBetween(fromIso: string, toMs: number): number {
  return Math.floor((toMs - new Date(fromIso).getTime()) / DAY_MS);
}

/**
 * Compute completion-readiness diagnostics for a task.
 * `attachmentCount` is passed in because attachments live in a separate table.
 * Returns [] for done/cancelled tasks (nothing to diagnose).
 */
export function diagnoseTask(
  task: TaskRow,
  attachmentCount: number,
  now: number = Date.now(),
): TaskDiagnostic[] {
  if (task.status === 'done' || task.status === 'cancelled') return [];

  const out: TaskDiagnostic[] = [];

  // Explicitly blocked
  if (task.status === 'blocked') {
    out.push({
      level: 'blocker',
      label: 'Blocked',
      detail: task.notes?.trim()
        ? `Marked blocked. Reason: ${task.notes.trim()}`
        : 'Marked blocked, but no reason recorded. Add a blocker note below.',
    });
  }

  // Overdue (status is already not done/cancelled — guarded at the top)
  if (task.dueAt && new Date(task.dueAt).getTime() < now) {
    const overdueDays = daysBetween(task.dueAt, now);
    out.push({
      level: 'blocker',
      label: 'Overdue',
      detail:
        overdueDays >= 1
          ? `Past due by ${overdueDays} day${overdueDays === 1 ? '' : 's'}.`
          : 'Past its due time today.',
    });
  }

  // No owner
  if (!task.assignedToUserId && !task.assignedToContactId) {
    out.push({
      level: 'warning',
      label: 'No owner',
      detail: 'No assignee — unowned tasks tend to stall. Assign someone.',
    });
  }

  // No due date
  if (!task.dueAt) {
    out.push({
      level: 'warning',
      label: 'No due date',
      detail: 'No target date set — work without a deadline slips.',
    });
  }

  // Stalled in progress (started long ago, still not done)
  if (task.status === 'in_progress' && task.startedAt) {
    const stalledDays = daysBetween(task.startedAt, now);
    if (stalledDays >= 7) {
      out.push({
        level: 'warning',
        label: 'Stalled',
        detail: `In progress for ${stalledDays} days without completion.`,
      });
    }
  }

  // Sitting in todo a long time after creation
  if (task.status === 'todo' && task.createdAt) {
    const ageDays = daysBetween(task.createdAt, now);
    if (ageDays >= 14) {
      out.push({
        level: 'info',
        label: 'Untouched',
        detail: `Created ${ageDays} days ago and not started.`,
      });
    }
  }

  // No reference material
  if (attachmentCount === 0) {
    out.push({
      level: 'info',
      label: 'No attachments',
      detail: 'No reference files attached. Add supporting material if relevant.',
    });
  }

  return out;
}

/** Highest severity present, for an at-a-glance summary chip. */
export function topLevel(diags: TaskDiagnostic[]): DiagnosticLevel | null {
  if (diags.some((d) => d.level === 'blocker')) return 'blocker';
  if (diags.some((d) => d.level === 'warning')) return 'warning';
  if (diags.some((d) => d.level === 'info')) return 'info';
  return null;
}
