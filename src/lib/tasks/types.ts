// src/lib/tasks/types.ts
// Hand-written domain types for the task engine.
// Once `supabase gen types --schema app` is run, these can be replaced by /
// aligned with the generated Database['app'] types.

export type TaskPriority = 'low' | 'med' | 'high' | 'urgent';

export interface TaskBoard {
  id: string;
  organization_id: string;
  name: string;
  kind: string; // 'todo' | 'pipeline' (free label)
  description: string | null;
  position: number;
  created_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface TaskStatusOption {
  id: string;
  organization_id: string;
  board_id: string;
  key: string;     // stable machine key, matches TaskItem.status
  label: string;
  color: string | null;
  position: number;
  is_done: boolean;
}

export interface TaskGroup {
  id: string;
  organization_id: string;
  board_id: string;
  name: string;
  color: string | null;
  position: number;
}

export interface TaskItem {
  id: string;
  organization_id: string;
  board_id: string;
  group_id: string | null;
  parent_item_id: string | null;
  title: string;
  description: string | null;
  status: string;               // = TaskStatusOption.key for this board
  priority: TaskPriority | null;
  assignee_user_id: string | null;
  start_date: string | null;    // 'YYYY-MM-DD'
  due_date: string | null;      // 'YYYY-MM-DD'
  position: number;
  party_id: string | null;
  contact_id: string | null;
  communication_id: string | null;
  custom: Record<string, unknown>;
  archived_at: string | null;
  created_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface TaskUpdate {
  id: string;
  organization_id: string;
  item_id: string;
  author_user_id: string | null;
  kind: string; // 'comment' | 'status_change' | 'system'
  body: string | null;
  meta: Record<string, unknown>;
  created_at: string;
}

export interface TaskDependency {
  id: string;
  organization_id: string;
  item_id: string;
  depends_on_item_id: string;
  type: string; // 'finish_to_start' | ...
}

/** Everything needed to render one board in any view (kanban / calendar / gantt). */
export interface BoardData {
  board: TaskBoard;
  statusOptions: TaskStatusOption[];
  groups: TaskGroup[];
  items: TaskItem[];
  dependencies: TaskDependency[];
}
