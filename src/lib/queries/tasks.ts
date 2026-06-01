/**
 * lib/queries/tasks.ts
 *
 * Task list/detail fetch + URL parsers.
 *
 * 2026-06-01 cleanup: app.tasks is deal-scoped and has NO party_id /
 * engagement_id / party_type / module / reminder_at / linked_strategy_action_id
 * columns. The SELECTs were rewritten to schema-correct deal-based shape; the
 * URL parsers below are unchanged (pure, no DB) and still consumed by tests.
 */

import 'server-only';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import type { PartyTypeCode } from '@/types/ai';
import type {
  TaskFilters,
  TaskListResult,
  TaskPagination,
  TaskPriority,
  TaskRow,
  TaskSort,
  TaskStatus,
} from '@/types/task';
import {
  DEFAULT_TASK_FILTERS,
  DEFAULT_TASK_SORT,
  TASK_DEFAULT_PAGE_SIZE,
  TASK_PAGE_SIZE_OPTIONS,
} from '@/types/task';

const ALL_STATUSES: readonly TaskStatus[] = [
  'todo',
  'in_progress',
  'blocked',
  'done',
  'cancelled',
] as const;
const OPEN_STATUSES: readonly TaskStatus[] = ['todo', 'in_progress', 'blocked'] as const;
const ALL_PRIORITIES: readonly TaskPriority[] = ['low', 'medium', 'high', 'urgent'] as const;
const ALL_MODULES: readonly PartyTypeCode[] = [
  'investor',
  'paper_mill',
  'partner',
  'customer',
  'filler_supplier',
] as const;
const ALL_SORTS: readonly TaskSort[] = [
  'due_soonest',
  'priority',
  'newest',
  'oldest',
] as const;

/* URL parse (pure — unchanged) */

export function parseTaskFilters(
  params: Record<string, string | string[] | undefined>,
): TaskFilters {
  const statusRaw = single(params.status);
  const status: TaskFilters['status'] =
    statusRaw === 'all'
      ? 'all'
      : statusRaw === 'open'
        ? 'open'
        : statusRaw && (ALL_STATUSES as readonly string[]).includes(statusRaw)
          ? (statusRaw as TaskStatus)
          : 'open';

  const priority = pickEnum(params.priority, ALL_PRIORITIES, 'all' as const) as
    | TaskPriority
    | 'all';
  const module = pickEnum(params.partyType, ALL_MODULES, 'all' as const) as
    | PartyTypeCode
    | 'all';
  const overdueOnly = single(params.overdue) === '1';
  const partyId =
    single(params.party) && /^[0-9a-f-]{36}$/i.test(single(params.party)!)
      ? single(params.party)!
      : null;

  return { status, priority, module, overdueOnly, partyId } as never;
}

export function parseTaskSort(
  params: Record<string, string | string[] | undefined>,
): TaskSort {
  const raw = single(params.sort);
  return raw && (ALL_SORTS as readonly string[]).includes(raw)
    ? (raw as TaskSort)
    : DEFAULT_TASK_SORT;
}

export function parseTaskPagination(
  params: Record<string, string | string[] | undefined>,
): TaskPagination {
  const pageRaw = Number(single(params.page) ?? '1');
  const sizeRaw = Number(single(params.size) ?? String(TASK_DEFAULT_PAGE_SIZE));
  const page = Number.isFinite(pageRaw) && pageRaw >= 1 ? Math.floor(pageRaw) : 1;
  const pageSize = (TASK_PAGE_SIZE_OPTIONS as readonly number[]).includes(sizeRaw)
    ? sizeRaw
    : TASK_DEFAULT_PAGE_SIZE;
  return { page, pageSize };
}

function single(v: string | string[] | undefined): string | undefined {
  return Array.isArray(v) ? v[0] : v;
}
function pickEnum<T extends string>(
  v: string | string[] | undefined,
  allowed: readonly T[],
  fallback: T | 'all',
): T | 'all' {
  const s = single(v);
  if (!s) return fallback;
  if (s === 'all') return 'all';
  if ((allowed as readonly string[]).includes(s)) return s as T;
  return fallback;
}

