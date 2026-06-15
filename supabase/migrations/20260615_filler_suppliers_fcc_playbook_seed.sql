-- ============================================================
-- 20260615_filler_suppliers_fcc_playbook_seed.sql
-- FCC licensing playbook for the FILLER SUPPLIERS pipeline
-- (the PUSH / royalty side: license FCC tech to PCC/GCC suppliers).
--
-- One transaction does everything:
--   PART 1  STRUCTURE
--     1a) Fix the Pilot stage bug (it was is_lost=true / is_terminal=true at
--         70% -- clearly wrong for a mid-pipeline pilot). -> normal progression.
--     1b) Add a Lost stage (the pipeline had none). Cloned from paper_mill's
--         lost row so every column (incl organization_id / color_hex / any
--         NOT NULL we cannot see) matches the table exactly. Idempotent.
--         >>> If you do NOT want a Lost stage, comment out block 1b. The rest
--             still works (lost templates simply insert 0 rows).
--   PART 2  PLAYBOOK
--     2a) Replace filler_suppliers templates (delete old, insert new).
--     2b) Backfill the 85 existing deals (apply_stage_playbook, idempotent).
--     2c) Soft-delete STALE playbook items left by the old templates
--         (orphan pb_cl / pb_task) -- same fix paper_mill needed, baked in here.
--
-- Safe: single transaction (rolls back on any error); org_id explicit
-- (b25de8f2...); stages resolved by code (no hard-coded UUIDs); cleanup is
-- a reversible soft-delete scoped to filler_suppliers only.
-- Run in the Supabase SQL Editor.
-- ============================================================

begin;

-- 0) Guard
do $$
begin
  if not exists (select 1 from app.pipelines where code = 'filler_suppliers') then
    raise exception 'pipeline code filler_suppliers not found';
  end if;
end $$;

-- ---------- PART 1: STRUCTURE ----------

-- 1a) Fix Pilot: make it a normal progression stage (was lost/terminal). 0 deals, safe.
update app.stages s
set is_lost = false, is_terminal = false, is_won = false
from app.pipelines p
where p.id = s.pipeline_id and p.code = 'filler_suppliers' and s.code = 'pilot';

-- 1b) Add a Lost stage by cloning paper_mill's lost row (idempotent).
do $$
declare
  v_fs  uuid := (select id from app.pipelines where code = 'filler_suppliers');
  v_row app.stages%rowtype;
begin
  if v_fs is null then return; end if;
  if exists (select 1 from app.stages where pipeline_id = v_fs and code = 'lost') then
    return;
  end if;

  select s.* into v_row
  from app.stages s
  join app.pipelines p on p.id = s.pipeline_id and p.code = 'paper_mill'
  where s.code = 'lost'
  limit 1;
  if not found then
    raise notice 'no paper_mill lost stage to clone; skipping Lost stage add';
    return;
  end if;

  v_row.id                     := gen_random_uuid();
  v_row.pipeline_id            := v_fs;
  v_row.code                   := 'lost';
  v_row.name                   := 'Lost';
  v_row.sort_order             := 9;          -- after mass_production (8)
  v_row.default_probability_pct := 0;
  v_row.is_terminal            := true;
  v_row.is_won                 := false;
  v_row.is_lost                := true;
  -- organization_id, color_hex, is_active, timestamps inherited from the clone

  insert into app.stages select v_row.*;
end $$;

-- ---------- PART 2: PLAYBOOK ----------

-- 2a) Replace templates (tasks first: FK)
delete from app.stage_task_templates
where stage_id in (
  select s.id from app.stages s
  join app.pipelines p on p.id = s.pipeline_id
  where p.code = 'filler_suppliers'
);
delete from app.stage_checklist_templates
where stage_id in (
  select s.id from app.stages s
  join app.pipelines p on p.id = s.pipeline_id
  where p.code = 'filler_suppliers'
);

