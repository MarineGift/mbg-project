-- ============================================================
-- seed_20261014b_omya_us_plants.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Applies the report "US MTI / Omya / Artemyn plants for FCC" (2026-10-14).
-- Each claim was re-checked before use. Report items NOT applied:
--   - MTI customers (IP at Eastover / Ticonderoga, NORPAC at Longview,
--     Chillicothe rated high): URM already holds the newer owners
--     (Sylvamo, Nippon Dynawave) and Chillicothe as historical (closed 2025).
--   - Wickliffe 35,000 t/yr: already on the existing link.
--   - Artemyn US plants: report itself could not confirm any.
--   - $15/t royalty scenarios: analysis, not data.
--
-- 1) Omya US plant rows (filler_supplier), each only if no 'Omya%<town>%'
--    row exists. Group row 'Omya (USA)' stays as is.
--      PCC on-site at Domtar mills (listed as Omya PCC USA at the mill
--      street address): Hawesville KY, Johnsonburg PA, Kingsport TN
--      GCC: Florence VT (Verpol + East plants), Sylacauga AL,
--           Lucerne Valley CA, Superior AZ
-- 2) Profiles for the new rows.
-- 3) Domtar Hawesville mill row if missing (Johnsonburg / Kingsport exist).
-- 4) Links Omya PCC plant -> Domtar mill, batch 'us_omya_plants_20261014':
--      Hawesville  active      medium
--      Johnsonburg active      medium
--      Kingsport   historical  medium  (Domtar ended uncoated freesheet
--                  2020, mill converted to recycled containerboard)
--    GCC plants get NO mill links - customers not disclosed.
-- 5) Artemyn row: notes line appended (guarded).
--
-- MBG is a technology licensor. Omya is a royalty licensee - these rows
-- are licensee footprint and host-mill intelligence only.
--
-- Idempotent. Last statement is a verification select (one result set).
-- No BEGIN / no DO blocks / no semicolons or bare keywords in strings.
-- ============================================================

-- ---------- 1) OMYA US PLANT ROWS ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, notes, organization_id)
select 3::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 3 and x.deleted_at is null
                   and x.party_name ilike 'Specialty Minerals (USA - %'
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'US', v.region, v.town, 'https://www.omya.com', 'active',
       'us_omya_plants_20261014', v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('Omya (USA - Hawesville KY)', 'KY', 'Hawesville',
   'Omya PCC USA plant, 58 Wescor Road / Hwy 1406, Hawesville KY 42348, tel +1 270-927-1001 - the same street address as the Domtar Hawesville integrated mill, so an on-site PCC plant. Omya was hiring plant operators there in 2023. Capacity not disclosed. Sources: business listings, Omya job posting, Domtar mill page, 2026-10.'),
  ('Omya (USA - Johnsonburg PA)', 'PA', 'Johnsonburg',
   'Omya PCC USA plant, 499 Glen Avenue, Johnsonburg PA 15845, tel +1 814-965-3400, established 2007, about 20 staff. Serves the Domtar Johnsonburg uncoated freesheet mill. Capacity not disclosed. Sources: business listings, 2026-10.'),
  ('Omya (USA - Kingsport TN)', 'TN', 'Kingsport',
   'Omya PCC USA plant, 100 Clinchfield Street, Kingsport TN 37660 - the Domtar Kingsport mill address. Domtar idled Kingsport uncoated freesheet 2020-04, closed it permanently 2020-08 and converted the mill to recycled linerboard and medium. Current operation of the PCC plant unconfirmed. Sources: business listings, Domtar 10-K FY2020 and FY2021.'),
  ('Omya (USA - Florence VT)', 'VT', 'Florence',
   'Omya Verpol (West) Plant and East Plant, Florence VT - finely ground calcium carbonate, with an on-site cogeneration plant (VT DEC air permit). Marble trucked in by the Pittsford and Middlebury quarries, product shipped by rail. Long described as the largest Omya site in the US. GCC for paper, paint, plastics. Former North American HQ at Proctor VT until 2007. Mill-level customers not disclosed.'),
  ('Omya (USA - Sylacauga AL)', 'AL', 'Sylacauga',
   'Omya GCC plant and quarry at Sylacauga AL (white marble belt). Products for paper, polymers and packaging. Capacity and mill-level customers not disclosed. Source: report 2026-10-14, current paper-grade output to be confirmed.'),
  ('Omya (USA - Lucerne Valley CA)', 'CA', 'Lucerne Valley',
   'Omya Main Plant, 7299 Crystal Creek Road, Lucerne Valley CA 92356, tel +1 760-248-7306, formerly Pluess-Staufer (California). Limestone crushing, roller-mill grinding and surface treatment, air permits renewed 2025-10 (MDAQMD facility 461). Paper share not disclosed. Note: SMI also runs a Lucerne Valley plant.'),
  ('Omya (USA - Superior AZ)', 'AZ', 'Superior',
   'Omya mineral plant in Arizona, town per the 2026-10-14 report (Superior AZ). Mining and processing, paper-grade output not confirmed. Verify town and products before use.')
) as v(party_name, region, town, notes)
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null
    and p.party_name ilike 'Omya%' || v.town || '%'
);

