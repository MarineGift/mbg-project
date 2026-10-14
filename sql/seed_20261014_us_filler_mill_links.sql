-- ============================================================
-- seed_20261014_us_filler_mill_links.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- US filler supplier gaps (report "US paper PCC/GCC producers", 2026-10)
-- plus the paper mills they supply.
--
-- Already in URM, NOT touched here: Minerals Technologies, Specialty
-- Minerals (HQ / USA Regional HQ), Omya (USA), Mississippi Lime, Imerys,
-- Artemyn, Lhoist (HQ), Carmeuse, Huber.
--
-- 1) New filler_supplier companies (2)
--      Columbia River Carbonates  - Woodland WA, Omya + Bleeck JV, paper GCC
--      GLC Minerals               - Green Bay WI, GCC processor, paper minor
-- 2) SMI US satellite PCC plants that the FY2024 MTI 10-K lists (filed
--    2025-02-21, Item 2 Properties) but that may be missing as plant rows:
--      Selma AL, Ashdown AR, Quinnesec MI, Cloquet MN, International Falls MN,
--      Eastover SC, Longview WA, Superior WI
--    Each row is added ONLY if no 'Specialty Minerals%<town>%' filler row
--    exists yet. Ticonderoga, Wickliffe, Chillicothe already exist.
-- 3) Host paper mills, added ONLY if no US mill row matches the town:
--      IP Riverdale (Selma AL), Billerud Quinnesec, Boise Paper / PCA
--      International Falls, Nippon Dynawave Longview, Sofidel Duluth
--    Domtar Ashdown, Sappi Cloquet, Sylvamo Eastover / Ticonderoga and
--    Phoenix Paper Wickliffe already exist and are reused.
-- 4) party_supply_links SMI plant -> host mill (10 pairs), batch tag
--    extra_data.batch = 'us_filler_gap_20261014'. Not-exists guarded.
--      Superior WI -> Duluth is HISTORICAL (Verso idled Duluth 2020-07,
--      now a Sofidel recycled tissue mill). Longview host = Nippon Dynawave
--      per WA Ecology (plant effluent goes to that mill), confidence medium.
--
-- Columbia River Carbonates and GLC get NO mill links: neither publishes
-- mill-level customers. Do not guess them.
--
-- MBG is a technology licensor. These rows are licensee and host-mill
-- intelligence only.
--
-- Idempotent. Last statement is a verification select (one result set).
-- No BEGIN / no DO blocks / no semicolons or bare keywords in strings.
-- Rollback (manual):
--   delete links with extra_data->>'batch' = 'us_filler_gap_20261014'
--   delete profiles + parties with source = 'us_filler_gap_20261014'
-- ============================================================

-- ---------- 1) FILLER COMPANIES ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city, address,
   website, phone_e164, status, source, notes, organization_id)
select v.party_type_id, v.entity_type_id, v.party_name, v.country_code, v.region,
       v.city, v.address, v.website, v.phone_e164, 'active', 'us_filler_gap_20261014',
       v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  (3::smallint, 1::smallint, 'Columbia River Carbonates', 'US', 'WA', 'Woodland',
   '300 North Pekin Road, Woodland, WA 98674', 'https://www.carbonates.com', '+13602256505',
   'Founded 1985. Joint venture of Omya and Bleeck Management. Ultra-fine GCC for paper, paint and plastics across the US Pacific Northwest and Western Canada. White marble quarried at Calder on Prince of Wales Island (Alaska), processed at Woodland WA. Mill-level customers not disclosed. FCC route: Omya licensing (CRC is an Omya JV). Sources: company profile, WA Ecology facility summary, 2026-10.'),
  (3::smallint, 1::smallint, 'GLC Minerals', 'US', 'WI', 'Green Bay',
   '1450 Bylsby Ave, Green Bay, WI', 'https://www.glcminerals.com', null,
   'Family business with roots in 1871, processing calcium carbonate at its Port of Green Bay dockside site since 1945. Custom GCC, dolomitic lime and gypsum for agronomy, animal feed, glass, plastics and industrial fillers. Paper is a minor market. Low FCC priority. Sources: company profile and local press, 2026-10.')
) as v(party_type_id, entity_type_id, party_name, country_code, region, city, address,
       website, phone_e164, notes)
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null
    and (lower(p.party_name) = lower(v.party_name)
         or p.party_name ilike split_part(v.party_name, ' ', 1) || ' ' || split_part(v.party_name, ' ', 2) || '%')
);

-- ---------- 2) SMI SATELLITE PLANT ROWS ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city, address,
   website, phone_e164, status, source, notes, organization_id)
