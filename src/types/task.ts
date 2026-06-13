/**
 * types/task.ts
 *
 * Data model for the task list + detail.
 */

import type { PartyTypeCode } from './ai';

/** app.task_status enum. */
export type TaskStatus =
  | 'todo'
  | 'in_progress'
  | 'blocked'
  | 'done'
  | 'cancelled';

/** app.priority_level enum. */
export type TaskPriority = 'low' | 'medium' | 'high' | 'urgent';

/** One list row (flattened). */
export interface TaskRow {
  id: string;
  title: string;
  description: string | null;
  /** Free-form notes; reused as the blocker reason on the detail page. */
  notes: string | null;
  status: TaskStatus;
  priority: TaskPriority;
  dueAt: string | null;
  reminderAt: string | null;
  /** When work started (status -> in_progress). Used by the stalled diagnostic. */
  startedAt: string | null;
  partyType: PartyTypeCode | null;
  partyId: string | null;
  partyName: string | null;
  partyTypeCode: PartyTypeCode | null;
  engagementId: string | null;
  engagementName: string | null;
  engagementPipelineCode: string | null;
  /** Owning deal id (app.tasks.deal_id, NOT NULL). Same value as engagementId today. */
  dealId: string | null;
  assignedToUserId: string | null;
  assignedToContactId: string | null;
  createdAt: string;
  completedAt: string | null;
  /** Whether this is an AI-generated task (linked_strategy_action_id != null) */
  aiSuggested: boolean;
}

export interface TaskFilters {
  status: TaskStatus | 'all' | 'open'; // 'open' = todo + in_progress + blocked
  priority: TaskPriority | 'all';
  partyType: PartyTypeCode | 'all';
  /** if true, only tasks with due_at <= now and status not done/cancelled */
  overdueOnly: boolean;
  /** a specific party */
  partyId: string | null;
}

export type TaskSort =
  | 'due_soonest'      // due_at ASC (nulls last)
  | 'priority'         // urgent > high > medium > low, ties broken by due_at ASC
  | 'newest'           // created_at DESC
  | 'oldest';          // created_at ASC

export interface TaskPagination {
  page: number;
  pageSize: number;
}

export interface TaskListResult {
  rows: TaskRow[];
  totalCount: number;
  filters: TaskFilters;
  sort: TaskSort;
  pagination: TaskPagination;
}

export const DEFAULT_TASK_FILTERS: TaskFilters = {
  status: 'open',
  priority: 'all',
  partyType: 'all',
  overdueOnly: false,
  partyId: null,
};
export const DEFAULT_TASK_SORT: TaskSort = 'due_soonest';
export const TASK_DEFAULT_PAGE_SIZE = 25;
export const TASK_PAGE_SIZE_OPTIONS: readonly number[] = [25, 50, 100] as const;
