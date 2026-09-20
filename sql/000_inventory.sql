-- ============================================================
-- 000_inventory.sql
-- URM Platform — 실제 스키마 전수 조사
--
-- 이 스크립트는 카탈로그(information_schema, pg_catalog)만 조회한다.
-- app 스키마의 테이블을 직접 참조하지 않으므로, 테이블이 하나도
-- 없어도 파싱·실행 모두 실패하지 않는다.
--
-- 앞서 preflight.sql 이 실패한 이유가 이것이다.
-- to_regclass 로 감싸도 CASE 안의 SELECT 는 파싱 단계에서
-- 관계 해석이 일어나므로, 존재하지 않는 테이블을 문장에 적으면
-- 실행 전에 42P01 로 죽는다.
--
-- Supabase SQL Editor 에 통째로 붙여넣고 실행한 뒤
-- 결과 전체를 복사해 주십시오.
-- ============================================================

WITH

-- ── 1. 서버 정보 ─────────────────────────────────────────
s_version AS (
  SELECT
    1 AS section, 'server' AS category,
    'version' AS item,
    current_setting('server_version') AS detail,
    CASE WHEN current_setting('server_version_num')::int >= 150000
         THEN 'PG15+ : security_invoker 및 컬럼지정 SET NULL 사용 가능'
         ELSE 'PG15 미만 : 뷰 org 필터 직접 추가 + 트리거 방식 필요'
    END AS note
),

-- ── 2. 존재하는 스키마 ───────────────────────────────────
s_schemas AS (
  SELECT
    2, 'schema', nspname,
    (SELECT count(*)::text FROM pg_class c
      WHERE c.relnamespace = n.oid AND c.relkind = 'r') || ' tables',
    ''
  FROM pg_namespace n
  WHERE nspname NOT LIKE 'pg\_%'
    AND nspname NOT IN ('information_schema')
),

-- ── 3. 테이블 목록 (app 및 유사 스키마) ──────────────────
s_tables AS (
  SELECT
    3, 'table',
    n.nspname || '.' || c.relname,
    CASE c.relkind WHEN 'r' THEN 'table' WHEN 'v' THEN 'view'
                   WHEN 'm' THEN 'matview' WHEN 'p' THEN 'partitioned'
                   ELSE c.relkind::text END
      || ' / rows~' || greatest(c.reltuples,0)::bigint::text,
    CASE WHEN c.relrowsecurity THEN 'RLS ON' ELSE 'RLS off' END
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE c.relkind IN ('r','v','m','p')
    AND n.nspname NOT LIKE 'pg\_%'
    AND n.nspname NOT IN ('information_schema','extensions','graphql','graphql_public','net','vault','pgbouncer','realtime','storage','supabase_migrations','supabase_functions','cron')
),

-- ── 4. 컬럼 (핵심 테이블만) ──────────────────────────────
s_columns AS (
  SELECT
    4, 'column',
    table_schema || '.' || table_name || '.' || column_name,
    data_type || CASE WHEN is_nullable = 'NO' THEN ' NOT NULL' ELSE '' END,
    coalesce(column_default, '')
  FROM information_schema.columns
  WHERE table_schema NOT LIKE 'pg\_%'
    AND table_schema NOT IN ('information_schema','extensions','graphql','graphql_public','net','vault','pgbouncer','realtime','storage','supabase_migrations','supabase_functions','cron')
    AND table_name ~* '(part(y|ies)|contact|organization|engagement|pipeline|stage|communication|task|user|document|attachment|module|type)'
),

-- ── 5. 외래키 ────────────────────────────────────────────
s_fks AS (
  SELECT
    5, 'fk',
    con.conrelid::regclass::text || '.' ||
      (SELECT string_agg(a.attname, ',' ORDER BY x.ord)
         FROM unnest(con.conkey) WITH ORDINALITY AS x(attnum, ord)
         JOIN pg_attribute a ON a.attrelid = con.conrelid AND a.attnum = x.attnum),
    '→ ' || con.confrelid::regclass::text || '.' ||
      (SELECT string_agg(a.attname, ',' ORDER BY x.ord)
         FROM unnest(con.confkey) WITH ORDINALITY AS x(attnum, ord)
         JOIN pg_attribute a ON a.attrelid = con.confrelid AND a.attnum = x.attnum),
    con.conname
  FROM pg_constraint con
  JOIN pg_class c ON c.oid = con.conrelid
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE con.contype = 'f'
    AND n.nspname NOT LIKE 'pg\_%'
    AND n.nspname NOT IN ('information_schema','extensions','storage','realtime','auth')
),

-- ── 6. ENUM 타입 ─────────────────────────────────────────
s_enums AS (
  SELECT
    6, 'enum',
    n.nspname || '.' || t.typname,
    string_agg(e.enumlabel, ', ' ORDER BY e.enumsortorder),
    ''
  FROM pg_type t
  JOIN pg_namespace n ON n.oid = t.typnamespace
  JOIN pg_enum e ON e.enumtypid = t.oid
  WHERE n.nspname NOT LIKE 'pg\_%'
    AND n.nspname NOT IN ('information_schema')
  GROUP BY n.nspname, t.typname
),

-- ── 7. 확장 ──────────────────────────────────────────────
s_ext AS (
  SELECT 7, 'extension', extname, extversion, ''
  FROM pg_extension
)

SELECT section, category, item, detail, note
FROM (
  SELECT * FROM s_version
  UNION ALL SELECT * FROM s_schemas
  UNION ALL SELECT * FROM s_tables
  UNION ALL SELECT * FROM s_columns
  UNION ALL SELECT * FROM s_fks
  UNION ALL SELECT * FROM s_enums
  UNION ALL SELECT * FROM s_ext
) x
ORDER BY section, category, item;


-- ============================================================
-- 마이그레이션 이력은 별도로 실행하십시오.
-- supabase_migrations 스키마가 없는 프로젝트도 있어
-- 위 쿼리에 넣으면 같은 42P01 문제가 재발합니다.
--
--   SELECT version, name FROM supabase_migrations.schema_migrations
--    ORDER BY version;
-- ============================================================
