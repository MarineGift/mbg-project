-- ============================================================
-- seed_20261014g_china_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- China update (reports "China PCC/GCC producers" + "China paper companies",
-- 2026-10). Already in URM and NOT redone: SMI satellites at Gold East
-- (Dagang), Gold Huasheng (Suzhou), Nine Dragons Beihai, Zhefeng Quzhou,
-- Asia Symbol Rugao (GCC), and the Guangxi Huana filler row.
--
-- 1) Filler rows if missing: Omya (China), Guangxi Huarui, Guangxi Guigang
--    Huitong + profiles. Sanxin skipped (no usable detail).
-- 2) Link SMI -> Sun Paper Yanzhou, if not linked yet. Checked: MTI built a
--    100 kt coating PCC satellite (2014) and a 100 kt filling PCC satellite
--    (2015, with a FulFill high-filler technology partnership) at Sun Paper.
-- 3) Plant blocks (Mill profile card), China outreach priority 1-8:
--      1 Sun Paper Yanzhou  2 Gold East  3 Asia Symbol Shandong (Rizhao)
--      4 Nine Dragons Beihai  5 Gold Huasheng  6 Bohui  7 Wuzhou Special
--      8 Lee and Man Chongqing (tissue track)
--    plus context rows Chenming (financial risk) and Shanying (packaging).
--    FCC scenarios only where a single printing-line capacity is known:
--    Nine Dragons Beihai W and P line 400 kt, Wuzhou printing lines 300 kt.
--    Mills are matched on CN rows only - NOTHING is created. Verify lists
--    each target as matched or MISSING.
--
-- Idempotent. Last statement is a verification select.
-- ============================================================

-- ---------- 1) FILLER ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, notes, organization_id)
select 3::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 3 and x.deleted_at is null and x.country_code = 'CN'
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'CN', v.region, v.city, v.website, 'active', 'china_update_20261014',
       v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('Omya (China)', 'Omya%China%', null, null, 'https://www.omya.com', 'Omya China. 2023 plan: six new China plants - GCC in Guangxi, Guangdong and Shandong, two PCC in Shandong, one PCC in Fujian - plus one in Indonesia, about 1.0 Mt/yr in total (740 kt GCC, 260 kt PCC, China and Indonesia combined). Host mills and current running status not public. Royalty licensee at Omya HQ level.'),
  ('Guangxi Huarui New Materials', '%Huarui%', 'Guangxi', 'Hezhou', 'https://www.huaruigcc.com', 'Guangxi Huarui New Materials, founded 2018, Wanggao industrial park, Hezhou, Guangxi. Marble and calcite powder 200-3000 mesh, brightness about 92-97, surface modification and masterbatch lines - mainly plastics and coatings. Stated 1 Mt powder and masterbatch, over 3 Mt total ore handling, not paper GCC. Check for a wet paper-grade GCC line first.'),
  ('Guangxi Guigang Huitong Calcium', '%Huitong%', 'Guangxi', 'Guigang', 'https://www.chemical-huitong.com', 'Guangxi Guigang Huitong Calcium Industry, Guigang, Guangxi. PCC, GCC, nano calcium carbonate, quick and hydrated lime. Published PCC spec: CaCO3 98.67 pct, brightness 97.6, D50 about 4.9 um, pH 9.8, paper listed among uses. Dry powder - slurry supply to large mills unconfirmed.')
) as v(party_name, guard_like, region, city, website, notes)
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
);

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
       d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
from app.parties p
join (values
  ('Omya (China)', 'GCC producer', 'Omya China on-site and merchant GCC and PCC', 'satellite (on-site) + merchant', 'B', 'pcc'),
  ('Guangxi Huarui New Materials', 'GCC processor', 'Guangxi GCC powder - paper role unconfirmed', 'merchant', 'C', 'gcc'),
  ('Guangxi Guigang Huitong Calcium', 'PCC producer', 'Guangxi PCC and GCC powder', 'merchant', 'C', 'pcc')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'china_update_20261014'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 2) SMI -> SUN PAPER YANZHOU ----------
insert into app.party_supply_links
  (id, organization_id, mill_party_id, filler_party_id, link_type,
   product_grade, volume_estimate, confidence, active_since, active_until,
   notes, extra_data, created_at, updated_at)
