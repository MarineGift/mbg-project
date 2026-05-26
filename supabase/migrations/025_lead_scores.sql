-- ============================================================
-- 025_lead_scores.sql
-- 목적: party별 lead scoring (0~100) 캐시 테이블
-- 의존성: 001~010 적용 완료
-- ============================================================

-- ------------------------------------------------------------
-- 1. lead_scores 테이블
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS app.lead_scores (
    id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id uuid        NOT NULL
                                REFERENCES app.organizations(id) ON DELETE CASCADE,
    party_id        uuid        NOT NULL
                                REFERENCES app.parties(id) ON DELETE CASCADE,

    -- 0~100 종합 점수
    score           int         NOT NULL DEFAULT 0
                                CHECK (score BETWEEN 0 AND 100),

    -- 세부 점수 분해 (선택)
    factors         jsonb       NOT NULL DEFAULT '{}',
    -- 예: {"engagement_activity": 30, "industry_fit": 25, "tier": 20, "recent_contact": 15, "manual_boost": 10}

    -- 신뢰도 (낮으면 UI에서 "?" 표시)
    confidence      numeric(3,2) NOT NULL DEFAULT 0.5
                                 CHECK (confidence BETWEEN 0 AND 1),

    -- 산정 메타
    computed_at     timestamptz NOT NULL DEFAULT NOW(),
    computed_by     text        NOT NULL DEFAULT 'system'
                                CHECK (computed_by IN ('system', 'ai', 'manual')),
    valid_until     timestamptz,    -- NULL = 영구; 만료 시 재계산 필요

    -- 메타
    notes           text,
    created_at      timestamptz NOT NULL DEFAULT NOW(),
    updated_at      timestamptz NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_lead_scores_party UNIQUE (party_id)
);

CREATE INDEX IF NOT EXISTS idx_lead_scores_org
    ON app.lead_scores (organization_id);
CREATE INDEX IF NOT EXISTS idx_lead_scores_party
    ON app.lead_scores (party_id);
CREATE INDEX IF NOT EXISTS idx_lead_scores_score
    ON app.lead_scores (organization_id, score DESC);

COMMENT ON TABLE app.lead_scores IS
    'Party별 lead score (0-100) 캐시. 정렬·필터에 사용. ttl 만료 시 백그라운드 재계산';
COMMENT ON COLUMN app.lead_scores.factors IS
    '점수 분해 jsonb. UI에서 hover 시 표시 가능. 합계는 score와 일치하지 않을 수 있음 (가중치)';
COMMENT ON COLUMN app.lead_scores.valid_until IS
    'NULL이면 영구 유효. timestamp이면 그 시점 이후 stale로 간주';

-- 업데이트 트리거
DROP TRIGGER IF EXISTS trg_lead_scores_updated_at ON app.lead_scores;
CREATE TRIGGER trg_lead_scores_updated_at
    BEFORE UPDATE ON app.lead_scores
    FOR EACH ROW EXECUTE FUNCTION app.set_updated_at();

-- ------------------------------------------------------------
-- 2. RLS (010 패턴 따름)
-- ------------------------------------------------------------

ALTER TABLE app.lead_scores ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS pol_lead_scores_select ON app.lead_scores;
CREATE POLICY pol_lead_scores_select ON app.lead_scores
    FOR SELECT USING (organization_id = app.current_organization_id());

DROP POLICY IF EXISTS pol_lead_scores_insert ON app.lead_scores;
CREATE POLICY pol_lead_scores_insert ON app.lead_scores
    FOR INSERT WITH CHECK (organization_id = app.current_organization_id());

DROP POLICY IF EXISTS pol_lead_scores_update ON app.lead_scores;
CREATE POLICY pol_lead_scores_update ON app.lead_scores
    FOR UPDATE USING (organization_id = app.current_organization_id())
              WITH CHECK (organization_id = app.current_organization_id());

DROP POLICY IF EXISTS pol_lead_scores_delete ON app.lead_scores;
CREATE POLICY pol_lead_scores_delete ON app.lead_scores
    FOR DELETE USING (organization_id = app.current_organization_id());

