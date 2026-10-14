-- ============================================================
-- seed_20261014p_taiwan_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Taiwan update (reports "Taiwan PCC/GCC producers" + "Taiwan paper
-- companies", 2026-10). Already in URM: YFY, Longchen, Cheng Loong group.
--
-- 1) Filler rows if missing + profiles: Lih Hsiang, Diamond Quantum
--    (DIACAL), An Jung Minerals, Chu Shin (APEX), Tai Yang Industry.
--    Yuncheng Chemical NOT added - stopped all calcium carbonate output
--    2026-07-31 (noted on Diamond Quantum, which supplies its customers).
--    Omya / MTI / Artemyn: no Taiwan paper plant found - nothing added.
-- 2) Mill rows if missing: Chung Hwa Pulp Chiutang, Hualien, Taitung,
--    Cheng Loong Chupei, YFY Qingshui tissue, Jih Sun, Kuan Yuan.
-- 3) Plant blocks, Taiwan priority 1-8:
--      1 CHP Chiutang  2 CHP Hualien  3 CHP Taitung  4 Cheng Loong Chupei
--      5 YFY Qingshui tissue  6 Jih Sun  7 Kuan Yuan  8 Longchen Erlin
--    context: Taiwan Scott, Cheng Loong Tayuan and Houli, Hsing Chung.
--    No capacities public per mill - no FCC scenarios. No supply links -
--    no mill-filler pair is publicly confirmed.
--
-- Idempotent. Last statement is a verification select.
-- ============================================================

