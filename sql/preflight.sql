-- ============================================================
-- preflight.sql
-- URM Platform — 014/015/016 실행 전 검증
--
-- Supabase SQL Editor 에 통째로 붙여넣고 한 번 실행한다.
-- 결과 한 표로 모든 판단이 끝난다.
--
-- verdict 열:
--   OK      → 그대로 진행
--   ACTION  → 조치 후 진행
--   BLOCK   → 해결 전까지 실행 금지
-- ============================================================

WITH
-- 1. PostgreSQL 버전 (security_invoker, 부록 A-1 지원 여부)
v_pg AS (
  SELECT current_setting('server_version_num')::int AS num,
         current_setting('server_version')          AS txt
),

-- 2. app.contacts 컬럼
v_contacts AS (
  SELECT
    bool_or(column_name = 'party_id')                              AS has_party_id,
    bool_or(column_name = 'party_id' AND is_nullable = 'NO')       AS party_id_not_null,
    bool_or(column_name = 'contact_name')                          AS has_contact_name,
    string_agg(column_name, ', ' ORDER BY ordinal_position)
      FILTER (WHERE column_name ~* 'name')                         AS name_cols
  FROM information_schema.columns
  WHERE table_schema = 'app' AND table_name = 'contacts'
),

-- 3. app.parties 이름 컬럼
v_parties AS (
  SELECT bool_or(column_name = 'party_name') AS has_party_name
  FROM information_schema.columns
  WHERE table_schema = 'app' AND table_name = 'parties'
),

-- 4. party_type 룩업 테이블
v_lookup AS (
  SELECT ccu.table_schema || '.' || ccu.table_name AS ref_table
  FROM information_schema.table_constraints tc
  JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
   AND tc.table_schema    = kcu.table_schema
  JOIN information_schema.constraint_column_usage ccu
    ON tc.constraint_name = ccu.constraint_name
  WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema    = 'app'
    AND tc.table_name      = 'parties'
    AND kcu.column_name    = 'party_type_id'
  LIMIT 1
),

-- 5. 파이프라인 테이블 컬럼
v_pipe AS (
  SELECT
    bool_or(table_name='pipeline_definitions' AND column_name='party_type_id') AS pd_party_type_id,
    bool_or(table_name='pipeline_definitions' AND column_name='is_default')    AS pd_is_default,
    bool_or(table_name='pipeline_stages'      AND column_name='sort_order')    AS ps_sort_order
  FROM information_schema.columns
  WHERE table_schema='app'
    AND table_name IN ('pipeline_definitions','pipeline_stages')
),

-- 6. 중복 default 파이프라인
v_dupes AS (
  SELECT CASE WHEN to_regclass('app.pipeline_definitions') IS NULL THEN -1 ELSE (
    SELECT count(*)::int FROM (
      SELECT 1 FROM app.pipeline_definitions
       WHERE is_default
       GROUP BY organization_id, party_type_id
      HAVING count(*) > 1
    ) d) END AS n
),

-- 7. engagements 의 스테이지 참조 컬럼 (015 재실행 방어에 필요)
v_eng AS (
  SELECT bool_or(column_name = 'pipeline_stage_id') AS has_stage_fk,
         string_agg(column_name, ', ' ORDER BY ordinal_position)
           FILTER (WHERE column_name ~* 'stage')    AS stage_cols
  FROM information_schema.columns
  WHERE table_schema='app' AND table_name='engagements'
)

