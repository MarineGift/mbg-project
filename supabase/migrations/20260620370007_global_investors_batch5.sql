-- ============================================================
-- 20260620370007_global_investors_batch5.sql
-- BATCH 5: more global CVC + family offices. 5 firms. Source: investor_global_2026Q3_b5.
-- Dedup vs live type-1 incl. batch-1..4. All names new. Verified 2026-06.
-- NOTE: Mousse Partners HQ = New York, US (Chanel/Wertheimer family office) -> tagged US.
--       Pictet excluded (private bank, not a direct VC/family-fund investor here).
-- investor_types: cvc=3, family_office=6
-- ============================================================

begin;

-- 1) parties
insert into app.parties (party_type_id, entity_type_id, party_name, status, source, country_code, region, city, website, organization_id)
select v.* from (values
  (1::smallint,1::smallint,'POSCO Venture Capital','active','investor_global_2026Q3_b5','KR',NULL,'Seoul',NULL,'b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'SABIC Ventures','active','investor_global_2026Q3_b5','NL',NULL,'Sittard','https://ventures.sabic.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Shell Ventures','active','investor_global_2026Q3_b5','NL',NULL,'The Hague',NULL,'b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Planet First Partners','active','investor_global_2026Q3_b5','GB',NULL,'London','https://www.planetfirst.partners','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Mousse Partners','active','investor_global_2026Q3_b5','US',NULL,'New York','https://moussepartners.com','b25de8f2-1020-482f-9012-183f63883169'::uuid)
) as v(party_type_id, entity_type_id, party_name, status, source, country_code, region, city, website, organization_id)
where not exists (select 1 from app.parties p where p.party_name=v.party_name and p.deleted_at is null);

-- 2) investor_profile
-- investor_type_id=3 (cvc)
insert into app.investor_profile (party_id, investor_type_id, sector_focus, geographic_focus, is_lead_investor, organization_id)
select p.id, 3::smallint, v.sector_focus, v.geographic_focus, true, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p join (values
  ('POSCO Venture Capital', array['advanced_materials','industrial','deep_tech']::text[], array['Asia','Korea']::text[]),
  ('SABIC Ventures', array['advanced_materials','industrial','climate','energy']::text[], array['Europe','Global']::text[]),
  ('Shell Ventures', array['energy','climate','industrial']::text[], array['Europe','Global']::text[])
) as v(party_name, sector_focus, geographic_focus) on v.party_name=p.party_name
where p.source='investor_global_2026Q3_b5' and p.deleted_at is null and not exists (select 1 from app.investor_profile ip where ip.party_id=p.id);

-- investor_type_id=6 (family_office)
insert into app.investor_profile (party_id, investor_type_id, sector_focus, geographic_focus, is_lead_investor, organization_id)
select p.id, 6::smallint, v.sector_focus, v.geographic_focus, true, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p join (values
  ('Planet First Partners', array['climate','industrial','advanced_materials']::text[], array['Europe','Global']::text[]),
  ('Mousse Partners', array['consumer','food_ag']::text[], array['North America','Global']::text[])
) as v(party_name, sector_focus, geographic_focus) on v.party_name=p.party_name
where p.source='investor_global_2026Q3_b5' and p.deleted_at is null and not exists (select 1 from app.investor_profile ip where ip.party_id=p.id);

-- 3) investor_sector_focus
insert into app.investor_sector_focus (investor_profile_id, sector_id, organization_id)
select ip.id, v.sector_id::smallint, 'b25de8f2-1020-482f-9012-183f63883169'::uuid from app.parties p join app.investor_profile ip on ip.party_id=p.id
join (values
  ('POSCO Venture Capital', 1),
  ('POSCO Venture Capital', 2),
  ('POSCO Venture Capital', 3),
  ('SABIC Ventures', 1),
  ('SABIC Ventures', 2),
  ('SABIC Ventures', 4),
  ('SABIC Ventures', 5),
  ('Shell Ventures', 5),
  ('Shell Ventures', 4),
  ('Shell Ventures', 2),
  ('Planet First Partners', 4),
  ('Planet First Partners', 2),
  ('Planet First Partners', 1),
  ('Mousse Partners', 10),
  ('Mousse Partners', 12)
) as v(party_name, sector_id) on v.party_name=p.party_name
where p.source='investor_global_2026Q3_b5' and p.deleted_at is null and not exists (select 1 from app.investor_sector_focus x where x.investor_profile_id=ip.id and x.sector_id=v.sector_id);

-- 4) investor_stage_focus
insert into app.investor_stage_focus (investor_profile_id, stage_id, organization_id)
select ip.id, v.stage_id::smallint, 'b25de8f2-1020-482f-9012-183f63883169'::uuid from app.parties p join app.investor_profile ip on ip.party_id=p.id
join (values
  ('POSCO Venture Capital', 2),
  ('POSCO Venture Capital', 3),
  ('POSCO Venture Capital', 4),
  ('SABIC Ventures', 2),
  ('SABIC Ventures', 3),
  ('SABIC Ventures', 4),
  ('Shell Ventures', 3),
  ('Shell Ventures', 4),
  ('Shell Ventures', 11),
  ('Planet First Partners', 4),
  ('Planet First Partners', 11),
  ('Mousse Partners', 4),
  ('Mousse Partners', 11)
) as v(party_name, stage_id) on v.party_name=p.party_name
where p.source='investor_global_2026Q3_b5' and p.deleted_at is null and not exists (select 1 from app.investor_stage_focus x where x.investor_profile_id=ip.id and x.stage_id=v.stage_id);

commit;

-- Verify: select count(*) from app.parties where source='investor_global_2026Q3_b5'; -- expect 5
