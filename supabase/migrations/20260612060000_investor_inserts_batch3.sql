-- ============================================================
-- 20260612060000_investor_inserts_batch3.sql
-- batch3: Life-science large crossover/specialist funds +
-- advanced-materials / deep-tech corporate CVCs.
-- All NEW (checked against live AM/DT/LS lists, 2026-06-12).
-- Source tag: investor_enrich_2026Q3_b3 (distinct from b1/b2 so
-- this batch can be rolled back independently).
--
-- Vocab: party_type investor=1, entity_type company=1 / fund=4,
--   investor_type vc=1 / cvc=3,
--   sectors: advanced_materials=1, deep_tech=3, energy=5,
--            healthcare=9, life_science=16, industrial=2, ai=6,
--   stages: seed=2, series_a=3, series_b=4, growth=11.
-- ============================================================

begin;

-- ---------- 1) parties ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, status, source,
   country_code, region, city, website, organization_id)
select v.* from (values
  -- Life-science large crossover / specialist funds
  (1::smallint,1::smallint,'EcoR1 Capital','active','investor_enrich_2026Q3_b3','US','CA','San Francisco','https://www.ecor1cap.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1,1,'Perceptive Advisors','active','investor_enrich_2026Q3_b3','US','NY','New York','https://www.perceptivelife.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'RTW Investments','active','investor_enrich_2026Q3_b3','US','NY','New York','https://www.rtwfunds.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Deep Track Capital','active','investor_enrich_2026Q3_b3','US','CT','Greenwich','https://www.deeptrackcapital.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'venBio','active','investor_enrich_2026Q3_b3','US','CA','San Francisco','https://www.venbio.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Vida Ventures','active','investor_enrich_2026Q3_b3','US','CA','Los Angeles','https://www.vidaventures.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Baker Brothers Advisors','active','investor_enrich_2026Q3_b3','US','NY','New York','https://www.bakerbros.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Redmile Group','active','investor_enrich_2026Q3_b3','US','CA','San Francisco','https://www.redmilegrp.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'MPM BioImpact','active','investor_enrich_2026Q3_b3','US','MA','Boston','https://www.mpmbioimpact.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Cormorant Asset Management','active','investor_enrich_2026Q3_b3','US','MA','Boston','https://www.cormorantco.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Avoro Capital Advisors','active','investor_enrich_2026Q3_b3','US','CA','San Francisco','https://www.avorocapital.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Logos Capital','active','investor_enrich_2026Q3_b3','US','CA','San Francisco','https://www.logoscapital.com','b25de8f2-1020-482f-9012-183f63883169'),
  -- Advanced-materials / deep-tech corporate CVCs + funds
  (1,4,'BASF Venture Capital','active','investor_enrich_2026Q3_b3','US','CA','Fremont','https://www.basf-vc.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,4,'Saint-Gobain NOVA','active','investor_enrich_2026Q3_b3','US','MA','Northborough','https://www.saint-gobain.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,4,'GM Ventures','active','investor_enrich_2026Q3_b3','US','MI','Detroit','https://www.gmventures.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,4,'Diamond Edge Ventures','active','investor_enrich_2026Q3_b3','US','CA','Mountain View','https://www.diamondedge.vc','b25de8f2-1020-482f-9012-183f63883169'),
  (1,4,'Toyota Ventures','active','investor_enrich_2026Q3_b3','US','CA','Los Altos','https://www.toyota.ventures','b25de8f2-1020-482f-9012-183f63883169'),
  (1,4,'In-Q-Tel','active','investor_enrich_2026Q3_b3','US','VA','Arlington','https://www.iqt.org','b25de8f2-1020-482f-9012-183f63883169'),
  (1,1,'Prime Movers Lab','active','investor_enrich_2026Q3_b3','US','WY','Jackson','https://www.primemoverslab.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,4,'Mitsui Global Investment','active','investor_enrich_2026Q3_b3','US','CA','Menlo Park','https://www.mitsui.com','b25de8f2-1020-482f-9012-183f63883169'),
  (1,4,'Sumitomo Corp Equity Asia / Presidio','active','investor_enrich_2026Q3_b3','US','CA','San Francisco','https://www.presidio.vc','b25de8f2-1020-482f-9012-183f63883169')
) as v(party_type_id, entity_type_id, party_name, status, source,
       country_code, region, city, website, organization_id)
where not exists (
  select 1 from app.parties p
  where p.party_name = v.party_name and p.deleted_at is null
);

-- ---------- 2) investor_profile ----------
-- LS funds (investor_type vc=1)
insert into app.investor_profile
  (party_id, investor_type_id, sector_focus, geographic_focus, is_lead_investor, organization_id)
select p.id, 1::smallint,
       array['life_science','healthcare']::text[], array['US']::text[], true,
       'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p
where p.source='investor_enrich_2026Q3_b3'
  and p.party_name in ('EcoR1 Capital','Perceptive Advisors','RTW Investments',
    'Deep Track Capital','venBio','Vida Ventures','Baker Brothers Advisors',
    'Redmile Group','MPM BioImpact','Cormorant Asset Management',
    'Avoro Capital Advisors','Logos Capital')
  and not exists (select 1 from app.investor_profile ip where ip.party_id=p.id);

-- AM/DT CVCs (investor_type cvc=3, except Prime Movers Lab = vc)
insert into app.investor_profile
  (party_id, investor_type_id, sector_focus, geographic_focus, is_strategic, organization_id)
select p.id,
       case when p.party_name='Prime Movers Lab' then 1 else 3 end::smallint,
       array['advanced_materials','deep_tech','industrial']::text[], array['US']::text[],
       case when p.party_name='Prime Movers Lab' then false else true end,
       'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p
where p.source='investor_enrich_2026Q3_b3'
  and p.party_name in ('BASF Venture Capital','Saint-Gobain NOVA','GM Ventures',
    'Diamond Edge Ventures','Toyota Ventures','In-Q-Tel','Prime Movers Lab',
    'Mitsui Global Investment','Sumitomo Corp Equity Asia / Presidio')
  and not exists (select 1 from app.investor_profile ip where ip.party_id=p.id);

-- ---------- 3) investor_sector_focus ----------
-- LS funds -> life_science(16)+healthcare(9)
insert into app.investor_sector_focus (investor_profile_id, sector_id, organization_id)
select ip.id, s.sid::smallint, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p
join app.investor_profile ip on ip.party_id=p.id
cross join (values (16),(9)) s(sid)
where p.source='investor_enrich_2026Q3_b3'
  and p.party_name in ('EcoR1 Capital','Perceptive Advisors','RTW Investments',
    'Deep Track Capital','venBio','Vida Ventures','Baker Brothers Advisors',
    'Redmile Group','MPM BioImpact','Cormorant Asset Management',
    'Avoro Capital Advisors','Logos Capital')
  and not exists (select 1 from app.investor_sector_focus x
                  where x.investor_profile_id=ip.id and x.sector_id=s.sid);

-- AM/DT CVCs -> advanced_materials(1)+deep_tech(3)+industrial(2)
insert into app.investor_sector_focus (investor_profile_id, sector_id, organization_id)
select ip.id, s.sid::smallint, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p
join app.investor_profile ip on ip.party_id=p.id
cross join (values (1),(3),(2)) s(sid)
where p.source='investor_enrich_2026Q3_b3'
  and p.party_name in ('BASF Venture Capital','Saint-Gobain NOVA','GM Ventures',
    'Diamond Edge Ventures','Toyota Ventures','In-Q-Tel','Prime Movers Lab',
    'Mitsui Global Investment','Sumitomo Corp Equity Asia / Presidio')
  and not exists (select 1 from app.investor_sector_focus x
                  where x.investor_profile_id=ip.id and x.sector_id=s.sid);

-- energy(5) for the energy-active CVCs
insert into app.investor_sector_focus (investor_profile_id, sector_id, organization_id)
select ip.id, 5::smallint, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p
join app.investor_profile ip on ip.party_id=p.id
where p.source='investor_enrich_2026Q3_b3'
  and p.party_name in ('BASF Venture Capital','GM Ventures','Toyota Ventures','Prime Movers Lab')
  and not exists (select 1 from app.investor_sector_focus x
                  where x.investor_profile_id=ip.id and x.sector_id=5);

-- ---------- 4) investor_stage_focus ----------
-- LS funds: mostly series_a/b (+ seed for early-stage ones, growth for crossover)
insert into app.investor_stage_focus (investor_profile_id, stage_id, organization_id)
select ip.id, st.sid::smallint, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p
join app.investor_profile ip on ip.party_id=p.id
cross join (values (3),(4)) st(sid)
where p.source='investor_enrich_2026Q3_b3'
  and not exists (select 1 from app.investor_stage_focus x
                  where x.investor_profile_id=ip.id and x.stage_id=st.sid);

