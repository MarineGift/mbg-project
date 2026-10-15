-- ============================================================
-- seed_20261014ae_srilanka_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Sri Lanka update (reports 2026-10). Introduction -> intro_ko / intro_en
-- (only when empty), detail -> notes once with 'LK check 2026-10-14',
-- plant data -> Mill profile card.
--
-- 1) Fillers if missing: LANMIC (ultrafine GCC), Quality Chemicals (PCC and
--    GCC claimed), Unitum (UNICAL), Promark, Lanka Phosphate PCC proposal.
-- 2) Mills if missing + plant blocks, priority 1-4: National Paper
--    (Valaichchenai, printing), Nalaka Tissue (15 t/day), Nithya, KSPA.
--    Small volumes - value is technical proof (printing and tissue).
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
       v.party_name, 'LK', v.region, v.city, v.website, 'active', 'srilanka_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('Lanka Minerals & Chemicals (LANMIC)', '%LANMIC%', 'Western Province', 'Avissawella', 'https://www.lanmic.com', '1998년 설립 Lanka Minerals & Chemicals(LANMIC). Seethawaka 수출가공구역(Avissawella) 등 5개 사업장, 초미립 GCC W-CARB(D50 1 µm 미만)·표면처리 LAKCARB, 연구소 3곳, 수출.', 'Lanka Minerals and Chemicals (LANMIC, founded 1998), Seethawaka Industrial Park, Avissawella and other sites - ultrafine GCC W-CARB (D50 under 1 um), coated LAKCARB, three R and D labs, exports to Australia, Egypt, India, Pakistan, Thailand, Middle East.', 'LK check 2026-10-14: PCC and dispersions are in its 2017 trademark goods list - not proof of a PCC plant. Wet GCC line and paper customers to confirm. MD M. U. Bopitiya, info@lanmic.com, +94 11 262 2453.'),
  ('Quality Chemicals (Sri Lanka)', '%Quality Chemicals%', 'Sabaragamuwa', 'Balangoda', 'https://www.qualitychemicals.lk', '발랑고다의 Quality Chemicals. PCC·GCC·수산화칼슘 제조 공정 소개, PCC 용도에 제지 포함.', 'Quality Chemicals, 82 Kaltota Road, Balangoda - describes PCC, GCC and calcium hydroxide manufacture (sorting, washing, grinding, calcining, chemical treatment), paper among PCC uses.', 'LK check 2026-10-14: PCC bulk density 0.28-0.9 g/cm3. Capacity, slurry and paper customers not public - site visit needed. MD M. A. S. Ananda Wijayasiri, info@qualitychemicals.lk, +94 45 228 7382.'),
  ('Unitum Chemicals (UNICAL)', '%Unitum%', 'Western Province', 'Colombo', 'https://www.unitumlanka.com', 'UNICAL 브랜드의 Unitum Chemicals. 자체 광산 원료, 분쇄·코팅 GCC(5~55 µm), 계약제조.', 'Unitum Chemicals (UNICAL brand) - ground and coated GCC (5-55 um), raw stone of selected own quarries, contract manufacturing, head office Aitken Spence Tower 1, Colombo 02.', 'LK check 2026-10-14: products for paint, rubber, plastics, PVC - paper fine grades and wet plant not confirmed. info@unitumlanka.com, +94 11 739 9995.'),
  ('Promark Lanka', '%Promark%', 'Central Province', 'Digana', 'https://www.promarklanka.lk', '캔디 Digana 의 Promark Lanka. GCC·돌로마이트·석회석 채굴·분쇄(100~325 mesh, 주문 400~800 mesh).', 'Promark Lanka, Digana, Kandy - quarrying and grinding GCC, dolomite, limestone (100-325 mesh, 400-800 mesh to order).', 'LK check 2026-10-14: raw-material or grinding partner only. promarklanka@gmail.com.'),
  ('Lanka Phosphate - PCC project (proposal)', '%Lanka Phosphate%', 'North Central Province', 'Eppawala', null, 'Lanka Phosphate 의 Eppawala 인산염 부산물을 이용한 PCC 공장 제안(2026-01) — 초기 3만 t, 확장 5만 t, 투자 64~78억 LKR.', 'Lanka Phosphate - proposal (2026-01) for a PCC plant using Eppawala phosphate by-products, 30,000 t/yr initial and 50,000 t/yr expanded, LKR 6.4-7.8bn, powder and paper slurry PCC.', 'LK check 2026-10-14: proposal seeking approval - not decided or built. If approved, propose designing FCC in the plant.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
);

