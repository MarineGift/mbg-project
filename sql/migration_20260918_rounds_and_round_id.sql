-- ============================================================
-- migration_20260918_rounds_and_round_id.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
-- The editor runs ONLY the highlighted text when a selection exists.
--
-- What this does
--   1. Creates app.rounds (the table the frontend has been calling since
--      2026-06-02 but which was never migrated -- probe returned 42P01).
--   2. Adds app.deals.round_id + FK + index.
--   3. Gives app.campaigns.organization_id the same default the other tenant
--      tables have -- this is what made the New Campaign save fail with
--      "new row violates row-level security policy".
--   4. Creates the two rounds: 2026 Bridge Round (closed) and the 2026 Seed
--      Round (open).
--   5. Backfills the 250 existing Bridge Round deals onto the Bridge round.
--
-- Shape is matched to what the shipped frontend already expects
-- (lib/actions/rounds.ts inserts with organization_id OMITTED and relies on a
-- column default; status is one of planned/open/closed/cancelled).
--
-- NOT in this file (deliberately kept separate, applied after this one is
-- verified): stage renames, the missing "passed" stage, the Seed playbook.
--
-- Idempotent: safe to run more than once.
-- Conventions: no BEGIN, no DO blocks, guards on every statement.
-- ============================================================


-- ------------------------------------------------------------
-- 1) app.rounds
-- ------------------------------------------------------------
create table if not exists app.rounds (
  id                  uuid primary key default gen_random_uuid(),
  organization_id     uuid not null default app.current_organization_id(),
  name                text not null,
  round_type          text,
  target_amount       numeric,
  pre_money_valuation numeric,
  currency            text not null default 'USD',
  status              text not null default 'open',
  opened_at           date,
  closed_at           date,
  notes               text,
  created_at          timestamptz not null default now(),
  created_by          uuid default auth.uid(),
  updated_at          timestamptz not null default now(),
  constraint rounds_status_check
    check (status in ('planned', 'open', 'closed', 'cancelled'))
);

create unique index if not exists rounds_org_name_uidx
  on app.rounds (organization_id, name);

create index if not exists rounds_org_status_idx
  on app.rounds (organization_id, status);

drop trigger if exists trg_rounds_updated_at on app.rounds;
create trigger trg_rounds_updated_at
  before update on app.rounds
  for each row execute function app.set_updated_at();


-- ------------------------------------------------------------
-- 2) RLS on app.rounds -- same org-isolation shape as app.deal_parties
-- ------------------------------------------------------------
alter table app.rounds enable row level security;

grant select, insert, update, delete on app.rounds to authenticated;

drop policy if exists pol_rounds_select on app.rounds;
create policy pol_rounds_select on app.rounds
  for select
  using (organization_id = (select app.current_organization_id()));

drop policy if exists pol_rounds_insert on app.rounds;
create policy pol_rounds_insert on app.rounds
  for insert
  with check (organization_id = (select app.current_organization_id()));

drop policy if exists pol_rounds_update on app.rounds;
create policy pol_rounds_update on app.rounds
  for update
  using (organization_id = (select app.current_organization_id()))
  with check (organization_id = (select app.current_organization_id()));

drop policy if exists pol_rounds_delete on app.rounds;
create policy pol_rounds_delete on app.rounds
  for delete
  using (organization_id = (select app.current_organization_id()));


-- ------------------------------------------------------------
-- 3) app.deals.round_id
-- ------------------------------------------------------------
alter table app.deals
  add column if not exists round_id uuid;

alter table app.deals
  drop constraint if exists deals_round_id_fkey;

alter table app.deals
  add constraint deals_round_id_fkey
  foreign key (round_id) references app.rounds (id) on delete set null;

create index if not exists deals_round_id_idx
  on app.deals (round_id) where round_id is not null;


-- ------------------------------------------------------------
-- 4) app.campaigns.organization_id default
--    Without this the column is NOT NULL with no default, the client omits it,
--    and the RLS WITH CHECK (organization_id = current_organization_id())
--    rejects the row. Matches app.deal_parties.organization_id.
-- ------------------------------------------------------------
alter table app.campaigns
  alter column organization_id set default app.current_organization_id();


-- ------------------------------------------------------------
-- 5) The two rounds
--    target_amount for the Seed round is left NULL on purpose -- set it with
--    the statement at the bottom of this file once the figure is final.
-- ------------------------------------------------------------
insert into app.rounds
  (organization_id, name, round_type, currency, status, opened_at, notes)
values
  ('b25de8f2-1020-482f-9012-183f63883169',
   '2026 Bridge Round',
   'bridge',
   'USD',
   'closed',
   null,
   'Closed out. Holds the 250 investor deals enrolled by sector in July 2026.'),
  ('b25de8f2-1020-482f-9012-183f63883169',
   'MarineBio Group, Inc. 2026 Seed Round',
   'seed',
   'USD',
   'open',
   current_date,
   'Seed round opened September 2026.')
on conflict (organization_id, name) do nothing;


-- ------------------------------------------------------------
-- 6) Backfill: existing Bridge Round deals -> 2026 Bridge Round
--    Only investor-pipeline deals whose campaign name starts with
--    "Bridge Round" (the three sector campaigns: 120 + 60 + 70 = 250).
--    Network campaign deals (Capital Factory, Houston Angel, Houston Sweep)
--    are left with round_id NULL so they can be assigned by hand.
-- ------------------------------------------------------------
update app.deals d
set round_id = r.id
from app.rounds r
where r.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and r.name = '2026 Bridge Round'
  and d.round_id is null
  and d.deleted_at is null
  and d.pipeline_id = (select p.id from app.pipelines p where p.code = 'investors')
  and d.campaign_id in (
    select c.id from app.campaigns c where c.name like 'Bridge Round%'
  );


-- ------------------------------------------------------------
-- 7) Verification -- read these result sets before moving on
-- ------------------------------------------------------------

-- 7a) the rounds that now exist
select id, name, round_type, status, currency, target_amount, opened_at
from app.rounds
order by created_at;

-- 7b) deal counts per round (expect: Bridge 250, Seed 0, unassigned 6)
select coalesce(r.name, '(no round)') as round_name,
       count(*) as live_deals
from app.deals d
left join app.rounds r on r.id = d.round_id
where d.deleted_at is null
  and d.pipeline_id = (select p.id from app.pipelines p where p.code = 'investors')
group by coalesce(r.name, '(no round)')
order by live_deals desc;

-- 7c) which deals are still unassigned (should be the 6 network ones)
select d.deal_name, c.name as campaign_name, s.name as stage_name
from app.deals d
left join app.campaigns c on c.id = d.campaign_id
left join app.stages s on s.id = d.current_stage_id
where d.deleted_at is null
  and d.round_id is null
  and d.pipeline_id = (select p.id from app.pipelines p where p.code = 'investors')
order by d.deal_name;

-- 7d) confirm the campaigns default is in place (expect a default, not '-')
select column_name, is_nullable, column_default
from information_schema.columns
where table_schema = 'app'
  and table_name = 'campaigns'
  and column_name = 'organization_id';


-- ============================================================
-- 8) SET THE SEED TARGET AMOUNT
--
-- Uncomment the statement below, replace 0 with the real figure, highlight
-- just that statement and run it. Left commented so no invented number is
-- ever written.
--
-- update app.rounds
--    set target_amount = 0
--  where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
--    and name = 'MarineBio Group, Inc. 2026 Seed Round';
-- ============================================================
