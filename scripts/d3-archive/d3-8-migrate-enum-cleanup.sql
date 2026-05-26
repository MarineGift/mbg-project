-- =============================================================================
-- D3-8 Migration: app.party_type enum 6 deprecated 값 제거
-- 제거 대상: filler, crowdfunding, product_launch, sales, government_grant, buyer
-- 유지 (5개): investor, paper_mill, partner, customer, filler_supplier
-- 영향:
--   - ai.brand_voice 의 18 row DELETE (각 6개씩 3개 deprecated 값)
--   - 12개 컬럼 ALTER TYPE
--   - 8개 VIEW DROP/CREATE
-- 안전 장치: 단일 트랜잭션, POST-CHECK 실패 시 자동 ROLLBACK
-- =============================================================================

BEGIN;

-- ===========================================================================
-- [1/7] ai.brand_voice 의 deprecated row 18개 DELETE
-- ===========================================================================
DELETE FROM ai.brand_voice
WHERE module::text IN ('crowdfunding', 'product_launch', 'sales',
                       'filler', 'government_grant', 'buyer');


-- ===========================================================================
-- [2/7] 8개 VIEW DROP (의존성 순서: 참조하는 것 먼저)
-- ===========================================================================
DROP VIEW IF EXISTS app.v_person_dedup_candidates;
DROP VIEW IF EXISTS app.v_party_dedup_candidates;
DROP VIEW IF EXISTS app.v_filler_suppliers;
DROP VIEW IF EXISTS app.v_firm_alumni;
DROP VIEW IF EXISTS app.v_investor_outreach_list;
DROP VIEW IF EXISTS app.v_investor_with_partners;
DROP VIEW IF EXISTS app.v_paper_mills;
DROP VIEW IF EXISTS app.v_person_career_history;


-- ===========================================================================
-- [3/7] 새 enum 생성 (5개 값만)
-- ===========================================================================
CREATE TYPE app.party_type_v2 AS ENUM (
    'investor',
    'paper_mill',
    'partner',
    'customer',
    'filler_supplier'
);


-- ===========================================================================
-- [4/7] 12개 컬럼 ALTER TYPE (deprecated row 없으므로 단순 캐스트)
-- ===========================================================================
ALTER TABLE ai.brand_voice
    ALTER COLUMN module TYPE app.party_type_v2
    USING module::text::app.party_type_v2;

ALTER TABLE ai.drafts
    ALTER COLUMN module TYPE app.party_type_v2
    USING module::text::app.party_type_v2;

ALTER TABLE app.communications
    ALTER COLUMN party_type TYPE app.party_type_v2
    USING party_type::text::app.party_type_v2;

ALTER TABLE app.consultations
    ALTER COLUMN party_type TYPE app.party_type_v2
    USING party_type::text::app.party_type_v2;

ALTER TABLE app.custom_field_definitions
    ALTER COLUMN party_type TYPE app.party_type_v2
    USING party_type::text::app.party_type_v2;

ALTER TABLE app.engagements
    ALTER COLUMN party_type TYPE app.party_type_v2
    USING party_type::text::app.party_type_v2;

ALTER TABLE app.industry_collections
    ALTER COLUMN primary_party_type TYPE app.party_type_v2
    USING primary_party_type::text::app.party_type_v2;

ALTER TABLE app.parties
    ALTER COLUMN party_type TYPE app.party_type_v2
    USING party_type::text::app.party_type_v2;

ALTER TABLE app.person_firm_history
    ALTER COLUMN party_type TYPE app.party_type_v2
    USING party_type::text::app.party_type_v2;

ALTER TABLE app.pipelines
    ALTER COLUMN party_type TYPE app.party_type_v2
    USING party_type::text::app.party_type_v2;

ALTER TABLE app.response_strategies
    ALTER COLUMN party_type TYPE app.party_type_v2
    USING party_type::text::app.party_type_v2;

ALTER TABLE app.tasks
    ALTER COLUMN party_type TYPE app.party_type_v2
    USING party_type::text::app.party_type_v2;


-- ===========================================================================
-- [5/7] 옛 enum DROP, 새 enum RENAME
-- ===========================================================================
DROP TYPE app.party_type;
ALTER TYPE app.party_type_v2 RENAME TO party_type;


