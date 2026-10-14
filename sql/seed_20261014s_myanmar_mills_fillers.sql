-- ============================================================
-- seed_20261014s_myanmar_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Myanmar update (reports "Myanmar PCC/GCC producers" + "Myanmar paper
-- companies", 2026-10). Company introduction -> intro_ko / intro_en (filled
-- only when empty), extra detail -> notes once with 'MM check 2026-10-14',
-- plant data -> Mill profile card.
--
-- 1) Filler: Crown Calcium Carbonate (Yangon) - running status to confirm.
--    Not added: Empire Chemicals, Ziwaka (distributors), Ochnology
--    (limestone sourcing), the unnamed SBM mill customer. No Omya / MTI /
--    Artemyn plant found in Myanmar.
-- 2) Mills if missing + plant blocks, priority 1-7:
--      1 New Century (5,000 t/month recycled packaging)  2 YDE (new 50 t
--      line)  3 Star Flower tissue  4 KKN Tissue  5 Yeni Paper Mill
--      6 Nilar Pulp & Paper (R and D partner)  7 Thabaung (only on restart)
--    context: Special Manufacturing, Tissue World (imports jumbo rolls).
--    No FCC scenarios, no supply links.
--
-- Idempotent. Last statement is a verification select.
-- ============================================================

-- ---------- 1) FILLER ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, intro_ko, intro_en, notes, organization_id)
select 3::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 3 and x.deleted_at is null
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'MM', v.region, v.city, v.website, 'active', 'myanmar_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('Crown Calcium Carbonate', '%Crown Calcium%', 'Yangon', 'East Dagon', null, '양곤 East Dagon 산업단지의 Crown Calcium Carbonate. 미얀마 산업협회(MIA) 2026~2028 집행위원 명단 등재(U Thein Kyaw).', 'Crown Calcium Carbonate Co., East Dagon Industrial Zone, Yangon - listed on the Myanmar Industries Association 2026-2028 executive committee (U Thein Kyaw).', 'MM check 2026-10-14: 173/B Phan Chet Wun U Shwe Ohe Street, East Dagon, Yangon, +95 9 43056211 / +95 9 258878881 (directory). One archive directory marks it closed - confirm running status. Paper-grade GCC, PCC plant and paper customers not confirmed. An unnamed SBM customer in Myanmar runs 4 SCM1000 ultrafine mills (800 / 1,250 mesh, 8-12 t/h) with stearic coating - plastics grade, not wet-end filler.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
);

-- existing filler rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
    notes = case when coalesce(p.notes, '') ilike '%MM check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
    updated_at = now()
