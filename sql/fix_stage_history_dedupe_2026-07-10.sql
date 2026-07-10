-- ============================================================
-- fix_stage_history_dedupe_2026-07-10.sql
-- Follow-up on VERIFY 3 of fix_submission_stage_moves:
--   (a) Lowercarbon got TWO history rows at the same instant,
--       one with my note and one with null notes - a live DB
--       trigger on app.deals evidently writes history on stage
--       change (repo has no such trigger = repo-DB drift).
--       DIAG A lists live triggers to confirm, CLEANUP C
--       removes the null-notes twin.
--   (b) First Bight produced 0 rows - most likely the inbound
--       mail automation already moved the deal to reply_received
--       and the forward-only guard correctly skipped it.
--       DIAG B shows the actual deal state.
--
-- Supabase SQL Editor safe: no do-blocks, no temp tables,
-- no semicolons inside string literals
-- ============================================================

-- ------------------------------------------------------------
-- DIAG A: live triggers on app.deals - if one of these writes
-- deal_stage_history, manual stage-move SQL must UPDATE only
-- and let the trigger log history (new convention going forward)
-- ------------------------------------------------------------
select t.tgname,
       pg_get_triggerdef(t.oid) as definition
from pg_trigger t
where t.tgrelid = 'app.deals'::regclass
  and not t.tgisinternal
order by t.tgname;


-- ------------------------------------------------------------
-- DIAG B: First Bight party / deal / stage state
-- expected: deal already on reply_received or later via the
-- inbound automation - if deal_id is null instead, tell me and
-- a deal creation SQL comes next
-- ------------------------------------------------------------
select pt.party_name,
       pt.id   as party_id,
       dl.id   as deal_id,
       pl.code as pipeline_code,
       s.code  as stage_code,
       s.sort_order,
       dl.stage_entered_at
from app.parties pt
left join app.deals dl
       on dl.party_id = pt.id and dl.deleted_at is null
left join app.pipelines pl on pl.id = dl.pipeline_id
left join app.stages    s  on s.id  = dl.current_stage_id
where pt.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and pt.party_name ilike '%first bight%';


-- ------------------------------------------------------------
-- CLEANUP C: delete today's null-notes history twin - a row is
-- removed only when a same-deal, same-transition row WITH notes
-- exists within 2 seconds (the manual row stays, so the note
-- about the Lowercarbon submission is preserved)
-- ------------------------------------------------------------
delete from app.deal_stage_history h
using app.deal_stage_history k
where h.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and h.changed_at::date = current_date
  and h.notes is null
  and k.ctid <> h.ctid
  and k.deal_id = h.deal_id
  and k.to_stage_id = h.to_stage_id
  and k.from_stage_id is not distinct from h.from_stage_id
  and k.notes is not null
  and abs(extract(epoch from (k.changed_at - h.changed_at))) < 2;


-- ------------------------------------------------------------
-- VERIFY: today's history - expect exactly 1 Lowercarbon row
-- (with the note) and nothing else unexpected
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
