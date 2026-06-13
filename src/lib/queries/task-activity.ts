// src/lib/queries/task-activity.ts
//
// Task Activity Timeline (read).
//
// Source: audit.change_log (already populated by trg_audit_tasks -> log_change;
// 2108 rows across 1229 tasks as of 2026-06-12). No migration needed for the
// automatic events; we just read and humanize them.
//
// Manual comments (BB1 step 2) will live in app.task_activity and be merged in
// here once that table exists. For now this returns the audit-derived events.

import 'server-only';
import { createSupabaseServerClient } from '@/lib/supabase/server';

export type TaskActivityKind =
  | 'created'
  | 'status_change'
  | 'priority_change'
  | 'due_change'
  | 'assignee_change'
  | 'completed'
  | 'reopened'
  | 'field_change'
  | 'comment'
  | 'deleted';

export interface TaskActivityEvent {
  id: string;
  kind: TaskActivityKind;
  /** human-readable summary, e.g. "Status: To Do -> In Progress" */
  summary: string;
  /** optional secondary detail / comment body */
  detail: string | null;
  actorUserId: string | null;
  actorName: string | null;
  occurredAt: string;
}

interface RawAuditRow {
  id: number;
  occurred_at: string;
  operation: string; // INSERT | UPDATE | DELETE
  changed_columns: string[] | null;
  changed_by: string | null;
  actor_name: string | null;
  old_data: Record<string, unknown> | null;
  new_data: Record<string, unknown> | null;
}

const STATUS_LABELS: Record<string, string> = {
  todo: 'To Do',
  in_progress: 'In Progress',
  blocked: 'Blocked',
  done: 'Done',
  cancelled: 'Cancelled',
  // legacy values still present in older rows / audit history
  pending: 'To Do',
  open: 'To Do',
  completed: 'Done',
};

const PRIORITY_LABELS: Record<string, string> = {
  urgent: 'Urgent',
  high: 'High',
  medium: 'Medium',
  low: 'Low',
};

function lbl(map: Record<string, string>, v: unknown): string {
  const s = v == null ? '' : String(v);
  return map[s] ?? (s || '—');
}

function fmtDate(v: unknown): string {
  if (!v) return 'none';
  const d = new Date(String(v));
  if (Number.isNaN(d.getTime())) return String(v);
  return d.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
}

/**
 * Turn one audit row into 0..n timeline events. An UPDATE that touches several
 * columns yields one event per meaningful column; noise columns are skipped.
 */
function rowToEvents(r: RawAuditRow): TaskActivityEvent[] {
  const base = { actorUserId: r.changed_by, actorName: r.actor_name, occurredAt: r.occurred_at };

  if (r.operation === 'INSERT') {
    return [{ id: `${r.id}-c`, kind: 'created', summary: 'Task created', detail: null, ...base }];
  }
  if (r.operation === 'DELETE') {
    return [{ id: `${r.id}-d`, kind: 'deleted', summary: 'Task deleted', detail: null, ...base }];
  }

  // UPDATE — derive per-column events
  const cols = r.changed_columns ?? [];
  const old = r.old_data ?? {};
  const neu = r.new_data ?? {};
  const events: TaskActivityEvent[] = [];

  // Skip bookkeeping columns that aren't interesting on a timeline.
  const IGNORE = new Set(['updated_at', 'updated_by', 'search_vector', 'extra_data']);

  for (const col of cols) {
    if (IGNORE.has(col)) continue;

    if (col === 'status') {
      const from = String(old.status ?? '');
      const to = String(neu.status ?? '');
      const isDone = (s: string) => s === 'done' || s === 'completed';
      const kind: TaskActivityKind =
        isDone(to) ? 'completed' : isDone(from) ? 'reopened' : 'status_change';
      events.push({
        id: `${r.id}-status`,
        kind,
        summary:
          kind === 'completed'
            ? 'Marked complete'
            : kind === 'reopened'
              ? 'Reopened'
              : `Status: ${lbl(STATUS_LABELS, from)} -> ${lbl(STATUS_LABELS, to)}`,
        detail: null,
        ...base,
      });
    } else if (col === 'priority') {
      events.push({
        id: `${r.id}-priority`,
        kind: 'priority_change',
        summary: `Priority: ${lbl(PRIORITY_LABELS, old.priority)} -> ${lbl(PRIORITY_LABELS, neu.priority)}`,
        detail: null,
        ...base,
      });
    } else if (col === 'due_at') {
      events.push({
        id: `${r.id}-due`,
        kind: 'due_change',
        summary: `Due date: ${fmtDate(old.due_at)} -> ${fmtDate(neu.due_at)}`,
        detail: null,
        ...base,
      });
    } else if (col === 'assigned_to_contact_id' || col === 'assigned_to_user_id') {
      events.push({
        id: `${r.id}-assignee`,
        kind: 'assignee_change',
        summary: 'Assignee changed',
        detail: null,
        ...base,
      });
    } else if (col === 'notes') {
      const to = (neu.notes as string | null)?.trim();
      events.push({
        id: `${r.id}-notes`,
        kind: 'field_change',
        summary: to ? 'Blocker / notes updated' : 'Blocker / notes cleared',
        detail: to ? to.slice(0, 240) : null,
        ...base,
      });
    } else if (col === 'description' || col === 'title') {
      events.push({
        id: `${r.id}-${col}`,
        kind: 'field_change',
        summary: `${col === 'title' ? 'Title' : 'Description'} edited`,
        detail: null,
        ...base,
      });
    }
    // other columns (started_at, completed_at, etc.) are implied by status; skip.
  }

  return events;
}

/**
 * Fetch the activity timeline for one task, newest first.
 * Calls the app.task_activity RPC (SECURITY DEFINER), which reads
 * audit.change_log scoped to the caller's org and joins the actor name.
 * audit.change_log has RLS + no authenticated grant, so a direct read returns
 * nothing — the RPC is the supported path. On any error returns [] so the
 * detail page degrades to "no history" instead of throwing.
 */
export async function fetchTaskActivity(taskId: string): Promise<TaskActivityEvent[]> {
  const supabase = await createSupabaseServerClient();

  const rpc = supabase as unknown as {
    rpc: (
      fn: string,
      args: Record<string, unknown>,
    ) => Promise<{ data: RawAuditRow[] | null; error: { message: string } | null }>;
  };

  let rows: RawAuditRow[] = [];
  try {
    const { data, error } = await rpc.rpc('task_activity', { p_task_id: taskId });
    if (error) {
      // eslint-disable-next-line no-console
      console.warn('[task-activity] rpc failed:', error.message);
      return [];
    }
    rows = data ?? [];
  } catch (err) {
    // eslint-disable-next-line no-console
    console.warn('[task-activity] rpc threw:', err instanceof Error ? err.message : err);
    return [];
  }

  const events = rows.flatMap(rowToEvents);
  events.sort((a, b) => new Date(b.occurredAt).getTime() - new Date(a.occurredAt).getTime());
  return events;
}
