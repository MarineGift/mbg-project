-- ============================================================
-- seed_20261014z_jordan_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Jordan update (reports 2026-10). Introduction -> intro_ko / intro_en
-- (only when empty), detail -> notes once with 'JO check 2026-10-14',
-- plant data -> Mill profile card.
--
-- 1) Fillers if missing: Manaseer (350 kt+), GCCI (250 kt), Jordan Minerals
--    (paper superfine grades), Jordan Carbonate (Omya JV 2006), Petra,
--    ILCCMCo (PCC claimed - to verify). Global Polymer skipped.
-- 2) Mills if missing + plant blocks, priority 1-3: Sanabel Al Ataa (new
--    tissue PM1 + PM2, 47 kt), Al Snobar (Fine, 54 kt), Al Keena (Fine,
--    30 kt). context: Jordan Paper and Cardboard (in liquidation).
--    Not added: NIC (liquidated 2003), Al Hourani, Perfect Printing
--    (converters).
--    No FCC scenarios, no supply links (no mill-filler pair confirmed).
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
       v.party_name, 'JO', v.region, v.city, v.website, 'active', 'jordan_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('Manaseer Carbonate', '%Manaseer%', 'Karak', 'Qatrana', 'https://www.manaseer-ic.com', 'Manaseer Industrial Complex 의 탄산칼슘 사업(2017년 생산 개시, Qatrana 공장). 비코팅·코팅·과립 GCC, 연 35만 t 초과, 제지 용도 명시.', 'Manaseer Carbonate (Manaseer Industrial Complex), production since 2017 at Qatrana - natural, coated and granulated GCC (MCMCarb), over 350,000 t/yr, paper among uses.', 'JO check 2026-10-14: MCMCarb Natural 3.5-200 um, Coated 3.5-30 um, Granulates 0.1-3 mm (ranges, not D50). Earlier note mentions lines 1 and 2 over 1 Mt total. Paper customers and slurry capability unknown. HQ King Abdullah II St, 8th Circle, Amman, info@manaseer-ic.com, +962 6 580 0600.'),
  ('Global Calcium Carbonate Industries (GCCI)', '%Global Calcium Carbonate%', 'Amman', 'Amman', 'https://www.gccjo.com', '2010년 설립 Global Calcium Carbonate Industries. 2022년 가공시설 가동, 연 최대 25만 t, 원료 순도 99.5% 이상, 제지 충전·코팅 명시.', 'Global Calcium Carbonate Industries (founded 2010, quarrying 2015, processing plant 2022) - up to 250,000 t/yr, 99.5 pct+ limestone, granules to d97 3.5 um, paper filler and coating named.', 'JO check 2026-10-14: over 15 Mt reserves (company). Dry processing - wet slurry not confirmed. 209 Wasfi Al Tal St, Amman, info@gccjo.com, +962 79 833 6762.'),
  ('Jordan Minerals Establishment (JME)', '%Jordan Minerals%', 'Amman', 'Amman', 'https://www.jordanminerals.com', '1980년대 초 설립 Jordan Minerals(JME). 미분쇄 천연 GCC, 제지용 초미분 JM1SFN·JM2SFN, 과거 연 35만 t 초과.', 'Jordan Minerals Establishment (early 1980s) - micronised natural GCC, superfine JM1SFN and JM2SFN listed for paper, over 350,000 t/yr in 2019 chamber data.', 'JO check 2026-10-14: coated grades (JM1SFC, JM2SFC) are for PVC and masterbatch. Request JM1SFN / JM2SFN samples for FCC tests. Union Professional Building, Shmeisani, Amman, +962 6 5602794.'),
  ('Jordan Carbonate Company', '%Jordan Carbonate%', 'Amman', 'Zezia', 'https://www.jordancarbonate.com', '1979년 설립 Jordan Carbonate(JorCal). Zezia·Al Hasa 거점 천연·처리 GCC, 2006년 Omya 와 합작.', 'Jordan Carbonate Company (founded 1979, JorCal) - natural and treated GCC at Zezia and Al Hasa, joint venture with Omya in 2006.', 'JO check 2026-10-14: 2015 ministry data lists paper among uses, current site stresses paint, plastics, construction. Current Omya stake and scope to confirm - check for existing technology restrictions. enquiries@jordancarbonate.com, +962 6 566 5517.'),
  ('Petra Calcium Carbonate (PCCC)', '%Petra Calcium%', 'Amman', 'Amman', 'https://www.petracc.com', '2003년 설립 Petra Calcium Carbonate. Qatranah 채광, 암만 공장 자동화 3라인, 천연·코팅 탄산칼슘, 레바논 등 수출.', 'Petra Calcium Carbonate Company (founded 2003) - Qatranah quarry, three automated lines in Amman, natural and coated calcium carbonate, exports incl. Lebanon.', 'JO check 2026-10-14: fine grades down to 8 um top cut, paper named for coarse grades - paper fine GCC not confirmed. info@petracc.com.'),
  ('Industrial Lime & Calcium Carbonate (ILCCMCo)', '%ILCCM%', 'Aqaba', 'Aqaba', 'https://www.ilccm.co', 'Rocks Group 의 ILCCMCo(아카바 산업단지). Al Hasa 광산, GCC·PCC·생석회·소석회 통합공정 소개.', 'Industrial Lime and Calcium Carbonate Manufacturing Co. (Rocks Group), Aqaba Industrial Zone - Al Hasa quarry (over 50 Mt), presents GCC, PCC, quick and hydrated lime with calcination, slaking and carbonation.', 'JO check 2026-10-14: site mixes schedules and facility pages - commercial PCC operation, capacity and customers NOT confirmed. Check first. info@ilccm.co.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
);

