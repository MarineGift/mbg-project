-- ============================================================
-- 014_drive_integration.sql
-- URM Platform — Google Drive 연동
--
-- 목적: README "알려진 한계 (Phase 1)"의 "첨부 파일 미처리" 해소.
--       Drive를 파일 저장소로, URM을 system of record로 두고
--       ID로만 연결한다. 파일 자체는 절대 복제하지 않는다.
--
-- 전제 (실행 전 반드시 확인할 것):
--   - app.parties(id uuid, organization_id uuid) 존재
--   - app.engagements(id uuid, organization_id uuid) 존재
--   - app.communications(id uuid, organization_id uuid) 존재
--   - app.tasks(id uuid, organization_id uuid) 존재
--   - JWT에 organization_id 주입 (migration 013 custom_access_token_hook)
--   컬럼명이 다르면 아래 참조를 프로젝트 실제 스키마에 맞게 수정.
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- 1. 파티별 홈 폴더
--    파티 1개 = Drive 폴더 1개. 하위에 01~04 표준 구조.
-- ------------------------------------------------------------
ALTER TABLE app.parties
  ADD COLUMN IF NOT EXISTS drive_folder_id text,
  ADD COLUMN IF NOT EXISTS drive_folder_synced_at timestamptz;

COMMENT ON COLUMN app.parties.drive_folder_id IS
  'Google Drive 폴더 ID. 파티 생성 시 자동 생성되며 표준 하위 4폴더를 포함한다.';

CREATE UNIQUE INDEX IF NOT EXISTS parties_drive_folder_id_uniq
  ON app.parties (drive_folder_id)
  WHERE drive_folder_id IS NOT NULL;

-- ------------------------------------------------------------
-- 2. 문서 종류
-- ------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'drive_link_kind') THEN
    CREATE TYPE app.drive_link_kind AS ENUM (
      'agreement',      -- 계약서, NDA, MOU, 멤버십 계약
      'material_sent',  -- 우리가 보낸 IR 덱, 스펙시트, 제안서
      'reference',      -- 상대방이 준 자료
      'correspondence', -- 메일 첨부, 미팅 노트
      'diligence',      -- 실사 요청자료
      'application',    -- 프로그램/그랜트 지원서
      'internal'        -- 내부 작업본
    );
  END IF;
END$$;

-- ------------------------------------------------------------
-- 3. 다형 링크 테이블
--    어떤 엔티티에든 Drive 파일을 붙인다.
--    entity_type + entity_id 로 참조하되 FK는 걸지 않는다
--    (다형 참조이므로 트리거로 정합성 확보).
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS app.drive_links (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id   uuid NOT NULL
                      REFERENCES app.organizations(id) ON DELETE CASCADE,

  entity_type       text NOT NULL
                      CHECK (entity_type IN ('party','engagement','communication','task','organization')),
  entity_id         uuid NOT NULL,

  -- Drive 메타데이터 캐시. URM 검색 시 Drive API를 때리지 않기 위함.
  drive_file_id     text NOT NULL,
  title             text NOT NULL,
  mime_type         text,
  web_view_link     text,
  file_size_bytes   bigint,
  drive_modified_at timestamptz,

  kind              app.drive_link_kind NOT NULL DEFAULT 'reference',
  version_label     text,          -- 'IR v2.0', 'Membership signed' 등
  note              text,

  created_by        uuid REFERENCES app.users(id) ON DELETE SET NULL,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),

  -- 같은 엔티티에 같은 파일을 두 번 붙이지 않는다
  UNIQUE (entity_type, entity_id, drive_file_id)
);

COMMENT ON TABLE app.drive_links IS
  'URM 엔티티와 Google Drive 파일의 연결. 파일 본체는 Drive에만 존재하며 여기에는 메타데이터 캐시만 둔다.';

CREATE INDEX IF NOT EXISTS drive_links_entity_idx
  ON app.drive_links (organization_id, entity_type, entity_id);

CREATE INDEX IF NOT EXISTS drive_links_file_idx
  ON app.drive_links (organization_id, drive_file_id);

CREATE INDEX IF NOT EXISTS drive_links_kind_idx
  ON app.drive_links (organization_id, kind, created_at DESC);

-- 제목 검색 (기존 pg_trgm GIN 인덱스 전략과 동일하게)
CREATE INDEX IF NOT EXISTS drive_links_title_trgm_idx
  ON app.drive_links USING gin (title gin_trgm_ops);

