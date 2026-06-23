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
      .select('id, deal_name, next_step, next_step_date, party_id, pipeline_id')
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

  const [partyRes, taskDealRes, pipelinesRes] = await Promise.all([
    partyIds.length
      ? supabase.schema('app').from('parties' as never).select('id, name').in('id', partyIds)
      : Promise.resolve({ data: [] as unknown[] }),
    dealIds.length
      ? supabase.schema('app').from('deals' as never).select('id, deal_name, pipeline_id').in('id', dealIds)
      : Promise.resolve({ data: [] as unknown[] }),
    supabase.schema('app').from('pipelines' as never).select('id, code'),
  ])

  const partyName = new Map<string, string>()
  for (const p of (partyRes.data ?? []) as any[]) partyName.set(p.id, p.name)
  const pipelineCode = new Map<string, string>()
  for (const p of (pipelinesRes.data ?? []) as any[]) pipelineCode.set(p.id, p.code)
  const dealName = new Map<string, string>()
  const dealPipeline = new Map<string, string | null>()
  for (const d of (taskDealRes.data ?? []) as any[]) {
    dealName.set(d.id, d.deal_name)
    dealPipeline.set(d.id, d.pipeline_id ?? null)
  }
  // deal board route is /pipelines/{code}; fall back to root if code unresolved
  const cockpitDealHref = (dealId: string, pipelineId: string | null): string => {
    const code = pipelineId ? pipelineCode.get(pipelineId) : undefined
    return code ? `/pipelines/${code}?deal=${dealId}` : '/'
  }

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
      href: t.deal_id ? cockpitDealHref(t.deal_id, dealPipeline.get(t.deal_id) ?? null) : '/',
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
      href: cockpitDealHref(d.id, d.pipeline_id ?? null),
    })
  }

  // True totals BEFORE capping (the UI badge shows these).
  const counts = {
    overdue: overdue.length, thisWeek: thisWeek.length, waitingFor: waitingFor.length,
  }
  const byDueAsc  = (a: CockpitItem, b: CockpitItem) => (a.due ?? '9999').localeCompare(b.due ?? '9999')
  const byDueDesc = (a: CockpitItem, b: CockpitItem) => (b.due ?? '0000').localeCompare(a.due ?? '0000')
  overdue.sort(byDueDesc)   // freshest-overdue first; ancient stale items truncate off the bottom
  thisWeek.sort(byDueAsc)   // soonest first
  waitingFor.sort(byDueAsc)

  const LANE_LIMIT = 50
  return {
    today, weekEnd,
    overdue:    overdue.slice(0, LANE_LIMIT),
    thisWeek:   thisWeek.slice(0, LANE_LIMIT),
    waitingFor: waitingFor.slice(0, LANE_LIMIT),
    counts,
  }
}

// ───────────────────────────────────────────────────────────
// getTodayBoard() — Today as a source-typed kanban (todo_v2 Phase 1.5)
//
// Seven columns in canonical order:
//   event -> meeting -> deal_task -> communication -> todo -> next_step -> close
//
// Window:
//   - deadline sources (deal_task / todo / next_step / close): due <= weekEnd,
//     not done  (so OVERDUE items are included, sorted newest-first so the most
//     relevant stay visible and ancient stale items truncate off the bottom).
//   - time sources (event / meeting / communication): timestamp in [today, weekEnd]
//     (upcoming only; past events/meetings/logs are not "to do"), soonest first.
// Every item carries an href so the row links straight to the right place.
// Timezone: v1 buckets on the server (UTC) date, same caveat as getTodayCockpit.
// ───────────────────────────────────────────────────────────

export type BoardSource =
  | 'event' | 'meeting' | 'deal_task' | 'communication'
  | 'todo'  | 'milestone_next_step' | 'milestone_close'

export interface BoardItem {
  id:      string
  source:  BoardSource
  title:   string
  context: string | null       // party or deal name
  when:    string | null       // 'YYYY-MM-DD' for display
  overdue: boolean
  href:    string
}

export interface BoardColumn {
  source: BoardSource
  items:  BoardItem[]
  total:  number               // true total before the per-column cap
}

export interface TodayBoard {
  today:   string
  weekEnd: string
  columns: BoardColumn[]
}

const BOARD_ORDER: BoardSource[] = [
  'event', 'meeting', 'deal_task', 'communication',
  'todo', 'milestone_next_step', 'milestone_close',
]
const COLUMN_LIMIT = 50

