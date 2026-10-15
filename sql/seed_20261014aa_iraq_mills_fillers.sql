-- ============================================================
-- seed_20261014aa_iraq_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Iraq update (reports 2026-10). Introduction -> intro_ko / intro_en
-- (only when empty), detail -> notes once with 'IQ check 2026-10-14',
-- plant data -> Mill profile card.
--
-- 1) Fillers if missing: White Shield (Kayaci, GCC + PCC claimed), Noor Al
--    Shams (Kalar), Al Azm (Baghdad), Basmat Al-Haram. Iranian, Turkish and
--    Chinese exporters to Iraq not added here.
-- 2) Mills if missing + plant blocks, priority 1-2: Al Sindyan (tissue
--    65 t/day), Al Shumookh (packaging 500 t/day planned + 70 t/day tissue
--    project). context: Basra and Maysan state mills (rehabilitation),
--    Narjis (match only).
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
       v.party_name, 'IQ', v.region, v.city, v.website, 'active', 'iraq_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('White Shield (Kayaci Group)', '%White Shield%', 'Sulaymaniyah', 'Darbandikhan', null, 'Kayaci Group 의 White Shield. 다르반디칸 고순도 탄산칼슘 광산·가공공장, GCC·PCC·미분·충전제, 걸프 수출.', 'White Shield (Kayaci Group) - high-purity, high-brightness calcium carbonate quarry and plant at Darbandikhan, Kurdistan, lists GCC, PCC, fine powders and fillers, exports to the Gulf.', 'IQ check 2026-10-14: plant address, lines and capacity not public. PCC reactors and sales to confirm. Contact per report info@kayacigroup.com, +964 770 132 6551.'),
  ('Noor Al Shams Calcium Carbonate Factory', '%Noor Al Shams%', 'Sulaymaniyah', 'Kalar', null, '술라이마니야 칼라르의 Noor Al Shams 탄산칼슘 공장. 제지·플라스틱·의약·건설·파이프·도료·사료 용도.', 'Noor Al Shams Calcium Carbonate Factory, Kalar, Sulaymaniyah - paper, plastics, pharma, construction, pipe, paint and feed listed as uses.', 'IQ check 2026-10-14: GCC or PCC, grades and capacity not public. Tel +964 770 777 4577.'),
  ('Al Azm Company for Industrial Investment', '%Al Azm%', 'Baghdad', 'Baghdad', 'https://www.alazm.me', '바그다드의 Al Azm. 천연·분쇄·표면처리 탄산칼슘, 산업단지 개발·국제 산업협력.', 'Al Azm Company for Industrial Investment, Baghdad - natural, ground and coated calcium carbonate, also industrial-park development.', 'IQ check 2026-10-14: site wrongly describes GCC as chemical precipitation - no PCC plant inferred. CEO Zainab Al-Janabi, chairman Mundher Maki Al-Hasani. Al-Karrada, Abu Nuwas St, Baghdad, +964 780 912 4387. Fit for local co-investment rather than supply.'),
  ('Basmat Al-Haram', '%Basmat Al-Haram%', 'Baghdad', 'Baghdad', 'https://www.basmat-alharam.com', '바그다드의 광물 분쇄·가공업체 Basmat Al-Haram. 초미세 탄산칼슘·석영·장석·활석.', 'Basmat Al-Haram, Baghdad - mineral grinding, ultrafine calcium carbonate, quartz, feldspar, talc.', 'IQ check 2026-10-14: website under construction - confirm running lines. Tel +964 784 410 9270.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
);

-- existing filler rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
    notes = case when coalesce(p.notes, '') ilike '%IQ check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
    updated_at = now()
