-- ===========================================================================
--  migration_20260915_mail_folders.sql
--  URM - Mail folders pinned to an important party (e.g. Greentown Labs)
-- ---------------------------------------------------------------------------
--  !! SUPABASE SQL EDITOR: press Ctrl+A (SELECT ALL) BEFORE pressing Run. !!
--  The editor runs ONLY the highlighted text when a selection exists, which
--  produces bogus 'relation "..." does not exist' errors.
-- ---------------------------------------------------------------------------
--  WHAT THIS DOES
--    Creates app.mail_folders: a short, hand-curated list of parties whose
--    mail you want to watch as its own folder under Inbox in the sidebar.
--
--    No mail is physically moved or copied. A folder is a saved view over
--    app.communications:
--        communications.party_id = mail_folders.party_id
--        OR from_address ILIKE '%@<one of match_domains>'
--    Inbound mail already gets party_id resolved on ingest
--    (src/lib/email/header-parser.ts: contact email -> party email -> domain),
--    so existing mail drops into the folder the moment you create it.
--    match_domains is the escape hatch for senders that are not registered
--    contacts (newsletters, no-reply@, a second corporate domain).
--
--  IDEMPOTENT: safe to re-run.
--  ROLLBACK:   drop table if exists app.mail_folders;
-- ===========================================================================

create table if not exists app.mail_folders (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references app.organizations(id) on delete cascade,
  party_id         uuid not null references app.parties(id) on delete cascade,
  -- null => fall back to the party name at render time
  label            text,
  -- tailwind-ish dot colour for the sidebar chip, e.g. '#10b981'
  color            text,
  -- extra sender domains folded into this folder, lower-case, no '@'
  match_domains    text[] not null default '{}'::text[],
  sort_order       integer not null default 0,
  created_by       uuid default auth.uid(),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  deleted_at       timestamptz
);

-- one live folder per party
create unique index if not exists mail_folders_org_party_uniq
  on app.mail_folders (organization_id, party_id)
  where deleted_at is null;

create index if not exists mail_folders_org_sort_idx
  on app.mail_folders (organization_id, sort_order, created_at)
  where deleted_at is null;

-- ---------------------------------------------------------------------------
-- RLS - org scoped, same pattern as the other tenant tables
-- ---------------------------------------------------------------------------
alter table app.mail_folders enable row level security;

drop policy if exists pol_mail_folders_select_org on app.mail_folders;
create policy pol_mail_folders_select_org
  on app.mail_folders
  for select
  using (organization_id = app.current_organization_id());

drop policy if exists pol_mail_folders_insert_org on app.mail_folders;
create policy pol_mail_folders_insert_org
  on app.mail_folders
  for insert
  with check (organization_id = app.current_organization_id());

drop policy if exists pol_mail_folders_update_org on app.mail_folders;
create policy pol_mail_folders_update_org
  on app.mail_folders
  for update
  using (organization_id = app.current_organization_id())
  with check (organization_id = app.current_organization_id());

drop policy if exists pol_mail_folders_delete_org on app.mail_folders;
create policy pol_mail_folders_delete_org
  on app.mail_folders
  for delete
  using (organization_id = app.current_organization_id());

grant select, insert, update, delete on app.mail_folders to authenticated;

-- ---------------------------------------------------------------------------
-- Seed: Greentown Labs Houston (skipped silently if the party is absent)
-- ---------------------------------------------------------------------------
insert into app.mail_folders (organization_id, party_id, label, color, match_domains, sort_order)
select p.organization_id,
       p.id,
       p.party_name,
       '#10b981',
       array['greentownlabs.com'],
       0
from app.parties p
where p.deleted_at is null
  and p.party_name ilike 'Greentown Labs Houston'
order by p.updated_at desc
limit 1
on conflict do nothing;

-- ---------------------------------------------------------------------------
-- VERIFY 1 - table shape. Expected columns:
--   id, organization_id, party_id, label, color, match_domains, sort_order,
--   created_by, created_at, updated_at, deleted_at
-- ---------------------------------------------------------------------------
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'app' and table_name = 'mail_folders'
order by ordinal_position;

-- ---------------------------------------------------------------------------
-- VERIFY 2 - the folders that now exist, with how much mail each one holds.
-- ---------------------------------------------------------------------------
select f.id,
       coalesce(f.label, p.party_name) as folder,
       f.match_domains,
       count(c.id) filter (where c.direction = 'inbound')                        as inbound,
       count(c.id) filter (where c.direction = 'inbound' and c.read_at is null)  as unread
from app.mail_folders f
join app.parties p on p.id = f.party_id
left join app.communications c
       on c.party_id = f.party_id
      and c.deleted_at is null
where f.deleted_at is null
group by f.id, folder, f.match_domains, f.sort_order
order by f.sort_order, folder;

-- ---------------------------------------------------------------------------
-- VERIFY 3 - how much Greentown mail is still unlinked (party_id is null).
-- Those rows reach the folder only through match_domains. If the number is
-- large, run the optional backfill below to attach them to the party.
-- ---------------------------------------------------------------------------
select count(*) as unlinked_greentown_mail
from app.communications
where deleted_at is null
  and party_id is null
  and lower(from_address) like '%@greentownlabs.com';

-- ---------------------------------------------------------------------------
-- OPTIONAL BACKFILL - attach unlinked mail to the folder party by sender
-- domain. Review VERIFY 3 first, then run this block on its own if you want
-- the rows permanently linked to the party (it also fixes the party's
-- Communications tab, not just the folder view).
-- ---------------------------------------------------------------------------
-- update app.communications c
--    set party_id = f.party_id,
--        updated_at = now()
--   from app.mail_folders f
--  where c.deleted_at is null
--    and c.party_id is null
--    and c.organization_id = f.organization_id
--    and f.deleted_at is null
--    and exists (
--          select 1 from unnest(f.match_domains) d
--           where lower(c.from_address) like '%@' || d
--        );
