-- ============================================================
-- 20260620370002_global_investors_batch2.sql
-- Global (non-US) investor enrichment BATCH 2: gap geographies +
-- MBG-core sectors (advanced materials / industrial / climate / deep tech / life science).
-- 20 firms: Japan, Canada, Nordics, Middle East, NL/FR/BE/CH/DE.
-- Source tag: investor_global_2026Q3_b2.
--
-- Dedup: checked against live type-1 list incl. batch-1 (2026-06-20).
-- All 20 names are new. NOT EXISTS guard is a backstop.
-- Verified per firm (web research, 2026-06): real firm, HQ, active investor, sector + stage.
--
-- Vocab (live, locked 2026-06-20):
--   party_types.investor=1, entity_types.company=1
--   investor_types: vc=1, cvc=3   (Aramco Ventures = cvc)
--   sectors: advanced_materials=1, industrial=2, deep_tech=3, climate=4,
--            energy=5, healthcare=9, food_ag=12, life_science=16
--   stages: seed=2, series_a=3, series_b=4, series_c=5, early=10, growth=11, late=12
-- ============================================================

begin;

-- ---------- 1) parties ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, status, source,
   country_code, region, city, website, organization_id)
select v.* from (values
  (1::smallint,1::smallint,'Universal Materials Incubator','active','investor_global_2026Q3_b2','JP',NULL,'Tokyo','https://www.umi.co.jp','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Beyond Next Ventures','active','investor_global_2026Q3_b2','JP',NULL,'Tokyo','https://beyondnextventures.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Real Tech Holdings','active','investor_global_2026Q3_b2','JP',NULL,'Tokyo','https://www.realtech.holdings','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Global Brain','active','investor_global_2026Q3_b2','JP',NULL,'Tokyo','https://globalbrains.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'BDC Capital','active','investor_global_2026Q3_b2','CA',NULL,'Montreal','https://www.bdc.ca','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Lumira Ventures','active','investor_global_2026Q3_b2','CA',NULL,'Toronto','https://www.lumiraventures.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Amplitude Ventures','active','investor_global_2026Q3_b2','CA',NULL,'Montreal','https://www.amplitudevc.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Cycle Capital','active','investor_global_2026Q3_b2','CA',NULL,'Montreal','https://www.cyclecapital.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Climentum Capital','active','investor_global_2026Q3_b2','DK',NULL,'Copenhagen','https://climentum.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Industrifonden','active','investor_global_2026Q3_b2','SE',NULL,'Stockholm','https://industrifonden.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Pale Blue Dot','active','investor_global_2026Q3_b2','SE',NULL,'Malmo','https://paleblue.vc','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'2150','active','investor_global_2026Q3_b2','GB',NULL,'London','https://www.2150.vc','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Aramco Ventures','active','investor_global_2026Q3_b2','SA',NULL,'Dhahran','https://www.aramcoventures.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'EQT Life Sciences','active','investor_global_2026Q3_b2','NL',NULL,'Amsterdam','https://eqtgroup.com/private-capital/eqt-life-sciences','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Gilde Healthcare','active','investor_global_2026Q3_b2','NL',NULL,'Utrecht','https://gildehealthcare.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Seventure Partners','active','investor_global_2026Q3_b2','FR',NULL,'Paris','https://www.seventure.fr','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Jeito Capital','active','investor_global_2026Q3_b2','FR',NULL,'Paris','https://www.jeito.life','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'V-Bio Ventures','active','investor_global_2026Q3_b2','BE',NULL,'Ghent','https://v-bio.ventures','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Verve Ventures','active','investor_global_2026Q3_b2','CH',NULL,'Zurich','https://www.verve.vc','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'High-Tech Gruenderfonds','active','investor_global_2026Q3_b2','DE',NULL,'Bonn','https://www.htgf.de','b25de8f2-1020-482f-9012-183f63883169'::uuid)
) as v(party_type_id, entity_type_id, party_name, status, source,
       country_code, region, city, website, organization_id)
where not exists (select 1 from app.parties p where p.party_name = v.party_name and p.deleted_at is null);

-- ---------- 2) investor_profile ----------
-- investor_type_id=1 (vc)
insert into app.investor_profile
  (party_id, investor_type_id, sector_focus, geographic_focus, is_lead_investor, organization_id)