-- ---------- 2) PROFILES (new rows only) ----------
insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   onsite_pcc_evidence, mineral_class, industry_source, notes, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid,
       d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
       d.onsite, d.mineral_class, 'industry-research',
       'Plant row under Omya (USA). FCC licensing is negotiated at Omya headquarters level, not per plant.',
       '{}'::jsonb, now(), now()
from app.parties p
join (values
  ('Omya (USA - Hawesville KY)',     'PCC producer', 'Omya on-site PCC plant (US)', 'satellite (on-site)', 'B',
   'Omya PCC USA listed at the Domtar Hawesville mill street address.', 'pcc'),
  ('Omya (USA - Johnsonburg PA)',    'PCC producer', 'Omya on-site PCC plant (US)', 'satellite (on-site)', 'B',
   'Omya PCC USA plant at Johnsonburg serving the Domtar mill.', 'pcc'),
  ('Omya (USA - Kingsport TN)',      'PCC producer', 'Omya on-site PCC plant (US) - host converted', 'satellite (on-site)', 'C',
   'Omya PCC USA listed at the Domtar Kingsport mill address. Host stopped making uncoated freesheet in 2020.', 'pcc'),
  ('Omya (USA - Florence VT)',       'GCC producer', 'Omya flagship US GCC site', 'merchant', 'B', null, 'gcc'),
  ('Omya (USA - Sylacauga AL)',      'GCC producer', 'Omya US GCC plant', 'merchant', 'C', null, 'gcc'),
  ('Omya (USA - Lucerne Valley CA)', 'GCC producer', 'Omya US GCC plant', 'merchant', 'B', null, 'gcc'),
  ('Omya (USA - Superior AZ)',       'GCC producer', 'Omya US mineral plant - paper role unconfirmed', 'merchant', 'C', null, 'gcc')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, onsite, mineral_class)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null
  and p.source = 'us_omya_plants_20261014'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 3) DOMTAR HAWESVILLE MILL (only if missing) ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null and x.country_code = 'US'
                 order by x.created_at limit 1), 1)::smallint,
       'Domtar - Hawesville Mill (Hawesville, KY)', 'US', 'KY', 'Hawesville',
       'https://www.domtar.com', 'active', 'us_omya_plants_20261014',
       'Integrated kraft pulp and fine paper mill, 58 Wescor Road, Hawesville KY, opened 1967, Domtar since 2007. Specialty and fine papers plus hardwood market pulp, about 600,000 t/yr paper. Title V permit renewed 2025-03. Host of the Omya Hawesville PCC plant.',
       'b25de8f2-1020-482f-9012-183f63883169'::uuid
where not exists (
  select 1 from app.parties m
  where m.party_type_id = 2 and m.deleted_at is null and m.country_code = 'US'
    and (m.city ilike 'Hawesville' or m.party_name ilike '%Hawesville%')
);

insert into app.paper_mill_profile
  (party_id, organization_id, main_product_category, main_products, headquarters,
   filler_use_intensity, evidence_level, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, 'Printing and writing / specialty',
       'Fine and specialty uncoated papers, hardwood market pulp', 'Fort Mill, SC',
       'high', 'B', 'industry-research', '{}'::jsonb, now(), now()
from app.parties p
where p.party_type_id = 2 and p.deleted_at is null
  and p.source = 'us_omya_plants_20261014'
  and not exists (select 1 from app.paper_mill_profile mp where mp.party_id = p.id);

-- ---------- 4) LINKS: Omya PCC plant -> Domtar mill ----------
insert into app.party_supply_links
  (id, organization_id, mill_party_id, filler_party_id, link_type,
   product_grade, volume_estimate, confidence, active_since, active_until,
   notes, extra_data, created_at, updated_at)
