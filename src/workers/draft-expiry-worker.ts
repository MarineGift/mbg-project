/**
 * workers/draft-expiry-worker.ts
 *
 * 만료된 ai.drafts 행의 status를 'expired'로 갱신.
 *
 * 호출 방식:
 *   - Vercel Cron (`vercel.json`의 `"schedule": "0 * * * *"`) 매시간 1회
 *   - 또는 stand-alone Node 워커: `tsx src/workers/draft-expiry-worker.ts`
 *
 * SQL 측 함수 ai.expire_stale_drafts()가 다음을 수행:
 *   - WHERE status = 'pending_review' AND expires_at < NOW() AND expired_handled = false
 *   - UPDATE status='expired', expired_handled=true
 *   - 만료된 건수를 (expired_count int, organization_id uuid) 형태로 반환
 */

import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { env } from '../lib/env';
import { isMainEntry } from './runtime';

export interface ExpireResult {
  expired: number;
  ranAt: string;
}

/**
 * 단위 테스트 가능한 핵심 로직.
 * supabase 클라이언트를 외부에서 주입.
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

  // RPC 응답 형식: RETURNS TABLE (expired_count int, organization_id uuid)
  // → 행 배열로 반환 (organization별 그룹). 모든 행의 expired_count를 합산.
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
    // 단일 행 fallback
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
