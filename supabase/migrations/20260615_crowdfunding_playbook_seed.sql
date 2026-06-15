-- ============================================================
-- 20260615_crowdfunding_playbook_seed.sql
-- Playbook for the CROWDFUNDING pipeline (running a reward crowdfunding
-- campaign, e.g. Kickstarter / Indiegogo / Wadiz).
-- Stages: research -> outreach -> application -> review -> live_campaign
--         -> funded (Won) -> closed (Lost).
--
-- One transaction: replace templates -> seed -> backfill existing deals
-- -> soft-delete stale orphans. org_id explicit; stages resolved by code;
-- idempotent backfill. Run in the Supabase SQL Editor.
-- ============================================================

begin;

do $$
begin
  if not exists (select 1 from app.pipelines where code = 'crowdfunding') then
    raise exception 'pipeline code crowdfunding not found';
  end if;
end $$;

-- Replace templates (tasks first: FK)
delete from app.stage_task_templates
where stage_id in (select s.id from app.stages s join app.pipelines p on p.id = s.pipeline_id where p.code = 'crowdfunding');
delete from app.stage_checklist_templates
where stage_id in (select s.id from app.stages s join app.pipelines p on p.id = s.pipeline_id where p.code = 'crowdfunding');

-- Checklist templates
insert into app.stage_checklist_templates (organization_id, stage_id, title, sort_order)
select 'b25de8f2-1020-482f-9012-183f63883169', s.id, v.title, v.sort_order
from (values
  -- research
  ('research','Platform chosen (Kickstarter / Indiegogo / Wadiz): fees and rules fit',10),
  ('research','Comparable campaigns analyzed (goal, tiers, conversion)',20),
  ('research','Funding goal and minimum viable budget set',30),
  ('research','Target audience and core message defined',40),
  -- outreach
  ('outreach','Pre-launch landing page live; email signups collecting',10),
  ('outreach','Email and social audience list built; warm-up planned',20),
  ('outreach','Press, influencer and community contacts lined up',30),
  ('outreach','Day-1 backer commitments secured for early momentum',40),
  -- application
  ('application','Campaign story, problem/solution and team written',10),
  ('application','Hero video produced',20),
  ('application','Reward tiers and pricing finalized',30),
  ('application','Fulfillment, shipping and timeline planned',40),
  ('application','Campaign submitted to the platform',50),
  -- review
  ('review','Platform review passed; required changes addressed',10),
  ('review','Launch date and time scheduled',20),
  ('review','Launch-day comms queued (email, social, press)',30),
  ('review','Payment, bank and tax setup verified',40),
  -- live_campaign
  ('live_campaign','Launch executed; day-1 momentum hit',10),
  ('live_campaign','Daily backer updates and comment responses ongoing',20),
  ('live_campaign','Mid-campaign press and ads push done',30),
  ('live_campaign','Stretch goals announced as targets are hit',40),
  -- funded (Won)
  ('funded','Campaign funded; funds collected',10),
  ('funded','Backer survey sent (sizes, addresses, choices)',20),
  ('funded','Production and fulfillment kicked off',30),
  ('funded','Backer thank-you and timeline update sent',40),
  -- closed (Lost)
  ('closed','Outcome reason captured (goal missed / cancelled / platform issue)',10),
  ('closed','Lessons learned and relaunch decision documented',20)
) as v(stage_code, title, sort_order)
join app.pipelines p on p.code = 'crowdfunding'
join app.stages s on s.pipeline_id = p.id and s.code = v.stage_code;

-- Task templates (each tied to a checklist item)
insert into app.stage_task_templates
  (organization_id, stage_id, checklist_template_id, title, description,
   default_priority, due_in_days, sort_order)
select 'b25de8f2-1020-482f-9012-183f63883169', s.id, ct.id,
       v.title, v.description, v.priority, v.due_in_days, v.sort_order
