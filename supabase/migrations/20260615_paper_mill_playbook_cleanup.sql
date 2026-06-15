-- ============================================================
-- 20260615_paper_mill_playbook_cleanup.sql
-- Remove STALE playbook items left on paper_mill deals.
--
-- Why: the FCC playbook seed deleted the old paper_mill templates and inserted
-- new ones (new UUIDs). The deal_checklists / tasks materialised by the OLD
-- templates are tagged extra_data.pb_cl / pb_task with the now-deleted template
-- ids, so they linger as orphans alongside the fresh FCC items
-- (lead showed ~5 items/deal instead of 3).
--
-- This SOFT-deletes (sets deleted_at = now()) only:
--   * rows on paper_mill deals,
--   * that were playbook-generated (have a pb_cl / pb_task tag),
--   * whose referenced template no longer exists (true orphans).
-- The fresh FCC items reference live templates, so they are kept.
--
-- Safe: soft-delete is reversible; idempotent (deleted_at is null guard);
-- scoped to paper_mill so no other pipeline is touched.
-- Run in the Supabase SQL Editor.
-- ============================================================

-- ------------------------------------------------------------
-- PART A  (DRY RUN -- run first, deletes nothing)
-- How many orphaned items would be soft-deleted, per stage.
-- ------------------------------------------------------------
select s.code as stage,
       count(*) filter (where dc.id is not null) as orphan_checklist_items
from app.deal_checklists dc
join app.deals d      on d.id = dc.deal_id
join app.stages s     on s.id = d.current_stage_id
join app.pipelines p  on p.id = s.pipeline_id and p.code = 'paper_mill'
where dc.deleted_at is null
  and (dc.extra_data ? 'pb_cl')
  and not exists (select 1 from app.stage_checklist_templates sct
                  where sct.id::text = dc.extra_data->>'pb_cl')
group by s.code
order by s.code;

select s.code as stage,
       count(*) as orphan_tasks
from app.tasks t
join app.deals d      on d.id = t.deal_id
join app.stages s     on s.id = d.current_stage_id
join app.pipelines p  on p.id = s.pipeline_id and p.code = 'paper_mill'
where t.deleted_at is null
  and (t.extra_data ? 'pb_task')
  and not exists (select 1 from app.stage_task_templates stt
                  where stt.id::text = t.extra_data->>'pb_task')
group by s.code
order by s.code;


-- ------------------------------------------------------------
-- PART B  (APPLY -- soft-delete the orphans)
-- ------------------------------------------------------------
begin;

-- tasks first
update app.tasks t
set deleted_at = now()
from app.deals d
join app.stages s    on s.id = d.current_stage_id
join app.pipelines p on p.id = s.pipeline_id and p.code = 'paper_mill'
where t.deal_id = d.id
  and t.deleted_at is null
  and (t.extra_data ? 'pb_task')
  and not exists (select 1 from app.stage_task_templates stt
                  where stt.id::text = t.extra_data->>'pb_task');

-- then checklist items
update app.deal_checklists dc
set deleted_at = now()
from app.deals d
join app.stages s    on s.id = d.current_stage_id
join app.pipelines p on p.id = s.pipeline_id and p.code = 'paper_mill'
where dc.deal_id = d.id
  and dc.deleted_at is null
  and (dc.extra_data ? 'pb_cl')
  and not exists (select 1 from app.stage_checklist_templates sct
                  where sct.id::text = dc.extra_data->>'pb_cl');

commit;


-- ------------------------------------------------------------
-- PART C  (VERIFY -- after commit)
-- Expect: lead 294 items / 98 deals (98 x 3), qualified 2 / 1 deal.
-- ------------------------------------------------------------
select s.code as stage,
       count(distinct dc.id)      as checklist_items,
       count(distinct dc.deal_id) as deals_with_items
from app.deal_checklists dc
join app.deals d      on d.id = dc.deal_id
join app.stages s     on s.id = d.current_stage_id
join app.pipelines p  on p.id = s.pipeline_id and p.code = 'paper_mill'
where dc.deleted_at is null
  and (dc.extra_data ? 'pb_cl')
group by s.code
order by s.code;
