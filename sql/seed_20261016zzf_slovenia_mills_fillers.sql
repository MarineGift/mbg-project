-- ============================================================
-- seed_20261016zzf_slovenia_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Slovenia update (reports 2026-10-16). Fixed generator.
-- Calcit guard is Slovenia-specific (the Bulgarian Calcit JSC row stays apart).
-- 1) Fillers if missing (3): Calcit d.o.o. Stahovica, IAK Kresnice,
--    InterCal Slovenija / Apnenec.
-- 2) Mills if missing (5) + plant blocks, priority 1-5: Goričane, Papirnica
--    Vevče, Paloma, MM Količevo, Radeče Papir Nova. Context (1): Vipap
--    Videm Krško (bankrupt 2026-02).
-- 3) app.country_markets SI row (priority medium).
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
           v.party_name, 'SI', v.region, v.city, v.website, 'active', 'slovenia_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('calcit.*(stahovica|slovenia|d.o.o|group)', 'Calcit d.o.o. - Stahovica', 'Central Slovenia', 'Stahovica', null, '유럽 제지용 GCC 2위(회사 발표 약 20%), 매출 약 80% 제지 — Stahovica 15 본사·공장·연구실, Gospić(HR, 2012 Calcit Lika)·Terneuzen(NL, Calcit Zeeland). HydroPlex·CalPlex·CoverPlex. 2025 매출 1.019억 유로. WIG Wietersdorfer 50%·CHL 50%.', 'Calcit d.o.o., Stahovica 15, Stahovica (Kamnik) - claims about 20 pct of European paper GCC filler (second largest), about 80 pct of sales to paper, dry and wet GCC with own quarry and lab, plants also at Gospić (Croatia, Calcit Lika, 2012, rail) and Terneuzen (Netherlands, Calcit Zeeland, port). Paper grades HydroPlex (filler and coating), CalPlex (filler, precoat, coat), CoverPlex (coating, kaolin replacement). Over 300 staff. 2025 sales EUR 101.9 m (net EUR 0.29 m). Owners WIG Wietersdorfer (AT) 50 pct and CHL d.o.o. 50 pct. Director Miha Kirn.', 'SI check 2026-10-16: supplied UPM Augsburg, Plattling and Ettringen (UPM supplier award 2017 - DE rows). Plant capacities not public. info@calcit.si, +386 1 8327 015. Independent paper GCC leader - FCC licence candidate 1 for Europe (check existing filler-partner NDAs first). Not the Bulgarian Calcit JSC.'),
  ('industrija apna kresnice|\miak\M', 'Industrija Apna Kresnice (IAK) - Kresnice', 'Central Slovenia', 'Kresnice', null, 'Kresnice 석회·광물 — 생석회, 탄산칼슘 충전제용 암석분말, 골재, calcium precipitate.', 'Industrija Apna Kresnice d.o.o., Kresnice 14 - lime, rock flour for carbonate fillers, aggregates and a calcium precipitate product.', 'SI check 2026-10-16: calcium precipitate is not confirmed paper PCC. info@iak.si.'),
  ('intercal slovenija|apnenec', 'InterCal Slovenija / Apnenec', 'Slovenia', null, null, 'Wietersdorfer 계열 InterCal Slovenija(생석회·소석회)·Apnenec(석회석·분말).', 'InterCal Slovenija (quicklime, hydrated lime) and Apnenec d.o.o. (industrial and agricultural limestone and powders), both WIG Wietersdorfer group - same owner as half of Calcit.', 'SI check 2026-10-16: PCC raw-material route only. No Slovenian paper PCC plant found.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%SI check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('calcit.*(stahovica|slovenia|d.o.o|group)', 'Calcit d.o.o. - Stahovica', 'Central Slovenia', 'Stahovica', null, '유럽 제지용 GCC 2위(회사 발표 약 20%), 매출 약 80% 제지 — Stahovica 15 본사·공장·연구실, Gospić(HR, 2012 Calcit Lika)·Terneuzen(NL, Calcit Zeeland). HydroPlex·CalPlex·CoverPlex. 2025 매출 1.019억 유로. WIG Wietersdorfer 50%·CHL 50%.', 'Calcit d.o.o., Stahovica 15, Stahovica (Kamnik) - claims about 20 pct of European paper GCC filler (second largest), about 80 pct of sales to paper, dry and wet GCC with own quarry and lab, plants also at Gospić (Croatia, Calcit Lika, 2012, rail) and Terneuzen (Netherlands, Calcit Zeeland, port). Paper grades HydroPlex (filler and coating), CalPlex (filler, precoat, coat), CoverPlex (coating, kaolin replacement). Over 300 staff. 2025 sales EUR 101.9 m (net EUR 0.29 m). Owners WIG Wietersdorfer (AT) 50 pct and CHL d.o.o. 50 pct. Director Miha Kirn.', 'SI check 2026-10-16: supplied UPM Augsburg, Plattling and Ettringen (UPM supplier award 2017 - DE rows). Plant capacities not public. info@calcit.si, +386 1 8327 015. Independent paper GCC leader - FCC licence candidate 1 for Europe (check existing filler-partner NDAs first). Not the Bulgarian Calcit JSC.'),
  ('industrija apna kresnice|\miak\M', 'Industrija Apna Kresnice (IAK) - Kresnice', 'Central Slovenia', 'Kresnice', null, 'Kresnice 석회·광물 — 생석회, 탄산칼슘 충전제용 암석분말, 골재, calcium precipitate.', 'Industrija Apna Kresnice d.o.o., Kresnice 14 - lime, rock flour for carbonate fillers, aggregates and a calcium precipitate product.', 'SI check 2026-10-16: calcium precipitate is not confirmed paper PCC. info@iak.si.'),
  ('intercal slovenija|apnenec', 'InterCal Slovenija / Apnenec', 'Slovenia', null, null, 'Wietersdorfer 계열 InterCal Slovenija(생석회·소석회)·Apnenec(석회석·분말).', 'InterCal Slovenija (quicklime, hydrated lime) and Apnenec d.o.o. (industrial and agricultural limestone and powders), both WIG Wietersdorfer group - same owner as half of Calcit.', 'SI check 2026-10-16: PCC raw-material route only. No Slovenian paper PCC plant found.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'slovenia_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Calcit d.o.o. - Stahovica', 'GCC producer', 'European paper GCC number 2 - FCC licence candidate 1', 'merchant', 'B', 'gcc'),
  ('Industrija Apna Kresnice (IAK) - Kresnice', 'Lime and carbonate producer', 'Lime and rock flour - raw material', 'merchant', 'C', 'pcc'),
  ('InterCal Slovenija / Apnenec', 'Lime producer', 'Lime - PCC raw material', 'merchant', 'C', 'pcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'slovenia_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'SI', v.region, v.city, v.website, 'active', 'slovenia_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('gori[cč]ane', 'medvode', 'gori[cč]ane', 'Goričane - Medvode', 'Central Slovenia', 'Medvode', null, '1740년부터 Goričane(Ladja 10, Medvode) — 고급 저평량 출판지·설명서용지·특수지(출판·제약·화장품).', 'Goričane, tovarna papirja Medvode d.d., Ladja 10, Medvode (papermaking since 1740) - fine lightweight publishing, leaflet and specialty papers for publishing, pharma and cosmetics.', 'SI check 2026-10-16: capacity and filler use not public. +386 1 582 34 00.'),
  ('vev[cč]e', 'ljubljana|dobrunje', 'vev[cč]e|brigl', 'Papirnica Vevče - Ljubljana', 'Central Slovenia', 'Ljubljana', null, 'Brigl & Bergmeister 계열 Papirnica Vevče(Papirniška pot 25) — 라벨지·유연포장 특수지, 신규 필름프레스. 그룹 2개 공장 약 20만 t(AT 포함).', 'Papirnica Vevče d.o.o. (Brigl and Bergmeister group), Papirniška pot 25, Ljubljana-Dobrunje - label and flexible-packaging papers, new film press. Group about 200,000 t/yr incl. the Austrian mill.', 'SI check 2026-10-16: Slovenian capacity not public. +386 1 587 74 52.'),
  ('paloma', 'sladki vrh', 'paloma|shp', 'Paloma - Sladki Vrh', 'Podravje', 'Sladki Vrh', null, 'SHP Group 계열 Paloma(Sladki Vrh 1) 위생용지 연 8.7만 t(그룹 13.9만 t), 2020 PS9, 2024 현대화. 보스니아 SHP Celex 와 같은 그룹.', 'Paloma d.d. (SHP Group), Sladki Vrh 1 - toilet tissue, kitchen towel, facial and parent reels, 87,000 t/yr (group about 139,000 t/yr, 4 sites, 46 countries), PS9 machine started 2020, modernisation finished 2024. Same group as SHP Celex (Banja Luka, BA).', 'SI check 2026-10-16: info@paloma.si.'),
  ('kol[iı][cč]evo', 'dom[zž]ale', 'kol[iı][cč]evo|\mmm\M|mayr', 'MM Količevo - Domžale', 'Central Slovenia', 'Domžale', null, 'MM Board & Paper Količevo(Papirniška cesta 1) BM3 연 30만 t — FBB·WLC·화이트탑 라이너(180~450 g/m²), 2023 현대화.', 'MM Količevo (MM Board and Paper), Papirniška cesta 1, Domžale - board machine BM3, 300,000 t/yr, FBB, WLC and white-top liner 180-450 g/m2, modernised 2023.', 'SI check 2026-10-16: kolicevo@mm.group.'),
  ('rade[cč]e', 'rade[cč]e', 'rade[cč]e', 'Radeče Papir Nova - Radeče', 'Lower Sava', 'Radeče', null, 'Radeče Papir Nova(Njivice 7) 보안용지·특수지, 2024 매출 약 5,110만 유로·190명.', 'Radeče Papir Nova d.o.o., Njivice 7, Radeče - security and specialty papers, 2024 sales about EUR 51.1 m, about 190 staff.', 'SI check 2026-10-16: strict qualification. info@radecepapir.si.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SI'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%SI check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SI'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('gori[cč]ane', 'medvode', 'gori[cč]ane', '1740년부터 Goričane(Ladja 10, Medvode) — 고급 저평량 출판지·설명서용지·특수지(출판·제약·화장품).', 'Goričane, tovarna papirja Medvode d.d., Ladja 10, Medvode (papermaking since 1740) - fine lightweight publishing, leaflet and specialty papers for publishing, pharma and cosmetics.', 'SI check 2026-10-16: capacity and filler use not public. +386 1 582 34 00.'),
  ('vev[cč]e', 'ljubljana|dobrunje', 'vev[cč]e|brigl', 'Brigl & Bergmeister 계열 Papirnica Vevče(Papirniška pot 25) — 라벨지·유연포장 특수지, 신규 필름프레스. 그룹 2개 공장 약 20만 t(AT 포함).', 'Papirnica Vevče d.o.o. (Brigl and Bergmeister group), Papirniška pot 25, Ljubljana-Dobrunje - label and flexible-packaging papers, new film press. Group about 200,000 t/yr incl. the Austrian mill.', 'SI check 2026-10-16: Slovenian capacity not public. +386 1 587 74 52.'),
  ('paloma', 'sladki vrh', 'paloma|shp', 'SHP Group 계열 Paloma(Sladki Vrh 1) 위생용지 연 8.7만 t(그룹 13.9만 t), 2020 PS9, 2024 현대화. 보스니아 SHP Celex 와 같은 그룹.', 'Paloma d.d. (SHP Group), Sladki Vrh 1 - toilet tissue, kitchen towel, facial and parent reels, 87,000 t/yr (group about 139,000 t/yr, 4 sites, 46 countries), PS9 machine started 2020, modernisation finished 2024. Same group as SHP Celex (Banja Luka, BA).', 'SI check 2026-10-16: info@paloma.si.'),
  ('kol[iı][cč]evo', 'dom[zž]ale', 'kol[iı][cč]evo|\mmm\M|mayr', 'MM Board & Paper Količevo(Papirniška cesta 1) BM3 연 30만 t — FBB·WLC·화이트탑 라이너(180~450 g/m²), 2023 현대화.', 'MM Količevo (MM Board and Paper), Papirniška cesta 1, Domžale - board machine BM3, 300,000 t/yr, FBB, WLC and white-top liner 180-450 g/m2, modernised 2023.', 'SI check 2026-10-16: kolicevo@mm.group.'),
  ('rade[cč]e', 'rade[cč]e', 'rade[cč]e', 'Radeče Papir Nova(Njivice 7) 보안용지·특수지, 2024 매출 약 5,110만 유로·190명.', 'Radeče Papir Nova d.o.o., Njivice 7, Radeče - security and specialty papers, 2024 sales about EUR 51.1 m, about 190 staff.', 'SI check 2026-10-16: strict qualification. info@radecepapir.si.'),
  ('vipap|videm kr[sš]ko', null, 'vipap|videm kr[sš]ko', null, null, 'SI check 2026-10-16: Printing, newsprint and packaging, Krško - stopped mid 2025-12, bankruptcy opened 2026-02-25, shares delisted 2026-05 - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'slovenia_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SI'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('gori[cč]ane', 'medvode', 'gori[cč]ane'),
  ('vev[cč]e', 'ljubljana|dobrunje', 'vev[cč]e|brigl'),
  ('paloma', 'sladki vrh', 'paloma|shp'),
  ('kol[iı][cč]evo', 'dom[zž]ale', 'kol[iı][cč]evo|\mmm\M|mayr'),
  ('rade[cč]e', 'rade[cč]e', 'rade[cč]e'),
  ('vipap|videm kr[sš]ko', null, 'vipap|videm kr[sš]ko')
      ) as v(name_rx, city_rx, owner_rx)
    ) m
    where m.id is not null
      and not exists (select 1 from app.paper_mill_profile mp where mp.party_id = m.id);
    
update app.paper_mill_profile mp
    set extra_data = coalesce(mp.extra_data, '{}'::jsonb) || jsonb_build_object('plant',
          case when m.ctx then m.plant || coalesce(mp.extra_data -> 'plant', '{}'::jsonb)  -- context row: keep existing keys
               else m.plant end),
        main_products = coalesce(nullif(btrim(mp.main_products), ''), m.plant ->> 'products'),
        updated_at = now()
    from (
      select v.plant, v.ctx, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SI'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('gori[cč]ane', 'medvode', 'gori[cč]ane', false,
   $pj${"owner": "Goričane", "priority": 1, "products": "Lightweight publishing, leaflet and specialty paper", "grades": ["UWF", "Specialty paper"], "pitch": "Calcit + Goričane + MBG trial", "approach": "Lead Slovenian account.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('vev[cč]e', 'ljubljana|dobrunje', 'vev[cč]e|brigl', false,
   $pj${"owner": "Brigl and Bergmeister", "priority": 2, "products": "Label and flexible packaging paper", "grades": ["Specialty paper"], "approach": "Opacity and surface trial - link with the Austrian mill.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('paloma', 'sladki vrh', 'paloma|shp', false,
   $pj${"owner": "SHP Group", "priority": 3, "products": "Tissue and parent reels", "grades": ["Tissue"], "capacity": {"value": 87000, "unit": "metric_t", "year": "Company figure", "source": "paloma.si"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Tissue trial range."}, "approach": "SHP group tissue trial with Banja Luka.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('kol[iı][cč]evo', 'dom[zž]ale', 'kol[iı][cč]evo|\mmm\M|mayr', false,
   $pj${"owner": "MM Group", "priority": 4, "products": "FBB, WLC, white-top liner", "grades": ["FBB", "WLC", "White-top liner"], "machines": 1, "capacity": {"value": 300000, "unit": "metric_t", "year": "Company figure (BM3)", "source": "mm.group"}, "approach": "Middle-ply and white-top trial - bulk and stiffness kept. Link with MM Kotkamills (FI).", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('rade[cč]e', 'rade[cč]e', 'rade[cč]e', false,
   $pj${"owner": "Radeče Papir Nova", "priority": 5, "products": "Security and specialty paper", "grades": ["Security paper", "Specialty paper"], "approach": "Specialty R&D test.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('vipap|videm kr[sš]ko', null, 'vipap|videm kr[sš]ko', true,
   $pj${"owner": "Vipap Videm Krško", "products": "Printing, newsprint and packaging, Krško - stopped mid 2025-12, bankruptcy opened 2026-02-25, shares delisted 2026-05", "approach": "Bankrupt - asset sale only.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'SI', 'Slovenia', 'medium',
   $cm$Calcit (European paper GCC number 2, about 20 pct) HQ at Stahovica - Goričane, Vevče specialty, Paloma tissue (87 kt), MM Količevo board (300 kt) - Vipap bankrupt$cm$,
   $cm$Slovenia is home to Calcit, which claims about 20 pct of European paper GCC (80 pct of sales to paper) with plants at Stahovica, Gospić (HR) and Terneuzen (NL), owned 50/50 by WIG Wietersdorfer and CHL. Mills: Goričane (fine lightweight specialty), Papirnica Vevče (label and flexible packaging, Brigl and Bergmeister), Paloma (tissue 87 kt, SHP Group), MM Količevo (FBB and WLC, 300 kt), Radeče Papir Nova (security paper). Vipap Videm Krško went bankrupt in 2026-02. Lime at IAK and InterCal / Apnenec. No paper PCC plant.$cm$,
   $cm${"fillers": "Paper GCC: Calcit d.o.o. (Stahovica, plus Calcit Lika HR and Calcit Zeeland NL). Lime and rock flour: IAK Kresnice, InterCal Slovenija / Apnenec. No PCC.", "mills": "Specialty: Goričane, Papirnica Vevče, Radeče Papir Nova. Tissue: Paloma. Board: MM Količevo. Bankrupt: Vipap Videm Krško.", "strategy": "Calcit as the European GCC licence partner (Slovenia, Croatia, Netherlands plants, UPM customers). Three-way trial Calcit + Goričane + MBG, SHP group tissue (Paloma and SHP Celex), MM board group link.", "risks": "Check NDAs with existing filler partners before Calcit talks, Vipap closure.", "next_steps": ["Open licence talks with Calcit", "Propose a Goričane trial with Calcit GCC"], "key_numbers": [{"label": "Calcit 2025", "value": "EUR 101.9 m sales, about 20 pct European paper GCC (company)"}, {"label": "MM Količevo", "value": "300 kt (BM3)"}, {"label": "Paloma", "value": "87 kt tissue"}], "files": ["seed_20261016zzf_slovenia_mills_fillers"]}$cm$::jsonb,
   $cm$Calcit(유럽 제지용 GCC 2위, 약 20%) 본사 Stahovica — Goričane·Vevče 특수지, Paloma 티슈(8.7만 t), MM Količevo 판지(30만 t) — Vipap 파산$cm$,
   $cm$슬로베니아에는 유럽 제지용 GCC 약 20%(회사 발표, 매출 80% 제지)의 Calcit 본사 — 공장 Stahovica·Gospić(HR)·Terneuzen(NL), WIG Wietersdorfer·CHL 50:50. 제지: Goričane(고급 저평량 특수지), Vevče(라벨·유연포장, Brigl & Bergmeister), Paloma(티슈 8.7만 t, SHP), MM Količevo(FBB·WLC 30만 t), Radeče(보안용지). Vipap Krško 2026-02 파산. 석회 IAK·InterCal/Apnenec. 제지용 PCC 없음.$cm$,
   2610, 19350,
   $cm$하한 Paloma 8.7만 t × 3%, 상한 Paloma + Količevo 38.7만 t × 5%$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('gori[cč]ane', 'medvode', 'gori[cč]ane'),
  ('vev[cč]e', 'ljubljana|dobrunje', 'vev[cč]e|brigl'),
  ('paloma', 'sladki vrh', 'paloma|shp'),
  ('kol[iı][cč]evo', 'dom[zž]ale', 'kol[iı][cč]evo|\mmm\M|mayr'),
  ('rade[cč]e', 'rade[cč]e', 'rade[cč]e'),
  ('vipap|videm kr[sš]ko', null, 'vipap|videm kr[sš]ko')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'slovenia_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SI'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'slovenia_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'calcit.*(stahovica|slovenia|d.o.o|group)' or p.party_name ~* 'industrija apna kresnice|\miak\M' or p.party_name ~* 'intercal slovenija|apnenec')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'SI'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'SI'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'SI'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SI'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    