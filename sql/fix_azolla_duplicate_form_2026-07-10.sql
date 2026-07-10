-- ============================================================
-- fix_azolla_duplicate_form_2026-07-10.sql
-- The P1 field-seed VERIFY interleaved TWO field sets - a legacy
-- generic 15-field Azolla form (drafting, resynced by FIX B
-- earlier today) coexists with the new P1 typeform row. Azolla
-- accepts submissions only through the typeform, and every
-- answer on the legacy sheet is a copy of answer_library, so the
-- legacy row is deleted (fields and answers cascade).
--
-- DIAG A first - eyeball it, then B deletes. B is guarded to
-- never touch the typeform row or anything submitted/decided.
-- Skip statement B if you want to keep the legacy sheet instead.
--
-- Supabase SQL Editor safe: no do-blocks, no temp tables,
-- no semicolons inside string literals
-- ============================================================

-- ------------------------------------------------------------
-- DIAG A: every Azolla form with field count (expect 2 rows -
-- the typeform row with 10 fields and the legacy row with 15)
-- ------------------------------------------------------------
select f.id, f.form_url, f.form_type, f.status, f.cycle_label,
       f.created_at::date as created,
       count(ff.id) as field_count
from app.application_forms f
join app.parties pt on pt.id = f.party_id
left join app.application_form_fields ff on ff.form_id = f.id
where f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and pt.party_name ilike '%azolla%'
group by f.id, f.form_url, f.form_type, f.status, f.cycle_label, f.created_at
order by f.created_at;


-- ------------------------------------------------------------
-- B: delete the legacy Azolla form (guards - keeps the typeform
-- row, never deletes submitted or decided forms)
-- ------------------------------------------------------------
delete from app.application_forms f
using app.parties pt
where pt.id = f.party_id
  and f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and pt.party_name ilike '%azolla%'
  and f.form_url <> 'https://azollaventures.typeform.com/to/zgHBtjoX'
  and f.status not in ('submitted','decided');


-- ------------------------------------------------------------
-- VERIFY 1: one Azolla form remains, 10 fields, drafting
-- ------------------------------------------------------------
select f.form_url, f.status, count(ff.id) as field_count
from app.application_forms f
join app.parties pt on pt.id = f.party_id
left join app.application_form_fields ff on ff.form_id = f.id
where f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and pt.party_name ilike '%azolla%'
group by f.form_url, f.status;


-- ------------------------------------------------------------
-- VERIFY 2: duplicate sweep across the whole blitz - any other
-- party carrying more than one live application form shows here
-- (expect 0 rows, or a list of parties to clean the same way)
-- ------------------------------------------------------------
select pt.party_name, count(*) as live_forms,
       string_agg(f.status, ', ' order by f.created_at) as statuses
from app.application_forms f
join app.parties pt on pt.id = f.party_id
where f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
group by pt.party_name
having count(*) > 1
order by pt.party_name;
