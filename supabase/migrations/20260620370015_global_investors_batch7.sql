-- ============================================================
-- 20260620370015_global_investors_batch7.sql
-- BATCH 7: Japanese trading-house CVC. 2 firms. Source: investor_global_2026Q3_b7. Verified 2026-06.
-- Presidio Ventures (Sumitomo Corp CVC, Silicon Valley -> US),
-- Itochu Technology Ventures (ITV, Tokyo, JP). investor_types: cvc=3.
-- Dedup vs live type-1 incl. batch-1..6. Both names new.
-- ============================================================

begin;

insert into app.parties (party_type_id, entity_type_id, party_name, status, source, country_code, region, city, website, organization_id)
select v.* from (values
  (1::smallint,1::smallint,'Presidio Ventures','active','investor_global_2026Q3_b7','US',NULL,'Palo Alto','https://presidio-ventures.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Itochu Technology Ventures','active','investor_global_2026Q3_b7','JP',NULL,'Tokyo',NULL,'b25de8f2-1020-482f-9012-183f63883169'::uuid)
) as v(party_type_id, entity_type_id, party_name, status, source, country_code, region, city, website, organization_id)
where not exists (select 1 from app.parties p where p.party_name=v.party_name and p.deleted_at is null);

insert into app.investor_profile (party_id, investor_type_id, sector_focus, geographic_focus, is_lead_investor, organization_id)
select p.id, 3::smallint, v.sector_focus, v.geographic_focus, true, 'b25de8f2-1020-482f-9012-183f63883169'::uuid from app.parties p join (values
  ('Presidio Ventures', array['deep_tech','energy','industrial','mobility']::text[], array['North America','Global']::text[]),
  ('Itochu Technology Ventures', array['deep_tech','software','ai']::text[], array['Asia','Global']::text[])
) as v(party_name, sector_focus, geographic_focus) on v.party_name=p.party_name
where p.source='investor_global_2026Q3_b7' and p.deleted_at is null and not exists (select 1 from app.investor_profile ip where ip.party_id=p.id);

insert into app.investor_sector_focus (investor_profile_id, sector_id, organization_id)
select ip.id, v.sector_id::smallint, 'b25de8f2-1020-482f-9012-183f63883169'::uuid from app.parties p join app.investor_profile ip on ip.party_id=p.id join (values
  ('Presidio Ventures', 3),
  ('Presidio Ventures', 5),
  ('Presidio Ventures', 2),
  ('Presidio Ventures', 11),
  ('Itochu Technology Ventures', 3),
  ('Itochu Technology Ventures', 7),
  ('Itochu Technology Ventures', 6)
) as v(party_name, sector_id) on v.party_name=p.party_name
where p.source='investor_global_2026Q3_b7' and p.deleted_at is null and not exists (select 1 from app.investor_sector_focus z where z.investor_profile_id=ip.id and z.sector_id=v.sector_id);

insert into app.investor_stage_focus (investor_profile_id, stage_id, organization_id)
select ip.id, v.stage_id::smallint, 'b25de8f2-1020-482f-9012-183f63883169'::uuid from app.parties p join app.investor_profile ip on ip.party_id=p.id join (values
  ('Presidio Ventures', 2),
  ('Presidio Ventures', 3),
  ('Presidio Ventures', 4),
  ('Itochu Technology Ventures', 2),
  ('Itochu Technology Ventures', 3),
  ('Itochu Technology Ventures', 4)
) as v(party_name, stage_id) on v.party_name=p.party_name
where p.source='investor_global_2026Q3_b7' and p.deleted_at is null and not exists (select 1 from app.investor_stage_focus z where z.investor_profile_id=ip.id and z.stage_id=v.stage_id);

commit;

-- Verify: select count(*) from app.parties where source='investor_global_2026Q3_b7'; -- expect 2