select 3::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 3 and x.deleted_at is null
                   and x.party_name ilike 'Specialty Minerals (USA - %'
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'US', v.region, v.town, v.address,
       'https://www.mineralstech.com', v.phone_e164, 'active', 'us_filler_gap_20261014',
       v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('Specialty Minerals (USA - Selma AL)', 'AL', 'Selma', null, null,
   'SMI satellite PCC plant at Selma AL, listed in the MTI FY2024 10-K (Item 2). Host in earlier 10-K tables: International Paper (Riverdale mill).'),
  ('Specialty Minerals (USA - Ashdown AR)', 'AR', 'Ashdown', null, null,
   'SMI satellite PCC plant at Ashdown AR, listed in the MTI FY2024 10-K. Host in earlier 10-K tables: Domtar.'),
  ('Specialty Minerals (USA - Quinnesec MI)', 'MI', 'Quinnesec', null, null,
   'SMI satellite PCC plant at Quinnesec MI, listed in the MTI FY2024 10-K. Host chain: Champion, International Paper, Verso, now Billerud (Verso acquired 2022).'),
  ('Specialty Minerals (USA - Cloquet MN)', 'MN', 'Cloquet', null, null,
   'SMI satellite PCC plant at Cloquet MN, listed in the MTI FY2024 10-K. Host: Sappi Cloquet (earlier Potlatch).'),
  ('Specialty Minerals (USA - International Falls MN)', 'MN', 'International Falls', null, null,
   'SMI satellite PCC plant at International Falls MN, listed in the MTI FY2024 10-K. Host: Boise Paper, a PCA division (earlier Boise Cascade, Boise Inc.).'),
  ('Specialty Minerals (USA - Eastover SC)', 'SC', 'Eastover', null, null,
   'SMI satellite PCC plant at Eastover SC, listed in the MTI FY2024 10-K. Host: Sylvamo Eastover (International Paper until the 2021 spin-off).'),
  ('Specialty Minerals (USA - Longview WA)', 'WA', 'Longview', '3515 Industrial Way, Longview, WA', '+13605770912',
   'SMI satellite PCC plant at Longview WA, listed in the MTI FY2024 10-K. WA Ecology: lime plus CO2 PCC process, effluent treated by the adjacent Nippon Dynawave mill. Older 10-K tables name Weyerhaeuser and later NORPAC as host.'),
  ('Specialty Minerals (USA - Superior WI)', 'WI', 'Superior', null, null,
   'SMI PCC plant at Superior WI on a Graymont site, built 2011 to ship up to 70,000 t/yr PCC to the NewPage (later Verso) Duluth MN supercalendered mill under 10 miles away. Duluth idled 2020-07, converted to recycled tissue (ST Paper 2023, Sofidel 2024). Still listed in the MTI FY2024 10-K - current customer not disclosed.')
) as v(party_name, region, town, address, phone_e164, notes)
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null
    and p.party_name ilike 'Specialty Minerals%' || v.town || '%'
);

-- ---------- 3) FILLER PROFILES (new rows only) ----------
insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   onsite_pcc_evidence, mineral_class, industry_source, notes, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid,
       d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
       d.onsite, d.mineral_class, 'industry-research', d.notes, '{}'::jsonb, now(), now()
