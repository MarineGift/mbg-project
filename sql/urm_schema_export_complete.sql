-- ############################################################
-- HOW TO RUN: Ctrl+A (SELECT ALL), then Run the WHOLE file.
-- URM schema/reference export for AI
-- READ ONLY: this file does not INSERT / UPDATE / DELETE anything.
-- ############################################################

-- ============================================================
-- 1. KEY TABLE COLUMNS
-- ============================================================
select
  table_name,
  ordinal_position,
  column_name,
  data_type,
  udt_name,
  is_nullable,
  column_default
from information_schema.columns
where table_schema = 'app'
  and table_name in (
    'parties','party_types','entity_types','contacts','contact_types',
    'investor_profile','investor_stage_focus','investor_sector_focus',
    'investor_interest_tags','interest_tags','investor_types',
    'sectors','investment_stages','party_relationships','mentors',
    'email_whitelist','communications'
  )
order by table_name, ordinal_position;

-- ============================================================
-- 2. PARTY TYPES
-- ============================================================
select id, code, display_name_en, is_active
from app.party_types
order by id;

-- ============================================================
-- 3. ENTITY TYPES
-- ============================================================
select id, code
from app.entity_types
order by id;

-- ============================================================
-- 4. SECTORS
-- ============================================================
select id, code, label_en, sort_order
from app.sectors
order by sort_order nulls last, id;

-- ============================================================
-- 5. INVESTMENT STAGES
-- ============================================================
select id, code, label_en, sort_order
from app.investment_stages
order by sort_order nulls last, id;

-- ============================================================
-- 6. INVESTOR TYPES
-- ============================================================
select *
from app.investor_types
order by id;

-- ============================================================
-- 7. CONTACT TYPES
-- ============================================================
select id, code
from app.contact_types
order by id;

-- ============================================================
-- 8. INTEREST TAGS
-- ============================================================
select *
from app.interest_tags
order by id;

-- ============================================================
-- 9. APP VIEWS
-- ============================================================
select
  table_name as view_name,
  view_definition
from information_schema.views
where table_schema = 'app'
order by table_name;

-- ============================================================
-- 10. RLS STATUS FOR KEY TABLES
-- ============================================================
select
  n.nspname as schema_name,
  c.relname as table_name,
  c.relrowsecurity as rls_enabled,
  c.relforcerowsecurity as force_rls
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'app'
  and c.relkind = 'r'
  and c.relname in (
    'parties','contacts','investor_profile','investor_stage_focus',
    'investor_sector_focus','investor_interest_tags','mentors',
    'party_relationships','email_whitelist','communications'
  )
order by c.relname;

-- ============================================================
-- 11. RLS POLICIES
-- ============================================================
select
  schemaname,
  tablename,
  policyname,
  permissive,
  roles::text,
  cmd,
  qual,
  with_check
from pg_policies
where schemaname = 'app'
  and tablename in (
    'parties','contacts','investor_profile','investor_stage_focus',
    'investor_sector_focus','investor_interest_tags','mentors',
    'party_relationships','email_whitelist','communications'
  )
order by tablename, policyname;

-- ============================================================
-- 12. CONSTRAINTS / FOREIGN KEYS
-- ============================================================
select
  tc.table_name,
  tc.constraint_name,
  tc.constraint_type,
  kcu.column_name,
  ccu.table_name as foreign_table_name,
  ccu.column_name as foreign_column_name
from information_schema.table_constraints tc
left join information_schema.key_column_usage kcu
  on tc.constraint_name = kcu.constraint_name
 and tc.constraint_schema = kcu.constraint_schema
left join information_schema.constraint_column_usage ccu
  on tc.constraint_name = ccu.constraint_name
 and tc.constraint_schema = ccu.constraint_schema
where tc.table_schema = 'app'
  and tc.table_name in (
    'parties','party_types','entity_types','contacts','contact_types',
    'investor_profile','investor_stage_focus','investor_sector_focus',
    'investor_interest_tags','interest_tags','investor_types',
    'sectors','investment_stages','party_relationships','mentors',
    'email_whitelist','communications'
  )
order by tc.table_name, tc.constraint_type, tc.constraint_name, kcu.ordinal_position;

-- ============================================================
-- 13. INDEXES
-- ============================================================
select
  tablename,
  indexname,
  indexdef
from pg_indexes
where schemaname = 'app'
  and tablename in (
    'parties','contacts','investor_profile','investor_stage_focus',
    'investor_sector_focus','investor_interest_tags','mentors',
    'party_relationships','email_whitelist','communications'
  )
order by tablename, indexname;

-- ============================================================
-- 14. TRIGGERS
-- ============================================================
select
  event_object_table as table_name,
  trigger_name,
  event_manipulation,
  action_timing,
  action_statement
from information_schema.triggers
where trigger_schema = 'app'
order by event_object_table, trigger_name, event_manipulation;

-- ============================================================
-- 15. VERIFY SINGLE-ORG / GREENTOWN REFERENCES
-- ============================================================
select
  id,
  party_name,
  party_type_id,
  organization_id,
  deleted_at
from app.parties
where deleted_at is null
  and (
    lower(party_name) like '%greentown%'
    or organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  )
order by party_name
limit 100;
