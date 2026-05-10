import { NextResponse, type NextRequest } from 'next/server';
import { getUserAndOrg } from '@/lib/supabase/server';
import { sendDraft, DraftSendError, type SendDraftOverrides } from '@/lib/email/draft-sender';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

/**
 * POST /api/drafts/[id]/approve
 *
 * 인증된 사용자가 AI 드래프트를 승인 → outbound communication 생성 + TABS Mailer로 발송.
 *
 * 본문 (선택):
 *   {
 *     "subject": "override 제목",
 *     "body_plain": "...",
 *     "body_html": "..."
 *   }
 *
 * 응답:
 *   200 { ok: true, outbound_communication_id, message_id, mocked }
 *   400 { error }
 *   401 / 403 (미들웨어가 처리)
 *   500 { error, detail }
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

  let overrides: SendDraftOverrides = {};
  if (request.headers.get('content-length') !== '0') {
    try {
      const body = await request.json();
      const b = body as Record<string, unknown>;
      if (typeof b.subject === 'string') overrides.subject = b.subject;
      if (typeof b.body_plain === 'string') overrides.bodyPlain = b.body_plain;
      if (typeof b.body_html === 'string') overrides.bodyHtml = b.body_html;
    } catch {
      // 빈 본문 허용
    }
  }

  try {
    const result = await sendDraft(
      auth.supabase,
      auth.organizationId,
      id,
      auth.userId,
      overrides,
    );
    return NextResponse.json({
      ok: true,
      outbound_communication_id: result.outboundCommunicationId,
      message_id: result.messageId,
      mocked: result.mocked,
    });
  } catch (err) {
    if (err instanceof DraftSendError) {
      return NextResponse.json(
        { error: 'send_failed', detail: err.message },
        { status: 400 },
      );
    }
    return NextResponse.json(
      { error: 'internal_error', detail: (err as Error).message },
      { status: 500 },
    );
  }
}
