-- ============================================================
-- seed_crowdfunding_playbook_v2.sql (2026-07-18)
-- REUSABLE crowdfunding playbook, version 2. Replaces the 2026-06-15 set
-- (27 checklist / 21 task) with a full standard process usable on every
-- future campaign: 42 checklist / 41 task across the 7 existing stages
-- (research, outreach, application, review, live_campaign, funded, closed).
-- Stage codes unchanged (deal history preserved).
--
-- Policy honored (2026-06-14): every task template is tied to a checklist
-- template, otherwise apply_stage_playbook skips it.
-- Trigger trg_apply_stage_playbook fires on stage change only, so existing
-- deals get an explicit backfill call below.
--
-- Pattern: replace templates -> backfill -> soft-delete stale orphans.
-- Conventions: no BEGIN, no DO-blocks, NOT EXISTS or delete guards,
-- org id explicit, stages resolved by code. Supabase SQL Editor. Re-runnable.
-- ============================================================

-- (0) guard: abort loudly if the pipeline is missing (division by zero on purpose)
select 1 / count(*) as pipeline_present
from app.pipelines where code = 'crowdfunding';

-- (1) wipe old templates (tasks first: FK)
delete from app.stage_task_templates
where stage_id in (select s.id from app.stages s
                   join app.pipelines p on p.id = s.pipeline_id
                   where p.code = 'crowdfunding');

delete from app.stage_checklist_templates
where stage_id in (select s.id from app.stages s
                   join app.pipelines p on p.id = s.pipeline_id
                   where p.code = 'crowdfunding');

-- (2) checklist templates (42)
insert into app.stage_checklist_templates (organization_id, stage_id, title, sort_order)
select 'b25de8f2-1020-482f-9012-183f63883169', s.id, v.title, v.sort_order
from (values
  -- research (7)
  ('research','Platform chosen: fees, rules, category fit',10),
  ('research','Five comparable campaigns benchmarked: goal, tiers, conversion',20),
  ('research','Production quotes secured: 3 vendors, MOQ, unit cost, lead time',30),
  ('research','Funding goal and minimum viable budget locked',40),
  ('research','Target persona and core message defined',50),
  ('research','Claim boundaries confirmed: allowed vs banned wording',60),
  ('research','Lead target and ad budget back-calculated',70),
  -- outreach (7)
  ('outreach','Pre-launch landing page live, signups collecting',10),
  ('outreach','Paid lead funnel running, cost per lead tracked',20),
  ('outreach','Nurture sequence live: welcome, story, proof, offer, launch alert',30),
  ('outreach','Email infra verified: SPF, DKIM, DMARC, inbox placement',40),
  ('outreach','Press, influencer and community contacts lined up',50),
  ('outreach','Day-1 backer commitments secured (target 30 pct of goal)',60),
  ('outreach','Weekly go or no-go gate: lead count vs target',70),
  -- application (7)
  ('application','Campaign story, problem, solution and team written',10),
  ('application','Hero video done (new or re-edited)',20),
  ('application','Product and lifestyle photos done',30),
  ('application','Reward tiers, pricing and early-bird finalized',40),
  ('application','Fulfillment plan set: zones, 3PL, landed cost per unit',50),
  ('application','Compliance pack attached: labels, certs, safety docs',60),
  ('application','Campaign submitted to the platform',70),
  -- review (5)
  ('review','Platform review passed, required changes addressed',10),
  ('review','Launch date and time locked',20),
  ('review','Launch-day comms queued: email, social, press',30),
  ('review','Payment, bank and tax setup verified',40),
  ('review','CS macros and FAQ ready',50),
  -- live_campaign (6)
  ('live_campaign','Day-1 momentum hit: about 30 pct inside 48 hours',10),
  ('live_campaign','Daily updates and comment replies ongoing',20),
  ('live_campaign','Mid-campaign press and ads push done',30),
  ('live_campaign','Stretch goals rolled out as milestones land',40),
  ('live_campaign','Cross-promotion and platform newsletter secured',50),
  ('live_campaign','Final 48-hour urgency push done',60),
  -- funded (7)
  ('funded','Funds collected, platform fees reconciled',10),
  ('funded','Backer survey sent: addresses, choices',20),
  ('funded','Production started, QC plan set',30),
  ('funded','Fulfillment executed, tracking shared',40),
  ('funded','InDemand or pre-order channel opened',50),
  ('funded','B2B retail outreach activated',60),
  ('funded','Post-campaign retro documented',70),
  -- closed (3)
  ('closed','Outcome reason captured',10),
  ('closed','Lessons and relaunch decision documented',20),
  ('closed','Lead list preserved for the next campaign',30)
) as v(stage_code, title, sort_order)
join app.pipelines p on p.code = 'crowdfunding'
join app.stages s on s.pipeline_id = p.id and s.code = v.stage_code;

