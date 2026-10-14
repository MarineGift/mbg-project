-- ============================================================
-- seed_20261014f_india_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- India update (reports "India PCC/GCC producers" + "India paper companies",
-- 2026-10). Already in URM and NOT redone: SMI links to JK Rayagada (46 kt),
-- BILT Sewa (15 kt), Century Lalkuan (45 kt), Andhra Rajahmundry (NewYield),
-- Satia (42 kt), Gulshan links to Orient Amlai and ITC Tribeni, and the
-- Gulshan, Wolkem and 20 Microns filler rows.
--
-- 1) Mill rows, only if no IN row matches the town or company (8 checks):
--    JK Rayagada, Satia, Century Lalkuan, Andhra Rajahmundry, Trident
--    Barnala, West Coast Dandeli, TNPL Kagithapuram, Silvertone Muzaffarnagar
-- 2) Filler rows if missing: Fimakem India, Omya (India) + profiles
-- 3) Links (batch 'india_update_20261014'):
--      Gulshan  -> Trident Barnala     potential  22 kt/yr planned FY2027-28
--      Gulshan  -> Silvertone          active     since 2013 (Gulshan names it)
--      Fimakem  -> ITC Bhadrachalam    active     medium (Wolkem names the site)
--      Fimakem  -> JK Rayagada         active     medium
-- 4) Plant blocks (Mill profile card) for India outreach priority 1-7:
--      1 JK Rayagada  2 Satia  3 Century Lalkuan (ITC since 2026-08)
--      4 Andhra Rajahmundry  5 Trident Barnala  6 West Coast Dandeli  7 TNPL
--    FCC scenarios only on writing-and-printing mills. Century and TNPL
--    capacities include board and tissue, so no scenario there.
--
-- Idempotent. Last statement is a verification select.
-- ============================================================

-- ---------- 1) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null and x.country_code = 'IN'
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'IN', v.region, v.city, v.website, 'active', 'india_update_20261014',
       v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('%Rayagada%', '%JK Paper%', 'JK Paper - JKPM Unit (Rayagada)', 'Odisha', 'Rayagada', 'https://www.jkpaper.com', 'JK Paper Mills unit at Jaykaypur, Rayagada - copy and printing and writing papers.'),
  ('%Muktsar%', '%Satia%', 'Satia Industries - Sri Muktsar Sahib Mill (Sri Muktsar Sahib)', 'Punjab', 'Sri Muktsar Sahib', 'https://www.satiagroup.com', 'Satia Industries writing and printing paper mill, agro-residue and wood furnish.'),
  ('%Lalkuan%', '%Century Pulp%', 'Century Pulp & Paper - Lalkuan Mill (Lalkuan)', 'Uttarakhand', 'Lalkuan', 'https://www.centurypaper.org.in', 'Century Pulp and Paper integrated mill at Lalkuan - printing and writing, board, tissue, pulp. Owned by ITC since 2026-08.'),
  ('%Rajahmundry%', '%Andhra Paper%', 'Andhra Paper - Rajahmundry Mill (Rajahmundry)', 'Andhra Pradesh', 'Rajahmundry', 'https://www.andhrapaper.com', 'Andhra Paper writing and printing paper mill at Rajahmundry (second unit at Kadiyam).'),
  ('%Barnala%', '%Trident%', 'Trident - Barnala Paper Mill (Barnala)', 'Punjab', 'Barnala', 'https://www.tridentindia.com', 'Trident Limited integrated wheat-straw based paper mill at Barnala - copy and writing and printing papers.'),
  ('%Dandeli%', '%West Coast Paper%', 'West Coast Paper Mills - Dandeli Mill (Dandeli)', 'Karnataka', 'Dandeli', 'https://www.westcoastpaper.com', 'West Coast Paper Mills integrated mill at Dandeli - printing, writing and copy papers.'),
  ('%Kagithapuram%', '%TNPL%', 'TNPL - Unit I Kagithapuram (Karur)', 'Tamil Nadu', 'Kagithapuram', 'https://www.tnpl.com', 'Tamil Nadu Newsprint and Papers Unit I at Kagithapuram, Karur - bagasse based printing and writing paper.'),
  ('%Silvertone%', '%Silvertone%', 'Silvertone Pulp & Paper Mill (Muzaffarnagar)', 'Uttar Pradesh', 'Muzaffarnagar', null, 'Silvertone Pulp and Paper Mill Pvt Ltd, Muzaffarnagar UP - host of a Gulshan on-site PCC plant since 2013.')
) as v(name_like, alt_like, party_name, region, city, website, notes)
where not exists (
  select 1 from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'IN'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
);

insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from app.parties p
where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'IN'
  and p.source = 'india_update_20261014'
  and not exists (select 1 from app.paper_mill_profile mp where mp.party_id = p.id);

-- ---------- 2) FILLER ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, notes, organization_id)
select 3::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 3 and x.deleted_at is null and x.country_code = 'IN'
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'IN', v.region, v.city, v.website, 'active', 'india_update_20261014',
       v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('Fimakem India', '%Fimakem%', 'Rajasthan', 'Udaipur', 'https://www.wolkem.com', 'Joint venture of Wolkem India and Fimatec (Japan). Ultrafine wet ground calcium carbonate slurry for paper. Satellite WGCC plants named by Wolkem: Bhadrachalam (Telangana), Rayagada (Odisha), plus a WGCC plant at Perundurai (Tamil Nadu). Current running status of each site to be confirmed.'),
  ('Omya (India)', 'Omya%India%', null, null, 'https://www.omya.com', 'Omya in India since 2004 with dry calcium carbonate and slurry plants, also covering Nepal, Sri Lanka and Bangladesh. Plant locations, capacities and paper customers not public. Royalty licensee at Omya HQ level - India is part of the global talks.')
) as v(party_name, guard_like, region, city, website, notes)
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
);

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   onsite_pcc_evidence, mineral_class, industry_source, notes, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
       d.onsite, d.mineral_class, 'industry-research', d.notes, '{}'::jsonb, now(), now()
from app.parties p
join (values
  ('Fimakem India', 'GCC producer', 'India satellite wet GCC slurry for paper (Wolkem + Fimatec JV)',
   'satellite (on-site) + merchant', 'B', 'Wolkem names satellite WGCC sites at Bhadrachalam and Rayagada.', 'gcc',
   'Wet-end filler is the FCC entry point - coating pigment needs separate validation.'),
  ('Omya (India)', 'GCC producer', 'Omya South Asia dry and slurry calcium carbonate',
   'merchant', 'C', null, 'gcc', 'Plant list not public.')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, onsite, mineral_class, notes)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'india_update_20261014'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 3) LINKS ----------
insert into app.party_supply_links
  (id, organization_id, mill_party_id, filler_party_id, link_type,
   product_grade, volume_estimate, confidence, active_since, active_until,
   notes, extra_data, created_at, updated_at)
select gen_random_uuid(), 'b25de8f2-1020-482f-9012-183f63883169'::uuid, m.id, f.id, r.link_type,
       case when r.filler_like like 'Fimakem%' then 'WGCC filler-grade' else 'PCC filler-grade' end,
       r.volume, r.confidence, r.since, null, r.label,
       jsonb_build_object('supply_structure', r.structure, 'evidence_url', r.evidence,
                          'source', r.src, 'batch', 'india_update_20261014', 'researched_at', '2026-10-14'),
       now(), now()