-- existing filler rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
    notes = case when coalesce(p.notes, '') ilike '%JO check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
    updated_at = now()
from (values
  ('Manaseer Carbonate', '%Manaseer%', 'Karak', 'Qatrana', 'https://www.manaseer-ic.com', 'Manaseer Industrial Complex 의 탄산칼슘 사업(2017년 생산 개시, Qatrana 공장). 비코팅·코팅·과립 GCC, 연 35만 t 초과, 제지 용도 명시.', 'Manaseer Carbonate (Manaseer Industrial Complex), production since 2017 at Qatrana - natural, coated and granulated GCC (MCMCarb), over 350,000 t/yr, paper among uses.', 'JO check 2026-10-14: MCMCarb Natural 3.5-200 um, Coated 3.5-30 um, Granulates 0.1-3 mm (ranges, not D50). Earlier note mentions lines 1 and 2 over 1 Mt total. Paper customers and slurry capability unknown. HQ King Abdullah II St, 8th Circle, Amman, info@manaseer-ic.com, +962 6 580 0600.'),
  ('Global Calcium Carbonate Industries (GCCI)', '%Global Calcium Carbonate%', 'Amman', 'Amman', 'https://www.gccjo.com', '2010년 설립 Global Calcium Carbonate Industries. 2022년 가공시설 가동, 연 최대 25만 t, 원료 순도 99.5% 이상, 제지 충전·코팅 명시.', 'Global Calcium Carbonate Industries (founded 2010, quarrying 2015, processing plant 2022) - up to 250,000 t/yr, 99.5 pct+ limestone, granules to d97 3.5 um, paper filler and coating named.', 'JO check 2026-10-14: over 15 Mt reserves (company). Dry processing - wet slurry not confirmed. 209 Wasfi Al Tal St, Amman, info@gccjo.com, +962 79 833 6762.'),
  ('Jordan Minerals Establishment (JME)', '%Jordan Minerals%', 'Amman', 'Amman', 'https://www.jordanminerals.com', '1980년대 초 설립 Jordan Minerals(JME). 미분쇄 천연 GCC, 제지용 초미분 JM1SFN·JM2SFN, 과거 연 35만 t 초과.', 'Jordan Minerals Establishment (early 1980s) - micronised natural GCC, superfine JM1SFN and JM2SFN listed for paper, over 350,000 t/yr in 2019 chamber data.', 'JO check 2026-10-14: coated grades (JM1SFC, JM2SFC) are for PVC and masterbatch. Request JM1SFN / JM2SFN samples for FCC tests. Union Professional Building, Shmeisani, Amman, +962 6 5602794.'),
  ('Jordan Carbonate Company', '%Jordan Carbonate%', 'Amman', 'Zezia', 'https://www.jordancarbonate.com', '1979년 설립 Jordan Carbonate(JorCal). Zezia·Al Hasa 거점 천연·처리 GCC, 2006년 Omya 와 합작.', 'Jordan Carbonate Company (founded 1979, JorCal) - natural and treated GCC at Zezia and Al Hasa, joint venture with Omya in 2006.', 'JO check 2026-10-14: 2015 ministry data lists paper among uses, current site stresses paint, plastics, construction. Current Omya stake and scope to confirm - check for existing technology restrictions. enquiries@jordancarbonate.com, +962 6 566 5517.'),
  ('Petra Calcium Carbonate (PCCC)', '%Petra Calcium%', 'Amman', 'Amman', 'https://www.petracc.com', '2003년 설립 Petra Calcium Carbonate. Qatranah 채광, 암만 공장 자동화 3라인, 천연·코팅 탄산칼슘, 레바논 등 수출.', 'Petra Calcium Carbonate Company (founded 2003) - Qatranah quarry, three automated lines in Amman, natural and coated calcium carbonate, exports incl. Lebanon.', 'JO check 2026-10-14: fine grades down to 8 um top cut, paper named for coarse grades - paper fine GCC not confirmed. info@petracc.com.'),
  ('Industrial Lime & Calcium Carbonate (ILCCMCo)', '%ILCCM%', 'Aqaba', 'Aqaba', 'https://www.ilccm.co', 'Rocks Group 의 ILCCMCo(아카바 산업단지). Al Hasa 광산, GCC·PCC·생석회·소석회 통합공정 소개.', 'Industrial Lime and Calcium Carbonate Manufacturing Co. (Rocks Group), Aqaba Industrial Zone - Al Hasa quarry (over 50 Mt), presents GCC, PCC, quick and hydrated lime with calcination, slaking and carbonation.', 'JO check 2026-10-14: site mixes schedules and facility pages - commercial PCC operation, capacity and customers NOT confirmed. Check first. info@ilccm.co.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
  and coalesce(p.source, '') <> 'jordan_update_20261014';

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
       d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
from app.parties p
join (values
  ('Manaseer Carbonate', 'GCC producer', 'Jordan large GCC - FCC partner priority 1', 'merchant', 'B', 'gcc'),
  ('Global Calcium Carbonate Industries (GCCI)', 'GCC producer', 'Jordan GCC with paper filler and coating grades', 'merchant', 'B', 'gcc'),
  ('Jordan Minerals Establishment (JME)', 'GCC producer', 'Jordan superfine paper GCC', 'merchant', 'B', 'gcc'),
  ('Jordan Carbonate Company', 'GCC producer', 'Jordan GCC with Omya JV history', 'merchant', 'C', 'gcc'),
  ('Petra Calcium Carbonate (PCCC)', 'GCC producer', 'Jordan GCC', 'merchant', 'C', 'gcc'),
  ('Industrial Lime & Calcium Carbonate (ILCCMCo)', 'PCC producer', 'Possible Jordan PCC - commissioning to verify', 'merchant', 'C', 'pcc')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'jordan_update_20261014'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 2) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, intro_ko, intro_en, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'JO', v.region, v.city, v.website, 'active', 'jordan_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('%Sanabel%', '%Sanabel Al Ataa%', 'Sanabel Al Ataa Paper & Cardboard (Al Qastal)', 'Amman', 'Al Qastal', 'https://www.sanabel.info', 'Al Khattab Industrial Group 의 Sanabel Al Ataa(2024-07 개장, 암만 Al Qastal). 재생 판지·포장원지·티슈 원지, 약 1억 JD 투자, 연 10만 t 이상 발표.', 'Sanabel Al Ataa for Paper and Cardboard Industries (Al Khattab Industrial Group), Al Qastal, Amman - opened 2024-07, about JD 100m, recycled board, packaging base paper and tissue, over 100,000 t/yr announced.', 'JO check 2026-10-14: Baosuo tissue PM1 (2025, 2.85 m, 1,600 m/min, 21,000 t) and PM2 (started 2026-10, 3.65 m, 26,000 t) per MET 2026-10-02. Also testliner, fluting, kraft, white-top liner, core board, plasterboard paper. Industry directory says 120,000 t - basis differs. Chairman Mahmoud Khattab. Contact per report info@sanabelataa.com, +962 79 292 0888.'),
  ('%Snobar%', '%Snober%', 'Al Snobar Hygienic Paper Mill - Fine (Jordan)', 'Amman', null, 'https://www.finehh.com', 'Fine Hygienic Holding 의 Al Snobar Hygienic Paper Mill. Valmet PM4(2007, 폭 약 5.4m, 2,000 m/min), 연 5.4만 t 티슈 원지.', 'Al Snobar Hygienic Paper Mill (Fine Hygienic Holding), Jordan - Valmet (ex-Metso) PM4 started 2007, about 5.4 m, 2,000 m/min, 54,000 t/yr tissue base paper.', 'JO check 2026-10-14: about EUR 70m project (2006). Contact per report +962 6 440 3001, alsnober@finehh.com. Fine group also runs Al Nakheel (UAE) and mills in Egypt.'),
  ('%Keena%', '%Al Kina%', 'Al Keena Hygienic Paper Mill - Fine (Jordan)', 'Amman', null, 'https://www.finehh.com', 'Fine Hygienic Holding 의 Al Keena Hygienic Paper Mill(1996 개장). Voith PM2(폭 3.67m, 1,650 m/min), 연 3만 t 티슈 원지.', 'Al Keena Hygienic Paper Mill (Fine Hygienic Holding, opened 1996), Jordan - Voith PM2, 3.67 m, 1,650 m/min, 30,000 t/yr tissue base paper.', 'JO check 2026-10-14: contact per report +962 6 440 3001, ALKEENA@finehh.com. Group HQ Building 84, Mohammad Ali Bdeir St, Abdoun, Amman, +962 6 465 2688.')
) as v(name_like, alt_like, party_name, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'JO'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
);

-- existing mill rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
    notes = case when m.notes is null or coalesce(p.notes, '') ilike '%JO check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
    updated_at = now()
from (
  select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'JO'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Sanabel%', '%Sanabel Al Ataa%', '%Sanabel%', 'Al Khattab Industrial Group 의 Sanabel Al Ataa(2024-07 개장, 암만 Al Qastal). 재생 판지·포장원지·티슈 원지, 약 1억 JD 투자, 연 10만 t 이상 발표.', 'Sanabel Al Ataa for Paper and Cardboard Industries (Al Khattab Industrial Group), Al Qastal, Amman - opened 2024-07, about JD 100m, recycled board, packaging base paper and tissue, over 100,000 t/yr announced.', 'JO check 2026-10-14: Baosuo tissue PM1 (2025, 2.85 m, 1,600 m/min, 21,000 t) and PM2 (started 2026-10, 3.65 m, 26,000 t) per MET 2026-10-02. Also testliner, fluting, kraft, white-top liner, core board, plasterboard paper. Industry directory says 120,000 t - basis differs. Chairman Mahmoud Khattab. Contact per report info@sanabelataa.com, +962 79 292 0888.'),
  ('%Snobar%', '%Snober%', '%Snobar%', 'Fine Hygienic Holding 의 Al Snobar Hygienic Paper Mill. Valmet PM4(2007, 폭 약 5.4m, 2,000 m/min), 연 5.4만 t 티슈 원지.', 'Al Snobar Hygienic Paper Mill (Fine Hygienic Holding), Jordan - Valmet (ex-Metso) PM4 started 2007, about 5.4 m, 2,000 m/min, 54,000 t/yr tissue base paper.', 'JO check 2026-10-14: about EUR 70m project (2006). Contact per report +962 6 440 3001, alsnober@finehh.com. Fine group also runs Al Nakheel (UAE) and mills in Egypt.'),
  ('%Keena%', '%Al Kina%', '%Keena%', 'Fine Hygienic Holding 의 Al Keena Hygienic Paper Mill(1996 개장). Voith PM2(폭 3.67m, 1,650 m/min), 연 3만 t 티슈 원지.', 'Al Keena Hygienic Paper Mill (Fine Hygienic Holding, opened 1996), Jordan - Voith PM2, 3.67 m, 1,650 m/min, 30,000 t/yr tissue base paper.', 'JO check 2026-10-14: contact per report +962 6 440 3001, ALKEENA@finehh.com. Group HQ Building 84, Mohammad Ali Bdeir St, Abdoun, Amman, +962 6 465 2688.'),
  ('%Jordan Paper & Cardboard%', '%Jordan Paper and Cardboard%', '%Jordan Paper%', '1973년 설립 자르카의 Jordan Paper & Cardboard Factories. 골판지 원지·판지·상자 — 2024-08 자발적 청산 개시.', 'Jordan Paper and Cardboard Factories (founded 1973), Zarqa - corrugating base paper, board and boxes - voluntary liquidation started 2024-08-14.', null)
  ) as v(name_like, alt_like, owner_like, intro_ko, intro_en, notes)
) m
where p.id = m.id and coalesce(p.source, '') <> 'jordan_update_20261014';

