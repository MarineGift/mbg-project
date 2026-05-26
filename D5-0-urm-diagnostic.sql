-- ===========================================================================
-- D5-0 urm.* schema diagnostic
-- Run in Supabase SQL Editor (project: ogenmrgxwhpbfepeldqx)
-- Read-only. No side effects.
--
-- Outputs:
--   - 1 NOTICE block (schema/table summary + row counts)
--   - 7 result sets (parallel tables, columns, FKs, RLS, enums, functions, indexes)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- [1] Schema existence + table summary + row counts (NOTICE)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_schema_exists boolean;
  v_table_count   int;
  v_total_rows    bigint;
  v_rec           record;
BEGIN
  SELECT EXISTS(SELECT 1 FROM information_schema.schemata WHERE schema_name = 'urm')
    INTO v_schema_exists;

  RAISE NOTICE '=== D5-0 urm.* schema diagnostic ===';
  RAISE NOTICE '';
  RAISE NOTICE '[1] schema "urm" exists: %', v_schema_exists;

  IF NOT v_schema_exists THEN
    RAISE NOTICE 'urm schema does not exist yet. Skipping further NOTICE output.';
    RAISE NOTICE 'Result sets below will be empty.';
    RETURN;
  END IF;

  SELECT COUNT(*) INTO v_table_count
    FROM information_schema.tables
    WHERE table_schema = 'urm' AND table_type = 'BASE TABLE';
  RAISE NOTICE '[2] urm BASE TABLE count: %', v_table_count;
  RAISE NOTICE '';
  RAISE NOTICE '[3] urm tables and row counts:';

  FOR v_rec IN
    SELECT table_name FROM information_schema.tables
     WHERE table_schema = 'urm' AND table_type = 'BASE TABLE'
     ORDER BY table_name
  LOOP
    BEGIN
      EXECUTE format('SELECT count(*) FROM urm.%I', v_rec.table_name) INTO v_total_rows;
      RAISE NOTICE '  urm.%-30s : % rows', v_rec.table_name, v_total_rows;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE '  urm.%-30s : ERROR (%)', v_rec.table_name, SQLERRM;
    END;
  END LOOP;

  RAISE NOTICE '';
  RAISE NOTICE '=== Comparison vs app.* below in result sets ===';
END $$;

-- ---------------------------------------------------------------------------
-- [4] Parallel table audit: app.* vs urm.*
-- ---------------------------------------------------------------------------
SELECT
  COALESCE(a.tname, u.tname) AS table_name,
  CASE WHEN a.tname IS NOT NULL THEN 'yes' ELSE '-' END AS in_app,
  CASE WHEN u.tname IS NOT NULL THEN 'yes' ELSE '-' END AS in_urm,
  CASE
    WHEN a.tname IS NOT NULL AND u.tname IS NOT NULL THEN 'both'
    WHEN a.tname IS NOT NULL THEN 'app only'
    ELSE 'urm only'
  END AS status
FROM
  (SELECT table_name AS tname FROM information_schema.tables
     WHERE table_schema = 'app' AND table_type = 'BASE TABLE') a
FULL OUTER JOIN
  (SELECT table_name AS tname FROM information_schema.tables
     WHERE table_schema = 'urm' AND table_type = 'BASE TABLE') u
  ON a.tname = u.tname
ORDER BY COALESCE(a.tname, u.tname);

-- ---------------------------------------------------------------------------
-- [5] urm column details (all columns, all tables)
-- ---------------------------------------------------------------------------
SELECT
  table_name,
  ordinal_position AS pos,
  column_name,
  data_type,
  CASE WHEN udt_schema NOT IN ('pg_catalog','information_schema')
       THEN udt_schema || '.' || udt_name
       ELSE udt_name END AS udt,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'urm'
ORDER BY table_name, ordinal_position;

-- ---------------------------------------------------------------------------
-- [6] urm foreign keys (cross-schema FKs especially relevant)
-- ---------------------------------------------------------------------------
SELECT
  tc.table_name                                  AS source_table,
  kcu.column_name                                AS source_col,
  ccu.table_schema || '.' || ccu.table_name      AS ref_table,
  ccu.column_name                                AS ref_col,
  tc.constraint_name,
  rc.delete_rule,
  rc.update_rule
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
 AND tc.table_schema    = kcu.table_schema
JOIN information_schema.constraint_column_usage ccu
  ON ccu.constraint_name = tc.constraint_name
 AND ccu.table_schema    = tc.table_schema
LEFT JOIN information_schema.referential_constraints rc
  ON rc.constraint_name  = tc.constraint_name
 AND rc.constraint_schema = tc.table_schema
WHERE tc.table_schema = 'urm'
  AND tc.constraint_type = 'FOREIGN KEY'
ORDER BY tc.table_name, kcu.column_name;

-- ---------------------------------------------------------------------------
-- [7] urm RLS policies
-- ---------------------------------------------------------------------------
SELECT
  schemaname || '.' || tablename AS table_ref,
  policyname,
  permissive,
  roles::text                     AS roles,
  cmd,
  qual                            AS using_expr,
  with_check
FROM pg_policies
WHERE schemaname = 'urm'
ORDER BY tablename, policyname;

-- ---------------------------------------------------------------------------
-- [8] urm enums (also list app enums for parallel reference)
-- ---------------------------------------------------------------------------
SELECT
  n.nspname AS schema_name,
  t.typname AS enum_name,
  array_agg(e.enumlabel ORDER BY e.enumsortorder) AS values
FROM pg_type t
JOIN pg_enum e      ON t.oid = e.enumtypid
JOIN pg_namespace n ON n.oid = t.typnamespace
WHERE n.nspname IN ('urm','app')
GROUP BY n.nspname, t.typname
ORDER BY n.nspname, t.typname;

-- ---------------------------------------------------------------------------
-- [9] urm functions
-- ---------------------------------------------------------------------------
SELECT
  p.proname                                       AS function_name,
  pg_get_function_identity_arguments(p.oid)       AS args,
  pg_get_function_result(p.oid)                   AS returns,
  CASE p.prokind WHEN 'f' THEN 'function'
                 WHEN 'p' THEN 'procedure'
                 WHEN 'a' THEN 'aggregate'
                 WHEN 'w' THEN 'window' END       AS kind,
  l.lanname                                       AS language
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
JOIN pg_language  l ON l.oid = p.prolang
WHERE n.nspname = 'urm'
ORDER BY p.proname;

-- ---------------------------------------------------------------------------
-- [10] urm indexes
-- ---------------------------------------------------------------------------
SELECT
  schemaname || '.' || tablename AS table_ref,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'urm'
ORDER BY tablename, indexname;
