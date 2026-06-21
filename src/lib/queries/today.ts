// src/lib/queries/today.ts  (todo_v2 Phase 1 - Today cockpit aggregation)
//
// getTodayCockpit() is a dedicated read-model for the /today cockpit. It is NOT
// the calendar feed: it includes status='blocked' items that may have no due date
// (so they never appear in the date-ranged getCalendarFeed), and it applies
// done/blocked semantics that the calendar feed does not carry.
//
// Three lanes:
//   overdue    : actionable, not done, not blocked, due < today
//   thisWeek   : actionable, not done, not blocked, today <= due <= today+7
//   waitingFor : status = 'blocked', not done (regardless of due date)
//
// Sources: app.todo_items (due_date) + app.tasks (deal tasks, due_at) +
//          app.deals.next_step_date (open/'active' deals; next-step milestones).
// "done": todo -> status key whose todo_status_options.is_done = true;
//          task -> completed_at not null (also excludes status done/cancelled).
// Timezone: v1 buckets on the server (UTC) calendar date. Boundary items can be
// off by a few hours; a user tz can be injected later.

import { createSupabaseServerClient } from '@/lib/supabase/server'
import { requireAuth } from '@/lib/auth'

export type CockpitSource = 'todo' | 'deal_task' | 'milestone'
export type CockpitLane = 'overdue' | 'thisWeek' | 'waitingFor'

export interface CockpitItem {
  id:        string
  source:    CockpitSource
  lane:      CockpitLane
  title:     string
  due:       string | null      // 'YYYY-MM-DD' (null only for waitingFor w/o date)
  status:    string | null
  priority:  string | null
  context:   string | null      // party name (todo/milestone) or deal name (task)
  board_id:  string | null
  deal_id:   string | null
  href:      string
}

export interface TodayCockpit {
  today:      string
  weekEnd:    string
  overdue:    CockpitItem[]
  thisWeek:   CockpitItem[]
  waitingFor: CockpitItem[]
  counts:     { overdue: number; thisWeek: number; waitingFor: number }
}

const BLOCKED = 'blocked'
const TASK_DONE_STATUSES = new Set(['done', 'completed', 'cancelled', 'canceled'])

