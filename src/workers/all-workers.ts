/**
 * workers/all-workers.ts
 *
 * Runs BOTH workers in a single process so one worker-service start command
 * covers everything:
 *   - mailcarrier  (inbound IMAP -> communications/engagements)
 *   - mailrun      (bulk mailing queue: app.mail_runs / mail_run_recipients)
 *
 * Worker service start command:
 *   npm run worker:all
 *   (= tsx --env-file=.env.local src/workers/all-workers.ts)
 *
 * Both loops install their own graceful-shutdown handler and exit on SIGTERM/
 * SIGINT. allSettled is used so one worker failing does not abort the other's
 * shutdown/cleanup.
 */

import { runMailCarrierWorker } from './mailcarrier-worker';
import { runMailRunWorker } from './mailrun-worker';
import { runSequenceWorker } from './sequence-worker';
import { runReminderWorker } from './reminder-worker';
import { isMainEntry } from './runtime';

async function main(): Promise<void> {
  // eslint-disable-next-line no-console
  console.log('[all-workers] starting: mailcarrier + mailrun + sequence + reminder');
  const results = await Promise.allSettled([runMailCarrierWorker(), runMailRunWorker(), runSequenceWorker(), runReminderWorker()]);
  results.forEach((r, i) => {
    const name = i === 0 ? 'mailcarrier' : i === 1 ? 'mailrun' : i === 2 ? 'sequence' : 'reminder';
    if (r.status === 'rejected') {
      // eslint-disable-next-line no-console
      console.error(`[all-workers] ${name} exited with error:`, r.reason);
    }
  });
  // eslint-disable-next-line no-console
  console.log('[all-workers] all workers stopped');
}

if (isMainEntry(import.meta.url)) {
  main().catch((err) => {
    // eslint-disable-next-line no-console
    console.error('[all-workers] fatal:', err);
    process.exit(1);
  });
}
