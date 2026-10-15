-- ============================================================
-- seed_20261015e_australia_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Australia update (reports 2026-10). Introduction -> intro_ko / intro_en
-- (only when empty), detail -> notes once with 'AU check 2026-10-15',
-- plant data -> Mill profile card. Already in URM: Visy, Opal (group rows).
--
-- 1) Fillers if missing: Omya Australia (Bathurst + historical sites),
--    Imerys Burnie (historical - Burnie mill closed 2010).
-- 2) Mills if missing + plant blocks, priority 1-6: Boyer (260 kt printing
--    grades, copy paper 2026), ABC Tissue, Arbex Millicent, Solaris Paper,
--    Visy Tumut (680 kt kraftliner), Opal Botany (420 kt recycled).
--    context, match only: Opal Maryvale (white paper stopped 2023), Encore.
--    FCC scenario only for Boyer. No supply links.
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
       v.party_name, 'AU', v.region, v.city, v.website, 'active', 'australia_update_20261015',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('Omya Australia', '%Omya%Australia%', 'New South Wales', 'Bathurst', 'https://www.omya.com', 'Omya 의 호주 법인. Bathurst(NSW, 622 Vale Road) 대리석 GCC 가공, 과거 Moss Vale·Bajool·Geelong(건식·습식 GCC) 시설.', 'Omya Australia - GCC processing at 622 Vale Road, Bathurst NSW (marble, high brightness), historically also Moss Vale (dry GCC for paper), Bajool QLD (high-white marble) and Geelong VIC (60 pct dry, 40 pct wet GCC).', 'AU check 2026-10-15: which sites still run, paper-grade output and paper customers to confirm - Geelong wet GCC history matters most for FCC. Royalty licensee at Omya HQ level. No paper PCC plant found in Australia.'),
  ('Imerys Minerals Australia - Burnie (historical)', '%Imerys%Australia%', 'Tasmania', 'Burnie', null, 'Imerys Minerals Australia 의 Burnie GCC 공장(과거, 연 7만 t, 말레이시아 Ipoh 대리석 수입) — 인접 Burnie 제지공장은 2010-06 폐쇄.', 'Imerys Minerals Australia - former GCC plant next to the Burnie paper mill, Tasmania (about 70,000 t/yr filler and coating GCC, imported Ipoh marble feed). The Burnie mill closed 2010-06.', 'AU check 2026-10-15: current status of the GCC plant not confirmed - likely closed or repurposed with its only customer gone. History only. Sibelco Australia (no paper plant found) and MTI Australia (non-paper sites) not added.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
);

-- existing filler rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
    notes = case when coalesce(p.notes, '') ilike '%AU check 2026-10-15%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
    updated_at = now()
