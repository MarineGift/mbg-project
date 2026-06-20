-- ============================================================
-- 20260620370003_global_investors_batch3.sql
-- Global investor enrichment BATCH 3: Korea CVC / China hard tech /
-- India + SE Asia deep tech / Middle East sovereign. 11 firms.
-- Source tag: investor_global_2026Q3_b3.
--
-- Dedup: checked against live type-1 list incl. batch-1/2 (2026-06-20). All names new.
-- Verified per firm (web research, 2026-06): real firm, HQ, active investor, sector + stage.
-- NOTE: LG Technology Ventures HQ is Santa Clara, US (LG Group's US-based CVC) -> tagged US.
--       ADQ is an Abu Dhabi sovereign wealth fund -> investor_type 'other'(10).
--       SK Square (SK Group investment holding) -> 'growth_equity'(2).
--
-- Vocab (live, locked 2026-06-20):
--   investor_types: vc=1, growth_equity=2, cvc=3, other=10
--   sectors: advanced_materials=1, industrial=2, deep_tech=3, climate=4, energy=5,
--            ai=6, healthcare=9, food_ag=12, life_science=16
--   stages: seed=2, series_a=3, series_b=4, growth=11
-- ============================================================

begin;

-- ---------- 1) parties ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, status, source,
   country_code, region, city, website, organization_id)
select v.* from (values
  (1::smallint,1::smallint,'Samsung Ventures','active','investor_global_2026Q3_b3','KR',NULL,'Seoul','https://www.samsungventure.co.kr','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'SK Square','active','investor_global_2026Q3_b3','KR',NULL,'Seoul','https://www.sksquare.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'LG Technology Ventures','active','investor_global_2026Q3_b3','US',NULL,'Santa Clara','https://www.lgtechventures.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'IDG Capital','active','investor_global_2026Q3_b3','CN',NULL,'Beijing','https://www.idgcapital.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'GL Ventures','active','investor_global_2026Q3_b3','CN',NULL,'Beijing',NULL,'b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Lotus Lake Ventures','active','investor_global_2026Q3_b3','CN',NULL,'Beijing','https://www.tsinghua-vc.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Blume Ventures','active','investor_global_2026Q3_b3','IN',NULL,'Mumbai','https://blume.vc','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Wavemaker Partners','active','investor_global_2026Q3_b3','SG',NULL,'Singapore','https://wavemakerpartners.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Openspace Ventures','active','investor_global_2026Q3_b3','SG',NULL,'Singapore','https://www.openspace.vc','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'ADQ','active','investor_global_2026Q3_b3','AE',NULL,'Abu Dhabi','https://www.adq.ae','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'KAUST Innovation Ventures','active','investor_global_2026Q3_b3','SA',NULL,'Thuwal','https://innovation.kaust.edu.sa','b25de8f2-1020-482f-9012-183f63883169'::uuid)
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
  ('IDG Capital', array['deep_tech','ai']::text[], array['Asia','Global']::text[]),
  ('GL Ventures', array['deep_tech','advanced_materials','life_science']::text[], array['Asia','Global']::text[]),
  ('Lotus Lake Ventures', array['deep_tech','advanced_materials']::text[], array['Asia','China']::text[]),
  ('Blume Ventures', array['deep_tech']::text[], array['Asia','India']::text[]),
  ('Wavemaker Partners', array['deep_tech','climate','industrial']::text[], array['Asia','Southeast Asia']::text[]),
  ('Openspace Ventures', array['deep_tech','life_science']::text[], array['Asia','Southeast Asia']::text[]),
  ('KAUST Innovation Ventures', array['deep_tech','advanced_materials','life_science']::text[], array['Middle East','Global']::text[])
) as v(party_name, sector_focus, geographic_focus) on v.party_name = p.party_name
where p.source = 'investor_global_2026Q3_b3' and p.deleted_at is null
  and not exists (select 1 from app.investor_profile ip where ip.party_id = p.id);

-- investor_type_id=2 (growth_equity)
insert into app.investor_profile
  (party_id, investor_type_id, sector_focus, geographic_focus, is_lead_investor, organization_id)
select p.id, 2::smallint, v.sector_focus, v.geographic_focus, true, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p
join (values
  ('SK Square', array['deep_tech','advanced_materials','ai']::text[], array['Asia','Korea']::text[])
) as v(party_name, sector_focus, geographic_focus) on v.party_name = p.party_name
where p.source = 'investor_global_2026Q3_b3' and p.deleted_at is null
  and not exists (select 1 from app.investor_profile ip where ip.party_id = p.id);

-- investor_type_id=3 (cvc)
insert into app.investor_profile
  (party_id, investor_type_id, sector_focus, geographic_focus, is_lead_investor, organization_id)
select p.id, 3::smallint, v.sector_focus, v.geographic_focus, true, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p
join (values
  ('Samsung Ventures', array['advanced_materials','deep_tech','life_science']::text[], array['Asia','Global']::text[]),
  ('LG Technology Ventures', array['advanced_materials','deep_tech','life_science']::text[], array['North America','Global']::text[])
) as v(party_name, sector_focus, geographic_focus) on v.party_name = p.party_name
where p.source = 'investor_global_2026Q3_b3' and p.deleted_at is null
  and not exists (select 1 from app.investor_profile ip where ip.party_id = p.id);

-- investor_type_id=10 (other)
insert into app.investor_profile
  (party_id, investor_type_id, sector_focus, geographic_focus, is_lead_investor, organization_id)
select p.id, 10::smallint, v.sector_focus, v.geographic_focus, true, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p
join (values
  ('ADQ', array['industrial','energy','advanced_materials','climate']::text[], array['Middle East','Global']::text[])
) as v(party_name, sector_focus, geographic_focus) on v.party_name = p.party_name
where p.source = 'investor_global_2026Q3_b3' and p.deleted_at is null
  and not exists (select 1 from app.investor_profile ip where ip.party_id = p.id);

-- ---------- 3) investor_sector_focus ----------
insert into app.investor_sector_focus (investor_profile_id, sector_id, organization_id)
select ip.id, v.sector_id::smallint, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p join app.investor_profile ip on ip.party_id = p.id
join (values
  ('Samsung Ventures', 1),
  ('Samsung Ventures', 3),
  ('Samsung Ventures', 16),
  ('SK Square', 3),
  ('SK Square', 1),
  ('SK Square', 6),
  ('LG Technology Ventures', 1),
  ('LG Technology Ventures', 3),
  ('LG Technology Ventures', 16),
  ('IDG Capital', 3),
  ('IDG Capital', 6),
  ('GL Ventures', 3),
  ('GL Ventures', 1),
  ('GL Ventures', 16),
  ('Lotus Lake Ventures', 3),
  ('Lotus Lake Ventures', 1),
  ('Blume Ventures', 3),
  ('Wavemaker Partners', 3),
  ('Wavemaker Partners', 4),
  ('Wavemaker Partners', 2),
  ('Openspace Ventures', 3),
  ('Openspace Ventures', 16),
  ('ADQ', 2),
  ('ADQ', 5),
  ('ADQ', 1),
  ('ADQ', 4),
  ('KAUST Innovation Ventures', 3),
  ('KAUST Innovation Ventures', 1),
  ('KAUST Innovation Ventures', 16)
) as v(party_name, sector_id) on v.party_name = p.party_name
where p.source = 'investor_global_2026Q3_b3' and p.deleted_at is null
  and not exists (select 1 from app.investor_sector_focus x
                  where x.investor_profile_id = ip.id and x.sector_id = v.sector_id);

