-- ============================================================
-- 026_saved_views.sql
-- 목적: 사용자별 저장된 filter/sort/column 프리셋
-- 의존성: 001~010
-- ============================================================

-- ------------------------------------------------------------
-- 1. saved_views 테이블
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS app.saved_views (
    id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id uuid        NOT NULL
                                REFERENCES app.organizations(id) ON DELETE CASCADE,
    user_id         uuid        NOT NULL
                                REFERENCES app.users(id) ON DELETE CASCADE,

    -- 어떤 엔티티의 view인가
    entity_type     text        NOT NULL
                                CHECK (entity_type IN (
                                    'party', 'engagement', 'contact', 'task',
                                    'communication', 'inbox', 'draft'
                                )),
    -- 어떤 모듈 컨텍스트
    module          app.module_type,

    -- 표시 정보
    name            text        NOT NULL,
    description     text,
    icon            text,           -- lucide icon name
    color           text,           -- HEX or tailwind token

    -- 실제 view 설정
    filters         jsonb       NOT NULL DEFAULT '{}',
    -- 예: {"tier": ["tier_1","tier_2"], "country_code": "KR", "search": "paper"}

    sort            jsonb       NOT NULL DEFAULT '[]',
    -- 예: [{"field":"updated_at","dir":"desc"}]

    visible_columns text[]      NOT NULL DEFAULT '{}',
    -- 예: ARRAY['name','tier','country_code','last_contact_at']

    -- 공유 / 기본값
    is_default      boolean     NOT NULL DEFAULT false,
    is_shared       boolean     NOT NULL DEFAULT false,
    -- shared = 같은 organization 멤버 모두 SELECT 가능

    -- 메타
    use_count       int         NOT NULL DEFAULT 0,
    last_used_at    timestamptz,
    created_at      timestamptz NOT NULL DEFAULT NOW(),
    updated_at      timestamptz NOT NULL DEFAULT NOW(),

    -- 한 사용자가 같은 entity_type+module에 같은 이름 view 중복 방지
    CONSTRAINT uq_saved_views_user_entity_name
        UNIQUE (user_id, entity_type, module, name)
);

CREATE INDEX IF NOT EXISTS idx_saved_views_user_entity
    ON app.saved_views (user_id, entity_type, module);
CREATE INDEX IF NOT EXISTS idx_saved_views_org_shared
    ON app.saved_views (organization_id, is_shared)
    WHERE is_shared = true;
CREATE INDEX IF NOT EXISTS idx_saved_views_default
    ON app.saved_views (user_id, entity_type, module, is_default)
    WHERE is_default = true;

COMMENT ON TABLE app.saved_views IS
    '사용자별 저장된 필터/정렬/컬럼 프리셋. 페이지 우상단 dropdown으로 노출';
COMMENT ON COLUMN app.saved_views.filters IS
    '엔티티별 자유 jsonb. UI는 entity_type별로 알맞은 필터 키 해석';
COMMENT ON COLUMN app.saved_views.is_shared IS
    'true면 organization 멤버 모두 SELECT 가능 (수정은 owner만)';

-- 트리거
DROP TRIGGER IF EXISTS trg_saved_views_updated_at ON app.saved_views;
CREATE TRIGGER trg_saved_views_updated_at
    BEFORE UPDATE ON app.saved_views
    FOR EACH ROW EXECUTE FUNCTION app.set_updated_at();

-- ------------------------------------------------------------
-- 2. is_default 단일성 보장 트리거
-- (한 (user_id, entity_type, module)에 is_default=true는 최대 1개)
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION app.enforce_single_default_view()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.is_default = true THEN
        UPDATE app.saved_views
           SET is_default = false
         WHERE user_id     = NEW.user_id
           AND entity_type = NEW.entity_type
           AND COALESCE(module::text,'') = COALESCE(NEW.module::text,'')
           AND id <> NEW.id;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_saved_views_single_default ON app.saved_views;
CREATE TRIGGER trg_saved_views_single_default
    AFTER INSERT OR UPDATE OF is_default ON app.saved_views
    FOR EACH ROW
    WHEN (NEW.is_default = true)
    EXECUTE FUNCTION app.enforce_single_default_view();

-- ------------------------------------------------------------
-- 3. RLS (shared view 고려)
-- ------------------------------------------------------------

ALTER TABLE app.saved_views ENABLE ROW LEVEL SECURITY;

-- SELECT: 본인 것 + 같은 조직의 shared view
DROP POLICY IF EXISTS pol_saved_views_select ON app.saved_views;
CREATE POLICY pol_saved_views_select ON app.saved_views
    FOR SELECT USING (
        organization_id = app.current_organization_id()
        AND (user_id = app.current_user_id() OR is_shared = true)
    );

-- INSERT: 본인 것만 + 자기 조직만
DROP POLICY IF EXISTS pol_saved_views_insert ON app.saved_views;
CREATE POLICY pol_saved_views_insert ON app.saved_views
    FOR INSERT WITH CHECK (
        organization_id = app.current_organization_id()
        AND user_id = app.current_user_id()
    );

-- UPDATE: 본인 것만
DROP POLICY IF EXISTS pol_saved_views_update ON app.saved_views;
CREATE POLICY pol_saved_views_update ON app.saved_views
    FOR UPDATE
    USING (
        organization_id = app.current_organization_id()
        AND user_id = app.current_user_id()
    )
    WITH CHECK (
        organization_id = app.current_organization_id()
        AND user_id = app.current_user_id()
    );

-- DELETE: 본인 것만
DROP POLICY IF EXISTS pol_saved_views_delete ON app.saved_views;
CREATE POLICY pol_saved_views_delete ON app.saved_views
    FOR DELETE USING (
        organization_id = app.current_organization_id()
        AND user_id = app.current_user_id()
    );

-- ------------------------------------------------------------
-- 4. 감사 트리거
-- ------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_audit_saved_views ON app.saved_views;
CREATE TRIGGER trg_audit_saved_views
    AFTER INSERT OR UPDATE OR DELETE ON app.saved_views
    FOR EACH ROW EXECUTE FUNCTION audit.log_change();

-- ------------------------------------------------------------
-- 5. 검증
-- ------------------------------------------------------------

DO $$
DECLARE
    v_policies int;
BEGIN
    SELECT COUNT(*) INTO v_policies
      FROM pg_policies
     WHERE schemaname = 'app' AND tablename = 'saved_views';

    RAISE NOTICE '[026] saved_views RLS policies: %', v_policies;

    IF v_policies < 4 THEN
        RAISE WARNING '[026] Expected 4 policies, got %', v_policies;
    END IF;
END$$;
