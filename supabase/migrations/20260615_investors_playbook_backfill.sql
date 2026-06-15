-- ============================================================
-- 20260615_investors_playbook_backfill.sql
-- The Investors pipeline already has a full template playbook
-- (20260612020000: 31 checklist / 21 task templates) but it was never
-- backfilled onto existing deals, so those deals show no checklist items.
-- Now that apply_stage_playbook sets stage_id correctly again, backfill the
-- existing investor deals at their current stage (idempotent).
-- Run in the Supabase SQL Editor.
-- ============================================================

begin;

do $$
declare r record;
begin
  for r in
    select dl.id, dl.current_stage_id
    from app.deals dl
    join app.stages s on s.id = dl.current_stage_id
    join app.pipelines p on p.id = s.pipeline_id
    where p.code = 'investors' and dl.deleted_at is null
  loop
    perform app.apply_stage_playbook(r.id, r.current_stage_id);
  end loop;
end $$;

commit;

-- VERIFY (after commit): items should appear, stage-scoped.
-- select s.code as stage,
--        count(distinct dc.id) as checklist_items, count(distinct dc.deal_id) as deals
-- from app.deal_checklists dc
-- join app.deals d on d.id = dc.deal_id
-- join app.stages s on s.id = d.current_stage_id
-- join app.pipelines p on p.id = s.pipeline_id and p.code = 'investors'
-- where dc.deleted_at is null and (dc.extra_data ? 'pb_cl')
-- group by s.code order by s.code;
