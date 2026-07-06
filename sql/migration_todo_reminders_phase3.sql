-- ============================================================
-- migration_todo_reminders_phase3.sql (2026-07-06)
-- To-do Phase 3: task reminders (due-today + overdue).
--   Adds a once-per-day dedupe marker and an RPC the cron worker calls to
--   fetch everything that needs a reminder, grouped-ready with the assignee's
--   email resolved. Sending (Slack + email) happens in the Node worker; this
--   migration only exposes the data + the mark-sent helper.
--
--   Channel: Slack (notifySlack) + email (sendOutboundEmail) — decided per run
--   by the worker. Scope: not-archived, not-done, due_date <= today, and not
--   already reminded today.
--
-- Idempotent. Supabase-editor safe (plain statements + $func$ bodies only).
-- ============================================================

-- ---------- 1) Dedupe column -------------------------------------------
alter table app.todo_items
  add column if not exists reminded_at date;

comment on column app.todo_items.reminded_at is
  'Date this task last generated a reminder. Guards against re-sending within the same day when the cron runs hourly.';

-- Fast lookup of what still needs reminding today.
create index if not exists ix_todo_items_due_reminder
  on app.todo_items (organization_id, due_date)
  where archived_at is null;

-- ---------- 2) Due-reminders reader -------------------------------------
-- Returns one row per task that should be reminded on p_today, with the
-- assignee's email + name resolved (LEFT JOIN so unassigned tasks still list,
-- with null email -> worker routes those to Slack / org-default only).
--
-- "Done" is per-board: a status is done when its todo_status_options row has
-- is_done = true. We EXCLUDE done tasks by anti-joining that set.
--
-- SECURITY DEFINER so the cron worker (service_role, no session org) can read
-- across orgs; the worker groups by organization_id itself.
create or replace function app.get_due_task_reminders(p_today date)
returns table (
  task_id         uuid,
  organization_id uuid,
  title           text,
  due_date        date,
  priority        text,
  status          text,
  board_id        uuid,
  assignee_user_id uuid,
  assignee_email  text,
  assignee_name   text,
  party_id        uuid,
  is_overdue      boolean
)
language sql
stable
security definer
set search_path = app, public, auth
as $reader$
  select
    ti.id,
    ti.organization_id,
    ti.title,
    ti.due_date,
    ti.priority,
    ti.status,
    ti.board_id,
    ti.assignee_user_id,
    au.email::text,
    coalesce(
      nullif(trim(concat_ws(' ', u.given_name, u.family_name)), ''),
      au.email::text
    ) as assignee_name,
    ti.party_id,
    (ti.due_date < p_today) as is_overdue
  from app.todo_items ti
  left join auth.users au on au.id = ti.assignee_user_id
  left join app.users  u  on u.id  = ti.assignee_user_id
  where ti.archived_at is null
    and ti.due_date is not null
    and ti.due_date <= p_today
    and (ti.reminded_at is null or ti.reminded_at < p_today)
    -- exclude tasks whose current status is a done-status on their board
    and not exists (
      select 1
      from app.todo_status_options so
      where so.board_id = ti.board_id
        and so.key = ti.status
        and so.is_done = true
    )
  order by ti.organization_id, ti.due_date asc, ti.priority nulls last;
$reader$;

-- ---------- 3) Mark-sent helper ----------------------------------------
-- The worker calls this with the ids it successfully notified, stamping
-- reminded_at = p_today so they don't fire again until their next due cycle.
create or replace function app.mark_task_reminders_sent(p_ids uuid[], p_today date)
returns integer
language sql
volatile
security definer
set search_path = app, public
as $marker$
  with upd as (
    update app.todo_items
       set reminded_at = p_today
     where id = any(p_ids)
     returning 1
  )
  select count(*)::int from upd;
$marker$;

-- ---------- 4) Grants ---------------------------------------------------
-- The cron worker uses the service_role key; grant execute so RPC is callable.
grant execute on function app.get_due_task_reminders(date) to service_role;
grant execute on function app.mark_task_reminders_sent(uuid[], date) to service_role;

-- refresh PostgREST schema cache so the RPCs are callable immediately
notify pgrst, 'reload schema';

-- ---------- VERIFY ------------------------------------------------------
-- (a) column present
select column_name from information_schema.columns
where table_schema = 'app' and table_name = 'todo_items' and column_name = 'reminded_at';

-- (b) functions present
select proname from pg_proc
where proname in ('get_due_task_reminders', 'mark_task_reminders_sent')
order by proname;
