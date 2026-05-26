-- =============================================================
-- Phase 21a: Email Tracking
-- Run in Supabase SQL Editor (single paste, safe to re-run)
-- =============================================================

-- ── 1. TABLES ──────────────────────────────────────────────

-- Master tracking record (one per sent email)
CREATE TABLE IF NOT EXISTS app.email_tracking (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id          UUID        NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  draft_id        UUID        REFERENCES app.email_drafts(id) ON DELETE SET NULL,
  party_id        UUID        REFERENCES app.parties(id) ON DELETE SET NULL,
  contact_id      UUID        REFERENCES app.contacts(id) ON DELETE SET NULL,
  subject         TEXT,
  sent_to         TEXT        NOT NULL DEFAULT '',
  open_token      TEXT        UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(16), 'hex'),
  sent_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  first_opened_at TIMESTAMPTZ,
  open_count      INT         NOT NULL DEFAULT 0,
  click_count     INT         NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- One row per unique link in the email body
CREATE TABLE IF NOT EXISTS app.email_tracking_links (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tracking_id  UUID NOT NULL REFERENCES app.email_tracking(id) ON DELETE CASCADE,
  token        TEXT UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(12), 'hex'),
  original_url TEXT NOT NULL,
  click_count  INT  NOT NULL DEFAULT 0
);