from (values
  ('White Shield (Kayaci Group)', '%White Shield%', 'Sulaymaniyah', 'Darbandikhan', null, 'Kayaci Group 의 White Shield. 다르반디칸 고순도 탄산칼슘 광산·가공공장, GCC·PCC·미분·충전제, 걸프 수출.', 'White Shield (Kayaci Group) - high-purity, high-brightness calcium carbonate quarry and plant at Darbandikhan, Kurdistan, lists GCC, PCC, fine powders and fillers, exports to the Gulf.', 'IQ check 2026-10-14: plant address, lines and capacity not public. PCC reactors and sales to confirm. Contact per report info@kayacigroup.com, +964 770 132 6551.'),
  ('Noor Al Shams Calcium Carbonate Factory', '%Noor Al Shams%', 'Sulaymaniyah', 'Kalar', null, '술라이마니야 칼라르의 Noor Al Shams 탄산칼슘 공장. 제지·플라스틱·의약·건설·파이프·도료·사료 용도.', 'Noor Al Shams Calcium Carbonate Factory, Kalar, Sulaymaniyah - paper, plastics, pharma, construction, pipe, paint and feed listed as uses.', 'IQ check 2026-10-14: GCC or PCC, grades and capacity not public. Tel +964 770 777 4577.'),
  ('Al Azm Company for Industrial Investment', '%Al Azm%', 'Baghdad', 'Baghdad', 'https://www.alazm.me', '바그다드의 Al Azm. 천연·분쇄·표면처리 탄산칼슘, 산업단지 개발·국제 산업협력.', 'Al Azm Company for Industrial Investment, Baghdad - natural, ground and coated calcium carbonate, also industrial-park development.', 'IQ check 2026-10-14: site wrongly describes GCC as chemical precipitation - no PCC plant inferred. CEO Zainab Al-Janabi, chairman Mundher Maki Al-Hasani. Al-Karrada, Abu Nuwas St, Baghdad, +964 780 912 4387. Fit for local co-investment rather than supply.'),
  ('Basmat Al-Haram', '%Basmat Al-Haram%', 'Baghdad', 'Baghdad', 'https://www.basmat-alharam.com', '바그다드의 광물 분쇄·가공업체 Basmat Al-Haram. 초미세 탄산칼슘·석영·장석·활석.', 'Basmat Al-Haram, Baghdad - mineral grinding, ultrafine calcium carbonate, quartz, feldspar, talc.', 'IQ check 2026-10-14: website under construction - confirm running lines. Tel +964 784 410 9270.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
  and coalesce(p.source, '') <> 'iraq_update_20261014';

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
       d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
from app.parties p
join (values
  ('White Shield (Kayaci Group)', 'GCC producer', 'Iraq GCC (PCC claimed) - FCC partner priority 1', 'merchant', 'C', 'gcc'),
  ('Noor Al Shams Calcium Carbonate Factory', 'GCC producer', 'Kurdistan carbonate naming paper', 'merchant', 'C', 'gcc'),
  ('Al Azm Company for Industrial Investment', 'GCC producer', 'Iraq GCC and industrial investor', 'merchant', 'C', 'gcc'),
  ('Basmat Al-Haram', 'GCC producer', 'Baghdad ultrafine carbonate', 'merchant', 'C', 'gcc')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'iraq_update_20261014'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 2) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, intro_ko, intro_en, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'IQ', v.region, v.city, v.website, 'active', 'iraq_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('%Sindyan%', '%SPM%Baghdad%', 'Al Sindyan Paper Mill (Baghdad)', 'Baghdad', 'Al Zaafaraniah', 'https://www.alsindyanpm.com', '2022년 설립 바그다드 Al Zaafaraniah 산업단지의 Al Sindyan Paper Mill. 유럽산 설비, 미용티슈·화장지·키친타월·냅킨 원지 65 t/일.', 'Al Sindyan Paper Mill (founded 2022), Al Zaafaraniah Industrial Zone, Baghdad - European machinery, facial, toilet, kitchen towel and napkin base paper, 65 t/day.', 'IQ check 2026-10-14: about 19,500-21,450 t/yr at 300-330 days (calculated). Altiqniat Alhaditha (ACACIA) states nearly the same profile (65 t/day, first jumbo-roll maker) - may be the same mill, do not count twice. Contact per report info@alsindyanpm.com, +964 78444 43650.'),
  ('%Shumookh%', '%Shomokh%', 'Al Shumookh Paper Production (Al-Rumaitha)', 'Al-Muthanna', 'Al-Rumaitha', 'https://www.alshomokhpaper.com', '이라크 Al-Muthanna Al-Rumaitha 의 Al Shumookh Paper Production. 재생 폐지 골판지원지(플루팅·테스트라이너·크라프트·화이트탑) 1단계 500 t/일, 장기 1,800 t/일 계획.', 'Al Shumookh Paper Production Co., Al-Rumaitha, Al-Muthanna - recycled fluting, testliner, kraft liner and white-top liner, phase 1 planned 500 t/day, long-term 1,800 t/day.', 'IQ check 2026-10-14: Al-Muthanna investment authority 2026-09-30 describes installation and trial preparation - not yet in normal production. Contractor posts also mention a used A.Celli crescent-former tissue machine (70 t/day, about 80 pct installed). CEO Ali Alshawi, COO Mohammed Alshaawi, CFO Mohamed Khamis - Dubai office Prism Tower, Business Bay. info@alshomokhpaper.com.'),
  ('%Basra Paper%', '%Basrah Paper%', 'Basra Paper Factory (Basra)', 'Basra', 'Basra', null, '이라크 정부 투자자료에 등장하는 국영 Basra 제지공장 — 재건 사업 대상.', 'Basra Paper Factory (state) - listed by the National Investment Commission as a rehabilitation project.', 'IQ check 2026-10-14: targets differ by government list - 60,000 t/yr (USD 45m) versus 640 t/day (USD 236m). Grades, contract status and machine condition unknown.'),
  ('%Maysan Paper%', '%Maisan Paper%', 'Maysan Paper Factory (Maysan)', 'Maysan', null, null, 'State Company for Paper Manufacture 의 Maysan 제지공장 — 연 5.7만 t 재건·개발 투자 대상.', 'Maysan Paper Factory (State Company for Paper Manufacture) - 57,000 t/yr rehabilitation and development opportunity.', 'IQ check 2026-10-14: investment USD 35-50m by source. Running status and grades unknown.')
) as v(name_like, alt_like, party_name, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'IQ'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
);

-- existing mill rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
    notes = case when m.notes is null or coalesce(p.notes, '') ilike '%IQ check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
    updated_at = now()
from (
  select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'IQ'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Sindyan%', '%SPM%Baghdad%', '%Sindyan%', '2022년 설립 바그다드 Al Zaafaraniah 산업단지의 Al Sindyan Paper Mill. 유럽산 설비, 미용티슈·화장지·키친타월·냅킨 원지 65 t/일.', 'Al Sindyan Paper Mill (founded 2022), Al Zaafaraniah Industrial Zone, Baghdad - European machinery, facial, toilet, kitchen towel and napkin base paper, 65 t/day.', 'IQ check 2026-10-14: about 19,500-21,450 t/yr at 300-330 days (calculated). Altiqniat Alhaditha (ACACIA) states nearly the same profile (65 t/day, first jumbo-roll maker) - may be the same mill, do not count twice. Contact per report info@alsindyanpm.com, +964 78444 43650.'),
  ('%Shumookh%', '%Shomokh%', '%Shumookh%', '이라크 Al-Muthanna Al-Rumaitha 의 Al Shumookh Paper Production. 재생 폐지 골판지원지(플루팅·테스트라이너·크라프트·화이트탑) 1단계 500 t/일, 장기 1,800 t/일 계획.', 'Al Shumookh Paper Production Co., Al-Rumaitha, Al-Muthanna - recycled fluting, testliner, kraft liner and white-top liner, phase 1 planned 500 t/day, long-term 1,800 t/day.', 'IQ check 2026-10-14: Al-Muthanna investment authority 2026-09-30 describes installation and trial preparation - not yet in normal production. Contractor posts also mention a used A.Celli crescent-former tissue machine (70 t/day, about 80 pct installed). CEO Ali Alshawi, COO Mohammed Alshaawi, CFO Mohamed Khamis - Dubai office Prism Tower, Business Bay. info@alshomokhpaper.com.'),
  ('%Basra Paper%', '%Basrah Paper%', '%Basra Paper%', '이라크 정부 투자자료에 등장하는 국영 Basra 제지공장 — 재건 사업 대상.', 'Basra Paper Factory (state) - listed by the National Investment Commission as a rehabilitation project.', 'IQ check 2026-10-14: targets differ by government list - 60,000 t/yr (USD 45m) versus 640 t/day (USD 236m). Grades, contract status and machine condition unknown.'),
  ('%Maysan Paper%', '%Maisan Paper%', '%Maysan%', 'State Company for Paper Manufacture 의 Maysan 제지공장 — 연 5.7만 t 재건·개발 투자 대상.', 'Maysan Paper Factory (State Company for Paper Manufacture) - 57,000 t/yr rehabilitation and development opportunity.', 'IQ check 2026-10-14: investment USD 35-50m by source. Running status and grades unknown.'),
  ('%Narjis%', '%Narjis Factory%', '%Narjis%', '키르쿠크의 티슈 제조업체 Narjis Factory.', 'Narjis Factory for Tissue Paper Production, Kirkuk.', null)
  ) as v(name_like, alt_like, owner_like, intro_ko, intro_en, notes)
) m
where p.id = m.id and coalesce(p.source, '') <> 'iraq_update_20261014';

