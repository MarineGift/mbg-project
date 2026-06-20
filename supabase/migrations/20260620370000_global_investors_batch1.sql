-- ============================================================
-- 20260620370000_global_investors_batch1.sql
-- Global (non-US) investor enrichment: Advanced Materials / Deep Tech / Life Science.
-- 27 firms across Europe, Israel, Japan, Korea, China, Singapore.
-- Source tag: investor_global_2026Q3.
--
-- Dedup: every firm checked against the live type-1 investor list
-- (2026-06-20) and is NOT already present. Existing non-US firms
-- (Evonik VC, Emerald, Henkel, Pangaea, Sofinnova, Atomico, Balderton,
-- Generation IM, Northzone, Temasek, GIC, Circulate, CPP, ADIA, Mubadala,
-- QIA, PIF, Norges, Suzano) deliberately excluded. NOT EXISTS guard is a backstop.
--
-- Verified per firm (web research, 2026-06): real firm, HQ, active investor,
-- sector + stage focus. Sofinnova Partners excluded (= existing 'Sofinnova Partners US').
--
-- Vocab (live, locked 2026-06-20):
--   party_types.investor=1, entity_types.company=1
--   investor_types: vc=1, cvc=3
--   sectors: advanced_materials=1, industrial=2, deep_tech=3, climate=4,
--            healthcare=9, life_science=16
--   stages: seed=2, series_a=3, series_b=4, series_c=5, early=10, growth=11, late=12
-- ============================================================

begin;

-- ---------- 1) parties ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, status, source,
   country_code, region, city, website, organization_id)
select v.* from (values
  (1::smallint,1::smallint,'BASF Venture Capital','active','investor_global_2026Q3','DE',NULL,'Ludwigshafen','https://www.basf.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Saint-Gobain NOVA','active','investor_global_2026Q3','FR',NULL,'Courbevoie','https://www.nova-saint-gobain.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Syensqo Ventures','active','investor_global_2026Q3','BE',NULL,'Brussels','https://www.syensqo.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'World Fund','active','investor_global_2026Q3','DE',NULL,'Berlin','https://www.worldfund.vc','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Extantia Capital','active','investor_global_2026Q3','DE',NULL,'Berlin','https://extantia.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Planet A Ventures','active','investor_global_2026Q3','DE',NULL,'Hamburg','https://planet-a.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'AP Ventures','active','investor_global_2026Q3','GB',NULL,'London','https://apventures.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Pitango','active','investor_global_2026Q3','IL',NULL,'Herzliya','https://www.pitango.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'OurCrowd','active','investor_global_2026Q3','IL',NULL,'Jerusalem','https://www.ourcrowd.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'JAFCO','active','investor_global_2026Q3','JP',NULL,'Tokyo','https://www.jafco.co.jp','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'HV Capital','active','investor_global_2026Q3','DE',NULL,'Munich','https://www.hvcapital.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Earlybird','active','investor_global_2026Q3','DE',NULL,'Berlin','https://earlybird.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'EQT Ventures','active','investor_global_2026Q3','SE',NULL,'Stockholm','https://eqtventures.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Lakestar','active','investor_global_2026Q3','CH',NULL,'Zurich','https://www.lakestar.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Speedinvest','active','investor_global_2026Q3','AT',NULL,'Vienna','https://speedinvest.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Korea Investment Partners','active','investor_global_2026Q3','KR',NULL,'Seoul','https://www.kipvc.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Legend Capital','active','investor_global_2026Q3','CN',NULL,'Beijing','https://www.legendcapital.com.cn','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Forbion','active','investor_global_2026Q3','NL',NULL,'Naarden','https://forbion.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Medicxi','active','investor_global_2026Q3','GB',NULL,'London','https://www.medicxi.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'HealthCap','active','investor_global_2026Q3','SE',NULL,'Stockholm','https://www.healthcap.eu','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Kurma Partners','active','investor_global_2026Q3','FR',NULL,'Paris','https://www.kurmapartners.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Gimv','active','investor_global_2026Q3','BE',NULL,'Antwerp','https://www.gimv.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Andera Partners','active','investor_global_2026Q3','FR',NULL,'Paris','https://www.anderapartners.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Qiming Venture Partners','active','investor_global_2026Q3','CN',NULL,'Shanghai','https://www.qimingvc.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Vertex Ventures','active','investor_global_2026Q3','SG',NULL,'Singapore','https://www.vertexholdings.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Syncona','active','investor_global_2026Q3','GB',NULL,'London','https://www.synconaltd.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Abingworth','active','investor_global_2026Q3','GB',NULL,'London','https://www.abingworth.com','b25de8f2-1020-482f-9012-183f63883169'::uuid)
) as v(party_type_id, entity_type_id, party_name, status, source,
       country_code, region, city, website, organization_id)
where not exists (
  select 1 from app.parties p
  where p.party_name = v.party_name and p.deleted_at is null
);

-- ---------- 2) investor_profile (one per new party) ----------
-- investor_type_id=1 (vc)
insert into app.investor_profile
  (party_id, investor_type_id, sector_focus, geographic_focus,
   is_lead_investor, organization_id)
