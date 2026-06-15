-- ============================================================
-- 20260615_government_grant_playbook_seed.sql
-- Playbook for the GOVERNMENT GRANT pipeline (pursuing public R&D /
-- innovation grants).
-- Stages: identified -> eligibility -> preparing -> submitted -> under_review
--         -> awarded (Won) -> rejected (Lost).
--
-- One transaction: replace templates -> seed -> backfill -> cleanup orphans.
-- (0 deals today, so backfill / cleanup are no-ops but kept for re-runs.)
-- org_id explicit; stages resolved by code; idempotent.
-- Run in the Supabase SQL Editor.
-- ============================================================

begin;

do $$
begin
  if not exists (select 1 from app.pipelines where code = 'government_grant') then
    raise exception 'pipeline code government_grant not found';
  end if;
end $$;

-- Replace templates (tasks first: FK)
delete from app.stage_task_templates
where stage_id in (select s.id from app.stages s join app.pipelines p on p.id = s.pipeline_id where p.code = 'government_grant');
delete from app.stage_checklist_templates
where stage_id in (select s.id from app.stages s join app.pipelines p on p.id = s.pipeline_id where p.code = 'government_grant');

-- Checklist templates
insert into app.stage_checklist_templates (organization_id, stage_id, title, sort_order)
select 'b25de8f2-1020-482f-9012-183f63883169', s.id, v.title, v.sort_order
from (values
  -- identified
  ('identified','Grant program profiled (funder, amount, scope, deadline)',10),
  ('identified','Project-to-program fit assessed',20),
  ('identified','Go / no-go decision to pursue made',30),
  -- eligibility
  ('eligibility','Eligibility criteria confirmed (entity, size, region, TRL)',10),
  ('eligibility','Co-funding / matching requirement assessed and sourced',20),
  ('eligibility','Required documents and partners list compiled',30),
  -- preparing
  ('preparing','Technical / project narrative drafted',10),
  ('preparing','Budget and justification prepared',20),
  ('preparing','Partners / collaborators and letters of support secured',30),
  ('preparing','Internal review and compliance check done',40),
  -- submitted
  ('submitted','Application submitted before the deadline',10),
  ('submitted','Submission confirmation / receipt saved',20),
  ('submitted','Reviewer-question contact and decision timeline noted',30),
  -- under_review
  ('under_review','Clarification / reviewer questions answered on time',10),
  ('under_review','Interview / panel prepared and attended (if required)',20),
  ('under_review','Decision date tracked',30),
  -- awarded (Won)
  ('awarded','Award offer accepted; grant agreement signed',10),
  ('awarded','Reporting, milestones and disbursement schedule set up',20),
  ('awarded','Project kickoff and spend tracking started',30),
  -- rejected (Lost)
  ('rejected','Reviewer feedback obtained and recorded',10),
  ('rejected','Reapply / resubmit decision and date set',20)
) as v(stage_code, title, sort_order)
join app.pipelines p on p.code = 'government_grant'
join app.stages s on s.pipeline_id = p.id and s.code = v.stage_code;

-- Task templates (each tied to a checklist item)
insert into app.stage_task_templates
  (organization_id, stage_id, checklist_template_id, title, description,
   default_priority, due_in_days, sort_order)
select 'b25de8f2-1020-482f-9012-183f63883169', s.id, ct.id,
       v.title, v.description, v.priority, v.due_in_days, v.sort_order
