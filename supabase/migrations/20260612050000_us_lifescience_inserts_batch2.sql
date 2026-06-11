-- ============================================================
-- 20260612050000_us_lifescience_inserts_batch2.sql
-- Nationwide US life-science investor enrichment (batch 2).
-- Focus: life_science (weakest target sector) + healthcare.
-- Source tag: investor_enrich_2026Q3.
--
-- Dedup: every firm below was checked against the live list of
-- existing life_science/healthcare investors (2026-06-12) and is
-- NOT already present. NOT EXISTS(party_name) guard is a backstop.
--
-- Verified per firm: real firm, HQ location, sector + stage focus
-- (web research, 2026-06). Detailed metadata (ticket size, fund
-- size) intentionally left null for later enrichment.
--
-- Vocab (live):
--   party_types.investor=1, entity_types.company=1, investor_types.vc=1
--   sectors: life_science=16, healthcare=9
--   stages: seed=2, series_a=3, series_b=4, series_c=5,
--           early=10, growth=11, late=12
-- ============================================================

begin;

-- ---------- 1) parties ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, status, source,
   country_code, region, city, website, organization_id)
select v.* from (values
  (1::smallint,1::smallint,'Omega Funds','active','investor_enrich_2026Q3','US','MA','Boston','https://www.omegafunds.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1,1,'Northpond Ventures','active','investor_enrich_2026Q3','US','MD','Bethesda','https://www.northpond.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Sofinnova Investments','active','investor_enrich_2026Q3','US','CA','Menlo Park','https://sofinnovainvestments.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'SV Health Investors','active','investor_enrich_2026Q3','US','MA','Boston','https://www.svhealthinvestors.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Bain Capital Life Sciences','active','investor_enrich_2026Q3','US','MA','Boston','https://www.baincapitallifesciences.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Lightstone Ventures','active','investor_enrich_2026Q3','US','MA','Boston','https://www.lightstonevc.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Longitude Capital','active','investor_enrich_2026Q3','US','CA','Menlo Park','https://www.longitudecapital.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'New Leaf Venture Partners','active','investor_enrich_2026Q3','US','NY','New York','https://www.nlvpartners.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'New Science Ventures','active','investor_enrich_2026Q3','US','CT','Greenwich','https://www.newscienceventures.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Casdin Capital','active','investor_enrich_2026Q3','US','NY','New York','https://www.casdincapital.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Frazier Healthcare Partners','active','investor_enrich_2026Q3','US','WA','Seattle','https://www.frazierhealthcare.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Hatteras Venture Partners','active','investor_enrich_2026Q3','US','NC','Durham','https://www.hatterasvp.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Alexandria Venture Investments','active','investor_enrich_2026Q3','US','CA','Pasadena','https://www.areit.com/venture','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Avalon Ventures','active','investor_enrich_2026Q3','US','CA','La Jolla','https://www.avalonventures.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Boxer Capital','active','investor_enrich_2026Q3','US','CA','San Diego','https://www.boxercapital.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Genoa Ventures','active','investor_enrich_2026Q3','US','CA','San Francisco','https://www.genoaventures.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Civilization Ventures','active','investor_enrich_2026Q3','US','CA','San Francisco','https://www.civ.vc','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Sanderling Ventures','active','investor_enrich_2026Q3','US','CA','San Mateo','https://www.sanderling.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Foothill Ventures','active','investor_enrich_2026Q3','US','CA','Los Altos','https://www.foothill.ventures','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Lightspeed Venture Partners','active','investor_enrich_2026Q3','US','CA','Menlo Park','https://lsvp.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'SpringRock Ventures','active','investor_enrich_2026Q3','US','WA','Seattle','https://www.springrockventures.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Venture Investors Health Fund','active','investor_enrich_2026Q3','US','WI','Madison','https://www.ventureinvestors.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'5AM Ventures II','active','investor_enrich_2026Q3','US','CA','San Diego','https://www.5amventures.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Vivo Capital','active','investor_enrich_2026Q3','US','CA','Palo Alto','https://www.vivocapital.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Sofinnova Partners US','active','investor_enrich_2026Q3','US','CA','La Jolla','https://www.sofinnovapartners.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Column Group','active','investor_enrich_2026Q3','US','CA','San Francisco','https://www.thecolumngroup.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Westlake Village BioPartners','active','investor_enrich_2026Q3','US','CA','Westlake Village','https://www.westlakebiopartners.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Samsara BioCapital','active','investor_enrich_2026Q3','US','CA','Menlo Park','https://www.samsarabiocapital.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Mubadala Capital Ventures','active','investor_enrich_2026Q3','US','CA','San Francisco','https://www.mubadalacapital.ae','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Decheng Capital','active','investor_enrich_2026Q3','US','CA','Menlo Park','https://www.dechengcapital.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'aMoon Fund','active','investor_enrich_2026Q3','US','MA','Boston','https://www.amoon.vc','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Cure Ventures','active','investor_enrich_2026Q3','US','MA','Boston','https://www.cureventures.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Dimension Capital','active','investor_enrich_2026Q3','US','MA','Cambridge','https://www.dimension.xyz','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Catalio Capital Management','active','investor_enrich_2026Q3','US','NY','New York','https://www.catalio.com','b25de8f2-1020-482f-9012-183f63883169')
) as v(party_type_id, entity_type_id, party_name, status, source,
       country_code, region, city, website, organization_id)
where not exists (
  select 1 from app.parties p
  where p.party_name = v.party_name and p.deleted_at is null
);

-- ---------- 2) investor_profile (one per new party) ----------
insert into app.investor_profile
  (party_id, investor_type_id, sector_focus, geographic_focus,
   is_lead_investor, organization_id)