-- Checklist templates  (stage_code, title, sort_order)
insert into app.stage_checklist_templates (organization_id, stage_id, title, sort_order)
select 'b25de8f2-1020-482f-9012-183f63883169', s.id, v.title, v.sort_order
from (values
  -- Prospect
  ('prospect','Supplier plant profiled: PCC/GCC capacity, product lines, mills served',10),
  ('prospect','Strategic fit assessed: nearby paper mills that could pull FCC',20),
  ('prospect','Right contact identified (BD / product / plant manager)',30),
  -- Contacted
  ('contacted','Intro made; FCC licensing concept presented (~1.5x price, new margin)',10),
  ('contacted','Supplier interest confirmed; intro meeting booked',20),
  -- NDA
  ('nda','NDA sent and under review',10),
  ('nda','NDA signed; technical package shareable',20),
  -- Lab test
  ('lab_test','FCC samples and process shared with the supplier lab',10),
  ('lab_test','Lab test plan agreed (grades, specs, success criteria)',20),
  ('lab_test','Lab results received and reviewed against criteria',30),
  -- Evaluation
  ('evaluation','Joint business case built (volume, ~1.5x price, margin, target mills)',10),
  ('evaluation','Supplier internal approval to proceed to pilot',20),
  -- Pilot
  ('pilot','Pilot production run planned (line, volume, schedule)',10),
  ('pilot','Pilot run completed; quality and yield validated',20),
  ('pilot','A target mill lined up to pull the pilot output',30),
  -- Royalty Agreement
  ('royalty','Royalty/license terms drafted (rate, territory, exclusivity, term)',10),
  ('royalty','Terms negotiated and agreed in principle',20),
  ('royalty','Royalty/license agreement signed',30),
  -- Mass Production (Won)
  ('mass_production','Commercial FCC supply to mills started',10),
  ('mass_production','Royalty reporting and settlement process set up',20),
  ('mass_production','First royalty payment received',30),
  -- Lost
  ('lost','Loss reason captured (no fit / lab fail / pricing / declined / timing)',10),
  ('lost','Re-engage date set if the deal is revivable',20)
) as v(stage_code, title, sort_order)
join app.pipelines p on p.code = 'filler_suppliers'
join app.stages s on s.pipeline_id = p.id and s.code = v.stage_code;

-- Task templates  (each tied to a checklist item)
insert into app.stage_task_templates
  (organization_id, stage_id, checklist_template_id, title, description,
   default_priority, due_in_days, sort_order)
select 'b25de8f2-1020-482f-9012-183f63883169', s.id, ct.id,
       v.title, v.description, v.priority, v.due_in_days, v.sort_order
from (values
  ('prospect','Supplier plant profiled: PCC/GCC capacity, product lines, mills served',
   'Profile the supplier plant','Capture PCC/GCC capacity, product lines and the mills it already serves.','medium',3,10),
  ('prospect','Right contact identified (BD / product / plant manager)',
   'Find and verify the decision-maker','Identify the BD/product/plant lead and verify a contact.','medium',5,20),
  ('contacted','Intro made; FCC licensing concept presented (~1.5x price, new margin)',
   'Send intro and licensing one-pager','Introduce FCC licensing; lead with the ~1.5x price and margin upside.','high',3,10),
  ('contacted','Supplier interest confirmed; intro meeting booked',
   'Book the intro meeting','Secure a first meeting with the supplier.','high',5,20),
  ('nda','NDA sent and under review',
   'Send the NDA','Send the NDA for signature and track status.','high',3,10),
  ('nda','NDA signed; technical package shareable',
   'Share the technical package','After signature, share the FCC technical package.','medium',5,20),
  ('lab_test','FCC samples and process shared with the supplier lab',
   'Provide samples and process docs','Send FCC samples and process documentation to the lab.','high',5,10),
  ('lab_test','Lab results received and reviewed against criteria',
   'Review lab results','Collect results; compare against the agreed success criteria.','high',10,20),
  ('evaluation','Joint business case built (volume, ~1.5x price, margin, target mills)',
   'Build the supplier business case','Model volume, ~1.5x price, margin and target-mill demand.','high',5,10),
  ('evaluation','Supplier internal approval to proceed to pilot',
   'Secure go-ahead for pilot','Get supplier internal approval to run a pilot.','high',7,20),
  ('pilot','Pilot production run planned (line, volume, schedule)',
   'Plan the pilot run','Agree line, volume and schedule for the pilot.','high',5,10),
  ('pilot','Pilot run completed; quality and yield validated',
   'Run pilot and validate','Execute the pilot; validate quality and yield.','high',14,20),
  ('royalty','Royalty/license terms drafted (rate, territory, exclusivity, term)',
   'Send royalty/license draft','Draft rate, territory, exclusivity and term.','high',3,10),
  ('royalty','Terms negotiated and agreed in principle',
   'Negotiate and finalize terms','Work redlines to agreement in principle, then signature.','high',10,20),
  ('mass_production','Royalty reporting and settlement process set up',
   'Set up royalty reporting','Stand up reporting and settlement; confirm the first payment path.','high',7,10),
  ('lost','Loss reason captured (no fit / lab fail / pricing / declined / timing)',
   'Record loss reason and re-engage reminder','Capture why the deal was lost; set a re-engage date if revivable.','low',2,10)
) as v(stage_code, cl_title, title, description, priority, due_in_days, sort_order)
join app.pipelines p on p.code = 'filler_suppliers'
join app.stages s on s.pipeline_id = p.id and s.code = v.stage_code
join app.stage_checklist_templates ct on ct.stage_id = s.id and ct.title = v.cl_title;

