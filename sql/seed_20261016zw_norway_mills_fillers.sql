-- ============================================================
-- seed_20261016zw_norway_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Norway update (reports 2026-10-16).
-- 1) Fillers if missing (2): Omya Hustadmarmor, Brønnøy Kalk (raw marble).
-- 2) Mills if missing (6) + plant blocks, priority 1-6: Norske Skog
--    Saugbrugs, Hellefoss, Norske Skog Skogn, Vajda-Papir Drammen, Ranheim,
--    Nordic Paper Greåker. Context (4): pulp-only mills.
-- 3) app.country_markets NO row (priority medium).
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
           v.party_name, 'NO', v.region, v.city, v.website, 'active', 'norway_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('hustadmarmor|omya.*(norway|norge|elnesv)', 'Omya Hustadmarmor - Elnesvågen', 'Møre og Romsdal', 'Elnesvågen', null, 'Omya 그룹 노르웨이 GCC(1978 법인, Sjøvegen 69, Elnesvågen) — Hydrocarb(1979~) 분말·슬러리, 전용 탱커로 북유럽·중부유럽 제지사 공급, Knarrevik·Hammerfall 사업장. 2007 연 300만 t 초과. 2025 매출 약 13억 NOK.', 'Omya Hustadmarmor AS (Omya group, company 1978, org no 912 864 227), Sjøvegen 69, Elnesvågen (Hustadvika) - paper GCC powder and slurry (Hydrocarb since 1979) shipped by dedicated tankers to Nordic and central European mills, also sites at Knarrevik (Bergen) and Hammerfall (Nordland). Over 3 Mt/yr in a 2007 study. 2025 sales about NOK 1.3 bn, operating profit NOK 32.9 m. Marble supplied by Brønnøy Kalk.', 'NO check 2026-10-16: plant manager Trond Gunnar Moe Sollund, customer-service.no@omya.com, +47 71 26 77 00. Royalty licensee at Omya HQ level - FiberLean competes with FCC. No paper PCC plant found in Norway.'),
  ('br[oø]nn[oø]y kalk', 'Brønnøy Kalk - Velfjord', 'Nordland', 'Velfjord', null, 'Norsk Mineral 계열 — Akselberg(Velfjord) 방해석 대리석 노천광(1997~), 연 약 200만 t 채굴, 2단 파쇄 후 선박으로 Elnesvågen(Omya) 공급.', 'Brønnøy Kalk AS (Norsk Mineral group), Akselberg open pit at Velfjord (Brønnøy, Nordland) - calcite marble since 1997, about 2 Mt/yr mined, two-stage crushing and shipped to Omya Hustadmarmor at Elnesvågen (autonomous Volvo haulage).', 'NO check 2026-10-16: raw material only - 2 Mt is ore, not GCC (do not add to Omya output). Not added: Norsk Mineral (parent), Visnes Kalk, Naas, Langnes Marmorbrudd, Franzefoss, Sibelco Nordic.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%NO check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('hustadmarmor|omya.*(norway|norge|elnesv)', 'Omya Hustadmarmor - Elnesvågen', 'Møre og Romsdal', 'Elnesvågen', null, 'Omya 그룹 노르웨이 GCC(1978 법인, Sjøvegen 69, Elnesvågen) — Hydrocarb(1979~) 분말·슬러리, 전용 탱커로 북유럽·중부유럽 제지사 공급, Knarrevik·Hammerfall 사업장. 2007 연 300만 t 초과. 2025 매출 약 13억 NOK.', 'Omya Hustadmarmor AS (Omya group, company 1978, org no 912 864 227), Sjøvegen 69, Elnesvågen (Hustadvika) - paper GCC powder and slurry (Hydrocarb since 1979) shipped by dedicated tankers to Nordic and central European mills, also sites at Knarrevik (Bergen) and Hammerfall (Nordland). Over 3 Mt/yr in a 2007 study. 2025 sales about NOK 1.3 bn, operating profit NOK 32.9 m. Marble supplied by Brønnøy Kalk.', 'NO check 2026-10-16: plant manager Trond Gunnar Moe Sollund, customer-service.no@omya.com, +47 71 26 77 00. Royalty licensee at Omya HQ level - FiberLean competes with FCC. No paper PCC plant found in Norway.'),
  ('br[oø]nn[oø]y kalk', 'Brønnøy Kalk - Velfjord', 'Nordland', 'Velfjord', null, 'Norsk Mineral 계열 — Akselberg(Velfjord) 방해석 대리석 노천광(1997~), 연 약 200만 t 채굴, 2단 파쇄 후 선박으로 Elnesvågen(Omya) 공급.', 'Brønnøy Kalk AS (Norsk Mineral group), Akselberg open pit at Velfjord (Brønnøy, Nordland) - calcite marble since 1997, about 2 Mt/yr mined, two-stage crushing and shipped to Omya Hustadmarmor at Elnesvågen (autonomous Volvo haulage).', 'NO check 2026-10-16: raw material only - 2 Mt is ore, not GCC (do not add to Omya output). Not added: Norsk Mineral (parent), Visnes Kalk, Naas, Langnes Marmorbrudd, Franzefoss, Sibelco Nordic.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'norway_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Omya Hustadmarmor - Elnesvågen', 'GCC producer', 'Omya Europe GCC slurry hub - licensee (Omya HQ)', 'merchant', 'B', 'gcc'),
  ('Brønnøy Kalk - Velfjord', 'Carbonate raw material', 'Calcite marble for Omya - raw material', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'norway_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'NO', v.region, v.city, v.website, 'active', 'norway_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('saugbrugs', 'halden', 'norske skog', 'Norske Skog Saugbrugs - Halden', 'Østfold', 'Halden', null, 'Norske Skog Saugbrugs — SC 잡지용지 PM4·PM5 가동, PM6 2023 산사태 후 중단. 2026-10-07 PM6 재건 결정(최대 8.5억 NOK) — 크라프트라이너 30만 t 또는 SC 23만 t, 가동 후 PM4·PM5 영구 중단. 2025 매출 약 23.2억 NOK.', 'Norske Skog Saugbrugs AS, Halden - SC magazine paper on PM4 and PM5, PM6 stopped after the 2023 landslide. Rebuild decided 2026-10-07 (up to NOK 850 m): flexible TMP-based kraftliner up to 300,000 t/yr or SC about 230,000 t/yr, PM4 and PM5 to stop permanently once PM6 runs. 2025 sales about NOK 2.32 bn.', 'NO check 2026-10-16: design stage now - pitch FCC for the SC mode.'),
  ('hellefoss', 'hokksund', 'hellefoss', 'Hellefoss Book Paper - Hokksund', 'Buskerud', 'Hokksund', null, '1898년부터 제지 — 고벌크 서적용지(Snowbulk·Snowbright·Super Snowbright 50~90 g/m²) 연 약 5만 t, 3,750 mm·600 m/분, 가문비 기계펄프+표백 화학펄프 10~15%. 2025 매출 약 2.9억 NOK.', 'Hellefoss Book Paper AS (papermaking since 1898), Hellefossveien 113, Hokksund - bulky book paper Snowbulk, Snowbright, Super Snowbright (50-90 g/m2), about 50,000 t/yr, 3,750 mm wide at about 600 m/min, spruce mechanical pulp with 10-15 pct bleached chemical pulp. 2025 sales about NOK 292 m.', 'NO check 2026-10-16: filler may cut bulk - watch it. Mill manager Geir Harbu, geir.harbu@hellefoss.no, sales@hellefoss.no, +47 32 25 22 00.'),
  ('skogn', 'levanger|skogn', 'norske skog', 'Norske Skog Skogn - Levanger', 'Trøndelag', 'Skogn', null, 'Norske Skog Skogn — 신문용지 + PM1 서적용지(NOR Book) 전환 2026-04 완료, 최대 연 14만 t. 2025 매출 약 28.4억 NOK, 2026-09 신임 공장장 Mads Eikeland.', 'Norske Skog Skogn AS, Skogn (Levanger) - newsprint plus book paper NOR Book on PM1 after the conversion finished 2026-04 (up to 140,000 t/yr, swing with newsprint). 2025 sales about NOK 2.84 bn. New mill director Mads Eikeland (2026-09).', 'NO check 2026-10-16: mechanical-pulp grades are already opaque - check FCC gain.'),
  ('vajda', 'drammen', 'vajda', 'Vajda-Papir Scandinavia - Drammen', 'Buskerud', 'Drammen', null, '헝가리 Vajda 그룹 Drammen 티슈 원지 — 재생 저백색~버진 고품질. 그룹 14.5만 t 은 헝가리 포함. 2025 매출 약 5.2억 NOK.', 'Vajda-Papir Scandinavia AS (Vajda Papír group, Hungary), Drammen - tissue base paper, low-white recycled up to premium virgin grades. Group 145,000 t/yr includes Hungary. 2025 sales about NOK 522 m.', 'NO check 2026-10-16: Drammen capacity not public.'),
  ('ranheim', 'ranheim|trondheim', 'ranheim', 'Ranheim Paper & Board - Ranheim', 'Trøndelag', 'Ranheim', null, 'Trondheim Ranheim 종이·솔리드보드·포장재, 2025 매출 약 10.6억 NOK, 156명.', 'Ranheim Paper & Board AS, Peder Myhres veg 19, Ranheim (Trondheim) - paper, solid board and packaging, 2025 sales about NOK 1.06 bn, 156 staff (2026-09).', 'NO check 2026-10-16: strength-led recycled grades.'),
  ('nordic paper.*gre[aå]ker|gre[aå]ker', 'gre[aå]ker|sarpsborg', 'nordic paper', 'Nordic Paper Greåker', 'Østfold', 'Greåker', null, 'Nordic Paper Greåker — 천연 내유지(PFAS 무첨가, 베이킹페이퍼) 연 4.4만 t, PM1·PM4, 약 100명.', 'Nordic Paper Greåker Mill, Greåkerveien 129, Greåker - natural greaseproof paper without added PFAS (baking paper, food wraps, baking cups), 44,000 t/yr on PM1 and PM4, about 100 staff, mill manager Håvard Johannessen.', 'NO check 2026-10-16: greaseproof needs a closed sheet - limited fit.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%NO check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('saugbrugs', 'halden', 'norske skog', 'Norske Skog Saugbrugs — SC 잡지용지 PM4·PM5 가동, PM6 2023 산사태 후 중단. 2026-10-07 PM6 재건 결정(최대 8.5억 NOK) — 크라프트라이너 30만 t 또는 SC 23만 t, 가동 후 PM4·PM5 영구 중단. 2025 매출 약 23.2억 NOK.', 'Norske Skog Saugbrugs AS, Halden - SC magazine paper on PM4 and PM5, PM6 stopped after the 2023 landslide. Rebuild decided 2026-10-07 (up to NOK 850 m): flexible TMP-based kraftliner up to 300,000 t/yr or SC about 230,000 t/yr, PM4 and PM5 to stop permanently once PM6 runs. 2025 sales about NOK 2.32 bn.', 'NO check 2026-10-16: design stage now - pitch FCC for the SC mode.'),
  ('hellefoss', 'hokksund', 'hellefoss', '1898년부터 제지 — 고벌크 서적용지(Snowbulk·Snowbright·Super Snowbright 50~90 g/m²) 연 약 5만 t, 3,750 mm·600 m/분, 가문비 기계펄프+표백 화학펄프 10~15%. 2025 매출 약 2.9억 NOK.', 'Hellefoss Book Paper AS (papermaking since 1898), Hellefossveien 113, Hokksund - bulky book paper Snowbulk, Snowbright, Super Snowbright (50-90 g/m2), about 50,000 t/yr, 3,750 mm wide at about 600 m/min, spruce mechanical pulp with 10-15 pct bleached chemical pulp. 2025 sales about NOK 292 m.', 'NO check 2026-10-16: filler may cut bulk - watch it. Mill manager Geir Harbu, geir.harbu@hellefoss.no, sales@hellefoss.no, +47 32 25 22 00.'),
  ('skogn', 'levanger|skogn', 'norske skog', 'Norske Skog Skogn — 신문용지 + PM1 서적용지(NOR Book) 전환 2026-04 완료, 최대 연 14만 t. 2025 매출 약 28.4억 NOK, 2026-09 신임 공장장 Mads Eikeland.', 'Norske Skog Skogn AS, Skogn (Levanger) - newsprint plus book paper NOR Book on PM1 after the conversion finished 2026-04 (up to 140,000 t/yr, swing with newsprint). 2025 sales about NOK 2.84 bn. New mill director Mads Eikeland (2026-09).', 'NO check 2026-10-16: mechanical-pulp grades are already opaque - check FCC gain.'),
  ('vajda', 'drammen', 'vajda', '헝가리 Vajda 그룹 Drammen 티슈 원지 — 재생 저백색~버진 고품질. 그룹 14.5만 t 은 헝가리 포함. 2025 매출 약 5.2억 NOK.', 'Vajda-Papir Scandinavia AS (Vajda Papír group, Hungary), Drammen - tissue base paper, low-white recycled up to premium virgin grades. Group 145,000 t/yr includes Hungary. 2025 sales about NOK 522 m.', 'NO check 2026-10-16: Drammen capacity not public.'),
  ('ranheim', 'ranheim|trondheim', 'ranheim', 'Trondheim Ranheim 종이·솔리드보드·포장재, 2025 매출 약 10.6억 NOK, 156명.', 'Ranheim Paper & Board AS, Peder Myhres veg 19, Ranheim (Trondheim) - paper, solid board and packaging, 2025 sales about NOK 1.06 bn, 156 staff (2026-09).', 'NO check 2026-10-16: strength-led recycled grades.'),
  ('nordic paper.*gre[aå]ker|gre[aå]ker', 'gre[aå]ker|sarpsborg', 'nordic paper', 'Nordic Paper Greåker — 천연 내유지(PFAS 무첨가, 베이킹페이퍼) 연 4.4만 t, PM1·PM4, 약 100명.', 'Nordic Paper Greåker Mill, Greåkerveien 129, Greåker - natural greaseproof paper without added PFAS (baking paper, food wraps, baking cups), 44,000 t/yr on PM1 and PM4, about 100 staff, mill manager Håvard Johannessen.', 'NO check 2026-10-16: greaseproof needs a closed sheet - limited fit.'),
  ('follacell', null, 'follacell', null, null, 'NO check 2026-10-16: MM FollaCell CTMP pulp, Follafoss - context only.'),
  ('vafos', null, 'vafos', null, null, 'NO check 2026-10-16: Mechanical pulp, Kragerø - context only.'),
  ('rygene', null, 'rygene', null, null, 'NO check 2026-10-16: Mechanical pulp, Arendal - context only.'),
  ('borregaard', null, 'borregaard', null, null, 'NO check 2026-10-16: Specialty cellulose, Sarpsborg - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'norway_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('saugbrugs', 'halden', 'norske skog'),
  ('hellefoss', 'hokksund', 'hellefoss'),
  ('skogn', 'levanger|skogn', 'norske skog'),
  ('vajda', 'drammen', 'vajda'),
  ('ranheim', 'ranheim|trondheim', 'ranheim'),
  ('nordic paper.*gre[aå]ker|gre[aå]ker', 'gre[aå]ker|sarpsborg', 'nordic paper'),
  ('follacell', null, 'follacell'),
  ('vafos', null, 'vafos'),
  ('rygene', null, 'rygene'),
  ('borregaard', null, 'borregaard')
      ) as v(name_rx, city_rx, owner_rx)
    ) m
    where m.id is not null
      and not exists (select 1 from app.paper_mill_profile mp where mp.party_id = m.id);
    
update app.paper_mill_profile mp
    set extra_data = coalesce(mp.extra_data, '{}'::jsonb) || jsonb_build_object('plant', m.plant),
        main_products = coalesce(nullif(btrim(mp.main_products), ''), m.plant ->> 'products'),
        updated_at = now()
    from (
      select v.plant, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('saugbrugs', 'halden', 'norske skog',
   $pj${"owner": "Norske Skog", "priority": 1, "products": "SC magazine paper, future kraftliner", "grades": ["SC paper", "Kraftliner"], "capacity_split": [{"label": "PM6 plan - SC mode", "value_t": 230000}, {"label": "PM6 plan - kraftliner mode", "value_t": 300000}], "pitch": "FCC in SC grade on the rebuilt PM6", "approach": "Lead Norwegian account - design-stage timing, Omya Hustadmarmor nearby.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "recent": "PM6 rebuild decision 2026-10-07", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('hellefoss', 'hokksund', 'hellefoss',
   $pj${"owner": "Hellefoss", "priority": 2, "products": "Bulky book paper", "grades": ["Book paper"], "capacity": {"value": 50000, "unit": "metric_t", "year": "Company figure", "source": "hellefoss.com"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.1}], "note": "Report scenario - bulk must hold."}, "approach": "Early joint trial - FCC 3, 5, 10 pct vs reference.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('skogn', 'levanger|skogn', 'norske skog',
   $pj${"owner": "Norske Skog", "priority": 3, "products": "Newsprint, book paper (NOR Book)", "grades": ["Newsprint", "Book paper"], "capacity_split": [{"label": "PM1 NOR Book (swing)", "value_t": 140000}], "approach": "NOR Book fibre-saving trial.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "recent": "PM1 book-paper conversion 2026-04", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('vajda', 'drammen', 'vajda',
   $pj${"owner": "Vajda Papír", "priority": 4, "products": "Tissue base paper", "grades": ["Tissue"], "approach": "Recycled vs virgin tissue FCC 3-5 pct.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('ranheim', 'ranheim|trondheim', 'ranheim',
   $pj${"owner": "Ranheim", "priority": 5, "products": "Paper, solid board", "grades": ["Board"], "approach": "Strength-hold trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('nordic paper.*gre[aå]ker|gre[aå]ker', 'gre[aå]ker|sarpsborg', 'nordic paper',
   $pj${"owner": "Nordic Paper", "priority": 6, "products": "Greaseproof paper", "grades": ["Specialty paper"], "capacity": {"value": 44000, "unit": "metric_t", "year": "Company figure", "source": "nordic-paper.com"}, "approach": "Functional co-development only.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('follacell', null, 'follacell',
   $pj${"owner": "MM Group", "products": "MM FollaCell CTMP pulp, Follafoss", "approach": "Pulp only.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('vafos', null, 'vafos',
   $pj${"owner": "Vafos Pulp", "products": "Mechanical pulp, Kragerø", "approach": "Pulp only.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('rygene', null, 'rygene',
   $pj${"owner": "Rygene-Smith and Thommesen", "products": "Mechanical pulp, Arendal", "approach": "Pulp only.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('borregaard', null, 'borregaard',
   $pj${"owner": "Borregaard", "products": "Specialty cellulose, Sarpsborg", "approach": "Pulp only.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'NO', 'Norway', 'medium',
   $cm$Omya Hustadmarmor GCC hub (Elnesvågen) - Norske Skog Saugbrugs PM6 rebuild (2026-10), Skogn NOR Book, Hellefoss book paper, Vajda tissue$cm$,
   $cm$Norway is home to Omya Hustadmarmor, Europe's main paper GCC slurry hub (over 3 Mt/yr in 2007, tanker supply, marble by Brønnøy Kalk). Mills: Norske Skog Saugbrugs (SC paper, PM6 rebuild decided 2026-10-07 for kraftliner 300 kt or SC 230 kt), Skogn (newsprint plus NOR Book 140 kt since 2026-04), Hellefoss (bulky book paper 50 kt), Vajda-Papir Drammen tissue, Ranheim board, Nordic Paper Greåker greaseproof (44 kt). Pulp-only: FollaCell, Vafos, Rygene, Borregaard. No paper PCC plant found.$cm$,
   $cm${"fillers": "GCC: Omya Hustadmarmor (Elnesvågen, Knarrevik, Hammerfall). Raw marble: Brønnøy Kalk (2 Mt/yr ore). No PCC.", "mills": "Printing: Norske Skog Saugbrugs (SC) and Skogn (newsprint, NOR Book), Hellefoss (book). Tissue: Vajda-Papir Drammen. Board: Ranheim. Specialty: Nordic Paper Greåker. Pulp context: FollaCell, Vafos, Rygene, Borregaard.", "strategy": "Omya Hustadmarmor as producer via Omya HQ, early trial at Hellefoss, design-stage pitch for Saugbrugs PM6 SC mode, NOR Book at Skogn, tissue at Vajda.", "risks": "Omya FiberLean competition, PM6 mode not yet chosen, bulk loss on book paper.", "next_steps": ["Pitch FCC to Norske Skog for the Saugbrugs PM6 project", "Propose a Hellefoss trial"], "key_numbers": [{"label": "Omya Hustadmarmor 2025", "value": "about NOK 1.3 bn sales"}, {"label": "Saugbrugs PM6 decision", "value": "2026-10-07, up to NOK 850 m"}, {"label": "Report scenario", "value": "23,200-46,400 t FCC (5-10 pct of 464 kt)"}], "files": ["seed_20261016zw_norway_mills_fillers"]}$cm$::jsonb,
   $cm$Omya Hustadmarmor GCC 허브(Elnesvågen) — Norske Skog Saugbrugs PM6 재건(2026-10), Skogn NOR Book, Hellefoss 서적용지, Vajda 티슈$cm$,
   $cm$노르웨이에는 유럽 제지용 GCC 슬러리 허브 Omya Hustadmarmor(2007 연 300만 t 초과, 탱커 공급, Brønnøy Kalk 대리석). 제지: Norske Skog Saugbrugs(SC, 2026-10-07 PM6 재건 결정 — 라이너 30만 또는 SC 23만 t), Skogn(신문+NOR Book 14만 t, 2026-04), Hellefoss(고벌크 서적용지 5만 t), Vajda Drammen 티슈, Ranheim 판지, Nordic Paper Greåker 내유지(4.4만 t). 펄프 전용: FollaCell·Vafos·Rygene·Borregaard. 제지용 PCC 없음.$cm$,
   23200, 46400,
   $cm$Saugbrugs PM6(SC) 23만 + Skogn 14만 + Hellefoss 5만 + Greåker 4.4만 t × FCC 5~10% (보고서 시나리오, PM6 는 미가동)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('saugbrugs', 'halden', 'norske skog'),
  ('hellefoss', 'hokksund', 'hellefoss'),
  ('skogn', 'levanger|skogn', 'norske skog'),
  ('vajda', 'drammen', 'vajda'),
  ('ranheim', 'ranheim|trondheim', 'ranheim'),
  ('nordic paper.*gre[aå]ker|gre[aå]ker', 'gre[aå]ker|sarpsborg', 'nordic paper'),
  ('follacell', null, 'follacell'),
  ('vafos', null, 'vafos'),
  ('rygene', null, 'rygene'),
  ('borregaard', null, 'borregaard')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'norway_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'norway_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'hustadmarmor|omya.*(norway|norge|elnesv)' or p.party_name ~* 'br[oø]nn[oø]y kalk')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'NO'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'NO'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'NO'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'NO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    