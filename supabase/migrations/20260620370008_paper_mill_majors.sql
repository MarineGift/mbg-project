-- ============================================================
-- 20260620370008_paper_mill_majors.sql
-- Add 4 global paper/pulp groups as paper_mill parties (party_type_id=2) + paper_mill_profile.
-- Stora Enso (FI), UPM (FI), Oji Holdings (JP), Mondi (GB). Source: industry-research.
-- These are company-level paper_mill rows (consistent with existing company+plant entries).
-- IDEMPOTENT: NOT EXISTS on lower(party_name)+party_type_id=2 for parties, and on party_id
-- for profile. If a giant already exists in the 600+ live paper_mill set, the party insert
-- is skipped and only a missing profile row would be added. Verify query at bottom.
-- paper_mill = party_type_id=2 ; entity_type=company=1 ; evidence_level CHECK in NULL/A/B/C/D.
-- ============================================================

begin;

-- 1) parties (paper_mill, type=2)
insert into app.parties (party_type_id, entity_type_id, party_name, country_code, region, city, website, status, source, notes, organization_id)
select 2::smallint, 1::smallint, 'Stora Enso', 'FI', 'Uusimaa', 'Helsinki', 'https://www.storaenso.com', 'active', 'industry-research', 'Global renewable-materials group; major European pulp/board producer.', 'b25de8f2-1020-482f-9012-183f63883169'::uuid
where not exists (select 1 from app.parties p where lower(p.party_name)=lower('Stora Enso') and p.party_type_id=2 and p.deleted_at is null);

insert into app.parties (party_type_id, entity_type_id, party_name, country_code, region, city, website, status, source, notes, organization_id)
select 2::smallint, 1::smallint, 'UPM', 'FI', 'Uusimaa', 'Helsinki', 'https://www.upm.com', 'active', 'industry-research', 'Major global graphic-paper producer (high mineral-filler use); pulp & biochemicals.', 'b25de8f2-1020-482f-9012-183f63883169'::uuid
where not exists (select 1 from app.parties p where lower(p.party_name)=lower('UPM') and p.party_type_id=2 and p.deleted_at is null);

insert into app.parties (party_type_id, entity_type_id, party_name, country_code, region, city, website, status, source, notes, organization_id)
select 2::smallint, 1::smallint, 'Oji Holdings', 'JP', 'Tokyo', 'Tokyo', 'https://www.ojiholdings.co.jp', 'active', 'industry-research', 'Japan''s largest paper group; paperboard, packaging and functional materials.', 'b25de8f2-1020-482f-9012-183f63883169'::uuid
where not exists (select 1 from app.parties p where lower(p.party_name)=lower('Oji Holdings') and p.party_type_id=2 and p.deleted_at is null);

insert into app.parties (party_type_id, entity_type_id, party_name, country_code, region, city, website, status, source, notes, organization_id)
select 2::smallint, 1::smallint, 'Mondi', 'GB', 'England', 'London', 'https://www.mondigroup.com', 'active', 'industry-research', 'Global packaging & paper group (UK-listed, Vienna ops).', 'b25de8f2-1020-482f-9012-183f63883169'::uuid
where not exists (select 1 from app.parties p where lower(p.party_name)=lower('Mondi') and p.party_type_id=2 and p.deleted_at is null);

-- 2) paper_mill_profile (1 row per party; only if missing)
insert into app.paper_mill_profile (party_id, organization_id, main_product_category, main_products, headquarters, filler_use_intensity, evidence_level, industry_source)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, 'Packaging, biomaterials, paper', 'Packaging board, market & specialised pulp, biomaterials, paper', 'Helsinki, Finland', 'medium', 'C', 'industry-research'
from app.parties p
where lower(p.party_name)=lower('Stora Enso') and p.party_type_id=2 and p.deleted_at is null
  and not exists (select 1 from app.paper_mill_profile pm where pm.party_id=p.id);

insert into app.paper_mill_profile (party_id, organization_id, main_product_category, main_products, headquarters, filler_use_intensity, evidence_level, industry_source)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, 'Graphic papers, pulp, biochemicals', 'Graphic & specialty papers, pulp, biofuels, biochemicals, label materials', 'Helsinki, Finland', 'high', 'C', 'industry-research'
from app.parties p
where lower(p.party_name)=lower('UPM') and p.party_type_id=2 and p.deleted_at is null
  and not exists (select 1 from app.paper_mill_profile pm where pm.party_id=p.id);

insert into app.paper_mill_profile (party_id, organization_id, main_product_category, main_products, headquarters, filler_use_intensity, evidence_level, industry_source)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, 'Paper & packaging', 'Paperboard, containerboard, household & functional paper, pulp', 'Tokyo, Japan', 'medium', 'C', 'industry-research'
from app.parties p
where lower(p.party_name)=lower('Oji Holdings') and p.party_type_id=2 and p.deleted_at is null
  and not exists (select 1 from app.paper_mill_profile pm where pm.party_id=p.id);

insert into app.paper_mill_profile (party_id, organization_id, main_product_category, main_products, headquarters, filler_use_intensity, evidence_level, industry_source)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, 'Packaging & paper', 'Corrugated & flexible packaging, kraft & uncoated fine paper', 'London, UK / Vienna, Austria', 'medium', 'C', 'industry-research'
from app.parties p
where lower(p.party_name)=lower('Mondi') and p.party_type_id=2 and p.deleted_at is null
  and not exists (select 1 from app.paper_mill_profile pm where pm.party_id=p.id);

commit;

-- Verify (newly tagged this file):
-- select party_name,country_code from app.parties where source='industry-research' and party_type_id=2;
-- Profile check:
-- select p.party_name, pm.filler_use_intensity, pm.evidence_level
-- from app.parties p join app.paper_mill_profile pm on pm.party_id=p.id
-- where p.party_name in ('Stora Enso','UPM','Oji Holdings','Mondi');
