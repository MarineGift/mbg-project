'use server';

// src/lib/tasks/actions.ts
// Server actions for the task engine (Todo + Pipeline boards share this code).
//
// Conventions (mbg-project):
//  - Gotcha #45 (CORRECTED): the shared server client does NOT default to the app
//    schema at runtime. The <Database, 'app'> generic in server.ts is TYPE-ONLY; no
//    `db: { schema: 'app' }` option is set, so the runtime default schema is `public`.
//    => Target the app schema EXPLICITLY with .schema('app').from('TABLE' as never).
//    `.schema('app')` needs no cast; 'TABLE' needs `as never` and write payloads need
//    `as never`, since database.ts is not yet regenerated.
//  - SaaS multi-tenancy: RLS scopes every query by app.current_organization_id();
//    organization_id and created_by/author_user_id are filled by column DEFAULTS
//    (current_organization_id() / auth.uid()), so writes NEVER send them. This makes
//    tenant + author un-spoofable from the client.
//  - The `app` schema must be in Settings > API > Exposed schemas (already is).

// Uses the project's existing server-side Supabase helper.
import { createSupabaseServerClient as createClient } from '@/lib/supabase/server';

import type {
  BoardData,
  TaskBoard,
  TaskItem,
  TaskStatusOption,
  TaskGroup,
  TaskUpdate,
  TaskDependency,
} from './types';

// ---------------------------------------------------------------------------
// Reads
// ---------------------------------------------------------------------------

/** All boards in the user's org (for the sidebar). */
export async function listBoards(): Promise<TaskBoard[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema('app')
    .from('todo_boards' as never)
    .select('*')
    .order('position', { ascending: true });
  if (error) throw new Error(`listBoards: ${error.message}`);
  return (data ?? []) as unknown as TaskBoard[];
}

/** Everything needed to render one board in kanban / calendar / gantt. */
export async function listBoard(boardId: string): Promise<BoardData> {
  const supabase = await createClient();

  const [boardR, statusR, groupR, itemR] = await Promise.all([
    supabase.schema('app').from('todo_boards' as never)
      .select('*').eq('id', boardId).single(),
    supabase.schema('app').from('todo_status_options' as never)
      .select('*').eq('board_id', boardId).order('position', { ascending: true }),
    supabase.schema('app').from('todo_groups' as never)
      .select('*').eq('board_id', boardId).order('position', { ascending: true }),
    supabase.schema('app').from('todo_items' as never)
      .select('*').eq('board_id', boardId).is('archived_at', null)
      .order('position', { ascending: true }),
  ]);

  if (boardR.error) throw new Error(`listBoard.board: ${boardR.error.message}`);
  if (statusR.error) throw new Error(`listBoard.status: ${statusR.error.message}`);
  if (groupR.error) throw new Error(`listBoard.groups: ${groupR.error.message}`);
  if (itemR.error) throw new Error(`listBoard.items: ${itemR.error.message}`);

  const items = (itemR.data ?? []) as unknown as TaskItem[];

  let dependencies: TaskDependency[] = [];
  const itemIds = items.map((i) => i.id);
  if (itemIds.length) {
    const depR = await supabase
      .schema('app')
      .from('todo_dependencies' as never)
      .select('*').in('item_id', itemIds);
    if (depR.error) throw new Error(`listBoard.deps: ${depR.error.message}`);
    dependencies = (depR.data ?? []) as unknown as TaskDependency[];
  }

  return {
    board: boardR.data as unknown as TaskBoard,
    statusOptions: (statusR.data ?? []) as unknown as TaskStatusOption[],
    groups: (groupR.data ?? []) as unknown as TaskGroup[],
    items,
    dependencies,
  };
}

// ---------------------------------------------------------------------------
// Writes
// ---------------------------------------------------------------------------

export interface CreateItemInput {
  boardId: string;
  title: string;
  status: string;                 // a status_options.key for this board
  description?: string | null;
  groupId?: string | null;
  priority?: string | null;
  assigneeUserId?: string | null;
  startDate?: string | null;      // 'YYYY-MM-DD'
  dueDate?: string | null;        // 'YYYY-MM-DD'
  position?: number;
  partyId?: string | null;
  contactId?: string | null;
  communicationId?: string | null;
}