from (values
  ('research','Platform chosen (Kickstarter / Indiegogo / Wadiz): fees and rules fit',
   'Choose the platform','Compare fees, audience and rules; pick the best-fit platform.','medium',3,10),
  ('research','Comparable campaigns analyzed (goal, tiers, conversion)',
   'Benchmark comparable campaigns','Study five similar campaigns: goal, pledge tiers, conversion.','medium',5,20),
  ('research','Funding goal and minimum viable budget set',
   'Set funding goal and budget','Define the goal and the minimum viable budget to deliver.','high',5,30),
  ('outreach','Pre-launch landing page live; email signups collecting',
   'Build the pre-launch page','Stand up a landing page that collects email signups.','high',5,10),
  ('outreach','Email and social audience list built; warm-up planned',
   'Grow and warm up the audience','Build the email and social list; plan the warm-up sequence.','high',10,20),
  ('outreach','Press, influencer and community contacts lined up',
   'Line up press and partners','Contact press, influencers and communities ahead of launch.','medium',7,30),
  ('outreach','Day-1 backer commitments secured for early momentum',
   'Confirm day-1 backers','Secure committed backers to pledge in the first 48 hours.','high',7,40),
  ('application','Campaign story, problem/solution and team written',
   'Write the campaign page','Draft the story, problem/solution, team and traction.','high',5,10),
  ('application','Hero video produced',
   'Produce the campaign video','Script, shoot and edit the hero video.','high',10,20),
  ('application','Reward tiers and pricing finalized',
   'Finalize reward tiers','Set tiers, pricing and limited / early-bird rewards.','high',5,30),
  ('application','Campaign submitted to the platform',
   'Submit for platform review','Submit the completed campaign to the platform.','high',7,40),
  ('review','Platform review passed; required changes addressed',
   'Resolve review feedback','Address platform review feedback and resubmit if needed.','high',5,10),
  ('review','Launch date and time scheduled',
   'Lock the launch date','Pick and confirm the launch date and time.','high',3,20),
  ('review','Launch-day comms queued (email, social, press)',
   'Schedule launch announcements','Queue the launch-day email, social and press blasts.','medium',3,30),
  ('live_campaign','Launch executed; day-1 momentum hit',
   'Execute launch','Go live and drive day-1 traffic to hit early momentum.','high',1,10),
  ('live_campaign','Daily backer updates and comment responses ongoing',
   'Run daily backer comms','Post updates and answer backer comments every day.','high',2,20),
  ('live_campaign','Mid-campaign press and ads push done',
   'Run the mid-campaign push','Execute the mid-campaign press and paid-ads push.','high',7,30),
  ('live_campaign','Stretch goals announced as targets are hit',
   'Announce stretch goals','Roll out stretch goals as funding milestones are hit.','medium',10,40),
  ('funded','Backer survey sent (sizes, addresses, choices)',
   'Send backer surveys','Collect sizes, addresses and reward choices from backers.','high',5,10),
  ('funded','Production and fulfillment kicked off',
   'Start production and fulfillment','Kick off production and the fulfillment plan.','high',14,20),
  ('closed','Outcome reason captured (goal missed / cancelled / platform issue)',
   'Document outcome and relaunch plan','Record why the campaign closed and whether / when to relaunch.','low',5,10)
) as v(stage_code, cl_title, title, description, priority, due_in_days, sort_order)
join app.pipelines p on p.code = 'crowdfunding'
join app.stages s on s.pipeline_id = p.id and s.code = v.stage_code
join app.stage_checklist_templates ct on ct.stage_id = s.id and ct.title = v.cl_title;

-- Backfill existing deals (idempotent)
do $$
declare r record;
begin
  for r in
    select dl.id, dl.current_stage_id
    from app.deals dl
    join app.stages s on s.id = dl.current_stage_id
    join app.pipelines p on p.id = s.pipeline_id
    where p.code = 'crowdfunding' and dl.deleted_at is null
  loop
    perform app.apply_stage_playbook(r.id, r.current_stage_id);
  end loop;
end $$;

-- Soft-delete stale orphans (playbook items whose template no longer exists)
update app.tasks t set deleted_at = now()
from app.deals d
join app.stages s on s.id = d.current_stage_id
join app.pipelines p on p.id = s.pipeline_id and p.code = 'crowdfunding'
where t.deal_id = d.id and t.deleted_at is null and (t.extra_data ? 'pb_task')
  and not exists (select 1 from app.stage_task_templates stt where stt.id::text = t.extra_data->>'pb_task');

update app.deal_checklists dc set deleted_at = now()
from app.deals d
join app.stages s on s.id = d.current_stage_id
join app.pipelines p on p.id = s.pipeline_id and p.code = 'crowdfunding'
where dc.deal_id = d.id and dc.deleted_at is null and (dc.extra_data ? 'pb_cl')
  and not exists (select 1 from app.stage_checklist_templates sct where sct.id::text = dc.extra_data->>'pb_cl');

commit;

-- VERIFY (after commit): expect 27 checklist / 21 task across 7 stages.
-- select s.sort_order, s.code,
--        count(distinct c.id) as checklist_templates, count(distinct t.id) as task_templates
-- from app.stages s
-- join app.pipelines p on p.id=s.pipeline_id and p.code='crowdfunding'
-- left join app.stage_checklist_templates c on c.stage_id=s.id
-- left join app.stage_task_templates t on t.stage_id=s.id
-- group by s.sort_order, s.code order by s.sort_order;
