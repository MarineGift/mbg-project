-- ============================================================
-- seed_20261014n_korea_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Korea update (reports "Korea PCC/GCC producers" + "Korea paper
-- companies", 2026-10). Already in URM: Omya Korea Inc., Taekyung Industry,
-- Taekyung BK, GMC, Hansol mills, Moorim, Kleannara, Hankuk Paper, and the
-- Taekyung BK -> Hansol Janghang PCC link (recorded 2026-07 from an internal
-- note only).
--
-- 1) Taekyung BK -> Hansol Janghang link CONFIRMED by a filing: Janghang PCC
--    slurry plant made 52,210 t in 2025 (quarterly report 2026-05-15).
--    volume and confidence high written, caveat replaced.
-- 2) Filler row Omya Hankook Chemical (Omya-Hankuk Paper PCC JV, Onsan) if
--    missing, and link -> Hankuk Paper Onsan, active / medium.
-- 3) Notes appended (guarded) on Omya Korea, Taekyung Industry, Taekyung BK,
--    GMC - plants and capacities by filing.
-- 4) Mill rows if missing: Moorim Paper Jinju, Moorim P&P Ulsan, Moorim SP,
--    Hankuk Paper Onsan and Hyunpung, Kleannara, Samjung Pulp.
-- 5) Plant blocks, Korea priority:
--      1 Moorim Jinju and Moorim P&P Ulsan (ACTIVE MBG account, 9,000 t/yr
--        program, 3-party NDA with Omya)  2 Hansol Janghang  3 Hankuk Onsan
--      4 Hansol Cheonan  5 Hansol Shintanjin  6 Moorim SP  7 Kleannara
--      8 Samjung Pulp
--    context: Hankuk Hyunpung, Hansol Daejeon, Asia Paper, Shindaeyang,
--    Jeonju Paper, Taerim.
--    FCC scenarios on Moorim Jinju (361,590 t), Moorim P&P (479,350 t) and
--    Hankuk Onsan (600,000 t).
--
-- Idempotent. Last statement is a verification select.
-- ============================================================

-- ---------- 1) TAEKYUNG BK -> HANSOL JANGHANG: CONFIRMED ----------
update app.party_supply_links l
set volume_estimate = '52,210 t (2025 output, Janghang PCC slurry plant)',
    confidence = 'high',
    notes = coalesce(nullif(btrim(l.notes), '') || ' | ', '')
            || 'Confirmed 2026-10-14: Taekyung Industry consolidated quarterly report 2026-05-15 lists the Janghang PCC slurry plant - 52,210 t in 2025, utilization 97.1 pct in 2026 Q1.',
    extra_data = coalesce(l.extra_data, '{}'::jsonb) || jsonb_build_object(
                   'caveat', 'Confirmed by filing 2026-05-15 (Janghang PCC slurry plant output).',
                   'source_type', 'filing', 'confirmed_batch', 'korea_update_20261014'),
    updated_at = now()
where l.deleted_at is null
  and l.filler_party_id in (select f.id from app.parties f
                            where f.party_type_id = 3 and f.deleted_at is null and f.party_name ilike 'Taekyung BK%')
  and l.mill_party_id in (select m.id from app.parties m
                          where m.party_type_id = 2 and m.deleted_at is null and m.country_code = 'KR'
                            and m.party_name ilike '%Janghang%')
  and coalesce(l.extra_data ->> 'confirmed_batch', '') <> 'korea_update_20261014';

-- ---------- 2) OMYA HANKOOK CHEMICAL + LINK ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, notes, organization_id)
select 3::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 3 and x.deleted_at is null and x.country_code = 'KR'
                 order by x.created_at limit 1), 1)::smallint,
       'Omya Hankook Chemical (Onsan)', 'KR', 'Ulsan', 'Ulsan', 'https://www.omya.com', 'active', 'korea_update_20261014',
       'Omya Hankook Chemical - joint venture set up 2004-12 by Omya Korea (51 pct at founding, KRW 2.5bn capital) and Hankuk Paper to make paper PCC. Plant 40 Wonsan-ro, Onsan-eup, Ulju-gun, Ulsan, next to the Hankuk Paper Onsan mill, PCC slurry by pipeline (satellite). Current capacity and volumes not public.', 'b25de8f2-1020-482f-9012-183f63883169'::uuid
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null
    and (p.party_name ilike '%Hankook Chemical%' or p.party_name ilike '%Omya Hankook%')
);

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   onsite_pcc_evidence, mineral_class, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, 'PCC producer', 'Omya-Hankuk Paper PCC JV at Onsan', 'satellite (on-site)', 'B',
       'Satellite next to Hankuk Paper Onsan, pipeline supply (2004 press release).', 'pcc',
       'industry-research', '{}'::jsonb, now(), now()
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'korea_update_20261014'
  and p.party_name = 'Omya Hankook Chemical (Onsan)'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 3) FILLER NOTES ----------
