-- ============================================================
-- 20260620370010_restore_upm_oji_anchors.sql
-- Restore soft-deleted company-level paper_mill anchors and ensure profiles.
-- DB had 'UPM' (FI) and 'Oji Holdings Corporation' (JP) as party_type_id=2 but
-- deleted_at IS NOT NULL. Mills for both are already live; this restores the
-- company umbrella row (matching the live pattern of 'Stora Enso Oyj' / 'Mondi (HQ)').
-- Idempotent: restore only if currently soft-deleted; profile inserted only if missing.
-- ============================================================

begin;

update app.parties set deleted_at = null, updated_at = now()
where party_name = 'UPM' and party_type_id = 2 and deleted_at is not null;

update app.parties set deleted_at = null, updated_at = now()
where party_name = 'Oji Holdings Corporation' and party_type_id = 2 and deleted_at is not null;

insert into app.paper_mill_profile
  (party_id, organization_id, main_product_category, main_products, headquarters,
   filler_use_intensity, evidence_level, industry_source)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, 'Graphic papers, pulp, biochemicals', 'Graphic & specialty papers, pulp, biofuels, biochemicals, label materials', 'Helsinki, Finland', 'high', 'C', 'industry-research'
from app.parties p
where p.party_name = 'UPM' and p.party_type_id = 2 and p.deleted_at is null
  and not exists (select 1 from app.paper_mill_profile pm where pm.party_id = p.id);

insert into app.paper_mill_profile
  (party_id, organization_id, main_product_category, main_products, headquarters,
   filler_use_intensity, evidence_level, industry_source)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, 'Paper & packaging', 'Paperboard, containerboard, household & functional paper, pulp', 'Tokyo, Japan', 'medium', 'C', 'industry-research'
from app.parties p
where p.party_name = 'Oji Holdings Corporation' and p.party_type_id = 2 and p.deleted_at is null
  and not exists (select 1 from app.paper_mill_profile pm where pm.party_id = p.id);

commit;

-- Verify (expect exactly 1 live row each + has_profile true):
-- select p.party_name, count(*) over (partition by p.party_name) live_rows,
--        (pm.party_id is not null) has_profile, pm.filler_use_intensity
-- from app.parties p left join app.paper_mill_profile pm on pm.party_id=p.id
-- where p.party_type_id=2 and p.deleted_at is null and p.party_name in ('UPM','Oji Holdings Corporation');