from (values
  ('identified','Grant program profiled (funder, amount, scope, deadline)',
   'Profile the grant program','Capture funder, amount, scope and deadline.','medium',3,10),
  ('identified','Project-to-program fit assessed',
   'Assess fit','Assess fit between our project / capabilities and the program.','medium',5,20),
  ('eligibility','Eligibility criteria confirmed (entity, size, region, TRL)',
   'Confirm eligibility','Check every eligibility criterion against our profile.','high',3,10),
  ('eligibility','Co-funding / matching requirement assessed and sourced',
   'Secure co-funding','Confirm any matching / co-funding requirement can be met.','high',5,20),
  ('eligibility','Required documents and partners list compiled',
   'List documents and partners','Compile required documents and partner commitments.','medium',5,30),
  ('preparing','Technical / project narrative drafted',
   'Draft the technical narrative','Write the project / technical proposal narrative.','high',10,10),
  ('preparing','Budget and justification prepared',
   'Build the budget','Prepare the budget and its justification.','high',7,20),
  ('preparing','Partners / collaborators and letters of support secured',
   'Secure partners and letters','Get partner commitments and letters of support.','medium',10,30),
  ('preparing','Internal review and compliance check done',
   'Internal compliance review','Review against the solicitation requirements checklist.','high',5,40),
  ('submitted','Application submitted before the deadline',
   'Submit the application','Submit before the deadline and save the confirmation.','high',2,10),
  ('under_review','Clarification / reviewer questions answered on time',
   'Respond to reviewer questions','Answer clarification requests promptly.','high',3,10),
  ('under_review','Interview / panel prepared and attended (if required)',
   'Prepare for panel / interview','Prepare for and attend any required panel or interview.','high',7,20),
  ('awarded','Award offer accepted; grant agreement signed',
   'Sign the grant agreement','Accept the offer and execute the grant agreement.','high',5,10),
  ('awarded','Reporting, milestones and disbursement schedule set up',
   'Set up reporting and milestones','Stand up reporting, milestones and disbursement tracking.','high',7,20),
  ('rejected','Reviewer feedback obtained and recorded',
   'Capture feedback and reapply plan','Record reviewer feedback; set a reapply decision and date.','low',5,10)
) as v(stage_code, cl_title, title, description, priority, due_in_days, sort_order)
join app.pipelines p on p.code = 'government_grant'
join app.stages s on s.pipeline_id = p.id and s.code = v.stage_code
join app.stage_checklist_templates ct on ct.stage_id = s.id and ct.title = v.cl_title;

-- Backfill existing deals (idempotent; 0 today)
do $$
declare r record;
begin
  for r in
    select dl.id, dl.current_stage_id
    from app.deals dl
    join app.stages s on s.id = dl.current_stage_id
    join app.pipelines p on p.id = s.pipeline_id
    where p.code = 'government_grant' and dl.deleted_at is null
  loop
    perform app.apply_stage_playbook(r.id, r.current_stage_id);
  end loop;
end $$;

-- Soft-delete stale orphans
update app.tasks t set deleted_at = now()
from app.deals d
join app.stages s on s.id = d.current_stage_id
join app.pipelines p on p.id = s.pipeline_id and p.code = 'government_grant'
where t.deal_id = d.id and t.deleted_at is null and (t.extra_data ? 'pb_task')
  and not exists (select 1 from app.stage_task_templates stt where stt.id::text = t.extra_data->>'pb_task');

update app.deal_checklists dc set deleted_at = now()
from app.deals d
join app.stages s on s.id = d.current_stage_id
join app.pipelines p on p.id = s.pipeline_id and p.code = 'government_grant'
where dc.deal_id = d.id and dc.deleted_at is null and (dc.extra_data ? 'pb_cl')
  and not exists (select 1 from app.stage_checklist_templates sct where sct.id::text = dc.extra_data->>'pb_cl');

commit;

-- VERIFY (after commit): expect 21 checklist / 15 task across 7 stages.
-- select s.sort_order, s.code,
--        count(distinct c.id) as checklist_templates, count(distinct t.id) as task_templates
-- from app.stages s
-- join app.pipelines p on p.id=s.pipeline_id and p.code='government_grant'
-- left join app.stage_checklist_templates c on c.stage_id=s.id
-- left join app.stage_task_templates t on t.stage_id=s.id
-- group by s.sort_order, s.code order by s.sort_order;
