-- ============================================================
-- 20260625120000_email_blocklist.sql
-- 목적: 수신거부(do-not-send / 발송금지) 리스트.
--       app.email_whitelist 와 동일한 형식(pattern + kind + is_active)을 재사용하되,
--       의미는 정반대(차단)이고 bypass 불가. 발송 전 send-outbound 에서 강제 적용.
-- 의존성: 001~010 (app.organizations, app.current_organization_id, gen_random_uuid)
-- 적용: Supabase SQL Editor 에서 실행 (git push 는 DB 에 적용하지 않음)
-- ============================================================

-- ------------------------------------------------------------
-- 1. email_blocklist 테이블 (email_whitelist 형식 미러)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS app.email_blocklist (
    id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id uuid        NOT NULL
                                REFERENCES app.organizations(id) ON DELETE CASCADE,
    -- 차단 패턴. kind 에 따라 정확한 주소 / 도메인 / 정규식으로 해석.
    pattern         text        NOT NULL,
    kind            text        NOT NULL DEFAULT 'address'
                                CHECK (kind IN ('address', 'domain', 'regex')),
    -- 차단 사유(선택): 'unsubscribe' | 'manual' | 'complaint' | 'hard_bounce' ...
    reason          text,
    notes           text,
    is_active       boolean     NOT NULL DEFAULT true,
    created_at      timestamptz NOT NULL DEFAULT NOW(),
    created_by      uuid        -- auth.users(id) 와 매칭되나 FK 는 걸지 않음(스키마 차이 방지)
);

-- 동일 org 안에서 같은 (kind, pattern) 중복 방지 (대소문자 무시)
CREATE UNIQUE INDEX IF NOT EXISTS uq_email_blocklist_org_kind_pattern
    ON app.email_blocklist (organization_id, kind, lower(pattern));

-- 발송 시 active 패턴 조회용
CREATE INDEX IF NOT EXISTS idx_email_blocklist_org_active
    ON app.email_blocklist (organization_id) WHERE is_active;

COMMENT ON TABLE app.email_blocklist IS
    '수신거부/발송금지 리스트. email_whitelist 형식 재사용, 의미는 차단(bypass 불가). send-outbound 에서 강제.';
COMMENT ON COLUMN app.email_blocklist.kind IS
    'address=정확한 이메일, domain=@뒤 도메인, regex=정규식(대소문자 무시).';
COMMENT ON COLUMN app.email_blocklist.reason IS
    '차단 사유 태그(선택): unsubscribe | manual | complaint | hard_bounce 등.';

-- ------------------------------------------------------------
-- 2. RLS (025 패턴 따름)
-- ------------------------------------------------------------
ALTER TABLE app.email_blocklist ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS pol_email_blocklist_select ON app.email_blocklist;
CREATE POLICY pol_email_blocklist_select ON app.email_blocklist
    FOR SELECT USING (organization_id = app.current_organization_id());

DROP POLICY IF EXISTS pol_email_blocklist_insert ON app.email_blocklist;
CREATE POLICY pol_email_blocklist_insert ON app.email_blocklist
    FOR INSERT WITH CHECK (organization_id = app.current_organization_id());

DROP POLICY IF EXISTS pol_email_blocklist_update ON app.email_blocklist;
CREATE POLICY pol_email_blocklist_update ON app.email_blocklist
    FOR UPDATE USING (organization_id = app.current_organization_id())
              WITH CHECK (organization_id = app.current_organization_id());

DROP POLICY IF EXISTS pol_email_blocklist_delete ON app.email_blocklist;
CREATE POLICY pol_email_blocklist_delete ON app.email_blocklist
    FOR DELETE USING (organization_id = app.current_organization_id());

-- 워커는 SUPABASE_SERVICE_ROLE_KEY 로 접속하므로 RLS 우회(추가 정책 불필요).
