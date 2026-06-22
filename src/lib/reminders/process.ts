// src/lib/reminders/process.ts  (todo_v2 Phase 1 - reminder delivery)
//
// processReminders() builds a per-assignee daily digest (Overdue + Due Today)
// over todo_items / deal tasks / deal next-step milestones, and emails ONE
// digest per user via the proven sendOutboundEmail path. Idempotent per
// (org, user, day) through app.reminder_log.
//
// Routing (multi-user): todo -> assignee_user_id, task -> assigned_to_user_id,
// milestone -> deals.owner_user_id. Recipient email from app.users.
// From account: REMINDER_FROM_ACCOUNT_ID (app.inbound_mailboxes.id) or null =
// org default. Internal mail -> skipWhitelist:true. Tagged externalData.source.
//
// Env: REMINDER_SEND_HOUR (local hour, default 8), REMINDER_TZ (default
// Asia/Seoul), REMINDER_FROM_ADDRESS, REMINDER_FROM_NAME, REMINDER_FROM_ACCOUNT_ID,
// REMINDER_APP_URL (digest links, default https://urm.marinebiogroup.com).

import { createSupabaseAdminClient } from '@/lib/supabase/admin'
import { sendOutboundEmail } from '@/lib/email/send-outbound'

const SEND_HOUR       = Number(process.env.REMINDER_SEND_HOUR ?? '8')
const TZ              = process.env.REMINDER_TZ ?? 'Asia/Seoul'
const FROM_ADDR       = process.env.REMINDER_FROM_ADDRESS ?? 'yunyoung.heo@marinebiogroup.com'
const FROM_NAME       = process.env.REMINDER_FROM_NAME ?? 'MBG URM'
const FROM_ACCOUNT_ID = process.env.REMINDER_FROM_ACCOUNT_ID || null
const APP_URL         = (process.env.REMINDER_APP_URL ?? 'https://urm.marinebiogroup.com').replace(/\/$/, '')

const TASK_DONE = new Set(['done', 'completed', 'cancelled', 'canceled'])
const KIND = 'daily_digest'

export interface ReminderRunResult {
  eligible: boolean
  localHour: number
  digestDate: string
  usersConsidered: number
  sent: number
  skipped: number
  failed: number
}

interface DueItem {
  source: 'todo' | 'deal_task' | 'milestone'
  lane: 'overdue' | 'today'
  title: string
  due: string
  context: string | null
}

function localParts(now: Date, tz: string): { hour: number; date: string } {
  const fmt = new Intl.DateTimeFormat('en-CA', {
    timeZone: tz, year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', hour12: false,
  })
  const p = Object.fromEntries(fmt.formatToParts(now).map((x) => [x.type, x.value]))
  const hour = Number(p.hour === '24' ? '0' : p.hour)
  return { hour, date: `${p.year}-${p.month}-${p.day}` }
}

function esc(s: string): string {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
}

function renderDigest(items: DueItem[], name: string | null, digestDate: string): { subject: string; html: string } {
  const overdue = items.filter((i) => i.lane === 'overdue')
  const todays  = items.filter((i) => i.lane === 'today')
  const subject = `Your day: ${overdue.length} overdue, ${todays.length} due today`
  const row = (i: DueItem) =>
    `<tr><td style="padding:4px 10px 4px 0;color:#64748b;white-space:nowrap">${esc(i.due)}</td>` +
    `<td style="padding:4px 0">${esc(i.title)}${i.context ? ` <span style="color:#94a3b8">- ${esc(i.context)}</span>` : ''}</td></tr>`
  const section = (label: string, list: DueItem[], color: string) =>
    list.length
      ? `<h3 style="margin:18px 0 6px;font-size:14px;color:${color}">${label} (${list.length})</h3>` +
        `<table style="border-collapse:collapse;font-size:13px;width:100%">${list.map(row).join('')}</table>`
      : ''
  const html =
    `<div style="font-family:system-ui,Segoe UI,Arial,sans-serif;color:#0f172a;max-width:560px">` +
    `<p style="font-size:14px">Hi ${esc(name ?? 'there')}, here is your ${esc(digestDate)} summary.</p>` +
    section('Overdue', overdue, '#dc2626') +
    section('Due today', todays, '#0f172a') +
    `<p style="margin-top:20px;font-size:13px"><a href="${APP_URL}/today" style="color:#2563eb">Open Today &rarr;</a></p>` +
    `</div>`
  return { subject, html }
}

