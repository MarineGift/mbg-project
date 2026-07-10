-- supabase/migrations/20260701_campaign_dataroom.sql
-- Consolidates "data rooms" INTO campaigns:
--   * app.campaign_folders   - Drive folders per campaign
--   * app.campaign_materials - prep checklist per campaign
--   * seeds the Pangaea seed round as a fundraising campaign (folders + checklist)
--   * deletes all (test) deals, then makes deals.campaign_id NOT NULL with a
--     BEFORE INSERT trigger defaulting to a "General" fallback campaign, so
--     every deal belongs to a campaign and no existing insert path breaks.
--   * drops the standalone data_room_* tables.
--
-- Wrapped in a transaction: if anything fails, nothing is applied (including the
-- deals delete), so it is safe to fix and re-run. Verified safe against the FK
-- report: communications/engagements are ON DELETE SET NULL (email history is
-- preserved); the CASCADE children are deal-scoped test data.

begin;

-- ---------- 1) materials tables ----------
create table if not exists app.campaign_folders (
  id              uuid primary key default gen_random_uuid(),
  campaign_id     uuid not null references app.campaigns(id) on delete cascade,
  name            text not null,
  drive_folder_id text not null,
  sort_order      int  not null default 0
);
create index if not exists campaign_folders_campaign_idx on app.campaign_folders(campaign_id);
alter table app.campaign_folders enable row level security;
drop policy if exists campaign_folders_rw on app.campaign_folders;
create policy campaign_folders_rw on app.campaign_folders
  for all to authenticated
  using (campaign_id in (select id from app.campaigns))
  with check (campaign_id in (select id from app.campaigns));
grant select, insert, update, delete on app.campaign_folders to authenticated;

create table if not exists app.campaign_materials (
  id           uuid primary key default gen_random_uuid(),
  campaign_id  uuid not null references app.campaigns(id) on delete cascade,
  section    text not null,
  item_key   text not null,
  label      text not null,
  detail     text,
  status     text not null default 'not_started'
               check (status in ('not_started','in_progress','ready','private')),
  sort_order int  not null default 0,
  updated_at timestamptz not null default now(),
  unique (campaign_id, item_key)
);
create index if not exists campaign_materials_campaign_idx on app.campaign_materials(campaign_id);
alter table app.campaign_materials enable row level security;
drop policy if exists campaign_materials_rw on app.campaign_materials;
create policy campaign_materials_rw on app.campaign_materials
  for all to authenticated
  using (campaign_id in (select id from app.campaigns))
  with check (campaign_id in (select id from app.campaigns));
grant select, insert, update, delete on app.campaign_materials to authenticated;

-- ---------- 2) campaigns: Pangaea (fundraising) + General fallback ----------
-- created_by / organization_id set explicitly (SQL editor has no JWT).
insert into app.campaigns (id, organization_id, created_by, name, campaign_type, description, status) values
 ('d0000000-0000-4000-8000-0000000000fe',
  'b25de8f2-1020-482f-9012-183f63883169',
  '551fc4a0-b365-47eb-bf2f-0c3f594001c0',
  'Seed Round - Pangaea (Andrew)',
  'fundraising',
  '$1M for 5% - $20M pre-money - first meeting Jul 8, 2026 (Andrew Haughian, Pangaea Ventures)',
  'active')
on conflict (id) do nothing;

insert into app.campaigns (id, organization_id, created_by, name, campaign_type, description, status) values
 ('d0000000-0000-4000-8000-0000000000ff',
  'b25de8f2-1020-482f-9012-183f63883169',
  '551fc4a0-b365-47eb-bf2f-0c3f594001c0',
  'General (unassigned)',
  null,
  'System fallback: deals created without a campaign are attached here.',
  'archived')
on conflict (id) do nothing;

-- ---------- 3) seed Pangaea folders + checklist ----------
insert into app.campaign_folders (campaign_id, name, drive_folder_id, sort_order) values
 ('d0000000-0000-4000-8000-0000000000fe','IR Data Room (top)','1xIgu2Cdkf5kKXYeRn9Vy50l6QHLUQ3Zj',10),
 ('d0000000-0000-4000-8000-0000000000fe','00 - Pitch deck','1UqHcdR2rytFk6ML-25iJA-j0ddlR1p0A',20),
 ('d0000000-0000-4000-8000-0000000000fe','01 - One-pager','1xWxiR0qxH4Qd6J1ikxSWT4f0bwFK9q51',30),
 ('d0000000-0000-4000-8000-0000000000fe','02 - Data room','1EZOTpzKrLeBkXY4Z01ZqbVyveBeZe2pf',40),
 ('d0000000-0000-4000-8000-0000000000fe','03 - Investor targets','1URF8eVrOiotvXqnOXQTM1nK2YXxCxEsb',50),
 ('d0000000-0000-4000-8000-0000000000fe','04 - Outreach','1yv2mk5CbGGh4g9GWRiEk4xeBydSk21CU',60),
 ('d0000000-0000-4000-8000-0000000000fe','05 - Archive','119EJzgHVe2fcWbmvlZzmYzu5wGa45pRQ',70)
on conflict do nothing;