-- ---------- 1) FILLER ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, notes, organization_id)
select 3::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 3 and x.deleted_at is null and x.country_code = 'TW'
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'TW', v.region, v.city, v.website, 'active', 'taiwan_update_20261014', v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('Lih Hsiang Industrial', '%Lih Hsiang%', 'Taipei', 'Taipei', 'https://www.lihhsiang.com', 'Founded 1966 - PCC, GCC and surface-treated calcium carbonate, paper named among markets. Grinding and classifying with Maruo Calcium (Japan), later European technology, output raised 12,000 to 18,000 t/month (about 216,000 t/yr, historical). Office 8F-4, 130 Zhongxiao E. Rd Sec 2, Taipei, +886-2-2321-2021, ugen@lihhsiang.com.tw (per report). Paper customers, slurry plant and mill site to confirm.'),
  ('Diamond Quantum Biotech (DIACAL)', '%Diamond Quantum%', 'Taichung', 'Dadu', 'https://www.diacal.com.tw', 'DIACAL-LIGHT PCC for paper filling and coating (CaCO3 98 pct+, brightness 96 pct+, pH 9.3-10.0) and colloidal calcium carbonate. 1 Wangfu St, Dadu, Taichung. Yuncheng Chemical stopped all calcium carbonate production on 2026-07-31 and arranged for Diamond Quantum to make equivalent grades for its customers - share of customers and added capacity not public. Contact per report: Ms. Leona Chao, +886-4-2693-2811 ext 14, service@diacal.com.tw.'),
  ('An Jung Minerals', '%An Jung%', 'Yilan', 'Dongshan', 'https://www.anjungmineral.com', 'Taiwan marble calcium carbonate, ultrafine grinding, paper among served industries. 69 Dexing 1st Rd, Dongshan, Yilan, +886-3-990-1142. About 150,000 t/yr PCC, GCC and activated carbonate around 2003 (Roskill, historical). Current paper supply to confirm.'),
  ('Chu Shin Chemical (APEX)', '%Chu Shin%', 'Hsinchu', 'Hsinchu', 'https://www.chu-shin.com', 'APEX brand, founded 1974 - PCC, nano PCC, GCC, ultrafine GCC, activated carbonate, lime. 3, Lane 67, Sec 6, Zhonghua Rd, Hsinchu, +886-3-537-2126 ext 238. States 250,000 t/yr (all products and sites). Uses a DRY GCC process and itself notes paper GCC is usually wet ground. OEM service, own logistics, APEX-VN plant in Vietnam.'),
  ('Tai Yang Industry', '%Tai Yang Industry%', null, null, null, 'PCC technology developer with ITRI - high-purity PCC (98 pct+) by calcining and carbonating oyster shell, crystal shape and size control 0.5-10 um, spherical and hollow carbonate research. R and D partner candidate, no paper-scale supply.')
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
  ('Lih Hsiang Industrial', 'PCC producer', 'Taiwan PCC and GCC, paper market - FCC partner priority 1', 'merchant', 'B', 'pcc'),
  ('Diamond Quantum Biotech (DIACAL)', 'PCC producer', 'Taiwan paper PCC - takes over Yuncheng customers 2026', 'merchant', 'B', 'pcc'),
  ('An Jung Minerals', 'GCC producer', 'Yilan marble GCC with paper history', 'merchant', 'C', 'gcc'),
  ('Chu Shin Chemical (APEX)', 'PCC producer', 'Taiwan PCC and dry GCC - OEM, Vietnam reach', 'merchant', 'C', 'pcc'),
  ('Tai Yang Industry', 'PCC producer', 'Oyster-shell PCC technology - R and D partner', 'merchant', 'C', 'pcc')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'taiwan_update_20261014'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 2) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null and x.country_code = 'TW'
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'TW', v.region, v.city, v.website, 'active', 'taiwan_update_20261014', v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('%Chiutang%', '%Jiutang%', 'Chung Hwa Pulp - Chiutang Mill (Kaohsiung)', 'Kaohsiung', 'Dashu', null, 'Chung Hwa Pulp (YFY group) Chiutang mill, Dashu, Kaohsiung - coated and uncoated, copy and specialty papers.'),
  ('%Chung Hwa%Hualien%', '%Hualien%', 'Chung Hwa Pulp - Hualien Mill (Hualien)', 'Hualien', 'Hualien', null, 'Chung Hwa Pulp Hualien mill - bleached hardwood kraft pulp, fine printing and PPC paper.'),
  ('%Chung Hwa%Taitung%', '%Taitung%', 'Chung Hwa Pulp - Taitung Mill (Taitung)', 'Taitung', 'Taitung', null, 'Chung Hwa Pulp Taitung mill - printing paper and white / coated board.'),
  ('%Chupei%', '%Zhubei%', 'Cheng Loong - Chupei Mill (Hsinchu County)', 'Hsinchu County', 'Zhubei', null, 'Cheng Loong Chupei mill - coated white board, toilet and facial tissue, napkins, hand towels, recycled fibre.'),
  ('%YFY%Qingshui%', '%Qingshui%', 'YFY Consumer - Qingshui Tissue Mill (Taichung)', 'Taichung', 'Qingshui', 'https://www.yfy.com', 'YFY tissue mill at Qingshui, Taichung (Yangmei is the second tissue site).'),
  ('%Jih Sun%', '%Jih Sun%', 'Jih Sun Paper Industrial (Taiwan)', null, null, null, 'Jih Sun Paper - uncoated printing and writing, computer base paper, wrapping, cast coated and specialty papers (paper association register).'),
  ('%Kuan Yuan%', '%Kuan Yuan%', 'Kuan Yuan Paper (Taichung)', 'Taichung', 'Taichung', null, 'Kuan Yuan Paper - coated white board, grey board, duplex coated board - Taichung and Chunan mills.')
) as v(name_like, alt_like, party_name, region, city, website, notes)
where not exists (
  select 1 from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TW'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
);