select p.id, 1::smallint,
       v.sector_focus, v.geographic_focus, true,
       'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p
join (values
  ('World Fund', array['advanced_materials','climate','deep_tech']::text[], array['Europe']::text[]),
  ('Extantia Capital', array['advanced_materials','climate','industrial']::text[], array['Europe']::text[]),
  ('Planet A Ventures', array['advanced_materials','climate','industrial']::text[], array['Europe']::text[]),
  ('AP Ventures', array['advanced_materials','deep_tech','climate']::text[], array['Europe','Global']::text[]),
  ('Pitango', array['deep_tech','life_science']::text[], array['Israel','Global']::text[]),
  ('OurCrowd', array['deep_tech']::text[], array['Israel','Global']::text[]),
  ('JAFCO', array['deep_tech','life_science']::text[], array['Asia','Japan']::text[]),
  ('HV Capital', array['deep_tech','climate']::text[], array['Europe']::text[]),
  ('Earlybird', array['deep_tech']::text[], array['Europe']::text[]),
  ('EQT Ventures', array['deep_tech']::text[], array['Europe','Global']::text[]),
  ('Lakestar', array['deep_tech']::text[], array['Europe','Global']::text[]),
  ('Speedinvest', array['deep_tech','industrial']::text[], array['Europe']::text[]),
  ('Korea Investment Partners', array['deep_tech','life_science']::text[], array['Asia','Korea']::text[]),
  ('Legend Capital', array['deep_tech','life_science']::text[], array['Asia','China']::text[]),
  ('Forbion', array['life_science','advanced_materials']::text[], array['Europe','Global']::text[]),
  ('Medicxi', array['life_science','healthcare']::text[], array['Europe','Global']::text[]),
  ('HealthCap', array['life_science','healthcare']::text[], array['Europe','Global']::text[]),
  ('Kurma Partners', array['life_science','healthcare']::text[], array['Europe']::text[]),
  ('Gimv', array['life_science','healthcare']::text[], array['Europe']::text[]),
  ('Andera Partners', array['life_science','healthcare']::text[], array['Europe']::text[]),
  ('Qiming Venture Partners', array['life_science','healthcare']::text[], array['Asia','China']::text[]),
  ('Vertex Ventures', array['deep_tech','life_science']::text[], array['Asia','Global']::text[]),
  ('Syncona', array['life_science','healthcare']::text[], array['Europe','Global']::text[]),
  ('Abingworth', array['life_science','healthcare']::text[], array['Europe','Global']::text[])
) as v(party_name, sector_focus, geographic_focus)
  on v.party_name = p.party_name
where p.source = 'investor_global_2026Q3'
  and p.deleted_at is null
  and not exists (select 1 from app.investor_profile ip where ip.party_id = p.id);