insert into app.campaign_materials (campaign_id, section, item_key, label, detail, status, sort_order) values
 ('d0000000-0000-4000-8000-0000000000fe','Pitch materials','deck','Pitch deck (Share, anonymized)','Ver3.3 built - upload to 00_Pitch, set view-only','ready',10),
 ('d0000000-0000-4000-8000-0000000000fe','Pitch materials','onepager','One-pager (PDF)','Built - fill email field, upload to 01_OnePager','ready',20),
 ('d0000000-0000-4000-8000-0000000000fe','Pitch materials','qa','Anticipated Q&A doc','Built - paste SMI inbound + Q11.5 blocks','in_progress',30),
 ('d0000000-0000-4000-8000-0000000000fe','Pitch materials','email','Andrew intro email','Draft ready - not sent (attach deck + one-pager)','in_progress',40),
 ('d0000000-0000-4000-8000-0000000000fe','Data room - IP','ip_patents','Patent filings / certificates','Add PDFs: 5 granted + PCT + USPTO 19/396,332','in_progress',110),
 ('d0000000-0000-4000-8000-0000000000fe','Data room - IP','ip_defense','Patent defense (KIPO rejection)','Upload KR 10-2023-0192566 rejection + USPTO/EPO submissions','in_progress',120),
 ('d0000000-0000-4000-8000-0000000000fe','Data room - IP','ip_papers','ACS papers','Upload 2020 Sustainable Chem Eng + 2022 Omega PDFs','in_progress',130),
 ('d0000000-0000-4000-8000-0000000000fe','Data room - core (gaps)','fin_model','Financial model (3-yr royalty)','Contracted vs pipeline split','not_started',210),
 ('d0000000-0000-4000-8000-0000000000fe','Data room - core (gaps)','cap_table','Cap table','Current + post-money at 1M / 5%','not_started',220),
 ('d0000000-0000-4000-8000-0000000000fe','Data room - core (gaps)','legal','Legal / agreements','Incorporation, key agreements','not_started',230),
 ('d0000000-0000-4000-8000-0000000000fe','Data room - core (gaps)','us_entity','US entity docs','Austin entity formation','not_started',240),
 ('d0000000-0000-4000-8000-0000000000fe','Data room - core (gaps)','banking','Banking / tax (PRIVATE)','Never in any share link','private',250),
 ('d0000000-0000-4000-8000-0000000000fe','Deal-critical before Jul 8','chain_of_title','IP chain-of-title','500K patent transfer: from whom, arm-length, to US entity (Q11)','not_started',310),
 ('d0000000-0000-4000-8000-0000000000fe','Deal-critical before Jul 8','confirmed_9000','9,000 t confirmed - what exactly','PO / supply order / LOI; pipeline status (Q5)','not_started',320),
 ('d0000000-0000-4000-8000-0000000000fe','Deal-critical before Jul 8','floor_split','Contracted vs pipeline split','Show the floor, not only the projection (Q13/Q14)','not_started',330),
 ('d0000000-0000-4000-8000-0000000000fe','Deal-critical before Jul 8','nda_template','NDA template','Ready to open the data room on real interest (Q6)','not_started',340),
 ('d0000000-0000-4000-8000-0000000000fe','Deal-critical before Jul 8','us_lead','US commercial lead','Who runs US scaling; this round or Series A (Q19)','not_started',350),
 ('d0000000-0000-4000-8000-0000000000fe','Deal-critical before Jul 8','biggest_risk','Biggest-risk answer','One real risk + its mitigation (Q23)','not_started',360),
 ('d0000000-0000-4000-8000-0000000000fe','Outreach','investor_list','Investor target list (69)','Optional - save CSV to 03_Investor_Targets','not_started',410)
on conflict (campaign_id, item_key) do nothing;

-- ---------- 4) deals: campaign-first ----------
-- delete all (test) deals. CASCADE clears deal-scoped children; communications /
-- engagements are SET NULL (email history kept). parties/contacts untouched.
delete from app.deals;

-- ensure column + FK, then make it required with a fallback-defaulting trigger.
alter table app.deals add column if not exists campaign_id uuid;

do $$
begin
  if not exists (
    select 1
    from information_schema.key_column_usage kcu
    join information_schema.table_constraints tc
      on tc.constraint_name = kcu.constraint_name and tc.table_schema = kcu.table_schema
    where tc.table_schema = 'app' and tc.table_name = 'deals'
      and tc.constraint_type = 'FOREIGN KEY' and kcu.column_name = 'campaign_id'
  ) then
    alter table app.deals
      add constraint deals_campaign_id_fkey
      foreign key (campaign_id) references app.campaigns(id) on delete restrict;
  end if;
end $$;

create or replace function app.deals_default_campaign()
returns trigger language plpgsql as $$
begin
  if new.campaign_id is null then
    new.campaign_id := 'd0000000-0000-4000-8000-0000000000ff';  -- General fallback
  end if;
  return new;
end $$;

drop trigger if exists deals_default_campaign_trg on app.deals;
create trigger deals_default_campaign_trg
  before insert on app.deals
  for each row execute function app.deals_default_campaign();

alter table app.deals alter column campaign_id set not null;

-- ---------- 5) retire the standalone data_room_* tables ----------
drop table if exists app.data_room_items cascade;
drop table if exists app.data_room_folders cascade;
drop table if exists app.data_rooms cascade;

commit;
