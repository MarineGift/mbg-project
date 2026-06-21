/**
 * workers/sequence-worker.ts
 *
 * Drip engine for email sequences. Polls due enrollments via
 * processSequence(null) and sends each due step (Day 0 / Day 3 / Day 7 ...) as
 * enrollments come due. WITHOUT this loop, sequences only send when someone
 * clicks "Run Now" or an external cron hits POST /api/sequences/process.
 *
 * Sending reuses processSequence -> sendOutboundEmail (the proven core) with a
 * service-role admin client (no request context needed). Restart-safe via the
 * shared shutdown controller.
 *
 * Run (persistent):  npx tsx --env-file=.env.local src/workers/sequence-worker.ts
 * Run (drain once):  npx tsx --env-file=.env.local src/workers/sequence-worker.ts --once
 *
 * Env: NEXT_PUBLIC_SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY (admin client).
 */

import { processSequence } from '../lib/utils/sequence-processor';
import { createShutdownController, isMainEntry } from './runtime';

const POLL_INTERVAL_MS = 60_000; // 1 min; sequences are day-based, so this is ample

export async function runSequenceWorker(): Promise<void> {
  const ctl = createShutdownController('sequence-worker');
  // eslint-disable-next-line no-console
  console.log(`[sequence-worker] started (poll every ${POLL_INTERVAL_MS / 1000}s)`);
  while (!ctl.isShuttingDown()) {
    try {
      const r = await ctl.track(processSequence(null));
      if (r.processed > 0) {
        // eslint-disable-next-line no-console
        console.log(
          `[sequence-worker] processed ${r.processed}: sent ${r.sent}, skipped ${r.skipped}, failed ${r.failed}`,
        );
      }
    } catch (err) {
      // eslint-disable-next-line no-console
      console.error('[sequence-worker] tick error:', err instanceof Error ? err.message : err);
    }
    await ctl.sleep(POLL_INTERVAL_MS);
  }
  await ctl.waitForInflight();
  // eslint-disable-next-line no-console
  console.log('[sequence-worker] stopped');
}

if (isMainEntry(import.meta.url)) {
  const once = process.argv.includes('--once');
  if (once) {
    processSequence(null)
      .then((r) => {
        // eslint-disable-next-line no-console
        console.log('[sequence-worker] once:', JSON.stringify(r));
        process.exit(0);
      })
      .catch((err) => {
        // eslint-disable-next-line no-console
        console.error('[sequence-worker] fatal:', err);
        process.exit(1);
      });
  } else {
    runSequenceWorker().catch((err) => {
      // eslint-disable-next-line no-console
      console.error('[sequence-worker] fatal:', err);
      process.exit(1);
    });
  }
}