-- Raw event log (every open/click)
CREATE TABLE IF NOT EXISTS app.email_tracking_events (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  tracking_id  UUID        NOT NULL REFERENCES app.email_tracking(id) ON DELETE CASCADE,
  link_id      UUID        REFERENCES app.email_tracking_links(id) ON DELETE SET NULL,
  event_type   TEXT        NOT NULL CHECK (event_type IN ('open', 'click')),
  url          TEXT,
  ip           TEXT,
  user_agent   TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── 2. INDEXES ─────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_et_org        ON app.email_tracking(org_id);
CREATE INDEX IF NOT EXISTS idx_et_party      ON app.email_tracking(party_id);
CREATE INDEX IF NOT EXISTS idx_et_draft      ON app.email_tracking(draft_id);
CREATE INDEX IF NOT EXISTS idx_et_open_token ON app.email_tracking(open_token);
CREATE INDEX IF NOT EXISTS idx_etl_token     ON app.email_tracking_links(token);
CREATE INDEX IF NOT EXISTS idx_ete_tracking  ON app.email_tracking_events(tracking_id);
CREATE INDEX IF NOT EXISTS idx_ete_created   ON app.email_tracking_events(created_at DESC);

-- ── 3. RLS ─────────────────────────────────────────────────

ALTER TABLE app.email_tracking        ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.email_tracking_links  ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.email_tracking_events ENABLE ROW LEVEL SECURITY;

-- email_tracking
DROP POLICY IF EXISTS "et_select" ON app.email_tracking;
CREATE POLICY "et_select" ON app.email_tracking FOR SELECT
  USING (org_id IN (
    SELECT organization_id FROM public.organization_members WHERE user_id = auth.uid()
  ));

DROP POLICY IF EXISTS "et_insert" ON app.email_tracking;
CREATE POLICY "et_insert" ON app.email_tracking FOR INSERT
  WITH CHECK (org_id IN (
    SELECT organization_id FROM public.organization_members WHERE user_id = auth.uid()
  ));

-- email_tracking_links
DROP POLICY IF EXISTS "etl_select" ON app.email_tracking_links;
CREATE POLICY "etl_select" ON app.email_tracking_links FOR SELECT
  USING (tracking_id IN (
    SELECT et.id FROM app.email_tracking et
    JOIN public.organization_members om ON om.organization_id = et.org_id
    WHERE om.user_id = auth.uid()
  ));

DROP POLICY IF EXISTS "etl_insert" ON app.email_tracking_links;
CREATE POLICY "etl_insert" ON app.email_tracking_links FOR INSERT
  WITH CHECK (tracking_id IN (
    SELECT et.id FROM app.email_tracking et
    JOIN public.organization_members om ON om.organization_id = et.org_id
    WHERE om.user_id = auth.uid()
  ));

-- email_tracking_events
DROP POLICY IF EXISTS "ete_select" ON app.email_tracking_events;
CREATE POLICY "ete_select" ON app.email_tracking_events FOR SELECT
  USING (tracking_id IN (
    SELECT et.id FROM app.email_tracking et
    JOIN public.organization_members om ON om.organization_id = et.org_id
    WHERE om.user_id = auth.uid()
  ));

-- ── 4. PUBLIC RPCs (no auth — called by pixel/redirect) ────

-- Record open event
CREATE OR REPLACE FUNCTION public.record_email_open(
  p_token TEXT,
  p_ip    TEXT DEFAULT NULL,
  p_ua    TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, app
AS $$
DECLARE
  v_id UUID;
BEGIN
  SELECT id INTO v_id FROM app.email_tracking WHERE open_token = p_token;
  IF v_id IS NULL THEN RETURN; END IF;

  INSERT INTO app.email_tracking_events(tracking_id, event_type, ip, user_agent)
  VALUES (v_id, 'open', p_ip, p_ua);

  UPDATE app.email_tracking
  SET open_count      = open_count + 1,
      first_opened_at = COALESCE(first_opened_at, now())
  WHERE id = v_id;
END;
$$;

-- Record click event — returns original URL for redirect
CREATE OR REPLACE FUNCTION public.record_email_click(
  p_token TEXT,
  p_ip    TEXT DEFAULT NULL,
  p_ua    TEXT DEFAULT NULL
)
RETURNS TEXT
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, app
AS $$
DECLARE
  v_link_id    UUID;
  v_tracking_id UUID;
  v_url        TEXT;
BEGIN
  SELECT id, tracking_id, original_url
  INTO v_link_id, v_tracking_id, v_url
  FROM app.email_tracking_links
  WHERE token = p_token;

  IF v_link_id IS NULL THEN RETURN NULL; END IF;

  INSERT INTO app.email_tracking_events(tracking_id, link_id, event_type, url, ip, user_agent)
  VALUES (v_tracking_id, v_link_id, 'click', v_url, p_ip, p_ua);

  UPDATE app.email_tracking_links SET click_count = click_count + 1 WHERE id = v_link_id;
  UPDATE app.email_tracking       SET click_count = click_count + 1 WHERE id = v_tracking_id;

  RETURN v_url;
END;
$$;

-- Create tracking record + links (called from server action after send)
CREATE OR REPLACE FUNCTION public.create_email_tracking(
  p_org_id     UUID,
  p_draft_id   UUID    DEFAULT NULL,
  p_party_id   UUID    DEFAULT NULL,
  p_contact_id UUID    DEFAULT NULL,
  p_subject    TEXT    DEFAULT NULL,
  p_sent_to    TEXT    DEFAULT '',
  p_links      JSONB   DEFAULT '[]'
)
RETURNS JSONB  -- {tracking_id, open_token, links:[{token,url}]}
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, app
AS $$
DECLARE
  v_id          UUID;
  v_open_token  TEXT;
  v_link        JSONB;
  v_link_token  TEXT;
  v_result_links JSONB := '[]'::JSONB;
BEGIN
  INSERT INTO app.email_tracking(org_id, draft_id, party_id, contact_id, subject, sent_to)
  VALUES (p_org_id, p_draft_id, p_party_id, p_contact_id, p_subject, p_sent_to)
  RETURNING id, open_token INTO v_id, v_open_token;

  FOR v_link IN SELECT * FROM jsonb_array_elements(p_links) LOOP
    INSERT INTO app.email_tracking_links(tracking_id, original_url)
    VALUES (v_id, v_link->>'url')
    RETURNING token INTO v_link_token;

    v_result_links := v_result_links || jsonb_build_object(
      'token', v_link_token,
      'url',   v_link->>'url'
    );
  END LOOP;

  RETURN jsonb_build_object(
    'tracking_id', v_id,
    'open_token',  v_open_token,
    'links',       v_result_links
  );
END;
$$;

-- Fetch tracking summary for a list of draft IDs (inbox display)
CREATE OR REPLACE FUNCTION public.get_tracking_for_drafts(p_draft_ids UUID[])
RETURNS TABLE (
  draft_id        UUID,
  tracking_id     UUID,
  open_count      INT,
  click_count     INT,
  first_opened_at TIMESTAMPTZ,
  sent_at         TIMESTAMPTZ
)
LANGUAGE sql SECURITY DEFINER
SET search_path = public, app
AS $$
  SELECT
    et.draft_id,
    et.id        AS tracking_id,
    et.open_count,
    et.click_count,
    et.first_opened_at,
    et.sent_at
  FROM app.email_tracking et
  WHERE et.draft_id = ANY(p_draft_ids)
  ORDER BY et.sent_at DESC;
$$;
