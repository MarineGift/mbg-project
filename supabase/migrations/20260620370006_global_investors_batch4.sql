-- ============================================================
-- 20260620370006_global_investors_batch4.sql
-- Global investor enrichment BATCH 4: corporate VC (CVC) + family offices. 7 firms.
-- Source tag: investor_global_2026Q3_b4.
--
-- Dedup: checked against live type-1 list incl. batch-1/2/3 (2026-06-20). All names new.
-- Henkel excluded (already in DB as 'Henkel Tech Ventures').
-- Verified per firm (web research, 2026-06): real firm, HQ, active investor, sector + stage.
--   CVC: Robert Bosch VC (Stuttgart), ABB Technology Ventures (Zurich), TotalEnergies Ventures (Paris).
--   Family offices: Vorwerk Ventures (Mittelsten Scheid), Tengelmann Ventures (Haub),
--                   Blue Pool Capital (Joe Tsai/Alibaba, HK), Exor (Agnelli, Amsterdam).
--
-- Vocab (live, locked 2026-06-20):
--   investor_types: cvc=3, family_office=6
--   sectors: advanced_materials=1, industrial=2, deep_tech=3, climate=4, energy=5,
--            ai=6, healthcare=9, consumer=10, life_science=16
--   stages: seed=2, series_a=3, series_b=4, growth=11
-- ============================================================

begin;

-- ---------- 1) parties ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, status, source,
   country_code, region, city, website, organization_id)
select v.* from (values
  (1::smallint,1::smallint,'Robert Bosch Venture Capital','active','investor_global_2026Q3_b4','DE',NULL,'Stuttgart','https://www.rbvc.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'ABB Technology Ventures','active','investor_global_2026Q3_b4','CH',NULL,'Zurich','https://global.abb/group/en/technology/ventures','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'TotalEnergies Ventures','active','investor_global_2026Q3_b4','FR',NULL,'Paris','https://ventures.totalenergies.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Vorwerk Ventures','active','investor_global_2026Q3_b4','DE',NULL,'Berlin','https://vorwerkventures.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Tengelmann Ventures','active','investor_global_2026Q3_b4','DE',NULL,'Munich',NULL,'b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Blue Pool Capital','active','investor_global_2026Q3_b4','HK',NULL,'Hong Kong','https://bluepoolcapital.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Exor','active','investor_global_2026Q3_b4','NL',NULL,'Amsterdam','https://www.exor.com','b25de8f2-1020-482f-9012-183f63883169'::uuid)
) as v(party_type_id, entity_type_id, party_name, status, source,
       country_code, region, city, website, organization_id)
where not exists (select 1 from app.parties p where p.party_name = v.party_name and p.deleted_at is null);

-- ---------- 2) investor_profile ----------
-- investor_type_id=3 (cvc)
insert into app.investor_profile
  (party_id, investor_type_id, sector_focus, geographic_focus, is_lead_investor, organization_id)
select p.id, 3::smallint, v.sector_focus, v.geographic_focus, true, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p
join (values
  ('Robert Bosch Venture Capital', array['deep_tech','industrial','advanced_materials']::text[], array['Europe','Global']::text[]),
  ('ABB Technology Ventures', array['industrial','deep_tech','energy','climate']::text[], array['Europe','Global']::text[]),
  ('TotalEnergies Ventures', array['energy','climate','industrial','advanced_materials']::text[], array['Europe','Global']::text[])
) as v(party_name, sector_focus, geographic_focus) on v.party_name = p.party_name
where p.source = 'investor_global_2026Q3_b4' and p.deleted_at is null
  and not exists (select 1 from app.investor_profile ip where ip.party_id = p.id);

-- investor_type_id=6 (family_office)
insert into app.investor_profile
  (party_id, investor_type_id, sector_focus, geographic_focus, is_lead_investor, organization_id)
select p.id, 6::smallint, v.sector_focus, v.geographic_focus, true, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p
join (values
  ('Vorwerk Ventures', array['climate','consumer']::text[], array['Europe']::text[]),
  ('Tengelmann Ventures', array['consumer','deep_tech']::text[], array['Europe','North America']::text[]),
  ('Blue Pool Capital', array['deep_tech','healthcare']::text[], array['Asia','Global']::text[]),
  ('Exor', array['deep_tech','life_science','industrial']::text[], array['Europe','Global']::text[])
) as v(party_name, sector_focus, geographic_focus) on v.party_name = p.party_name
where p.source = 'investor_global_2026Q3_b4' and p.deleted_at is null
  and not exists (select 1 from app.investor_profile ip where ip.party_id = p.id);

-- ---------- 3) investor_sector_focus ----------
insert into app.investor_sector_focus (investor_profile_id, sector_id, organization_id)
select ip.id, v.sector_id::smallint, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p join app.investor_profile ip on ip.party_id = p.id
join (values
  ('Robert Bosch Venture Capital', 3),
  ('Robert Bosch Venture Capital', 2),
  ('Robert Bosch Venture Capital', 1),
  ('ABB Technology Ventures', 2),
  ('ABB Technology Ventures', 3),
  ('ABB Technology Ventures', 5),
  ('ABB Technology Ventures', 4),
  ('TotalEnergies Ventures', 5),
  ('TotalEnergies Ventures', 4),
  ('TotalEnergies Ventures', 2),
  ('TotalEnergies Ventures', 1),
  ('Vorwerk Ventures', 4),
  ('Vorwerk Ventures', 10),
  ('Tengelmann Ventures', 10),
  ('Tengelmann Ventures', 3),
  ('Blue Pool Capital', 3),
  ('Blue Pool Capital', 9),
  ('Exor', 3),
  ('Exor', 16),
  ('Exor', 2)
) as v(party_name, sector_id) on v.party_name = p.party_name
where p.source = 'investor_global_2026Q3_b4' and p.deleted_at is null
  and not exists (select 1 from app.investor_sector_focus x
                  where x.investor_profile_id = ip.id and x.sector_id = v.sector_id);

-- ---------- 4) investor_stage_focus ----------
insert into app.investor_stage_focus (investor_profile_id, stage_id, organization_id)
select ip.id, v.stage_id::smallint, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p join app.investor_profile ip on ip.party_id = p.id
join (values
  ('Robert Bosch Venture Capital', 2),
  ('Robert Bosch Venture Capital', 3),
  ('Robert Bosch Venture Capital', 4),
  ('ABB Technology Ventures', 3),
  ('ABB Technology Ventures', 4),
  ('ABB Technology Ventures', 11),
  ('TotalEnergies Ventures', 2),
  ('TotalEnergies Ventures', 3),
  ('TotalEnergies Ventures', 4),
  ('Vorwerk Ventures', 2),
  ('Vorwerk Ventures', 3),
  ('Vorwerk Ventures', 4),
  ('Tengelmann Ventures', 3),
  ('Tengelmann Ventures', 4),
  ('Tengelmann Ventures', 11),
  ('Blue Pool Capital', 4),
  ('Blue Pool Capital', 11),
  ('Exor', 11)
) as v(party_name, stage_id) on v.party_name = p.party_name
where p.source = 'investor_global_2026Q3_b4' and p.deleted_at is null
  and not exists (select 1 from app.investor_stage_focus x
                  where x.investor_profile_id = ip.id and x.stage_id = v.stage_id);

commit;

-- Verify: select count(*) from app.parties where source='investor_global_2026Q3_b4'; -- expect 7
-- Rollback: delete from app.parties where source='investor_global_2026Q3_b4';
