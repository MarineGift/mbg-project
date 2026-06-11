-- ============================================================
-- 20260612070000_dedup_duplicate_large_funds.sql
-- Merge duplicate investor parties (legacy ingest created two
-- rows for several large funds). Strategy:
--   1) Union-merge sector tags onto the KEEP row.
--   2) Soft-delete (deleted_at) the duplicate row(s).
--
-- KEEP / DROP decided from live audit (2026-06-12):
--   DCVC:  keep 'Data Collective Venture Capital'  drop 'DCVC (Data Collective)'
--   FF:    keep 'Founders Fund LLC'                drop 'Founders Fund'
--   GC:    keep 'General Catalyst Partners LLC'    drop 'General Catalyst'
--   Khosla:keep 'Khosla Ventures LLC'              drop 'Khosla Ventures'
--   Lux:   keep 'Lux Capital Management LLC'(deal) drop 'Lux Capital'
--   NEA:   keep 'New Enterprise Associates (NEA)'  drop 'NEA Management Company LLC',
--                                                       'New Enterprise Associates, Inc.'
--
-- deal_links verified: only Lux Capital Management LLC has a deal
-- link (=1) and it is the KEEP row, so no deal references are lost.
-- All DROP rows have deal_links=0.
--
-- Idempotent-ish: re-running re-soft-deletes (no-op) and the tag
-- merge uses NOT EXISTS guards.
-- ============================================================

begin;

-- helper: resolve party_id by exact name (active only)
-- (inline via subselects below)

-- ---------- 1) Merge missing sector tags onto KEEP rows ----------
-- For each (keep, drop) pair, copy any sector_id present on DROP's
-- profile but missing on KEEP's profile.
with pairs(keep_name, drop_name) as (
  values
    ('Data Collective Venture Capital','DCVC (Data Collective)'),
    ('Founders Fund LLC','Founders Fund'),
    ('General Catalyst Partners LLC','General Catalyst'),
    ('Khosla Ventures LLC','Khosla Ventures'),
    ('Lux Capital Management LLC','Lux Capital'),
    ('New Enterprise Associates (NEA)','NEA Management Company LLC'),
    ('New Enterprise Associates (NEA)','New Enterprise Associates, Inc.')
)
insert into app.investor_sector_focus (investor_profile_id, sector_id, organization_id)
select keep_ip.id, drop_isf.sector_id,
       'b25de8f2-1020-482f-9012-183f63883169'::uuid
from pairs
join app.parties keep_p
  on keep_p.party_name = pairs.keep_name and keep_p.deleted_at is null
join app.investor_profile keep_ip on keep_ip.party_id = keep_p.id
join app.parties drop_p
  on drop_p.party_name = pairs.drop_name and drop_p.deleted_at is null
join app.investor_profile drop_ip on drop_ip.party_id = drop_p.id
join app.investor_sector_focus drop_isf
  on drop_isf.investor_profile_id = drop_ip.id
where not exists (
  select 1 from app.investor_sector_focus k
  where k.investor_profile_id = keep_ip.id
    and k.sector_id = drop_isf.sector_id
);

-- ---------- 2) Merge missing stage tags onto KEEP rows ----------
with pairs(keep_name, drop_name) as (
  values
    ('Data Collective Venture Capital','DCVC (Data Collective)'),
    ('Founders Fund LLC','Founders Fund'),
    ('General Catalyst Partners LLC','General Catalyst'),
    ('Khosla Ventures LLC','Khosla Ventures'),
    ('Lux Capital Management LLC','Lux Capital'),
    ('New Enterprise Associates (NEA)','NEA Management Company LLC'),
    ('New Enterprise Associates (NEA)','New Enterprise Associates, Inc.')
)
insert into app.investor_stage_focus (investor_profile_id, stage_id, organization_id)
select keep_ip.id, drop_istf.stage_id,
       'b25de8f2-1020-482f-9012-183f63883169'::uuid
from pairs
join app.parties keep_p
  on keep_p.party_name = pairs.keep_name and keep_p.deleted_at is null
join app.investor_profile keep_ip on keep_ip.party_id = keep_p.id
join app.parties drop_p
  on drop_p.party_name = pairs.drop_name and drop_p.deleted_at is null
join app.investor_profile drop_ip on drop_ip.party_id = drop_p.id
join app.investor_stage_focus drop_istf
  on drop_istf.investor_profile_id = drop_ip.id
where not exists (
  select 1 from app.investor_stage_focus k
  where k.investor_profile_id = keep_ip.id
    and k.stage_id = drop_istf.stage_id
);

-- ---------- 3) Soft-delete the duplicate rows ----------
update app.parties
set deleted_at = now()
where deleted_at is null
  and party_name in (
    'DCVC (Data Collective)',
    'Founders Fund',
    'General Catalyst',
    'Khosla Ventures',
    'NEA Management Company LLC',
    'New Enterprise Associates, Inc.'
  );

-- Lux: drop 'Lux Capital' (keep the Management LLC row with the deal link)
update app.parties
set deleted_at = now()
where deleted_at is null
  and party_name = 'Lux Capital';

commit;

-- Verify: each fund should now resolve to ONE active row
-- select party_name from app.parties
-- where deleted_at is null
--   and party_name ~* 'data collective|dcvc|founders fund|general catalyst|khosla|lux capital|enterprise associates|nea management'
-- order by party_name;
--
-- Rollback: un-delete (tag merges are harmless to keep)
-- update app.parties set deleted_at = null
-- where party_name in ('DCVC (Data Collective)','Founders Fund','General Catalyst',
--   'Khosla Ventures','NEA Management Company LLC','New Enterprise Associates, Inc.','Lux Capital');
