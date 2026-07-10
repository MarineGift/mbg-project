-- ============================================================
-- fix_submission_stage_moves_2026-07-10.sql
-- Form blitz session, Task 1: record confirmed sends
--   (1) Lowercarbon Capital - application SHIP IT done
--       -> application_forms status submitted + deal to cold_outreach
--   (2) First Bight Ventures - deck V3 reply emailed to Collin
--       -> deal to reply_received (inbound deck request answered)
--   (3) Pangaea (Andrew) NOT sent yet - intentionally untouched
--
-- Supabase SQL Editor safe:
--   * no do-blocks, no temp tables, self-contained CTE statements
--   * no semicolons or SQL keywords inside string literals
-- Stage moves are FORWARD-ONLY: a deal already at or past the
-- target stage is left as-is (mirrors app.deal_stage_history
-- automation convention)
-- ============================================================


-- ------------------------------------------------------------
-- 1. Lowercarbon application form -> submitted
-- ------------------------------------------------------------
update app.application_forms f
set status       = 'submitted',
    submitted_at = coalesce(f.submitted_at, now()),
    updated_at   = now()
from app.parties pt
where pt.id = f.party_id
  and f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and pt.party_name ilike '%lowercarbon%'
  and f.status = 'drafting';


-- ------------------------------------------------------------
-- 2. Lowercarbon deal -> cold_outreach (+ history)
-- ------------------------------------------------------------
with org as (
  select 'b25de8f2-1020-482f-9012-183f63883169'::uuid as id
),
pl as (
  select p.id
  from app.pipelines p
  where p.organization_id = (select id from org)
    and p.code = 'investors'
),
tgt as (
  select s.id, s.sort_order
  from app.stages s
  where s.pipeline_id = (select id from pl)
    and s.code = 'cold_outreach'
),
d as (
  select dl.id,
         dl.current_stage_id,
         cs.sort_order as cur_sort,
         dl.created_by
  from app.deals dl
  join app.parties pt on pt.id = dl.party_id
  join app.stages  cs on cs.id = dl.current_stage_id
  where dl.organization_id = (select id from org)
    and dl.pipeline_id     = (select id from pl)
    and dl.deleted_at is null
    and pt.party_name ilike '%lowercarbon%'
),
upd as (
  update app.deals dl
  set current_stage_id = (select id from tgt),
      stage_entered_at = now(),
      last_activity_at = now(),
      updated_at       = now()
  from d
  where dl.id = d.id
    and d.cur_sort < (select sort_order from tgt)
  returning dl.id, d.current_stage_id as from_stage_id, d.created_by
)
insert into app.deal_stage_history
  (deal_id, from_stage_id, to_stage_id, changed_at, changed_by, notes, organization_id)
select u.id,
       u.from_stage_id,
       (select id from tgt),
       now(),
       u.created_by,
       'manual - Series A application submitted via Lowercarbon web form on 2026-07-10',
       (select id from org)
from upd u;


-- ------------------------------------------------------------
-- 3. First Bight deal -> reply_received (+ history)
-- ------------------------------------------------------------
with org as (
  select 'b25de8f2-1020-482f-9012-183f63883169'::uuid as id
),
pl as (
  select p.id
  from app.pipelines p
  where p.organization_id = (select id from org)
    and p.code = 'investors'
),
tgt as (
  select s.id, s.sort_order
  from app.stages s
  where s.pipeline_id = (select id from pl)
    and s.code = 'reply_received'
),
d as (
  select dl.id,
         dl.current_stage_id,
         cs.sort_order as cur_sort,
         dl.created_by
  from app.deals dl
  join app.parties pt on pt.id = dl.party_id
  join app.stages  cs on cs.id = dl.current_stage_id
  where dl.organization_id = (select id from org)
    and dl.pipeline_id     = (select id from pl)
    and dl.deleted_at is null
    and pt.party_name ilike '%first bight%'
),
upd as (
  update app.deals dl
  set current_stage_id = (select id from tgt),
      stage_entered_at = now(),
      last_activity_at = now(),
      updated_at       = now()
  from d
  where dl.id = d.id
    and d.cur_sort < (select sort_order from tgt)
  returning dl.id, d.current_stage_id as from_stage_id, d.created_by
)
insert into app.deal_stage_history
  (deal_id, from_stage_id, to_stage_id, changed_at, changed_by, notes, organization_id)
select u.id,
       u.from_stage_id,
       (select id from tgt),
       now(),
       u.created_by,
       'manual - deck V3 emailed to Collin answering inbound deck request on 2026-07-10',
       (select id from org)
from upd u;


-- ------------------------------------------------------------
-- VERIFY 1: both deals now on expected stages
-- expect Lowercarbon = cold_outreach (or later),
--        First Bight = reply_received (or later)
-- ------------------------------------------------------------
select pt.party_name,
       s.code  as stage_code,
       s.name  as stage_name,
       dl.stage_entered_at,
       dl.last_activity_at
from app.deals dl
join app.parties pt on pt.id = dl.party_id
join app.stages  s  on s.id  = dl.current_stage_id
where dl.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and dl.deleted_at is null
  and (pt.party_name ilike '%lowercarbon%' or pt.party_name ilike '%first bight%')
order by pt.party_name;


-- ------------------------------------------------------------
-- VERIFY 2: Lowercarbon form is submitted with timestamp
-- ------------------------------------------------------------
select pt.party_name, f.status, f.submitted_at, f.form_url
from app.application_forms f
join app.parties pt on pt.id = f.party_id
where f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and pt.party_name ilike '%lowercarbon%';


-- ------------------------------------------------------------
-- VERIFY 3: history rows written (expect 2 new rows today)
-- ------------------------------------------------------------
select h.changed_at, pt.party_name, sf.code as from_code, st.code as to_code, h.notes
from app.deal_stage_history h
join app.deals   dl on dl.id = h.deal_id
join app.parties pt on pt.id = dl.party_id
left join app.stages sf on sf.id = h.from_stage_id
join app.stages      st on st.id = h.to_stage_id
where h.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and h.changed_at::date = current_date
order by h.changed_at desc;