-- existing filler rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
    notes = case when coalesce(p.notes, '') ilike '%LK check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
    updated_at = now()
from (values
  ('Lanka Minerals & Chemicals (LANMIC)', '%LANMIC%', 'Western Province', 'Avissawella', 'https://www.lanmic.com', '1998년 설립 Lanka Minerals & Chemicals(LANMIC). Seethawaka 수출가공구역(Avissawella) 등 5개 사업장, 초미립 GCC W-CARB(D50 1 µm 미만)·표면처리 LAKCARB, 연구소 3곳, 수출.', 'Lanka Minerals and Chemicals (LANMIC, founded 1998), Seethawaka Industrial Park, Avissawella and other sites - ultrafine GCC W-CARB (D50 under 1 um), coated LAKCARB, three R and D labs, exports to Australia, Egypt, India, Pakistan, Thailand, Middle East.', 'LK check 2026-10-14: PCC and dispersions are in its 2017 trademark goods list - not proof of a PCC plant. Wet GCC line and paper customers to confirm. MD M. U. Bopitiya, info@lanmic.com, +94 11 262 2453.'),
  ('Quality Chemicals (Sri Lanka)', '%Quality Chemicals%', 'Sabaragamuwa', 'Balangoda', 'https://www.qualitychemicals.lk', '발랑고다의 Quality Chemicals. PCC·GCC·수산화칼슘 제조 공정 소개, PCC 용도에 제지 포함.', 'Quality Chemicals, 82 Kaltota Road, Balangoda - describes PCC, GCC and calcium hydroxide manufacture (sorting, washing, grinding, calcining, chemical treatment), paper among PCC uses.', 'LK check 2026-10-14: PCC bulk density 0.28-0.9 g/cm3. Capacity, slurry and paper customers not public - site visit needed. MD M. A. S. Ananda Wijayasiri, info@qualitychemicals.lk, +94 45 228 7382.'),
  ('Unitum Chemicals (UNICAL)', '%Unitum%', 'Western Province', 'Colombo', 'https://www.unitumlanka.com', 'UNICAL 브랜드의 Unitum Chemicals. 자체 광산 원료, 분쇄·코팅 GCC(5~55 µm), 계약제조.', 'Unitum Chemicals (UNICAL brand) - ground and coated GCC (5-55 um), raw stone of selected own quarries, contract manufacturing, head office Aitken Spence Tower 1, Colombo 02.', 'LK check 2026-10-14: products for paint, rubber, plastics, PVC - paper fine grades and wet plant not confirmed. info@unitumlanka.com, +94 11 739 9995.'),
  ('Promark Lanka', '%Promark%', 'Central Province', 'Digana', 'https://www.promarklanka.lk', '캔디 Digana 의 Promark Lanka. GCC·돌로마이트·석회석 채굴·분쇄(100~325 mesh, 주문 400~800 mesh).', 'Promark Lanka, Digana, Kandy - quarrying and grinding GCC, dolomite, limestone (100-325 mesh, 400-800 mesh to order).', 'LK check 2026-10-14: raw-material or grinding partner only. promarklanka@gmail.com.'),
  ('Lanka Phosphate - PCC project (proposal)', '%Lanka Phosphate%', 'North Central Province', 'Eppawala', null, 'Lanka Phosphate 의 Eppawala 인산염 부산물을 이용한 PCC 공장 제안(2026-01) — 초기 3만 t, 확장 5만 t, 투자 64~78억 LKR.', 'Lanka Phosphate - proposal (2026-01) for a PCC plant using Eppawala phosphate by-products, 30,000 t/yr initial and 50,000 t/yr expanded, LKR 6.4-7.8bn, powder and paper slurry PCC.', 'LK check 2026-10-14: proposal seeking approval - not decided or built. If approved, propose designing FCC in the plant.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
  and coalesce(p.source, '') <> 'srilanka_update_20261014';

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
       d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
from app.parties p
join (values
  ('Lanka Minerals & Chemicals (LANMIC)', 'GCC producer', 'Sri Lanka ultrafine GCC - FCC partner priority 1', 'merchant', 'B', 'gcc'),
  ('Quality Chemicals (Sri Lanka)', 'PCC producer', 'Sri Lanka PCC and GCC - PCC route candidate', 'merchant', 'C', 'pcc'),
  ('Unitum Chemicals (UNICAL)', 'GCC producer', 'Sri Lanka GCC and contract manufacturing', 'merchant', 'C', 'gcc'),
  ('Promark Lanka', 'GCC producer', 'Raw GCC and dolomite', 'merchant', 'C', 'gcc'),
  ('Lanka Phosphate - PCC project (proposal)', 'PCC producer', 'Proposed Sri Lanka PCC plant', 'merchant', 'C', 'pcc')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'srilanka_update_20261014'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 2) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, intro_ko, intro_en, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'LK', v.region, v.city, v.website, 'active', 'srilanka_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('%National Paper%', '%Valaichchenai%', 'National Paper Company - Valaichchenai Mill (Batticaloa)', 'Eastern Province', 'Valaichchenai', 'https://www.npc.lk', '1955년 설립 스리랑카 국영 National Paper Company 의 Valaichchenai 공장. 인쇄·필기용지·컬러지·포장지, 2020년 재가동, 2025년 1~9월 2,066 t 생산.', 'National Paper Company (state, founded 1955), Valaichchenai mill, Batticaloa - white printing, writing, colour, manila and wrapping paper, restarted 2020, 2,066 t produced Jan-Sep 2025.', 'LK check 2026-10-14: September 2025 output 344.5 t (Ministry of Industry). Waste paper of state bodies feeds the mill (Cabinet 2025). Old design capacity 20,500 t/yr (World Bank). HQ 61 Stratford Avenue, Colombo 05, +94 11 255 6465, sales@npc.lk.'),
  ('%Nalaka%', '%Nalaka Tissue%', 'Nalaka Tissue Paper Manufacturing (Horana)', 'Western Province', 'Horana', 'https://www.nalakastationery.com', 'Nalaka Group 의 티슈 원지 제조사. 2023년 일본산 티슈 제지기 도입, 약 15 t/일, 12~40 gsm 화장지·냅킨·페이셜·키친타월.', 'Nalaka Tissue Paper Manufacturing (Nalaka Group) - Japanese tissue machine installed 2023, about 15 t/day, 12-40 gsm toilet, napkin, facial and kitchen tissue. Group also makes recycled board and kraft at Poruwadanda, Horana.', 'LK check 2026-10-14: per Paper Mart interview 2024. Registered office 258A Galvihara Road, Dehiwala, +94 11 273 6760, nalakapaper@gmail.com.'),
  ('%Nithya Paper%', '%Nithya%', 'Nithya Paper & Boards Lanka (Horana)', 'Western Province', 'Horana', 'https://www.nithyapaper.com', '2015년 설립 Horana 수출가공구역의 Nithya Paper & Boards Lanka. 재생 플루팅(112~200 gsm)·테스트라이너(140~300 gsm)·크라프트.', 'Nithya Paper and Boards Lanka (founded 2015), Horana Export Processing Zone - recycled fluting 112-200 gsm, testliner 140-300 gsm and kraft, Presidential Export Award 2017/18.', 'LK check 2026-10-14: Plot 49, BOI EPZ Horana, +94 11 767 2685, srilanka@nithyagroups.com. Capacity not published.'),
  ('%KSPA%', '%Embilipitiya%', 'KSPA Embilipitiya Paper Mills (Embilipitiya)', 'Sabaragamuwa', 'Embilipitiya', 'https://www.kspapaper.com', 'Anunine Holdings 계열 KSPA Embilipitiya Paper Mills(2019년 설립). 옛 국영 공장을 PPP 로 운영, 100% 재생섬유 미디엄·테스트라이너(80~200 gsm).', 'KSPA Embilipitiya Paper Mills (Anunine Holdings, founded 2019), Thunkama, Embilipitiya - former state mill run under a 30-year PPP since 2022, 100 pct recycled medium and testliner 80-200 gsm, FSC.', 'LK check 2026-10-14: restart confirmed in the 2025 government report. Head office 9 Modarawila Industrial Zone, Panadura, +94 38 559 3000.')
) as v(name_like, alt_like, party_name, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LK'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
);

-- existing mill rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
    notes = case when m.notes is null or coalesce(p.notes, '') ilike '%LK check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
    updated_at = now()
from (
  select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LK'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%National Paper%', '%Valaichchenai%', '%National Paper%', '1955년 설립 스리랑카 국영 National Paper Company 의 Valaichchenai 공장. 인쇄·필기용지·컬러지·포장지, 2020년 재가동, 2025년 1~9월 2,066 t 생산.', 'National Paper Company (state, founded 1955), Valaichchenai mill, Batticaloa - white printing, writing, colour, manila and wrapping paper, restarted 2020, 2,066 t produced Jan-Sep 2025.', 'LK check 2026-10-14: September 2025 output 344.5 t (Ministry of Industry). Waste paper of state bodies feeds the mill (Cabinet 2025). Old design capacity 20,500 t/yr (World Bank). HQ 61 Stratford Avenue, Colombo 05, +94 11 255 6465, sales@npc.lk.'),
  ('%Nalaka%', '%Nalaka Tissue%', '%Nalaka%', 'Nalaka Group 의 티슈 원지 제조사. 2023년 일본산 티슈 제지기 도입, 약 15 t/일, 12~40 gsm 화장지·냅킨·페이셜·키친타월.', 'Nalaka Tissue Paper Manufacturing (Nalaka Group) - Japanese tissue machine installed 2023, about 15 t/day, 12-40 gsm toilet, napkin, facial and kitchen tissue. Group also makes recycled board and kraft at Poruwadanda, Horana.', 'LK check 2026-10-14: per Paper Mart interview 2024. Registered office 258A Galvihara Road, Dehiwala, +94 11 273 6760, nalakapaper@gmail.com.'),
  ('%Nithya Paper%', '%Nithya%', '%Nithya%', '2015년 설립 Horana 수출가공구역의 Nithya Paper & Boards Lanka. 재생 플루팅(112~200 gsm)·테스트라이너(140~300 gsm)·크라프트.', 'Nithya Paper and Boards Lanka (founded 2015), Horana Export Processing Zone - recycled fluting 112-200 gsm, testliner 140-300 gsm and kraft, Presidential Export Award 2017/18.', 'LK check 2026-10-14: Plot 49, BOI EPZ Horana, +94 11 767 2685, srilanka@nithyagroups.com. Capacity not published.'),
  ('%KSPA%', '%Embilipitiya%', '%KSPA%', 'Anunine Holdings 계열 KSPA Embilipitiya Paper Mills(2019년 설립). 옛 국영 공장을 PPP 로 운영, 100% 재생섬유 미디엄·테스트라이너(80~200 gsm).', 'KSPA Embilipitiya Paper Mills (Anunine Holdings, founded 2019), Thunkama, Embilipitiya - former state mill run under a 30-year PPP since 2022, 100 pct recycled medium and testliner 80-200 gsm, FSC.', 'LK check 2026-10-14: restart confirmed in the 2025 government report. Head office 9 Modarawila Industrial Zone, Panadura, +94 38 559 3000.')
  ) as v(name_like, alt_like, owner_like, intro_ko, intro_en, notes)
) m
where p.id = m.id and coalesce(p.source, '') <> 'srilanka_update_20261014';

