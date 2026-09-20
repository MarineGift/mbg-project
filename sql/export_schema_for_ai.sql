-- ############################################################
-- HOW TO RUN: Ctrl+A (SELECT ALL), then Run. Copy each result and give it to the other AI.
-- export_schema_for_ai.sql — dumps the app schema + reference codes so another AI
-- can generate ACCURATE SQL (real columns, types, valid party_type/sector/stage codes).
-- Read-only. Safe.
-- ============================================================

-- (1) Columns of the key app tables (table, column, type, nullable, default)
select table_name, column_name, data_type, is_nullable, column_default
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

-- (2) Valid party_type codes + ids
select id, code, display_name_en, is_active from app.party_types order by id;

-- (3) Valid entity_type codes
select id, code from app.entity_types order by id;

-- (4) Valid sector codes (standard + Greentown taxonomy)
select id, code, label_en from app.sectors order by sort_order, id;

-- (5) Valid investment stage codes
select id, code, label_en from app.investment_stages order by sort_order, id;

-- (6) Contact type codes (for creating contacts / email)
select id, code from app.contact_types order by id;

-- (7) Views available in app schema
select table_name as view_name
from information_schema.views
where table_schema = 'app'
order by table_name;

-- (8) RLS policies on the AI-created tables (so it knows the access rules)
select tablename, policyname, cmd, roles::text
from pg_policies
where schemaname = 'app'
  and tablename in ('mentors','party_relationships','email_whitelist')
order by tablename, policyname;
