-- ============================================================
-- PROBE: discover child tables referencing app.parties / investor_profile
-- (2026-07-04) READ ONLY. Run FIRST and send output back so the merge SQL
-- reparents EXACTLY the right tables (no missed FKs, no guesses).
-- ============================================================

-- (1) every FK column pointing at app.parties(id)
select tc.table_schema, tc.table_name, kcu.column_name, ccu.table_name as ref_table
from information_schema.table_constraints tc
join information_schema.key_column_usage kcu
  on tc.constraint_name = kcu.constraint_name and tc.table_schema = kcu.table_schema
join information_schema.constraint_column_usage ccu
  on tc.constraint_name = ccu.constraint_name and tc.table_schema = ccu.table_schema
where tc.constraint_type = 'FOREIGN KEY'
  and ccu.table_schema = 'app'
  and ccu.table_name in ('parties','investor_profile')
order by ref_table, tc.table_name, kcu.column_name;

-- (2) does app.investor_profile have a UNIQUE(party_id)? (decides whether a
--     merged party can even hold a second profile row) 
select conname, contype, pg_get_constraintdef(oid) as def
from pg_constraint
where conrelid = 'app.investor_profile'::regclass
order by contype;

-- (3) columns on investor_profile (to know what to backfill onto canonical)
select column_name, data_type
from information_schema.columns
where table_schema='app' and table_name='investor_profile'
order by ordinal_position;
