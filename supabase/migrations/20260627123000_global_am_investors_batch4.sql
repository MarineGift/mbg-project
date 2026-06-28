-- ============================================================
-- 20260627123000_global_am_investors_batch4.sql
-- Global (non-US) Advanced Materials investors -> app.parties + investor_profile (BATCH 4, FINAL).
-- 2 net-new Japan firms, verified on their OWN sites (research 2026-06-27).
-- Middle East reviewed: materials-specialist arms (Aramco Ventures, SABIC Ventures) already in CRM;
-- remaining Gulf SWFs (Mubadala/ADIA/PIF/QIA/ADQ) are generalist -> no net-new added.
-- Dedup vs current CRM (1,778 names) + NOT EXISTS guard. source=global_am_investors_2026Q3 (same campaign).
-- investor_sector_focus omitted (sector-id mapping unknown), kept in sector_focus text[].
-- ============================================================

begin;

insert into app.parties (party_type_id, entity_type_id, party_name, status, source, country_code, region, city, website, notes, organization_id)
select 1::smallint, 1::smallint, v.party_name, 'active', 'global_am_investors_2026Q3', v.country_code, NULL, v.city, v.website, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('Asahi Kasei Ventures','JP','Tokyo','https://www.asahikaseiventures.com','Corporate VC of Asahi Kasei (Tokyo). Invests in Materials and Healthcare. USD 100M Care for Earth framework for carbon-neutral and bio-based materials.'),
  ('Mitsui Chemicals 321FORCE','JP','Tokyo','https://jp.mitsuichemicals.com/en/special/cvc_general/index.htm','Mitsui Chemicals CVC fund 321FORCE (managed with Global Brain). Focus on sustainable materials, mobility, electronics and healthcare. US arm is 321Catalyst.')
) as v(party_name, country_code, city, website, notes)
where not exists (select 1 from app.parties p where p.party_name=v.party_name and p.deleted_at is null);

insert into app.investor_profile (party_id, investor_type_id, sector_focus, geographic_focus, is_lead_investor, organization_id)
select p.id,
       coalesce((select id from app.investor_types where code=v.itype_code),
                (select id from app.investor_types where code='other'))::smallint,
       v.sector_focus, v.geographic_focus, false, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p join (values
  ('Asahi Kasei Ventures', 'cvc', array['advanced_materials','specialty_chemicals','sustainability','healthcare']::text[], array['Global']::text[]),
  ('Mitsui Chemicals 321FORCE', 'cvc', array['sustainable_materials','specialty_chemicals','mobility','electronics']::text[], array['Global']::text[])
) as v(party_name, itype_code, sector_focus, geographic_focus) on v.party_name=p.party_name
where p.source='global_am_investors_2026Q3' and p.party_type_id=1 and p.deleted_at is null
  and not exists (select 1 from app.investor_profile ip where ip.party_id=p.id);

commit;

-- ===================== VERIFY =====================
select p.party_name, p.country_code, p.city, ip.investor_type_id, ip.sector_focus
from app.parties p join app.investor_profile ip on ip.party_id=p.id
where p.party_name in (
  'Asahi Kasei Ventures',
  'Mitsui Chemicals 321FORCE'
) order by p.party_name;
select count(*) from app.parties where source='global_am_investors_2026Q3';  -- expect 13 cumulative