from (values
  ('Crown Calcium Carbonate', '%Crown Calcium%', 'Yangon', 'East Dagon', null, '양곤 East Dagon 산업단지의 Crown Calcium Carbonate. 미얀마 산업협회(MIA) 2026~2028 집행위원 명단 등재(U Thein Kyaw).', 'Crown Calcium Carbonate Co., East Dagon Industrial Zone, Yangon - listed on the Myanmar Industries Association 2026-2028 executive committee (U Thein Kyaw).', 'MM check 2026-10-14: 173/B Phan Chet Wun U Shwe Ohe Street, East Dagon, Yangon, +95 9 43056211 / +95 9 258878881 (directory). One archive directory marks it closed - confirm running status. Paper-grade GCC, PCC plant and paper customers not confirmed. An unnamed SBM customer in Myanmar runs 4 SCM1000 ultrafine mills (800 / 1,250 mesh, 8-12 t/h) with stearic coating - plastics grade, not wet-end filler.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
  and coalesce(p.source, '') <> 'myanmar_update_20261014';

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
       d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
from app.parties p
join (values
  ('Crown Calcium Carbonate', 'GCC producer', 'Myanmar carbonate - status to confirm', 'merchant', 'C', 'gcc')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'myanmar_update_20261014'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 2) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, intro_ko, intro_en, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'MM', v.region, v.city, v.website, 'active', 'myanmar_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('%New Century Paper%', '%San Kaung%', 'New Century Paper Mill (Yangon)', 'Yangon', 'Shwe Pyi Thar', 'https://www.newcenturypaper.com', '양곤 Shwe Pyi Thar·Watayar 에 공장을 둔 미얀마 민간 산업용지 제조사 New Century Paper Mill(2004년 설립). 100% 재생원료 골심지·테스트라이너·판지, 월 5,000톤.', 'New Century Paper Mill (founded 2004), Myanmar private industrial paper maker with mills at Shwe Pyi Thar and Watayar, Yangon - 100 pct recycled corrugating medium, testliner and paperboard, 5,000 t/month.', 'MM check 2026-10-14: 49 U Tun Nyo Road, Shwe Pyi Thar Industrial Zone 3, Yangon, +95 9 7315 6609 (company site). MD Yong Hway Chai, mill manager Myint Wai, production manager Chit Ko Ko. Medium 110 / 125 / 140 gsm, testliner 125-160 gsm, board to 300 gsm.'),
  ('%YDE%', '%YDE Pulp%', 'YDE Pulp and Paper (Yeni, Bago)', 'Bago', 'Yeni', null, '바고 지역 예니의 YDE Pulp and Paper. 50톤 규모 신규 제지라인 기계 설치 중(2026-08 보도), 제품 미확인.', 'YDE Pulp and Paper, Yeni, Bago Region - new 50 t paper line under machine installation (press 2026-08), products not yet known.', null),
  ('%Star Flower%', '%Star Flower%', 'Star Flower Tissue (Yangon)', 'Yangon', 'East Dagon', null, '양곤 East Dagon 산업단지의 티슈 제조사 Star Flower. MPPIA 2026-07 수처리 협의 기록.', 'Star Flower Co., tissue maker in East Dagon Industrial Zone, Yangon - in MPPIA water-treatment talks 2026-07.', 'MM check 2026-10-14: 147/148 Phan Chet Wun U Shwe Ohe Street, East Dagon, Yangon, +95 9 5011855 / +95 9 5040220 (directory).'),
  ('%KKN Tissue%', '%KKN%', 'KKN Tissue (Yedashe, Bago)', 'Bago', 'Yedashe', null, '바고 지역 Myohla·Yedashe 의 티슈 업체 KKN Tissue. 2026-08 정부 보도에 가동 정황.', 'KKN Tissue, Myohla, Yedashe, Bago Region - operations reported by the government 2026-08.', null),
  ('%Yeni Paper%', '%Yeni%Mill%', 'Yeni Paper Mill (Bago)', 'Bago', 'Yeni', null, '바고 지역 예니의 Yeni 제지공장. 20톤 규모 포장용지 라인, 대나무 펄프 시험(2026-08 산업부 점검).', 'Yeni Paper Mill, Yeni, Bago Region - 20 t packaging paper line and bamboo pulp trials (Ministry of Industry visit 2026-08).', null),
  ('%Nilar Pulp%', '%Nilar%', 'Nilar Pulp & Paper (Yangon)', 'Yangon', 'Dagon Seikkan', 'https://www.nppcoltd.com', '양곤 Dagon Seikkan 의 Nilar Pulp & Paper(2003년 설립). 볏짚·버개스·대나무·케나프 등 특수펄프·비표백 펄프시트, 품질시험·폐수처리 체계.', 'Nilar Pulp and Paper (founded 2003), Dagon Seikkan, Yangon - specialty and unbleached pulp sheets of rice straw, bagasse, bamboo, kenaf, sisal, abaca and pineapple fibre, with in-house paper testing.', 'MM check 2026-10-14: CEO Mrs. Nilar Yu, No.59 U Shwe Bin Street, Industrial Zone 1, Dagon Seikkan, Yangon, +95 9 977212013. About 4.5 acres. Tests brightness, kappa, ash, burst, CSF.')
) as v(name_like, alt_like, party_name, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MM'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
);

-- existing mill rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
    notes = case when m.notes is null or coalesce(p.notes, '') ilike '%MM check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
    updated_at = now()
from (
  select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MM'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%New Century Paper%', '%San Kaung%', '%New Century%', '양곤 Shwe Pyi Thar·Watayar 에 공장을 둔 미얀마 민간 산업용지 제조사 New Century Paper Mill(2004년 설립). 100% 재생원료 골심지·테스트라이너·판지, 월 5,000톤.', 'New Century Paper Mill (founded 2004), Myanmar private industrial paper maker with mills at Shwe Pyi Thar and Watayar, Yangon - 100 pct recycled corrugating medium, testliner and paperboard, 5,000 t/month.', 'MM check 2026-10-14: 49 U Tun Nyo Road, Shwe Pyi Thar Industrial Zone 3, Yangon, +95 9 7315 6609 (company site). MD Yong Hway Chai, mill manager Myint Wai, production manager Chit Ko Ko. Medium 110 / 125 / 140 gsm, testliner 125-160 gsm, board to 300 gsm.'),
  ('%YDE%', '%YDE Pulp%', '%YDE%', '바고 지역 예니의 YDE Pulp and Paper. 50톤 규모 신규 제지라인 기계 설치 중(2026-08 보도), 제품 미확인.', 'YDE Pulp and Paper, Yeni, Bago Region - new 50 t paper line under machine installation (press 2026-08), products not yet known.', null),
  ('%Star Flower%', '%Star Flower%', '%Star Flower%', '양곤 East Dagon 산업단지의 티슈 제조사 Star Flower. MPPIA 2026-07 수처리 협의 기록.', 'Star Flower Co., tissue maker in East Dagon Industrial Zone, Yangon - in MPPIA water-treatment talks 2026-07.', 'MM check 2026-10-14: 147/148 Phan Chet Wun U Shwe Ohe Street, East Dagon, Yangon, +95 9 5011855 / +95 9 5040220 (directory).'),
  ('%KKN Tissue%', '%KKN%', '%KKN%', '바고 지역 Myohla·Yedashe 의 티슈 업체 KKN Tissue. 2026-08 정부 보도에 가동 정황.', 'KKN Tissue, Myohla, Yedashe, Bago Region - operations reported by the government 2026-08.', null),
  ('%Yeni Paper%', '%Yeni%Mill%', '%Yeni%', '바고 지역 예니의 Yeni 제지공장. 20톤 규모 포장용지 라인, 대나무 펄프 시험(2026-08 산업부 점검).', 'Yeni Paper Mill, Yeni, Bago Region - 20 t packaging paper line and bamboo pulp trials (Ministry of Industry visit 2026-08).', null),
  ('%Nilar Pulp%', '%Nilar%', '%Nilar%', '양곤 Dagon Seikkan 의 Nilar Pulp & Paper(2003년 설립). 볏짚·버개스·대나무·케나프 등 특수펄프·비표백 펄프시트, 품질시험·폐수처리 체계.', 'Nilar Pulp and Paper (founded 2003), Dagon Seikkan, Yangon - specialty and unbleached pulp sheets of rice straw, bagasse, bamboo, kenaf, sisal, abaca and pineapple fibre, with in-house paper testing.', 'MM check 2026-10-14: CEO Mrs. Nilar Yu, No.59 U Shwe Bin Street, Industrial Zone 1, Dagon Seikkan, Yangon, +95 9 977212013. About 4.5 acres. Tests brightness, kappa, ash, burst, CSF.'),
  ('%Thabaung%', '%Thabaung%', '%Thabaung%', '에야와디 지역 타바웅의 국영 펄프·제지공장. 과거 설계능력 펄프 200톤/일, 일반지 50톤/일, 신문용지 60톤/일, 2014년 일부 가동 중단.', 'Thabaung pulp and paper mill, Ayeyarwady Region (state) - design pulp 200 t/day, paper 50 t/day, newsprint 60 t/day, parts stopped 2014.', null),
  ('%Special Manufacturing%', '%SMC Tissue%', '%Special Manufacturing%', '양곤 Hlaing Thar Yar 의 티슈 업체 Special Manufacturing(SMC Tissue). 안면·포켓티슈.', 'Special Manufacturing Co. (SMC Tissue), Hlaing Thar Yar, Yangon - facial and pocket tissue.', null),
  ('%Tissue World%', '%Myanmar Tissue World%', '%Tissue World%', '양곤 Mingalardon 의 Tissue World. 화장지·냅킨·안면티슈, 점보롤 수입 가공.', 'Tissue World Manufacturing and Trading, Mingalardon, Yangon - toilet, napkin and facial tissue converted using imported jumbo rolls.', null)
  ) as v(name_like, alt_like, owner_like, intro_ko, intro_en, notes)
) m
where p.id = m.id and coalesce(p.source, '') <> 'myanmar_update_20261014';