-- ---------- 4) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (
  select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'JO'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Sanabel%', '%Sanabel Al Ataa%', '%Sanabel%'),
  ('%Snobar%', '%Snober%', '%Snobar%'),
  ('%Keena%', '%Al Kina%', '%Keena%'),
  ('%Jordan Paper & Cardboard%', '%Jordan Paper and Cardboard%', '%Jordan Paper%')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'JO'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Sanabel%', '%Sanabel Al Ataa%', '%Sanabel%',
   $pj${"owner": "Al Khattab Industrial Group", "priority": 1, "products": "Virgin-pulp tissue jumbo rolls, testliner, fluting, white-top liner, core board, plasterboard paper", "grades": ["Tissue", "White-top liner", "Testliner"], "machines": 2, "capacity_split": [{"label": "Tissue PM1 (2025)", "value_t": 21000}, {"label": "Tissue PM2 (2026-10)", "value_t": 26000}, {"label": "Company total (announced)", "value_t": 100000}], "pitch": "New tissue machines on 100 pct virgin pulp - FCC pilot for pulp saving while settings are still being tuned", "approach": "First Jordan contact. Board grades only for white top - not brown liner or fluting.", "recent": [{"date": "2026-10", "text": "Second Baosuo tissue machine (PM2, 26,000 t/yr) started up (MET)"}], "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Snobar%', '%Snober%', '%Snobar%',
   $pj${"owner": "Fine Hygienic Holding", "priority": 2, "products": "Facial, toilet and towel tissue base paper", "grades": ["Tissue"], "machines": 1, "capacity_split": [{"label": "PM4", "value_t": 54000}], "pitch": "High-speed line proof - FCC run stability plus fibre saving", "approach": "Approach Fine at group level with Al Keena and Al Nakheel (UAE).", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Keena%', '%Al Kina%', '%Keena%',
   $pj${"owner": "Fine Hygienic Holding", "priority": 3, "products": "Tissue base paper", "grades": ["Tissue"], "machines": 1, "capacity_split": [{"label": "PM2", "value_t": 30000}], "approach": "Small additive trial on the existing line.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Jordan Paper & Cardboard%', '%Jordan Paper and Cardboard%', '%Jordan Paper%',
   $pj${"owner": "Jordan Paper and Cardboard Factories", "products": "Corrugating base paper, board, boxes", "approach": "Excluded - in liquidation since 2024-08 (SDC).", "checked_at": "2026-10-14"}$pj$::jsonb)
  ) as v(name_like, alt_like, owner_like, plant)
) m
where mp.party_id = m.id;

-- ---------- 5) VERIFY ----------
with v(name_like, alt_like, owner_like) as (values
  ('%Sanabel%', '%Sanabel Al Ataa%', '%Sanabel%'),
  ('%Snobar%', '%Snober%', '%Snobar%'),
  ('%Keena%', '%Al Kina%', '%Keena%'),
  ('%Jordan Paper & Cardboard%', '%Jordan Paper and Cardboard%', '%Jordan Paper%')
)
select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_like) as name,
       case when p.source = 'jordan_update_20261014' then 'added now' when p.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from v
left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'JO'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1)
left join app.paper_mill_profile mp on mp.party_id = p.id
union all
select 'filler', p.party_name,
       case when p.source = 'jordan_update_20261014' then 'added now' else 'already there' end, '-',
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ilike '%Manaseer%' or p.party_name ilike '%Global Calcium Carbonate%' or p.party_name ilike '%Jordan Minerals%' or p.party_name ilike '%Jordan Carbonate%' or p.party_name ilike '%Petra Calcium%' or p.party_name ilike '%ILCCM%')
union all
select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', '-'
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and l.extra_data ->> 'batch' = 'jordan_update_20261014'
order by 1, 4, 2;
