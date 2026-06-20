-- ============================================================
-- 20260620370013_filler_supplier_gaps.sql
-- Surgical additions to filler_supplier (party_type_id=3): major global CaCO3/PCC/GCC
-- producers confirmed ABSENT from the current ~99-row live list. Source: filler_gap_2026Q3.
-- Verified 2026-06 (Mordor / industry sources). Party-level only; filler_supplier_profile
-- (supply_model / evidence_level / market_role) to be backfilled in a follow-up pass.
-- IDEMPOTENT: NOT EXISTS on lower(party_name)+party_type_id=3+live. paper_mill=2, filler=3.
-- Note: 'Specialty Minerals Inc.' is distinct from existing 'Double A Specialty Minerals'.
-- ============================================================

begin;

insert into app.parties (party_type_id, entity_type_id, party_name, country_code, region, city, website, status, source, notes, organization_id)
select v.* from (values
  (3::smallint,1::smallint,'Specialty Minerals Inc.','US',NULL,'New York','https://www.mineralstech.com/specialty-minerals','active','filler_gap_2026Q3','World''s largest PCC/GCC supplier; paper-filler leader; 54 PCC plants in 16 countries; subsidiary of Minerals Technologies.','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (3::smallint,1::smallint,'Minerals Technologies Inc.','US',NULL,'New York','https://www.mineralstech.com','active','filler_gap_2026Q3','Parent of Specialty Minerals (NYSE: MTX); PCC/GCC, processed minerals.','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (3::smallint,1::smallint,'Schaefer Kalk','DE',NULL,'Diez','https://www.schaeferkalk.com','active','filler_gap_2026Q3','German PCC and GCC producer for paper and other industries (~442 kt PCC).','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (3::smallint,1::smallint,'Shiraishi Calcium','JP',NULL,'Osaka',NULL,'active','filler_gap_2026Q3','Japanese PCC pioneer (Shiraishi Group).','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (3::smallint,1::smallint,'Sibelco','BE',NULL,'Antwerp','https://www.sibelco.com','active','filler_gap_2026Q3','Belgian industrial-minerals group; GCC and PCC; ~120 sites across 31 countries.','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (3::smallint,1::smallint,'Calcinor','ES',NULL,'San Sebastian','https://www.calcinor.com','active','filler_gap_2026Q3','Spanish lime and calcium carbonate producer.','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (3::smallint,1::smallint,'Huber Engineered Materials','US',NULL,'Atlanta','https://www.hubermaterials.com','active','filler_gap_2026Q3','J.M. Huber unit; kaolin, PCC and specialty minerals.','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (3::smallint,1::smallint,'Lhoist (HQ)','BE',NULL,'Limelette','https://www.lhoist.com','active','filler_gap_2026Q3','Belgian lime and minerals group (headquarters).','b25de8f2-1020-482f-9012-183f63883169'::uuid)
) as v(party_type_id, entity_type_id, party_name, country_code, region, city, website, status, source, notes, organization_id)
where not exists (select 1 from app.parties p where lower(p.party_name)=lower(v.party_name) and p.party_type_id=3 and p.deleted_at is null);

commit;

-- Verify: select party_name,country_code from app.parties where source='filler_gap_2026Q3' and party_type_id=3 order by party_name; -- expect up to 8
-- Rollback: delete from app.parties where source='filler_gap_2026Q3';