export async function processReminders(opts?: { force?: boolean; now?: Date }): Promise<ReminderRunResult> {
  const supabase = createSupabaseAdminClient()
  const now = opts?.now ?? new Date()
  const force = !!opts?.force
  const { hour: localHour, date: today } = localParts(now, TZ)
  const eligible = force || localHour >= SEND_HOUR
  const result: ReminderRunResult = { eligible, localHour, digestDate: today, usersConsidered: 0, sent: 0, skipped: 0, failed: 0 }
  if (!eligible) return result

  const { data: doneOpts } = await supabase.schema('app').from('todo_status_options' as never)
    .select('board_id, key, is_done').eq('is_done', true)
  const doneKeys = new Set<string>()
  for (const o of (doneOpts ?? []) as any[]) doneKeys.add(`${o.board_id}|${o.key}`)

  const [todosRes, tasksRes, dealsRes] = await Promise.all([
    supabase.schema('app').from('todo_items' as never)
      .select('id, title, due_date, status, board_id, party_id, assignee_user_id, organization_id')
      .is('archived_at', null).not('assignee_user_id', 'is', null)
      .not('due_date', 'is', null).lte('due_date', today),
    supabase.schema('app').from('tasks' as never)
      .select('id, title, due_at, status, deal_id, assigned_to_user_id, organization_id')
      .is('deleted_at', null).is('completed_at', null).not('assigned_to_user_id', 'is', null)
      .not('due_at', 'is', null).lte('due_at', `${today}T23:59:59.999Z`),
    supabase.schema('app').from('deals' as never)
      .select('id, deal_name, next_step, next_step_date, owner_user_id, organization_id')
      .eq('status', 'active').is('deleted_at', null).not('owner_user_id', 'is', null)
      .not('next_step_date', 'is', null).lte('next_step_date', today),
  ])

  const todoRows = (todosRes.data ?? []) as any[]
  const taskRows = (tasksRes.data ?? []) as any[]
  const dealRows = (dealsRes.data ?? []) as any[]

  // context names
  const partyIds = Array.from(new Set(todoRows.map((r) => r.party_id).filter(Boolean))) as string[]
  const taskDealIds = Array.from(new Set(taskRows.map((r) => r.deal_id).filter(Boolean))) as string[]
  const [partyRes, taskDealRes] = await Promise.all([
    partyIds.length ? supabase.schema('app').from('parties' as never).select('id, name').in('id', partyIds) : Promise.resolve({ data: [] }),
    taskDealIds.length ? supabase.schema('app').from('deals' as never).select('id, deal_name').in('id', taskDealIds) : Promise.resolve({ data: [] }),
  ])
  const partyName = new Map<string, string>()
  for (const p of (partyRes.data ?? []) as any[]) partyName.set(p.id, p.name)
  const taskDealName = new Map<string, string>()
  for (const d of (taskDealRes.data ?? []) as any[]) taskDealName.set(d.id, d.deal_name)

  const laneOf = (due: string): 'overdue' | 'today' => (due < today ? 'overdue' : 'today')

  // group items by assignee user id
  const byUser = new Map<string, DueItem[]>()
  const add = (uid: string, item: DueItem) => {
    const arr = byUser.get(uid); if (arr) arr.push(item); else byUser.set(uid, [item])
  }

  for (const t of todoRows) {
    if (doneKeys.has(`${t.board_id}|${t.status}`)) continue
    const due = t.due_date as string
    add(t.assignee_user_id, { source: 'todo', lane: laneOf(due), title: t.title, due, context: t.party_id ? partyName.get(t.party_id) ?? null : null })
  }
  for (const t of taskRows) {
    if (t.status && TASK_DONE.has(t.status)) continue
    const due = (t.due_at as string).slice(0, 10)
    add(t.assigned_to_user_id, { source: 'deal_task', lane: laneOf(due), title: t.title, due, context: t.deal_id ? taskDealName.get(t.deal_id) ?? null : null })
  }
  for (const d of dealRows) {
    const due = d.next_step_date as string
    add(d.owner_user_id, { source: 'milestone', lane: laneOf(due), title: d.next_step ? `${d.deal_name} - ${d.next_step}` : `${d.deal_name} - next step`, due, context: d.deal_name ?? null })
  }

  const userIds = Array.from(byUser.keys())
  result.usersConsidered = userIds.length
  if (!userIds.length) return result

  const { data: userRows } = await supabase.schema('app').from('users' as never)
    .select('id, email, full_name, organization_id, is_active').in('id', userIds)
  const users = new Map<string, any>()
  for (const u of (userRows ?? []) as any[]) users.set(u.id, u)

  for (const uid of userIds) {
    const u = users.get(uid)
    const items = (byUser.get(uid) ?? []).sort((a, b) => a.due.localeCompare(b.due))
    if (!u || !u.is_active || !u.email || items.length === 0) { result.skipped++; continue }

    if (!force) {
      const { data: existing } = await supabase.schema('app').from('reminder_log' as never)
        .select('id').eq('organization_id', u.organization_id).eq('user_id', uid)
        .eq('digest_date', today).eq('kind', KIND).maybeSingle()
      if (existing) { result.skipped++; continue }
    }

    const { subject, html } = renderDigest(items, u.full_name ?? null, today)
    try {
      const r = await sendOutboundEmail({
        supabase,
        organizationId: u.organization_id,
        to: u.email,
        fromName: FROM_NAME,
        fromAddress: FROM_ADDR,
        mailAccountId: FROM_ACCOUNT_ID,
        subject,
        bodyHtml: html,
        useSignature: false,
        skipWhitelist: true,
        aiGenerated: false,
        externalData: { source: 'reminder', kind: KIND, digest_date: today, item_count: items.length },
        traceLabel: 'reminder',
      })
      if (r.ok) {
        await supabase.schema('app').from('reminder_log' as never).upsert(
          { organization_id: u.organization_id, user_id: uid, digest_date: today, kind: KIND, item_count: items.length, communication_id: r.communicationId ?? null },
          { onConflict: 'organization_id,user_id,digest_date,kind', ignoreDuplicates: true } as never,
        )
        result.sent++
      } else {
        result.failed++
      }
    } catch {
      result.failed++
    }
  }

  return result
}