select gen_random_uuid(), 'b25de8f2-1020-482f-9012-183f63883169'::uuid, m.id, f.id, 'active',
       'PCC coating-grade + filler-grade', '2 x 100,000 t/yr', 'high', '2014-01-01'::date, null,
       'SMI - Sun Paper Yanzhou: coating PCC satellite (2014) and filling PCC satellite (2015) with FulFill technology partnership',
       jsonb_build_object('supply_structure', 'on-site satellite PCC x2', 'link_kind', 'pcc_satellite',
                          'evidence_url', 'https://investors.mineralstech.com/node/8911',
                          'source', 'MTI releases 2013 and 2015-04-06',
                          'batch', 'china_update_20261014', 'researched_at', '2026-10-14'),
       now(), now()
from (values ('%Yanzhou%', '%Sun Paper%', '%Sun%')) as v(name_like, alt_like, owner_like)
cross join lateral (
  select y.id from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CN'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
  order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
  limit 1
) m
cross join lateral (
  select x.id from app.parties x
  where x.party_type_id = 3 and x.deleted_at is null and x.party_name ilike 'Specialty Minerals%'
  order by (x.party_name ilike '%China%') desc, (x.party_name ilike '%Yanzhou%') desc,
           (x.party_name = 'Specialty Minerals Inc.') desc, x.created_at
  limit 1
) f
where not exists (
  select 1 from app.party_supply_links l
  join app.parties lf on lf.id = l.filler_party_id
  where l.mill_party_id = m.id and l.deleted_at is null and lf.party_name ilike 'Specialty Minerals%'
);