-- investor_type_id=3 (cvc)
insert into app.investor_profile
  (party_id, investor_type_id, sector_focus, geographic_focus,
   is_lead_investor, organization_id)
select p.id, 3::smallint,
       v.sector_focus, v.geographic_focus, true,
       'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p
join (values
  ('BASF Venture Capital', array['advanced_materials','industrial','climate']::text[], array['Europe','Global']::text[]),
  ('Saint-Gobain NOVA', array['advanced_materials','industrial','climate']::text[], array['Europe','Global']::text[]),
  ('Syensqo Ventures', array['advanced_materials','climate','life_science']::text[], array['Europe','Global']::text[])
) as v(party_name, sector_focus, geographic_focus)
  on v.party_name = p.party_name
where p.source = 'investor_global_2026Q3'
  and p.deleted_at is null
  and not exists (select 1 from app.investor_profile ip where ip.party_id = p.id);

-- ---------- 3) investor_sector_focus ----------
insert into app.investor_sector_focus
  (investor_profile_id, sector_id, organization_id)
select ip.id, v.sector_id::smallint, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p
join app.investor_profile ip on ip.party_id = p.id
join (values
  ('BASF Venture Capital', 1),
  ('BASF Venture Capital', 2),
  ('BASF Venture Capital', 4),
  ('Saint-Gobain NOVA', 1),
  ('Saint-Gobain NOVA', 2),
  ('Saint-Gobain NOVA', 4),
  ('Syensqo Ventures', 1),
  ('Syensqo Ventures', 4),
  ('Syensqo Ventures', 16),
  ('World Fund', 1),
  ('World Fund', 4),
  ('World Fund', 3),
  ('Extantia Capital', 1),
  ('Extantia Capital', 4),
  ('Extantia Capital', 2),
  ('Planet A Ventures', 1),
  ('Planet A Ventures', 4),
  ('Planet A Ventures', 2),
  ('AP Ventures', 1),
  ('AP Ventures', 3),
  ('AP Ventures', 4),
  ('Pitango', 3),
  ('Pitango', 16),
  ('OurCrowd', 3),
  ('JAFCO', 3),
  ('JAFCO', 16),
  ('HV Capital', 3),
  ('HV Capital', 4),
  ('Earlybird', 3),
  ('EQT Ventures', 3),
  ('Lakestar', 3),
  ('Speedinvest', 3),
  ('Speedinvest', 2),
  ('Korea Investment Partners', 3),
  ('Korea Investment Partners', 16),
  ('Legend Capital', 3),
  ('Legend Capital', 16),
  ('Forbion', 16),
  ('Forbion', 1),
  ('Medicxi', 16),
  ('Medicxi', 9),
  ('HealthCap', 16),
  ('HealthCap', 9),
  ('Kurma Partners', 16),
  ('Kurma Partners', 9),
  ('Gimv', 16),
  ('Gimv', 9),
  ('Andera Partners', 16),
  ('Andera Partners', 9),
  ('Qiming Venture Partners', 16),
  ('Qiming Venture Partners', 9),
  ('Vertex Ventures', 3),
  ('Vertex Ventures', 16),
  ('Syncona', 16),
  ('Syncona', 9),
  ('Abingworth', 16),
  ('Abingworth', 9)
) as v(party_name, sector_id)
  on v.party_name = p.party_name
where p.source = 'investor_global_2026Q3'
  and p.deleted_at is null
  and not exists (
    select 1 from app.investor_sector_focus x
    where x.investor_profile_id = ip.id and x.sector_id = v.sector_id
  );

-- ---------- 4) investor_stage_focus ----------
-- All get series_a(3)+series_b(4); early-active firms get seed(2);
-- growth/late-capable firms get growth(11).
insert into app.investor_stage_focus
  (investor_profile_id, stage_id, organization_id)