-- ---------- 4) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (
  select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'IQ'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Sindyan%', '%SPM%Baghdad%', '%Sindyan%'),
  ('%Shumookh%', '%Shomokh%', '%Shumookh%'),
  ('%Basra Paper%', '%Basrah Paper%', '%Basra Paper%'),
  ('%Maysan Paper%', '%Maisan Paper%', '%Maysan%'),
  ('%Narjis%', '%Narjis Factory%', '%Narjis%')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'IQ'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Sindyan%', '%SPM%Baghdad%', '%Sindyan%',
   $pj${"owner": "Al Sindyan Paper Mill", "priority": 1, "products": "Facial, toilet, kitchen towel and napkin base paper", "grades": ["Tissue"], "capacity_split": [{"label": "65 t/day x 320 days (calculated)", "value_t": 20800}], "pitch": "Tissue FCC at 3 / 5 / 7 pct using MBG tissue data", "approach": "First Iraq contact. Confirm furnish (virgin versus recycled) and the ACACIA relationship.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Shumookh%', '%Shomokh%', '%Shumookh%',
   $pj${"owner": "Al Shumookh group", "priority": 2, "products": "Fluting 80-185 gsm, testliner, kraft liner and white-top liner 115-200 gsm (planned), tissue line project", "grades": ["Fluting", "Testliner", "White-top liner", "Tissue"], "capacity_split": [{"label": "Packaging phase 1, 500 t/day x 330 (planned)", "value_t": 165000}, {"label": "Tissue project 70 t/day x 330 (planned)", "value_t": 23100}], "pitch": "Tissue line first (5 pct FCC), packaging later with strength and drainage trials", "approach": "Check start-up status of both lines. White-top liner surface ply is the only packaging grade worth an early look.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Basra Paper%', '%Basrah Paper%', '%Basra Paper%',
   $pj${"owner": "Iraqi state", "products": "To confirm", "approach": "Only once rehabilitation is contracted and grades are known.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Maysan Paper%', '%Maisan Paper%', '%Maysan%',
   $pj${"owner": "State Company for Paper Manufacture", "products": "To confirm", "capacity_split": [{"label": "Rehabilitation target", "value_t": 57000}], "approach": "Confirm grades before any FCC estimate.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Narjis%', '%Narjis Factory%', '%Narjis%',
   $pj${"owner": "Narjis Factory", "products": "Tissue", "approach": "Confirm own paper machine.", "checked_at": "2026-10-14"}$pj$::jsonb)
  ) as v(name_like, alt_like, owner_like, plant)
) m
where mp.party_id = m.id;

-- ---------- 5) VERIFY ----------
with v(name_like, alt_like, owner_like) as (values
  ('%Sindyan%', '%SPM%Baghdad%', '%Sindyan%'),
  ('%Shumookh%', '%Shomokh%', '%Shumookh%'),
  ('%Basra Paper%', '%Basrah Paper%', '%Basra Paper%'),
  ('%Maysan Paper%', '%Maisan Paper%', '%Maysan%'),
  ('%Narjis%', '%Narjis Factory%', '%Narjis%')
)
select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_like) as name,
       case when p.source = 'iraq_update_20261014' then 'added now' when p.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from v
left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'IQ'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1)
left join app.paper_mill_profile mp on mp.party_id = p.id
union all
select 'filler', p.party_name,
       case when p.source = 'iraq_update_20261014' then 'added now' else 'already there' end, '-',
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ilike '%White Shield%' or p.party_name ilike '%Noor Al Shams%' or p.party_name ilike '%Al Azm%' or p.party_name ilike '%Basmat Al-Haram%')
union all
select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', '-'
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and l.extra_data ->> 'batch' = 'iraq_update_20261014'
order by 1, 4, 2;