from (values
  ('Gulshan%', '%Barnala%', '%Trident%', '%Trident%', 'potential', 'medium', 'about 22,000 t/yr (planned)', null::date, 'Gulshan - Trident Barnala on-site PCC (contract 2026-03, start FY2027-28)', 'on-site PCC slurry plant (planned)', 'https://economictimes.indiatimes.com', 'Economic Times 2026-03'),
  ('Gulshan%', '%Silvertone%', '%Silvertone%', '%Silvertone%', 'active', 'high', null, '2013-01-01'::date, 'Gulshan - Silvertone Muzaffarnagar on-site PCC (2013)', 'on-site PCC (Gulshan owned)', 'https://www.gulshanindia.com', 'Gulshan company page'),
  ('Fimakem%', '%Bhadrachalam%', '%Bhadrachalam%', '%ITC%', 'active', 'medium', null, null::date, 'Fimakem - ITC Bhadrachalam satellite WGCC', 'satellite wet GCC', 'https://www.wolkem.com', 'Wolkem company page'),
  ('Fimakem%', '%Rayagada%', '%JK Paper%', '%JK%', 'active', 'medium', null, null::date, 'Fimakem - JK Paper Rayagada satellite WGCC', 'satellite wet GCC', 'https://www.wolkem.com', 'Wolkem company page')
) as r(filler_like, name_like, alt_like, owner_like, link_type, confidence, volume, since, label, structure, evidence, src)
cross join lateral (
  select x.id from app.parties x
  where x.party_type_id = 3 and x.deleted_at is null and x.party_name ilike r.filler_like
  order by x.created_at limit 1
) f
cross join lateral (
  select y.id from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'IN'
     and (y.party_name ilike r.name_like or y.party_name ilike r.alt_like or y.city ilike btrim(r.name_like, '%'))
  order by (y.party_name ilike r.owner_like) desc, (y.party_name ilike r.name_like) desc, y.created_at
  limit 1
) m
where not exists (
  select 1 from app.party_supply_links l
  where l.mill_party_id = m.id and l.filler_party_id = f.id and l.deleted_at is null
);

-- ---------- 4) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (values
  ('%Rayagada%', '%JK Paper%', '%JK%'),
  ('%Muktsar%', '%Satia%', '%Satia%'),
  ('%Lalkuan%', '%Century Pulp%', '%Century%'),
  ('%Rajahmundry%', '%Andhra Paper%', '%Andhra%'),
  ('%Barnala%', '%Trident%', '%Trident%'),
  ('%Dandeli%', '%West Coast Paper%', '%West Coast%'),
  ('%Kagithapuram%', '%TNPL%', '%Tamil Nadu%'),
  ('%Silvertone%', '%Silvertone%', '%Silvertone%')
) as v(name_like, alt_like, owner_like)
cross join lateral (
  select y.id from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'IN'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
  order by (y.party_name ilike v.owner_like) desc, (y.party_name ilike v.name_like) desc, y.created_at
  limit 1
) m
where not exists (select 1 from app.paper_mill_profile mp where mp.party_id = m.id);

update app.paper_mill_profile mp
set extra_data = coalesce(mp.extra_data, '{}'::jsonb) || jsonb_build_object('plant', m.plant),
    main_products = coalesce(nullif(btrim(mp.main_products), ''), m.plant ->> 'products'),
    updated_at = now()