export async function getTodayBoard(): Promise<TodayBoard> {
  await requireAuth()
  const supabase = await createSupabaseServerClient()

  const now       = new Date()
  const today     = now.toISOString().slice(0, 10)
  const weekEnd   = new Date(now.getTime() + 7 * 86_400_000).toISOString().slice(0, 10)
  const todayTs   = `${today}T00:00:00.000Z`
  const weekEndTs = `${weekEnd}T23:59:59.999Z`

  const [doneOptsRes, eventsRes, meetingsRes, tasksRes, commsRes, todosRes, dealsRes, pipelinesRes] =
    await Promise.all([
      supabase.schema('app').from('todo_status_options' as never)
        .select('board_id, key, is_done').eq('is_done', true),

      // calendar events happening today..weekEnd (exclude meeting-backed + cancelled)
      supabase.schema('app').from('calendar_events' as never)
        .select('id, title, start_at, party_id, parties ( name )')
        .is('meeting_id', null)
        .neq('status', 'cancelled')
        .gte('start_at', todayTs)
        .lte('start_at', weekEndTs)
        .order('start_at'),

      // meetings scheduled today..weekEnd
      supabase.schema('app').from('meetings' as never)
        .select('id, title, scheduled_at, party_id, parties ( name )')
        .neq('status', 'cancelled')
        .gte('scheduled_at', todayTs)
        .lte('scheduled_at', weekEndTs)
        .order('scheduled_at'),

      // deal tasks: not deleted, not completed; due_at <= weekEnd (includes overdue)
      supabase.schema('app').from('tasks' as never)
        .select('id, title, due_at, status, deal_id')
        .is('deleted_at', null)
        .is('completed_at', null)
        .not('due_at', 'is', null)
        .lte('due_at', weekEndTs),

      // communications logged today..weekEnd
      supabase.schema('app').from('communications' as never)
        .select('id, subject, occurred_at, party_id, parties ( name )')
        .is('deleted_at', null)
        .not('occurred_at', 'is', null)
        .gte('occurred_at', todayTs)
        .lte('occurred_at', weekEndTs)
        .order('occurred_at'),

      // todo_items: not archived; due_date <= weekEnd (includes overdue)
      supabase.schema('app').from('todo_items' as never)
        .select('id, title, due_date, status, board_id, party_id')
        .is('archived_at', null)
        .not('due_date', 'is', null)
        .lte('due_date', weekEnd),

      // active deals with next_step_date OR expected_close_date <= weekEnd
      supabase.schema('app').from('deals' as never)
        .select('id, deal_name, next_step, next_step_date, expected_close_date, party_id, pipeline_id')
        .eq('status', 'active')
        .is('deleted_at', null)
        .or(`next_step_date.lte.${weekEnd},expected_close_date.lte.${weekEnd}`),

      // pipelines: id -> code, to build deal board links /pipelines/{code}
      supabase.schema('app').from('pipelines' as never)
        .select('id, code'),
    ])

  // pipeline id -> code (deal board route is /pipelines/{code})
  const pipelineCode = new Map<string, string>()
  for (const p of (pipelinesRes.data ?? []) as any[]) pipelineCode.set(p.id, p.code)
  const dealHref = (dealId: string, pipelineId: string | null): string => {
    const code = pipelineId ? pipelineCode.get(pipelineId) : undefined
    return code ? `/pipelines/${code}?deal=${dealId}` : '/'
  }

  const doneKeys = new Set<string>()
  for (const o of (doneOptsRes.data ?? []) as any[]) doneKeys.add(`${o.board_id}|${o.key}`)

  const eventRows = (eventsRes.data   ?? []) as any[]
  const meetRows  = (meetingsRes.data ?? []) as any[]
  const taskRows  = (tasksRes.data    ?? []) as any[]
  const commRows  = (commsRes.data    ?? []) as any[]
  const todoRows  = (todosRes.data    ?? []) as any[]
  const dealRows  = (dealsRes.data    ?? []) as any[]

  // batch name lookups for todos (party) and deal tasks (deal)
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
      ? supabase.schema('app').from('deals' as never).select('id, deal_name, pipeline_id').in('id', dealIds)
      : Promise.resolve({ data: [] as unknown[] }),
  ])
  const partyName = new Map<string, string>()
  for (const p of (partyRes.data ?? []) as any[]) partyName.set(p.id, p.name)
  const dealName = new Map<string, string>()
  const dealPipeline = new Map<string, string | null>()
  for (const d of (taskDealRes.data ?? []) as any[]) {
    dealName.set(d.id, d.deal_name)
    dealPipeline.set(d.id, d.pipeline_id ?? null)
  }

  const buckets: Record<BoardSource, BoardItem[]> = {
    event: [], meeting: [], deal_task: [], communication: [],
    todo: [], milestone_next_step: [], milestone_close: [],
  }
  const embeddedParty = (r: any): string | null => (r.parties as any)?.name ?? null

  // events
  for (const e of eventRows) {
    buckets.event.push({
      id: e.id, source: 'event', title: e.title || '(untitled event)',
      context: embeddedParty(e),
      when: e.start_at ? String(e.start_at).slice(0, 10) : null,
      overdue: false, href: '/calendar',
    })
  }
  // meetings
  for (const m of meetRows) {
    buckets.meeting.push({
      id: m.id, source: 'meeting', title: m.title || '(untitled meeting)',
      context: embeddedParty(m),
      when: m.scheduled_at ? String(m.scheduled_at).slice(0, 10) : null,
      overdue: false, href: '/calendar',
    })
  }
  // deal tasks
  for (const t of taskRows) {
    if (t.status && TASK_DONE_STATUSES.has(t.status)) continue
    const when = t.due_at ? String(t.due_at).slice(0, 10) : null
    buckets.deal_task.push({
      id: t.id, source: 'deal_task', title: t.title,
      context: t.deal_id ? dealName.get(t.deal_id) ?? null : null,
      when, overdue: !!when && when < today,
      href: t.deal_id ? dealHref(t.deal_id, dealPipeline.get(t.deal_id) ?? null) : '/',
    })
  }
  // communications
  for (const c of commRows) {
    buckets.communication.push({
      id: c.id, source: 'communication', title: c.subject || '(no subject)',
      context: embeddedParty(c),
      when: c.occurred_at ? String(c.occurred_at).slice(0, 10) : null,
      overdue: false, href: '/inbox',
    })
  }
  // todos
  for (const t of todoRows) {
    if (doneKeys.has(`${t.board_id}|${t.status}`)) continue
    const when = t.due_date ?? null
    buckets.todo.push({
      id: t.id, source: 'todo', title: t.title,
      context: t.party_id ? partyName.get(t.party_id) ?? null : null,
      when, overdue: !!when && when < today,
      href: '/todo',
    })
  }
  // deal milestones -> next_step and/or close
  for (const d of dealRows) {
    const ctx = d.party_id ? partyName.get(d.party_id) ?? null : (d.deal_name ?? null)
    const ns = d.next_step_date as string | null
    if (ns && ns <= weekEnd) {
      buckets.milestone_next_step.push({
        id: `${d.id}:next_step`, source: 'milestone_next_step',
        title: d.next_step ? `${d.deal_name} - ${d.next_step}` : `${d.deal_name} - next step`,
        context: ctx, when: ns, overdue: ns < today,
        href: dealHref(d.id, d.pipeline_id ?? null),
      })
    }
    const cl = d.expected_close_date as string | null
    if (cl && cl <= weekEnd) {
      buckets.milestone_close.push({
        id: `${d.id}:close`, source: 'milestone_close',
        title: `${d.deal_name} - expected close`,
        context: ctx, when: cl, overdue: cl < today,
        href: dealHref(d.id, d.pipeline_id ?? null),
      })
    }
  }

  const whenAsc  = (a: BoardItem, b: BoardItem) => (a.when ?? '9999').localeCompare(b.when ?? '9999')
  const whenDesc = (a: BoardItem, b: BoardItem) => (b.when ?? '0000').localeCompare(a.when ?? '0000')
  // deadline columns: newest-first (relevant stays, ancient overdue truncates off bottom)
  buckets.deal_task.sort(whenDesc)
  buckets.todo.sort(whenDesc)
  buckets.milestone_next_step.sort(whenDesc)
  buckets.milestone_close.sort(whenDesc)
  // time columns: soonest-first
  buckets.event.sort(whenAsc)
  buckets.meeting.sort(whenAsc)
  buckets.communication.sort(whenAsc)

  const columns: BoardColumn[] = BOARD_ORDER.map((source) => ({
    source,
    total: buckets[source].length,
    items: buckets[source].slice(0, COLUMN_LIMIT),
  }))

  return { today, weekEnd, columns }
}
