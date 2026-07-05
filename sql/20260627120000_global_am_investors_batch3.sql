-- ============================================================
-- 20260627120000_global_am_investors_batch3.sql
-- Global (non-US) Advanced Materials investors -> app.parties + investor_profile (BATCH 3).
-- 3 net-new firms, verified on their OWN sites / official sources (research 2026-06-27).
-- Deduped against current CRM (1,778 current names) + NOT EXISTS guard. source=global_am_investors_2026Q3 (same campaign).
-- Taiwania Capital is a broad deep-tech VC whose official mandate includes new materials.
-- investor_sector_focus omitted (sector-id mapping unknown), kept in sector_focus text[].
-- ============================================================

begin;

insert into app.parties (party_type_id, entity_type_id, party_name, status, source, country_code, region, city, website, notes, organization_id)
select 1::smallint, 1::smallint, v.party_name, 'active', 'global_am_investors_2026Q3', v.country_code, NULL, v.city, v.website, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('Demeter','FR','Paris','https://demeter-im.com','European ecological-transition investment platform, about EUR 1.3B AUM, covering new materials and circular economy. Co-manages the Circular Innovation Fund with Cycle Capital.'),
  ('Infinity Recycling','NL','Rotterdam','https://infinity-recycling.com','Growth-equity investor. Circular Plastics Fund backs advanced recycling technology that produces virgin-grade materials from end-of-life plastic. Fund registered in Luxembourg.'),
  ('Taiwania Capital','TW','Taipei','https://www.taiwaniacapital.com','Government-backed VC (National Development Fund of Taiwan) with a broad deep-tech mandate that includes new materials and smart machinery, such as Skeleton Technologies.')
) as v(party_name, country_code, city, website, notes)
where not exists (select 1 from app.parties p where p.party_name=v.party_name and p.deleted_at is null);

insert into app.investor_profile (party_id, investor_type_id, sector_focus, geographic_focus, is_lead_investor, organization_id)
select p.id,
       coalesce((select id from app.investor_types where code=v.itype_code),
                (select id from app.investor_types where code='other'))::smallint,
       v.sector_focus, v.geographic_focus, false, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p join (values
  ('Demeter', 'vc', array['energy_transition','new_materials','circular_economy','cleantech']::text[], array['Europe','Global']::text[]),
  ('Infinity Recycling', 'vc', array['circular_economy','advanced_recycling','plastics','sustainable_materials']::text[], array['Europe']::text[]),
  ('Taiwania Capital', 'vc', array['deep_tech','new_materials','semiconductors','green_energy']::text[], array['Taiwan','Global']::text[])
) as v(party_name, itype_code, sector_focus, geographic_focus) on v.party_name=p.party_name
where p.source='global_am_investors_2026Q3' and p.party_type_id=1 and p.deleted_at is null
  and not exists (select 1 from app.investor_profile ip where ip.party_id=p.id);

commit;

-- ===================== VERIFY =====================
select p.party_name, p.country_code, p.city, ip.investor_type_id, ip.sector_focus
from app.parties p join app.investor_profile ip on ip.party_id=p.id
where p.party_name in (
  'Demeter',
  'Infinity Recycling',
  'Taiwania Capital'
) order by p.party_name;
select count(*) from app.parties where source='global_am_investors_2026Q3';
