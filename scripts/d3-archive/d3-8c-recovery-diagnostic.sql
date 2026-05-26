-- =============================================================================
-- D3-8c Recovery Diagnostic
-- 목적: half-migrated 상태 복구 마이그레이션 작성을 위한 추가 정보 수집
-- 변경: 없음 (read-only)
-- 결과: 4개 쿼리
-- =============================================================================


-- -----------------------------------------------------------------------------
-- [Q1] 3개 함수 정의 추출
--      복구 마이그레이션에서 DROP → CREATE 시 이 정의 그대로 사용
-- -----------------------------------------------------------------------------
SELECT
    n.nspname        AS schema,
    p.proname        AS function_name,
    pg_get_function_arguments(p.oid) AS arguments,
    pg_get_functiondef(p.oid)        AS definition
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname IN ('app', 'ai')
  AND p.proname IN (
        'find_similar_parties',
        'find_similar_persons',
        'fn_pick_meeting_engagement_kind'
      )
ORDER BY n.nspname, p.proname;


-- -----------------------------------------------------------------------------
-- [Q2] 5개 array 컬럼의 deprecated 값 분포
--      ALTER COLUMN 전에 deprecated 값이 array element 안에 있는지 확인
-- -----------------------------------------------------------------------------
WITH unnested AS (
    SELECT 'app.organizations.allowed_modules' AS source,
           unnest(allowed_modules)::text AS val
    FROM app.organizations
    WHERE allowed_modules IS NOT NULL

    UNION ALL
    SELECT 'app.teams.focus_modules',
           unnest(focus_modules)::text
    FROM app.teams
    WHERE focus_modules IS NOT NULL

    UNION ALL
    SELECT 'app.template_categories.applicable_modules',
           unnest(applicable_modules)::text
    FROM app.template_categories
    WHERE applicable_modules IS NOT NULL

    UNION ALL
    SELECT 'ai.agents.applicable_modules',
           unnest(applicable_modules)::text
    FROM ai.agents
    WHERE applicable_modules IS NOT NULL

    UNION ALL
    SELECT 'ai.auto_send_rules.allowed_modules',
           unnest(allowed_modules)::text
    FROM ai.auto_send_rules
    WHERE allowed_modules IS NOT NULL
)
SELECT
    source,
    val               AS enum_value,
    COUNT(*)          AS occurrences,
    CASE
        WHEN val IN ('filler', 'crowdfunding', 'product_launch',
                     'sales', 'government_grant', 'buyer')
            THEN 'DEPRECATED — needs removal'
        ELSE 'ok'
    END AS status
FROM unnested
GROUP BY source, val
ORDER BY source, val;


-- -----------------------------------------------------------------------------
-- [Q3] 현재 enum 상태 확인 (옛 + 새 공존)
-- -----------------------------------------------------------------------------
SELECT
    n.nspname || '.' || t.typname AS enum_full_name,
    array_agg(e.enumlabel ORDER BY e.enumsortorder) AS enum_values,
    COUNT(*) AS value_count
FROM pg_type t
JOIN pg_enum e       ON e.enumtypid = t.oid
JOIN pg_namespace n  ON n.oid       = t.typnamespace
WHERE n.nspname = 'app'
  AND t.typname IN ('party_type', 'party_type_v2')
GROUP BY n.nspname, t.typname
ORDER BY t.typname;


-- -----------------------------------------------------------------------------
-- [Q4] 현재 존재하는 VIEW 확인 (누락된 3개 식별)
-- -----------------------------------------------------------------------------
SELECT
    viewname,
    'exists' AS status
FROM pg_views
WHERE schemaname = 'app'
  AND viewname IN (
        'v_filler_suppliers',
        'v_firm_alumni',
        'v_investor_outreach_list',
        'v_investor_with_partners',
        'v_paper_mills',
        'v_party_dedup_candidates',
        'v_person_career_history',
        'v_person_dedup_candidates'
      )

UNION ALL

SELECT
    expected_name,
    'MISSING' AS status
FROM (VALUES
    ('v_filler_suppliers'),
    ('v_firm_alumni'),
    ('v_investor_outreach_list'),
    ('v_investor_with_partners'),
    ('v_paper_mills'),
    ('v_party_dedup_candidates'),
    ('v_person_career_history'),
    ('v_person_dedup_candidates')
) AS expected(expected_name)
WHERE expected_name NOT IN (
    SELECT viewname FROM pg_views WHERE schemaname = 'app'
)

ORDER BY viewname;
