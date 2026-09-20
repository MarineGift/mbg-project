-- ============================================================
-- 015_houston_pipelines.sql  (rev.4)
-- URM Platform — 휴스턴 사업 파이프라인 시드
--
-- rev.4 변경점 (외부 검토 반영):
--   1) 재실행 안전성 확보. 기존 default 파이프라인이 있으면 건너뛴다.
--      v_reseed=true 로 두면 지우고 다시 만들되, engagement 가
--      물려 있으면 거부한다 (데이터 손실 방지).
--   2) partner 의 'Active Collaboration' 을 won → active 로 변경.
--      생태계 관계는 협업이 시작되는 순간이 가장 활발한 상태다.
--      won 으로 두면 Greentown·Rice·UH 가 실질 파이프라인에서
--      사라진다. partner 파이프라인에는 won 스테이지를 두지 않는다.
--      관계는 승리로 끝나지 않는다.
--
-- rev.3: stage_kind + is_terminal 도입
-- rev.2: party_type_id FK 반영, buyer → 라이선싱 파이프라인 재설계
--
-- ⚠ Public 리포 주의: 실제 UUID·Drive ID 를 이 파일에 적지 말 것.
-- ============================================================

-- ------------------------------------------------------------
-- STEP 0 — 실행 전 확인 (아래를 먼저 따로 실행)
-- ------------------------------------------------------------
-- (A) 파이프라인 테이블 컬럼
--   SELECT table_name, column_name, data_type
--     FROM information_schema.columns
--    WHERE table_schema='app'
--      AND table_name IN ('pipeline_definitions','pipeline_stages')
--    ORDER BY table_name, ordinal_position;
--
-- (B) party_type_id 참조 대상
--   SELECT kcu.table_name, kcu.column_name,
--          ccu.table_name AS ref_table, ccu.column_name AS ref_column
--     FROM information_schema.table_constraints tc
--     JOIN information_schema.key_column_usage kcu
--       ON tc.constraint_name=kcu.constraint_name AND tc.table_schema=kcu.table_schema
--     JOIN information_schema.constraint_column_usage ccu
--       ON tc.constraint_name=ccu.constraint_name
--    WHERE tc.constraint_type='FOREIGN KEY' AND tc.table_schema='app'
--      AND tc.table_name IN ('parties','pipeline_definitions','pipeline_stages');
--
-- (C) 룩업 실제 값
--   SELECT * FROM app.party_types ORDER BY 1;
--
-- (D) 중복 방지 제약 존재 여부  ← rev.4 추가
--   SELECT conname, pg_get_constraintdef(oid)
--     FROM pg_constraint
--    WHERE conrelid = 'app.pipeline_definitions'::regclass
--      AND contype IN ('u','p');
--
--   (organization_id, party_type_id) 또는 name 을 포함한 UNIQUE 가
--   없다면 아래 스크립트의 존재 확인 로직에만 의존하게 된다.
--   장기적으로는 부분 유니크 인덱스를 두는 편이 안전하다:
--
--     CREATE UNIQUE INDEX IF NOT EXISTS pipeline_definitions_default_uniq
--       ON app.pipeline_definitions (organization_id, party_type_id)
--       WHERE is_default;
-- ============================================================


-- ------------------------------------------------------------
-- TX 1. 스테이지 분류 컬럼 + 중복 default 방지
--
--   active — 진행 중. 실질 파이프라인 집계 대상
--   won    — 목표 달성. 종결
--   lost   — 실패. 종결
--   hold   — 보류. 되살아날 수 있으므로 종결이 아니다
-- ------------------------------------------------------------
BEGIN;

ALTER TABLE app.pipeline_stages
  ADD COLUMN IF NOT EXISTS stage_kind  text    NOT NULL DEFAULT 'active',
  ADD COLUMN IF NOT EXISTS is_terminal boolean NOT NULL DEFAULT false;

ALTER TABLE app.pipeline_stages
  DROP CONSTRAINT IF EXISTS pipeline_stages_stage_kind_check;
