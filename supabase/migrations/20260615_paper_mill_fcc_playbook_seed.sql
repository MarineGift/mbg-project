-- ============================================================
-- 20260615_paper_mill_fcc_playbook_seed.sql
-- Seed stage_checklist_templates + stage_task_templates for the
-- PAPER MILL pipeline (the FCC demand / PULL journey).
--
-- Stage STRUCTURE is left untouched (lead -> qualified -> sample_sent ->
-- trial_eval -> quotation -> negotiation -> won -> lost). Only the per-stage
-- checklist + task PLAYBOOK is (re)seeded, so no deal is ever re-staged here.
--
-- Mechanism: app.apply_stage_playbook(deal, stage) materialises these templates
-- onto a deal as deal_checklists + tasks when it ENTERS a stage. The final
-- backfill block applies them to the 99 existing paper_mill deals too.
--
-- Safety:
--   * Replace semantics: existing paper_mill templates are deleted, then re-seeded.
--   * organization_id is set explicitly (the column default
--     app.current_organization_id() returns NULL in the Supabase SQL Editor).
--   * Stages are resolved by (pipeline code 'paper_mill' + stage code) -- no
--     hard-coded UUIDs -- so this is portable and self-checking.
--   * apply_stage_playbook is idempotent (each row tagged extra_data.pb_cl/pb_task),
--     so the backfill is safe to run more than once.
--   * Whole thing is one transaction; any error rolls everything back.
--
-- Run in the Supabase SQL Editor.
-- ============================================================

begin;

-- 0) Resolve the pipeline once (fails loudly if 'paper_mill' is missing).
do $$
begin
  if not exists (select 1 from app.pipelines where code = 'paper_mill') then
    raise exception 'pipeline code paper_mill not found';
  end if;
end $$;

-- 1) Wipe existing paper_mill templates (tasks first: FK).
delete from app.stage_task_templates
where stage_id in (
  select s.id from app.stages s
  join app.pipelines p on p.id = s.pipeline_id
  where p.code = 'paper_mill'
);

delete from app.stage_checklist_templates
where stage_id in (
  select s.id from app.stages s
  join app.pipelines p on p.id = s.pipeline_id
  where p.code = 'paper_mill'
);

-- 2) Checklist templates  (stage_code, title, sort_order)
insert into app.stage_checklist_templates (organization_id, stage_id, title, sort_order)
select 'b25de8f2-1020-482f-9012-183f63883169', s.id, v.title, v.sort_order
from (values
  -- Lead  (Prospecting)
  ('lead','Mill profile captured: grades, pulp usage and cost, current filler and loading',10),
  ('lead','Incumbent PCC/filler supplier identified and linked to the deal',20),
  ('lead','Production/purchasing decision-maker identified',30),
  -- Qualified
  ('qualified','Decision-maker reached at the mill; intro meeting booked',10),
  ('qualified','FCC technical fit confirmed: substitutable grade, volume, pulp-cost pain',20),
  -- Sample sent  (Value Proposition + sample)
  ('sample_sent','Win-Win / zero-investment cost-saving case presented to the mill',10),
  ('sample_sent','Mill-specific savings and carbon reduction quantified for their volume',20),
  ('sample_sent','Mill QA/production agreed to a sample or trial (POC); date set',30),
  -- Trial / Eval  (Validation -- the crux)
  ('trial_eval','Lab and/or mill trial run; technical data supplied on request',10),
  ('trial_eval','Trial report received; quality PASS confirmed by the mill',20),
  ('trial_eval','Mill agrees to request FCC supply from its filler supplier',30),
  -- Quotation  (mill commercial commitment)
  ('quotation','FCC adoption proposal / savings quotation shared with the mill',10),
  ('quotation','Mill confirms intent to adopt FCC (verbal or written)',20),
  -- Negotiation  (supplier royalty / PUSH)
  ('negotiation','Filler supplier engaged on the mill request; royalty/license track opened',10),
  ('negotiation','Royalty/license and supply terms agreed in principle',20),
  -- Won  (Closing)
  ('won','Royalty/license contract signed (MarineBio and supplier)',10),
  ('won','Long-term supply agreement signed (mill and supplier)',20),
  ('won','First PO received; royalty settlement registered',30),
  -- Lost
  ('lost','Loss reason captured (mill declined / trial failed / supplier declined / price / timing)',10),
  ('lost','Re-engage date set if the deal is revivable',20)
) as v(stage_code, title, sort_order)
join app.pipelines p on p.code = 'paper_mill'
join app.stages s on s.pipeline_id = p.id and s.code = v.stage_code;

-- 3) Task templates  (each tied to a checklist item; policy: no standalone tasks)
--    (stage_code, cl_title, title, description, priority, due_in_days, sort_order)
insert into app.stage_task_templates
  (organization_id, stage_id, checklist_template_id, title, description,
   default_priority, due_in_days, sort_order)
select 'b25de8f2-1020-482f-9012-183f63883169', s.id, ct.id,
       v.title, v.description, v.priority, v.due_in_days, v.sort_order
