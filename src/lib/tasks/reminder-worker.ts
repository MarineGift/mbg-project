// src/lib/tasks/reminder-worker.ts
// ============================================================
// To-do Phase 3: task reminder worker.
//
// Scans app.todo_items (via app.get_due_task_reminders) for tasks that are
// due today or overdue, not done, not archived, and not already reminded
// today. Sends:
//   - one Slack digest per organization (notifySlack), and
//   - one email per assignee (sendOutboundEmail), grouping that assignee's
//     due/overdue tasks into a single message.
// Then stamps reminded_at = today (app.mark_task_reminders_sent) so nothing
// re-fires until its next due cycle, even if the cron runs hourly.
//
// Reuses existing infra only: notifySlack, sendOutboundEmail, the admin client,
// and the CRON_SECRET-guarded route pattern (see /api/tasks/reminders).
// Never throws to the caller for a single send failure — failures are counted
// and the successfully-notified ids are still marked, so a partial outage does
// not cause an endless re-send storm.
// ============================================================

import { createSupabaseAdminClient } from '@/lib/supabase/admin';
import { notifySlack } from '@/lib/slack/notify';
import { sendOutboundEmail } from '@/lib/email/send-outbound';

interface DueReminderRow {
  task_id: string;
  organization_id: string;
  title: string;
  due_date: string;        // 'YYYY-MM-DD'
  priority: string | null;
  status: string;
  board_id: string;
  assignee_user_id: string | null;
  assignee_email: string | null;
  assignee_name: string | null;
  party_id: string | null;
  is_overdue: boolean;
}

export interface ReminderRunResult {
  scanned: number;
  orgs: number;
  slackSent: number;
  emailsSent: number;
  emailsFailed: number;
  marked: number;
}

function todayIsoDate(): string {
  const d = new Date();
  const p = (n: number) => (n < 10 ? `0${n}` : `${n}`);
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
}

const esc = (s: string) =>
  s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

function priTag(p: string | null): string {
  const key = (p ?? '').toLowerCase();
  if (key === 'urgent') return '[URGENT] ';
  if (key === 'high') return '[High] ';
  return '';
}

/** Slack digest text for one org. Overdue first, then due-today. */
function buildSlackDigest(rows: DueReminderRow[]): string {
  const overdue = rows.filter((r) => r.is_overdue);
  const dueToday = rows.filter((r) => !r.is_overdue);
  const lines: string[] = [`*Task reminders* — ${rows.length} item(s)`];
  if (overdue.length) {
    lines.push(`\n:warning: *Overdue (${overdue.length})*`);
    for (const r of overdue) {
      lines.push(`• ${priTag(r.priority)}${r.title} — due ${r.due_date}`);
    }
  }
  if (dueToday.length) {
    lines.push(`\n:date: *Due today (${dueToday.length})*`);
    for (const r of dueToday) {
      lines.push(`• ${priTag(r.priority)}${r.title}`);
    }
  }
  return lines.join('\n');
}

/** HTML email body for one assignee's tasks. */
function buildEmailHtml(name: string | null, rows: DueReminderRow[]): string {
  const overdue = rows.filter((r) => r.is_overdue);
  const dueToday = rows.filter((r) => !r.is_overdue);
  const section = (heading: string, list: DueReminderRow[]) =>
    list.length
      ? `<h3 style="margin:16px 0 6px;font-size:14px;">${esc(heading)} (${list.length})</h3>` +
        '<ul style="margin:0;padding-left:18px;">' +
        list
          .map(
            (r) =>
              `<li style="margin:2px 0;">${esc(priTag(r.priority))}${esc(r.title)}` +
              (r.is_overdue ? ` <span style="color:#b45309;">— due ${esc(r.due_date)}</span>` : '') +
              '</li>',
          )
          .join('') +
        '</ul>'
      : '';
  const greeting = name ? `Hi ${esc(name)},` : 'Hi,';
  return (
    `<div style="font-family:system-ui,Segoe UI,Arial,sans-serif;font-size:14px;color:#0f172a;">` +
    `<p>${greeting}</p>` +
    `<p>You have ${rows.length} task(s) needing attention:</p>` +
    section('Overdue', overdue) +
    section('Due today', dueToday) +
    `<p style="margin-top:16px;color:#64748b;font-size:12px;">Sent by URM task reminders.</p>` +
    `</div>`
  );
}

