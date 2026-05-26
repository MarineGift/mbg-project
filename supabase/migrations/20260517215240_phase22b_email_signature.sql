-- ============================================================
-- Patch 3a (수정판) — 이메일 서명 테이블
-- app.organization_members 참조 제거 (테이블 없음 에러 수정)
-- ============================================================

-- 1. 서명 테이블 생성
CREATE TABLE IF NOT EXISTS app.email_signatures (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id        uuid        NOT NULL,
  user_id       uuid        REFERENCES auth.users(id) ON DELETE SET NULL,
  name          text        NOT NULL DEFAULT '기본 서명',
  html          text        NOT NULL DEFAULT '',
  plain_text    text        NOT NULL DEFAULT '',
  is_default    boolean     NOT NULL DEFAULT false,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

-- 2. 기본 서명 중복 방지 (org_id + user_id 조합으로 1개만)
CREATE UNIQUE INDEX IF NOT EXISTS uidx_email_signatures_default
  ON app.email_signatures (org_id, COALESCE(user_id, '00000000-0000-0000-0000-000000000000'::uuid))
  WHERE is_default = true;

-- 3. updated_at 자동 갱신 트리거
CREATE OR REPLACE FUNCTION app.set_email_signatures_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;

DROP TRIGGER IF EXISTS trg_email_signatures_updated_at ON app.email_signatures;
CREATE TRIGGER trg_email_signatures_updated_at
  BEFORE UPDATE ON app.email_signatures
  FOR EACH ROW EXECUTE FUNCTION app.set_email_signatures_updated_at();

-- 4. RLS — 인증된 사용자만 (org 멤버십 테이블 참조 없이)
ALTER TABLE app.email_signatures ENABLE ROW LEVEL SECURITY;

-- 기존 정책 삭제 후 재생성
DROP POLICY IF EXISTS "authenticated users manage signatures" ON app.email_signatures;
CREATE POLICY "authenticated users manage signatures"
  ON app.email_signatures
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- ※ 보안 강화가 필요하면 나중에 실제 멤버십 테이블명 확인 후
--   USING (org_id = (SELECT organization_id FROM <실제테이블> WHERE user_id = auth.uid()))
--   으로 교체

-- 5. Storage 버킷 (email-attachments)
-- ※ Supabase Dashboard > Storage에서 직접 생성 권장
-- 아래는 이미 버킷이 없는 경우만 실행
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'email-attachments',
  'email-attachments',
  false,
  26214400,
  NULL
)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS
DROP POLICY IF EXISTS "auth upload email-attachments" ON storage.objects;
CREATE POLICY "auth upload email-attachments"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'email-attachments');

DROP POLICY IF EXISTS "auth read email-attachments" ON storage.objects;
CREATE POLICY "auth read email-attachments"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'email-attachments');

DROP POLICY IF EXISTS "auth delete email-attachments" ON storage.objects;
CREATE POLICY "auth delete email-attachments"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'email-attachments');