-- (3) task templates (41), each tied to its checklist item
insert into app.stage_task_templates
  (organization_id, stage_id, checklist_template_id, title, description,
   default_priority, due_in_days, sort_order)
select 'b25de8f2-1020-482f-9012-183f63883169', s.id, ct.id,
       v.title, v.description, v.priority, v.due_in_days, v.sort_order
from (values
  -- research
  ('research','Platform chosen: fees, rules, category fit',
   'Choose the platform','Compare fees, audience, rules and category fit, then pick one main platform.','high',3,10),
  ('research','Five comparable campaigns benchmarked: goal, tiers, conversion',
   'Benchmark comparable campaigns','Study five similar campaigns: goal, pledge tiers, page structure, conversion signals.','medium',5,20),
  ('research','Production quotes secured: 3 vendors, MOQ, unit cost, lead time',
   'Collect production quotes','Get 3 vendor quotes: MOQ, unit cost, lead time, quality certifications. These numbers set the goal and the delivery promise.','high',7,30),
  ('research','Funding goal and minimum viable budget locked',
   'Lock goal and budget','Set the funding goal and the minimum viable budget using the vendor quotes.','high',5,40),
  ('research','Target persona and core message defined',
   'Define persona and message','Write the target persona and the one-line core message the whole page hangs on.','high',5,50),
  ('research','Claim boundaries confirmed: allowed vs banned wording',
   'Map allowed and banned claims','List allowed wording and banned wording per the product category rules. Lock the copy boundaries early.','high',5,60),
  ('research','Lead target and ad budget back-calculated',
   'Back-calculate leads and budget','Goal amount -> needed leads (3-5 pct conversion) -> ad budget. Produce a one-page funding math memo.','high',5,70),
  -- outreach
  ('outreach','Pre-launch landing page live, signups collecting',
   'Build the pre-launch page','Stand up a landing page that collects email signups against a concrete launch promise.','high',5,10),
  ('outreach','Paid lead funnel running, cost per lead tracked',
   'Launch the lead ads','Run paid ads to the landing page, track cost per lead weekly, kill losing creatives fast.','high',7,20),
  ('outreach','Nurture sequence live: welcome, story, proof, offer, launch alert',
   'Build the nurture sequence','Opt-in sequence, 4-5 touches: welcome, brand story, proof, early-bird offer, launch alert.','high',7,30),
  ('outreach','Email infra verified: SPF, DKIM, DMARC, inbox placement',
   'Verify email infrastructure','SPF, DKIM, DMARC checks plus an inbox placement test before any volume sends.','high',5,40),
  ('outreach','Press, influencer and community contacts lined up',
   'Line up press and partners','Contact press, influencers and communities ahead of launch, log every touch.','medium',10,50),
  ('outreach','Day-1 backer commitments secured (target 30 pct of goal)',
   'Confirm day-1 backers','Secure pledges covering about 30 pct of the goal inside the first 48 hours.','high',10,60),
  ('outreach','Weekly go or no-go gate: lead count vs target',
   'Run the weekly gate','Compare lead count vs target weekly, decide go, delay, or lower the goal.','medium',7,70),
  -- application
  ('application','Campaign story, problem, solution and team written',
   'Write the campaign page','Draft the story, problem, solution, team and traction in the target language.','high',7,10),
  ('application','Hero video done (new or re-edited)',
   'Produce the hero video','Script, shoot and edit the hero video, or re-edit existing footage to the current design.','high',10,20),
  ('application','Product and lifestyle photos done',
   'Shoot product photos','Hero shots, texture close-ups and lifestyle scenes matching the persona.','medium',7,30),
  ('application','Reward tiers, pricing and early-bird finalized',
   'Finalize reward tiers','Set tiers, pricing, limited early-bird rewards and bundle logic.','high',5,40),
  ('application','Fulfillment plan set: zones, 3PL, landed cost per unit',
   'Plan fulfillment','Shipping zones, 3PL pick, landed cost per unit, timeline buffer.','high',7,50),
  ('application','Compliance pack attached: labels, certs, safety docs',
   'Assemble the compliance pack','Label proofs, certifications and safety docs the platform or customs may request.','medium',7,60),
  ('application','Campaign submitted to the platform',
   'Submit the campaign','Submit the completed campaign for platform review.','high',3,70),
  -- review
  ('review','Platform review passed, required changes addressed',
   'Resolve review feedback','Address platform review feedback and resubmit if needed.','high',5,10),
  ('review','Launch date and time locked',
   'Lock the launch date','Pick and confirm the launch date and time, aligned to audience timezone.','high',3,20),
  ('review','Launch-day comms queued: email, social, press',
   'Queue launch announcements','Queue the launch-day email, social and press blasts.','medium',3,30),
  ('review','Payment, bank and tax setup verified',
   'Verify payment and tax setup','Confirm payout account, bank details and tax forms on the platform.','high',3,40),
  ('review','CS macros and FAQ ready',
   'Prepare CS macros and FAQ','Draft answer macros and the FAQ block covering shipping, safety and timeline.','medium',5,50),
  -- live_campaign
  ('live_campaign','Day-1 momentum hit: about 30 pct inside 48 hours',
   'Execute launch','Go live, fire the queued comms, drive day-1 traffic to hit early momentum.','high',1,10),
  ('live_campaign','Daily updates and comment replies ongoing',
   'Run daily backer comms','Post updates and answer backer comments every day of the campaign.','high',2,20),
  ('live_campaign','Mid-campaign press and ads push done',
   'Run the mid-campaign push','Execute the mid-campaign press and paid-ads push against the slump.','high',7,30),
  ('live_campaign','Stretch goals rolled out as milestones land',
   'Announce stretch goals','Roll out stretch goals as funding milestones are hit.','medium',10,40),
  ('live_campaign','Cross-promotion and platform newsletter secured',
   'Secure cross-promotion','Swap mentions with adjacent campaigns, pitch the platform newsletter team.','medium',7,50),
  ('live_campaign','Final 48-hour urgency push done',
   'Run the final 48-hour push','Last-chance email plus social countdown, retarget page visitors.','high',14,60),
  -- funded
  ('funded','Funds collected, platform fees reconciled',
   'Reconcile funds','Confirm the payout, reconcile platform and payment fees against the plan.','high',5,10),
  ('funded','Backer survey sent: addresses, choices',
   'Send backer surveys','Collect addresses and reward choices, chase non-responders.','high',5,20),
  ('funded','Production started, QC plan set',
   'Start production with QC','Kick off production, set the QC checkpoints and the acceptance criteria.','high',14,30),
  ('funded','Fulfillment executed, tracking shared',
   'Execute fulfillment','Ship rewards, share tracking, handle failed addresses and reships.','high',30,40),
  ('funded','InDemand or pre-order channel opened',
   'Open the post-campaign channel','InDemand or own-site pre-orders so sales keep running after the close.','medium',10,50),
  ('funded','B2B retail outreach activated',
   'Activate B2B retail outreach','Pitch relevant retailers using the campaign numbers as traction proof.','medium',14,60),
  ('funded','Post-campaign retro documented',
   'Write the retro','Numbers, what worked, what to reuse on the next campaign. One page.','medium',10,70),
  -- closed
  ('closed','Outcome reason captured',
   'Document outcome and relaunch plan','Record why the campaign closed and whether or when to relaunch.','low',5,10),
  ('closed','Lead list preserved for the next campaign',
   'Preserve the lead list','Export and tag the leads, they seed the next campaign audience.','medium',3,30)
) as v(stage_code, cl_title, title, description, priority, due_in_days, sort_order)
join app.pipelines p on p.code = 'crowdfunding'
join app.stages s on s.pipeline_id = p.id and s.code = v.stage_code
join app.stage_checklist_templates ct on ct.stage_id = s.id and ct.title = v.cl_title;

