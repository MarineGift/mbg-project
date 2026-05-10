import { NextResponse, type NextRequest } from 'next/server';
import { simpleParser } from 'mailparser';
import { getAdminSupabase } from '@/lib/supabase/admin';
import { persistInbound, MailCarrierError } from '@/lib/email/mailcarrier';
import { env } from '@/lib/env';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

/**
 * POST /api/webhooks/inbound
 *
 * 외부 메일 제공사(Postmark/Mailgun/SendGrid) 또는 자체 MailCarrier→웹훅 브리지에서 호출.
 *
 * 헤더:
 *   X-URM-Webhook-Secret: 환경변수 INBOUND_WEBHOOK_SECRET와 일치해야 함
 *
 * 본문 (JSON):
 *   {
 *     "raw_eml_base64": "<base64 RFC 822 message>",
 *     "organization_id": "<org uuid>"
 *   }
 *
 * 응답:
 *   200 { ok: true, communication_id: "...", duplicate: false }
 *   200 { ok: true, duplicate: true }  // 이미 존재하는 message-id
 *   401 { error: "invalid_signature" }
 *   400 { error: "..." }
 */
export async function POST(request: NextRequest): Promise<NextResponse> {
  // 1. Secret 검증
  if (!env.INBOUND_WEBHOOK_SECRET) {
    return NextResponse.json(
      { error: 'webhook_not_configured', detail: 'INBOUND_WEBHOOK_SECRET is unset' },
      { status: 503 },
    );
  }
  const provided = request.headers.get('x-urm-webhook-secret');
  if (!provided || provided !== env.INBOUND_WEBHOOK_SECRET) {
    return NextResponse.json({ error: 'invalid_signature' }, { status: 401 });
  }

  // 2. 본문 파싱
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: 'invalid_json' }, { status: 400 });
  }
  const b = body as { raw_eml_base64?: unknown; organization_id?: unknown } | null;
  if (!b || typeof b.raw_eml_base64 !== 'string' || typeof b.organization_id !== 'string') {
    return NextResponse.json(
      { error: 'missing_fields', required: ['raw_eml_base64', 'organization_id'] },
      { status: 400 },
    );
  }

  let rawBuffer: Buffer;
  try {
    rawBuffer = Buffer.from(b.raw_eml_base64, 'base64');
    if (rawBuffer.byteLength === 0) {
      throw new Error('empty buffer');
    }
  } catch (err) {
    return NextResponse.json(
      { error: 'invalid_base64', detail: (err as Error).message },
      { status: 400 },
    );
  }

  // 3. 메일 파싱 + 영속화
  let parsed;
  try {
    parsed = await simpleParser(rawBuffer);
  } catch (err) {
    return NextResponse.json(
      { error: 'mail_parse_failed', detail: (err as Error).message },
      { status: 400 },
    );
  }

  const supa = getAdminSupabase();
  try {
    const result = await persistInbound(supa, b.organization_id, parsed);
    if (!result) {
      return NextResponse.json({ ok: true, duplicate: true });
    }
    return NextResponse.json({
      ok: true,
      communication_id: result.communicationId,
      thread_id: result.threadId,
      duplicate: false,
      is_auto_reply: result.isAutoReply,
    });
  } catch (err) {
    const status = err instanceof MailCarrierError ? 500 : 500;
    return NextResponse.json(
      { error: 'persist_failed', detail: (err as Error).message },
      { status },
    );
  }
}
