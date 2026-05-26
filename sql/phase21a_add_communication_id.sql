-- =============================================================
-- Phase 21a Patch: email_tracking에 communication_id 컬럼 추가
-- + communications 기반 조회 RPC 추가
-- 기존 테이블/RPC는 그대로 유지 (안전한 추가 전용 마이그레이션)
-- =============================================================

-- 1. communication_id 컬럼 추가
ALTER TABLE app.email_tracking
  ADD COLUMN IF NOT EXISTS communication_id UUID;

CREATE INDEX IF NOT EXISTS idx_et_communication
  ON app.email_tracking(communication_id);

-- 2. create_email_tracking RPC 교체 (p_communication_id 파라미터 추가)
CREATE OR REPLACE FUNCTION public.create_email_tracking(
  p_org_id          UUID,
  p_draft_id        UUID    DEFAULT NULL,
  p_communication_id UUID   DEFAULT NULL,   -- ← NEW
  p_party_id        UUID    DEFAULT NULL,
  p_contact_id      UUID    DEFAULT NULL,
  p_subject         TEXT    DEFAULT NULL,
  p_sent_to         TEXT    DEFAULT '',
  p_links           JSONB   DEFAULT '[]'
)
RETURNS JSONB  -- {tracking_id, open_token, links:[{token,url}]}
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, app
AS $$
DECLARE
  v_id           UUID;
  v_open_token   TEXT;
  v_link         JSONB;
  v_link_token   TEXT;
  v_result_links JSONB := '[]'::JSONB;
BEGIN
  INSERT INTO app.email_tracking(
    org_id, draft_id, communication_id,
    party_id, contact_id, subject, sent_to
  )
  VALUES (
    p_org_id, p_draft_id, p_communication_id,
    p_party_id, p_contact_id, p_subject, p_sent_to
  )
  RETURNING id, open_token INTO v_id, v_open_token;

  FOR v_link IN SELECT * FROM jsonb_array_elements(p_links) LOOP
    INSERT INTO app.email_tracking_links(tracking_id, original_url)
    VALUES (v_id, v_link->>'url')
    RETURNING token INTO v_link_token;

    v_result_links := v_result_links
      || jsonb_build_object('token', v_link_token, 'url', v_link->>'url');
  END LOOP;

  RETURN jsonb_build_object(
    'tracking_id', v_id,
    'open_token',  v_open_token,
    'links',       v_result_links
  );
END;
$$;

-- 3. communications 기반 배치 조회 RPC
CREATE OR REPLACE FUNCTION public.get_tracking_for_communications(
  p_communication_ids UUID[]
)
RETURNS TABLE (
  communication_id UUID,
  tracking_id      UUID,
  open_count       INT,
  click_count      INT,
  first_opened_at  TIMESTAMPTZ,
  sent_at          TIMESTAMPTZ
)
LANGUAGE sql SECURITY DEFINER
SET search_path = public, app
AS $$
  SELECT
    et.communication_id,
    et.id           AS tracking_id,
    et.open_count,
    et.click_count,
    et.first_opened_at,
    et.sent_at
  FROM app.email_tracking et
  WHERE et.communication_id = ANY(p_communication_ids)
  ORDER BY et.sent_at DESC;
$$;