-- ---------- 4) investor_stage_focus ----------
insert into app.investor_stage_focus (investor_profile_id, stage_id, organization_id)
select ip.id, v.stage_id::smallint, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p join app.investor_profile ip on ip.party_id = p.id
join (values
  ('Samsung Ventures', 3),
  ('Samsung Ventures', 4),
  ('Samsung Ventures', 11),
  ('SK Square', 4),
  ('SK Square', 11),
  ('LG Technology Ventures', 3),
  ('LG Technology Ventures', 4),
  ('IDG Capital', 2),
  ('IDG Capital', 3),
  ('IDG Capital', 4),
  ('IDG Capital', 11),
  ('GL Ventures', 2),
  ('GL Ventures', 3),
  ('GL Ventures', 4),
  ('Lotus Lake Ventures', 2),
  ('Lotus Lake Ventures', 3),
  ('Blume Ventures', 2),
  ('Blume Ventures', 3),
  ('Wavemaker Partners', 2),
  ('Wavemaker Partners', 3),
  ('Wavemaker Partners', 4),
  ('Openspace Ventures', 3),
  ('Openspace Ventures', 4),
  ('ADQ', 11),
  ('KAUST Innovation Ventures', 2),
  ('KAUST Innovation Ventures', 3)
) as v(party_name, stage_id) on v.party_name = p.party_name
where p.source = 'investor_global_2026Q3_b3' and p.deleted_at is null
  and not exists (select 1 from app.investor_stage_focus x
                  where x.investor_profile_id = ip.id and x.stage_id = v.stage_id);

commit;

-- Verify: select count(*) from app.parties where source='investor_global_2026Q3_b3'; -- expect 11
-- Rollback: delete from app.parties where source='investor_global_2026Q3_b3';