-- (4) backfill current-stage playbook on every live crowdfunding deal
--     (the trigger only fires on stage CHANGE, so this call is required)
select app.apply_stage_playbook(d.id, d.current_stage_id)
from app.deals d
join app.stages s on s.id = d.current_stage_id
join app.pipelines p on p.id = s.pipeline_id
where p.code = 'crowdfunding' and d.deleted_at is null;

-- (5) soft-delete stale orphans (items whose template no longer exists)
update app.tasks t set deleted_at = now()
from app.deals d
join app.stages s on s.id = d.current_stage_id
join app.pipelines p on p.id = s.pipeline_id and p.code = 'crowdfunding'
where t.deal_id = d.id and t.deleted_at is null and (t.extra_data ? 'pb_task')
  and not exists (select 1 from app.stage_task_templates stt
                  where stt.id::text = t.extra_data->>'pb_task');

update app.deal_checklists dc set deleted_at = now()
from app.deals d
join app.stages s on s.id = d.current_stage_id
join app.pipelines p on p.id = s.pipeline_id and p.code = 'crowdfunding'
where dc.deal_id = d.id and dc.deleted_at is null and (dc.extra_data ? 'pb_cl')
  and not exists (select 1 from app.stage_checklist_templates sct
                  where sct.id::text = dc.extra_data->>'pb_cl');