ALTER TABLE app.pipeline_stages
  ADD CONSTRAINT pipeline_stages_stage_kind_check
    CHECK (stage_kind IN ('active','won','lost','hold'));

-- is_terminal 은 stage_kind 에서 파생된다. 불일치를 물리적으로 막는다.
ALTER TABLE app.pipeline_stages
  DROP CONSTRAINT IF EXISTS pipeline_stages_terminal_consistent;
ALTER TABLE app.pipeline_stages
  ADD CONSTRAINT pipeline_stages_terminal_consistent
    CHECK (is_terminal = (stage_kind IN ('won','lost')));

COMMENT ON COLUMN app.pipeline_stages.stage_kind IS
  '집계용 분류. 실질 파이프라인은 active 만 센다. hold 는 종결이 아니므로 별도 표시.';

CREATE INDEX IF NOT EXISTS pipeline_stages_kind_idx
  ON app.pipeline_stages (pipeline_definition_id, stage_kind);

-- ---- 조직·party_type 당 default 파이프라인은 하나뿐 ----
--
-- 아래 DO 블록의 재실행 방어 로직만으로는 동시 실행이나 다른
-- 코드 경로에서의 중복 생성을 막지 못한다. DB 레벨에서 막는다.
-- 기존 중복이 있으면 인덱스 생성이 실패하므로 먼저 확인하고
-- 명확한 메시지로 중단시킨다.
DO $$
DECLARE v_dupes int;
BEGIN
  SELECT count(*) INTO v_dupes
    FROM (
      SELECT organization_id, party_type_id
        FROM app.pipeline_definitions
       WHERE is_default
       GROUP BY organization_id, party_type_id
      HAVING count(*) > 1
    ) d;

  IF v_dupes > 0 THEN
    RAISE EXCEPTION
      '중복 default 파이프라인 %건이 있습니다. 유니크 인덱스를 만들 수 없습니다. '
      '아래 쿼리로 확인 후 정리하십시오: '
      'SELECT organization_id, party_type_id, count(*) FROM app.pipeline_definitions '
      'WHERE is_default GROUP BY 1,2 HAVING count(*) > 1;',
      v_dupes;
  END IF;
END$$;

CREATE UNIQUE INDEX IF NOT EXISTS pipeline_definitions_default_uniq
  ON app.pipeline_definitions (organization_id, party_type_id)
  WHERE is_default;

COMMIT;