select gen_random_uuid(), 'b25de8f2-1020-482f-9012-183f63883169'::uuid,
       m.id, f.id, r.link_type, 'PCC filler-grade', null, 'medium',
       null, r.until,
       r.label || ' | src: business listings at the mill address + Domtar 10-K',
       jsonb_build_object(
         'supply_structure', 'on-site PCC (Omya owned and operated)',
         'link_kind', 'pcc_onsite',
         'source', 'business listings + Domtar 10-K',
         'batch', 'us_omya_plants_20261014',
         'researched_at', '2026-10-14'),
       now(), now()
from (values
  ('Hawesville',  'active',     null::date,          'Omya Hawesville KY - Domtar Hawesville'),
  ('Johnsonburg', 'active',     null::date,          'Omya Johnsonburg PA - Domtar Johnsonburg'),
  ('Kingsport',   'historical', '2020-04-01'::date,  'Omya Kingsport TN - Domtar Kingsport (UFS ended 2020)')
) as r(town, link_type, until, label)
cross join lateral (
  select x.id from app.parties x
  where x.party_type_id = 3 and x.deleted_at is null
    and x.party_name ilike 'Omya%' || r.town || '%'
  order by (x.party_name like 'Omya (USA - %') desc, x.created_at
  limit 1
) f
cross join lateral (
  select y.id from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'US'
    and (y.city ilike r.town or y.party_name ilike '%' || r.town || '%')
  order by (y.party_name ilike '%Domtar%') desc, y.created_at
  limit 1
) m
where not exists (
  select 1 from app.party_supply_links l
  where l.mill_party_id = m.id and l.filler_party_id = f.id and l.deleted_at is null
);

-- ---------- 5) ARTEMYN NOTE ----------
update app.parties p
set notes = coalesce(nullif(btrim(p.notes), '') || ' | ', '')
            || 'US check 2026-10-14: at launch (2024-07) Artemyn reported 23 industrial sites, about 1,000 staff and about USD 400M 2023 revenue (Flacks Group counts 24 plants). US legal entity Artemyn USA, LLC (a filing shows the former name Americarb, Inc.). No US plant list, capacity or mill customer is public yet - do not assume former Imerys US sites moved to Artemyn. Approach via global paper-minerals leadership.',
    updated_at = now()
where p.party_type_id = 3 and p.deleted_at is null
  and p.party_name = 'Artemyn'
  and coalesce(p.notes, '') not ilike '%Americarb%';

-- ---------- 6) VERIFY (single result set) ----------
select 'filler' as kind, p.party_name as name, p.city as detail,
       case when p.source = 'us_omya_plants_20261014' then 'added now' else 'already there' end as status
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null
  and p.party_name ilike 'Omya%'
  and (p.party_name ilike '%Hawesville%' or p.party_name ilike '%Johnsonburg%'
       or p.party_name ilike '%Kingsport%' or p.party_name ilike '%Florence%'
       or p.party_name ilike '%Sylacauga%' or p.party_name ilike '%Lucerne%'
       or p.party_name ilike '%Superior%')
union all
select 'mill', p.party_name, p.city, 'added now'
from app.parties p
where p.party_type_id = 2 and p.deleted_at is null and p.source = 'us_omya_plants_20261014'
union all
select 'link', f.party_name, m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-')
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and l.extra_data->>'batch' = 'us_omya_plants_20261014'
union all
select 'group link', f.party_name, m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-')
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and f.party_name = 'Omya (USA)'
  and (m.party_name ilike '%Hawesville%' or m.party_name ilike '%Johnsonburg%' or m.party_name ilike '%Kingsport%')
union all
select 'artemyn note', p.party_name,
       case when p.notes ilike '%Americarb%' then 'note present' else 'note missing' end, ''
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and p.party_name = 'Artemyn'
order by 1, 2;