SELECT * FROM (
  SELECT 1 AS seq, 'PostgreSQL 버전' AS check_item,
         (SELECT txt FROM v_pg) AS result,
         CASE WHEN (SELECT num FROM v_pg) >= 150000
              THEN 'OK — security_invoker 사용 가능, 부록 A-1 채택'
              ELSE 'ACTION — 뷰에서 security_invoker 제거하고 org 필터 직접 추가, 부록 A-2 채택'
         END AS verdict

  UNION ALL SELECT 2, 'contacts.party_id 존재',
         coalesce((SELECT has_party_id FROM v_contacts)::text, 'contacts 테이블 없음'),
         CASE WHEN (SELECT has_party_id FROM v_contacts)
              THEN 'OK' ELSE 'BLOCK — 부록 A 적용 불가. contact-party 정합성 포기 여부 결정 필요' END

  UNION ALL SELECT 3, 'contacts.party_id NOT NULL',
         coalesce((SELECT party_id_not_null FROM v_contacts)::text, '-'),
         CASE WHEN (SELECT party_id_not_null FROM v_contacts)
              THEN 'OK'
              ELSE 'ACTION — nullable 이면 복합 FK 가 일부 행을 검사하지 않는다. 무소속 contact 존재 여부 확인' END

  UNION ALL SELECT 4, 'contacts 이름 컬럼',
         coalesce((SELECT name_cols FROM v_contacts), '없음'),
         CASE WHEN (SELECT has_contact_name FROM v_contacts)
              THEN 'OK — 016 뷰 그대로 사용'
              ELSE 'ACTION — 016 의 v_pending_introductions 에서 contact_name 을 실제 컬럼명으로 교체' END

  UNION ALL SELECT 5, 'parties.party_name',
         coalesce((SELECT has_party_name FROM v_parties)::text, '-'),
         CASE WHEN (SELECT has_party_name FROM v_parties)
              THEN 'OK' ELSE 'ACTION — 014/016 뷰의 party_name 을 실제 컬럼명으로 교체' END

  UNION ALL SELECT 6, 'party_type 룩업 테이블',
         coalesce((SELECT ref_table FROM v_lookup), '확인 불가'),
         CASE WHEN (SELECT ref_table FROM v_lookup) IS NOT NULL
              THEN 'OK — 015 의 v_lookup_table 에 이 값을 넣을 것'
              ELSE 'BLOCK — parties.party_type_id 의 FK 대상을 수동 확인 필요' END

  UNION ALL SELECT 7, 'pipeline_definitions 컬럼',
         'party_type_id=' || coalesce((SELECT pd_party_type_id FROM v_pipe)::text,'-') ||
         ', is_default='  || coalesce((SELECT pd_is_default FROM v_pipe)::text,'-'),
         CASE WHEN (SELECT pd_party_type_id AND pd_is_default FROM v_pipe)
              THEN 'OK' ELSE 'BLOCK — 015 의 INSERT 컬럼명을 실제 스키마에 맞게 수정' END

  UNION ALL SELECT 8, 'pipeline_stages.sort_order',
         coalesce((SELECT ps_sort_order FROM v_pipe)::text, '-'),
         CASE WHEN (SELECT ps_sort_order FROM v_pipe)
              THEN 'OK' ELSE 'ACTION — position 등 다른 이름이면 015 수정' END

  UNION ALL SELECT 9, '중복 default 파이프라인',
         CASE WHEN (SELECT n FROM v_dupes) < 0 THEN '테이블 없음'
              ELSE (SELECT n FROM v_dupes)::text || '건' END,
         CASE WHEN (SELECT n FROM v_dupes) = 0 THEN 'OK — 유니크 인덱스 생성 가능'
              WHEN (SELECT n FROM v_dupes) < 0 THEN 'BLOCK'
              ELSE 'BLOCK — 정리 후 015 실행. 아래 정리 쿼리 참조' END

  UNION ALL SELECT 10, 'engagements 스테이지 참조',
         coalesce((SELECT stage_cols FROM v_eng), '없음'),
         CASE WHEN (SELECT has_stage_fk FROM v_eng)
              THEN 'OK' ELSE 'ACTION — 015 재실행 방어 블록의 e.pipeline_stage_id 를 실제 컬럼명으로 교체' END
) t
ORDER BY seq;


-- ============================================================
-- 참고 쿼리
-- ============================================================

-- 9번이 0건이 아닐 때 — 중복 default 확인
-- SELECT organization_id, party_type_id, count(*), array_agg(id)
--   FROM app.pipeline_definitions
--  WHERE is_default
--  GROUP BY 1,2 HAVING count(*) > 1;

-- 6번 결과로 나온 룩업 테이블의 실제 코드값
-- SELECT * FROM app.party_types ORDER BY 1;
--   → 'investor','buyer','partner','customer' 가 있는지,
--     코드 컬럼명이 code 인지 name 인지 확인

-- 2번이 false 일 때 — contacts 전체 컬럼
-- SELECT column_name, data_type, is_nullable
--   FROM information_schema.columns
--  WHERE table_schema='app' AND table_name='contacts'
--  ORDER BY ordinal_position;

-- 3번이 false 일 때 — 무소속 contact 존재 여부
-- SELECT count(*) FROM app.contacts WHERE party_id IS NULL;
