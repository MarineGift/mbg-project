-- ============================================================
-- 20260627113000_global_am_investors_batch2.sql
-- Global (non-US) Advanced Materials investors -> app.parties + investor_profile (BATCH 2).
-- 4 net-new firms, verified on their OWN sites (research 2026-06-27).
-- Deduped against current CRM (1,778 names, current official names) + NOT EXISTS guard.
-- Same campaign source='global_am_investors_2026Q3' as batch1 (idempotent; re-runs harmless).
-- investor_sector_focus omitted (sector-id mapping unknown); kept in sector_focus text[].
-- ============================================================

begin;

insert into app.parties (party_type_id, entity_type_id, party_name, status, source, country_code, region, city, website, notes, organization_id)
select 1::smallint, 1::smallint, v.party_name, 'active', 'global_am_investors_2026Q3', v.country_code, NULL, v.city, v.website, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('Chrysalix Venture Capital','CA','Vancouver','https://www.chrysalix.com','VC for resource-intensive industries; advanced materials, metal/concrete recycling, industrial innovation (office in Delft, NL).'),
  ('Henkel Ventures','DE','Dusseldorf','https://www.henkel-ventures.com','Corporate VC of Henkel; Adhesive Technologies & sustainable materials; ~EUR 300M AUM, geographically agnostic.'),
  ('GC Ventures','TH','Bangkok','https://www.pttgcgroup.com/en/products-and-innovations/gc-ventures','Corporate VC of PTT Global Chemical (PTTGC, Thailand); advanced materials, circularity, cleantech (US arm: GC Ventures America).'),
  ('Capricorn Partners','BE','Leuven','https://capricorn.be','Pan-European VC (Capricorn Venture Partners); Sustainable Chemistry Fund - materials/chemicals from renewable resources. NOT the US Capricorn Investment Group.')
) as v(party_name, country_code, city, website, notes)
where not exists (select 1 from app.parties p where p.party_name=v.party_name and p.deleted_at is null);

insert into app.investor_profile (party_id, investor_type_id, sector_focus, geographic_focus, is_lead_investor, organization_id)
select p.id,
       coalesce((select id from app.investor_types where code=v.itype_code),
                (select id from app.investor_types where code='other'))::smallint,
       v.sector_focus, v.geographic_focus, false, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p join (values
  ('Chrysalix Venture Capital', 'vc', array['advanced_materials','industrial_innovation','recycling','cleantech']::text[], array['North America','Europe']::text[]),
  ('Henkel Ventures', 'cvc', array['adhesives','specialty_materials','sustainability']::text[], array['Global']::text[]),
  ('GC Ventures', 'cvc', array['advanced_materials','specialty_chemicals','circular_economy','cleantech']::text[], array['Global']::text[]),
  ('Capricorn Partners', 'vc', array['sustainable_chemistry','advanced_materials','cleantech','circular_economy']::text[], array['Europe','North America']::text[])
) as v(party_name, itype_code, sector_focus, geographic_focus) on v.party_name=p.party_name
where p.source='global_am_investors_2026Q3' and p.party_type_id=1 and p.deleted_at is null
  and not exists (select 1 from app.investor_profile ip where ip.party_id=p.id);

commit;

-- ===================== VERIFY =====================
-- this batch's firms present with a profile (expect 4):
select p.party_name, p.country_code, p.city, ip.investor_type_id, ip.sector_focus
from app.parties p join app.investor_profile ip on ip.party_id=p.id
where p.party_name in (
  'Chrysalix Venture Capital',
  'Henkel Ventures',
  'GC Ventures',
  'Capricorn Partners'
) order by p.party_name;
-- cumulative count for the whole global campaign:
select count(*) from app.parties where source='global_am_investors_2026Q3';
