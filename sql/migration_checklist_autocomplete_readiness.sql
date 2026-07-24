-- ============================================================
-- migration_checklist_autocomplete_readiness.sql   (2026-07-23)
--
-- (A) Task completion drives its parent checklist item (derived state):
--     when every non-deleted task under a checklist item reaches
--     completed/cancelled, the item auto-completes (tagged
--     extra_data.auto_complete). If a task reopens, ONLY auto-completed
--     items revert - a manually ticked item is never touched.
-- (B) app.v_deal_stage_readiness : per-deal, current-stage gate signal
--     (checklist_total / checklist_complete / open_tasks / stage_ready).
--     stage_ready=true means the deal is READY to advance. Advancing the
--     stage stays a manual decision - moving the deal fires the existing
--     trg_apply_stage_playbook, which materialises the next stage's
--     checklist + tasks (playbook v2, 42cl/41task on crowdfunding).
--
-- Conventions honoured: exception-safe trigger (never blocks a task
-- update), plain self-contained statements, no semicolons inside string
-- literals, no standalone SQL keywords inside literals.
-- Run in the Supabase SQL Editor top to bottom, then run the VERIFY block.
-- ============================================================

-- ---------- (A1) trigger function ----------
create or replace function app.fn_task_checklist_autocomplete()
returns trigger
language plpgsql
security definer
set search_path = app, public
as $fn$
declare
  v_cl    uuid;
  v_ids   uuid[] := array[]::uuid[];
  v_total int;
  v_open  int;
begin
  begin
    if tg_op = 'INSERT' then
      if new.checklist_id is not null then
        v_ids := array[new.checklist_id];
      end if;
    elsif tg_op = 'DELETE' then
      if old.checklist_id is not null then
        v_ids := array[old.checklist_id];
      end if;
    else
      if new.checklist_id is not null then
        v_ids := v_ids || new.checklist_id;
      end if;
      if old.checklist_id is not null
         and old.checklist_id is distinct from new.checklist_id then
        v_ids := v_ids || old.checklist_id;
      end if;
    end if;

    foreach v_cl in array v_ids loop
      select count(*) filter (where t.deleted_at is null),
             count(*) filter (where t.deleted_at is null
                                and t.status not in ('completed', 'cancelled'))
        into v_total, v_open
        from app.tasks t
       where t.checklist_id = v_cl;

      if v_total > 0 and v_open = 0 then
        update app.deal_checklists dc
           set is_complete  = true,
               completed_at = now(),
               completed_by = coalesce(auth.uid(), dc.completed_by),
               extra_data   = coalesce(dc.extra_data, '{}'::jsonb)
                              || '{"auto_complete": true}'::jsonb
         where dc.id = v_cl
           and dc.deleted_at is null
           and dc.is_complete = false;
      elsif v_open > 0 then
        update app.deal_checklists dc
           set is_complete  = false,
               completed_at = null,
               completed_by = null,
               extra_data   = coalesce(dc.extra_data, '{}'::jsonb) - 'auto_complete'
         where dc.id = v_cl
           and dc.deleted_at is null
           and dc.is_complete = true
           and (dc.extra_data->>'auto_complete') = 'true';
      end if;
    end loop;
  exception when others then
    null;  -- derived state must never block a task write
  end;
  return null;
end $fn$;

-- ---------- (A2) trigger ----------
drop trigger if exists trg_task_checklist_autocomplete on app.tasks;
create trigger trg_task_checklist_autocomplete
  after insert or delete or update of status, deleted_at, checklist_id
  on app.tasks
  for each row execute function app.fn_task_checklist_autocomplete();

-- ---------- (A3) one-time backfill ----------
-- Items whose tasks are already all done: mark complete now (tagged auto).
update app.deal_checklists dc
   set is_complete  = true,
       completed_at = coalesce(dc.completed_at, now()),
       extra_data   = coalesce(dc.extra_data, '{}'::jsonb)
                      || '{"auto_complete": true}'::jsonb
 where dc.deleted_at is null
   and dc.is_complete = false
   and exists (
         select 1 from app.tasks t
          where t.checklist_id = dc.id
            and t.deleted_at is null)
   and not exists (
         select 1 from app.tasks t
          where t.checklist_id = dc.id
            and t.deleted_at is null
            and t.status not in ('completed', 'cancelled'));

-- ---------- (B) stage readiness view ----------
drop view if exists app.v_deal_stage_readiness;
create view app.v_deal_stage_readiness
with (security_invoker = true)
as
select d.id                as deal_id,
       d.deal_name,
       d.campaign_id,
       d.pipeline_id,
       d.current_stage_id,
       s.code              as stage_code,
       s.name              as stage_name,
       count(dc.id)                                        as checklist_total,
       count(dc.id) filter (where dc.is_complete)          as checklist_complete,
       (select count(*)
          from app.tasks t
         where t.deal_id = d.id
           and t.stage_id = d.current_stage_id
           and t.deleted_at is null
           and t.status not in ('completed', 'cancelled')) as open_tasks,
       (count(dc.id) > 0
        and count(dc.id) = count(dc.id) filter (where dc.is_complete)) as stage_ready
  from app.deals d
  join app.stages s
    on s.id = d.current_stage_id
  left join app.deal_checklists dc
    on dc.deal_id = d.id
   and dc.stage_id = d.current_stage_id
   and dc.deleted_at is null
 where d.deleted_at is null
 group by d.id, d.deal_name, d.campaign_id, d.pipeline_id,
          d.current_stage_id, s.code, s.name;

grant select on app.v_deal_stage_readiness to authenticated, service_role;

-- ============================================================
-- VERIFY (run each block separately)
-- ============================================================

-- V1: trigger installed on app.tasks
select tgname, tgenabled
  from pg_trigger
 where tgrelid = 'app.tasks'::regclass
   and tgname = 'trg_task_checklist_autocomplete';

-- V2: crowdfunding deals readiness snapshot
select r.deal_name, r.stage_code, r.checklist_total,
       r.checklist_complete, r.open_tasks, r.stage_ready
  from app.v_deal_stage_readiness r
  join app.pipelines p on p.id = r.pipeline_id
 where p.code = 'crowdfunding'
 order by r.deal_name;

-- V3: live test - complete every task under one checklist item of the
-- Indiegogo deal, confirm the item flips to is_complete=true, then check
-- extra_data.auto_complete = true on that row.
select dc.title, dc.is_complete, dc.extra_data->>'auto_complete' as auto_tag,
       count(t.id) filter (where t.deleted_at is null) as task_total,
       count(t.id) filter (where t.deleted_at is null
                             and t.status not in ('completed','cancelled')) as task_open
  from app.deal_checklists dc
  left join app.tasks t on t.checklist_id = dc.id
 where dc.deleted_at is null
   and dc.deal_id in (
     select d.id from app.deals d
      join app.pipelines p on p.id = d.pipeline_id
     where p.code = 'crowdfunding' and d.deleted_at is null)
 group by dc.id, dc.title, dc.is_complete, dc.extra_data
 order by dc.title;
