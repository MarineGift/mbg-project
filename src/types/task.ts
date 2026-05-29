/**
 * types/task.ts
 *
 * 태스크 목록 + 상세의 데이터 모델.
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

/** 목록 한 행 (평탄화). */
export interface TaskRow {
  id: string;
  title: string;
  description: string | null;
  status: TaskStatus;
  priority: TaskPriority;
  dueAt: string | null;
  reminderAt: string | null;
  partyType: PartyTypeCode | null;
  partyId: string | null;
  partyName: string | null;
  partyTypeCode: PartyTypeCode | null;
  engagementId: string | null;
  engagementName: string | null;
  assignedToUserId: string | null;
  createdAt: string;
  completedAt: string | null;
  /** AI가 생성한 태스크인지 (linked_strategy_action_id != null) */
  aiSuggested: boolean;
}

export interface TaskFilters {
  status: TaskStatus | 'all' | 'open'; // 'open' = todo + in_progress + blocked
  priority: TaskPriority | 'all';
  partyType: PartyTypeCode | 'all';
  /** true이면 due_at <= now 이면서 status가 done/cancelled 아닌 것만 */
  overdueOnly: boolean;
  /** 특정 거래처 */
  partyId: string | null;
}

export type TaskSort =
  | 'due_soonest'      // due_at ASC (null 마지막)
  | 'priority'         // urgent > high > medium > low, 같으면 due_at ASC
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
