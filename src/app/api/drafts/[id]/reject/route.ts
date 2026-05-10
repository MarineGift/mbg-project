import { NextResponse, type NextRequest } from 'next/server';
import { getUserAndOrg } from '@/lib/supabase/server';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

/**
 * POST /api/drafts/[id]/reject
 *
 * 인증된 사용자가 AI 드래프트를 거절. ai.drafts.status='rejected' + rejected_at + rejected_by.
 *
 * 본문 (선택):
 *   { "reason": "거절 사유" }
 */
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
): Promise<NextResponse> {
  const { id } = await params;

  let auth;
  try {
    auth = await getUserAndOrg();
  } catch (err) {
    return NextResponse.json(
      { error: 'unauthorized', detail: (err as Error).message },
      { status: 401 },
    );
  }

  let reason: string | null = null;
  try {
    const body = await request.json();
    if (body && typeof body === 'object' && typeof (body as { reason?: unknown }).reason === 'string') {
      reason = (body as { reason: string }).reason;
    }
  } catch {
    // 빈 본문 허용
  }

  const { data, error } = await auth.supabase
    .schema('ai')
    .from('drafts')
    .update({
      status: 'rejected',
      rejected_at: new Date().toISOString(),
      rejected_by: auth.userId,
      rejected_reason: reason,
    })
    .eq('organization_id', auth.organizationId)
    .eq('id', id)
    .eq('status', 'pending')  // 이미 'sent'/'rejected'인 경우 변경 불가 (멱등 방어)
    .select('id, status')
    .maybeSingle();

  if (error) {
    return NextResponse.json(
      { error: 'update_failed', detail: error.message },
      { status: 500 },
    );
  }
  if (!data) {
    return NextResponse.json(
      { error: 'not_found_or_not_pending', draft_id: id },
      { status: 404 },
    );
  }

  return NextResponse.json({ ok: true, draft_id: id, status: 'rejected' });
}