-- ------------------------------------------------------------
-- TX 2. 파이프라인 시드 (재실행 안전)
-- ------------------------------------------------------------
DO $$
DECLARE
  -- ▼▼▼ 실행 전 반드시 수정 ▼▼▼
  v_org             uuid    := '00000000-0000-0000-0000-000000000000';
  v_lookup_table    text    := 'app.party_types';
  v_lookup_code_col text    := 'code';
  v_reseed          boolean := false;  -- true: 기존 default 를 지우고 재생성
  -- ▲▲▲ 실행 전 반드시 수정 ▲▲▲

  v_pipe     uuid;
  v_type     uuid;
  v_existing uuid;
  v_inuse    int;

  v_specs jsonb := jsonb_build_object(

    -- ========================================================
    -- INVESTOR — 자금조달
    --
    -- Diligence 진입이 진짜 분기점이다. Researched~First Meeting 에
    -- 파티가 쌓이면 두터워 보이지만 아무 일도 없는 상태다.
    -- ========================================================
    'investor', jsonb_build_object(
      'name', 'HTX Fundraising',
      'stages', jsonb_build_array(
        jsonb_build_object('n','Researched',      'k','active'),
        jsonb_build_object('n','Intro Requested', 'k','active'),
        jsonb_build_object('n','First Meeting',   'k','active'),
        jsonb_build_object('n','Diligence',       'k','active'),
        jsonb_build_object('n','Term Sheet',      'k','active'),
        jsonb_build_object('n','Closed',          'k','won'),
        jsonb_build_object('n','On Hold',         'k','hold'),
        jsonb_build_object('n','Passed',          'k','lost'))),

    -- ========================================================
    -- BUYER (표시명: Licensee) — 기술 라이선싱
    --
    -- MBG는 필러를 만들어 팔지 않는다. FCC/HFCC 기술을 광물
    -- 대기업에 라이선싱하고 로열티를 받는다. Omya 도 SMI 도
    -- MBG 기술로 충전제를 생산해 제지사에 공급하고 MBG에
    -- 로열티를 지급한다. 그 외의 관계는 없다.
    --
    -- 실제 관문은 셋: NDA → Technical Validation → License Executed
    -- Technical Validation 이 압도적 병목이며 공이 상대편에 있는
    -- 유일한 구간이므로 체류일수를 반드시 감시한다.
    --
    -- 체결 이후의 로열티 관리는 customer(Royalty Accounts)로 넘긴다.
    -- 여기에 'Royalty Active' 를 두면 파티가 어디 사는지 모호해진다.
    -- ========================================================
    'buyer', jsonb_build_object(
      'name', 'Technology Licensing',
      'stages', jsonb_build_array(
        jsonb_build_object('n','Prospect',             'k','active'),
        jsonb_build_object('n','NDA',                  'k','active'),
        jsonb_build_object('n','Evaluation',           'k','active'),
        jsonb_build_object('n','Technical Validation', 'k','active'),
        jsonb_build_object('n','Term Negotiation',     'k','active'),
        jsonb_build_object('n','License Executed',     'k','won'),
        jsonb_build_object('n','On Hold',              'k','hold'),
        jsonb_build_object('n','Lost',                 'k','lost'))),

    -- ========================================================
    -- PARTNER — 협력기관 (Greentown, Rice, UH, HETI, C2V)
    --
    -- won 스테이지가 없다. 의도적이다.
    -- 생태계 관계는 계약으로 끝나지 않는다. Active Collaboration 은
    -- 관계가 가장 활발한 상태이지 종결이 아니므로 active 로 둔다.
    -- won 으로 두면 Greentown·Rice·UH 가 실질 파이프라인에서 사라진다.
    --
    -- 프로그램 지원(C2V Y6, Greentown Go)은 별도 파이프라인을 만들지
    -- 않는다. 마감일 있는 프로젝트이지 관계의 진전이 아니므로
    -- 주최기관만 partner 파티로 두고 지원 건은 engagement + task 로.
    -- ========================================================
    'partner', jsonb_build_object(
      'name', 'HTX Ecosystem',
      'stages', jsonb_build_array(
        jsonb_build_object('n','Mapped',              'k','active'),
        jsonb_build_object('n','Intro Meeting',       'k','active'),
        jsonb_build_object('n','Scoping',             'k','active'),
        jsonb_build_object('n','Agreement',           'k','active'),
        jsonb_build_object('n','Active Collaboration','k','active'),
        jsonb_build_object('n','On Hold',             'k','hold'),
        jsonb_build_object('n','No Fit',              'k','lost'))),

    -- ========================================================
    -- CUSTOMER — 라이선스 체결 이후의 로열티 계정
    --
    -- deal pipeline 이 아니라 post-close lifecycle 이다.
    -- At Risk 는 경고 상태이지 종결이 아니므로 active 로 둔다.
    -- ========================================================
    'customer', jsonb_build_object(
      'name', 'Royalty Accounts',
      'stages', jsonb_build_array(
        jsonb_build_object('n','Onboarding',      'k','active'),
        jsonb_build_object('n','Reporting Cycle', 'k','active'),
        jsonb_build_object('n','Field Expansion', 'k','active'),
        jsonb_build_object('n','At Risk',         'k','active'),
        jsonb_build_object('n','On Hold',         'k','hold'),
        jsonb_build_object('n','Terminated',      'k','lost')))
  );

  v_code  text;
  v_spec  jsonb;
  v_stage jsonb;
  v_idx   int;