-- seed for early-stage-active firms
insert into app.investor_stage_focus (investor_profile_id, stage_id, organization_id)
select ip.id, 2::smallint, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p
join app.investor_profile ip on ip.party_id=p.id
where p.source='investor_enrich_2026Q3_b3'
  and p.party_name in ('Perceptive Advisors','venBio','Vida Ventures','MPM BioImpact',
    'Toyota Ventures','Prime Movers Lab','In-Q-Tel','Diamond Edge Ventures',
    'BASF Venture Capital','Saint-Gobain NOVA')
  and not exists (select 1 from app.investor_stage_focus x
                  where x.investor_profile_id=ip.id and x.stage_id=2);

-- growth for crossover / late-capable funds
insert into app.investor_stage_focus (investor_profile_id, stage_id, organization_id)
select ip.id, 11::smallint, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p
join app.investor_profile ip on ip.party_id=p.id
where p.source='investor_enrich_2026Q3_b3'
  and p.party_name in ('Perceptive Advisors','RTW Investments','Deep Track Capital',
    'Baker Brothers Advisors','Redmile Group','Cormorant Asset Management',
    'Avoro Capital Advisors','Logos Capital','GM Ventures')
  and not exists (select 1 from app.investor_stage_focus x
                  where x.investor_profile_id=ip.id and x.stage_id=11);

commit;

-- Verify:
-- select count(*) from app.parties where source='investor_enrich_2026Q3_b3';  -- expect 21
-- Rollback this batch only:
-- delete from app.parties where source='investor_enrich_2026Q3_b3';
