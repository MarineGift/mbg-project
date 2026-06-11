-- ============================================================
-- 20260612030000_tx_investor_target_sector_tagging.sql
-- Fix missing sector / stage focus tags on existing TX
-- investors (verified against live audit, 2026-06-12).
-- Conservative set: only firms whose focus was verified.
--
-- sector ids : advanced_materials=1, deep_tech=3, life_science=16
-- stage ids  : seed=2, series_a=3, series_b=4 (app.investment_stages)
--
-- Idempotent: NOT EXISTS guards; safe to re-run.
-- Rollback hint: rows are identifiable by created_at >= '2026-06-12'.
-- ============================================================

begin;

-- 1) Sector focus additions
with adds(party_name, sector_id) as (
  values
    -- life_science (16)
    ('Sante Ventures',               16),
    ('TMC Innovation (TMCi)',        16),
    ('Health Wildcatters',           16),
    ('Green Park & Golf Ventures',   16),
    ('Vesalius Ventures',            16),
    ('First Bight Ventures',         16),
    -- deep_tech (3)
    ('First Bight Ventures',          3),
    ('Trust Ventures',                3),
    -- advanced_materials (1)
    ('Scout Ventures',                1),
    ('Chevron Technology Ventures',   1)
)
insert into app.investor_sector_focus
  (investor_profile_id, sector_id, organization_id)
select ip.id, a.sector_id::smallint,
       'b25de8f2-1020-482f-9012-183f63883169'::uuid
from adds a
join app.parties p
  on p.party_name = a.party_name and p.deleted_at is null
join app.party_types pt
  on pt.id = p.party_type_id and pt.code = 'investor'
join app.investor_profile ip
  on ip.party_id = p.id
where not exists (
  select 1 from app.investor_sector_focus x
  where x.investor_profile_id = ip.id
    and x.sector_id = a.sector_id
);

-- 2) Stage focus additions (Series A+ visibility)
with adds(party_name, stage_id) as (
  values
    ('Sante Ventures', 2),  -- seed
    ('Sante Ventures', 3),  -- series_a (leads seed / Series A)
    ('S3 Ventures',    3),  -- series_a (leads A/B)
    ('S3 Ventures',    4),  -- series_b
    ('Scout Ventures', 3),  -- series_a (seed lead, follows thru B)
    ('Scout Ventures', 4),  -- series_b
    ('KdT Ventures',   3)   -- series_a (seed lead, follows into A)
)
insert into app.investor_stage_focus
  (investor_profile_id, stage_id, organization_id)
select ip.id, a.stage_id::smallint,
       'b25de8f2-1020-482f-9012-183f63883169'::uuid
from adds a
join app.parties p
  on p.party_name = a.party_name and p.deleted_at is null
join app.party_types pt
  on pt.id = p.party_type_id and pt.code = 'investor'
join app.investor_profile ip
  on ip.party_id = p.id
where not exists (
  select 1 from app.investor_stage_focus x
  where x.investor_profile_id = ip.id
    and x.stage_id = a.stage_id
);

commit;

-- Verify: TX firms per target sector (expect AM 4 / DT 4 / LS 8 in TX)
-- select sec.code, count(distinct p.id) as tx_firms
-- from app.parties p
-- join app.party_types pt on pt.id = p.party_type_id and pt.code='investor'
-- join app.investor_profile ip on ip.party_id = p.id
-- join app.investor_sector_focus isf on isf.investor_profile_id = ip.id
-- join app.sectors sec on sec.id = isf.sector_id
-- where p.region = 'TX' and p.deleted_at is null
--   and sec.code in ('advanced_materials','deep_tech','life_science')
-- group by sec.code;
