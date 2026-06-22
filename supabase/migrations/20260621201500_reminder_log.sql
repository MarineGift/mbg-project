-- 20260621201500_reminder_log.sql
-- Idempotency ledger for the reminder digest worker (todo_v2).
-- At most one digest per (organization, user, day, kind). Worker writes via the
-- service role (bypasses RLS); a select policy lets the org read its own log.
-- Apply via Supabase SQL Editor (data/schema change, separate from git push).

create table if not exists app.reminder_log (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null,
  user_id          uuid not null,
  digest_date      date not null,
  kind             text not null default 'daily_digest',
  item_count       integer not null default 0,
  communication_id uuid,
  sent_at          timestamptz not null default now(),
  constraint reminder_log_unique unique (organization_id, user_id, digest_date, kind)
);

create index if not exists reminder_log_org_date_idx
  on app.reminder_log (organization_id, digest_date);

alter table app.reminder_log enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'app' and tablename = 'reminder_log'
      and policyname = 'reminder_log_org_select'
  ) then
    create policy reminder_log_org_select on app.reminder_log
      for select using (
        organization_id in (select u.organization_id from app.users u where u.id = auth.uid())
      );
  end if;
end $$;