-- ===========================================================================
-- [6/7] 8개 VIEW CREATE (definition 그대로 복원)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- 6.1 v_filler_suppliers
-- ---------------------------------------------------------------------------
CREATE VIEW app.v_filler_suppliers AS
 SELECT p.id AS firm_id,
    p.name AS firm_name,
    p.country_code,
    p.website,
    p.linkedin_url,
    p.industry_tags,
    p.interest_tags,
    p.relationship_score,
    p.party_type AS firm_module,
    p.parent_party_id,
    parent.name AS parent_name,
    fsp.supplier_type,
    fsp.market_role,
    fsp.supply_model,
    fsp.onsite_pcc_evidence,
    fsp.evidence_level,
    fsp.industry_source,
    fsp.auto_promoted_at,
    ((fsp.supplier_type IS NOT NULL) AND (fsp.market_role IS NOT NULL) AND (fsp.supply_model IS NOT NULL)) AS has_full_supplier_data,
    (fsp.onsite_pcc_evidence IS NOT NULL) AS has_pcc_evidence,
    fsp.id AS profile_id,
    fsp.created_at AS profile_created_at,
    fsp.updated_at AS profile_updated_at,
    p.organization_id
   FROM ((app.parties p
     JOIN app.filler_supplier_profile fsp ON ((fsp.party_id = p.id)))
     LEFT JOIN app.parties parent ON ((parent.id = p.parent_party_id)))
  WHERE ((p.deleted_at IS NULL) AND (fsp.deleted_at IS NULL))
  ORDER BY p.name;

-- ---------------------------------------------------------------------------
-- 6.2 v_firm_alumni
-- ---------------------------------------------------------------------------
CREATE VIEW app.v_firm_alumni AS
 SELECT h.firm_party_id,
    firm.name AS firm_name,
    firm.party_type AS firm_module,
    h.person_party_id,
    person.name AS person_name,
    person.linkedin_url AS person_linkedin,
    h.title_text,
    h.role_category,
    h.joined_at,
    h.left_at,
        CASE
            WHEN (h.left_at IS NULL) THEN 'current'::text
            ELSE 'alumni'::text
        END AS tenure_status,
    current_h.firm_party_id AS current_firm_id,
    current_firm.name AS current_firm_name,
    current_h.title_text AS current_title,
    h.organization_id
   FROM ((((app.person_firm_history h
     JOIN app.parties firm ON ((firm.id = h.firm_party_id)))
     JOIN app.parties person ON ((person.id = h.person_party_id)))
     LEFT JOIN LATERAL ( SELECT person_firm_history.firm_party_id,
            person_firm_history.title_text
           FROM app.person_firm_history
          WHERE ((person_firm_history.person_party_id = h.person_party_id) AND (person_firm_history.left_at IS NULL) AND (person_firm_history.is_primary = true) AND (person_firm_history.deleted_at IS NULL))
         LIMIT 1) current_h ON (true))
     LEFT JOIN app.parties current_firm ON ((current_firm.id = current_h.firm_party_id)))
  WHERE ((h.deleted_at IS NULL) AND (firm.deleted_at IS NULL) AND (person.deleted_at IS NULL))
  ORDER BY h.firm_party_id, h.joined_at DESC;

-- ---------------------------------------------------------------------------
-- 6.3 v_investor_outreach_list
-- ---------------------------------------------------------------------------
CREATE VIEW app.v_investor_outreach_list AS
 SELECT f.id AS firm_id,
    f.name AS firm_name,
    f.website AS firm_website,
    f.city,
    f.region,
    f.country_code,
    f.industry_tags AS firm_tags,
    f.interest_tags AS firm_interests,
    f.founded_year AS firm_founded,
    ip.subtype AS firm_subtype,
    ip.aum_usd AS firm_aum_usd,
    ip.fund_size_usd AS firm_fund_size_usd,
    ip.investment_stages AS firm_stages,
    ip.sector_focus AS firm_sectors,
    p.id AS partner_id,
    p.name AS partner_name,
    p.linkedin_url AS partner_linkedin,
    pp.title_text AS partner_title,
    pp.seniority_level AS partner_seniority,
    pp.is_decision_maker AS partner_is_decision_maker,
    pp.email AS partner_email,
    pp.focus_areas AS partner_focus,
    pp.background AS partner_background
   FROM (((app.parties f
     LEFT JOIN app.investor_profile ip ON ((ip.party_id = f.id)))
     LEFT JOIN app.parties p ON (((p.parent_party_id = f.id) AND (p.party_kind = 'individual'::app.party_kind) AND (p.party_type = 'investor'::app.party_type))))
     LEFT JOIN app.investor_partner_profile pp ON ((pp.party_id = p.id)))
  WHERE ((f.party_type = 'investor'::app.party_type) AND (f.party_kind = ANY (ARRAY['company'::app.party_kind, 'fund'::app.party_kind, 'organization'::app.party_kind])) AND (f.parent_party_id IS NULL) AND (f.deleted_at IS NULL))
  ORDER BY ('direct_fit'::text = ANY (f.interest_tags)) DESC, ('austin'::text = ANY (f.interest_tags)) DESC, pp.is_decision_maker DESC, pp.seniority_level, f.name, p.name;