update app.parties p
set notes = coalesce(nullif(btrim(p.notes), '') || ' | ', '') || 'KR check 2026-10-14: five Korean plants (Gunsan, Andong, Jeongseon, Jecheon, Onsan) and five quarries, over 1.2 Mt/yr calcium carbonate in total (dry plus slurry, not paper-only). Onsan hosts the Omya Hankook Chemical PCC JV with Hankuk Paper (2004). 2001 press named Hansol, Hankuk and Shin Moorim as main paper customers, paper about 70 pct of output then. KFTC 2017: paper GCC market about KRW 112.1bn, three suppliers Omya Korea, Taekyung Industry, GMC.',
    updated_at = now()
where p.party_type_id = 3 and p.deleted_at is null and p.country_code = 'KR'
  and p.party_name ilike 'Omya Korea%'
  and coalesce(p.notes, '') not ilike '%KR check 2026-10-14%';

update app.parties p
set notes = coalesce(nullif(btrim(p.notes), '') || ' | ', '') || 'KR check 2026-10-14: GCC capacity 545,220 t/yr per 2025 business report (filed 2026-03-23) - Gwangyang 144,000, Goesan 179,220, Onsan 222,000. Paper share not disclosed. One of three Korean paper GCC slurry suppliers (KFTC).',
    updated_at = now()
where p.party_type_id = 3 and p.deleted_at is null and p.country_code = 'KR'
  and p.party_name ilike 'Taekyung Industry%'
  and coalesce(p.notes, '') not ilike '%KR check 2026-10-14%';

update app.parties p
set notes = coalesce(nullif(btrim(p.notes), '') || ' | ', '') || 'KR check 2026-10-14: PCC output 2025 - Danyang 2 plant 10,393 t (dry PCC), Janghang plant 52,210 t (PCC slurry, 2026 Q1 utilization 97.1 pct), per Taekyung Industry consolidated quarterly report 2026-05-15. Janghang slurry plant serves the Hansol Janghang mill.',
    updated_at = now()
where p.party_type_id = 3 and p.deleted_at is null and p.country_code = 'KR'
  and p.party_name ilike 'Taekyung BK%'
  and coalesce(p.notes, '') not ilike '%KR check 2026-10-14%';

update app.parties p
set notes = coalesce(nullif(btrim(p.notes), '') || ' | ', '') || 'KR check 2026-10-14: founded 2007, paper GCC slurry - Jincheon plant (331 Munsa-ro, Jincheon-eup, Chungbuk, tel 043-537-6601), an Ulsan site and the Baekun limestone mine in Samcheok. 2011 history: 240,000 t/yr GCC sales system (historical figure). Entered the paper GCC slurry market 2010 (KFTC).',
    updated_at = now()
where p.party_type_id = 3 and p.deleted_at is null and p.country_code = 'KR'
  and p.party_name ilike 'GMC Co%'
  and coalesce(p.notes, '') not ilike '%KR check 2026-10-14%';

