-- ============================================================
-- migration_20260918b_investor_stages.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Investors pipeline stage cleanup. Run AFTER
-- migration_20260918_rounds_and_round_id.sql is verified.
--
-- Guiding rule: stage CODES are never changed. app.deal_stage_history,
-- the playbook templates and the automation triggers all key off codes, so
-- only display names, probabilities and flags move. Nothing is renamed that
-- the database joins on.
--
-- What this does
--   1. Renames display names to the fundraising vocabulary.
--   2. Fixes the probability inversion (reply_received was 10 while the
--      earlier warm_intro was 15) and spaces the ladder out.
--   3. Marks `contract` as won + terminal. Before this, no stage in the
--      pipeline had is_won / is_lost / is_terminal set at all, so forecast
--      roll-ups and the terminal-deal protection in the automation triggers
--      had nothing to act on.
--   4. Deactivates `followup_meeting` (0 deals, and its sort 7 placed it
--      after due_diligence, which reads as a regression on the board).
--   5. Adds `passed` (lost + terminal) and `hold`. The pipeline had no
--      rejection stage, so declined investors had nowhere to go.
--
-- Automation flags are left exactly as they are:
--   cold_outreach.auto_on_outbound, reply_received.auto_on_inbound,
--   first_meeting.auto_on_meeting. Moves stay forward-only.
--
-- Idempotent. No BEGIN, no DO blocks, guards on every statement.
-- ============================================================


-- ------------------------------------------------------------
-- 0) guard: abort loudly if the investors pipeline is missing
--    (division by zero on purpose)
-- ------------------------------------------------------------
select 1 / count(*) as investors_pipeline_present
from app.pipelines
where code = 'investors'
  and organization_id = 'b25de8f2-1020-482f-9012-183f63883169';


-- ------------------------------------------------------------
-- 1) display names + probabilities (codes untouched)
-- ------------------------------------------------------------
update app.stages s
set name = v.new_name,
    default_probability_pct = v.new_pct
from (values
  ('backlog',        'Target',         0),
  ('cold_outreach',  'Cold outreach',  5),
  ('warm_intro',     'Warm intro',    15),
  ('reply_received', 'Engaged',       20),
  ('first_meeting',  'Meeting',       30),
  ('due_diligence',  'Diligence',     40),
  ('term_sheet',     'Terms',         70),
  ('contract',       'Committed',     95)
) as v(code, new_name, new_pct)
where s.pipeline_id = (
        select p.id from app.pipelines p
        where p.code = 'investors'
          and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169')
  and s.code = v.code
  and (s.name is distinct from v.new_name
       or s.default_probability_pct is distinct from v.new_pct);


-- ------------------------------------------------------------
-- 2) contract = won + terminal
-- ------------------------------------------------------------
update app.stages s
set is_won = true,
    is_terminal = true
where s.pipeline_id = (
        select p.id from app.pipelines p
        where p.code = 'investors'
          and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169')
  and s.code = 'contract'
  and (s.is_won is distinct from true or s.is_terminal is distinct from true);


-- ------------------------------------------------------------
-- 3) deactivate followup_meeting
--    Guarded: only when it actually holds no live deals.
-- ------------------------------------------------------------
update app.stages s
set is_active = false
where s.pipeline_id = (
        select p.id from app.pipelines p
        where p.code = 'investors'
          and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169')
  and s.code = 'followup_meeting'
  and s.is_active = true
  and not exists (
    select 1 from app.deals d
    where d.current_stage_id = s.id and d.deleted_at is null
  );


-- ------------------------------------------------------------
-- 4) new stages: passed (lost) and hold
-- ------------------------------------------------------------
insert into app.stages
  (organization_id, pipeline_id, code, name, description, sort_order,
   default_probability_pct, is_terminal, is_won, is_lost, color_hex, is_active,
   auto_on_outbound, auto_on_inbound, auto_on_meeting)
select 'b25de8f2-1020-482f-9012-183f63883169',
       p.id, 'passed', 'Passed',
       'Investor declined or is not a fit. Terminal: automation never moves a deal out of here.',
       10, 0, true, false, true, '#94A3B8', true,
       false, false, false
from app.pipelines p
where p.code = 'investors'
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and not exists (
    select 1 from app.stages s
    where s.pipeline_id = p.id and s.code = 'passed'
  );

insert into app.stages
  (organization_id, pipeline_id, code, name, description, sort_order,
   default_probability_pct, is_terminal, is_won, is_lost, color_hex, is_active,
   auto_on_outbound, auto_on_inbound, auto_on_meeting)
select 'b25de8f2-1020-482f-9012-183f63883169',
       p.id, 'hold', 'Hold',
       'Parked by the investor or by us. Not terminal, but only moved by hand.',
       11, 0, false, false, false, '#A8A29E', true,
       false, false, false
from app.pipelines p
where p.code = 'investors'
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and not exists (
    select 1 from app.stages s
    where s.pipeline_id = p.id and s.code = 'hold'
  );


-- ------------------------------------------------------------
-- 5) Verification -- one result set
-- ------------------------------------------------------------
select s.sort_order,
       s.code,
       s.name,
       s.is_active,
       s.default_probability_pct as pct,
       s.auto_on_outbound as auto_out,
       s.auto_on_inbound  as auto_in,
       s.auto_on_meeting  as auto_meet,
       s.is_won, s.is_lost, s.is_terminal,
       (select count(*) from app.deals d
         where d.current_stage_id = s.id and d.deleted_at is null) as live_deals
from app.stages s
join app.pipelines p on p.id = s.pipeline_id
where p.code = 'investors'
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
order by s.sort_order;
