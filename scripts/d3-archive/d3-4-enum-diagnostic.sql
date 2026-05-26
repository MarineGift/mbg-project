-- =============================================================================
-- D3-4 Enum Migration Diagnostic
-- 목적: app.party_type enum 의 'filler' → 'filler_supplier' 변경 전 의존성 조사
-- 변경: 없음 (read-only)
-- 결과: 6개 쿼리
-- =============================================================================


-- -----------------------------------------------------------------------------
-- [Query 1/6] app.party_type enum 의 현재 값 목록 (확정용)
-- -----------------------------------------------------------------------------
SELECT
    n.nspname        AS schema,
    t.typname        AS enum_name,
    e.enumlabel      AS enum_value,
    e.enumsortorder  AS sort_order
FROM pg_type t
JOIN pg_enum e       ON e.enumtypid    = t.oid
JOIN pg_namespace n  ON n.oid          = t.typnamespace
WHERE t.typname = 'party_type'
  AND n.nspname = 'app'
ORDER BY e.enumsortorder;


-- -----------------------------------------------------------------------------
-- [Query 2/6] app.party_type 을 사용하는 모든 컬럼 (영향 범위 핵심)
-- → 마이그레이션 시 ALTER COLUMN 으로 변환해야 할 컬럼 목록
-- -----------------------------------------------------------------------------
SELECT
    c.table_schema,
    c.table_name,
    c.column_name,
    c.udt_schema || '.' || c.udt_name AS column_type,
    c.column_default,
    c.is_nullable
FROM information_schema.columns c
WHERE c.udt_schema = 'app'
  AND c.udt_name   = 'party_type'
ORDER BY c.table_schema, c.table_name, c.column_name;


-- -----------------------------------------------------------------------------
-- [Query 3/6] 각 의존 컬럼의 'filler' 값 row count
-- → 변환 대상 row 수 확인
-- -----------------------------------------------------------------------------
SELECT 'app.parties' AS tbl, 'party_type' AS col, party_type::text AS val, COUNT(*) AS cnt
FROM app.parties WHERE deleted_at IS NULL
GROUP BY party_type
UNION ALL
SELECT 'app.industry_collections', 'primary_party_type', primary_party_type::text, COUNT(*)
FROM app.industry_collections WHERE deleted_at IS NULL
GROUP BY primary_party_type
ORDER BY tbl, col, val;


-- -----------------------------------------------------------------------------
-- [Query 4/6] app.party_type 을 인자/리턴 타입으로 쓰는 함수
-- → 함수 시그니처 재정의 필요 여부
-- -----------------------------------------------------------------------------
SELECT
    n.nspname        AS schema,
    p.proname        AS function_name,
    pg_get_function_arguments(p.oid) AS arguments,
    pg_get_function_result(p.oid)    AS return_type
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND (
        pg_get_function_arguments(p.oid) ILIKE '%party_type%'
     OR pg_get_function_result(p.oid)    ILIKE '%party_type%'
  )
ORDER BY n.nspname, p.proname;


-- -----------------------------------------------------------------------------
-- [Query 5/6] app.party_type 을 사용하는 뷰/머티뷰
-- → 뷰 정의에서 enum 캐스트 사용 여부
-- -----------------------------------------------------------------------------
SELECT
    schemaname AS schema,
    viewname   AS view_name,
    'VIEW'     AS view_kind
FROM pg_views
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
  AND definition ILIKE '%party_type%'
UNION ALL
SELECT
    schemaname,
    matviewname,
    'MATVIEW'
FROM pg_matviews
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
  AND definition ILIKE '%party_type%'
ORDER BY schema, view_name;


-- -----------------------------------------------------------------------------
-- [Query 6/6] urm 스키마의 enum 목록 (병행 마이그레이션 검토용)
-- → urm 도 같은 패턴이면 같이 변경할지 결정
-- -----------------------------------------------------------------------------
SELECT
    n.nspname        AS schema,
    t.typname        AS enum_name,
    array_agg(e.enumlabel ORDER BY e.enumsortorder) AS enum_values
FROM pg_type t
JOIN pg_enum e       ON e.enumtypid = t.oid
JOIN pg_namespace n  ON n.oid       = t.typnamespace
WHERE n.nspname IN ('urm', 'app')
GROUP BY n.nspname, t.typname
ORDER BY n.nspname, t.typname;


-- =============================================================================
-- 해석 가이드
-- =============================================================================
--
-- Q1 → 현재 enum 값 5개 확정 (investor, paper_mill, partner, customer, filler)
--
-- Q2 → enum 의존 컬럼 (예상: app.parties.party_type,
--                       app.industry_collections.primary_party_type
--                       그 외 발견 시 추가 ALTER 필요)
--
-- Q3 → 변환 대상 row count. 예: parties 229건 + industry_collections N 건
--
-- Q4 → 함수가 enum 타입을 인자로 받는다면 enum DROP/CREATE 사이 함수도 같이 처리해야 함
--      함수가 없으면 마이그레이션 단순
--
-- Q5 → 뷰는 enum 타입을 직접 참조하지 않고 텍스트 캐스트로 사용하는 경우 영향 없음
--      뷰 정의에 ::app.party_type 명시 캐스트가 있으면 enum DROP 시 깨짐
--
-- Q6 → urm 에 같은 enum 있다면 동시 마이그레이션 필요. urm 은 smallint id 기반일 가능성
--      (이전 결과: urm.parties.party_type_id smallint, urm.party_types 마스터 테이블)
--
-- =============================================================================
