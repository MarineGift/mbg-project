-- ============================================================
-- 20260614_playbook_tasks_require_checklist.sql
-- Policy: tasks always live UNDER a checklist item. The stage playbook should
-- therefore stop creating standalone ("Prepare for X" / "Follow up - X") tasks.
-- We recreate apply_stage_playbook with one added guard on the task loop:
--   ... and checklist_template_id is not null
-- so only task templates explicitly tied to a checklist template ever seed.
-- (Existing templates keep their rows; they just won't materialize anymore.)
-- Run in Supabase SQL Editor.
-- ============================================================

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
      insert into app.deal_checklists (organization_id, deal_id, title, sort_order, extra_data)
      values (v_org, p_deal_id, ct.title, ct.sort_order,
              jsonb_build_object('pb_cl', ct.id::text));
    end if;
  end loop;

  -- tasks: ONLY those tied to a checklist template (policy: no standalone tasks)
  for tt in
    select * from app.stage_task_templates
    where stage_id = p_stage_id and is_active
      and checklist_template_id is not null   -- <-- policy guard
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

      -- if the linked checklist item isn't present, skip (stay compliant)
      if v_link_cl is not null then
        insert into app.tasks
          (organization_id, deal_id, title, description, status, priority, due_at, checklist_id, stage_id, extra_data)
        values
          (v_org, p_deal_id, tt.title, tt.description, 'pending', tt.default_priority,
           now() + (tt.due_in_days || ' days')::interval, v_link_cl, p_stage_id,
           jsonb_build_object('pb_task', tt.id::text));
      end if;
    end if;
  end loop;
end $$;

notify pgrst, 'reload schema';