-- ---------- 3) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (values
  ('%Chiutang%', '%Jiutang%', '%Chung Hwa%'),
  ('%Chung Hwa%Hualien%', '%Hualien%', '%Chung Hwa%'),
  ('%Chung Hwa%Taitung%', '%Taitung%', '%Chung Hwa%'),
  ('%Chupei%', '%Zhubei%', '%Cheng Loong%'),
  ('%YFY%Qingshui%', '%Qingshui%', '%YFY%'),
  ('%Jih Sun%', '%Jih Sun%', '%Jih Sun%'),
  ('%Kuan Yuan%', '%Kuan Yuan%', '%Kuan Yuan%'),
  ('%Erlin%', '%Longchen%', '%Longchen%'),
  ('%Taiwan Scott%', '%Hsinying%', '%Scott%'),
  ('%Cheng Loong%Tayuan%', '%Cheng Loong%Dayuan%', '%Cheng Loong%'),
  ('%Houli%', '%Cheng Loong%Houli%', '%Cheng Loong%'),
  ('%Hsing Chung%', '%Hsing Chung%', '%Hsing Chung%')
) as v(name_like, alt_like, owner_like)
cross join lateral (
  select y.id from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TW'
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TW'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Chiutang%', '%Jiutang%', '%Chung Hwa%',
   $pj${"owner": "Chung Hwa Pulp Corporation (YFY group)", "priority": 1, "products": "Coated and uncoated papers, copy paper, specialty papers", "grades": ["Copy paper", "Uncoated", "Coated", "Specialty"], "pitch": "Replace part of the current PCC / GCC in copy and uncoated grades - first Taiwan FCC trial", "approach": "Lead Taiwan account. Trial on the copy or uncoated line. Coating pigment is a separate question. YFY network can carry a win to other mills.", "to_collect": ["Current PCC / GCC supplier per machine and contract term", "Actual filler use (t/yr), slurry or powder", "Paper output per machine and grade", "Filler loading per grade, fibre furnish", "Who approves a machine trial"], "sources": [{"label": "Taiwan Paper Industry Association member register"}, {"label": "chp.com.tw"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Chung Hwa%Hualien%', '%Hualien%', '%Chung Hwa%',
   $pj${"owner": "Chung Hwa Pulp Corporation (YFY group)", "priority": 2, "products": "Bleached hardwood kraft pulp, fine printing paper, PPC copy paper", "grades": ["Uncoated printing", "Copy paper"], "pitch": "Pulp saving with opacity held - integrated pulp sets the cost baseline", "approach": "Follow-up after Chiutang.", "to_collect": ["Current PCC / GCC supplier per machine and contract term", "Actual filler use (t/yr), slurry or powder", "Paper output per machine and grade", "Filler loading per grade, fibre furnish", "Who approves a machine trial"], "sources": [{"label": "Taiwan Paper Industry Association member register"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Chung Hwa%Taitung%', '%Taitung%', '%Chung Hwa%',
   $pj${"owner": "Chung Hwa Pulp Corporation (YFY group)", "priority": 3, "products": "Printing papers, white and coated board", "grades": ["Printing paper", "White board"], "approach": "White grades - board plies need their own trial.", "to_collect": ["Current PCC / GCC supplier per machine and contract term", "Actual filler use (t/yr), slurry or powder", "Paper output per machine and grade", "Filler loading per grade, fibre furnish", "Who approves a machine trial"], "sources": [{"label": "Taiwan Paper Industry Association member register"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Chupei%', '%Zhubei%', '%Cheng Loong%',
   $pj${"owner": "Cheng Loong Corporation", "priority": 4, "products": "Coated white board, toilet and facial tissue, napkins, hand towels", "grades": ["Coated white board", "Tissue"], "pitch": "Recycled-fibre board and tissue - FCC to hold strength while cutting fibre cost", "approach": "Grade-by-grade joint trials. Cheng Loong also runs mills in Vietnam (Binh Duong) and China.", "to_collect": ["Current PCC / GCC supplier per machine and contract term", "Actual filler use (t/yr), slurry or powder", "Paper output per machine and grade", "Filler loading per grade, fibre furnish", "Who approves a machine trial"], "sources": [{"label": "Taiwan Paper Industry Association member register"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%YFY%Qingshui%', '%Qingshui%', '%YFY%',
   $pj${"owner": "Yuen Foong Yu (YFY) - consumer products", "priority": 5, "products": "Toilet and facial tissue, hand towels", "grades": ["Tissue", "Towel"], "capacity_split": [{"label": "Qingshui plus Yangmei, older Toscotec figure", "value_t": 74000}], "pitch": "Tissue FCC - separate track to the printing-paper program (CHP)", "approach": "Use the MBG 15 gsm tissue data. A later Toscotec line was designed for 120 t/day.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "sources": [{"label": "Toscotec supply reference"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Jih Sun%', '%Jih Sun%', '%Jih Sun%',
   $pj${"owner": "Jih Sun Paper Industrial", "priority": 6, "products": "Uncoated printing and writing, computer base paper, cast coated, specialty", "grades": ["Uncoated", "Specialty"], "pitch": "Smaller mill - fast first trial on uncoated printing paper", "approach": "Confirm the mill is running, its capacity and filler supplier.", "to_collect": ["Current PCC / GCC supplier per machine and contract term", "Actual filler use (t/yr), slurry or powder", "Paper output per machine and grade", "Filler loading per grade, fibre furnish", "Who approves a machine trial"], "sources": [{"label": "Taiwan Paper Industry Association member register"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Kuan Yuan%', '%Kuan Yuan%', '%Kuan Yuan%',
   $pj${"owner": "Kuan Yuan Paper", "priority": 7, "products": "Coated white board, grey board, duplex coated board", "grades": ["Coated white board", "Grey board"], "pitch": "Part of the filler in the white top ply", "approach": "Plies differ - test the top ply first.", "to_collect": ["Current PCC / GCC supplier per machine and contract term", "Actual filler use (t/yr), slurry or powder", "Paper output per machine and grade", "Filler loading per grade, fibre furnish", "Who approves a machine trial"], "sources": [{"label": "Taiwan Paper Industry Association member register"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Erlin%', '%Longchen%', '%Longchen%',
   $pj${"owner": "Longchen Paper and Packaging", "priority": 8, "products": "Linerboard and corrugating medium (ISO 50001 scope 2026-01)", "grades": ["Linerboard", "Corrugating medium"], "pitch": "Hold compression strength while cutting fibre", "approach": "Strength-critical - SCT, RCT, CMT, drainage. China mills at Wuxi, Pinghu and Hubei for later roll-out.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT specs", "Which grades or plies could take a filler", "Who approves a machine trial"], "sources": [{"label": "longchenpaper.com, ISO 50001 certificate 2026-01"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Taiwan Scott%', '%Hsinying%', '%Scott%',
   $pj${"owner": "Taiwan Scott Paper (Kimberly-Clark related)", "products": "Toilet and facial tissue, napkins, hand towels", "approach": "Tissue track - Tayuan and Hsinying mills registered. Ties to the Kimberly-Clark Kluang (Malaysia) track.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Cheng Loong%Tayuan%', '%Cheng Loong%Dayuan%', '%Cheng Loong%',
   $pj${"owner": "Cheng Loong Corporation", "products": "Recycled fibre, white recycled pulp", "capacity_split": [{"label": "White recycled pulp line (2023)", "value_t": 66000}], "approach": "Check white grades fed by the recycled pulp line.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Houli%', '%Cheng Loong%Houli%', '%Cheng Loong%',
   $pj${"owner": "Cheng Loong Corporation", "products": "Linerboard and corrugating medium", "approach": "Low priority - containerboard.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Hsing Chung%', '%Hsing Chung%', '%Hsing Chung%',
   $pj${"owner": "Hsing Chung Paper", "products": "Coated and uncoated printing, newsprint, kraft and bleached kraft papers", "approach": "Confirm which uncoated printing line is running.", "to_collect": ["Current PCC / GCC supplier per machine and contract term", "Actual filler use (t/yr), slurry or powder", "Paper output per machine and grade", "Filler loading per grade, fibre furnish", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb)
  ) as v(name_like, alt_like, owner_like, plant)
) m
where mp.party_id = m.id;

-- ---------- 4) VERIFY ----------
with v(name_like, alt_like, owner_like) as (values
  ('%Chiutang%', '%Jiutang%', '%Chung Hwa%'),
  ('%Chung Hwa%Hualien%', '%Hualien%', '%Chung Hwa%'),
  ('%Chung Hwa%Taitung%', '%Taitung%', '%Chung Hwa%'),
  ('%Chupei%', '%Zhubei%', '%Cheng Loong%'),
  ('%YFY%Qingshui%', '%Qingshui%', '%YFY%'),
  ('%Jih Sun%', '%Jih Sun%', '%Jih Sun%'),
  ('%Kuan Yuan%', '%Kuan Yuan%', '%Kuan Yuan%'),
  ('%Erlin%', '%Longchen%', '%Longchen%'),
  ('%Taiwan Scott%', '%Hsinying%', '%Scott%'),
  ('%Cheng Loong%Tayuan%', '%Cheng Loong%Dayuan%', '%Cheng Loong%'),
  ('%Houli%', '%Cheng Loong%Houli%', '%Cheng Loong%'),
  ('%Hsing Chung%', '%Hsing Chung%', '%Hsing Chung%')
)
select 'mill' as kind, coalesce(m.party_name, 'MISSING ' || v.name_like) as name,
       case when m.source = 'taiwan_update_20261014' then 'added now' when m.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as detail
from v
left join lateral (
  select y.id, y.party_name, y.source from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TW'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
  order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
  limit 1
) m on true
left join app.paper_mill_profile mp on mp.party_id = m.id
union all
select 'filler', p.party_name,
       case when p.source = 'taiwan_update_20261014' then 'added now' else 'already there' end, '-'
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ilike '%Lih Hsiang%' or p.party_name ilike '%Diamond Quantum%' or p.party_name ilike '%An Jung%' or p.party_name ilike '%Chu Shin%' or p.party_name ilike '%Tai Yang Industry%')
order by 1, 4, 2;