from app.parties p
join (values
  ('Columbia River Carbonates', 'GCC producer', 'US Pacific Northwest paper GCC merchant (Omya JV)',
   'merchant', 'C', null::text, 'gcc',
   'Ultra-fine GCC slurry and powder for paper, Woodland WA. Holds 1990s US patents on bulking and opacifying fillers for paper and board. Royalty route runs through Omya.'),
  ('GLC Minerals', 'GCC processor', 'Upper Midwest custom GCC processor - paper minor',
   'merchant', 'C', null::text, 'gcc',
   'Port of Green Bay dockside plant, about 400,000 t/yr of inbound minerals. Not a paper-filler specialist.')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, onsite, mineral_class, notes)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null
  and p.source = 'us_filler_gap_20261014'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   onsite_pcc_evidence, mineral_class, industry_source, notes, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid,
       'PCC producer', 'SMI satellite PCC plant (US)', 'satellite (on-site)', 'A',
       'Listed as a Satellite Plant, Specialty Additives, in the MTI FY2024 10-K Item 2 Properties (filed 2025-02-21).',
       'pcc', 'industry-research',
       'Plant row under Specialty Minerals (HQ). FCC conversation happens at SMI headquarters level, not per plant.',
       '{}'::jsonb, now(), now()
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null
  and p.source = 'us_filler_gap_20261014'
  and p.party_name like 'Specialty Minerals (USA - %'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 4) HOST MILLS (only when the town has no US mill row) ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null and x.country_code = 'US'
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'US', v.region, v.city, v.website, 'active', 'us_filler_gap_20261014',
       v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('International Paper - Riverdale Mill (Selma, AL)', 'AL', 'Selma', '%Riverdale%', 'https://www.internationalpaper.com',
   'Integrated mill near Selma AL. Host of the SMI Selma satellite PCC plant per MTI 10-K tables.'),
  ('Billerud - Quinnesec Mill (Quinnesec, MI)', 'MI', 'Quinnesec', '%Quinnesec%', 'https://www.billerud.com',
   'Ex-Verso mill, Billerud since 2022. Coated freesheet plus market pulp, first Tribute white kraftliner 2025. Host of the SMI Quinnesec satellite PCC plant.'),
  ('Boise Paper (PCA) - International Falls Mill (International Falls, MN)', 'MN', 'International Falls', '%International Falls%', 'https://www.boisepaper.com',
   'PCA Boise Paper division. Integrated mill, two paper machines, over 500,000 t/yr commodity and specialty uncoated papers. Host of the SMI International Falls satellite PCC plant.'),
  ('Nippon Dynawave Packaging - Longview Mill (Longview, WA)', 'WA', 'Longview', '%Dynawave%', null,
   'Nippon Paper Group mill at Longview WA, liquid packaging board. Treats the effluent of the adjacent SMI Longview PCC plant per WA Ecology.'),
  ('Sofidel - Duluth Mill (Duluth, MN)', 'MN', 'Duluth', '%Duluth%', 'https://www.sofidel.com',
   'Ex-NewPage / Verso supercalendered mill, idled 2020-07, restarted 2023 by ST Paper as a recycled tissue mill (about 65,000 t/yr), Sofidel since 2024-01. Former customer of the SMI Superior WI PCC plant - tissue grade, relevant to SMI tissue interest.')
) as v(party_name, region, city, name_like, website, notes)
where not exists (
  select 1 from app.parties m
  where m.party_type_id = 2 and m.deleted_at is null and m.country_code = 'US'
    and (m.party_name ilike v.name_like
         or (v.city <> 'Longview' and (m.city ilike v.city or m.party_name ilike '%' || v.city || '%')))
);

insert into app.paper_mill_profile
  (party_id, organization_id, main_product_category, main_products, headquarters,
   filler_use_intensity, evidence_level, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.cat, d.products, d.hq,
       d.intensity, 'B', 'industry-research', '{}'::jsonb, now(), now()
from app.parties p
join (values
  ('International Paper - Riverdale Mill (Selma, AL)', 'Printing and writing / packaging', 'Uncoated freesheet, containerboard', 'Memphis, TN', 'high'),
  ('Billerud - Quinnesec Mill (Quinnesec, MI)', 'Printing and writing / packaging', 'Coated freesheet, white kraftliner, market pulp', 'Solna, Sweden', 'high'),
  ('Boise Paper (PCA) - International Falls Mill (International Falls, MN)', 'Printing and writing', 'Uncoated freesheet office and specialty papers', 'Lake Forest, IL', 'high'),
  ('Nippon Dynawave Packaging - Longview Mill (Longview, WA)', 'Packaging', 'Liquid packaging board', 'Tokyo, Japan', 'medium'),
  ('Sofidel - Duluth Mill (Duluth, MN)', 'Tissue', 'Recycled bath tissue, towel, napkin', 'Porcari, Italy', 'low')
) as d(party_name, cat, products, hq, intensity)
  on p.party_name = d.party_name
where p.party_type_id = 2 and p.deleted_at is null
  and p.source = 'us_filler_gap_20261014'
  and not exists (select 1 from app.paper_mill_profile mp where mp.party_id = p.id);

-- ---------- 5) SUPPLY LINKS: SMI plant -> host mill ----------
insert into app.party_supply_links
  (id, organization_id, mill_party_id, filler_party_id, link_type,
   product_grade, volume_estimate, confidence, active_since, active_until,
   notes, extra_data, created_at, updated_at)
select gen_random_uuid(), 'b25de8f2-1020-482f-9012-183f63883169'::uuid,
       m.id, f.id, r.link_type, 'PCC filler-grade', r.volume, r.confidence,
       r.since, r.until,
       r.label || ' | src: MTI 10-K FY2024 Item 2 + earlier 10-K customer tables',
       jsonb_build_object(
         'evidence_url', e.evidence,
         'supply_structure', r.structure,
         'link_kind', 'pcc_satellite',
         'source', 'MTI 10-K',
         'batch', 'us_filler_gap_20261014',
         'researched_at', '2026-10-14'),
       now(), now()