select p.id, 1::smallint,
       array['life_science','healthcare']::text[],
       array['US']::text[],
       true,
       'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p
where p.source = 'investor_enrich_2026Q3'
  and p.party_name in (
    'Omega Funds','Northpond Ventures','Sofinnova Investments','SV Health Investors',
    'Bain Capital Life Sciences','Lightstone Ventures','Longitude Capital',
    'New Leaf Venture Partners','New Science Ventures','Casdin Capital',
    'Frazier Healthcare Partners','Hatteras Venture Partners','Alexandria Venture Investments',
    'Avalon Ventures','Boxer Capital','Genoa Ventures','Civilization Ventures',
    'Sanderling Ventures','Foothill Ventures','Lightspeed Venture Partners',
    'SpringRock Ventures','Venture Investors Health Fund','5AM Ventures II','Vivo Capital',
    'Sofinnova Partners US','Column Group','Westlake Village BioPartners','Samsara BioCapital',
    'Mubadala Capital Ventures','Decheng Capital','aMoon Fund','Cure Ventures',
    'Dimension Capital','Catalio Capital Management'
  )
  and not exists (select 1 from app.investor_profile ip where ip.party_id = p.id);

-- ---------- 3) investor_sector_focus ----------
-- All get life_science(16). Most also healthcare(9).
insert into app.investor_sector_focus
  (investor_profile_id, sector_id, organization_id)
select ip.id, s.sector_id::smallint,
       'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p
join app.investor_profile ip on ip.party_id = p.id
cross join (values (16),(9)) as s(sector_id)
where p.source = 'investor_enrich_2026Q3'
  and p.party_name in (
    'Omega Funds','Northpond Ventures','Sofinnova Investments','SV Health Investors',
    'Bain Capital Life Sciences','Lightstone Ventures','Longitude Capital',
    'New Leaf Venture Partners','New Science Ventures','Casdin Capital',
    'Frazier Healthcare Partners','Hatteras Venture Partners','Alexandria Venture Investments',
    'Avalon Ventures','Boxer Capital','Genoa Ventures','Civilization Ventures',
    'Sanderling Ventures','Foothill Ventures','Lightspeed Venture Partners',
    'SpringRock Ventures','Venture Investors Health Fund','5AM Ventures II','Vivo Capital',
    'Sofinnova Partners US','Column Group','Westlake Village BioPartners','Samsara BioCapital',
    'Mubadala Capital Ventures','Decheng Capital','aMoon Fund','Cure Ventures',
    'Dimension Capital','Catalio Capital Management'
  )
  and not exists (
    select 1 from app.investor_sector_focus x
    where x.investor_profile_id = ip.id and x.sector_id = s.sector_id
  );