export async function runTaskReminders(): Promise<ReminderRunResult> {
  const supabase = createSupabaseAdminClient();
  const today = todayIsoDate();

  const result: ReminderRunResult = {
    scanned: 0, orgs: 0, slackSent: 0, emailsSent: 0, emailsFailed: 0, marked: 0,
  };

  // 1) Fetch everything due (admin client -> service_role -> RPC is granted).
  const { data, error } = await (supabase.rpc as never as (
    fn: string, args: Record<string, unknown>,
  ) => Promise<{ data: unknown; error: unknown }>)(
    'get_due_task_reminders', { p_today: today },
  );
  if (error) {
    console.error('[taskReminders] get_due_task_reminders error', error);
    return result;
  }
  const rows = ((data ?? []) as DueReminderRow[]);
  result.scanned = rows.length;
  if (!rows.length) return result;

  // 2) Group by organization for Slack; by assignee for email.
  const byOrg = new Map<string, DueReminderRow[]>();
  for (const r of rows) {
    const arr = byOrg.get(r.organization_id) ?? [];
    arr.push(r);
    byOrg.set(r.organization_id, arr);
  }
  result.orgs = byOrg.size;

  const notifiedIds: string[] = [];

  for (const [orgId, orgRows] of byOrg) {
    // 2a) One Slack digest per org (best-effort; notifySlack never throws).
    const slackOk = await notifySlack(orgId, buildSlackDigest(orgRows));
    if (slackOk) {
      result.slackSent += 1;
      // Slack covered every row in this org.
      for (const r of orgRows) notifiedIds.push(r.task_id);
    }

    // 2b) One email per assignee that has an address.
    const byAssignee = new Map<string, DueReminderRow[]>();
    for (const r of orgRows) {
      if (!r.assignee_email) continue;
      const arr = byAssignee.get(r.assignee_email) ?? [];
      arr.push(r);
      byAssignee.set(r.assignee_email, arr);
    }

    for (const [email, aRows] of byAssignee) {
      const count = aRows.length;
      const subject =
        count === 1
          ? `Task reminder: ${aRows[0]!.title}`
          : `Task reminders: ${count} tasks need attention`;
      try {
        const sendRes = await sendOutboundEmail({
          supabase,
          organizationId: orgId,
          to: email,
          // From resolves to the org's default outbound account (mailAccountId null).
          fromName: 'URM Reminders',
          fromAddress: '',
          mailAccountId: null,
          subject,
          bodyHtml: buildEmailHtml(aRows[0]!.assignee_name, aRows),
          useSignature: false,
          skipWhitelist: true, // internal reminder to a known team member
          traceLabel: 'task-reminder',
          externalData: { source: 'task_reminder', day: today },
        });
        if (sendRes.ok) {
          result.emailsSent += 1;
          // ensure these are marked even if Slack was off for this org
          for (const r of aRows) notifiedIds.push(r.task_id);
        } else {
          result.emailsFailed += 1;
        }
      } catch (e) {
        result.emailsFailed += 1;
        console.error('[taskReminders] email send failed', email, e);
      }
    }
  }

  // 3) Mark everything we successfully notified (dedupe by id).
  const uniqueIds = Array.from(new Set(notifiedIds));
  if (uniqueIds.length) {
    const { data: marked, error: markErr } = await (supabase.rpc as never as (
      fn: string, args: Record<string, unknown>,
    ) => Promise<{ data: unknown; error: unknown }>)(
      'mark_task_reminders_sent', { p_ids: uniqueIds, p_today: today },
    );
    if (markErr) {
      console.error('[taskReminders] mark_task_reminders_sent error', markErr);
    } else {
      result.marked = typeof marked === 'number' ? marked : uniqueIds.length;
    }
  }

  return result;
}
