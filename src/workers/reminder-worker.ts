// src/workers/reminder-worker.ts  (todo_v2 Phase 1 - reminder delivery)
//
// Polls processReminders() on an interval. Once per local day, at/after the
// configured send hour, emails each assignee a single Overdue+Due-Today digest
// (idempotent via app.reminder_log). Mirrors the sequence-worker pattern.
//
// Run (persistent): npx tsx --env-file=.env.local src/workers/reminder-worker.ts
// Run (once/cron):  npx tsx --env-file=.env.local src/workers/reminder-worker.ts --once
// Test (send now):  npx tsx --env-file=.env.local src/workers/reminder-worker.ts --force
// Env: NEXT_PUBLIC_SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, REMINDER_* (see process.ts).

import { processReminders } from '../lib/reminders/process'
import { createShutdownController, isMainEntry } from './runtime'

const POLL_INTERVAL_MS = 5 * 60_000 // 5 min; the day/hour gate + reminder_log keep it to one digest per user per day

export async function runReminderWorker(): Promise<void> {
  const ctl = createShutdownController('reminder-worker')
  // eslint-disable-next-line no-console
  console.log(`[reminder-worker] started (poll every ${POLL_INTERVAL_MS / 1000}s)`)
  while (!ctl.isShuttingDown()) {
    try {
      const r = await ctl.track(processReminders())
      if (r.eligible && (r.sent > 0 || r.failed > 0)) {
        // eslint-disable-next-line no-console
        console.log(`[reminder-worker] digest run: considered ${r.usersConsidered}, sent ${r.sent}, skipped ${r.skipped}, failed ${r.failed}`)
      }
    } catch (err) {
      // eslint-disable-next-line no-console
      console.error('[reminder-worker] tick error:', err instanceof Error ? err.message : err)
    }
    await ctl.sleep(POLL_INTERVAL_MS)
  }
  await ctl.waitForInflight()
  // eslint-disable-next-line no-console
  console.log('[reminder-worker] stopped')
}

if (isMainEntry(import.meta.url)) {
  const force = process.argv.includes('--force')
  const once = process.argv.includes('--once') || force
  if (once) {
    processReminders({ force })
      .then((r) => {
        // eslint-disable-next-line no-console
        console.log('[reminder-worker] once:', JSON.stringify(r))
        process.exit(0)
      })
      .catch((err) => {
        // eslint-disable-next-line no-console
        console.error('[reminder-worker] fatal:', err)
        process.exit(1)
      })
  } else {
    runReminderWorker().catch((err) => {
      // eslint-disable-next-line no-console
      console.error('[reminder-worker] fatal:', err)
      process.exit(1)
    })
  }
}