-- ---------------------------------------------------------------------------
-- 6.4 v_investor_with_partners
-- ---------------------------------------------------------------------------
CREATE VIEW app.v_investor_with_partners AS
 SELECT f.id AS firm_id,
    f.name AS firm_name,
    f.website AS firm_website,
    ((f.city || ', '::text) || COALESCE(f.region, ''::text)) AS firm_hq,
    ((f.module_data ->> 'aum_usd_billions'::text))::numeric AS firm_aum_b,
    f.interest_tags AS firm_tags,
    p.id AS partner_id,
    p.name AS partner_name,
    (p.module_data ->> 'title'::text) AS partner_title,
    p.linkedin_url AS partner_linkedin,
    (p.module_data ->> 'email'::text) AS partner_email,
    (p.module_data -> 'focus_areas'::text) AS partner_focus,
    (p.module_data ->> 'background'::text) AS partner_background
   FROM (app.parties f
     LEFT JOIN app.parties p ON (((p.parent_party_id = f.id) AND (p.party_kind = 'individual'::app.party_kind) AND (p.party_type = 'investor'::app.party_type))))
  WHERE ((f.party_type = 'investor'::app.party_type) AND (f.parent_party_id IS NULL))
  ORDER BY f.name, p.name;

-- ---------------------------------------------------------------------------
-- 6.5 v_paper_mills
-- ---------------------------------------------------------------------------
CREATE VIEW app.v_paper_mills AS
 SELECT p.id,
    p.organization_id,
    p.name,
    p.legal_name,
    p.country_code,
    p.region,
    p.city,
    p.address,
    p.timezone,
    p.website,
    p.domain_normalized,
    p.linkedin_url,
    p.industry_tags,
    p.interest_tags,
    p.employee_count,
    p.annual_revenue_usd,
    p.tier,
    p.status,
    p.relationship_score,
    p.owner_user_id,
    p.owner_team_id,
    p.source,
    p.source_external_id,
    p.module_data AS party_module_data,
    pmp.main_product_category,
    pmp.main_products,
    pmp.headquarters,
    pmp.filler_use_intensity,
    pmp.europe_mills_footprint,
    pmp.evidence_level,
    pmp.industry_source,
    pmp.auto_promoted_at,
    pmp.module_data AS profile_module_data,
    ( SELECT count(*) AS count
           FROM app.party_supply_links psl
          WHERE ((psl.mill_party_id = p.id) AND (psl.deleted_at IS NULL) AND (psl.supply_type = 'active'::app.supply_link_type))) AS active_supplier_count,
    ( SELECT count(*) AS count
           FROM app.party_supply_links psl
          WHERE ((psl.mill_party_id = p.id) AND (psl.deleted_at IS NULL) AND (psl.supply_type = 'potential'::app.supply_link_type))) AS potential_supplier_count,
    ( SELECT count(*) AS count
           FROM app.party_supply_links psl
          WHERE ((psl.mill_party_id = p.id) AND (psl.deleted_at IS NULL) AND (psl.supply_type = 'historical'::app.supply_link_type))) AS historical_supplier_count,
    p.created_at,
    p.updated_at,
    p.deleted_at,
    pmp.created_at AS profile_created_at,
    pmp.updated_at AS profile_updated_at
   FROM (app.parties p
     LEFT JOIN app.paper_mill_profile pmp ON (((pmp.party_id = p.id) AND (pmp.deleted_at IS NULL))))
  WHERE ((p.party_type = 'paper_mill'::app.party_type) AND (p.deleted_at IS NULL));

