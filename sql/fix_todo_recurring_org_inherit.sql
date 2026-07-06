-- ============================================================
-- fix_todo_recurring_org_inherit.sql (2026-07-06)
-- FIX for migration_todo_recurring_phase2.sql:
--   The spawn trigger let organization_id / created_by fall to their column
--   DEFAULTS (current_organization_id() / auth.uid()). Inside an AFTER-UPDATE
--   trigger there is no request session, so current_organization_id() returns
--   NULL -> "null value in column organization_id violates not-null constraint",
--   and the next occurrence is never created.
--
--   Correct behaviour: a recurrence occurrence belongs to the SAME org and the
--   SAME owner as the task it descends from. So copy new.organization_id and
--   new.created_by explicitly instead of relying on session defaults.
--
-- Only app.todo_spawn_next_occurrence() changes. Columns / trigger / helper
-- from Phase 2 are untouched. Idempotent (create or replace). Editor-safe.
-- ============================================================

create or replace function app.todo_spawn_next_occurrence()
returns trigger
language plpgsql
as $spawn$
declare
  v_new_done   boolean;
  v_old_done   boolean;
  v_next_due   date;
  v_next_start date;
  v_first_key  text;
begin
  -- Only recurring tasks matter.
  if new.recurrence is null then
    return new;
  end if;

  -- Is the NEW status a done-status on this board?
  select coalesce(bool_or(so.is_done), false) into v_new_done
  from app.todo_status_options so
  where so.board_id = new.board_id and so.key = new.status;

  -- Was the OLD status a done-status? (guards re-saves within done)
  select coalesce(bool_or(so.is_done), false) into v_old_done
  from app.todo_status_options so
  where so.board_id = old.board_id and so.key = old.status;

  -- Fire only on the not-done -> done transition.
  if not v_new_done or v_old_done then
    return new;
  end if;

  -- A recurring task must have a due_date to anchor the cadence.
  v_next_due := app.todo_advance_date(new.due_date, new.recurrence);
  if v_next_due is null then
    return new;
  end if;

  -- Respect the recurrence end date.
  if new.recurrence_ends is not null and v_next_due > new.recurrence_ends then
    return new;
  end if;

  -- Preserve the start->due offset (keeps Gantt bars the same length).
  if new.start_date is not null then
    v_next_start := v_next_due - (new.due_date - new.start_date);
  else
    v_next_start := null;
  end if;

  -- First not-done status on this board = where the fresh occurrence lands.
  select so.key into v_first_key
  from app.todo_status_options so
  where so.board_id = new.board_id and so.is_done = false
  order by so.position asc
  limit 1;

  if v_first_key is null then
    return new;
  end if;

  -- Insert the next occurrence. organization_id + created_by are INHERITED from
  -- the source row (an occurrence belongs to the same tenant + owner) rather
  -- than left to session defaults, which are NULL inside a trigger context.
  insert into app.todo_items (
    organization_id, created_by,
    board_id, group_id, parent_item_id,
    title, description, status, priority,
    assignee_user_id, start_date, due_date, position,
    party_id, contact_id, communication_id, custom,
    recurrence, recurrence_ends, recurrence_parent_id
  )
  values (
    new.organization_id, new.created_by,
    new.board_id, new.group_id, new.parent_item_id,
    new.title, new.description, v_first_key, new.priority,
    new.assignee_user_id, v_next_start, v_next_due, 0,
    new.party_id, new.contact_id, new.communication_id, new.custom,
    new.recurrence, new.recurrence_ends,
    coalesce(new.recurrence_parent_id, new.id)
  );

  return new;
end
$spawn$;

-- Trigger already points at this function name; no trigger DDL needed.
notify pgrst, 'reload schema';

-- ---------- VERIFY ------------------------------------------------------
-- function updated (should list the new insert column list incl organization_id)
select proname,
       position('organization_id, created_by' in pg_get_functiondef(oid)) > 0
         as inherits_org_and_owner
from pg_proc
where proname = 'todo_spawn_next_occurrence';
