-- ============================================================
-- fix_todo_reminders_users_join.sql (2026-07-06)
-- FIX for migration_todo_reminders_phase3.sql:
--   get_due_task_reminders joined app.users for given_name/family_name, but
--   app.users has no such columns -> "42703: column u.given_name does not
--   exist". The name was only a nicety for the email greeting.
--
--   Fix: drop the app.users join entirely and derive assignee_name from the
--   email local-part (before the '@'). No dependency on the users table shape,
--   so this can't drift. auth.users still supplies the email.
--
-- Replaces only the reader function. reminded_at column, indexes, the
-- mark-sent helper and grants from Phase 3 are untouched.
-- Idempotent (create or replace). Editor-safe.
-- ============================================================

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
    -- Greeting name = email local-part (before '@'); null when no email.
    case
      when au.email is null then null
      else split_part(au.email::text, '@', 1)
    end as assignee_name,
    ti.party_id,
    (ti.due_date < p_today) as is_overdue
  from app.todo_items ti
  left join auth.users au on au.id = ti.assignee_user_id
  where ti.archived_at is null
    and ti.due_date is not null
    and ti.due_date <= p_today
    and (ti.reminded_at is null or ti.reminded_at < p_today)
    and not exists (
      select 1
      from app.todo_status_options so
      where so.board_id = ti.board_id
        and so.key = ti.status
        and so.is_done = true
    )
  order by ti.organization_id, ti.due_date asc, ti.priority nulls last;
$reader$;

grant execute on function app.get_due_task_reminders(date) to service_role;
notify pgrst, 'reload schema';

-- ---------- VERIFY ------------------------------------------------------
-- function runs without the users join (returns 0+ rows, no 42703)
select count(*) as due_today_or_overdue
from app.get_due_task_reminders(current_date);