-- ---------------------------------------------------------------------------
-- 6.6 v_party_dedup_candidates  (v_person_dedup_candidates 가 참조 — 먼저 생성)
-- ---------------------------------------------------------------------------
CREATE VIEW app.v_party_dedup_candidates AS
 WITH RECURSIVE party_roots AS (
         SELECT parties.id,
            parties.id AS root_id,
            0 AS depth
           FROM app.parties
          WHERE ((parties.deleted_at IS NULL) AND (parties.parent_party_id IS NULL))
        UNION ALL
         SELECT p.id,
            pr.root_id,
            (pr.depth + 1)
           FROM (app.parties p
             JOIN party_roots pr ON ((p.parent_party_id = pr.id)))
          WHERE ((p.deleted_at IS NULL) AND (pr.depth < 5))
        )
 SELECT LEAST(a.id, b.id) AS party_a,
    GREATEST(a.id, b.id) AS party_b,
        CASE
            WHEN (a.id < b.id) THEN a.name
            ELSE b.name
        END AS name_a,
        CASE
            WHEN (a.id < b.id) THEN b.name
            ELSE a.name
        END AS name_b,
        CASE
            WHEN (a.id < b.id) THEN a.country_code
            ELSE b.country_code
        END AS country_a,
        CASE
            WHEN (a.id < b.id) THEN b.country_code
            ELSE a.country_code
        END AS country_b,
    a.party_kind AS party_type,
    a.party_type AS module,
    GREATEST(
        CASE
            WHEN ((a.name_normalized IS NOT NULL) AND (b.name_normalized IS NOT NULL)) THEN similarity(a.name_normalized, b.name_normalized)
            ELSE (0)::real
        END,
        CASE
            WHEN ((a.phone_normalized IS NOT NULL) AND (a.phone_normalized = b.phone_normalized)) THEN (1.0)::real
            ELSE (0)::real
        END) AS similarity_score,
        CASE
            WHEN ((a.phone_normalized IS NOT NULL) AND (a.phone_normalized = b.phone_normalized) AND (a.name_normalized IS NOT NULL) AND (b.name_normalized IS NOT NULL) AND (similarity(a.name_normalized, b.name_normalized) >= (0.5)::double precision)) THEN 'both'::text
            WHEN ((a.phone_normalized IS NOT NULL) AND (a.phone_normalized = b.phone_normalized)) THEN 'phone_exact'::text
            ELSE 'name_trgm'::text
        END AS match_kind,
    a.parent_party_id AS a_parent_id,
    b.parent_party_id AS b_parent_id,
    ra.root_id AS a_root_id,
    rb.root_id AS b_root_id
   FROM (((app.parties a
     JOIN app.parties b ON (((a.id < b.id) AND (a.deleted_at IS NULL) AND (b.deleted_at IS NULL) AND (a.party_kind = b.party_kind) AND (a.party_type = b.party_type) AND (((a.name_normalized IS NOT NULL) AND (b.name_normalized IS NOT NULL) AND (a.name_normalized % b.name_normalized) AND (similarity(a.name_normalized, b.name_normalized) >= (0.5)::double precision)) OR ((a.phone_normalized IS NOT NULL) AND (a.phone_normalized = b.phone_normalized))))))
     LEFT JOIN party_roots ra ON ((ra.id = a.id)))
     LEFT JOIN party_roots rb ON ((rb.id = b.id)))
  WHERE ((NOT ((a.parent_party_id IS NOT NULL) AND (a.parent_party_id = b.parent_party_id))) AND (a.parent_party_id IS DISTINCT FROM b.id) AND (b.parent_party_id IS DISTINCT FROM a.id) AND ((ra.root_id IS NULL) OR (rb.root_id IS NULL) OR (ra.root_id <> rb.root_id)));