-- ---------- 4) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (
  select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LK'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%National Paper%', '%Valaichchenai%', '%National Paper%'),
  ('%Nalaka%', '%Nalaka Tissue%', '%Nalaka%'),
  ('%Nithya Paper%', '%Nithya%', '%Nithya%'),
  ('%KSPA%', '%Embilipitiya%', '%KSPA%')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LK'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%National Paper%', '%Valaichchenai%', '%National Paper%',
   $pj${"owner": "Government of Sri Lanka", "priority": 1, "products": "White printing, writing, colour, manila, cover and wrapping paper", "grades": ["Writing and printing"], "capacity_split": [{"label": "Jan-Sep 2025 output", "value_t": 2066}, {"label": "Old design capacity", "value_t": 20500}], "pitch": "Printing-paper validation - opacity, printability and pulp saving", "approach": "Technical proof site rather than a royalty source (about 400 t FCC/yr at 10 pct on 4,000 t). Check furnish and ash first.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Nalaka%', '%Nalaka Tissue%', '%Nalaka%',
   $pj${"owner": "Nalaka Group", "priority": 2, "products": "Tissue base paper 12-40 gsm", "grades": ["Tissue"], "machines": 1, "capacity_split": [{"label": "15 t/day x 330 (calculated)", "value_t": 4950}], "pitch": "Tissue FCC proof case using MBG low-grammage data", "approach": "Small royalty (about 250 t/yr at 5 pct) - value is the tissue reference.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Nithya Paper%', '%Nithya%', '%Nithya%',
   $pj${"owner": "Nithya group", "priority": 3, "products": "Fluting, testliner, recycled kraft", "grades": ["Fluting", "Testliner"], "approach": "Trial 2 / 5 / 8 pct FCC with burst, ring crush, Cobb and drying energy measured.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%KSPA%', '%Embilipitiya%', '%KSPA%',
   $pj${"owner": "Anunine Holdings", "priority": 4, "products": "Medium and test liner", "grades": ["Medium", "Testliner"], "approach": "Recycled-fibre saving and drainage trial - strength must hold.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb)
  ) as v(name_like, alt_like, owner_like, plant)
) m
where mp.party_id = m.id;

-- ---------- 5) VERIFY ----------
with v(name_like, alt_like, owner_like) as (values
  ('%National Paper%', '%Valaichchenai%', '%National Paper%'),
  ('%Nalaka%', '%Nalaka Tissue%', '%Nalaka%'),
  ('%Nithya Paper%', '%Nithya%', '%Nithya%'),
  ('%KSPA%', '%Embilipitiya%', '%KSPA%')
)
select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_like) as name,
       case when p.source = 'srilanka_update_20261014' then 'added now' when p.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from v
left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LK'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1)
left join app.paper_mill_profile mp on mp.party_id = p.id
union all
select 'filler', p.party_name,
       case when p.source = 'srilanka_update_20261014' then 'added now' else 'already there' end, '-',
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ilike '%LANMIC%' or p.party_name ilike '%Quality Chemicals%' or p.party_name ilike '%Unitum%' or p.party_name ilike '%Promark%' or p.party_name ilike '%Lanka Phosphate%')
union all
select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', '-'
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and l.extra_data ->> 'batch' = 'srilanka_update_20261014'
order by 1, 4, 2;
