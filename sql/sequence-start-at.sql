-- ============================================================
-- Email Sequence "Scheduled start" (start_at) + auto-apply trigger
-- Run in Supabase SQL Editor.
-- ============================================================

-- 1) New column: the instant the first email should go out.
alter table app.email_sequences
  add column if not exists start_at timestamptz;

-- 2) On enrollment insert, pin next_send_at to start_at when it is in the future.
--    Covers BOTH single enroll and bulk enroll (any path that inserts a row).
create or replace function app.enrollment_apply_start_at()
returns trigger
language plpgsql
security definer
set search_path = app, public
as $fn$
declare
  s_start timestamptz;
begin
  select start_at into s_start
  from app.email_sequences
  where id = new.sequence_id;

  if s_start is not null and s_start > now() then
    new.next_send_at := greatest(coalesce(new.next_send_at, now()), s_start);
  end if;

  return new;
end;
$fn$;

drop trigger if exists trg_enrollment_apply_start_at
  on app.email_sequence_enrollments;

create trigger trg_enrollment_apply_start_at
  before insert on app.email_sequence_enrollments
  for each row execute function app.enrollment_apply_start_at();

-- 3) (optional) verify
-- select column_name from information_schema.columns
--   where table_schema='app' and table_name='email_sequences' and column_name='start_at';
-- select tgname from pg_trigger where tgname='trg_enrollment_apply_start_at';
