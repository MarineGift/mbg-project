import { NextResponse, type NextRequest } from 'next/server';
import { getAdminSupabase } from '@/lib/supabase/admin';
import { verifyCronAuth } from '@/lib/cron-auth';
import { processInbound } from '@/lib/email/processor';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const BATCH_SIZE = 5;
const PER_INVOCATION_BUDGET_MS = 50_000; // Vercel maxDuration 60s 안전 마진

/**
 * Vercel Cron (2분 주기) — pg LISTEN 대신 폴링 기반으로 inbound 처리.
 *
 * communications WHERE direction='inbound' AND ai_processing_status='pending'
 * 인 행을 organization_id별로 BATCH_SIZE개까지 가져와 processor.processInbound()를 차례로 실행.
 *
 * 영구 연결이 가능한 환경에서는 본 라우트 대신 src/workers/consultation-worker.ts 패턴으로
 * 전용 호스트(Railway/Fly.io)에서 LISTEN/NOTIFY 기반으로 돌리는 것이 효율적.
 */
export async function GET(request: NextRequest): Promise<NextResponse> {
  const authError = verifyCronAuth(request);
  if (authError) {
    return NextResponse.json({ error: authError }, { status: 401 });
  }

  const supa = getAdminSupabase();
  const startedAt = Date.now();
  const summary = {
    picked: 0,
    processed: 0,
    failed: 0,
    skipped: 0,
    errors: [] as Array<{ communication_id: string; message: string }>,
  };

  // 조직별로 묶지 않고 단일 배치 (organization_id는 행마다 명시되어 있음)
  const { data: rows, error } = await supa
    .schema('app')
    .from('communications')
    .select('id, organization_id')
    .eq('direction', 'inbound')
    .eq('ai_processing_status', 'pending')
    .is('deleted_at', null)
    .order('received_at', { ascending: true })
    .limit(BATCH_SIZE);

  if (error) {
    return NextResponse.json(
      { error: 'pick_failed', detail: error.message },
      { status: 500 },
    );
  }

  const candidates = (rows ?? []) as Array<{ id: string; organization_id: string }>;
  summary.picked = candidates.length;

  for (const row of candidates) {
    if (Date.now() - startedAt > PER_INVOCATION_BUDGET_MS) {
      summary.skipped += candidates.length - summary.processed - summary.failed;
      break;
    }
    try {
      const result = await processInbound(supa, row.organization_id, row.id);
      if (result.status === 'processed') summary.processed += 1;
      else if (result.status === 'failed') {
        summary.failed += 1;
        summary.errors.push({
          communication_id: row.id,
          message: result.reason ?? 'unknown',
        });
      } else {
        summary.skipped += 1;
      }
    } catch (err) {
      summary.failed += 1;
      summary.errors.push({
        communication_id: row.id,
        message: (err as Error).message,
      });
    }
  }

  return NextResponse.json({
    ok: true,
    elapsed_ms: Date.now() - startedAt,
    ...summary,
  });
}
