-- supabase/migrations/20260603174500_create_deal_checklists.sql
--
-- app.deal_checklists : the middle tier of  Deal -> Checklist -> Task.
-- A deal has many checklist items; each task (app.tasks) may belong to one
-- checklist item via tasks.checklist_id (already present, nullable).
--
-- Why: checklist-actions.ts (addChecklistItem / toggleChecklistItem /
-- deleteChecklistItem) reads & writes app.deal_checklists, but the table was
-- never created in the live DB -> "Add" silently rolls back. This creates it
-- to match EXACTLY the columns the code uses (see that file's header + the
-- insert/update payloads):
--   id, deal_id, organization_id, title, is_complete, completed_at,
--   completed_by, sort_order, deleted_at, created_by, updated_by,
--   created_at, updated_at
--
-- Conventions mirror app.tasks / app.deal_parties:
--   - organization_id default app.current_organization_id(), NOT NULL
--   - RLS org isolation via app.current_organization_id()
--                          / app.is_member_of_organization()
--   - soft delete via deleted_at; updated_at maintained by trigger
--
-- Idempotent: safe to re-run. Run in Supabase SQL Editor, then keep this file.

begin;

create table if not exists app.deal_checklists (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null default app.current_organization_id(),
  deal_id         uuid not null references app.deals(id) on delete cascade,
  title           text not null,
  is_complete     boolean not null default false,
  completed_at    timestamptz,
  completed_by    uuid,
  sort_order      integer not null default 0,
  deleted_at      timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  created_by      uuid default auth.uid(),
  updated_by      uuid
);

-- list a deal's checklist items in order, skipping soft-deleted rows
create index if not exists ix_deal_checklists_deal
  on app.deal_checklists (deal_id, sort_order)
  where deleted_at is null;
create index if not exists ix_deal_checklists_org
  on app.deal_checklists (organization_id);

-- Link existing tasks.checklist_id -> app.deal_checklists(id) if not already a FK.
-- (tasks.checklist_id already exists as a nullable uuid; addTask in
--  deals/[id]/actions.ts verifies the checklist belongs to the same deal.)
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'tasks_checklist_id_fkey'
  ) then
    alter table app.tasks
      add constraint tasks_checklist_id_fkey
      foreign key (checklist_id) references app.deal_checklists(id)
      on delete set null;
  end if;
end$$;

-- keep updated_at fresh on UPDATE (self-contained; no external fn dependency)
create or replace function app.deal_checklists_touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_deal_checklists_updated_at on app.deal_checklists;
create trigger trg_deal_checklists_updated_at
  before update on app.deal_checklists
  for each row execute function app.deal_checklists_touch_updated_at();

-- row level security: tenant isolation, mirroring app.tasks / app.deal_parties
alter table app.deal_checklists enable row level security;

drop policy if exists pol_deal_checklists_select on app.deal_checklists;
create policy pol_deal_checklists_select on app.deal_checklists
  for select
  using (
    (organization_id = app.current_organization_id())
    or app.is_member_of_organization(organization_id)
  );

drop policy if exists pol_deal_checklists_insert on app.deal_checklists;
create policy pol_deal_checklists_insert on app.deal_checklists
  for insert
  with check (organization_id = app.current_organization_id());

drop policy if exists pol_deal_checklists_update on app.deal_checklists;
create policy pol_deal_checklists_update on app.deal_checklists
  for update
  using (organization_id = app.current_organization_id())
  with check (organization_id = app.current_organization_id());

drop policy if exists pol_deal_checklists_delete on app.deal_checklists;
create policy pol_deal_checklists_delete on app.deal_checklists
  for delete
  using (organization_id = app.current_organization_id());

-- privileges (RLS still applies on top). service_role bypasses RLS.
grant usage on schema app to authenticated, service_role;
grant select, insert, update, delete on app.deal_checklists to authenticated, service_role;

commit;

-- Force PostgREST to reload its schema cache so the new table is visible
-- immediately (otherwise the "schema cache" error can linger briefly).
notify pgrst, 'reload schema';
