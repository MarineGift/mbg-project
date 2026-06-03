-- supabase/migrations/20260603173500_create_deal_parties.sql
--
-- app.deal_parties : a deal's companies (M:N). One deal has many companies,
-- ALL EQUAL LEVEL. Each row records one company on the deal plus a `role`
-- (an attribute/condition value, NOT a hierarchy) and an optional commitment.
--
-- Why: createDeal (pipelines/[code]/actions.ts) inserts into this table, but it
-- was never created in the live DB ("Could not find the table 'app.deal_parties'
-- in the schema cache"). This migration creates it to match the code's columns
-- and the existing app-schema conventions (see app.tasks):
--   - organization_id  : default app.current_organization_id(), NOT NULL
--   - RLS              : org isolation via app.current_organization_id()
--                        / app.is_member_of_organization()
--   - id/created_at/updated_at defaults; updated_at maintained by trigger
--   - unique(deal_id, party_id) : a company can't be listed twice on one deal
--
-- deals.party_id stays NOT NULL (single legacy anchor = first listed company);
-- this table is the full, canonical company list and the reverse-lookup source
-- for "which deals is this party in".
--
-- Idempotent: safe to re-run. Run in Supabase SQL Editor, then keep this file.

begin;

create table if not exists app.deal_parties (
  id                uuid primary key default gen_random_uuid(),
  organization_id   uuid not null default app.current_organization_id(),
  deal_id           uuid not null references app.deals(id)   on delete cascade,
  party_id          uuid not null references app.parties(id) on delete restrict,
  role              text not null default 'primary',
  commitment_amount numeric,
  currency          text not null default 'USD',
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  created_by        uuid default auth.uid(),
  updated_by        uuid
);

-- a company appears at most once per deal (createDeal also de-dups in code)
create unique index if not exists ux_deal_parties_deal_party
  on app.deal_parties (deal_id, party_id);

-- forward (deal -> its companies) and reverse (party -> its deals) lookups
create index if not exists ix_deal_parties_deal  on app.deal_parties (deal_id);
create index if not exists ix_deal_parties_party on app.deal_parties (party_id);
create index if not exists ix_deal_parties_org   on app.deal_parties (organization_id);

-- keep updated_at fresh on UPDATE (self-contained; no external fn dependency)
create or replace function app.deal_parties_touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_deal_parties_updated_at on app.deal_parties;
create trigger trg_deal_parties_updated_at
  before update on app.deal_parties
  for each row execute function app.deal_parties_touch_updated_at();

-- row level security: tenant isolation, mirroring app.tasks (pol_tasks_*)
alter table app.deal_parties enable row level security;

drop policy if exists pol_deal_parties_select on app.deal_parties;
create policy pol_deal_parties_select on app.deal_parties
  for select
  using (
    (organization_id = app.current_organization_id())
    or app.is_member_of_organization(organization_id)
  );

drop policy if exists pol_deal_parties_insert on app.deal_parties;
create policy pol_deal_parties_insert on app.deal_parties
  for insert
  with check (organization_id = app.current_organization_id());

drop policy if exists pol_deal_parties_update on app.deal_parties;
create policy pol_deal_parties_update on app.deal_parties
  for update
  using (organization_id = app.current_organization_id())
  with check (organization_id = app.current_organization_id());

drop policy if exists pol_deal_parties_delete on app.deal_parties;
create policy pol_deal_parties_delete on app.deal_parties
  for delete
  using (organization_id = app.current_organization_id());

-- privileges (RLS still applies on top). service_role bypasses RLS.
grant usage on schema app to authenticated, service_role;
grant select, insert, update, delete on app.deal_parties to authenticated, service_role;

commit;

-- Force PostgREST to reload its schema cache so the new table is visible
-- immediately (otherwise the "schema cache" error can linger briefly).
notify pgrst, 'reload schema';