from (values
  ('Selma',               '%Riverdale%',           '%International Paper%', 'active',     'medium', null::text,             null::date,          null::date,          'on-site satellite PCC', 'SMI Selma AL - IP Riverdale'),
  ('Ashdown',             '%Ashdown%',             '%Domtar%',              'active',     'high',   null::text,             null::date,          null::date,          'on-site satellite PCC', 'SMI Ashdown AR - Domtar Ashdown'),
  ('Wickliffe',           '%Wickliffe%',           '%Phoenix%',             'active',     'high',   '~35,000 t/yr',         '2019-11-01'::date,  null::date,          'on-site satellite PCC', 'SMI Wickliffe KY - Phoenix Paper'),
  ('Quinnesec',           '%Quinnesec%',           '%Billerud%',            'active',     'high',   null::text,             null::date,          null::date,          'on-site satellite PCC', 'SMI Quinnesec MI - Billerud Quinnesec'),
  ('Cloquet',             '%Cloquet%',             '%Sappi%',               'active',     'high',   null::text,             null::date,          null::date,          'on-site satellite PCC', 'SMI Cloquet MN - Sappi Cloquet'),
  ('International Falls', '%International Falls%', '%Boise%',               'active',     'high',   null::text,             null::date,          null::date,          'on-site satellite PCC', 'SMI International Falls MN - Boise Paper (PCA)'),
  ('Ticonderoga',         '%Ticonderoga%',         '%Sylvamo%',             'active',     'high',   null::text,             null::date,          null::date,          'on-site satellite PCC', 'SMI Ticonderoga NY - Sylvamo Ticonderoga'),
  ('Eastover',            '%Eastover%',            '%Sylvamo%',             'active',     'high',   null::text,             null::date,          null::date,          'on-site satellite PCC', 'SMI Eastover SC - Sylvamo Eastover'),
  ('Longview',            '%Dynawave%',            '%Dynawave%',            'active',     'medium', null::text,             null::date,          null::date,          'adjacent satellite PCC', 'SMI Longview WA - Nippon Dynawave (host per WA Ecology)'),
  ('Superior',            '%Duluth%',              '%Sofidel%',             'historical', 'medium', 'up to 70,000 t/yr',    '2011-04-01'::date,  '2020-07-01'::date,  'near-site PCC (Superior WI to Duluth MN)', 'SMI Superior WI - Duluth mill (SC paper era, Verso idled 2020)')
) as r(town, mill_like, owner_like, link_type, confidence, volume, since, until, structure, label)
cross join lateral (
  select 'https://www.sec.gov/Archives/edgar/data/891014/000089101425000018/form10k.htm'::text as evidence
) e
cross join lateral (
  select x.id from app.parties x
  where x.party_type_id = 3 and x.deleted_at is null
    and x.party_name ilike 'Specialty Minerals%' || r.town || '%'
  order by (x.party_name like 'Specialty Minerals (USA - %') desc, x.created_at
  limit 1
) f
cross join lateral (
  select y.id from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'US'
    and (y.party_name ilike r.mill_like
         or y.city ilike btrim(r.mill_like, '%')
         or (r.town not in ('Longview', 'Superior')
             and (y.city ilike r.town or y.party_name ilike '%' || r.town || '%')))
  order by (y.party_name ilike r.owner_like) desc, (y.status = 'active') desc, y.created_at
  limit 1
) m
where not exists (
  select 1 from app.party_supply_links l
  where l.mill_party_id = m.id and l.filler_party_id = f.id and l.deleted_at is null
);

-- ---------- 6) VERIFY (single result set) ----------
select 'filler' as kind, p.party_name as name, p.city as detail,
       case when p.source = 'us_filler_gap_20261014' then 'added now' else 'already there' end as status
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null
  and (p.party_name in ('Columbia River Carbonates', 'GLC Minerals')
       or (p.party_name ilike 'Specialty Minerals%'
           and (p.party_name ilike '%Selma%' or p.party_name ilike '%Ashdown%'
                or p.party_name ilike '%Quinnesec%' or p.party_name ilike '%Cloquet%'
                or p.party_name ilike '%International Falls%' or p.party_name ilike '%Eastover%'
                or p.party_name ilike '%Longview%' or p.party_name ilike '%Superior%')))
union all
select 'mill', p.party_name, p.city,
       case when p.source = 'us_filler_gap_20261014' then 'added now' else 'already there' end
from app.parties p
where p.party_type_id = 2 and p.deleted_at is null and p.source = 'us_filler_gap_20261014'
union all
select 'link', f.party_name, m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-')
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and l.extra_data->>'batch' = 'us_filler_gap_20261014'
order by 1, 2;