from (values
  ('Omya Australia', '%Omya%Australia%', 'New South Wales', 'Bathurst', 'https://www.omya.com', 'Omya 의 호주 법인. Bathurst(NSW, 622 Vale Road) 대리석 GCC 가공, 과거 Moss Vale·Bajool·Geelong(건식·습식 GCC) 시설.', 'Omya Australia - GCC processing at 622 Vale Road, Bathurst NSW (marble, high brightness), historically also Moss Vale (dry GCC for paper), Bajool QLD (high-white marble) and Geelong VIC (60 pct dry, 40 pct wet GCC).', 'AU check 2026-10-15: which sites still run, paper-grade output and paper customers to confirm - Geelong wet GCC history matters most for FCC. Royalty licensee at Omya HQ level. No paper PCC plant found in Australia.'),
  ('Imerys Minerals Australia - Burnie (historical)', '%Imerys%Australia%', 'Tasmania', 'Burnie', null, 'Imerys Minerals Australia 의 Burnie GCC 공장(과거, 연 7만 t, 말레이시아 Ipoh 대리석 수입) — 인접 Burnie 제지공장은 2010-06 폐쇄.', 'Imerys Minerals Australia - former GCC plant next to the Burnie paper mill, Tasmania (about 70,000 t/yr filler and coating GCC, imported Ipoh marble feed). The Burnie mill closed 2010-06.', 'AU check 2026-10-15: current status of the GCC plant not confirmed - likely closed or repurposed with its only customer gone. History only. Sibelco Australia (no paper plant found) and MTI Australia (non-paper sites) not added.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
  and coalesce(p.source, '') <> 'australia_update_20261015';

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
       d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
from app.parties p
join (values
  ('Omya Australia', 'GCC producer', 'Omya Australia GCC - FCC partner priority 1', 'merchant', 'B', 'gcc'),
  ('Imerys Minerals Australia - Burnie (historical)', 'GCC producer', 'Historical Burnie GCC', 'satellite (on-site)', 'C', 'gcc')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'australia_update_20261015'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 2) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, intro_ko, intro_en, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'AU', v.region, v.city, v.website, 'active', 'australia_update_20261015',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('%Boyer%', '%Norske Skog%Boyer%', 'Boyer Corporation - Boyer Mill (Tasmania)', 'Tasmania', 'Boyer', 'https://www.boyercorporation.au', '태즈메이니아 Boyer 의 Boyer Corporation(2025-04 Norske Skog 에서 Boyer Capital 로 인수). 초지기 2대, 신문용지 약 14만 t + 경량코팅지 약 12만 t, 2026년 복사용지 진출.', 'Boyer Corporation, 1279 Boyer Road, Tasmania - bought by Boyer Capital (seller Norske Skog) in 2025-04, two paper machines on TMP, about 140,000 t newsprint and related grades plus 120,000 t LWC, entering copy and office paper in 2026.', 'AU check 2026-10-15: new sheeting and packing line commissioned early 2026, full output targeted 2026-07. Current PCC / GCC supplier not public. enquiry@boyercorporation.au, +61 3 6261 0111.'),
  ('%ABC Tissue%', '%ABC Tissue Products%', 'ABC Tissue Products (Wetherill Park)', 'New South Wales', 'Wetherill Park', 'https://www.abctissue.com', '호주 소유 티슈 제조사 ABC Tissue Products. 시드니 Wetherill Park(PM1)·브리즈번 Carole Park(티슈기 2대), 퍼스는 가공.', 'ABC Tissue Products (Australian-owned) - tissue machines at Wetherill Park, Sydney (PM1) and Carole Park, Brisbane (two machines), converting at Forrestfield, Perth - toilet, towel, napkin.', 'AU check 2026-10-15: machine-level capacity not public.'),
  ('%Millicent%', '%Arbex%', 'Arbex - Millicent Mill (South Australia)', 'South Australia', 'Millicent', 'https://www.arbex.com', 'Suzano 51%·Kimberly-Clark 49% 합작 Arbex(2026-07 출범)의 Millicent 티슈공장(1960년 가동, 약 400명).', 'Arbex Millicent Mill, South Australia - tissue mill since 1960, ex Kimberly-Clark Australia, part of Arbex (Suzano 51 / Kimberly-Clark 49, launched 2026-07-01, 22 mills in 14 countries), about 400 staff.', 'AU check 2026-10-15: restructuring under review (ABC News 2026-10-01). Capacity not public.'),
  ('%Solaris Paper%', '%Sorbent Paper%', 'Solaris Paper - Sorbent (Box Hill and Greystanes)', 'Victoria', 'Box Hill', 'https://www.solarispaper.com.au', 'Solaris Paper(Sorbent·Livi). 멜버른 Box Hill·시드니 Greystanes 티슈 원지 생산·가공, APP 전략 공급 파트너.', 'Solaris Paper / The Sorbent Paper Company - tissue base paper and converting at Box Hill (Melbourne) and Greystanes (Sydney), nine converting lines, strategic supply partner Asia Pulp and Paper (pulp, jumbo rolls, finished goods).', null),
  ('%Tumut%', '%Visy%Tumut%', 'Visy - Tumut Mill (NSW)', 'New South Wales', 'Tumut', 'https://www.visy.com.au', 'Visy 의 Tumut 통합 크라프트 펄프·제지공장(2001년 가동). 고강도 크라프트라이너(90~440 gsm) 연 68만 t 이상.', 'Visy Tumut Mill, NSW (since 2001) - integrated kraft pulp and paper, PM9 and PM10, high-strength kraftliner 90-440 gsm, over 680,000 t/yr (700,000 t approved).', 'AU check 2026-10-15: Visy runs eight machines in Australia, about 1.44 Mt/yr (about 760 kt recycled + 680 kt kraft): Smithfield PM3, PM6, Campbellfield PM4, PM5, Reservoir PM2, Gibson Island PM8 (AUD 30m upgrade 2025-09).'),
  ('%Botany%', '%Opal%Botany%', 'Opal - Botany Mill (NSW)', 'New South Wales', 'Botany', 'https://www.opalanz.com', 'Opal(Nippon Paper 계열)의 Botany 공장. B9(2013) 100% 재생 라이너·골심지 연 42만 t 이상.', 'Opal (Nippon Paper group) Botany Mill, NSW - B9 machine (2013), 100 pct recycled liner and corrugating medium, over 420,000 t/yr on OCC.', null)
) as v(name_like, alt_like, party_name, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AU'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
);

-- existing mill rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
    notes = case when m.notes is null or coalesce(p.notes, '') ilike '%AU check 2026-10-15%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
    updated_at = now()
from (
  select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AU'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Boyer%', '%Norske Skog%Boyer%', '%Boyer%', '태즈메이니아 Boyer 의 Boyer Corporation(2025-04 Norske Skog 에서 Boyer Capital 로 인수). 초지기 2대, 신문용지 약 14만 t + 경량코팅지 약 12만 t, 2026년 복사용지 진출.', 'Boyer Corporation, 1279 Boyer Road, Tasmania - bought by Boyer Capital (seller Norske Skog) in 2025-04, two paper machines on TMP, about 140,000 t newsprint and related grades plus 120,000 t LWC, entering copy and office paper in 2026.', 'AU check 2026-10-15: new sheeting and packing line commissioned early 2026, full output targeted 2026-07. Current PCC / GCC supplier not public. enquiry@boyercorporation.au, +61 3 6261 0111.'),
  ('%ABC Tissue%', '%ABC Tissue Products%', '%ABC Tissue%', '호주 소유 티슈 제조사 ABC Tissue Products. 시드니 Wetherill Park(PM1)·브리즈번 Carole Park(티슈기 2대), 퍼스는 가공.', 'ABC Tissue Products (Australian-owned) - tissue machines at Wetherill Park, Sydney (PM1) and Carole Park, Brisbane (two machines), converting at Forrestfield, Perth - toilet, towel, napkin.', 'AU check 2026-10-15: machine-level capacity not public.'),
  ('%Millicent%', '%Arbex%', '%Kimberly%', 'Suzano 51%·Kimberly-Clark 49% 합작 Arbex(2026-07 출범)의 Millicent 티슈공장(1960년 가동, 약 400명).', 'Arbex Millicent Mill, South Australia - tissue mill since 1960, ex Kimberly-Clark Australia, part of Arbex (Suzano 51 / Kimberly-Clark 49, launched 2026-07-01, 22 mills in 14 countries), about 400 staff.', 'AU check 2026-10-15: restructuring under review (ABC News 2026-10-01). Capacity not public.'),
  ('%Solaris Paper%', '%Sorbent Paper%', '%Solaris%', 'Solaris Paper(Sorbent·Livi). 멜버른 Box Hill·시드니 Greystanes 티슈 원지 생산·가공, APP 전략 공급 파트너.', 'Solaris Paper / The Sorbent Paper Company - tissue base paper and converting at Box Hill (Melbourne) and Greystanes (Sydney), nine converting lines, strategic supply partner Asia Pulp and Paper (pulp, jumbo rolls, finished goods).', null),
  ('%Tumut%', '%Visy%Tumut%', '%Visy%', 'Visy 의 Tumut 통합 크라프트 펄프·제지공장(2001년 가동). 고강도 크라프트라이너(90~440 gsm) 연 68만 t 이상.', 'Visy Tumut Mill, NSW (since 2001) - integrated kraft pulp and paper, PM9 and PM10, high-strength kraftliner 90-440 gsm, over 680,000 t/yr (700,000 t approved).', 'AU check 2026-10-15: Visy runs eight machines in Australia, about 1.44 Mt/yr (about 760 kt recycled + 680 kt kraft): Smithfield PM3, PM6, Campbellfield PM4, PM5, Reservoir PM2, Gibson Island PM8 (AUD 30m upgrade 2025-09).'),
  ('%Botany%', '%Opal%Botany%', '%Opal%', 'Opal(Nippon Paper 계열)의 Botany 공장. B9(2013) 100% 재생 라이너·골심지 연 42만 t 이상.', 'Opal (Nippon Paper group) Botany Mill, NSW - B9 machine (2013), 100 pct recycled liner and corrugating medium, over 420,000 t/yr on OCC.', null),
  ('%Maryvale%', '%Opal%Maryvale%', '%Opal%', 'Opal Maryvale 공장(빅토리아). 2023년 백색 복사용지(M5·M2) 생산 중단, M1·M3·M4 로 갈색 포장용지만 생산.', 'Opal Maryvale Mill, Victoria - white copy paper (M5, M2) stopped 2023 on wood supply loss, brown packaging on M1, M3, M4 continues.', null),
  ('%Encore Tissue%', '%Encore Tissue%', '%Encore%', '빅토리아 Laverton North 의 Encore Tissue.', 'Encore Tissue, Laverton North, Victoria.', null)
  ) as v(name_like, alt_like, owner_like, intro_ko, intro_en, notes)
) m
where p.id = m.id and coalesce(p.source, '') <> 'australia_update_20261015';

