-- ============================================================
-- 20260701170000_slack_integrations.sql
-- Slack <-> URM integration (your OWN Slack workspace, not CF's).
--
--   app.slack_integrations : workspace <-> org mapping + outbound Incoming
--                            Webhook URL + default channel + enabled flag.
--   app.slack_notes        : inbound quick notes captured via `/urm note ...`.
--
-- Multi-tenant / SaaS standard: organization_id default app.current_organization_id(),
-- RLS org-isolation (mirrors app.deal_parties), created_by default auth.uid().
-- Inbound webhook writes use the service_role admin client and set
-- organization_id EXPLICITLY (resolved from the Slack team_id).
--
-- Idempotent. Run in Supabase SQL Editor. Railway does NOT auto-run it.
-- ============================================================

begin;

-- shared touch fn for updated_at
create or replace function app.slack_touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

-- ---------- 1) slack_integrations ----------
create table if not exists app.slack_integrations (
  id                uuid primary key default gen_random_uuid(),
  organization_id   uuid not null default app.current_organization_id(),
  slack_team_id     text,
  slack_team_name   text,
  webhook_url       text,               -- Slack Incoming Webhook (outbound notifications)
  default_channel   text,               -- optional label, e.g. '#urm'
  enabled           boolean not null default true,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  created_by        uuid default auth.uid(),
  updated_by        uuid
);

-- one active config per org (MVP: single workspace per org)
create unique index if not exists ux_slack_integrations_org
  on app.slack_integrations (organization_id);
create index if not exists ix_slack_integrations_team
  on app.slack_integrations (slack_team_id);

drop trigger if exists trg_slack_integrations_updated_at on app.slack_integrations;
create trigger trg_slack_integrations_updated_at
  before update on app.slack_integrations
  for each row execute function app.slack_touch_updated_at();

alter table app.slack_integrations enable row level security;

drop policy if exists pol_slack_integrations_select on app.slack_integrations;
create policy pol_slack_integrations_select on app.slack_integrations
  for select using (
    (organization_id = app.current_organization_id())
    or app.is_member_of_organization(organization_id)
  );
drop policy if exists pol_slack_integrations_insert on app.slack_integrations;
create policy pol_slack_integrations_insert on app.slack_integrations
  for insert with check (organization_id = app.current_organization_id());
drop policy if exists pol_slack_integrations_update on app.slack_integrations;
create policy pol_slack_integrations_update on app.slack_integrations
  for update using (organization_id = app.current_organization_id())
  with check (organization_id = app.current_organization_id());
drop policy if exists pol_slack_integrations_delete on app.slack_integrations;
create policy pol_slack_integrations_delete on app.slack_integrations
  for delete using (organization_id = app.current_organization_id());

-- ---------- 2) slack_notes ----------
create table if not exists app.slack_notes (
  id                uuid primary key default gen_random_uuid(),
  organization_id   uuid not null default app.current_organization_id(),
  body              text not null,
  slack_user_id     text,
  slack_user_name   text,
  slack_team_id     text,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  created_by        uuid default auth.uid(),
  updated_by        uuid
);

create index if not exists ix_slack_notes_org on app.slack_notes (organization_id);

drop trigger if exists trg_slack_notes_updated_at on app.slack_notes;
create trigger trg_slack_notes_updated_at
  before update on app.slack_notes
  for each row execute function app.slack_touch_updated_at();

alter table app.slack_notes enable row level security;

drop policy if exists pol_slack_notes_select on app.slack_notes;
create policy pol_slack_notes_select on app.slack_notes
  for select using (
    (organization_id = app.current_organization_id())
    or app.is_member_of_organization(organization_id)
  );
drop policy if exists pol_slack_notes_insert on app.slack_notes;
create policy pol_slack_notes_insert on app.slack_notes
  for insert with check (organization_id = app.current_organization_id());
drop policy if exists pol_slack_notes_update on app.slack_notes;
create policy pol_slack_notes_update on app.slack_notes
  for update using (organization_id = app.current_organization_id())
  with check (organization_id = app.current_organization_id());
drop policy if exists pol_slack_notes_delete on app.slack_notes;
create policy pol_slack_notes_delete on app.slack_notes
  for delete using (organization_id = app.current_organization_id());

-- privileges (RLS still applies; service_role bypasses RLS)
grant usage on schema app to authenticated, service_role;
grant select, insert, update, delete on app.slack_integrations to authenticated, service_role;
grant select, insert, update, delete on app.slack_notes        to authenticated, service_role;

commit;

-- make PostgREST see the new tables immediately
notify pgrst, 'reload schema';

-- ============================================================
-- AFTER the app is deployed with SLACK_SIGNING_SECRET set, seed your workspace
-- config (get the webhook URL from api.slack.com -> Incoming Webhooks). Example:
--
--   insert into app.slack_integrations (organization_id, webhook_url, default_channel, created_by)
--   values ('b25de8f2-1020-482f-9012-183f63883169',
--           'https://hooks.slack.com/services/XXX/YYY/ZZZ', '#urm',
--           '551fc4a0-b365-47eb-bf2f-0c3f594001c0');
--
-- slack_team_id is auto-filled on the first `/urm` command (self-heal), so you
-- can leave it null here.
-- ============================================================