-- ---------- 4) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null and x.country_code = 'KR'
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'KR', v.region, v.city, v.website, 'active', 'korea_update_20261014', v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('%Jinju%', '%Moorim Paper%', 'Moorim Paper - Jinju Mill (Jinju)', 'Gyeongnam', 'Jinju', 'http://www.moorimpaper.co.kr', 'Moorim Paper printing paper mill at Jinju - woodfree and art paper.'),
  ('%Moorim P&P%', '%Moorim%Ulsan%', 'Moorim P&P - Ulsan Mill (Ulsan)', 'Ulsan', 'Ulsan', 'http://www.moorimpnp.co.kr', 'Moorim P&P integrated hardwood BKP and printing paper mill at Onsan, Ulsan.'),
  ('%Hankuk Paper%Onsan%', '%Hankuk Paper%', 'Hankuk Paper - Onsan Mill (Ulsan)', 'Ulsan', 'Ulsan', 'https://www.hankukpaper.com', 'Hankuk Paper printing paper mill at Onsan, Ulsan - miilk copy paper.'),
  ('%Moorim SP%', '%Moorim%Daegu%', 'Moorim SP - Daegu Mill (Daegu)', 'Daegu', 'Daegu', null, 'Moorim SP specialty paper mill, 205 Chimsan-ro, Buk-gu, Daegu - woodfree, art, CCP and specialty papers.'),
  ('%Kleannara%', '%Kleannara%', 'Kleannara - Cheongju Mill (Cheongju)', 'Chungbuk', 'Cheongju', 'https://www.kleannara.co.kr', 'Kleannara tissue and white board mill, Cheongju.'),
  ('%Samjung Pulp%', '%Samjung%', 'Samjung Pulp (Cheonan)', 'Chungnam', 'Cheonan', null, 'Samjung Pulp tissue maker - Cheonan and Haman sites, Pyeongtaek lines stopped 2025-12.'),
  ('%Hankuk%Hyunpung%', '%Hyeonpung%', 'Hankuk Paper - Hyunpung Mill (Daegu)', 'Daegu', 'Daegu', null, 'Hankuk Paper white board mill at Hyunpung, Daegu.')
) as v(name_like, alt_like, party_name, region, city, website, notes)
where not exists (
  select 1 from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'KR'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
);

-- link: Omya Hankook Chemical -> Hankuk Paper Onsan
insert into app.party_supply_links
  (id, organization_id, mill_party_id, filler_party_id, link_type,
   product_grade, volume_estimate, confidence, active_since, active_until,
   notes, extra_data, created_at, updated_at)
select gen_random_uuid(), 'b25de8f2-1020-482f-9012-183f63883169'::uuid, m.id, f.id, 'active', 'PCC filler-grade', null, 'medium', null, null,
       'Omya Hankook Chemical - Hankuk Paper Onsan: satellite PCC by pipeline (JV 2004-12) | src: Newswire 2004',
       jsonb_build_object('supply_structure', 'on-site satellite PCC (JV)', 'link_kind', 'pcc_satellite',
                          'source', 'Newswire 2004-12', 'batch', 'korea_update_20261014', 'researched_at', '2026-10-14'),
       now(), now()
from (values ('%Hankuk Paper%Onsan%', '%Hankuk Paper%', '%Hankuk%')) as v(name_like, alt_like, owner_like)
cross join lateral (
  select y.id from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'KR'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
  order by (y.party_name ilike v.name_like) desc, y.created_at
  limit 1
) m
cross join lateral (
  select x.id from app.parties x
  where x.party_type_id = 3 and x.deleted_at is null
    and (x.party_name ilike '%Hankook Chemical%' or x.party_name ilike '%Omya Hankook%')
  order by x.created_at limit 1
) f
where not exists (
  select 1 from app.party_supply_links l
  where l.mill_party_id = m.id and l.filler_party_id = f.id and l.deleted_at is null
);

