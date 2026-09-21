-- ============================================================
-- seed_ipo_advisor_pipeline.sql  (rev.1)
-- URM Platform — 상장 자문단 파이프라인
--
-- 015_houston_pipelines.sql 의 구조를 그대로 쓴다.
-- 주간사·PCAOB 감사인·증권법률고문·명의개서대리인·마켓메이커·
-- IR 펌은 "파티" 이므로 ipo_* 테이블이 아니라 여기에 산다.
--
-- ⚠ 설계 판단: 새 party_type 을 만들지 않는다.
--   party_types 의 실제 컬럼 구성을 확인하지 않고 INSERT 하면
--   스키마 불일치로 깨진다. 기존 'partner' 타입에 is_default=false
--   두 번째 파이프라인을 붙인다. 015 가 건 부분 유니크 인덱스는
--   is_default 인 행만 막으므로 충돌하지 않는다.
--
--   전용 party_type 'ipo_advisor' 를 원하면 STEP 0-(B) 를 먼저
--   실행해 컬럼 구성을 확인한 뒤 별도 패치로 분리하십시오.
--
-- ⚠ Public 리포 주의: 실제 UUID 를 이 파일에 적지 말 것.
-- ============================================================

-- ------------------------------------------------------------
-- STEP 0 — 실행 전 확인 (아래를 먼저 따로 실행)
-- ------------------------------------------------------------
-- (A) 'partner' 타입 존재
--   SELECT id, code FROM app.party_types WHERE code = 'partner';
--
-- (B) party_types 컬럼 구성 (전용 타입을 만들 경우에만 필요)
--   SELECT column_name, data_type, is_nullable, column_default
--     FROM information_schema.columns
--    WHERE table_schema='app' AND table_name='party_types'
--    ORDER BY ordinal_position;
--
-- (C) 같은 이름의 파이프라인이 이미 있는지
--   SELECT id, name, is_default FROM app.pipeline_definitions
--    WHERE name = 'Nasdaq Listing Advisors';
-- ============================================================

DO $$
DECLARE
  -- ▼▼▼ 실행 전 반드시 수정 ▼▼▼
  v_org      uuid    := '00000000-0000-0000-0000-000000000000';
  v_reseed   boolean := false;
  -- ▲▲▲ 실행 전 반드시 수정 ▲▲▲

  v_name     text := 'Nasdaq Listing Advisors';
  v_type     app.party_types.id%TYPE;   -- 실제 컬럼 타입 추종 (uuid 든 int 든)
  v_pipe     uuid;
  v_existing uuid;
  v_inuse    int;

  -- 자문단은 "따내는" 관계가 아니라 "붙잡는" 관계다.
  -- Engaged 가 종착이 아니라 가장 일이 많은 구간이므로 active 로 둔다.
  -- Retained 를 won 으로 두면 선임 직후 주간사가 파이프라인에서 사라진다.
  v_stages jsonb := jsonb_build_array(
    jsonb_build_object('n','Longlist',          'k','active'),
    jsonb_build_object('n','Intro Call',        'k','active'),
    jsonb_build_object('n','Capability Review', 'k','active'),
    jsonb_build_object('n','Bake-off / RFP',    'k','active'),
    jsonb_build_object('n','Fee Negotiation',   'k','active'),
    jsonb_build_object('n','Engaged',           'k','active'),
    jsonb_build_object('n','On Hold',           'k','hold'),
    jsonb_build_object('n','Declined',          'k','lost')
  );

  v_stage jsonb;
  v_idx   int := 0;
BEGIN

  IF v_org = '00000000-0000-0000-0000-000000000000' THEN
    RAISE EXCEPTION 'v_org 를 실제 organization_id 로 교체한 뒤 실행하십시오.';
  END IF;

  SELECT id INTO v_type FROM app.party_types WHERE code = 'partner';
  IF v_type IS NULL THEN
    RAISE EXCEPTION 'party_type "partner" 를 찾을 수 없습니다. STEP 0-(A) 확인.';
  END IF;

  SELECT id INTO v_existing
    FROM app.pipeline_definitions
   WHERE organization_id = v_org AND name = v_name
   LIMIT 1;

  IF v_existing IS NOT NULL THEN
    IF NOT v_reseed THEN
      RAISE NOTICE '건너뜀 (이미 존재): %', v_name;
      RETURN;
    END IF;

    SELECT count(*) INTO v_inuse
      FROM app.engagements e
      JOIN app.pipeline_stages ps ON ps.id = e.pipeline_stage_id
     WHERE ps.pipeline_definition_id = v_existing;

    IF v_inuse > 0 THEN
      RAISE EXCEPTION
        '재생성 거부: % 에 engagement %건이 연결되어 있습니다.', v_name, v_inuse;
    END IF;

    DELETE FROM app.pipeline_stages      WHERE pipeline_definition_id = v_existing;
    DELETE FROM app.pipeline_definitions WHERE id = v_existing;
    RAISE NOTICE '재생성: %', v_name;
  END IF;

  -- is_default = false 가 핵심이다. partner 의 기본 파이프라인은
  -- 'HTX Ecosystem' 이며 그 자리를 빼앗지 않는다.
  INSERT INTO app.pipeline_definitions (organization_id, party_type_id, name, is_default)
  VALUES (v_org, v_type, v_name, false)
  RETURNING id INTO v_pipe;

  FOR v_stage IN SELECT jsonb_array_elements(v_stages)
  LOOP
    v_idx := v_idx + 1;
    INSERT INTO app.pipeline_stages
      (pipeline_definition_id, name, sort_order, stage_kind, is_terminal)
    VALUES (
      v_pipe, v_stage ->> 'n', v_idx, v_stage ->> 'k',
      (v_stage ->> 'k') IN ('won','lost'));
  END LOOP;

  RAISE NOTICE '생성: % (스테이지 %개)', v_name, v_idx;
END$$;


-- ============================================================
-- 검증 / 사용
-- ============================================================
-- SELECT pd.name, ps.sort_order, ps.name AS stage, ps.stage_kind
--   FROM app.pipeline_definitions pd
--   JOIN app.pipeline_stages ps ON ps.pipeline_definition_id = pd.id
--  WHERE pd.name = 'Nasdaq Listing Advisors'
--  ORDER BY ps.sort_order;
--
-- 기대: 8 스테이지, won 없음 (선임은 종결이 아니다)
--
-- ---- 자문사를 마일스톤에 물리기 ----
-- INSERT INTO app.ipo_milestone_parties (milestone_id, party_id, role)
-- SELECT m.id, :party_id, 'underwriter'
--   FROM app.ipo_milestones m
--  WHERE m.code = 'K-CP-02';
--
-- role 값: underwriter / auditor / securities_counsel / ip_counsel
--          transfer_agent / market_maker / ir_firm
--
-- ---- 채워야 할 자문단 슬롯 점검 ----
-- SELECT r.role,
--        count(mp.party_id) AS filled
--   FROM unnest(ARRAY['underwriter','auditor','securities_counsel',
--                     'ip_counsel','transfer_agent','market_maker','ir_firm']) AS r(role)
--   LEFT JOIN app.ipo_milestone_parties mp ON mp.role = r.role
--  GROUP BY r.role ORDER BY filled, r.role;