-- ------------------------------------------------------------
-- 3. 감사 트리거 (010 패턴 따름)
-- ------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_audit_lead_scores ON app.lead_scores;
CREATE TRIGGER trg_audit_lead_scores
    AFTER INSERT OR UPDATE OR DELETE ON app.lead_scores
    FOR EACH ROW EXECUTE FUNCTION audit.log_change();

-- ------------------------------------------------------------
-- 4. Helper RPC: 여러 party의 score를 한 번에 조회
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_lead_scores_many(
    p_party_ids uuid[]
)
RETURNS TABLE (
    party_id    uuid,
    score       int,
    factors     jsonb,
    computed_at timestamptz
)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, app
AS $$
    SELECT ls.party_id, ls.score, ls.factors, ls.computed_at
      FROM app.lead_scores ls
      JOIN app.parties p ON p.id = ls.party_id
     WHERE ls.party_id = ANY(p_party_ids)
       AND p.organization_id = app.current_organization_id();
$$;

COMMENT ON FUNCTION public.get_lead_scores_many(uuid[]) IS
    'parties/page.tsx 등에서 N+1 방지 — 여러 party의 score를 한 번에 조회';

-- ------------------------------------------------------------
-- 5. 기본 점수 계산 함수 (시드/리프레시용)
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION app.compute_default_lead_score(p_party_id uuid)
RETURNS int
LANGUAGE plpgsql STABLE
AS $$
DECLARE
    v_score         int := 0;
    v_party         record;
    v_recent_comms  int;
    v_open_engs     int;
BEGIN
    SELECT p.tier, p.industry_tags, p.created_at
      INTO v_party
      FROM app.parties p
     WHERE p.id = p_party_id;

    IF NOT FOUND THEN RETURN 0; END IF;

    -- Factor 1: tier (최대 30)
    v_score := v_score + CASE v_party.tier
        WHEN 'tier_1' THEN 30
        WHEN 'tier_2' THEN 20
        WHEN 'tier_3' THEN 10
        ELSE 5
    END;

    -- Factor 2: 최근 30일 communication 수 (최대 30)
    SELECT COUNT(*) INTO v_recent_comms
      FROM app.communications c
     WHERE c.party_id = p_party_id
       AND c.occurred_at > NOW() - INTERVAL '30 days';
    v_score := v_score + LEAST(v_recent_comms * 5, 30);

    -- Factor 3: open engagement 수 (최대 20)
    SELECT COUNT(*) INTO v_open_engs
      FROM app.engagements e
     WHERE e.party_id = p_party_id
       AND e.status IN ('open', 'in_progress');
    v_score := v_score + LEAST(v_open_engs * 10, 20);

    -- Factor 4: industry tag 매칭 (최대 20) — 후속 로직
    -- TODO: organization 기본 타겟 industry와 매칭

    RETURN LEAST(v_score, 100);
END;
$$;

COMMENT ON FUNCTION app.compute_default_lead_score(uuid) IS
    '기본 lead score 계산. tier 30 + 최근 활동 30 + open engagement 20 + 산업 매칭 20';

-- ------------------------------------------------------------
-- 6. 초기 데이터: 모든 기존 party에 기본 score 부여 (idempotent)
-- ------------------------------------------------------------

INSERT INTO app.lead_scores (organization_id, party_id, score, factors, computed_by)
SELECT
    p.organization_id,
    p.id,
    app.compute_default_lead_score(p.id),
    jsonb_build_object(
        'auto_seeded', true,
        'algorithm_version', 'v1.0'
    ),
    'system'
FROM app.parties p
WHERE p.deleted_at IS NULL
ON CONFLICT (party_id) DO NOTHING;

-- ------------------------------------------------------------
-- 7. 검증
-- ------------------------------------------------------------

DO $$
DECLARE
    v_total       int;
    v_with_score  int;
BEGIN
    SELECT COUNT(*) INTO v_total FROM app.parties WHERE deleted_at IS NULL;
    SELECT COUNT(*) INTO v_with_score FROM app.lead_scores;

    RAISE NOTICE '[025] Total active parties: %', v_total;
    RAISE NOTICE '[025] Parties with lead_score: %', v_with_score;

    IF v_with_score < v_total THEN
        RAISE WARNING '[025] % parties missing lead_score', v_total - v_with_score;
    END IF;
END$$;
