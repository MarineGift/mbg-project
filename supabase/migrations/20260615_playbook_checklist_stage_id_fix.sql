-- ============================================================
-- 20260615_playbook_checklist_stage_id_fix.sql
-- Bug: 20260614 recreated app.apply_stage_playbook and (while adding the
-- "tasks require a checklist" guard) dropped stage_id from the deal_checklists
-- INSERT. Tasks kept stage_id, checklists did not. The deal Checklist tab
-- groups items by stage_id, so every playbook-materialised checklist landed in
-- the collapsed "Other" group -> the current stage looked empty ("no checklist,
-- task right there"), even though the items existed.
--
-- Fix:
--   1) Recreate apply_stage_playbook exactly as 20260614, but put stage_id back
--      on the checklist INSERT (matches the task INSERT, restores 20260613).
--   2) Backfill: set stage_id on already-materialised playbook checklist items
--      from their template's stage (covers paper_mill, filler_suppliers,
--      investors -- any deal). Only touches pb_cl rows with a null stage_id.
--
-- DB-only. The app already groups by stage_id, so no app change is needed.
-- Run in the Supabase SQL Editor.
-- ============================================================

begin;

-- 1) Recreate the function with stage_id restored on the checklist insert.
create or replace function app.apply_stage_playbook(p_deal_id uuid, p_stage_id uuid)
returns void
language plpgsql
security definer
set search_path = app, public
as $$
declare
  v_org     uuid;
  ct        record;
  tt        record;
  v_link_cl uuid;
begin
  select coalesce(d.organization_id,
                  (select organization_id from app.stages where id = p_stage_id))
    into v_org from app.deals d where d.id = p_deal_id;
  if v_org is null then v_org := 'b25de8f2-1020-482f-9012-183f63883169'; end if;

  -- checklist items
  for ct in
    select * from app.stage_checklist_templates
    where stage_id = p_stage_id and is_active
    order by sort_order, created_at
  loop
    if not exists (
      select 1 from app.deal_checklists dc
      where dc.deal_id = p_deal_id and (dc.extra_data->>'pb_cl') = ct.id::text
    ) then
      insert into app.deal_checklists (organization_id, deal_id, stage_id, title, sort_order, extra_data)
      values (v_org, p_deal_id, p_stage_id, ct.title, ct.sort_order,
              jsonb_build_object('pb_cl', ct.id::text));   -- <-- stage_id restored
    end if;
  end loop;

  -- tasks: ONLY those tied to a checklist template (policy: no standalone tasks)
  for tt in
    select * from app.stage_task_templates
    where stage_id = p_stage_id and is_active
      and checklist_template_id is not null
    order by sort_order, created_at
  loop
    if not exists (
      select 1 from app.tasks t
      where t.deal_id = p_deal_id and (t.extra_data->>'pb_task') = tt.id::text
    ) then
      v_link_cl := null;
      select dc.id into v_link_cl from app.deal_checklists dc
      where dc.deal_id = p_deal_id
        and (dc.extra_data->>'pb_cl') = tt.checklist_template_id::text
      limit 1;

      if v_link_cl is not null then
        insert into app.tasks
          (organization_id, deal_id, stage_id, title, description, status, priority, due_at, checklist_id, extra_data)
        values
          (v_org, p_deal_id, p_stage_id, tt.title, tt.description, 'pending', tt.default_priority,
           now() + (tt.due_in_days || ' days')::interval, v_link_cl,
           jsonb_build_object('pb_task', tt.id::text));
      end if;
    end if;
  end loop;
end $$;

-- 2) Backfill stage_id on existing playbook checklist items (all pipelines).
update app.deal_checklists dc
set stage_id = sct.stage_id
from app.stage_checklist_templates sct
where dc.stage_id is null
  and dc.deleted_at is null
  and (dc.extra_data ? 'pb_cl')
  and sct.id::text = dc.extra_data->>'pb_cl';

commit;

notify pgrst, 'reload schema';

-- ============================================================
-- VERIFY (run after commit) -- expect still_null = 0
-- select count(*) filter (where stage_id is null)     as still_null,
--        count(*) filter (where stage_id is not null)  as scoped
-- from app.deal_checklists
-- where (extra_data ? 'pb_cl') and deleted_at is null;
--
-- Per-pipeline sanity (paper_mill lead should now be stage-scoped):
-- select p.code as pipeline, s.code as stage,
--        count(*) filter (where dc.stage_id is not null) as scoped,
--        count(*) filter (where dc.stage_id is null)     as null_stage
-- from app.deal_checklists dc
-- join app.deals d on d.id = dc.deal_id
-- join app.stages s on s.id = d.current_stage_id
-- join app.pipelines p on p.id = s.pipeline_id
-- where dc.deleted_at is null and (dc.extra_data ? 'pb_cl')
-- group by p.code, s.code order by p.code, s.code;
