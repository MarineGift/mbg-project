'use server';
/**
 * lib/actions/email-tracking.ts
 *
 * 이메일 추적 레코드 생성 + HTML 픽셀 주입.
 *
 * 사용처:
 *   - communications.ts → sendOutboundManual (수동 발송)
 *   - (future) drafts.ts → sendApprovedDraft (AI 자동 발송)
 */

import { createSupabaseServerClient } from '@/lib/supabase/server';
import { rpc } from '@/lib/rpc/typed-rpc';
import { extractLinks, injectTracking } from '@/lib/utils/email-tracking';
import type { TrackingPayload } from '@/types/phase21';

/* ──────────────────────────────────────────────────────────
 * 입력 타입
 * ────────────────────────────────────────────────────────── */
export interface CreateTrackingInput {
  orgId: string;

  /** 수동 발송의 communications.id */
  communicationId?: string;

  /** 템플릿 기반 드래프트의 id (future) */
  draftId?: string;

  partyId?: string;
  contactId?: string;
  subject?: string;
  sentTo: string;

  /** 픽셀 + 링크를 삽입할 HTML 본문.
   *  plain text는 호출 전에 plainToHtml()로 변환해서 전달. */
  htmlBody: string;
}

export interface CreateTrackingResult {
  payload: TrackingPayload;
  /** 픽셀·추적 링크가 삽입된 HTML — sendOne(bodyHtml: ...) 에 전달 */
  injectedHtml: string;
}

/* ──────────────────────────────────────────────────────────
 * 메인 함수
 * ────────────────────────────────────────────────────────── */

/**
 * 1. htmlBody에서 외부 링크 추출
 * 2. email_tracking + email_tracking_links rows 생성 (RPC)
 * 3. HTML에 픽셀 + 추적 링크 주입
 * 4. injectedHtml 반환 → 이것을 sendOne(bodyHtml) 에 넘길 것
 */
export async function createEmailTracking(
  input: CreateTrackingInput,
): Promise<CreateTrackingResult> {
  const supabase = await createSupabaseServerClient();

  const links = extractLinks(input.htmlBody).map((url) => ({ url }));

  const { data, error } = await rpc(supabase, 'create_email_tracking', {
    p_org_id:           input.orgId,
    p_communication_id: input.communicationId ?? null,
    p_draft_id:         input.draftId         ?? null,
    p_party_id:         input.partyId         ?? null,
    p_contact_id:       input.contactId       ?? null,
    p_subject:          input.subject         ?? null,
    p_sent_to:          input.sentTo,
    p_links:            links,
  });

  if (error) {
    throw new Error(`createEmailTracking RPC failed: ${error.message}`);
  }

  const payload = data as unknown as TrackingPayload;
  const injectedHtml = injectTracking(input.htmlBody, payload);

  return { payload, injectedHtml };
}