select ip.id, v.stage_id::smallint, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p
join app.investor_profile ip on ip.party_id = p.id
join (values
  ('BASF Venture Capital', 3),
  ('BASF Venture Capital', 4),
  ('Saint-Gobain NOVA', 2),
  ('Saint-Gobain NOVA', 3),
  ('Syensqo Ventures', 2),
  ('Syensqo Ventures', 3),
  ('Syensqo Ventures', 4),
  ('World Fund', 2),
  ('World Fund', 3),
  ('World Fund', 4),
  ('Extantia Capital', 2),
  ('Extantia Capital', 3),
  ('Planet A Ventures', 2),
  ('Planet A Ventures', 3),
  ('AP Ventures', 2),
  ('AP Ventures', 3),
  ('AP Ventures', 4),
  ('Pitango', 2),
  ('Pitango', 3),
  ('Pitango', 4),
  ('OurCrowd', 2),
  ('OurCrowd', 3),
  ('OurCrowd', 4),
  ('JAFCO', 3),
  ('JAFCO', 4),
  ('HV Capital', 2),
  ('HV Capital', 3),
  ('HV Capital', 4),
  ('Earlybird', 2),
  ('Earlybird', 3),
  ('Earlybird', 4),
  ('EQT Ventures', 3),
  ('EQT Ventures', 4),
  ('EQT Ventures', 11),
  ('Lakestar', 3),
  ('Lakestar', 4),
  ('Lakestar', 11),
  ('Speedinvest', 2),
  ('Speedinvest', 3),
  ('Speedinvest', 4),
  ('Korea Investment Partners', 3),
  ('Korea Investment Partners', 4),
  ('Korea Investment Partners', 11),
  ('Legend Capital', 3),
  ('Legend Capital', 4),
  ('Legend Capital', 11),
  ('Forbion', 3),
  ('Forbion', 4),
  ('Forbion', 11),
  ('Medicxi', 2),
  ('Medicxi', 3),
  ('Medicxi', 4),
  ('HealthCap', 2),
  ('HealthCap', 3),
  ('HealthCap', 4),
  ('Kurma Partners', 2),
  ('Kurma Partners', 3),
  ('Kurma Partners', 4),
  ('Gimv', 3),
  ('Gimv', 4),
  ('Gimv', 11),
  ('Andera Partners', 2),
  ('Andera Partners', 3),
  ('Andera Partners', 4),
  ('Qiming Venture Partners', 3),
  ('Qiming Venture Partners', 4),
  ('Qiming Venture Partners', 11),
  ('Vertex Ventures', 3),
  ('Vertex Ventures', 4),
  ('Vertex Ventures', 11),
  ('Syncona', 3),
  ('Syncona', 4),
  ('Syncona', 11),
  ('Abingworth', 3),
  ('Abingworth', 4),
  ('Abingworth', 11)
) as v(party_name, stage_id)
  on v.party_name = p.party_name
where p.source = 'investor_global_2026Q3'
  and p.deleted_at is null
  and not exists (
    select 1 from app.investor_stage_focus x
    where x.investor_profile_id = ip.id and x.stage_id = v.stage_id
  );

commit;

-- ============================================================
-- Verify:
--   select count(*) as new_parties from app.parties where source='investor_global_2026Q3';
--   -- expect 27
--
--   select sec.code, count(distinct p.id)
--   from app.parties p
--   join app.investor_profile ip on ip.party_id=p.id
--   join app.investor_sector_focus isf on isf.investor_profile_id=ip.id
--   join app.sectors sec on sec.id=isf.sector_id
--   where p.source='investor_global_2026Q3' and p.deleted_at is null
--   group by sec.code order by 2 desc;
--
--   select coalesce(country_code,'(null)') cc, count(*) n
--   from app.parties where source='investor_global_2026Q3' group by 1 order by 2 desc;
--
-- Rollback this batch:
--   delete from app.parties where source='investor_global_2026Q3';
--   (cascades to investor_profile / sector_focus / stage_focus if FKs are ON DELETE CASCADE;
--    otherwise delete child rows first by investor_profile_id.)
-- ============================================================