select p.id, 1::smallint, v.sector_focus, v.geographic_focus, true, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p
join (values
  ('Universal Materials Incubator', array['advanced_materials','industrial','climate']::text[], array['Asia','Japan']::text[]),
  ('Beyond Next Ventures', array['deep_tech','life_science']::text[], array['Asia','Japan']::text[]),
  ('Real Tech Holdings', array['deep_tech','climate','industrial']::text[], array['Asia','Japan']::text[]),
  ('Global Brain', array['deep_tech']::text[], array['Asia','Japan']::text[]),
  ('BDC Capital', array['deep_tech','climate','life_science']::text[], array['North America','Canada']::text[]),
  ('Lumira Ventures', array['life_science','healthcare']::text[], array['North America','Canada']::text[]),
  ('Amplitude Ventures', array['life_science','healthcare']::text[], array['North America','Canada']::text[]),
  ('Cycle Capital', array['climate','industrial','advanced_materials']::text[], array['North America','Canada']::text[]),
  ('Climentum Capital', array['climate','industrial','advanced_materials']::text[], array['Europe','Nordics']::text[]),
  ('Industrifonden', array['deep_tech','life_science']::text[], array['Europe','Nordics']::text[]),
  ('Pale Blue Dot', array['climate','industrial']::text[], array['Europe','Nordics']::text[]),
  ('2150', array['climate','industrial']::text[], array['Europe','Global']::text[]),
  ('EQT Life Sciences', array['life_science','healthcare']::text[], array['Europe','Global']::text[]),
  ('Gilde Healthcare', array['life_science','healthcare','climate']::text[], array['Europe','North America']::text[]),
  ('Seventure Partners', array['life_science','food_ag']::text[], array['Europe','Global']::text[]),
  ('Jeito Capital', array['life_science','healthcare']::text[], array['Europe','Global']::text[]),
  ('V-Bio Ventures', array['life_science']::text[], array['Europe']::text[]),
  ('Verve Ventures', array['deep_tech','life_science','energy']::text[], array['Europe','Global']::text[]),
  ('High-Tech Gruenderfonds', array['deep_tech','industrial']::text[], array['Europe']::text[])
) as v(party_name, sector_focus, geographic_focus) on v.party_name = p.party_name
where p.source = 'investor_global_2026Q3_b2' and p.deleted_at is null
  and not exists (select 1 from app.investor_profile ip where ip.party_id = p.id);

-- investor_type_id=3 (cvc)
insert into app.investor_profile
  (party_id, investor_type_id, sector_focus, geographic_focus, is_lead_investor, organization_id)
select p.id, 3::smallint, v.sector_focus, v.geographic_focus, true, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p
join (values
  ('Aramco Ventures', array['advanced_materials','industrial','climate','energy']::text[], array['Middle East','Global']::text[])
) as v(party_name, sector_focus, geographic_focus) on v.party_name = p.party_name
where p.source = 'investor_global_2026Q3_b2' and p.deleted_at is null
  and not exists (select 1 from app.investor_profile ip where ip.party_id = p.id);

-- ---------- 3) investor_sector_focus ----------
insert into app.investor_sector_focus (investor_profile_id, sector_id, organization_id)
select ip.id, v.sector_id::smallint, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p join app.investor_profile ip on ip.party_id = p.id
join (values
  ('Universal Materials Incubator', 1),
  ('Universal Materials Incubator', 2),
  ('Universal Materials Incubator', 4),
  ('Beyond Next Ventures', 3),
  ('Beyond Next Ventures', 16),
  ('Real Tech Holdings', 3),
  ('Real Tech Holdings', 4),
  ('Real Tech Holdings', 2),
  ('Global Brain', 3),
  ('BDC Capital', 3),
  ('BDC Capital', 4),
  ('BDC Capital', 16),
  ('Lumira Ventures', 16),
  ('Lumira Ventures', 9),
  ('Amplitude Ventures', 16),
  ('Amplitude Ventures', 9),
  ('Cycle Capital', 4),
  ('Cycle Capital', 2),
  ('Cycle Capital', 1),
  ('Climentum Capital', 4),
  ('Climentum Capital', 2),
  ('Climentum Capital', 1),
  ('Industrifonden', 3),
  ('Industrifonden', 16),
  ('Pale Blue Dot', 4),
  ('Pale Blue Dot', 2),
  ('2150', 4),
  ('2150', 2),
  ('Aramco Ventures', 1),
  ('Aramco Ventures', 2),
  ('Aramco Ventures', 4),
  ('Aramco Ventures', 5),
  ('EQT Life Sciences', 16),
  ('EQT Life Sciences', 9),
  ('Gilde Healthcare', 16),
  ('Gilde Healthcare', 9),
  ('Gilde Healthcare', 4),
  ('Seventure Partners', 16),
  ('Seventure Partners', 12),
  ('Jeito Capital', 16),
  ('Jeito Capital', 9),
  ('V-Bio Ventures', 16),
  ('Verve Ventures', 3),
  ('Verve Ventures', 16),
  ('Verve Ventures', 5),
  ('High-Tech Gruenderfonds', 3),
  ('High-Tech Gruenderfonds', 2)
) as v(party_name, sector_id) on v.party_name = p.party_name
where p.source = 'investor_global_2026Q3_b2' and p.deleted_at is null
  and not exists (select 1 from app.investor_sector_focus x
                  where x.investor_profile_id = ip.id and x.sector_id = v.sector_id);