-- ---------- 3) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (values
  ('%Yanzhou%', '%Sun Paper%', '%Sun%'),
  ('%Gold East%', '%Dagang%', '%Gold East%'),
  ('%Rizhao%', '%Asia Symbol%Shandong%', '%Asia Symbol%'),
  ('%Beihai%', '%Nine Dragons%Beihai%', '%Nine Dragons%'),
  ('%Huasheng%', '%Gold Huasheng%', '%Huasheng%'),
  ('%Bohui%', '%Bohui%', '%Bohui%'),
  ('%Wuzhou Special%', '%Wuzhou%Paper%', '%Wuzhou%'),
  ('%Lee & Man%Chongqing%', '%Lee & Man%', '%Lee & Man%'),
  ('%Chenming%', '%Chenming%', '%Chenming%'),
  ('%Shanying%', '%Shanying%', '%Shanying%')
) as v(name_like, alt_like, owner_like)
cross join lateral (
  select y.id from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CN'
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CN'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Yanzhou%', '%Sun Paper%', '%Sun%',
   $pj${"owner": "Shandong Sun Paper Industry", "priority": 1, "products": "Uncoated and coated printing papers, coated board, tissue, pulp", "grades": ["Writing and printing", "Coated fine paper", "Coated board", "Tissue"], "capacity_split": [{"label": "Shandong bases (Yanzhou HQ, Yandian, Zoucheng Honghe) - paper plus pulp", "value_t": 8000000}, {"label": "Group 2025 output, all bases", "value_t": 10954000}], "filler": [{"supplier": "Specialty Minerals (MTI)", "type": "Satellite PCC, coating grade (OPACARB A40)", "status": "100,000 t/yr, running since 2014", "basis": "MTI release 2013"}, {"supplier": "Specialty Minerals (MTI)", "type": "Satellite PCC, filling grade", "status": "100,000 t/yr for a new machine started 2015", "basis": "MTI release 2015-04-06 - third MTI project at Sun"}, {"supplier": "MTI FulFill high-filler technology", "type": "Technology partnership", "status": "Part of the 2015 agreement", "basis": "Direct competitor to the FCC pulp-saving claim"}], "pitch": "Beat FulFill on the same machine - more pulp saved at equal strength, better bulk and opacity at equal ash", "approach": "Top China account. Sun already runs MTI satellites and FulFill - show the FCC case head to head. Go through SMI as producer and licensee, with clear background IP terms.", "recent": [{"date": "2025", "text": "Eight new paper machines and three pulp lines started across Shandong and Guangxi"}], "to_collect": ["Current PCC / GCC supplier per machine - outside satellite or in-house plant", "Actual annual PCC and GCC use (t), filler versus coating pigment", "Internal pulp cost versus purchased pulp - sets the FCC saving", "Filler loading per grade and target increase", "Quality gates FCC must pass versus current filler (and versus FulFill at MTI-supplied mills)", "Who approves a mill trial - mill technical, purchasing, central R and D"], "sources": [{"label": "MTI Sun Paper releases 2013 and 2015", "url": "https://investors.mineralstech.com/node/8911"}, {"label": "Sun Paper site"}, {"label": "China Paper Association 2025 annual report (2026-05) - 141.35 Mt output, W and P 18.8 Mt"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Gold East%', '%Dagang%', '%Gold East%',
   $pj${"owner": "APP China (Gold East Paper Jiangsu)", "priority": 2, "products": "Coated papers, office paper converting, thermal and special printing papers", "grades": ["Coated printing", "Copy paper", "Thermal base"], "capacity_split": [{"label": "Coated paper capacity", "value_t": 2000000}, {"label": "2025 paper output", "value_t": 2270000}], "filler": [{"supplier": "In-house", "type": "Own GCC plant and own PCC plant", "status": "Stated on the company site", "basis": "Gold East site, APP China page"}, {"supplier": "Specialty Minerals (MTI)", "type": "Satellite PCC", "status": "Existing link in URM", "basis": "MTI 10-K tables"}], "pitch": "Run FCC in the mill's own carbonate plants - no outside producer needed for the trial", "approach": "Scope to base-sheet filler, not coating pigment. In-house plants mean the licence can sit with APP directly, check the SMI satellite terms first.", "to_collect": ["Current PCC / GCC supplier per machine - outside satellite or in-house plant", "Actual annual PCC and GCC use (t), filler versus coating pigment", "Internal pulp cost versus purchased pulp - sets the FCC saving", "Filler loading per grade and target increase", "Quality gates FCC must pass versus current filler (and versus FulFill at MTI-supplied mills)", "Who approves a mill trial - mill technical, purchasing, central R and D"], "sources": [{"label": "goldeastpaper.com, APP China"}, {"label": "China Paper Association 2025 annual report (2026-05) - 141.35 Mt output, W and P 18.8 Mt"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Rizhao%', '%Asia Symbol%Shandong%', '%Asia Symbol%',
   $pj${"owner": "Asia Symbol (RGE group)", "priority": 3, "products": "Pulp and printing and writing papers", "grades": ["Writing and printing"], "capacity_split": [{"label": "Group 2025 output (Rizhao, Xinhui, Rugao)", "value_t": 3778000}], "pitch": "Direct technical evaluation on printing-paper lines", "approach": "Integrated pulp makes the saving smaller - compare FCC cost with the mill's own pulp cost, not market pulp.", "to_collect": ["Current PCC / GCC supplier per machine - outside satellite or in-house plant", "Actual annual PCC and GCC use (t), filler versus coating pigment", "Internal pulp cost versus purchased pulp - sets the FCC saving", "Filler loading per grade and target increase", "Quality gates FCC must pass versus current filler (and versus FulFill at MTI-supplied mills)", "Who approves a mill trial - mill technical, purchasing, central R and D"], "sources": [{"label": "China Paper Association 2025 annual report (2026-05) - 141.35 Mt output, W and P 18.8 Mt"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Beihai%', '%Nine Dragons%Beihai%', '%Nine Dragons%',
   $pj${"owner": "Nine Dragons Paper (Holdings)", "priority": 4, "products": "Printing and writing paper (new line), packaging grades", "grades": ["Writing and printing"], "capacity": {"value": 400000, "unit": "metric_t", "year": "New W and P line, started after mid-2025", "source": "Nine Dragons interim report"}, "filler": [{"supplier": "Specialty Minerals (MTI)", "type": "Satellite PCC", "status": "Existing link in URM (online 2023-24)", "basis": "MTI 2023 three-satellite release"}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.75, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 0.85, "fcc_share": 0.25, "fcc_loading": 0.2}, {"label": "Expanded", "utilization": 0.9, "fcc_share": 0.5, "fcc_loading": 0.25}], "note": "Planning scenarios on the stated line capacity, not orders. FCC in sheet is not the same as pulp replaced."}, "pitch": "New machine, filler recipe still being tuned - easier to bring FCC in now", "approach": "Work through SMI. Nine Dragons group capacity over 25 Mt is mostly packaging - count only this line.", "to_collect": ["Current PCC / GCC supplier per machine - outside satellite or in-house plant", "Actual annual PCC and GCC use (t), filler versus coating pigment", "Internal pulp cost versus purchased pulp - sets the FCC saving", "Filler loading per grade and target increase", "Quality gates FCC must pass versus current filler (and versus FulFill at MTI-supplied mills)", "Who approves a mill trial - mill technical, purchasing, central R and D"], "sources": [{"label": "Nine Dragons 2025 interim report"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Huasheng%', '%Gold Huasheng%', '%Huasheng%',
   $pj${"owner": "APP China (Gold Huasheng Paper Suzhou)", "priority": 5, "products": "Office and specialty papers", "grades": ["Copy paper", "Specialty"], "pitch": "Joint evaluation grade by grade", "approach": "Pair with Gold East in one APP China approach.", "to_collect": ["Current PCC / GCC supplier per machine - outside satellite or in-house plant", "Actual annual PCC and GCC use (t), filler versus coating pigment", "Internal pulp cost versus purchased pulp - sets the FCC saving", "Filler loading per grade and target increase", "Quality gates FCC must pass versus current filler (and versus FulFill at MTI-supplied mills)", "Who approves a mill trial - mill technical, purchasing, central R and D"], "sources": [{"label": "APP China"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Bohui%', '%Bohui%', '%Bohui%',
   $pj${"owner": "Bohui Paper Group (APP China)", "priority": 6, "products": "White board and cultural papers", "grades": ["Folding boxboard", "Cultural paper"], "capacity_split": [{"label": "Group 2025 output", "value_t": 4702000}], "pitch": "FCC in the filled layers of white board", "approach": "Layer-by-layer trial - board plies differ in furnish and filler.", "to_collect": ["Current PCC / GCC supplier per machine - outside satellite or in-house plant", "Actual annual PCC and GCC use (t), filler versus coating pigment", "Internal pulp cost versus purchased pulp - sets the FCC saving", "Filler loading per grade and target increase", "Quality gates FCC must pass versus current filler (and versus FulFill at MTI-supplied mills)", "Who approves a mill trial - mill technical, purchasing, central R and D"], "sources": [{"label": "China Paper Association 2025 annual report (2026-05) - 141.35 Mt output, W and P 18.8 Mt"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Wuzhou Special%', '%Wuzhou%Paper%', '%Wuzhou%',
   $pj${"owner": "Wuzhou Special Paper", "priority": 7, "products": "Printing and publishing paper, glassine, digital transfer paper", "grades": ["Printing and publishing", "Glassine", "Transfer paper"], "capacity": {"value": 300000, "unit": "metric_t", "year": "2025 annual report - printing and publishing lines only", "source": "Wuzhou Special Paper"}, "capacity_split": [{"label": "Glassine", "value_t": 460000}, {"label": "Digital transfer paper", "value_t": 112000}, {"label": "Printing and publishing", "value_t": 300000}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.75, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 0.85, "fcc_share": 0.25, "fcc_loading": 0.2}, {"label": "Expanded", "utilization": 0.9, "fcc_share": 0.5, "fcc_loading": 0.25}], "note": "Planning scenarios on the stated line capacity, not orders. FCC in sheet is not the same as pulp replaced."}, "pitch": "Start on printing and publishing lines - glassine needs density and transparency, a separate test", "approach": "Specialty-paper test partner.", "to_collect": ["Current PCC / GCC supplier per machine - outside satellite or in-house plant", "Actual annual PCC and GCC use (t), filler versus coating pigment", "Internal pulp cost versus purchased pulp - sets the FCC saving", "Filler loading per grade and target increase", "Quality gates FCC must pass versus current filler (and versus FulFill at MTI-supplied mills)", "Who approves a mill trial - mill technical, purchasing, central R and D"], "sources": [{"label": "Wuzhou Special Paper 2025 annual report"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Lee & Man%Chongqing%', '%Lee & Man%', '%Lee & Man%',
   $pj${"owner": "Lee and Man Paper Manufacturing", "priority": 8, "products": "Packaging paper and tissue", "grades": ["Tissue", "Containerboard"], "capacity_split": [{"label": "Chongqing paper", "value_t": 900000}, {"label": "Chongqing tissue", "value_t": 550000}, {"label": "Jiangxi Jiujiang tissue", "value_t": 240000}], "pitch": "Tissue FCC program - softness, dust, tensile and absorbency matter more than ash", "approach": "Separate tissue track, using the Korean tissue trial data. Lead with Chongqing and Jiangxi tissue lines.", "to_collect": ["Current PCC / GCC supplier per machine - outside satellite or in-house plant", "Actual annual PCC and GCC use (t), filler versus coating pigment", "Internal pulp cost versus purchased pulp - sets the FCC saving", "Filler loading per grade and target increase", "Quality gates FCC must pass versus current filler (and versus FulFill at MTI-supplied mills)", "Who approves a mill trial - mill technical, purchasing, central R and D"], "sources": [{"label": "Lee and Man 2025 annual report"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Chenming%', '%Chenming%', '%Chenming%',
   $pj${"owner": "Shandong Chenming Paper", "products": "Printing papers and white board", "capacity_split": [{"label": "2025 paper output", "value_t": 1090000}], "approach": "Hold until finances recover - 2025 net loss about RMB 8.3bn, mills restarted in stages (Shouguang, Jiangxi, Jilin 2025, Zhanjiang 2026-03). Trial cost and royalty payment risk.", "recent": [{"date": "2026-03", "text": "Zhanjiang mill restarted after a long stoppage"}], "sources": [{"label": "Chenming 2025 annual report"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Shanying%', '%Shanying%', '%Shanying%',
   $pj${"owner": "Shanying International", "products": "Recycled containerboard and industrial packaging", "capacity_split": [{"label": "2025 paper output", "value_t": 7545000}], "approach": "Long-term only - recycled fibre makes the virgin-pulp saving small. Possible later case in high-strength liner.", "checked_at": "2026-10-14"}$pj$::jsonb)
  ) as v(name_like, alt_like, owner_like, plant)
) m
where mp.party_id = m.id;

-- ---------- 4) VERIFY ----------
with v(name_like, alt_like, owner_like) as (values
  ('%Yanzhou%', '%Sun Paper%', '%Sun%'),
  ('%Gold East%', '%Dagang%', '%Gold East%'),
  ('%Rizhao%', '%Asia Symbol%Shandong%', '%Asia Symbol%'),
  ('%Beihai%', '%Nine Dragons%Beihai%', '%Nine Dragons%'),
  ('%Huasheng%', '%Gold Huasheng%', '%Huasheng%'),
  ('%Bohui%', '%Bohui%', '%Bohui%'),
  ('%Wuzhou Special%', '%Wuzhou%Paper%', '%Wuzhou%'),
  ('%Lee & Man%Chongqing%', '%Lee & Man%', '%Lee & Man%'),
  ('%Chenming%', '%Chenming%', '%Chenming%'),
  ('%Shanying%', '%Shanying%', '%Shanying%')
)
select 'mill' as kind, coalesce(m.party_name, 'MISSING ' || v.name_like) as name,
       coalesce(mp.extra_data #>> '{plant,owner}', '-') as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as detail
from v
left join lateral (
  select y.id, y.party_name from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CN'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
  order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
  limit 1
) m on true
left join app.paper_mill_profile mp on mp.party_id = m.id
union all
select 'filler', p.party_name,
       case when p.source = 'china_update_20261014' then 'added now' else 'already there' end, '-'
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null
  and (p.party_name ilike 'Omya%China%' or p.party_name ilike '%Huarui%' or p.party_name ilike '%Huitong%')
union all
select 'smi link', f.party_name || ' -> ' || m.party_name, l.link_type,
       coalesce(l.extra_data->>'batch', 'earlier batch')
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and f.party_name ilike 'Specialty Minerals%'
  and m.country_code = 'CN' and (m.party_name ilike '%Sun Paper%' or m.party_name ilike '%Yanzhou%')
order by 1, 4, 2;
