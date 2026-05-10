import { NextResponse, type NextRequest } from 'next/server';
import { getAdminSupabase } from '@/lib/supabase/admin';
import { verifyCronAuth } from '@/lib/cron-auth';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

/**
 * Vercel Cron — 매일 새벽 3시.
 * ai.expire_stale_drafts() RPC를 호출해 expires_at < NOW()인 pending 드래프트들을
 * status='expired'로 일괄 변경.
 */
export async function GET(request: NextRequest): Promise<NextResponse> {
  const authError = verifyCronAuth(request);
  if (authError) {
    return NextResponse.json({ error: authError }, { status: 401 });
  }

  const supa = getAdminSupabase();
  const startedAt = Date.now();

  const { data, error } = await supa.schema('ai').rpc('expire_stale_drafts');

  const elapsedMs = Date.now() - startedAt;

  if (error) {
    return NextResponse.json(
      {
        error: 'rpc_failed',
        detail: error.message,
        elapsed_ms: elapsedMs,
      },
      { status: 500 },
    );
  }

  // RPC 반환 형태가 환경에 따라 number / array / object일 수 있어 모두 수용
  let expiredCount = 0;
  if (typeof data === 'number') {
    expiredCount = data;
  } else if (Array.isArray(data) && data.length > 0) {
    const first = data[0];
    if (typeof first === 'number') expiredCount = first;
    else if (first && typeof first === 'object' && 'count' in first) {
      expiredCount = Number((first as { count: unknown }).count) || 0;
    }
  } else if (data && typeof data === 'object' && 'count' in data) {
    expiredCount = Number((data as { count: unknown }).count) || 0;
  }

  return NextResponse.json({
    ok: true,
    expired_count: expiredCount,
    elapsed_ms: elapsedMs,
  });
}
