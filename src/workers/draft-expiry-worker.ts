/**
 * workers/draft-expiry-worker.ts
 *
 * Set the status of expired ai.drafts rows to 'expired'.
 *
 * Invocation:
 *   - Vercel Cron (`"schedule": "0 * * * *"` in `vercel.json`) once per hour
 *   - or a stand-alone Node worker: `tsx src/workers/draft-expiry-worker.ts`
 *
 * The SQL-side function ai.expire_stale_drafts() does the following:
 *   - WHERE status = 'pending_review' AND expires_at < NOW() AND expired_handled = false
 *   - UPDATE status='expired', expired_handled=true
 *   - returns the expired count as (expired_count int, organization_id uuid)
 */

import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { env } from '../lib/env';
import { isMainEntry } from './runtime';

export interface ExpireResult {
  expired: number;
  ranAt: string;
}

/**
 * Unit-testable core logic.
 * The supabase client is injected externally.
 */
export async function expireStaleDrafts(
  supabase: SupabaseClient,
): Promise<ExpireResult> {
  const ranAt = new Date().toISOString();

  const { data, error } = await supabase
    .schema('ai')
    .rpc('expire_stale_drafts');

  if (error) {
    // eslint-disable-next-line no-console
    console.error('[draft-expiry-worker] rpc failed:', error);
    throw new Error(`expire_stale_drafts RPC failed: ${error.message}`);
  }

  // RPC response shape: RETURNS TABLE (expired_count int, organization_id uuid)
  // -> returned as an array of rows (grouped by organization). Sum expired_count across all rows.
  let expired = 0;
  if (Array.isArray(data)) {
    expired = data.reduce(
      (sum: number, row: unknown) => {
        if (row && typeof row === 'object') {
          const n = (row as { expired_count?: unknown }).expired_count;
          if (typeof n === 'number') return sum + n;
        }
        return sum;
      },
      0,
    );
  } else if (data && typeof data === 'object') {
    // single-row fallback
    const n = (data as { expired_count?: unknown }).expired_count;
    if (typeof n === 'number') expired = n;
  } else if (typeof data === 'number') {
    // scalar fallback
    expired = data;
  }

  // eslint-disable-next-line no-console
  console.log(
    `[draft-expiry-worker] expired ${expired} drafts at ${ranAt}`,
  );

  return { expired, ranAt };
}

async function main(): Promise<void> {
  const supabase = createClient(
    env.NEXT_PUBLIC_SUPABASE_URL,
    env.SUPABASE_SERVICE_ROLE_KEY,
  );
  await expireStaleDrafts(supabase);
}

if (isMainEntry(import.meta.url)) {
  main()
    .then(() => process.exit(0))
    .catch((err) => {
      // eslint-disable-next-line no-console
      console.error('[draft-expiry-worker] fatal:', err);
      process.exit(1);
    });
}