from (values
  -- Lead
  ('lead','Mill profile captured: grades, pulp usage and cost, current filler and loading',
   'Profile the mill','Capture grades produced, pulp usage and cost, and current filler type and loading.','high',3,10),
  ('lead','Incumbent PCC/filler supplier identified and linked to the deal',
   'Map the incumbent filler supplier','Identify the mill current PCC/filler supplier and supply footprint; link both companies to the deal.','medium',5,20),
  -- Qualified
  ('qualified','Decision-maker reached at the mill; intro meeting booked',
   'Reach the decision-maker and book an intro','Contact production/purchasing; book the intro meeting.','high',3,10),
  ('qualified','FCC technical fit confirmed: substitutable grade, volume, pulp-cost pain',
   'Confirm FCC technical fit','Validate substitutable grade, volume and pulp-cost pain.','medium',5,20),
  -- Sample sent
  ('sample_sent','Win-Win / zero-investment cost-saving case presented to the mill',
   'Deliver the zero-investment value pitch','Show pulp 800-1000 USD -> FCC 250-350 USD with no capex; quantify the mill savings.','high',3,10),
  ('sample_sent','Mill QA/production agreed to a sample or trial (POC); date set',
   'Secure and schedule the trial (POC)','Get QA/production agreement and lock a trial date.','high',5,20),
  -- Trial / Eval
  ('trial_eval','Lab and/or mill trial run; technical data supplied on request',
   'Support the trial','Lab to mill-scale; supply technical data; keep a results-review meeting booked.','high',7,10),
  ('trial_eval','Trial report received; quality PASS confirmed by the mill',
   'Review results and confirm PASS','Collect the trial report; confirm quality acceptance with the mill.','high',10,20),
  -- Quotation
  ('quotation','FCC adoption proposal / savings quotation shared with the mill',
   'Send the FCC adoption proposal','Provide the mill a savings quote and adoption proposal.','high',3,10),
  ('quotation','Mill confirms intent to adopt FCC (verbal or written)',
   'Get the mill request to its supplier','Secure the mill (written) request to its filler supplier for FCC.','high',5,20),
  -- Negotiation
  ('negotiation','Filler supplier engaged on the mill request; royalty/license track opened',
   'Engage the supplier on the mill request','Present the upside (~1.5x price, higher margin); open the royalty/license track.','high',3,10),
  ('negotiation','Royalty/license and supply terms agreed in principle',
   'Send royalty/license draft and align terms','Draft royalty/license; align supply terms and revenue share.','high',7,20),
  -- Won
  ('won','Royalty/license contract signed (MarineBio and supplier)',
   'Finalize signatures and onboarding','Close the royalty/license and the mill-supplier supply agreement; register royalty settlement.','high',5,10),
  -- Lost
  ('lost','Loss reason captured (mill declined / trial failed / supplier declined / price / timing)',
   'Record loss reason and set re-engage reminder','Capture why the deal was lost; set a re-engage date if revivable.','low',2,10)
) as v(stage_code, cl_title, title, description, priority, due_in_days, sort_order)
join app.pipelines p on p.code = 'paper_mill'
join app.stages s on s.pipeline_id = p.id and s.code = v.stage_code
join app.stage_checklist_templates ct on ct.stage_id = s.id and ct.title = v.cl_title;

-- 4) Backfill: apply the playbook to the 99 existing paper_mill deals at their
--    current stage (idempotent -- safe to re-run; remove this block to only
--    affect deals that enter a stage from now on).
do $$
declare r record;
begin
  for r in
    select dl.id, dl.current_stage_id
    from app.deals dl
    join app.stages s on s.id = dl.current_stage_id
    join app.pipelines p on p.id = s.pipeline_id
    where p.code = 'paper_mill' and dl.deleted_at is null
  loop
    perform app.apply_stage_playbook(r.id, r.current_stage_id);
  end loop;
end $$;

commit;

-- ============================================================
-- VERIFY (run after commit)
-- Expect: 20 checklist rows, 14 task rows across the 8 stages.
-- ============================================================
-- select s.sort_order, s.code,
--        count(distinct c.id) as checklist_templates,
--        count(distinct t.id) as task_templates
-- from app.stages s
-- join app.pipelines p on p.id = s.pipeline_id and p.code = 'paper_mill'
-- left join app.stage_checklist_templates c on c.stage_id = s.id
-- left join app.stage_task_templates t on t.stage_id = s.id
-- group by s.sort_order, s.code
-- order by s.sort_order;
--
-- Spot-check one deal got its checklist materialised:
-- select dc.title, dc.is_complete
-- from app.deal_checklists dc
-- join app.deals d on d.id = dc.deal_id
-- join app.stages s on s.id = d.current_stage_id
-- join app.pipelines p on p.id = s.pipeline_id and p.code = 'paper_mill'
-- where dc.deleted_at is null
-- order by d.created_at desc, dc.sort_order
-- limit 10;