export async function createItem(input: CreateItemInput): Promise<TaskItem> {
  const supabase = await createClient();
  const row = {
    board_id: input.boardId,
    group_id: input.groupId ?? null,
    title: input.title,
    description: input.description ?? null,
    status: input.status,
    priority: input.priority ?? null,
    assignee_user_id: input.assigneeUserId ?? null,
    start_date: input.startDate ?? null,
    due_date: input.dueDate ?? null,
    position: input.position ?? 0,
    party_id: input.partyId ?? null,
    contact_id: input.contactId ?? null,
    communication_id: input.communicationId ?? null,
    // organization_id + created_by come from column defaults (SaaS: un-spoofable)
  };
  const { data, error } = await supabase
    .schema('app')
    .from('todo_items' as never)
    .insert(row as never).select().single();
  if (error) throw new Error(`createItem: ${error.message}`);
  return data as unknown as TaskItem;
}

/** Drag-and-drop: move an item to a status column at a new position. */
export async function moveItem(
  itemId: string,
  status: string,
  position: number,
): Promise<void> {
  const supabase = await createClient();
  const { error } = await supabase
    .schema('app')
    .from('todo_items' as never)
    .update({ status, position } as never)
    .eq('id', itemId);
  if (error) throw new Error(`moveItem: ${error.message}`);
}

export interface UpdateItemPatch {
  title?: string;
  description?: string | null;
  status?: string;
  priority?: string | null;
  groupId?: string | null;
  assigneeUserId?: string | null;
  startDate?: string | null;
  dueDate?: string | null;
  position?: number;
  archived?: boolean;
}

export async function updateItem(itemId: string, patch: UpdateItemPatch): Promise<void> {
  const supabase = await createClient();
  const row: Record<string, unknown> = {};
  if (patch.title !== undefined) row.title = patch.title;
  if (patch.description !== undefined) row.description = patch.description;
  if (patch.status !== undefined) row.status = patch.status;
  if (patch.priority !== undefined) row.priority = patch.priority;
  if (patch.groupId !== undefined) row.group_id = patch.groupId;
  if (patch.assigneeUserId !== undefined) row.assignee_user_id = patch.assigneeUserId;
  if (patch.startDate !== undefined) row.start_date = patch.startDate;
  if (patch.dueDate !== undefined) row.due_date = patch.dueDate;
  if (patch.position !== undefined) row.position = patch.position;
  if (patch.archived !== undefined) {
    row.archived_at = patch.archived ? new Date().toISOString() : null;
  }
  if (Object.keys(row).length === 0) return;

  const { error } = await supabase
    .schema('app')
    .from('todo_items' as never)
    .update(row as never)
    .eq('id', itemId);
  if (error) throw new Error(`updateItem: ${error.message}`);
}

export async function deleteItem(itemId: string): Promise<void> {
  const supabase = await createClient();
  const { error } = await supabase
    .schema('app')
    .from('todo_items' as never)
    .delete()
    .eq('id', itemId);
  if (error) throw new Error(`deleteItem: ${error.message}`);
}

/** Activity log / comment on an item (Monday "Updates"). */
export async function addUpdate(
  itemId: string,
  body: string,
  kind: string = 'comment',
): Promise<TaskUpdate> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema('app')
    .from('todo_updates' as never)
    .insert({ item_id: itemId, body, kind } as never)
    .select().single();
  if (error) throw new Error(`addUpdate: ${error.message}`);
  return data as unknown as TaskUpdate;
}

// ---------------------------------------------------------------------------
// Quick-add helpers (Phase 1: natural-language capture)
// ---------------------------------------------------------------------------

/**
 * Resolve an @mention captured by the quick-add parser to a party.
 * Match order: exact name (case-insensitive) -> prefix -> first substring hit.
 * RLS scopes the lookup to the caller's org. Returns null when nothing matches.
 */
export async function resolvePartyIdByName(
  q: string,
): Promise<{ id: string; name: string } | null> {
  const query = q.trim();
  if (!query) return null;
  const supabase = await createClient();
  const esc = query.replace(/[%_]/g, (c) => `\\${c}`);
  const { data, error } = await supabase
    .schema('app')
    .from('parties' as never)
    .select('id,name')
    .ilike('name', `%${esc}%`)
    .limit(10);
  if (error) throw new Error(`resolvePartyIdByName: ${error.message}`);
  const rows = (data ?? []) as unknown as Array<{ id: string; name: string }>;
  if (!rows.length) return null;
  const lower = query.toLowerCase();
  return (
    rows.find((r) => r.name.toLowerCase() === lower) ??
    rows.find((r) => r.name.toLowerCase().startsWith(lower)) ??
    rows[0] ??
    null
  );
}