-- ------------------------------------------------------------
-- 4. updated_at 자동 갱신
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION app.touch_drive_links_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS drive_links_touch ON app.drive_links;
CREATE TRIGGER drive_links_touch
  BEFORE UPDATE ON app.drive_links
  FOR EACH ROW EXECUTE FUNCTION app.touch_drive_links_updated_at();

-- ------------------------------------------------------------
-- 5. RLS — 기존 정책과 동일한 조직 격리
-- ------------------------------------------------------------
ALTER TABLE app.drive_links ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS drive_links_org_isolation ON app.drive_links;
CREATE POLICY drive_links_org_isolation ON app.drive_links
  FOR ALL
  USING (
    organization_id = ((auth.jwt() -> 'app_metadata' ->> 'organization_id'))::uuid
  )
  WITH CHECK (
    organization_id = ((auth.jwt() -> 'app_metadata' ->> 'organization_id'))::uuid
  );

-- ------------------------------------------------------------
-- 6. 조직 단위 Drive 설정
-- ------------------------------------------------------------
ALTER TABLE app.organizations
  ADD COLUMN IF NOT EXISTS drive_root_folder_id text,
  ADD COLUMN IF NOT EXISTS drive_investor_folder_id text,
  ADD COLUMN IF NOT EXISTS drive_partner_folder_id text,
  ADD COLUMN IF NOT EXISTS drive_buyer_folder_id text,
  ADD COLUMN IF NOT EXISTS drive_customer_folder_id text;

COMMENT ON COLUMN app.organizations.drive_root_folder_id IS
  '지역 루트 폴더. 휴스턴: 1JmQzSBTAKJ-PYq4Q7SpD53G76bFX23Uq';

-- ------------------------------------------------------------
-- 7. 편의 뷰 — 파티 상세 화면에서 문서 탭 렌더용
--
--    app.parties 의 이름 컬럼은 party_name 으로 확인됨 (2026-08-21)
--    deleted_at 이 있는 소프트 삭제 스키마이므로 필터를 건다.
--
--    ⚠ security_invoker = true 가 핵심이다.
--    PostgreSQL 의 뷰는 기본적으로 뷰 소유자 권한으로 실행되므로
--    underlying table 의 RLS 가 호출자가 아니라 소유자 기준으로
--    평가된다. 이 뷰에는 organization_id 필터가 없으므로
--    security_invoker 없이 두면 조직 격리가 뚫린다.
--
--    PostgreSQL 15 미만이면 이 옵션이 없다. 버전 확인:
--      SELECT version();
--    15 미만이라면 아래 WHERE 절에 다음을 추가할 것:
--      AND p.organization_id
--          = ((auth.jwt() -> 'app_metadata' ->> 'organization_id'))::uuid
-- ------------------------------------------------------------
DROP VIEW IF EXISTS app.v_party_documents;
CREATE VIEW app.v_party_documents
WITH (security_invoker = true)
AS
SELECT
  p.id                AS party_id,
  p.organization_id,
  p.party_name,
  dl.id               AS link_id,
  dl.kind,
  dl.title,
  dl.version_label,
  dl.web_view_link,
  dl.mime_type,
  dl.drive_modified_at,
  dl.created_at
FROM app.parties p
JOIN app.drive_links dl
  ON dl.entity_type = 'party'
 AND dl.entity_id   = p.id
 AND dl.organization_id = p.organization_id
WHERE p.deleted_at IS NULL;

COMMIT;

-- ============================================================
-- 실행 후 확인
-- ============================================================
-- SELECT tablename, rowsecurity FROM pg_tables
--   WHERE schemaname = 'app' AND tablename = 'drive_links';
--   -> rowsecurity = true 이어야 함
--
-- 조직 루트 폴더 설정 예시:
-- UPDATE app.organizations
--    SET drive_root_folder_id     = '1JmQzSBTAKJ-PYq4Q7SpD53G76bFX23Uq',
--        drive_investor_folder_id = '1OrpO_aYQIG8Z0zCWCw2lo1TTJu7Ti7Vj',
--        drive_partner_folder_id  = '1F1mMGayViCQFZ4LlLsjd2N_DkGf3I3gu',
--        drive_buyer_folder_id    = '1gotK9uOWqo9OqODLtQ2zjraGNMDRJlDC'
--  WHERE id = '<your-org-uuid>';