/* Fetch (deal-scoped, schema-correct) */

interface RawTaskRow {
  id: string;
  title: string;
  description: string | null;
  status: TaskStatus;
  priority: TaskPriority;
  due_at: string | null;
  completed_at: string | null;
  created_at: string;
  assigned_to_user_id: string | null;
  deal_id: string | null;
  deal:
    | {
        id: string;
        deal_name: string;
        pipeline: { code: string; name: string } | null;
      }
    | Array<{ id: string; deal_name: string; pipeline: { code: string; name: string } | null }>
    | null;
}

const TASK_SELECT =
  'id, title, description, status, priority, due_at, completed_at, created_at, ' +
  'assigned_to_user_id, deal_id, ' +
  'deal:deals!deal_id ( id, deal_name, pipeline:pipelines!pipeline_id ( code, name ) )';

export async function fetchTasks(
  filters: TaskFilters = DEFAULT_TASK_FILTERS,
  sort: TaskSort = DEFAULT_TASK_SORT,
  pagination: TaskPagination = { page: 1, pageSize: TASK_DEFAULT_PAGE_SIZE },
): Promise<TaskListResult> {
  const supabase = await createSupabaseServerClient();

  let query = supabase
    .schema('app')
    .from('tasks' as never)
    .select(TASK_SELECT, { count: 'exact' })
    .is('deleted_at', null);

  // filters - status/priority/overdue only (no party/engagement/module columns).
  if (filters.status === 'open') {
    query = query.in('status', OPEN_STATUSES as unknown as string[]);
  } else if (filters.status !== 'all') {
    query = query.eq('status', filters.status);
  }
  if (filters.priority !== 'all') {
    query = query.eq('priority', filters.priority);
  }
  if (filters.overdueOnly) {
    query = query
      .not('due_at', 'is', null)
      .lt('due_at', new Date().toISOString())
      .in('status', OPEN_STATUSES as unknown as string[]);
  }

  // sort
  switch (sort) {
    case 'due_soonest':
      query = query.order('due_at', { ascending: true, nullsFirst: false });
      break;
    case 'priority':
      query = query.order('priority', { ascending: false });
      query = query.order('due_at', { ascending: true, nullsFirst: false });
      break;
    case 'newest':
      query = query.order('created_at', { ascending: false });
      break;
    case 'oldest':
      query = query.order('created_at', { ascending: true });
      break;
  }
  query = query.order('id', { ascending: true });

  // pagination
  const from = (pagination.page - 1) * pagination.pageSize;
  const to = from + pagination.pageSize - 1;
  query = query.range(from, to);

  const { data, error, count } = await query;
  if (error) {
    // eslint-disable-next-line no-console
    console.error('[queries/tasks.fetchTasks] failed:', error);
    return { rows: [], totalCount: 0, filters, sort, pagination };
  }

  const rows: TaskRow[] = ((data ?? []) as unknown as RawTaskRow[]).map(toTaskRow);

  return {
    rows,
    totalCount: count ?? 0,
    filters,
    sort,
    pagination,
  };
}

function toTaskRow(r: RawTaskRow): TaskRow {
  const deal = Array.isArray(r.deal) ? r.deal[0] : r.deal;
  return {
    id: r.id,
    title: r.title,
    description: r.description,
    status: r.status,
    priority: r.priority,
    dueAt: r.due_at,
    reminderAt: null,
    partyType: null,
    partyId: null,
    partyName: null,
    partyTypeCode: null,
    engagementId: r.deal_id,
    engagementName: deal?.deal_name ?? null,
    assignedToUserId: r.assigned_to_user_id,
    createdAt: r.created_at,
    completedAt: r.completed_at,
    aiSuggested: false,
  } as unknown as TaskRow;
}

// ---------------------------------------------------------------------------
// fetchTaskById
// ---------------------------------------------------------------------------
export async function fetchTaskById(id: string): Promise<TaskRow | null> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('tasks' as never)
    .select(TASK_SELECT)
    .eq('id', id)
    .is('deleted_at', null)
    .maybeSingle();
  if (error || !data) return null;
  return toTaskRow(data as unknown as RawTaskRow);
}