-- ---------- 5) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (values
  ('%Jinju%', '%Moorim Paper%', '%Moorim%'),
  ('%Moorim P&P%', '%Moorim%Ulsan%', '%Moorim%'),
  ('%Janghang%', '%Hansol%Janghang%', '%Hansol%'),
  ('%Hankuk Paper%Onsan%', '%Hankuk Paper%', '%Hankuk%'),
  ('%Hansol%Cheonan%', '%Hansol%Cheonan%', '%Hansol%'),
  ('%Shintanjin%', '%Sintanjin%', '%Hansol%'),
  ('%Moorim SP%', '%Moorim%Daegu%', '%Moorim SP%'),
  ('%Kleannara%', '%Kleannara%', '%Kleannara%'),
  ('%Samjung Pulp%', '%Samjung%', '%Samjung%'),
  ('%Hankuk%Hyunpung%', '%Hyeonpung%', '%Hankuk%'),
  ('%Hansol%Daejeon%', '%Hansol%Daejeon%', '%Hansol%'),
  ('%Asia Paper%', '%Asia Paper%', '%Asia Paper%'),
  ('%Shindaeyang%', '%Shin Dae Yang%', '%Shindaeyang%'),
  ('%Jeonju Paper%', '%Jeonju Paper%', '%Jeonju%'),
  ('%Taerim%', '%Taerim Paper%', '%Taerim%')
) as v(name_like, alt_like, owner_like)
cross join lateral (
  select y.id from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'KR'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
  order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'KR'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Jinju%', '%Moorim Paper%', '%Moorim%',
   $pj${"owner": "Moorim group - Moorim Paper", "priority": 1, "products": "Woodfree (uncoated) and art (coated) printing papers", "grades": ["Woodfree", "Art paper"], "capacity": {"value": 361590, "unit": "metric_t", "year": "2025 business report", "source": "Moorim Paper"}, "filler": [{"supplier": "Omya Korea", "type": "GCC / PCC supply", "status": "MBG FCC program partner", "basis": "MBG 3-party NDA"}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.75, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 0.85, "fcc_share": 0.25, "fcc_loading": 0.2}, {"label": "Expanded", "utilization": 0.9, "fcc_share": 0.5, "fcc_loading": 0.25}], "note": "Planning scenarios on nameplate paper capacity, not orders. FCC in sheet is not the same as pulp replaced."}, "pitch": "Scale the 9,000 t program to more machines and grades", "approach": "Active MBG account - 3-party NDA (MBG, Omya, Moorim), 9,000 t/yr commercial program with Omya as producer. Grow inside Moorim first: other machines and grades. Confirm which mill and machine run the program.", "recent": [{"date": "2025", "text": "Moorim Paper and Moorim P&P together about 39.1 pct of the Korean printing-paper market (company basis)"}], "to_collect": ["Current PCC / GCC supplier per machine and contract term", "Actual filler use (t/yr) and slurry solids", "Filler loading per grade and target increase", "Quality gates - opacity, brightness, tensile, stiffness, retention, drainage", "Who approves a machine trial"], "sources": [{"label": "Moorim Paper 2025 business report (KIND)"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Moorim P&P%', '%Moorim%Ulsan%', '%Moorim%',
   $pj${"owner": "Moorim group - Moorim P&P", "priority": 1, "products": "Woodfree and art papers, bleached hardwood kraft pulp (only Korean BHKP maker)", "grades": ["Woodfree", "Art paper"], "capacity": {"value": 479350, "unit": "metric_t", "year": "2025 business report - paper", "source": "Moorim P&P"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.75, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 0.85, "fcc_share": 0.25, "fcc_loading": 0.2}, {"label": "Expanded", "utilization": 0.9, "fcc_share": 0.5, "fcc_loading": 0.25}], "note": "Planning scenarios on nameplate paper capacity, not orders. FCC in sheet is not the same as pulp replaced."}, "pitch": "Second Moorim mill for FCC once the program is proven - compare with internal pulp cost", "approach": "Active MBG account - 3-party NDA (MBG, Omya, Moorim), 9,000 t/yr commercial program with Omya as producer. Grow inside Moorim first: other machines and grades. Confirm which mill and machine run the program. Own BHKP means the saving is set against internal pulp cost, not market pulp.", "to_collect": ["Current PCC / GCC supplier per machine and contract term", "Actual filler use (t/yr) and slurry solids", "Filler loading per grade and target increase", "Quality gates - opacity, brightness, tensile, stiffness, retention, drainage", "Who approves a machine trial"], "sources": [{"label": "Moorim P&P 2025 business report (KIND)"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Janghang%', '%Hansol%Janghang%', '%Hansol%',
   $pj${"owner": "Hansol Paper", "priority": 2, "products": "Printing and specialty papers", "grades": ["Woodfree", "Thermal", "Specialty"], "capacity_split": [{"label": "Hansol group printing and specialty (2025)", "value_t": 866000}, {"label": "Hansol group industrial paper (2025)", "value_t": 719000}], "filler": [{"supplier": "Taekyung BK", "type": "On-site PCC slurry plant (Janghang)", "status": "2025 output 52,210 t, 2026 Q1 utilization 97.1 pct", "basis": "Taekyung Industry consolidated quarterly report 2026-05-15"}], "pitch": "FCC in thermal, label base, copy and specialty grades - pulp saving plus smoothness and opacity", "approach": "Taekyung BK already makes PCC slurry on site - test whether FCC can run on that slurry plant. Check existing MBG NDA scope before sharing with a second filler maker. 2025 utilization 96.3 pct.", "to_collect": ["Current PCC / GCC supplier per machine and contract term", "Actual filler use (t/yr) and slurry solids", "Filler loading per grade and target increase", "Quality gates - opacity, brightness, tensile, stiffness, retention, drainage", "Who approves a machine trial"], "sources": [{"label": "Hansol Paper 2025 business report"}, {"label": "Taekyung Industry quarterly report 2026-05"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Hankuk Paper%Onsan%', '%Hankuk Paper%', '%Hankuk%',
   $pj${"owner": "Hankuk Paper", "priority": 3, "products": "Copy paper (miilk), printing papers, specialty", "grades": ["Copy paper", "Woodfree"], "capacity": {"value": 600000, "unit": "metric_t", "year": "Company careers page - Onsan", "source": "Hankuk Paper"}, "filler": [{"supplier": "Omya Hankook Chemical (Omya 51 pct JV, 2004)", "type": "Satellite PCC next to the mill, pipeline supply", "status": "JV set up 2004-12 - current volumes to confirm", "basis": "2004 press release"}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.75, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 0.85, "fcc_share": 0.25, "fcc_loading": 0.2}, {"label": "Expanded", "utilization": 0.9, "fcc_share": 0.5, "fcc_loading": 0.25}], "note": "Planning scenarios on nameplate paper capacity, not orders. FCC in sheet is not the same as pulp replaced."}, "pitch": "Copy and woodfree paper - FCC through the existing Omya satellite next door", "approach": "Omya route - same producer as the Moorim program. Ask current PCC grade, use and GCC blend.", "to_collect": ["Current PCC / GCC supplier per machine and contract term", "Actual filler use (t/yr) and slurry solids", "Filler loading per grade and target increase", "Quality gates - opacity, brightness, tensile, stiffness, retention, drainage", "Who approves a machine trial"], "sources": [{"label": "Newswire 2004-12 (Omya-Hankuk JV)"}, {"label": "Hankuk Paper careers page"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Hansol%Cheonan%', '%Hansol%Cheonan%', '%Hansol%',
   $pj${"owner": "Hansol Paper", "priority": 4, "products": "Printing and specialty papers", "approach": "After Janghang. 2025 utilization 96.9 pct.", "to_collect": ["Current PCC / GCC supplier per machine and contract term", "Actual filler use (t/yr) and slurry solids", "Filler loading per grade and target increase", "Quality gates - opacity, brightness, tensile, stiffness, retention, drainage", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Shintanjin%', '%Sintanjin%', '%Hansol%',
   $pj${"owner": "Hansol Paper", "priority": 5, "products": "Printing and specialty papers", "approach": "After Janghang. 2025 utilization 95.5 pct.", "to_collect": ["Current PCC / GCC supplier per machine and contract term", "Actual filler use (t/yr) and slurry solids", "Filler loading per grade and target increase", "Quality gates - opacity, brightness, tensile, stiffness, retention, drainage", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Moorim SP%', '%Moorim%Daegu%', '%Moorim SP%',
   $pj${"owner": "Moorim group - Moorim SP", "priority": 6, "products": "Specialty, information and fancy papers, woodfree, art, CCP", "grades": ["Specialty", "CCP", "Fancy paper"], "pitch": "Value-add - opacity, smoothness, stiffness gains in specialty grades", "approach": "Inside the Moorim group - natural next step after the main program. 2025 consolidated revenue about KRW 205.7bn.", "to_collect": ["Current PCC / GCC supplier per machine and contract term", "Actual filler use (t/yr) and slurry solids", "Filler loading per grade and target increase", "Quality gates - opacity, brightness, tensile, stiffness, retention, drainage", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Kleannara%', '%Kleannara%', '%Kleannara%',
   $pj${"owner": "Kleannara", "priority": 7, "products": "Toilet and facial tissue, white board", "grades": ["Tissue", "White board"], "pitch": "Two tracks - board (ply strength, smoothness, bulk) and tissue (softness, absorbency, dust)", "approach": "Link MBG tissue data to Korean KS / ISO test methods.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile and dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Samjung Pulp%', '%Samjung%', '%Samjung%',
   $pj${"owner": "Samjung Pulp", "priority": 8, "products": "Toilet tissue and hygiene papers", "approach": "Tissue track. Do not count the Pyeongtaek capacity.", "recent": [{"date": "2025-12", "text": "Pyeongtaek base-paper and finished-goods lines stopped"}], "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile and dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Hankuk%Hyunpung%', '%Hyeonpung%', '%Hankuk%',
   $pj${"owner": "Hankuk Paper", "products": "White board", "capacity_split": [{"label": "Company careers page", "value_t": 220000}], "approach": "Board plies need their own trial.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Hansol%Daejeon%', '%Hansol%Daejeon%', '%Hansol%',
   $pj${"owner": "Hansol Paper", "products": "Industrial paper", "approach": "Depends on grade. 2025 utilization 98.2 pct.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Asia Paper%', '%Asia Paper%', '%Asia Paper%',
   $pj${"owner": "Asia Paper", "products": "Containerboard and industrial paper", "capacity_split": [{"label": "Sejong", "value_t": 594000}, {"label": "Sihwa", "value_t": 363000}, {"label": "Gyeongsan Paper (affiliate)", "value_t": 281000}], "approach": "Recycled containerboard - test strength (RCT, SCT, burst) first.", "to_collect": ["Current filler use, if any", "RCT, SCT and burst specs", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Shindaeyang%', '%Shin Dae Yang%', '%Shindaeyang%',
   $pj${"owner": "Shindaeyang Paper", "products": "Liner and corrugating medium", "capacity_split": [{"label": "Sihwa 2025 output", "value_t": 410999}, {"label": "Banwol 2025 output", "value_t": 241594}], "approach": "Strength-critical - RCT, SCT and burst decide it. Korea containerboard 2025 output 5,642,958 t.", "to_collect": ["Current filler use, if any", "RCT, SCT and burst specs", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Jeonju Paper%', '%Jeonju Paper%', '%Jeonju%',
   $pj${"owner": "Jeonju Paper (Global Sae-A group since 2024-05)", "products": "Newsprint and containerboard, only Korean TMP line", "approach": "Test newsprint and containerboard separately. Group ties to Taerim Paper and Taerim Packaging.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Taerim%', '%Taerim Paper%', '%Taerim%',
   $pj${"owner": "Taerim Paper (Global Sae-A group)", "products": "Industrial paper and containerboard", "approach": "Conditional - strength tests first.", "checked_at": "2026-10-14"}$pj$::jsonb)
  ) as v(name_like, alt_like, owner_like, plant)
) m
where mp.party_id = m.id;

-- ---------- 6) VERIFY ----------
with v(name_like, alt_like, owner_like) as (values
  ('%Jinju%', '%Moorim Paper%', '%Moorim%'),
  ('%Moorim P&P%', '%Moorim%Ulsan%', '%Moorim%'),
  ('%Janghang%', '%Hansol%Janghang%', '%Hansol%'),
  ('%Hankuk Paper%Onsan%', '%Hankuk Paper%', '%Hankuk%'),
  ('%Hansol%Cheonan%', '%Hansol%Cheonan%', '%Hansol%'),
  ('%Shintanjin%', '%Sintanjin%', '%Hansol%'),
  ('%Moorim SP%', '%Moorim%Daegu%', '%Moorim SP%'),
  ('%Kleannara%', '%Kleannara%', '%Kleannara%'),
  ('%Samjung Pulp%', '%Samjung%', '%Samjung%'),
  ('%Hankuk%Hyunpung%', '%Hyeonpung%', '%Hankuk%'),
  ('%Hansol%Daejeon%', '%Hansol%Daejeon%', '%Hansol%'),
  ('%Asia Paper%', '%Asia Paper%', '%Asia Paper%'),
  ('%Shindaeyang%', '%Shin Dae Yang%', '%Shindaeyang%'),
  ('%Jeonju Paper%', '%Jeonju Paper%', '%Jeonju%'),
  ('%Taerim%', '%Taerim Paper%', '%Taerim%')
)
select 'mill' as kind, coalesce(m.party_name, 'MISSING ' || v.name_like) as name,
       case when m.source = 'korea_update_20261014' then 'added now' when m.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as detail
from v
left join lateral (
  select y.id, y.party_name, y.source from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'KR'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
  order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
  limit 1
) m on true
left join app.paper_mill_profile mp on mp.party_id = m.id
union all
select 'filler', p.party_name,
       case when p.source = 'korea_update_20261014' then 'added now' else 'already there' end,
       case when p.notes ilike '%KR check 2026-10-14%' then 'note added' else '-' end
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and p.country_code = 'KR'
  and (p.party_name ilike 'Omya Korea%' or p.party_name ilike 'Taekyung%' or p.party_name ilike 'GMC Co%'
       or p.party_name ilike '%Hankook Chemical%' or p.party_name ilike '%Omya Hankook%')
union all
select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'),
       coalesce(l.volume_estimate, '-')
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and m.country_code = 'KR'
  and ((f.party_name ilike 'Taekyung BK%' and m.party_name ilike '%Janghang%')
       or f.party_name ilike '%Hankook Chemical%' or f.party_name ilike '%Omya Hankook%')
order by 1, 4, 2;