-- 2b) Backfill existing deals (idempotent)
do $$
declare r record;
begin
  for r in
    select dl.id, dl.current_stage_id
    from app.deals dl
    join app.stages s on s.id = dl.current_stage_id
    join app.pipelines p on p.id = s.pipeline_id
    where p.code = 'filler_suppliers' and dl.deleted_at is null
  loop
    perform app.apply_stage_playbook(r.id, r.current_stage_id);
  end loop;
end $$;

-- 2c) Soft-delete STALE playbook items (orphans whose template no longer exists)
update app.tasks t
set deleted_at = now()
from app.deals d
join app.stages s    on s.id = d.current_stage_id
join app.pipelines p on p.id = s.pipeline_id and p.code = 'filler_suppliers'
where t.deal_id = d.id
  and t.deleted_at is null
  and (t.extra_data ? 'pb_task')
  and not exists (select 1 from app.stage_task_templates stt
                  where stt.id::text = t.extra_data->>'pb_task');

update app.deal_checklists dc
set deleted_at = now()
from app.deals d
join app.stages s    on s.id = d.current_stage_id
join app.pipelines p on p.id = s.pipeline_id and p.code = 'filler_suppliers'
where dc.deal_id = d.id
  and dc.deleted_at is null
  and (dc.extra_data ? 'pb_cl')
  and not exists (select 1 from app.stage_checklist_templates sct
                  where sct.id::text = dc.extra_data->>'pb_cl');

commit;

-- ============================================================
-- VERIFY (run after commit)
-- (i) Pilot fixed + Lost added; expect pilot is_lost=false, a lost row at 9:
-- select s.sort_order, s.code, s.name, s.default_probability_pct as prob, s.is_won, s.is_lost, s.is_terminal
-- from app.stages s join app.pipelines p on p.id=s.pipeline_id and p.code='filler_suppliers'
-- order by s.sort_order;
--
-- (ii) Templates; expect 23 checklist / 16 task across 9 stages:
-- select s.sort_order, s.code,
--        count(distinct c.id) as checklist_templates,
--        count(distinct t.id) as task_templates
-- from app.stages s
-- join app.pipelines p on p.id=s.pipeline_id and p.code='filler_suppliers'
-- left join app.stage_checklist_templates c on c.stage_id=s.id
-- left join app.stage_task_templates t on t.stage_id=s.id
-- group by s.sort_order, s.code order by s.sort_order;
--
-- (iii) Backfill clean; expect prospect 243/81 (81x3), lab_test 3/1, evaluation 2/1, mass_production 6/2:
-- select s.code as stage,
--        count(distinct dc.id) as checklist_items, count(distinct dc.deal_id) as deals
-- from app.deal_checklists dc
-- join app.deals d on d.id=dc.deal_id
-- join app.stages s on s.id=d.current_stage_id
-- join app.pipelines p on p.id=s.pipeline_id and p.code='filler_suppliers'
-- where dc.deleted_at is null and (dc.extra_data ? 'pb_cl')
-- group by s.code order by s.code;
