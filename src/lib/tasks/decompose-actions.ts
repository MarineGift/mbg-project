'use server';

// src/lib/tasks/decompose-actions.ts
// ============================================================
// To-do Phase 4: AI task decomposition.
//
// decomposeTask(goalItemId): takes an existing todo_items row as the "goal",
// asks the `task_decomposer` agent (via the existing ClaudeClient — inherits
// budget checks, cost logging in ai.runs, model routing) to break it into
// 3-8 concrete subtasks, then inserts each as a child (parent_item_id = goal)
// on the same board / first not-done status.
//
// Reuses:
//   - requireAuth()  -> organizationId + session
//   - ClaudeClient   -> the same path email reply-drafting uses
//   - createItem()   -> subtask insert (parent_item_id wiring added in the
//                       accompanying patch)
//
// The agent returns STRICT JSON: {"subtasks":[{title, priority?, due_offset_days?}]}
// We validate defensively — a malformed model reply yields an error, never a
// partial/garbage insert.
// ============================================================

import { requireAuth } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { ClaudeClient } from '@/lib/ai/claude-client';
import { createItem } from '@/lib/tasks/actions';
import type { TaskItem } from '@/lib/tasks/types';

interface DecomposedSubtask {
  title: string;
  priority?: string | null;
  due_offset_days?: number | null;
}

const VALID_PRIORITIES = new Set(['urgent', 'high', 'med', 'low']);

export interface DecomposeResult {
  ok: boolean;
  created: TaskItem[];
  errorMessage?: string;
}

function isoDatePlusDays(base: Date, days: number): string {
  const d = new Date(base.getFullYear(), base.getMonth(), base.getDate());
  d.setDate(d.getDate() + days);
  const p = (n: number) => (n < 10 ? `0${n}` : `${n}`);
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
}

/** Coerce the model's JSON into a clean, bounded subtask list. */
function parseSubtasks(raw: unknown): DecomposedSubtask[] {
  const root =
    raw && typeof raw === 'object' && 'subtasks' in (raw as Record<string, unknown>)
      ? (raw as { subtasks: unknown }).subtasks
      : raw;
  if (!Array.isArray(root)) return [];
  const out: DecomposedSubtask[] = [];
  for (const item of root) {
    if (!item || typeof item !== 'object') continue;
    const rec = item as Record<string, unknown>;
    const title = typeof rec.title === 'string' ? rec.title.trim() : '';
    if (!title) continue;
    const priority =
      typeof rec.priority === 'string' && VALID_PRIORITIES.has(rec.priority)
        ? rec.priority
        : null;
    const offsetRaw = rec.due_offset_days;
    const due_offset_days =
      typeof offsetRaw === 'number' && Number.isFinite(offsetRaw) && offsetRaw >= 0
        ? Math.floor(offsetRaw)
        : null;
    out.push({ title, priority, due_offset_days });
    if (out.length >= 12) break; // hard cap
  }
  return out;
}

/**
 * Decompose an existing task (the "goal") into subtasks via the AI agent.
 * The goal task is loaded to inherit board_id and to build the prompt input.
 */
export async function decomposeTask(goalItemId: string): Promise<DecomposeResult> {
  let auth;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, created: [], errorMessage: 'Not authenticated' };
  }

  const supabase = await createSupabaseServerClient();

  // 1) Load the goal task (RLS scopes to the caller's org).
  const { data: goalRow, error: goalErr } = await supabase
    .schema('app')
    .from('todo_items' as never)
    .select('id, board_id, title, description, party_id')
    .eq('id', goalItemId)
    .single();

  if (goalErr || !goalRow) {
    return { ok: false, created: [], errorMessage: 'Goal task not found' };
  }
  const goal = goalRow as unknown as {
    id: string; board_id: string; title: string;
    description: string | null; party_id: string | null;
  };

  // 2) Resolve the board's first not-done status (where subtasks land).
  const { data: statusRows, error: statusErr } = await supabase
    .schema('app')
    .from('todo_status_options' as never)
    .select('key, is_done, position')
    .eq('board_id', goal.board_id)
    .order('position', { ascending: true });

  if (statusErr) {
    return { ok: false, created: [], errorMessage: 'Board status lookup failed' };
  }
  const firstOpen = (statusRows as unknown as Array<{ key: string; is_done: boolean }>)
    .find((s) => !s.is_done);
  if (!firstOpen) {
    return { ok: false, created: [], errorMessage: 'Board has no open status' };
  }

  // 3) Ask the decomposer agent (existing ClaudeClient path).
  const goalText = goal.description
    ? `${goal.title}\n\n${goal.description}`
    : goal.title;

  let parsed: unknown;
  try {
    const client = new ClaudeClient(supabase, auth.organizationId);
    const out = await client.complete({
      agentRole: 'task_decomposer',
      inboundMessage: goalText,
      outputFormat: 'json',
      partyId: goal.party_id ?? undefined,
      traceLabel: 'task-decompose',
    });
    parsed = out.parsedJson ?? out.content;
    // If JSON parsing failed upstream, content is a string — try once here.
    if (typeof parsed === 'string') {
      try {
        parsed = JSON.parse(parsed.replace(/```json|```/g, '').trim());
      } catch {
        return { ok: false, created: [], errorMessage: 'AI returned unparseable output' };
      }
    }
  } catch (e) {
    return {
      ok: false,
      created: [],
      errorMessage: e instanceof Error ? e.message : 'AI call failed',
    };
  }

  const subtasks = parseSubtasks(parsed);
  if (!subtasks.length) {
    return { ok: false, created: [], errorMessage: 'No subtasks were generated' };
  }

  // 4) Insert each as a child of the goal, preserving order via position.
  const today = new Date();
  const created: TaskItem[] = [];
  for (let i = 0; i < subtasks.length; i += 1) {
    const s = subtasks[i]!;
    try {
      const item = await createItem({
        boardId: goal.board_id,
        title: s.title,
        status: firstOpen.key,
        priority: s.priority ?? null,
        dueDate: s.due_offset_days != null ? isoDatePlusDays(today, s.due_offset_days) : null,
        parentItemId: goal.id,
        partyId: goal.party_id ?? null,
        position: (i + 1) * 1000,
      });
      created.push(item);
    } catch (e) {
      console.error('[decomposeTask] subtask insert failed', s.title, e);
    }
  }

  if (!created.length) {
    return { ok: false, created: [], errorMessage: 'Subtasks generated but none could be saved' };
  }
  return { ok: true, created };
}