export async function getTodayCockpit(): Promise<TodayCockpit> {
  await requireAuth()
  const supabase = await createSupabaseServerClient()

  const now      = new Date()
  const today    = now.toISOString().slice(0, 10)
  const weekEnd  = new Date(now.getTime() + 7 * 86_400_000).toISOString().slice(0, 10)
  const weekEndTs = `${weekEnd}T23:59:59.999Z`

  const [doneOptsRes, todosRes, tasksRes, dealsRes] = await Promise.all([
    // done status keys per board
    supabase.schema('app').from('todo_status_options' as never)
      .select('board_id, key, is_done')
      .eq('is_done', true),

    // todo_items: dated (<= weekEnd) OR blocked, not archived
    supabase.schema('app').from('todo_items' as never)
      .select('id, title, due_date, status, priority, board_id, party_id')
      .is('archived_at', null)
      .or(`due_date.lte.${weekEnd},status.eq.${BLOCKED}`),

    // deal tasks: not deleted, not completed; dated (<= weekEnd) OR blocked
    supabase.schema('app').from('tasks' as never)
      .select('id, title, due_at, status, priority, deal_id')
      .is('deleted_at', null)
      .is('completed_at', null)
      .or(`due_at.lte.${weekEndTs},status.eq.${BLOCKED}`),

    // next-step milestones: active deals with a next_step_date <= weekEnd
    supabase.schema('app').from('deals' as never)
      .select('id, deal_name, next_step, next_step_date, party_id')
      .eq('status', 'active')
      .is('deleted_at', null)
      .not('next_step_date', 'is', null)
      .lte('next_step_date', weekEnd),
  ])

  const doneKeys = new Set<string>()
  for (const o of (doneOptsRes.data ?? []) as any[]) doneKeys.add(`${o.board_id}|${o.key}`)

  const todoRows = (todosRes.data ?? []) as any[]
  const taskRows = (tasksRes.data ?? []) as any[]
  const dealRows = (dealsRes.data ?? []) as any[]

  // batched name lookups
  const partyIds = Array.from(new Set(
    [...todoRows, ...dealRows].map((r) => r.party_id as string | null)
      .filter((x): x is string => !!x),
  ))
  const dealIds = Array.from(new Set(
    taskRows.map((r) => r.deal_id as string | null).filter((x): x is string => !!x),
  ))

  const [partyRes, taskDealRes] = await Promise.all([
    partyIds.length
      ? supabase.schema('app').from('parties' as never).select('id, name').in('id', partyIds)
      : Promise.resolve({ data: [] as unknown[] }),
    dealIds.length
      ? supabase.schema('app').from('deals' as never).select('id, deal_name').in('id', dealIds)
      : Promise.resolve({ data: [] as unknown[] }),
  ])

  const partyName = new Map<string, string>()
  for (const p of (partyRes.data ?? []) as any[]) partyName.set(p.id, p.name)
  const dealName = new Map<string, string>()
  for (const d of (taskDealRes.data ?? []) as any[]) dealName.set(d.id, d.deal_name)

  const overdue: CockpitItem[] = []
  const thisWeek: CockpitItem[] = []
  const waitingFor: CockpitItem[] = []

  const place = (due: string | null, isBlocked: boolean): CockpitLane | null => {
    if (isBlocked) return 'waitingFor'
    if (!due) return null
    if (due < today) return 'overdue'
    if (due <= weekEnd) return 'thisWeek'
    return null
  }
  const pushTo = (lane: CockpitLane, item: CockpitItem) => {
    if (lane === 'overdue') overdue.push(item)
    else if (lane === 'thisWeek') thisWeek.push(item)
    else waitingFor.push(item)
  }

  // todo_items
  for (const t of todoRows) {
    const isDone = doneKeys.has(`${t.board_id}|${t.status}`)
    if (isDone) continue
    const isBlocked = t.status === BLOCKED
    const lane = place(t.due_date ?? null, isBlocked)
    if (!lane) continue
    pushTo(lane, {
      id: t.id, source: 'todo', lane,
      title: t.title,
      due: t.due_date ?? null,
      status: t.status ?? null,
      priority: t.priority ?? null,
      context: t.party_id ? partyName.get(t.party_id) ?? null : null,
      board_id: t.board_id ?? null,
      deal_id: null,
      href: '/todo',
    })
  }

  // deal tasks
  for (const t of taskRows) {
    if (t.status && TASK_DONE_STATUSES.has(t.status)) continue
    const isBlocked = t.status === BLOCKED
    const due = t.due_at ? (t.due_at as string).slice(0, 10) : null
    const lane = place(due, isBlocked)
    if (!lane) continue
    pushTo(lane, {
      id: t.id, source: 'deal_task', lane,
      title: t.title,
      due,
      status: t.status ?? null,
      priority: t.priority ?? null,
      context: t.deal_id ? dealName.get(t.deal_id) ?? null : null,
      board_id: null,
      deal_id: t.deal_id ?? null,
      href: t.deal_id ? `/pipelines?deal=${t.deal_id}` : '/pipelines',
    })
  }

  // next-step milestones (overdue / thisWeek only)
  for (const d of dealRows) {
    const due = d.next_step_date as string
    const lane = place(due, false)
    if (!lane) continue
    pushTo(lane, {
      id: `${d.id}:next_step`, source: 'milestone', lane,
      title: d.next_step ? `${d.deal_name} - ${d.next_step}` : `${d.deal_name} - next step`,
      due,
      status: null,
      priority: null,
      context: d.party_id ? partyName.get(d.party_id) ?? null : (d.deal_name ?? null),
      board_id: null,
      deal_id: d.id,
      href: `/pipelines?deal=${d.id}`,
    })
  }

  const byDue = (a: CockpitItem, b: CockpitItem) =>
    (a.due ?? '9999').localeCompare(b.due ?? '9999')
  overdue.sort(byDue)
  thisWeek.sort(byDue)
  waitingFor.sort(byDue)

  return {
    today, weekEnd, overdue, thisWeek, waitingFor,
    counts: { overdue: overdue.length, thisWeek: thisWeek.length, waitingFor: waitingFor.length },
  }
}