-- ---------------------------------------------------------------------------
-- 6.7 v_person_career_history
-- ---------------------------------------------------------------------------
CREATE VIEW app.v_person_career_history AS
 SELECT h.id AS history_id,
    h.person_party_id,
    person.name AS person_name,
    person.linkedin_url AS person_linkedin,
    h.firm_party_id,
    firm.name AS firm_name,
    firm.website AS firm_website,
    firm.party_type AS firm_module,
    h.title_text,
    h.seniority_level,
    h.role_category,
    h.party_type AS context_module,
    h.joined_at,
    h.left_at,
        CASE
            WHEN (h.left_at IS NULL) THEN '현재'::text
            ELSE 'past'::text
        END AS status,
    h.is_primary,
    h.is_decision_maker,
        CASE
            WHEN (h.left_at IS NULL) THEN (EXTRACT(year FROM age((CURRENT_DATE)::timestamp with time zone, (h.joined_at)::timestamp with time zone)))::integer
            ELSE (EXTRACT(year FROM age((h.left_at)::timestamp with time zone, (h.joined_at)::timestamp with time zone)))::integer
        END AS years_at_firm,
    h.source,
    h.notes,
    h.organization_id
   FROM ((app.person_firm_history h
     JOIN app.parties person ON ((person.id = h.person_party_id)))
     JOIN app.parties firm ON ((firm.id = h.firm_party_id)))
  WHERE ((h.deleted_at IS NULL) AND (person.deleted_at IS NULL) AND (firm.deleted_at IS NULL))
  ORDER BY h.person_party_id, h.joined_at DESC;

-- ---------------------------------------------------------------------------
-- 6.8 v_person_dedup_candidates  (v_party_dedup_candidates 참조 — 나중에 생성)
-- ---------------------------------------------------------------------------
CREATE VIEW app.v_person_dedup_candidates AS
 SELECT party_a,
    party_b,
    name_a,
    name_b,
    country_a,
    country_b,
    party_type,
    module,
    similarity_score,
    match_kind,
    a_parent_id,
    b_parent_id,
    a_root_id,
    b_root_id
   FROM app.v_party_dedup_candidates
  WHERE (party_type = 'individual'::app.party_kind);


-- ===========================================================================
-- [7/7] POST-CHECK 검증
-- ===========================================================================
DO $$
DECLARE
    enum_count        integer;
    view_count        integer;
    deprecated_count  integer;
BEGIN
    -- enum 값 수
    SELECT COUNT(*) INTO enum_count
    FROM pg_type t
    JOIN pg_enum e ON e.enumtypid = t.oid
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE t.typname = 'party_type' AND n.nspname = 'app';

    IF enum_count != 5 THEN
        RAISE EXCEPTION '검증 실패: enum 값 수 = % (예상 5). ROLLBACK.', enum_count;
    END IF;

    -- VIEW 8개 재생성 확인
    SELECT COUNT(*) INTO view_count
    FROM pg_views
    WHERE schemaname = 'app'
      AND viewname IN (
        'v_filler_suppliers', 'v_firm_alumni', 'v_investor_outreach_list',
        'v_investor_with_partners', 'v_paper_mills', 'v_party_dedup_candidates',
        'v_person_career_history', 'v_person_dedup_candidates'
      );

    IF view_count != 8 THEN
        RAISE EXCEPTION '검증 실패: VIEW 수 = % (예상 8). ROLLBACK.', view_count;
    END IF;

    -- ai.brand_voice 잔여 deprecated 값 없음 확인
    SELECT COUNT(*) INTO deprecated_count
    FROM ai.brand_voice;

    RAISE NOTICE '';
    RAISE NOTICE '=== D3-8 마이그레이션 성공 ===';
    RAISE NOTICE '  enum 값          : 5개 (investor, paper_mill, partner, customer, filler_supplier)';
    RAISE NOTICE '  ai.brand_voice   : % rows (남은 5개 값만)', deprecated_count;
    RAISE NOTICE '  VIEW 재생성      : 8개';
    RAISE NOTICE '';
END $$;


COMMIT;


-- =============================================================================
-- 사후 확인 쿼리 (선택, 별도 실행)
-- =============================================================================
-- 1) enum 값 확인
-- SELECT enumlabel FROM pg_enum e
-- JOIN pg_type t ON t.oid = e.enumtypid
-- JOIN pg_namespace n ON n.oid = t.typnamespace
-- WHERE t.typname = 'party_type' AND n.nspname = 'app'
-- ORDER BY enumsortorder;
--
-- 2) parties 분포
-- SELECT party_type::text, COUNT(*) FROM app.parties
-- WHERE deleted_at IS NULL GROUP BY party_type ORDER BY party_type;
--
-- 3) ai.brand_voice 분포
-- SELECT module::text, COUNT(*) FROM ai.brand_voice
-- GROUP BY module ORDER BY module;
-- =============================================================================