-- ============================================================
-- VERIFY (read-only)
-- ============================================================

-- V1: templates per stage (expect 42 checklist / 41 task total)
select s.sort_order, s.code,
       count(distinct c.id) as checklist_templates,
       count(distinct t.id) as task_templates
from app.stages s
join app.pipelines p on p.id = s.pipeline_id and p.code = 'crowdfunding'
left join app.stage_checklist_templates c on c.stage_id = s.id
left join app.stage_task_templates t on t.stage_id = s.id
group by s.sort_order, s.code
order by s.sort_order;

-- V2: every task template is tied to a checklist (expect 0 untied)
select count(*) as untied_task_templates
from app.stage_task_templates stt
join app.stages s on s.id = stt.stage_id
join app.pipelines p on p.id = s.pipeline_id and p.code = 'crowdfunding'
where stt.checklist_template_id is null;

-- V3: live deals now carry the v2 research playbook (per deal counts)
select d.deal_name,
       count(distinct dc.id) filter (where dc.deleted_at is null) as live_checklist_items,
       count(distinct t.id)  filter (where t.deleted_at is null and t.extra_data ? 'pb_task') as live_pb_tasks
from app.deals d
join app.stages s on s.id = d.current_stage_id
join app.pipelines p on p.id = s.pipeline_id and p.code = 'crowdfunding'
left join app.deal_checklists dc on dc.deal_id = d.id
left join app.tasks t on t.deal_id = d.id
where d.deleted_at is null
group by d.deal_name;
