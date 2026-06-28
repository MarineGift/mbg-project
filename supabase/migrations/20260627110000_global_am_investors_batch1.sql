-- ============================================================
-- 20260627110000_global_am_investors_batch1.sql
-- Global (non-US) Advanced Materials investors -> app.parties + investor_profile.
-- 5 net-new firms, all verified on their OWN sites (research 2026-06-27).
-- Deduped against current CRM (1,778 names) AND guarded by NOT EXISTS on party_name.
-- source='global_am_investors_2026Q3'. investor_type via coalesce-by-code (cvc/vc -> other fallback).
-- investor_sector_focus omitted (sector-id mapping unknown); kept in sector_focus text[].
-- Run as one txn in Supabase SQL Editor. Safe to re-run.
-- ============================================================

begin;

-- 1) parties (party_type_id=1 investor, entity company=1)
insert into app.parties (party_type_id, entity_type_id, party_name, status, source, country_code, region, city, website, notes, organization_id)
select 1::smallint, 1::smallint, v.party_name, 'active', 'global_am_investors_2026Q3', v.country_code, NULL, v.city, v.website, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('M Ventures','NL','Amsterdam','https://www.m-ventures.com','Corporate VC of Merck KGaA (Darmstadt). Focus incl. Performance Materials & Electronics.'),
  ('Syensqo Ventures','BE','Brussels','https://www.syensqo.com','Corporate VC of Syensqo (formerly Solvay Ventures); sustainable advanced materials & specialty chemicals.'),
  ('European Circular Bioeconomy Fund (ECBF)','LU','Luxembourg','https://ecbf.vc','EU-initiated growth VC; bio-based materials/chemicals & sustainable packaging (e.g., Paptic).'),
  ('Holcim MAQER Ventures','CH','Zug','https://holcimmaqerventures.com','Corporate VC of Holcim (building materials); low-carbon cement/concrete, circular economy.'),
  ('Amcor Ventures','CH','Zurich','https://www.amcor.com/ventures','Amcor Corporate Venturing & Open Innovation; paper-based & bio packaging materials, recycling.')
) as v(party_name, country_code, city, website, notes)
where not exists (select 1 from app.parties p where p.party_name=v.party_name and p.deleted_at is null);

-- 2) investor_profile (scoped by this source + party_type_id=1)
insert into app.investor_profile (party_id, investor_type_id, sector_focus, geographic_focus, is_lead_investor, organization_id)
select p.id,
       coalesce((select id from app.investor_types where code=v.itype_code),
                (select id from app.investor_types where code='other'))::smallint,
       v.sector_focus, v.geographic_focus, false, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p join (values
  ('M Ventures', 'cvc', array['performance_materials','electronics','sustainability','frontier_tech']::text[], array['Global']::text[]),
  ('Syensqo Ventures', 'cvc', array['advanced_materials','specialty_chemicals','sustainability']::text[], array['Global']::text[]),
  ('European Circular Bioeconomy Fund (ECBF)', 'vc', array['bio_based_materials','bio_based_chemicals','sustainable_packaging','circular_economy']::text[], array['Europe']::text[]),
  ('Holcim MAQER Ventures', 'cvc', array['building_materials','low_carbon_cement','circular_economy','carbon_capture']::text[], array['Global']::text[]),
  ('Amcor Ventures', 'cvc', array['sustainable_packaging','paper_based_packaging','biomaterials','recycling']::text[], array['Global']::text[])
) as v(party_name, itype_code, sector_focus, geographic_focus) on v.party_name=p.party_name
where p.source='global_am_investors_2026Q3' and p.party_type_id=1 and p.deleted_at is null
  and not exists (select 1 from app.investor_profile ip where ip.party_id=p.id);

commit;

-- ===================== VERIFY =====================
-- rows this batch (expect 5):
select count(*) from app.parties where source='global_am_investors_2026Q3';
-- investor_profile this batch (expect 5):
select count(*) from app.investor_profile ip join app.parties p on p.id=ip.party_id where p.source='global_am_investors_2026Q3';
-- review:
select p.party_name, p.country_code, p.city, p.website, ip.investor_type_id, ip.sector_focus
from app.parties p join app.investor_profile ip on ip.party_id=p.id
where p.source='global_am_investors_2026Q3' order by p.country_code, p.party_name;
