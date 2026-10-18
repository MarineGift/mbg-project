-- ============================================================
-- seed_20261016zzo_belarus_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Belarus update (reports 2026-10-16). Fixed generator.
-- SANCTIONS HOLD: rows are reference data, no plant priority, every memo
-- carries a sanctions-screening note. Shklov has Spartak and the newsprint
-- mill - owner regex keeps them apart.
-- 1) Fillers if missing (2): Krasnoselskstroymaterialy (chalk), SabiAn.
-- 2) Mills if missing (6) + plant blocks (no priority): Dobrush, Shklov
--    Newsprint, Spartak, Albertin, Svetlogorsk, Krasnaya Zvezda. Context (3).
-- 3) app.country_markets BY row (priority none).
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
           v.party_name, 'BY', v.region, v.city, v.website, 'active', 'belarus_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('krasnoselsk|красносельск', 'Krasnoselskstroymaterialy - Krasnoselsky', 'Grodno', 'Krasnoselsky', null, 'Belarusian Cement Company 계열 Krasnoselskstroymaterialy(Volkovysk) — 시멘트·건설용 석회·미세 과립 백악(자체 원료).', 'OJSC Krasnoselskstroymaterialy (Belarusian Cement Company), Krasnoselsky, Volkovysk district (Grodno) - cement, building lime and fine granulated chalk of its own deposit.', 'BY check 2026-10-16: no paper GCC line confirmed. SANCTIONS: screen owner, OFAC and EU lists, banking and export-control rules before any contact (US company). Not added: Krichevcementnoshifer, Belarusian Cement Plant (cement).'),
  ('sabian|сабиан', 'SabiAn (synthetic CaCO3 supply)', 'Belarus', null, null, 'SabiAn — 합성 탄산칼슘(PCC) 소개·공급, 제지 등 용도 명시, 신규 생산시설 관련 수요처 모집.', 'SabiAn - markets synthetic (precipitated) calcium carbonate for pharma, chemicals, building, paint, adhesives, plastics and paper, seeking Belarusian buyers for a new production facility.', 'BY check 2026-10-16: maker, plant location and status unknown. SANCTIONS: screen owner, OFAC and EU lists, banking and export-control rules before any contact (US company). BSTU (Minsk) published research on cationic-starch modified GCC for printing paper (2016).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%BY check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('krasnoselsk|красносельск', 'Krasnoselskstroymaterialy - Krasnoselsky', 'Grodno', 'Krasnoselsky', null, 'Belarusian Cement Company 계열 Krasnoselskstroymaterialy(Volkovysk) — 시멘트·건설용 석회·미세 과립 백악(자체 원료).', 'OJSC Krasnoselskstroymaterialy (Belarusian Cement Company), Krasnoselsky, Volkovysk district (Grodno) - cement, building lime and fine granulated chalk of its own deposit.', 'BY check 2026-10-16: no paper GCC line confirmed. SANCTIONS: screen owner, OFAC and EU lists, banking and export-control rules before any contact (US company). Not added: Krichevcementnoshifer, Belarusian Cement Plant (cement).'),
  ('sabian|сабиан', 'SabiAn (synthetic CaCO3 supply)', 'Belarus', null, null, 'SabiAn — 합성 탄산칼슘(PCC) 소개·공급, 제지 등 용도 명시, 신규 생산시설 관련 수요처 모집.', 'SabiAn - markets synthetic (precipitated) calcium carbonate for pharma, chemicals, building, paint, adhesives, plastics and paper, seeking Belarusian buyers for a new production facility.', 'BY check 2026-10-16: maker, plant location and status unknown. SANCTIONS: screen owner, OFAC and EU lists, banking and export-control rules before any contact (US company). BSTU (Minsk) published research on cationic-starch modified GCC for printing paper (2016).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'belarus_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Krasnoselskstroymaterialy - Krasnoselsky', 'Chalk and lime producer', 'Chalk raw material - sanctions screening first', 'merchant', 'C', 'gcc'),
  ('SabiAn (synthetic CaCO3 supply)', 'PCC supplier', 'PCC supply lead - maker to trace', 'merchant', 'C', 'pcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'belarus_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'BY', v.region, v.city, v.website, 'active', 'belarus_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('dobrush|geroy truda|добруш', 'dobrush|добруш', 'dobrush|geroy|wallpaper', 'Dobrush Paper Factory (Geroy Truda)', 'Gomel', 'Dobrush', null, 'Dobrush Geroy Truda(1870 설립, Belarusian Wallpaper Holding) — GC1·GC2 코팅 백판지 160~330 g/m², 비코팅 다층 판지, Fluting·Topliner, 벽지 원지. 신규 다층 판지 라인 설계 20만 t.', 'Dobrush Paper Factory Geroy Truda (founded 1870, Belarusian Wallpaper Holding), Dobrush (Gomel) - GC1 and GC2 coated boxboard 160-330 g/m2, uncoated multi-ply board, fluting and topliner, wallpaper base, cup board. New multi-ply board line designed for 200,000 t/yr.', 'BY check 2026-10-16: technical best fit in Belarus. SANCTIONS: screen owner, OFAC and EU lists, banking and export-control rules before any contact (US company).'),
  ('shklov newsprint|asnova|газетной', 'shklov|шклов', 'asnova|newsprint|gazet|газет', 'Shklov Newsprint Mill', 'Mogilev', 'Shklov', null, 'Shklov 신문용지 공장(1st Zavodskaya 9) — 신문·오프셋(50 g/m²)·장식 원지·포장·봉투용지.', 'RUE Shklov Newsprint Mill (Zavod gazetnoy bumagi), 1st Zavodskaya Street 9, Shklov - newsprint, offset paper (50 g/m2 exported 2025), decorative base paper (line 2015), packaging and envelope papers.', 'BY check 2026-10-16: info@asnova.by. SANCTIONS: screen owner, OFAC and EU lists, banking and export-control rules before any contact (US company).'),
  ('spartak|спартак', 'shklov|шклов', 'spartak|спартак', 'Spartak Paper Mill - Shklov', 'Mogilev', 'Shklov', null, 'Spartak(1898, Shklov) — 티슈 원지 16~38 g/m²(폐지·셀룰로오스), 화장지·냅킨·타월, 골판지·상자. 2026 완공 목표 원지 약 2.4만 t 신규 사업.', 'Spartak Paper Mill (1898), Shklov - tissue base paper 16-38 g/m2 (1-3 ply, crepe 5-25 pct, up to 2,800 mm) of recovered paper or pulp, toilet tissue, napkins, towels, plus corrugated board and boxes. New project about 24,000 t/yr base paper targeted for 2026.', 'BY check 2026-10-16: info@bfs.by. SANCTIONS: screen owner, OFAC and EU lists, banking and export-control rules before any contact (US company).'),
  ('albertin|альбертин', 'slonim|слоним', 'albertin|альбертин', 'Slonim Albertin', 'Grodno', 'Slonim', null, 'Slonim Albertin(1809 기원) — Fluting·포장·왁스지·코어보드·박스보드·골판지·티슈 제품.', 'Slonim Cardboard and Paper Plant Albertin (roots 1809), Slonim - fluting, wrapping and waxed papers, coreboard and boxboard, corrugated board and boxes, toilet tissue, napkins and towels.', 'BY check 2026-10-16: Marketing@albertin.by. SANCTIONS: screen owner, OFAC and EU lists, banking and export-control rules before any contact (US company).'),
  ('svetlogorsk|светлогорск', 'svetlogorsk|светлогорск', 'svetlogorsk|светлогорск', 'Svetlogorsk Pulp and Cardboard Mill', 'Gomel', 'Svetlogorsk', null, 'Svetlogorsk 펄프·판지(OJSC) — 화학펄프(표백 펄프 투자), 라이너·골판지원지·포장 원지.', 'OJSC Svetlogorsk Pulp and Cardboard Mill, Svetlogorsk (Gomel) - chemical pulp (bleached pulp investment), liner, containerboard and packaging base papers. Parent of Krasnaya Zvezda.', 'BY check 2026-10-16: strength-led. SANCTIONS: screen owner, OFAC and EU lists, banking and export-control rules before any contact (US company).'),
  ('krasnaya zvezda|red.?star|красная звезда', 'chashniki|чашник', 'zvezda|red.?star|svetlogorsk', 'Krasnaya Zvezda - Chashniki', 'Vitebsk', 'Chashniki', null, 'Krasnaya Zvezda(Chashniki, Svetlogorsk 자회사) Fluting·Testliner·골판지, 2013~2014 현대화.', 'Krasnaya Zvezda Paper Mill (Svetlogorsk subsidiary), Chashniki (Vitebsk) - fluting, testliner, corrugated board and boxes, machines modernised 2013-2014.', 'BY check 2026-10-16: +375 2133 28483. SANCTIONS: screen owner, OFAC and EU lists, banking and export-control rules before any contact (US company).')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%BY check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('dobrush|geroy truda|добруш', 'dobrush|добруш', 'dobrush|geroy|wallpaper', 'Dobrush Geroy Truda(1870 설립, Belarusian Wallpaper Holding) — GC1·GC2 코팅 백판지 160~330 g/m², 비코팅 다층 판지, Fluting·Topliner, 벽지 원지. 신규 다층 판지 라인 설계 20만 t.', 'Dobrush Paper Factory Geroy Truda (founded 1870, Belarusian Wallpaper Holding), Dobrush (Gomel) - GC1 and GC2 coated boxboard 160-330 g/m2, uncoated multi-ply board, fluting and topliner, wallpaper base, cup board. New multi-ply board line designed for 200,000 t/yr.', 'BY check 2026-10-16: technical best fit in Belarus. SANCTIONS: screen owner, OFAC and EU lists, banking and export-control rules before any contact (US company).'),
  ('shklov newsprint|asnova|газетной', 'shklov|шклов', 'asnova|newsprint|gazet|газет', 'Shklov 신문용지 공장(1st Zavodskaya 9) — 신문·오프셋(50 g/m²)·장식 원지·포장·봉투용지.', 'RUE Shklov Newsprint Mill (Zavod gazetnoy bumagi), 1st Zavodskaya Street 9, Shklov - newsprint, offset paper (50 g/m2 exported 2025), decorative base paper (line 2015), packaging and envelope papers.', 'BY check 2026-10-16: info@asnova.by. SANCTIONS: screen owner, OFAC and EU lists, banking and export-control rules before any contact (US company).'),
  ('spartak|спартак', 'shklov|шклов', 'spartak|спартак', 'Spartak(1898, Shklov) — 티슈 원지 16~38 g/m²(폐지·셀룰로오스), 화장지·냅킨·타월, 골판지·상자. 2026 완공 목표 원지 약 2.4만 t 신규 사업.', 'Spartak Paper Mill (1898), Shklov - tissue base paper 16-38 g/m2 (1-3 ply, crepe 5-25 pct, up to 2,800 mm) of recovered paper or pulp, toilet tissue, napkins, towels, plus corrugated board and boxes. New project about 24,000 t/yr base paper targeted for 2026.', 'BY check 2026-10-16: info@bfs.by. SANCTIONS: screen owner, OFAC and EU lists, banking and export-control rules before any contact (US company).'),
  ('albertin|альбертин', 'slonim|слоним', 'albertin|альбертин', 'Slonim Albertin(1809 기원) — Fluting·포장·왁스지·코어보드·박스보드·골판지·티슈 제품.', 'Slonim Cardboard and Paper Plant Albertin (roots 1809), Slonim - fluting, wrapping and waxed papers, coreboard and boxboard, corrugated board and boxes, toilet tissue, napkins and towels.', 'BY check 2026-10-16: Marketing@albertin.by. SANCTIONS: screen owner, OFAC and EU lists, banking and export-control rules before any contact (US company).'),
  ('svetlogorsk|светлогорск', 'svetlogorsk|светлогорск', 'svetlogorsk|светлогорск', 'Svetlogorsk 펄프·판지(OJSC) — 화학펄프(표백 펄프 투자), 라이너·골판지원지·포장 원지.', 'OJSC Svetlogorsk Pulp and Cardboard Mill, Svetlogorsk (Gomel) - chemical pulp (bleached pulp investment), liner, containerboard and packaging base papers. Parent of Krasnaya Zvezda.', 'BY check 2026-10-16: strength-led. SANCTIONS: screen owner, OFAC and EU lists, banking and export-control rules before any contact (US company).'),
  ('krasnaya zvezda|red.?star|красная звезда', 'chashniki|чашник', 'zvezda|red.?star|svetlogorsk', 'Krasnaya Zvezda(Chashniki, Svetlogorsk 자회사) Fluting·Testliner·골판지, 2013~2014 현대화.', 'Krasnaya Zvezda Paper Mill (Svetlogorsk subsidiary), Chashniki (Vitebsk) - fluting, testliner, corrugated board and boxes, machines modernised 2013-2014.', 'BY check 2026-10-16: +375 2133 28483. SANCTIONS: screen owner, OFAC and EU lists, banking and export-control rules before any contact (US company).'),
  ('goznak|гознак', null, 'goznak|гознак', null, null, 'BY check 2026-10-16: Security and document papers, Borisov - context only. SANCTIONS: screen owner, OFAC and EU lists, banking and export-control rules before any contact (US company).'),
  ('\mexclusive\M', null, '\mexclusive\M', null, null, 'BY check 2026-10-16: Hygiene paper products, Grodno - machine to confirm - context only. SANCTIONS: screen owner, OFAC and EU lists, banking and export-control rules before any contact (US company).'),
  ('pukhovichi|пуховичск', null, 'pukhovichi|пуховичск', null, null, 'BY check 2026-10-16: Board, Svetly Bor - context only. SANCTIONS: screen owner, OFAC and EU lists, banking and export-control rules before any contact (US company).')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'belarus_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('dobrush|geroy truda|добруш', 'dobrush|добруш', 'dobrush|geroy|wallpaper'),
  ('shklov newsprint|asnova|газетной', 'shklov|шклов', 'asnova|newsprint|gazet|газет'),
  ('spartak|спартак', 'shklov|шклов', 'spartak|спартак'),
  ('albertin|альбертин', 'slonim|слоним', 'albertin|альбертин'),
  ('svetlogorsk|светлогорск', 'svetlogorsk|светлогорск', 'svetlogorsk|светлогорск'),
  ('krasnaya zvezda|red.?star|красная звезда', 'chashniki|чашник', 'zvezda|red.?star|svetlogorsk'),
  ('goznak|гознак', null, 'goznak|гознак'),
  ('\mexclusive\M', null, '\mexclusive\M'),
  ('pukhovichi|пуховичск', null, 'pukhovichi|пуховичск')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('dobrush|geroy truda|добруш', 'dobrush|добруш', 'dobrush|geroy|wallpaper', false,
   $pj${"owner": "Belarusian Wallpaper Holding", "products": "Coated boxboard, wallpaper base", "grades": ["FBB", "WLC"], "capacity_split": [{"label": "New board line design", "value_t": 200000}], "approach": "Hold - sanctions screening first.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('shklov newsprint|asnova|газетной', 'shklov|шклов', 'asnova|newsprint|gazet|газет', false,
   $pj${"owner": "State", "products": "Newsprint, offset, decor base", "grades": ["Newsprint", "UWF", "Decor paper"], "approach": "Hold - sanctions screening first.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('spartak|спартак', 'shklov|шклов', 'spartak|спартак', false,
   $pj${"owner": "Spartak", "products": "Tissue base paper, corrugated", "grades": ["Tissue"], "capacity_split": [{"label": "New base-paper project (2026 target)", "value_t": 24000}], "approach": "Hold - sanctions screening first.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('albertin|альбертин', 'slonim|слоним', 'albertin|альбертин', false,
   $pj${"owner": "Albertin", "products": "Board, packaging paper, tissue", "grades": ["Board", "Tissue"], "approach": "Hold - sanctions screening first.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('svetlogorsk|светлогорск', 'svetlogorsk|светлогорск', 'svetlogorsk|светлогорск', false,
   $pj${"owner": "State", "products": "Pulp, liner, containerboard", "grades": ["Testliner", "Medium"], "approach": "Hold - sanctions screening first.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('krasnaya zvezda|red.?star|красная звезда', 'chashniki|чашник', 'zvezda|red.?star|svetlogorsk', false,
   $pj${"owner": "Svetlogorsk PCM", "products": "Fluting, testliner", "grades": ["Testliner", "Medium"], "approach": "Hold - sanctions screening first.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('goznak|гознак', null, 'goznak|гознак', true,
   $pj${"owner": "Goznak", "products": "Security and document papers, Borisov", "approach": "Hold - sanctions.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mexclusive\M', null, '\mexclusive\M', true,
   $pj${"owner": "Exclusive LLC", "products": "Hygiene paper products, Grodno - machine to confirm", "approach": "Hold - sanctions.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('pukhovichi|пуховичск', null, 'pukhovichi|пуховичск', true,
   $pj${"owner": "Pukhovichi Cardboard Factory", "products": "Board, Svetly Bor", "approach": "Hold - sanctions.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'BY', 'Belarus', 'none',
   $cm$Sanctions hold - Dobrush coated board, Shklov newsprint and offset, Spartak and Albertin tissue, Svetlogorsk liner - no paper PCC or GCC plant$cm$,
   $cm$Belarus has real paper machines - Dobrush Geroy Truda (GC1 and GC2 coated board, new 200 kt board line design), Shklov Newsprint (newsprint, offset, decor base), Spartak Shklov (tissue base, new 24 kt project), Slonim Albertin (board and tissue), Svetlogorsk PCM and its Krasnaya Zvezda mill (liner) - plus Goznak security paper. No paper PCC or GCC maker confirmed: Krasnoselskstroymaterialy has chalk, SabiAn markets PCC of unknown origin, BSTU researches modified GCC. Many firms are state-linked: all work is on hold pending US and EU sanctions screening, so no priority is set.$cm$,
   $cm${"fillers": "Chalk: Krasnoselskstroymaterialy. PCC lead: SabiAn (maker unknown). Research: BSTU (modified GCC, 2016). Not added: cement plants.", "mills": "Board: Dobrush, Svetlogorsk, Krasnaya Zvezda. Printing: Shklov Newsprint. Tissue: Spartak, Albertin. Context: Goznak, Exclusive, Pukhovichi.", "strategy": "No outreach until sanctions screening clears each counterparty. Keep as reference data only.", "risks": "US and EU sanctions, banking and export-control limits, state ownership.", "next_steps": ["Add BY to the sanction-country campaign exclusion list"], "key_numbers": [{"label": "Dobrush new board line", "value": "200 kt design"}, {"label": "Spartak new project", "value": "about 24 kt (2026 target)"}], "files": ["seed_20261016zzo_belarus_mills_fillers"]}$cm$::jsonb,
   $cm$제재 보류 — Dobrush 코팅 백판지, Shklov 신문·오프셋, Spartak·Albertin 티슈, Svetlogorsk 라이너 — 제지용 PCC·GCC 공장 없음$cm$,
   $cm$벨라루스에는 실제 초지기 존재 — Dobrush Geroy Truda(GC1·GC2 코팅 백판지, 신규 20만 t 판지 라인 설계), Shklov 신문용지(신문·오프셋·장식 원지), Spartak Shklov(티슈 원지, 신규 2.4만 t), Slonim Albertin(판지·티슈), Svetlogorsk·Krasnaya Zvezda(라이너), Goznak 보안용지. 제지용 PCC·GCC 제조사 미확인: Krasnoselskstroymaterialy 백악, SabiAn 은 출처 불명 PCC 공급, BSTU 개질 GCC 연구. 국영 연관 기업 다수 — 미국·EU 제재 검토 전까지 전부 보류, 우선순위 미부여.$cm$,
   null, null,
   $cm$제재 검토 전 산정 안 함$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('dobrush|geroy truda|добруш', 'dobrush|добруш', 'dobrush|geroy|wallpaper'),
  ('shklov newsprint|asnova|газетной', 'shklov|шклов', 'asnova|newsprint|gazet|газет'),
  ('spartak|спартак', 'shklov|шклов', 'spartak|спартак'),
  ('albertin|альбертин', 'slonim|слоним', 'albertin|альбертин'),
  ('svetlogorsk|светлогорск', 'svetlogorsk|светлогорск', 'svetlogorsk|светлогорск'),
  ('krasnaya zvezda|red.?star|красная звезда', 'chashniki|чашник', 'zvezda|red.?star|svetlogorsk'),
  ('goznak|гознак', null, 'goznak|гознак'),
  ('\mexclusive\M', null, '\mexclusive\M'),
  ('pukhovichi|пуховичск', null, 'pukhovichi|пуховичск')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'belarus_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'belarus_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'krasnoselsk|красносельск' or p.party_name ~* 'sabian|сабиан')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'BY'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'BY'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'BY'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    