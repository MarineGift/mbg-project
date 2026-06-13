-- ============================================================
-- 20260613_checklist_stage_scope.sql
-- Stage-scope the deal execution layer so the UI can group + analyse by stage.
--
-- What this does:
--   1) Adds a nullable stage_id to app.deal_checklists and app.tasks.
--      (NULL = a deal-level item not tied to a stage; existing manual items.)
--   2) Backfills stage_id on existing playbook-generated rows, using the
--      extra_data tags the playbook already writes:
--        deal_checklists.extra_data->>'pb_cl'   -> stage_checklist_templates.stage_id
--        tasks.extra_data->>'pb_task'           -> stage_task_templates.stage_id
--   3) Updates app.apply_stage_playbook() so future seeds set stage_id too.
--
-- Idempotency is unchanged (still via extra_data.pb_cl / pb_task tags).
-- This migration only ADDS a column + backfills; it never rewrites the table
-- (nullable ADD COLUMN is metadata-only) and is safe to re-run.
--
-- Run in the Supabase SQL Editor (no BEGIN/COMMIT wrapper, per convention).
-- ============================================================

-- ---------- 1) columns ----------
alter table app.deal_checklists
  add column if not exists stage_id uuid references app.stages(id) on delete set null;

alter table app.tasks
  add column if not exists stage_id uuid references app.stages(id) on delete set null;

create index if not exists ix_deal_checklists_stage
  on app.deal_checklists (deal_id, stage_id) where deleted_at is null;

create index if not exists ix_tasks_stage
  on app.tasks (deal_id, stage_id) where deleted_at is null;

-- ---------- 2) backfill from existing playbook tags ----------
update app.deal_checklists dc
set stage_id = sct.stage_id
from app.stage_checklist_templates sct
where dc.stage_id is null
  and (dc.extra_data->>'pb_cl') is not null
  and sct.id = (dc.extra_data->>'pb_cl')::uuid;

update app.tasks t
set stage_id = stt.stage_id
from app.stage_task_templates stt
where t.stage_id is null
  and (t.extra_data->>'pb_task') is not null
  and stt.id = (t.extra_data->>'pb_task')::uuid;

-- A task linked to a checklist item but NOT tagged itself: inherit the
-- checklist item's stage (covers tasks whose template referenced a checklist).
update app.tasks t
set stage_id = dc.stage_id
from app.deal_checklists dc
where t.stage_id is null
  and t.checklist_id = dc.id
  and dc.stage_id is not null;

-- ---------- 3) apply_stage_playbook now sets stage_id on new rows ----------
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

  -- checklist items (now stage-scoped)
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
              jsonb_build_object('pb_cl', ct.id::text));
    end if;
  end loop;

  -- tasks (now stage-scoped; optionally linked to a checklist item)
  for tt in
    select * from app.stage_task_templates
    where stage_id = p_stage_id and is_active
    order by sort_order, created_at
  loop
    if not exists (
      select 1 from app.tasks t
      where t.deal_id = p_deal_id and (t.extra_data->>'pb_task') = tt.id::text
    ) then
      v_link_cl := null;
      if tt.checklist_template_id is not null then
        select dc.id into v_link_cl from app.deal_checklists dc
        where dc.deal_id = p_deal_id
          and (dc.extra_data->>'pb_cl') = tt.checklist_template_id::text
        limit 1;
      end if;
      insert into app.tasks
        (organization_id, deal_id, stage_id, title, description, status, priority, due_at, checklist_id, extra_data)
      values
        (v_org, p_deal_id, p_stage_id, tt.title, tt.description, 'pending', tt.default_priority,
         now() + (tt.due_in_days || ' days')::interval, v_link_cl,
         jsonb_build_object('pb_task', tt.id::text));
    end if;
  end loop;
end $$;

-- ---------- 4) make the new column visible to the API immediately ----------
notify pgrst, 'reload schema';

-- ---------- 5) verify ----------
select 'deal_checklists' as tbl,
       count(*) filter (where stage_id is not null) as stage_scoped,
       count(*) filter (where stage_id is null)     as deal_level,
       count(*)                                     as total
from app.deal_checklists where deleted_at is null
union all
select 'tasks',
       count(*) filter (where stage_id is not null),
       count(*) filter (where stage_id is null),
       count(*)
from app.tasks where deleted_at is null;