-- ---------- 4) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (
  select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AU'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Boyer%', '%Norske Skog%Boyer%', '%Boyer%'),
  ('%ABC Tissue%', '%ABC Tissue Products%', '%ABC Tissue%'),
  ('%Millicent%', '%Arbex%', '%Kimberly%'),
  ('%Solaris Paper%', '%Sorbent Paper%', '%Solaris%'),
  ('%Tumut%', '%Visy%Tumut%', '%Visy%'),
  ('%Botany%', '%Opal%Botany%', '%Opal%'),
  ('%Maryvale%', '%Opal%Maryvale%', '%Opal%'),
  ('%Encore Tissue%', '%Encore Tissue%', '%Encore%')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AU'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Boyer%', '%Norske Skog%Boyer%', '%Boyer%',
   $pj${"owner": "Boyer Capital", "priority": 1, "products": "Newsprint, improved newsprint, book paper, LWC, variable-data and copy paper", "grades": ["Copy paper", "LWC", "Book paper", "Newsprint"], "machines": 2, "capacity": {"value": 260000, "unit": "metric_t", "year": "Company figure (140 kt newsprint + 120 kt LWC)", "source": "boyercorporation.au"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.75, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 0.85, "fcc_share": 0.25, "fcc_loading": 0.2}, {"label": "Expanded", "utilization": 0.9, "fcc_share": 0.5, "fcc_loading": 0.25}], "note": "Planning scenarios on 260 kt printing-grade output (newsprint, book, LWC, copy), not orders. TMP furnish - FCC effect must be proven on the machine."}, "pitch": "New copy-paper grade - FCC for fibre saving and opacity while the recipe is still being set", "approach": "Lead Australian account. Australian-owned since 2025 - shorter decisions. Pair with Omya Australia as local producer.", "to_collect": ["Current PCC grade and on-site plant output, owner and operator", "Filler loading per grade, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%ABC Tissue%', '%ABC Tissue Products%', '%ABC Tissue%',
   $pj${"owner": "ABC Tissue Products", "priority": 2, "products": "Toilet tissue, towels, napkins, facial", "grades": ["Tissue"], "machines": 3, "pitch": "First commercial tissue trial using MBG low-grammage tissue data", "approach": "Find which machine runs which grade and any filler use.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Millicent%', '%Arbex%', '%Kimberly%',
   $pj${"owner": "Arbex (Suzano 51 / Kimberly-Clark 49)", "priority": 3, "products": "Toilet and facial tissue", "grades": ["Tissue"], "pitch": "Tissue proof that can roll out across Arbex mills", "approach": "Check decision path during restructuring. Ties to Kimberly-Clark Kluang (MY) and Israel.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Solaris Paper%', '%Sorbent Paper%', '%Solaris%',
   $pj${"owner": "Solaris Paper (APP partner)", "priority": 4, "products": "Toilet tissue, facial, towel (Sorbent, Livi)", "grades": ["Tissue"], "approach": "Trial in Australia, then a separate talk with APP technology - Solaris cannot commit APP mills.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Tumut%', '%Visy%Tumut%', '%Visy%',
   $pj${"owner": "Visy Industries", "priority": 5, "products": "Kraftliner", "grades": ["Kraftliner"], "machines": 2, "capacity_split": [{"label": "Tumut output", "value_t": 680000}, {"label": "Visy Australia total (approx.)", "value_t": 1440000}], "approach": "Strength-critical liner - only after a packaging-grade FCC is proven. Gibson Island (new grades) is the better first Visy trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Botany%', '%Opal%Botany%', '%Opal%',
   $pj${"owner": "Opal (Nippon Paper)", "priority": 6, "products": "Recycled liner and corrugating medium", "grades": ["Testliner", "Medium"], "capacity_split": [{"label": "Company figure (over)", "value_t": 420000}], "approach": "Packaging-grade FCC first - strength, retention, ash.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Maryvale%', '%Opal%Maryvale%', '%Opal%',
   $pj${"owner": "Opal (Nippon Paper)", "products": "Brown kraft packaging (white paper stopped 2023)", "approach": "No white-paper filler demand now - packaging FCC only, later.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Encore Tissue%', '%Encore Tissue%', '%Encore%',
   $pj${"owner": "Encore Tissue", "products": "Tissue products", "approach": "Confirm own base-paper making.", "checked_at": "2026-10-14"}$pj$::jsonb)
  ) as v(name_like, alt_like, owner_like, plant)
) m
where mp.party_id = m.id;

-- ---------- 5) VERIFY ----------
with v(name_like, alt_like, owner_like) as (values
  ('%Boyer%', '%Norske Skog%Boyer%', '%Boyer%'),
  ('%ABC Tissue%', '%ABC Tissue Products%', '%ABC Tissue%'),
  ('%Millicent%', '%Arbex%', '%Kimberly%'),
  ('%Solaris Paper%', '%Sorbent Paper%', '%Solaris%'),
  ('%Tumut%', '%Visy%Tumut%', '%Visy%'),
  ('%Botany%', '%Opal%Botany%', '%Opal%'),
  ('%Maryvale%', '%Opal%Maryvale%', '%Opal%'),
  ('%Encore Tissue%', '%Encore Tissue%', '%Encore%')
)
select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_like) as name,
       case when p.source = 'australia_update_20261015' then 'added now' when p.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from v
left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'AU'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1)
left join app.paper_mill_profile mp on mp.party_id = p.id
union all
select 'filler', p.party_name,
       case when p.source = 'australia_update_20261015' then 'added now' else 'already there' end, '-',
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ilike '%Omya%Australia%' or p.party_name ilike '%Imerys%Australia%')
union all
select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', '-'
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and l.extra_data ->> 'batch' = 'australia_update_20261015'
order by 1, 4, 2;
