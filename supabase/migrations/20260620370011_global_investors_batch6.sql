-- ============================================================
-- 20260620370011_global_investors_batch6.sql
-- BATCH 6: Japanese-affiliated CVC. 3 firms. Source: investor_global_2026Q3_b6. Verified 2026-06.
-- Diamond Edge Ventures (Mitsubishi Chemical Group CVC, San Francisco -> US),
-- Mitsui & Co. Global Investment (Menlo Park -> US), Marubeni Ventures (Tokyo, JP).
-- US tagging for SF/Menlo Park HQs follows the LG Technology Ventures precedent.
-- Dedup vs live type-1 incl. batch-1..5. All names new. investor_types: cvc=3.
-- ============================================================

begin;

-- 1) parties
insert into app.parties (party_type_id, entity_type_id, party_name, status, source, country_code, region, city, website, organization_id)
select v.* from (values
  (1::smallint,1::smallint,'Diamond Edge Ventures','active','investor_global_2026Q3_b6','US',NULL,'San Francisco','https://diamondedgeventures.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Mitsui & Co. Global Investment','active','investor_global_2026Q3_b6','US',NULL,'Menlo Park',NULL,'b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Marubeni Ventures','active','investor_global_2026Q3_b6','JP',NULL,'Tokyo',NULL,'b25de8f2-1020-482f-9012-183f63883169'::uuid)
) as v(party_type_id, entity_type_id, party_name, status, source, country_code, region, city, website, organization_id)
where not exists (select 1 from app.parties p where p.party_name=v.party_name and p.deleted_at is null);

-- 2) investor_profile (cvc=3)
insert into app.investor_profile (party_id, investor_type_id, sector_focus, geographic_focus, is_lead_investor, organization_id)
select p.id, 3::smallint, v.sector_focus, v.geographic_focus, true, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p join (values
  ('Diamond Edge Ventures', array['advanced_materials','industrial','deep_tech']::text[], array['North America','Global']::text[]),
  ('Mitsui & Co. Global Investment', array['deep_tech','healthcare','food_ag']::text[], array['North America','Global']::text[]),
  ('Marubeni Ventures', array['industrial','deep_tech','mobility']::text[], array['Asia','Global']::text[])
) as v(party_name, sector_focus, geographic_focus) on v.party_name=p.party_name
where p.source='investor_global_2026Q3_b6' and p.deleted_at is null and not exists (select 1 from app.investor_profile ip where ip.party_id=p.id);

-- 3) investor_sector_focus
insert into app.investor_sector_focus (investor_profile_id, sector_id, organization_id)
select ip.id, v.sector_id::smallint, 'b25de8f2-1020-482f-9012-183f63883169'::uuid from app.parties p join app.investor_profile ip on ip.party_id=p.id
join (values
  ('Diamond Edge Ventures', 1),
  ('Diamond Edge Ventures', 2),
  ('Diamond Edge Ventures', 3),
  ('Mitsui & Co. Global Investment', 3),
  ('Mitsui & Co. Global Investment', 9),
  ('Mitsui & Co. Global Investment', 12),
  ('Marubeni Ventures', 2),
  ('Marubeni Ventures', 3),
  ('Marubeni Ventures', 11)
) as v(party_name, sector_id) on v.party_name=p.party_name
where p.source='investor_global_2026Q3_b6' and p.deleted_at is null and not exists (select 1 from app.investor_sector_focus z where z.investor_profile_id=ip.id and z.sector_id=v.sector_id);

-- 4) investor_stage_focus
insert into app.investor_stage_focus (investor_profile_id, stage_id, organization_id)
select ip.id, v.stage_id::smallint, 'b25de8f2-1020-482f-9012-183f63883169'::uuid from app.parties p join app.investor_profile ip on ip.party_id=p.id
join (values
  ('Diamond Edge Ventures', 2),
  ('Diamond Edge Ventures', 3),
  ('Diamond Edge Ventures', 4),
  ('Mitsui & Co. Global Investment', 3),
  ('Mitsui & Co. Global Investment', 4),
  ('Mitsui & Co. Global Investment', 11),
  ('Marubeni Ventures', 3),
  ('Marubeni Ventures', 4),
  ('Marubeni Ventures', 11)
) as v(party_name, stage_id) on v.party_name=p.party_name
where p.source='investor_global_2026Q3_b6' and p.deleted_at is null and not exists (select 1 from app.investor_stage_focus z where z.investor_profile_id=ip.id and z.stage_id=v.stage_id);

commit;

-- Verify: select count(*) from app.parties where source='investor_global_2026Q3_b6'; -- expect 3
