-- ============================================================
-- fix_form_duplicates_and_azolla_stage_2026-07-10.sql
-- Cleanup after the duplicate sweep (diag CSV 2026-07-10 17:1x):
--
--   Azolla      keep 575afd44 (typeform, real P1 submission)
--               drop 5cdb934b (contact-us clone born 17:06 via
--               the from-template UI flow, marked submitted)
--   Lowercarbon keep 5384de68 (04:52 rewrite, the worked copy)
--               drop 126548c9 (04:39 first draft - both were
--               flipped to submitted by an unscoped update)
--   Anzu        keep ce64cf37 (www URL, 15 fields all answered)
--               and carry the P5 blitz meta onto it
--               drop 39c7f89e (empty blitz row)
--
-- Plus: Azolla deal -> cold_outreach.
--
-- CONVENTIONS LOCKED IN TODAY:
--   * form status changes MUST target form id or form_url,
--     never party + status alone (duplicates get hit)
--   * deal stage moves are UPDATE only - a live DB trigger on
--     app.deals writes deal_stage_history, manual inserts
--     double-log (proved and deduped earlier today)
--
-- Supabase SQL Editor safe: no do-blocks, no temp tables,
-- no semicolons inside string literals
-- ============================================================

-- ------------------------------------------------------------
-- 1. Azolla: drop the 17:06 clone (fields and answers cascade)
-- ------------------------------------------------------------
delete from app.application_forms
where id = '5cdb934b-aa3f-4720-b5e2-04a030235e50'::uuid
  and organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid;


-- ------------------------------------------------------------
-- 2. Lowercarbon: drop the 04:39 first draft
-- ------------------------------------------------------------
delete from app.application_forms
where id = '126548c9-43ae-4c0f-840a-f883409d02de'::uuid
  and organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid;


-- ------------------------------------------------------------
-- 3. Anzu: drop the empty blitz row, then carry P5 meta onto
--    the surviving worked copy
-- ------------------------------------------------------------
delete from app.application_forms
where id = '39c7f89e-4816-4c88-8526-c5fbb0b73a5b'::uuid
  and organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid;

update app.application_forms
set cycle_label = 'Series A 2026-07',
    notes       = 'P5 form blitz - company questionnaire route, 15 fields pre-answered on the worked copy',
    updated_at  = now()
where id = 'ce64cf37-9a02-498c-8b90-84bbddf5edba'::uuid
  and organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid;


-- ------------------------------------------------------------
-- 4. Azolla deal -> cold_outreach (UPDATE only, forward-only,
--    history comes off the live trigger)
-- ------------------------------------------------------------
update app.deals dl
set current_stage_id = tgt.id,
    stage_entered_at = now(),
    last_activity_at = now(),
    updated_at       = now()
from app.parties pt,
     app.pipelines pl,
     app.stages tgt,
     app.stages cur
where pt.id  = dl.party_id
  and pl.id  = dl.pipeline_id
  and cur.id = dl.current_stage_id
  and tgt.pipeline_id = pl.id
  and dl.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and pl.code = 'investors'
  and pt.party_name ilike '%azolla%'
  and dl.deleted_at is null
  and tgt.code = 'cold_outreach'
  and cur.sort_order < tgt.sort_order;


-- ------------------------------------------------------------
-- VERIFY 1: the three parties, one form each with the right
-- status (Azolla submitted typeform, Lowercarbon submitted,
-- Anzu drafting with the P5 label)
-- ------------------------------------------------------------
select pt.party_name, f.form_url, f.status, f.cycle_label,
       count(ff.id) as fields
from app.application_forms f
join app.parties pt on pt.id = f.party_id
left join app.application_form_fields ff on ff.form_id = f.id
where f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and (pt.party_name ilike '%azolla%'
    or pt.party_name ilike '%anzu%'
    or pt.party_name ilike '%lowercarbon%')
group by pt.party_name, f.form_url, f.status, f.cycle_label
order by pt.party_name;


-- ------------------------------------------------------------
-- VERIFY 2: Azolla deal stage plus today's history for it (one
-- trigger-written row expected for the move)
-- ------------------------------------------------------------
select pt.party_name, s.code as stage_code, dl.stage_entered_at
from app.deals dl
join app.parties pt on pt.id = dl.party_id
join app.stages  s  on s.id  = dl.current_stage_id
where dl.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and dl.deleted_at is null
  and pt.party_name ilike '%azolla%';


-- ------------------------------------------------------------
-- VERIFY 3: duplicate sweep rerun (expect 0 rows)
-- ------------------------------------------------------------
select pt.party_name, count(*) as live_forms
from app.application_forms f
join app.parties pt on pt.id = f.party_id
where f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
group by pt.party_name
having count(*) > 1;