-- ---------- 4) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (
  select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MM'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%New Century Paper%', '%San Kaung%', '%New Century%'),
  ('%YDE%', '%YDE Pulp%', '%YDE%'),
  ('%Star Flower%', '%Star Flower%', '%Star Flower%'),
  ('%KKN Tissue%', '%KKN%', '%KKN%'),
  ('%Yeni Paper%', '%Yeni%Mill%', '%Yeni%'),
  ('%Nilar Pulp%', '%Nilar%', '%Nilar%'),
  ('%Thabaung%', '%Thabaung%', '%Thabaung%'),
  ('%Special Manufacturing%', '%SMC Tissue%', '%Special Manufacturing%'),
  ('%Tissue World%', '%Myanmar Tissue World%', '%Tissue World%')
  ) as v(name_like, alt_like, owner_like)
) m
where m.id is not null
  and not exists (select 1 from app.paper_mill_profile mp where mp.party_id = m.id);

update app.paper_mill_profile mp
set extra_data = coalesce(mp.extra_data, '{}'::jsonb) || jsonb_build_object('plant', m.plant),
    main_products = coalesce(nullif(btrim(mp.main_products), ''), m.plant ->> 'products'),
    updated_at = now()
from (
  select v.plant, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MM'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%New Century Paper%', '%San Kaung%', '%New Century%',
   $pj${"owner": "New Century Paper (San Kaung group)", "priority": 1, "products": "Corrugating medium, testliner, custom paperboard", "grades": ["Corrugating medium", "Testliner"], "capacity_split": [{"label": "5,000 t/month x 12 (calculated)", "value_t": 60000}], "pitch": "Hold strength and drainage while replacing part of the low-cost fibre", "approach": "Clearest capacity and management contacts in Myanmar - first meeting. Recycled packaging, so pulp saving is smaller than in white grades. No PCC / GCC use found.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "sources": [{"label": "newcenturypaper.com"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%YDE%', '%YDE Pulp%', '%YDE%',
   $pj${"owner": "YDE Pulp and Paper Company", "priority": 2, "products": "To confirm - new paper line", "capacity_split": [{"label": "50 t/day x 330 days if per day (calculated, unit to confirm)", "value_t": 16500}], "pitch": "New line - filler dosing and furnish can be designed in now", "approach": "Confirm the product first. If printing or white paper, priority rises.", "recent": [{"date": "2026-08", "text": "Machine installation under way (Global New Light of Myanmar)"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Star Flower%', '%Star Flower%', '%Star Flower%',
   $pj${"owner": "Star Flower Co.", "priority": 3, "products": "Tissue", "grades": ["Tissue"], "pitch": "Tissue FCC with MBG low-grammage trial data", "approach": "Confirm it runs its own tissue machine (not jumbo-roll converting).", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%KKN Tissue%', '%KKN%', '%KKN%',
   $pj${"owner": "KKN Tissue", "priority": 4, "products": "Tissue", "grades": ["Tissue"], "approach": "Confirm own tissue machine, output and furnish.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Yeni Paper%', '%Yeni%Mill%', '%Yeni%',
   $pj${"owner": "Yeni Paper Mill (Ministry of Industry visit)", "priority": 5, "products": "Packaging paper, bamboo pulp trials", "grades": ["Packaging paper"], "pitch": "Local-fibre pulp replacement trial", "approach": "Strength-sensitive packaging - trial data first.", "recent": [{"date": "2026-08-03", "text": "Ministry of Industry inspected the 20 t packaging paper line"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Nilar Pulp%', '%Nilar%', '%Nilar%',
   $pj${"owner": "Nilar Pulp and Paper", "priority": 6, "products": "Specialty and unbleached pulp sheets (agro and non-wood fibre)", "pitch": "Joint R and D - agro fibre plus mineral filler, strength and functional papers", "approach": "R and D partner, not a volume buyer.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Thabaung%', '%Thabaung%', '%Thabaung%',
   $pj${"owner": "Myanmar state (Thabaung)", "priority": 7, "products": "Pulp, general paper, newsprint", "capacity_split": [{"label": "Paper 50 + newsprint 60 t/day design (historical)", "value_t": 36300}], "approach": "Only if a stable restart is confirmed - gas supply problems and stoppage history.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Special Manufacturing%', '%SMC Tissue%', '%Special Manufacturing%',
   $pj${"owner": "Special Manufacturing Co.", "products": "Facial and pocket tissue", "approach": "Tell base-paper making apart and converting before any approach.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Tissue World%', '%Myanmar Tissue World%', '%Tissue World%',
   $pj${"owner": "Tissue World Manufacturing and Trading", "products": "Converted tissue (imported jumbo rolls)", "approach": "Not an FCC buyer - use only to trace base-paper suppliers.", "checked_at": "2026-10-14"}$pj$::jsonb)
  ) as v(name_like, alt_like, owner_like, plant)
) m
where mp.party_id = m.id;

-- ---------- 5) VERIFY ----------
with v(name_like, alt_like, owner_like) as (values
  ('%New Century Paper%', '%San Kaung%', '%New Century%'),
  ('%YDE%', '%YDE Pulp%', '%YDE%'),
  ('%Star Flower%', '%Star Flower%', '%Star Flower%'),
  ('%KKN Tissue%', '%KKN%', '%KKN%'),
  ('%Yeni Paper%', '%Yeni%Mill%', '%Yeni%'),
  ('%Nilar Pulp%', '%Nilar%', '%Nilar%'),
  ('%Thabaung%', '%Thabaung%', '%Thabaung%'),
  ('%Special Manufacturing%', '%SMC Tissue%', '%Special Manufacturing%'),
  ('%Tissue World%', '%Myanmar Tissue World%', '%Tissue World%')
)
select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_like) as name,
       case when p.source = 'myanmar_update_20261014' then 'added now' when p.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from v
left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MM'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1)
left join app.paper_mill_profile mp on mp.party_id = p.id
union all
select 'filler', p.party_name,
       case when p.source = 'myanmar_update_20261014' then 'added now' else 'already there' end, '-',
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ilike '%Crown Calcium%')
union all
select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', '-'
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and l.extra_data ->> 'batch' = 'myanmar_update_20261014'
order by 1, 4, 2;
