-- ============================================================
-- 016_referral_and_opportunity.sql
-- URM Platform — 소개 경로 추적 + 문서 종류 확장 + 기회 가치 필드
--
-- 배경: 외부 검토 제안 중 채택할 부분을 반영한다.
--   1) 문서 종류를 소재 라이선싱 사업에 맞게 확장
--   2) 소개 경로(누가 누구를 소개했는가) 추적 — 기존 설계의 실제 공백
--   3) engagement 에 금액·확률·챔피언·의사결정자 필드 추가
--
-- 선행: 014_drive_integration.sql, 015_houston_pipelines.sql
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- 1. 문서 종류 확장
--
-- 기존 7종은 일반 CRM 기준이었다. MBG는 라이선싱 사업이므로
-- patent / test_report / loi / term_sheet 가 실제로 자주 쓰인다.
-- 특히 test_report 는 Technical Validation 단계의 산출물이라
-- 별도 종류로 두어야 병목 구간을 추적할 수 있다.
-- ------------------------------------------------------------
ALTER TYPE app.drive_link_kind ADD VALUE IF NOT EXISTS 'nda';
ALTER TYPE app.drive_link_kind ADD VALUE IF NOT EXISTS 'loi';
ALTER TYPE app.drive_link_kind ADD VALUE IF NOT EXISTS 'term_sheet';
ALTER TYPE app.drive_link_kind ADD VALUE IF NOT EXISTS 'license_agreement';
ALTER TYPE app.drive_link_kind ADD VALUE IF NOT EXISTS 'patent';
ALTER TYPE app.drive_link_kind ADD VALUE IF NOT EXISTS 'test_report';
ALTER TYPE app.drive_link_kind ADD VALUE IF NOT EXISTS 'spec_sheet';
ALTER TYPE app.drive_link_kind ADD VALUE IF NOT EXISTS 'meeting_note';
ALTER TYPE app.drive_link_kind ADD VALUE IF NOT EXISTS 'invoice';
ALTER TYPE app.drive_link_kind ADD VALUE IF NOT EXISTS 'royalty_report';

-- 주의: PostgreSQL 12+ 에서 ALTER TYPE ... ADD VALUE 는 트랜잭션 안에서
-- 실행할 수 있으나, 같은 트랜잭션 내에서 새 값을 즉시 사용할 수는 없다.
-- 새 값을 쓰는 INSERT 는 이 마이그레이션 커밋 이후에 수행할 것.

COMMIT;

BEGIN;

-- ------------------------------------------------------------
-- 2. 소개 경로 추적
--
-- 기존 설계의 실제 공백이었다. 휴스턴 생태계는 소개로 움직인다.
-- Greentown → 코퍼레이트 파트너 → 투자자 로 이어지는 연쇄에서
-- "누구를 통해 닿았는가"가 관계 자산의 핵심이다.
--
-- 단순 컬럼(introduced_by_party_id) 이 아니라 별도 테이블로 두는 이유:
--   - 한 관계에 소개자가 여러 명일 수 있다
--   - 소개를 "약속했지만 아직 안 된" 상태를 추적해야 한다
--     (미팅에서 가장 흔히 발생하고 가장 잘 잊히는 항목)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS app.introductions (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id   uuid NOT NULL
                      REFERENCES app.organizations(id) ON DELETE CASCADE,

  -- 소개해 준 쪽
  introducer_party_id   uuid REFERENCES app.parties(id) ON DELETE SET NULL,
  introducer_contact_id uuid REFERENCES app.contacts(id) ON DELETE SET NULL,

  -- 소개받은 대상
  target_party_id       uuid REFERENCES app.parties(id) ON DELETE CASCADE,
  target_contact_id     uuid REFERENCES app.contacts(id) ON DELETE SET NULL,

  status            text NOT NULL DEFAULT 'promised'
                      CHECK (status IN ('promised','requested','made','declined','stale')),

  promised_at       date,   -- 미팅에서 약속받은 날
  made_at           date,   -- 실제 소개가 이루어진 날
  context           text,   -- 어떤 자리에서 나온 약속인가
  note              text,

  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE app.introductions IS
  '소개 경로. status=promised 인 채로 오래 남은 행이 곧 놓친 기회다.';

CREATE INDEX IF NOT EXISTS introductions_target_idx
  ON app.introductions (organization_id, target_party_id);

CREATE INDEX IF NOT EXISTS introductions_introducer_idx
  ON app.introductions (organization_id, introducer_party_id);

-- 약속만 하고 진행되지 않은 소개를 찾는 부분 인덱스
CREATE INDEX IF NOT EXISTS introductions_pending_idx
  ON app.introductions (organization_id, promised_at)
  WHERE status IN ('promised','requested');

ALTER TABLE app.introductions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS introductions_org_isolation ON app.introductions;
CREATE POLICY introductions_org_isolation ON app.introductions
  FOR ALL
  USING (organization_id = ((auth.jwt() -> 'app_metadata' ->> 'organization_id'))::uuid)
  WITH CHECK (organization_id = ((auth.jwt() -> 'app_metadata' ->> 'organization_id'))::uuid);

-- ------------------------------------------------------------
-- 3. Engagement 가치 필드
--
-- 라이선싱은 딜 규모가 크고 건수가 적으므로 금액·확률 관리가
-- 제품 판매보다 오히려 더 중요하다.
-- champion 과 decision_maker 를 분리하는 것이 핵심이다.
-- 대기업에서 우리를 밀어주는 사람과 서명하는 사람은 거의 항상 다르다.
-- ------------------------------------------------------------
ALTER TABLE app.engagements
  ADD COLUMN IF NOT EXISTS potential_value_usd    numeric(14,2),
  ADD COLUMN IF NOT EXISTS probability_pct        smallint
                             CHECK (probability_pct BETWEEN 0 AND 100),
  ADD COLUMN IF NOT EXISTS champion_contact_id    uuid
                             REFERENCES app.contacts(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS decision_maker_contact_id uuid
                             REFERENCES app.contacts(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS royalty_basis          text;

COMMENT ON COLUMN app.engagements.royalty_basis IS
  '로열티 산정 기준. 톤당 정액 / 판매가 비율 / 하이브리드. 계약별로 다르므로 기록 필요.';

COMMENT ON COLUMN app.engagements.champion_contact_id IS
  '상대 조직 내부에서 우리를 밀어주는 사람. 의사결정자와 다르다.';

-- ------------------------------------------------------------
-- 4. 미체결 소개 뷰 — 주간 리뷰용
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW app.v_pending_introductions AS
SELECT
  i.id,
  i.organization_id,
  ip.party_name  AS introducer,
  tp.party_name  AS target,
  i.status,
  i.promised_at,
  (current_date - i.promised_at) AS days_pending,
  i.context
FROM app.introductions i
LEFT JOIN app.parties ip ON ip.id = i.introducer_party_id
LEFT JOIN app.parties tp ON tp.id = i.target_party_id
WHERE i.status IN ('promised','requested')
ORDER BY i.promised_at NULLS LAST;

COMMIT;

-- ============================================================
-- 검증
-- ============================================================
-- SELECT unnest(enum_range(NULL::app.drive_link_kind));
-- SELECT * FROM app.v_pending_introductions;
