-- =============================================================
-- Phase 22b Patch 1: Email Signature Schema
-- =============================================================
-- app.email_signatures 테이블: 발신자별 HTML 서명 관리
-- app.communications 에 attachment_paths 컬럼 추가
-- =============================================================

-- 1) 이메일 서명 테이블
CREATE TABLE IF NOT EXISTS app.email_signatures (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id        UUID NOT NULL REFERENCES app.organizations(id) ON DELETE CASCADE,
  name          TEXT NOT NULL DEFAULT '기본 서명',
  is_default    BOOLEAN NOT NULL DEFAULT false,
  html_content  TEXT NOT NULL DEFAULT '',
  plain_text    TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 한 조직당 is_default=true 는 하나만 허용
CREATE UNIQUE INDEX IF NOT EXISTS uq_email_signatures_default_per_org
  ON app.email_signatures(org_id)
  WHERE is_default = true;

-- 2) communications 에 첨부파일 경로 배열 추가
ALTER TABLE app.communications
  ADD COLUMN IF NOT EXISTS attachment_paths TEXT[] DEFAULT '{}';

-- 3) RLS
ALTER TABLE app.email_signatures ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "org members can manage signatures" ON app.email_signatures;
CREATE POLICY "org members can manage signatures"
  ON app.email_signatures
  FOR ALL
  USING (
    org_id IN (
      SELECT org_id FROM app.org_members WHERE user_id = auth.uid()
    )
  );

-- 4) updated_at 트리거
CREATE OR REPLACE FUNCTION app.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_email_signatures_updated_at ON app.email_signatures;
CREATE TRIGGER trg_email_signatures_updated_at
  BEFORE UPDATE ON app.email_signatures
  FOR EACH ROW EXECUTE FUNCTION app.set_updated_at();

-- 5) 초기 샘플 서명 삽입 함수 (선택 사항 — 필요 시 실행)
-- INSERT INTO app.email_signatures (org_id, name, is_default, html_content)
-- VALUES (
--   'b25de8f2-1020-482f-9012-183f63883169',
--   '기본 서명',
--   true,
--   '<p style="font-family:sans-serif;font-size:13px;color:#555;">
--     <strong>홍길동</strong><br>
--     Marine Bio Group | CEO<br>
--     📧 ceo@marinepad.com
--   </p>'
-- );
