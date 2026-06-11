-- ============================================================
-- 20260612040000_tx_investor_inserts_batch1.sql
-- Insert NEW verified Texas investors (not previously in DB).
-- Targets the weak sectors: deep_tech / advanced_materials /
-- life_science. Source tag: investor_enrich_2026Q3.
--
-- Verified vocab (live, 2026-06-12):
--   party_types.investor       = 1
--   entity_types.company       = 1   (fund = 4)
--   investor_types.vc          = 1
--   sectors: advanced_materials=1, deep_tech=3, ai=6,
--            healthcare=9, life_science=16, energy=5,
--            mobility=11, industrial=2
--   investment_stages: seed=2, series_a=3, series_b=4,
--                      series_c=5, early=10, growth=11
--
-- Each firm gets: parties + investor_profile (with array
-- focus mirrored) + investor_sector_focus + investor_stage_focus.
-- Idempotent on parties via NOT EXISTS(party_name).
-- ============================================================

begin;

-- ---------- 1) parties ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, status, source,
   country_code, region, city, website, founded_year,
   organization_id)
select v.* from (values
  (1::smallint, 1::smallint, 'Gigafund', 'active',
   'investor_enrich_2026Q3', 'US', 'TX', 'Austin',
   'https://www.gigafund.com', 2017,
   'b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint, 1::smallint, 'Bios Partners', 'active',
   'investor_enrich_2026Q3', 'US', 'TX', 'Fort Worth',
   'https://biospartners.com', 2014,
   'b25de8f2-1020-482f-9012-183f63883169'::uuid)
) as v(party_type_id, entity_type_id, party_name, status, source,
       country_code, region, city, website, founded_year,
       organization_id)
where not exists (
  select 1 from app.parties p
  where p.party_name = v.party_name and p.deleted_at is null
);

-- ---------- 2) investor_profile ----------
-- Gigafund: deep tech, multi-stage concentrated, lead investor
insert into app.investor_profile
  (party_id, investor_type_id, sector_focus, geographic_focus,
   is_lead_investor, is_strategic, organization_id)
select p.id, 1::smallint,
       array['deep_tech','energy','mobility','industrial']::text[],
       array['US']::text[],
       true, false,
       'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p
where p.party_name = 'Gigafund' and p.deleted_at is null
  and not exists (select 1 from app.investor_profile ip where ip.party_id = p.id);

-- Bios Partners: life science / healthcare, Series A-B, lead
insert into app.investor_profile
  (party_id, investor_type_id, sector_focus, geographic_focus,
   is_lead_investor, is_strategic, organization_id)
select p.id, 1::smallint,
       array['life_science','healthcare']::text[],
       array['US']::text[],
       true, false,
       'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p
where p.party_name = 'Bios Partners' and p.deleted_at is null
  and not exists (select 1 from app.investor_profile ip where ip.party_id = p.id);

-- ---------- 3) investor_sector_focus (normalized chips) ----------
with focus(party_name, sector_id) as (
  values
    ('Gigafund',       3), ('Gigafund',       5),
    ('Gigafund',      11), ('Gigafund',       2),
    ('Bios Partners', 16), ('Bios Partners',  9)
)
insert into app.investor_sector_focus
  (investor_profile_id, sector_id, organization_id)
select ip.id, f.sector_id::smallint,
       'b25de8f2-1020-482f-9012-183f63883169'::uuid
from focus f
join app.parties p on p.party_name = f.party_name and p.deleted_at is null
join app.investor_profile ip on ip.party_id = p.id
where not exists (
  select 1 from app.investor_sector_focus x
  where x.investor_profile_id = ip.id and x.sector_id = f.sector_id
);

-- ---------- 4) investor_stage_focus ----------
with stages(party_name, stage_id) as (
  values
    -- Gigafund: multi-stage, concentrated (seed through growth)
    ('Gigafund',       2), ('Gigafund',       3),
    ('Gigafund',       4), ('Gigafund',      11),
    -- Bios Partners: Series A / B (+ seed entry)
    ('Bios Partners',  2), ('Bios Partners',  3),
    ('Bios Partners',  4)
)
insert into app.investor_stage_focus
  (investor_profile_id, stage_id, organization_id)
select ip.id, s.stage_id::smallint,
       'b25de8f2-1020-482f-9012-183f63883169'::uuid
from stages s
join app.parties p on p.party_name = s.party_name and p.deleted_at is null
join app.investor_profile ip on ip.party_id = p.id
where not exists (
  select 1 from app.investor_stage_focus x
  where x.investor_profile_id = ip.id and x.stage_id = s.stage_id
);

commit;

-- Verify:
-- select p.party_name, p.city, it.code as type,
--        string_agg(distinct sec.code, ', ') as sectors,
--        string_agg(distinct ist.code, ', ') as stages
-- from app.parties p
-- join app.investor_profile ip on ip.party_id = p.id
-- join app.investor_types it on it.id = ip.investor_type_id
-- left join app.investor_sector_focus isf on isf.investor_profile_id = ip.id
-- left join app.sectors sec on sec.id = isf.sector_id
-- left join app.investor_stage_focus istf on istf.investor_profile_id = ip.id
-- left join app.investment_stages ist on ist.id = istf.stage_id
-- where p.source = 'investor_enrich_2026Q3'
-- group by p.party_name, p.city, it.code;
--
-- Rollback this batch:
-- delete from app.parties where source = 'investor_enrich_2026Q3';
--   (cascades to investor_profile / focus rows via FK)