from (
  select v.plant,
         (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'IN'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.owner_like) desc, (y.party_name ilike v.name_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Rayagada%', '%JK Paper%', '%JK%',
   $pj${"owner": "JK Paper Limited", "priority": 1, "products": "Copy paper, printing and writing papers", "grades": ["Copy paper", "Printing and writing"], "capacity": {"value": 315000, "unit": "metric_t", "year": "2025 investor analysis (JK group about 761,000-800,000 t)", "source": "Baroda Etrade, JK Paper site"}, "filler": [{"supplier": "Specialty Minerals (MTI)", "type": "On-site satellite PCC", "status": "Agreement 2011, over 46,000 t/yr expected", "basis": "MTI press release"}, {"supplier": "Fimakem India", "type": "Satellite wet GCC", "status": "Rayagada site named by Wolkem - confirm current", "basis": "Wolkem company page"}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.75, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 0.85, "fcc_share": 0.25, "fcc_loading": 0.2}, {"label": "Expanded", "utilization": 0.9, "fcc_share": 0.5, "fcc_loading": 0.25}], "note": "Planning scenarios on nameplate paper capacity, not orders. FCC in sheet is not the same as pulp replaced."}, "pitch": "Pulp saving in copy and printing grades while holding strength and opacity", "approach": "Lead India account. Meet the Rayagada technical and production heads. FCC supply goes through SMI as producer and licensee.", "to_collect": ["Current PCC / GCC supplier per machine and contract term", "Actual annual PCC and GCC use (t) and solids basis", "Furnish per grade - wood, agro-residue, recycled fibre shares", "Filler loading per grade and target increase", "Quality gates FCC must pass - strength, opacity, brightness, bulk, retention", "Who approves a mill trial (technical and purchasing)"], "sources": [{"label": "MTI JK Paper agreement 2011"}, {"label": "JK Paper site"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Muktsar%', '%Satia%', '%Satia%',
   $pj${"owner": "Satia Industries Limited", "priority": 2, "products": "Copy and writing and printing papers", "grades": ["Copy paper", "Writing and printing"], "capacity": {"value": 219000, "unit": "metric_t", "year": "FY2024-25", "source": "Papermart industry data"}, "filler": [{"supplier": "Specialty Minerals (MTI)", "type": "On-site satellite PCC", "status": "Agreement 2020, about 42,000 t/yr, running since 2021", "basis": "MTI press release 2020-05-21"}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.75, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 0.85, "fcc_share": 0.25, "fcc_loading": 0.2}, {"label": "Expanded", "utilization": 0.9, "fcc_share": 0.5, "fcc_loading": 0.25}], "note": "Planning scenarios on nameplate paper capacity, not orders. FCC in sheet is not the same as pulp replaced."}, "pitch": "High PCC use relative to paper output - test FCC strength support in an agro-residue furnish", "approach": "Pilot candidate. Mill head and papermaking technical head first, with SMI.", "to_collect": ["Current PCC / GCC supplier per machine and contract term", "Actual annual PCC and GCC use (t) and solids basis", "Furnish per grade - wood, agro-residue, recycled fibre shares", "Filler loading per grade and target increase", "Quality gates FCC must pass - strength, opacity, brightness, bulk, retention", "Who approves a mill trial (technical and purchasing)"], "sources": [{"label": "MTI Satia agreement 2020-05-21"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Lalkuan%', '%Century Pulp%', '%Century%',
   $pj${"owner": "ITC Limited (business transferred 2026-08-01, previously Century Pulp & Paper of the Aditya Birla group)", "priority": 3, "products": "Printing and writing papers, paperboard, tissue and pulp", "grades": ["Writing and printing", "Paperboard", "Tissue"], "capacity": {"value": 480000, "unit": "metric_t", "year": "At transfer to ITC 2026-08 - all grades", "source": "ITC, Business Standard"}, "filler": [{"supplier": "Specialty Minerals (MTI)", "type": "On-site satellite PCC", "status": "Agreement 2019, about 45,000 t/yr", "basis": "MTI press release"}], "pitch": "One site to prove FCC across printing paper, board and tissue", "approach": "Approach via ITC PSPD now. Whole-mill tonnage mixes board and tissue - split grade capacity before any volume estimate.", "recent": [{"date": "2026-08-01", "text": "Century Pulp and Paper transferred to ITC - ITC paper group about 1.5M t/yr"}], "to_collect": ["Current PCC / GCC supplier per machine and contract term", "Actual annual PCC and GCC use (t) and solids basis", "Furnish per grade - wood, agro-residue, recycled fibre shares", "Filler loading per grade and target increase", "Quality gates FCC must pass - strength, opacity, brightness, bulk, retention", "Who approves a mill trial (technical and purchasing)"], "sources": [{"label": "ITC announcement, Business Standard 2026"}, {"label": "MTI Century agreement 2019"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Rajahmundry%', '%Andhra Paper%', '%Andhra%',
   $pj${"owner": "Andhra Paper Limited (West Coast Paper group)", "priority": 4, "products": "Writing and printing papers", "grades": ["Writing and printing"], "capacity": {"value": 259400, "unit": "metric_t", "year": "FY2024-25, Rajahmundry plus Kadiyam", "source": "Papermart industry data"}, "filler": [{"supplier": "Specialty Minerals (MTI)", "type": "On-site satellite PCC, NewYield LO", "status": "Agreement 2023, running since 2024", "basis": "MTI 2023 release - the 180,000 t figure covers three sites, not Andhra alone"}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.75, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 0.85, "fcc_share": 0.25, "fcc_loading": 0.2}, {"label": "Expanded", "utilization": 0.9, "fcc_share": 0.5, "fcc_loading": 0.25}], "note": "Planning scenarios on nameplate paper capacity, not orders. FCC in sheet is not the same as pulp replaced."}, "pitch": "Already adopted a new PCC technology - open to filler innovation", "approach": "Work through SMI, which runs the NewYield plant on site.", "to_collect": ["Current PCC / GCC supplier per machine and contract term", "Actual annual PCC and GCC use (t) and solids basis", "Furnish per grade - wood, agro-residue, recycled fibre shares", "Filler loading per grade and target increase", "Quality gates FCC must pass - strength, opacity, brightness, bulk, retention", "Who approves a mill trial (technical and purchasing)"], "sources": [{"label": "MTI 2023 three-satellite release"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Barnala%', '%Trident%', '%Trident%',
   $pj${"owner": "Trident Limited", "priority": 5, "products": "Copy and writing and printing papers (wheat-straw based)", "grades": ["Copy paper", "Writing and printing"], "capacity": {"value": 175000, "unit": "metric_t", "year": "CRISIL rating note 2026-08", "source": "CRISIL"}, "filler": [{"supplier": "Gulshan Polyols", "type": "On-site PCC slurry plant", "status": "Contract 2026-03, about 22,000 t/yr, revenue starting FY2027-28", "basis": "Economic Times 2026-03 - not yet running"}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.75, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 0.85, "fcc_share": 0.25, "fcc_loading": 0.2}, {"label": "Expanded", "utilization": 0.9, "fcc_share": 0.5, "fcc_loading": 0.25}], "note": "Planning scenarios on nameplate paper capacity, not orders. FCC in sheet is not the same as pulp replaced."}, "pitch": "A new PCC plant is being designed now - the moment to bring a better filler to the spec", "approach": "Approach Trident and Gulshan together while the plant is still being built.", "recent": [{"date": "2026-03", "text": "Gulshan Polyols to build a 22,000 t/yr on-site PCC slurry plant at Barnala"}], "to_collect": ["Current PCC / GCC supplier per machine and contract term", "Actual annual PCC and GCC use (t) and solids basis", "Furnish per grade - wood, agro-residue, recycled fibre shares", "Filler loading per grade and target increase", "Quality gates FCC must pass - strength, opacity, brightness, bulk, retention", "Who approves a mill trial (technical and purchasing)"], "sources": [{"label": "Economic Times 2026-03"}, {"label": "CRISIL 2026-08"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Dandeli%', '%West Coast Paper%', '%West Coast%',
   $pj${"owner": "West Coast Paper Mills Limited", "priority": 6, "products": "Printing, writing and copy papers", "grades": ["Writing and printing", "Copy paper"], "capacity": {"value": 320000, "unit": "metric_t", "year": "FY2024-25, output about 318,590 t", "source": "Papermart industry data"}, "filler": [{"supplier": "Not confirmed", "type": "-", "status": "Unknown", "basis": "No public supplier found"}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.75, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 0.85, "fcc_share": 0.25, "fcc_loading": 0.2}, {"label": "Expanded", "utilization": 0.9, "fcc_share": 0.5, "fcc_loading": 0.25}], "note": "Planning scenarios on nameplate paper capacity, not orders. FCC in sheet is not the same as pulp replaced."}, "pitch": "Printing-paper focused mill - pulp saving is easy to measure", "approach": "Find the current filler supplier first, then set any volume estimate.", "to_collect": ["Current PCC / GCC supplier per machine and contract term", "Actual annual PCC and GCC use (t) and solids basis", "Furnish per grade - wood, agro-residue, recycled fibre shares", "Filler loading per grade and target increase", "Quality gates FCC must pass - strength, opacity, brightness, bulk, retention", "Who approves a mill trial (technical and purchasing)"], "sources": [{"label": "Papermart FY2024-25"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Kagithapuram%', '%TNPL%', '%Tamil Nadu%',
   $pj${"owner": "Tamil Nadu Newsprint and Papers Limited (state owned)", "priority": 7, "products": "Bagasse based printing and writing papers, and board (Unit II Tiruchirappalli)", "grades": ["Writing and printing", "Paperboard"], "capacity": {"value": 600000, "unit": "metric_t", "year": "FY2024-25 - Units I and II, includes board", "source": "Papermart industry data"}, "filler": [{"supplier": "Gulshan Polyols", "type": "Merchant PCC supply", "status": "Listed by Gulshan as a PCC customer", "basis": "Gulshan supply list - merchant, not on-site"}], "pitch": "Test FCC with non-wood (bagasse) fibre - strength and drainage at higher filler", "approach": "Split printing and board lines first - the 600,000 t includes board.", "to_collect": ["Current PCC / GCC supplier per machine and contract term", "Actual annual PCC and GCC use (t) and solids basis", "Furnish per grade - wood, agro-residue, recycled fibre shares", "Filler loading per grade and target increase", "Quality gates FCC must pass - strength, opacity, brightness, bulk, retention", "Who approves a mill trial (technical and purchasing)"], "sources": [{"label": "Papermart FY2024-25"}, {"label": "Gulshan company page"}], "checked_at": "2026-10-14"}$pj$::jsonb)
  ) as v(name_like, alt_like, owner_like, plant)
) m
where mp.party_id = m.id;

-- ---------- 5) VERIFY ----------
with v(name_like, alt_like, owner_like) as (values
  ('%Rayagada%', '%JK Paper%', '%JK%'),
  ('%Muktsar%', '%Satia%', '%Satia%'),
  ('%Lalkuan%', '%Century Pulp%', '%Century%'),
  ('%Rajahmundry%', '%Andhra Paper%', '%Andhra%'),
  ('%Barnala%', '%Trident%', '%Trident%'),
  ('%Dandeli%', '%West Coast Paper%', '%West Coast%'),
  ('%Kagithapuram%', '%TNPL%', '%Tamil Nadu%'),
  ('%Silvertone%', '%Silvertone%', '%Silvertone%')
)
select 'mill' as kind, coalesce(m.party_name, 'MISSING ' || v.name_like) as name,
       case when m.source = 'india_update_20261014' then 'added now' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as detail
from v
left join lateral (
  select y.id, y.party_name, y.source from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'IN'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
  order by (y.party_name ilike v.owner_like) desc, (y.party_name ilike v.name_like) desc, y.created_at
  limit 1
) m on true
left join app.paper_mill_profile mp on mp.party_id = m.id
union all
select 'filler', p.party_name,
       case when p.source = 'india_update_20261014' then 'added now' else 'already there' end, '-'
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null
  and (p.party_name ilike '%Fimakem%' or p.party_name ilike 'Omya%India%')
union all
select 'link', f.party_name || ' -> ' || m.party_name, l.link_type, coalesce(l.confidence, '-')
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and l.extra_data->>'batch' = 'india_update_20261014'
order by 1, 4, 2;