-- ---------- 4) investor_stage_focus ----------
-- Default Series A / B for this batch (all are Series A+ capable).
-- A few early/seed-active firms also get seed; growth-stage firms get growth.
insert into app.investor_stage_focus
  (investor_profile_id, stage_id, organization_id)
select ip.id, st.stage_id::smallint,
       'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p
join app.investor_profile ip on ip.party_id = p.id
cross join (values (3),(4)) as st(stage_id)   -- series_a, series_b for ALL
where p.source = 'investor_enrich_2026Q3'
  and p.party_name in (
    'Omega Funds','Northpond Ventures','Sofinnova Investments','SV Health Investors',
    'Bain Capital Life Sciences','Lightstone Ventures','Longitude Capital',
    'New Leaf Venture Partners','New Science Ventures','Casdin Capital',
    'Frazier Healthcare Partners','Hatteras Venture Partners','Alexandria Venture Investments',
    'Avalon Ventures','Boxer Capital','Genoa Ventures','Civilization Ventures',
    'Sanderling Ventures','Foothill Ventures','Lightspeed Venture Partners',
    'SpringRock Ventures','Venture Investors Health Fund','5AM Ventures II','Vivo Capital',
    'Sofinnova Partners US','Column Group','Westlake Village BioPartners','Samsara BioCapital',
    'Mubadala Capital Ventures','Decheng Capital','aMoon Fund','Cure Ventures',
    'Dimension Capital','Catalio Capital Management'
  )
  and not exists (
    select 1 from app.investor_stage_focus x
    where x.investor_profile_id = ip.id and x.stage_id = st.stage_id
  );

-- Seed-active early-stage firms get seed(2) too
insert into app.investor_stage_focus
  (investor_profile_id, stage_id, organization_id)
select ip.id, 2::smallint,
       'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p
join app.investor_profile ip on ip.party_id = p.id
where p.source = 'investor_enrich_2026Q3'
  and p.party_name in (
    'Avalon Ventures','Genoa Ventures','Civilization Ventures','Sanderling Ventures',
    'Foothill Ventures','SpringRock Ventures','Hatteras Venture Partners',
    'Venture Investors Health Fund','Cure Ventures','Dimension Capital','aMoon Fund'
  )
  and not exists (
    select 1 from app.investor_stage_focus x
    where x.investor_profile_id = ip.id and x.stage_id = 2
  );

-- Growth/late-capable firms get growth(11)
insert into app.investor_stage_focus
  (investor_profile_id, stage_id, organization_id)
select ip.id, 11::smallint,
       'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p
join app.investor_profile ip on ip.party_id = p.id
where p.source = 'investor_enrich_2026Q3'
  and p.party_name in (
    'Bain Capital Life Sciences','Longitude Capital','SV Health Investors',
    'Vivo Capital','Frazier Healthcare Partners','Casdin Capital',
    'Decheng Capital','Catalio Capital Management','Mubadala Capital Ventures'
  )
  and not exists (
    select 1 from app.investor_stage_focus x
    where x.investor_profile_id = ip.id and x.stage_id = 11
  );

commit;

-- Verify counts:
-- select count(*) as new_parties
-- from app.parties where source='investor_enrich_2026Q3';
--
-- select sec.code, count(distinct p.id)
-- from app.parties p
-- join app.party_types pt on pt.id=p.party_type_id and pt.code='investor'
-- join app.investor_profile ip on ip.party_id=p.id
-- join app.investor_sector_focus isf on isf.investor_profile_id=ip.id
-- join app.sectors sec on sec.id=isf.sector_id
-- where sec.code in ('life_science','healthcare') and p.deleted_at is null
-- group by sec.code;
--
-- Rollback this batch:
-- delete from app.parties where source='investor_enrich_2026Q3'
--   and party_name not in ('Gigafund','Bios Partners');  -- keep batch1
