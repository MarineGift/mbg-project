-- ===========================================================================
--  migration_20260915i_party_research.sql
--  URM - investor research notes + cold mail sent outside URM
-- ---------------------------------------------------------------------------
--  !! SUPABASE SQL EDITOR: press Ctrl+A (SELECT ALL) BEFORE pressing Run. !!
-- ---------------------------------------------------------------------------
--  WHAT THIS DOES
--    Two tables behind the new "투자사 분석" tab on a party page:
--
--    app.party_research    one row per party. Free text: what we found out
--                          about the firm - thesis, cheque size, portfolio
--                          overlap, who to reach, why they would or would not
--                          care about FCC.
--
--    app.party_cold_mails  outreach that was sent OUTSIDE this system, e.g.
--                          through Greentown's investor platform, so it never
--                          passes through the mailcarrier and never lands in
--                          app.communications. Paste it here and the party
--                          page finally shows the whole contact history.
--
--    Kept separate from app.communications on purpose: communications rows are
--    written by the mail pipeline and carry message ids, threads, tracking and
--    read state. A pasted copy of a message sent on someone else's platform
--    has none of that, and mixing the two would corrupt reply-rate and
--    open-rate reporting.
--
--  IDEMPOTENT: safe to re-run.
--  ROLLBACK:
--    drop table if exists app.party_cold_mails;
--    drop table if exists app.party_research;
-- ===========================================================================

create table if not exists app.party_research (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references app.organizations(id) on delete cascade,
  party_id         uuid not null references app.parties(id) on delete cascade,
  research_notes   text,
  created_by       uuid default auth.uid(),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  updated_by       uuid default auth.uid()
);

create unique index if not exists party_research_org_party_uniq
  on app.party_research (organization_id, party_id);

create table if not exists app.party_cold_mails (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references app.organizations(id) on delete cascade,
  party_id         uuid not null references app.parties(id) on delete cascade,
  -- where it was sent from: greentown, linkedin, warm_intro, other
  source           text not null default 'greentown',
  subject          text,
  body             text,
  recipient        text,
  sent_at          timestamptz,
  -- free text: no reply / replied / meeting booked / passed
  outcome          text,
  created_by       uuid default auth.uid(),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  deleted_at       timestamptz
);

create index if not exists party_cold_mails_party_idx
  on app.party_cold_mails (organization_id, party_id, sent_at desc)
  where deleted_at is null;

-- ---------------------------------------------------------------------------
-- RLS - org scoped, same pattern as the other tenant tables
-- ---------------------------------------------------------------------------
alter table app.party_research   enable row level security;
alter table app.party_cold_mails enable row level security;

drop policy if exists pol_party_research_select_org on app.party_research;
create policy pol_party_research_select_org on app.party_research
  for select using (organization_id = app.current_organization_id());

drop policy if exists pol_party_research_insert_org on app.party_research;
create policy pol_party_research_insert_org on app.party_research
  for insert with check (organization_id = app.current_organization_id());

drop policy if exists pol_party_research_update_org on app.party_research;
create policy pol_party_research_update_org on app.party_research
  for update using (organization_id = app.current_organization_id())
           with check (organization_id = app.current_organization_id());

drop policy if exists pol_party_research_delete_org on app.party_research;
create policy pol_party_research_delete_org on app.party_research
  for delete using (organization_id = app.current_organization_id());

drop policy if exists pol_party_cold_mails_select_org on app.party_cold_mails;
create policy pol_party_cold_mails_select_org on app.party_cold_mails
  for select using (organization_id = app.current_organization_id());

drop policy if exists pol_party_cold_mails_insert_org on app.party_cold_mails;
create policy pol_party_cold_mails_insert_org on app.party_cold_mails
  for insert with check (organization_id = app.current_organization_id());

drop policy if exists pol_party_cold_mails_update_org on app.party_cold_mails;
create policy pol_party_cold_mails_update_org on app.party_cold_mails
  for update using (organization_id = app.current_organization_id())
           with check (organization_id = app.current_organization_id());

drop policy if exists pol_party_cold_mails_delete_org on app.party_cold_mails;
create policy pol_party_cold_mails_delete_org on app.party_cold_mails
  for delete using (organization_id = app.current_organization_id());

grant select, insert, update, delete on app.party_research   to authenticated;
grant select, insert, update, delete on app.party_cold_mails to authenticated;

-- ---------------------------------------------------------------------------
-- VERIFY 1 - column shapes the TS code expects
-- ---------------------------------------------------------------------------
select table_name, column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'app'
  and table_name in ('party_research', 'party_cold_mails')
order by table_name, ordinal_position;

-- ---------------------------------------------------------------------------
-- VERIFY 2 - policies are in place (8 rows expected)
-- ---------------------------------------------------------------------------
select tablename, policyname, cmd
from pg_policies
where schemaname = 'app'
  and tablename in ('party_research', 'party_cold_mails')
order by tablename, cmd;
