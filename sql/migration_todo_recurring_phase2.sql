-- ============================================================
-- migration_todo_recurring_phase2.sql (2026-07-06)
-- To-do Phase 2: recurring tasks.
--   When a recurring task is moved into a DONE status, an AFTER-UPDATE trigger
--   spawns the next occurrence (same title / board / group / priority / party /
--   assignee), with dates rolled forward by the recurrence rule.
--
-- Storage: three dedicated columns on app.todo_items
--   recurrence          text  -- 'FREQ=WEEKLY;INTERVAL=1'  (subset of RRULE)
--   recurrence_ends     date  -- inclusive stop date (nullable = open-ended)
--   recurrence_parent_id uuid -- first task of the chain (lineage / cleanup)
--
-- Supported FREQ: DAILY, WEEKLY, MONTHLY, YEARLY. INTERVAL default 1.
-- (Full RRULE BY* rules are intentionally NOT parsed -- overkill for CRM
--  follow-ups. Only FREQ + INTERVAL, which cover every real recurring cadence
--  we use.) Unknown/blank recurrence -> no spawn, task just completes normally.
--
-- Completion detection: a status is "done" when the matching
--   app.todo_status_options row (board_id + key = status) has is_done = true.
--   The trigger fires only on the not-done -> done transition, so re-saving a
--   done task, or dragging within done, never double-spawns.
--
-- Loop safety: the spawned occurrence is inserted into the board's FIRST
--   not-done status, so it cannot re-fire this trigger.
--
-- Idempotent. Supabase-editor safe (single-statement DDL + one $func$ body,
-- no temp tables, no bare keywords in strings).
-- ============================================================

-- ---------- 1) Columns --------------------------------------------------
alter table app.todo_items
  add column if not exists recurrence text;
alter table app.todo_items
  add column if not exists recurrence_ends date;
alter table app.todo_items
  add column if not exists recurrence_parent_id uuid;

comment on column app.todo_items.recurrence is
  'Recurrence rule, RRULE subset: FREQ=DAILY|WEEKLY|MONTHLY|YEARLY plus optional INTERVAL=n. Null = one-off task.';
comment on column app.todo_items.recurrence_ends is
  'Inclusive last date a new occurrence may be scheduled. Null = open-ended.';
comment on column app.todo_items.recurrence_parent_id is
  'Points at the first task in the recurrence chain. Set on every spawned occurrence.';

-- Optional self-FK for lineage integrity (spawns clear if the root is deleted).
do $fk$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'todo_items_recurrence_parent_fkey'
  ) then
    alter table app.todo_items
      add constraint todo_items_recurrence_parent_fkey
      foreign key (recurrence_parent_id) references app.todo_items(id)
      on delete set null;
  end if;
end
$fk$;

-- Find open recurring occurrences quickly (dashboard / cleanup).
create index if not exists ix_todo_items_recurrence
  on app.todo_items (board_id)
  where recurrence is not null and archived_at is null;

-- ---------- 2) Date-advance helper -------------------------------------
-- Rolls a date forward by one recurrence step. Immutable + null-safe so it can
-- be reused in reports. Returns null when input date or rule is null.
create or replace function app.todo_advance_date(d date, rule text)
returns date
language plpgsql
immutable
as $adv$
declare
  v_freq text;
  v_interval int := 1;
  m text[];
begin
  if d is null or rule is null then
    return null;
  end if;

  -- FREQ=...  (required)
  m := regexp_match(upper(rule), 'FREQ=([A-Z]+)');
  if m is null then
    return null;
  end if;
  v_freq := m[1];

  -- INTERVAL=n  (optional, default 1, floored at 1)
  m := regexp_match(upper(rule), 'INTERVAL=([0-9]+)');
  if m is not null then
    v_interval := greatest(1, m[1]::int);
  end if;

  if v_freq = 'DAILY' then
    return d + (v_interval)::int;
  elsif v_freq = 'WEEKLY' then
    return d + (v_interval * 7)::int;
  elsif v_freq = 'MONTHLY' then
    return (d + (v_interval || ' months')::interval)::date;
  elsif v_freq = 'YEARLY' then
    return (d + (v_interval || ' years')::interval)::date;
  else
    return null;  -- unsupported FREQ -> caller skips spawning
  end if;
end
$adv$;

-- ---------- 3) Spawn-on-complete trigger fn ----------------------------
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

  -- Compute the next due date. A recurring task must have a due_date to anchor
  -- the cadence; without one there is nothing to roll forward.
  v_next_due := app.todo_advance_date(new.due_date, new.recurrence);
  if v_next_due is null then
    return new;  -- no due_date, or unsupported/blank rule -> just complete
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
    return new;  -- board has no open status; do not spawn into a done column
  end if;

  -- Insert the next occurrence. organization_id / created_by fall to column
  -- defaults (SaaS: un-spoofable). position 0 puts it at the top of its column.
  insert into app.todo_items (
    board_id, group_id, parent_item_id,
    title, description, status, priority,
    assignee_user_id, start_date, due_date, position,
    party_id, contact_id, communication_id, custom,
    recurrence, recurrence_ends, recurrence_parent_id
  )
  values (
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

-- ---------- 4) Trigger (AFTER UPDATE; separate from updated_at BEFORE) --
drop trigger if exists trg_todo_spawn_next_occurrence on app.todo_items;

create trigger trg_todo_spawn_next_occurrence
  after update of status on app.todo_items
  for each row
  execute function app.todo_spawn_next_occurrence();

-- refresh PostgREST schema cache so the new columns are selectable immediately
notify pgrst, 'reload schema';

-- ---------- VERIFY ------------------------------------------------------
-- (a) columns present
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'app' and table_name = 'todo_items'
  and column_name in ('recurrence','recurrence_ends','recurrence_parent_id')
order by column_name;

-- (b) trigger present + enabled
select tgname, tgenabled
from pg_trigger
where tgname = 'trg_todo_spawn_next_occurrence';

-- (c) helper sanity: weekly roll from a Monday
select app.todo_advance_date(date '2026-07-06', 'FREQ=WEEKLY;INTERVAL=1') as should_be_2026_07_13,
       app.todo_advance_date(date '2026-07-06', 'FREQ=MONTHLY')          as should_be_2026_08_06,
       app.todo_advance_date(date '2026-01-31', 'FREQ=MONTHLY')          as jan31_plus_month;