BEGIN

  IF v_org = '00000000-0000-0000-0000-000000000000' THEN
    RAISE EXCEPTION 'v_org 를 실제 organization_id 로 교체한 뒤 실행하십시오.';
  END IF;

  FOR v_code, v_spec IN SELECT * FROM jsonb_each(v_specs)
  LOOP
    EXECUTE format('SELECT id FROM %s WHERE %I = $1',
                   v_lookup_table, v_lookup_code_col)
      INTO v_type USING v_code;

    IF v_type IS NULL THEN
      RAISE EXCEPTION
        'party_type 코드 "%" 를 % . % 에서 찾을 수 없습니다. STEP 0-(C) 확인.',
        v_code, v_lookup_table, v_lookup_code_col;
    END IF;

    -- ---- 재실행 방어 ----
    SELECT id INTO v_existing
      FROM app.pipeline_definitions
     WHERE organization_id = v_org
       AND party_type_id   = v_type
       AND is_default
     LIMIT 1;

    IF v_existing IS NOT NULL THEN
      IF NOT v_reseed THEN
        RAISE NOTICE '건너뜀 (이미 존재): % → %', v_code, v_spec ->> 'name';
        CONTINUE;
      END IF;

      -- 재생성 요청이라도 engagement 가 물려 있으면 거부한다.
      -- 스테이지를 지우면 진행 중인 딜의 위치 정보가 사라진다.
      SELECT count(*) INTO v_inuse
        FROM app.engagements e
        JOIN app.pipeline_stages ps ON ps.id = e.pipeline_stage_id
       WHERE ps.pipeline_definition_id = v_existing;

      IF v_inuse > 0 THEN
        RAISE EXCEPTION
          '재생성 거부: % 파이프라인에 engagement %건이 연결되어 있습니다. '
          '수동으로 스테이지를 이관한 뒤 다시 시도하십시오.',
          v_code, v_inuse;
      END IF;

      DELETE FROM app.pipeline_stages      WHERE pipeline_definition_id = v_existing;
      DELETE FROM app.pipeline_definitions WHERE id = v_existing;
      RAISE NOTICE '재생성: %', v_code;
    END IF;

    INSERT INTO app.pipeline_definitions (organization_id, party_type_id, name, is_default)
    VALUES (v_org, v_type, v_spec ->> 'name', true)
    RETURNING id INTO v_pipe;

    v_idx := 0;
    FOR v_stage IN SELECT jsonb_array_elements(v_spec -> 'stages')
    LOOP
      v_idx := v_idx + 1;
      INSERT INTO app.pipeline_stages
        (pipeline_definition_id, name, sort_order, stage_kind, is_terminal)
      VALUES (
        v_pipe, v_stage ->> 'n', v_idx, v_stage ->> 'k',
        (v_stage ->> 'k') IN ('won','lost'));
    END LOOP;

    RAISE NOTICE '생성: % → % (스테이지 %개)', v_code, v_spec ->> 'name', v_idx;
  END LOOP;

END$$;


-- ============================================================
-- 검증
-- ============================================================
-- SELECT pt.code, pd.name AS pipeline, ps.sort_order,
--        ps.name AS stage, ps.stage_kind, ps.is_terminal
--   FROM app.pipeline_definitions pd
--   JOIN app.party_types     pt ON pt.id = pd.party_type_id
--   JOIN app.pipeline_stages ps ON ps.pipeline_definition_id = pd.id
--  ORDER BY pt.code, ps.sort_order;
--
-- 기대: 4개 party_type, 총 29개 stage
--       investor 8 + buyer 8 + partner 7 + customer 6
--       won 스테이지는 investor·buyer 에만 존재 (partner 는 의도적으로 없음)
--
-- 실질 파이프라인 집계:
--   SELECT count(*) FROM app.engagements e
--     JOIN app.pipeline_stages ps ON ps.id = e.pipeline_stage_id
--    WHERE ps.stage_kind = 'active';
--
-- 표시명 변경 (내부 code 는 그대로 두어 FK·코드 영향 없음):
--   UPDATE app.party_types SET name = 'Licensee' WHERE code = 'buyer';