-- ---------- 4) investor_stage_focus ----------
insert into app.investor_stage_focus (investor_profile_id, stage_id, organization_id)
select ip.id, v.stage_id::smallint, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p join app.investor_profile ip on ip.party_id = p.id
join (values
  ('Universal Materials Incubator', 2),
  ('Universal Materials Incubator', 3),
  ('Beyond Next Ventures', 2),
  ('Beyond Next Ventures', 3),
  ('Beyond Next Ventures', 4),
  ('Real Tech Holdings', 2),
  ('Real Tech Holdings', 3),
  ('Real Tech Holdings', 4),
  ('Global Brain', 3),
  ('Global Brain', 4),
  ('BDC Capital', 2),
  ('BDC Capital', 3),
  ('BDC Capital', 4),
  ('BDC Capital', 11),
  ('Lumira Ventures', 2),
  ('Lumira Ventures', 3),
  ('Lumira Ventures', 4),
  ('Amplitude Ventures', 2),
  ('Amplitude Ventures', 3),
  ('Amplitude Ventures', 4),
  ('Cycle Capital', 2),
  ('Cycle Capital', 3),
  ('Cycle Capital', 4),
  ('Climentum Capital', 2),
  ('Climentum Capital', 3),
  ('Industrifonden', 2),
  ('Industrifonden', 3),
  ('Industrifonden', 4),
  ('Industrifonden', 11),
  ('Pale Blue Dot', 2),
  ('Pale Blue Dot', 3),
  ('2150', 2),
  ('2150', 3),
  ('2150', 4),
  ('Aramco Ventures', 3),
  ('Aramco Ventures', 4),
  ('Aramco Ventures', 11),
  ('EQT Life Sciences', 3),
  ('EQT Life Sciences', 4),
  ('EQT Life Sciences', 11),
  ('Gilde Healthcare', 3),
  ('Gilde Healthcare', 4),
  ('Gilde Healthcare', 11),
  ('Seventure Partners', 2),
  ('Seventure Partners', 3),
  ('Seventure Partners', 4),
  ('Jeito Capital', 3),
  ('Jeito Capital', 4),
  ('Jeito Capital', 11),
  ('V-Bio Ventures', 2),
  ('V-Bio Ventures', 3),
  ('Verve Ventures', 2),
  ('Verve Ventures', 3),
  ('Verve Ventures', 4),
  ('High-Tech Gruenderfonds', 2),
  ('High-Tech Gruenderfonds', 3)
) as v(party_name, stage_id) on v.party_name = p.party_name
where p.source = 'investor_global_2026Q3_b2' and p.deleted_at is null
  and not exists (select 1 from app.investor_stage_focus x
                  where x.investor_profile_id = ip.id and x.stage_id = v.stage_id);

commit;

-- Verify:
--   select count(*) from app.parties where source='investor_global_2026Q3_b2'; -- expect 20
--   select sec.code, count(distinct p.id) from app.parties p
--     join app.investor_profile ip on ip.party_id=p.id
--     join app.investor_sector_focus isf on isf.investor_profile_id=ip.id
--     join app.sectors sec on sec.id=isf.sector_id
--     where p.source='investor_global_2026Q3_b2' and p.deleted_at is null group by sec.code order by 2 desc;
--   select coalesce(country_code,'(null)') cc, count(*) n from app.parties
--     where source='investor_global_2026Q3_b2' group by 1 order by 2 desc;
-- Rollback: delete from app.parties where source='investor_global_2026Q3_b2';
