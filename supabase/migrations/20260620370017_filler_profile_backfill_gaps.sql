-- ============================================================
-- 20260620370017_filler_profile_backfill_gaps.sql
-- Backfill filler_supplier_profile for the 6 firms added in 370013 (source filler_gap_2026Q3).
-- All are corporate-level merchant suppliers -> supply_model='merchant', evidence_level='C'
-- (per the project's supply_model->evidence rule: merchant->C, satellite->B).
-- Idempotent: 1 profile per party, inserted only if missing. NOT NULL cols all provided.
-- ============================================================

begin;

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, notes, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, 'PCC/GCC producer', 'Global PCC/GCC merchant supplier', 'merchant', 'C', 'CaCO3 (PCC/GCC)', 'industry-research', 'World''s largest PCC/GCC supplier; paper-filler technology leader.', '{}'::jsonb, now(), now()
from app.parties p
where p.party_name = 'Specialty Minerals Inc.' and p.party_type_id = 3 and p.deleted_at is null
  and p.source = 'filler_gap_2026Q3'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, notes, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, 'Minerals group (parent)', 'Global minerals parent (PCC/GCC)', 'merchant', 'C', 'CaCO3 (PCC/GCC)', 'industry-research', 'Parent of Specialty Minerals (NYSE: MTX).', '{}'::jsonb, now(), now()
from app.parties p
where p.party_name = 'Minerals Technologies Inc.' and p.party_type_id = 3 and p.deleted_at is null
  and p.source = 'filler_gap_2026Q3'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, notes, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, 'PCC/GCC producer', 'PCC/GCC merchant supplier (paper)', 'merchant', 'C', 'CaCO3 (PCC/GCC)', 'industry-research', 'German PCC/GCC producer for paper (~442 kt PCC).', '{}'::jsonb, now(), now()
from app.parties p
where p.party_name = 'Schaefer Kalk' and p.party_type_id = 3 and p.deleted_at is null
  and p.source = 'filler_gap_2026Q3'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, notes, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, 'Lime/CaCO3 producer', 'Lime & CaCO3 merchant supplier', 'merchant', 'C', 'CaCO3 / lime', 'industry-research', 'Spanish lime and calcium carbonate producer.', '{}'::jsonb, now(), now()
from app.parties p
where p.party_name = 'Calcinor' and p.party_type_id = 3 and p.deleted_at is null
  and p.source = 'filler_gap_2026Q3'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, notes, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, 'Specialty minerals producer', 'Specialty minerals (kaolin, PCC)', 'merchant', 'C', 'Kaolin / CaCO3', 'industry-research', 'J.M. Huber engineered-minerals unit.', '{}'::jsonb, now(), now()
from app.parties p
where p.party_name = 'Huber Engineered Materials' and p.party_type_id = 3 and p.deleted_at is null
  and p.source = 'filler_gap_2026Q3'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, notes, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, 'Lime/minerals producer', 'Lime & minerals merchant supplier', 'merchant', 'C', 'Lime / CaCO3', 'industry-research', 'Belgian lime and minerals group (HQ).', '{}'::jsonb, now(), now()
from app.parties p
where p.party_name = 'Lhoist (HQ)' and p.party_type_id = 3 and p.deleted_at is null
  and p.source = 'filler_gap_2026Q3'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

commit;

-- Verify: select p.party_name, fp.supply_model, fp.evidence_level, fp.market_role, fp.mineral_class
-- from app.parties p join app.filler_supplier_profile fp on fp.party_id=p.id
-- where p.source='filler_gap_2026Q3' order by p.party_name;  -- expect 6
