/**
 * lib/queries/email-tracking.ts
 *
 * 이메일 추적 데이터 조회.
 */

import { createSupabaseServerClient } from '@/lib/supabase/server';
import type {
  EmailTracking,
  EmailTrackingEvent,
  DraftTrackingSummary,
} from '@/types/phase21';

/* ──────────────────────────────────────────────────────────
 * 단건 조회
 * ────────────────────────────────────────────────────────── */

/** communication_id로 추적 레코드 조회 (수동 발송용) */
export async function fetchTrackingForCommunication(
  communicationId: string,
): Promise<EmailTracking | null> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('email_tracking')
    .select('*')
    .eq('communication_id', communicationId)
    .order('sent_at', { ascending: false })
    .limit(1)
    .maybeSingle();
  if (error) throw error;
  return data;
}

/** draft_id로 추적 레코드 조회 (드래프트 기반 발송용) */
export async function fetchTrackingForDraft(
  draftId: string,
): Promise<EmailTracking | null> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('email_tracking')
    .select('*')
    .eq('draft_id', draftId)
    .order('sent_at', { ascending: false })
    .limit(1)
    .maybeSingle();
  if (error) throw error;
  return data;
}

/** party_id로 해당 거래처의 발송 이력 전체 조회 */
export async function fetchTrackingForParty(
  partyId: string,
): Promise<EmailTracking[]> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('email_tracking')
    .select('*')
    .eq('party_id', partyId)
    .order('sent_at', { ascending: false });
  if (error) throw error;
  return data ?? [];
}

/** 단건 이벤트 로그 조회 */
export async function fetchTrackingEvents(
  trackingId: string,
): Promise<EmailTrackingEvent[]> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('email_tracking_events')
    .select('*')
    .eq('tracking_id', trackingId)
    .order('created_at', { ascending: false });
  if (error) throw error;
  return data ?? [];
}

/* ──────────────────────────────────────────────────────────
 * 배치 조회 (인박스 목록 배지용)
 * ────────────────────────────────────────────────────────── */

/**
 * communication_id 배열로 추적 요약 일괄 조회.
 * 인박스 sent 탭에서 행마다 배지를 표시할 때 사용.
 * Map<communicationId, DraftTrackingSummary> 반환.
 */
export async function fetchTrackingMapForCommunications(
  communicationIds: string[],
): Promise<Map<string, DraftTrackingSummary>> {
  if (!communicationIds.length) return new Map();

  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.rpc(
    'get_tracking_for_communications',
    { p_communication_ids: communicationIds },
  );
  if (error) throw error;

  const map = new Map<string, DraftTrackingSummary>();
  for (const row of (data ?? []) as Array<{
    communication_id: string;
    tracking_id: string;
    open_count: number;
    click_count: number;
    first_opened_at: string | null;
    sent_at: string;
  }>) {
    if (row.communication_id) {
      map.set(row.communication_id, {
        draft_id: row.communication_id,   // 재사용 — id 필드로 활용
        tracking_id: row.tracking_id,
        open_count: row.open_count,
        click_count: row.click_count,
        first_opened_at: row.first_opened_at,
        sent_at: row.sent_at,
      });
    }
  }
  return map;
}

/** draft_id 배열 배치 조회 (기존 호환) */
export async function fetchTrackingMapForDrafts(
  draftIds: string[],
): Promise<Map<string, DraftTrackingSummary>> {
  if (!draftIds.length) return new Map();

  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.rpc('get_tracking_for_drafts', {
    p_draft_ids: draftIds,
  });
  if (error) throw error;

  const map = new Map<string, DraftTrackingSummary>();
  for (const row of (data ?? []) as DraftTrackingSummary[]) {
    if (row.draft_id) map.set(row.draft_id, row);
  }
  return map;
}
