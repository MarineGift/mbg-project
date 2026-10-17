-- ============================================================
-- seed_20261016zx_hungary_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Hungary update (reports 2026-10-16).
-- 1) Fillers if missing (2): Omya Hungária (Szolnok PCC history),
--    Carbonát Kft.
-- 2) Mills if missing (2) + plant blocks: Vajda-Papír Dunaföldvár (1),
--    Hamburger Hungária (2). Context (5): Sofidel Hungary, Piszke, Duna Papír,
--    Dunafin, Szolnok mill.
-- 3) app.country_markets HU row (priority medium).
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
           v.party_name, 'HU', v.region, v.city, v.website, 'active', 'hungary_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('omya.*(hung|eger|szolnok)', 'Omya Hungária - Eger (Szolnok PCC history)', 'Heves', 'Eger', null, 'Omya Hungária Kft.(1993, Lesrét u. 71, Eger) — 2025 매출 약 132억 HUF·62명. Szolnok 위성 PCC(1999, 약 4만 t, 당시 Neusiedler/Mondi 비도공지 12만 t 공장) — 2006 EU 심사·2005 Roskill.', 'Omya Hungária Kft. (1993), Lesrét utca 71, Eger - non-metallic mineral products, 2025 sales about HUF 13.2 bn, net HUF 563 m, about 62 staff. Satellite PCC at Szolnok started 1999 (about 40,000 t/yr) at the then Neusiedler / Mondi uncoated mill (about 120,000 t/yr), per 2005 Roskill and the 2006 EU merger review.', 'HU check 2026-10-16: Szolnok status and Eger paper output to confirm (Hungarian-origin Omya GCC listed is agricultural). Royalty licensee at Omya HQ level.'),
  ('carbon[aá]t kft|carbonatkft', 'Carbonát Kft. - Döbrönte', 'Veszprém', 'Döbrönte', null, '40년+ 석회석 채굴·분쇄(Döbrönte) — CaCO3 98~99% 석회석 분말, 건설·농업·사료.', 'Carbonát Kft., Döbrönte - limestone quarrying and grinding for over 40 years, ground limestone at 98-99 pct CaCO3 for building, agriculture and feed.', 'HU check 2026-10-16: paper grade not confirmed. ertekesites@carbonatkft.hu, +36 89 318 444. Not added: MTI, Imerys, Carmeuse (no Hungarian paper plant found).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%HU check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('omya.*(hung|eger|szolnok)', 'Omya Hungária - Eger (Szolnok PCC history)', 'Heves', 'Eger', null, 'Omya Hungária Kft.(1993, Lesrét u. 71, Eger) — 2025 매출 약 132억 HUF·62명. Szolnok 위성 PCC(1999, 약 4만 t, 당시 Neusiedler/Mondi 비도공지 12만 t 공장) — 2006 EU 심사·2005 Roskill.', 'Omya Hungária Kft. (1993), Lesrét utca 71, Eger - non-metallic mineral products, 2025 sales about HUF 13.2 bn, net HUF 563 m, about 62 staff. Satellite PCC at Szolnok started 1999 (about 40,000 t/yr) at the then Neusiedler / Mondi uncoated mill (about 120,000 t/yr), per 2005 Roskill and the 2006 EU merger review.', 'HU check 2026-10-16: Szolnok status and Eger paper output to confirm (Hungarian-origin Omya GCC listed is agricultural). Royalty licensee at Omya HQ level.'),
  ('carbon[aá]t kft|carbonatkft', 'Carbonát Kft. - Döbrönte', 'Veszprém', 'Döbrönte', null, '40년+ 석회석 채굴·분쇄(Döbrönte) — CaCO3 98~99% 석회석 분말, 건설·농업·사료.', 'Carbonát Kft., Döbrönte - limestone quarrying and grinding for over 40 years, ground limestone at 98-99 pct CaCO3 for building, agriculture and feed.', 'HU check 2026-10-16: paper grade not confirmed. ertekesites@carbonatkft.hu, +36 89 318 444. Not added: MTI, Imerys, Carmeuse (no Hungarian paper plant found).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'hungary_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Omya Hungária - Eger (Szolnok PCC history)', 'GCC and PCC supplier', 'Omya Hungary - Szolnok PCC history, licensee group', 'satellite', 'B', 'pcc'),
  ('Carbonát Kft. - Döbrönte', 'GCC producer', 'High-purity ground limestone - raw and processing partner', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'hungary_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'HU', v.region, v.city, v.website, 'active', 'hungary_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('vajda', 'dunaf[oö]ldv[aá]r', 'vajda', 'Vajda-Papír - Dunaföldvár', 'Tolna', 'Dunaföldvár', null, 'Vajda-Papír Dunaföldvár 티슈 원지 연 11.5만 t — 1라인 3.5만 t(2018, ANDRITZ) + 2라인 8만 t(2022, Toscotec 5.6 m·2,200 m/분). 2026 가공 3만 t 증설·자동창고. Ooops! 브랜드, 노르웨이 Drammen 계열.', 'Vajda-Papír Kft. (HQ Dunaharaszti), tissue base-paper mill at Dunaföldvár - line 1 35,000 t/yr (2018, ANDRITZ) and line 2 80,000 t/yr (2022, Toscotec, 5.6 m, up to 2,200 m/min), 115,000 t/yr total (2023 ESG report). 2026: 30,000 t/yr more converting and an automated warehouse. Brand Ooops!, sister mill Vajda-Papir Scandinavia (Drammen, Norway).', 'HU check 2026-10-16: converting add-on is not base paper - not added. info@vajdapapir.hu, +36 1 283 9390.'),
  ('hamburger.*hung|hamburger.*duna', 'duna[uú]jv[aá]ros', 'hamburger|prinzhorn', 'Hamburger Hungária - Dunaújváros', 'Fejér', 'Dunaújváros', null, 'Prinzhorn 계열 재생 골판지 원지(Papírgyári út 46) 연 70만 t — PM3 21만 t(90~175 g/m²) + PM7 49만 t(7.8 m·1,500 m/분), 수출 약 80%.', 'Hamburger Hungária Kft. (Prinzhorn group), Papírgyári út 46, Dunaújváros - recycled liner and fluting 700,000 t/yr: PM3 210,000 t (4.32 m, 90-175 g/m2) and PM7 490,000 t (7.80 m, 1,500 m/min, 70-150 g/m2), about 80 pct exported.', 'HU check 2026-10-16: brown recycled grades - strength-hold only. office.dun@hamburger-containerboard.com, +36 25 557700.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'HU'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%HU check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'HU'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('vajda', 'dunaf[oö]ldv[aá]r', 'vajda', 'Vajda-Papír Dunaföldvár 티슈 원지 연 11.5만 t — 1라인 3.5만 t(2018, ANDRITZ) + 2라인 8만 t(2022, Toscotec 5.6 m·2,200 m/분). 2026 가공 3만 t 증설·자동창고. Ooops! 브랜드, 노르웨이 Drammen 계열.', 'Vajda-Papír Kft. (HQ Dunaharaszti), tissue base-paper mill at Dunaföldvár - line 1 35,000 t/yr (2018, ANDRITZ) and line 2 80,000 t/yr (2022, Toscotec, 5.6 m, up to 2,200 m/min), 115,000 t/yr total (2023 ESG report). 2026: 30,000 t/yr more converting and an automated warehouse. Brand Ooops!, sister mill Vajda-Papir Scandinavia (Drammen, Norway).', 'HU check 2026-10-16: converting add-on is not base paper - not added. info@vajdapapir.hu, +36 1 283 9390.'),
  ('hamburger.*hung|hamburger.*duna', 'duna[uú]jv[aá]ros', 'hamburger|prinzhorn', 'Prinzhorn 계열 재생 골판지 원지(Papírgyári út 46) 연 70만 t — PM3 21만 t(90~175 g/m²) + PM7 49만 t(7.8 m·1,500 m/분), 수출 약 80%.', 'Hamburger Hungária Kft. (Prinzhorn group), Papírgyári út 46, Dunaújváros - recycled liner and fluting 700,000 t/yr: PM3 210,000 t (4.32 m, 90-175 g/m2) and PM7 490,000 t (7.80 m, 1,500 m/min, 70-150 g/m2), about 80 pct exported.', 'HU check 2026-10-16: brown recycled grades - strength-hold only. office.dun@hamburger-containerboard.com, +36 25 557700.'),
  ('sofidel.*hung|sofidel.*l[aá]batlan', null, 'sofidel.*hung|sofidel.*l[aá]batlan', null, null, 'HU check 2026-10-16: Sofidel Hungary - Lábatlan converting (ex Forest Papír, 2016), no base paper confirmed - context only.'),
  ('piszke', null, 'piszke', null, null, 'HU check 2026-10-16: Tissue products (Crepto, Szilvia), group sales over HUF 10 bn (2024) - own machine to confirm - context only.'),
  ('duna pap[ií]r', null, 'duna pap[ií]r', null, null, 'HU check 2026-10-16: Duna Papír, Tököl - hygiene paper products (2025 sales HUF 3.82 bn) - own machine not confirmed - context only.'),
  ('dunafin', null, 'dunafin', null, null, 'HU check 2026-10-16: Former printing and writing paper, Dunaújváros - status to confirm - context only.'),
  ('szolnok', null, 'szolnok', null, null, 'HU check 2026-10-16: Szolnok uncoated mill (ex Neusiedler / Mondi, about 120 kt) with Omya satellite PCC history - status to confirm - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'hungary_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'HU'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('vajda', 'dunaf[oö]ldv[aá]r', 'vajda'),
  ('hamburger.*hung|hamburger.*duna', 'duna[uú]jv[aá]ros', 'hamburger|prinzhorn'),
  ('sofidel.*hung|sofidel.*l[aá]batlan', null, 'sofidel.*hung|sofidel.*l[aá]batlan'),
  ('piszke', null, 'piszke'),
  ('duna pap[ií]r', null, 'duna pap[ií]r'),
  ('dunafin', null, 'dunafin'),
  ('szolnok', null, 'szolnok')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'HU'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('vajda', 'dunaf[oö]ldv[aá]r', 'vajda',
   $pj${"owner": "Vajda Papír", "priority": 1, "products": "Tissue base paper, toilet, kitchen, napkins", "grades": ["Tissue"], "machines": 2, "capacity": {"value": 115000, "unit": "metric_t", "year": "Company 2023 ESG", "source": "vajdapapir.hu"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Tissue trial range."}, "pitch": "Tissue FCC 3-5-7 pct on the Toscotec line", "approach": "Lead Hungarian account - group trial with Drammen.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('hamburger.*hung|hamburger.*duna', 'duna[uú]jv[aá]ros', 'hamburger|prinzhorn',
   $pj${"owner": "Prinzhorn", "priority": 2, "products": "Recycled liner and fluting", "grades": ["Testliner", "Medium"], "machines": 2, "capacity": {"value": 700000, "unit": "metric_t", "year": "Company site", "source": "hamburger-containerboard.com"}, "capacity_split": [{"label": "PM7", "value_t": 490000}, {"label": "PM3", "value_t": 210000}], "approach": "Fibre-saving trial with strength kept - group link with Hamburger TR.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('sofidel.*hung|sofidel.*l[aá]batlan', null, 'sofidel.*hung|sofidel.*l[aá]batlan',
   $pj${"owner": "Sofidel", "products": "Sofidel Hungary - Lábatlan converting (ex Forest Papír, 2016), no base paper confirmed", "approach": "Converter or status to confirm.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('piszke', null, 'piszke',
   $pj${"owner": "Magyar Piszke Papír", "products": "Tissue products (Crepto, Szilvia), group sales over HUF 10 bn (2024) - own machine to confirm", "approach": "Converter or status to confirm.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('duna pap[ií]r', null, 'duna pap[ií]r',
   $pj${"owner": "Hungarian state", "products": "Duna Papír, Tököl - hygiene paper products (2025 sales HUF 3.82 bn) - own machine not confirmed", "approach": "Converter or status to confirm.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('dunafin', null, 'dunafin',
   $pj${"owner": "Dunafin", "products": "Former printing and writing paper, Dunaújváros - status to confirm", "approach": "Converter or status to confirm.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('szolnok', null, 'szolnok',
   $pj${"owner": "Mondi (former)", "products": "Szolnok uncoated mill (ex Neusiedler / Mondi, about 120 kt) with Omya satellite PCC history - status to confirm", "approach": "Converter or status to confirm.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'HU', 'Hungary', 'medium',
   $cm$Vajda-Papír tissue (115 kt, Dunaföldvár) and Hamburger Hungária recycled liner (700 kt) - Omya Szolnok satellite PCC history$cm$,
   $cm$Hungary's base-paper output is Vajda-Papír tissue at Dunaföldvár (115 kt on two lines, 2018 and 2022) and Hamburger Hungária recycled liner and fluting at Dunaújváros (700 kt). Sofidel Hungary, Piszke and Duna Papír mostly convert. Omya ran a satellite PCC at the Szolnok uncoated mill since 1999 (about 40 kt) - current status of both to confirm. Omya Hungária (Eger) is active (HUF 13.2 bn sales 2025). Carbonát Kft. grinds 98-99 pct limestone.$cm$,
   $cm${"fillers": "Omya Hungária (Eger, Szolnok PCC history). Ground limestone: Carbonát Kft. Not added: MTI, Imerys, Carmeuse.", "mills": "Tissue: Vajda-Papír Dunaföldvár. Recycled liner: Hamburger Hungária Dunaújváros. Context: Sofidel Hungary, Magyar Piszke Papír, Duna Papír, Dunafin, Szolnok mill.", "strategy": "Vajda tissue trial (with Drammen, Norway) first, Hamburger strength-hold trial later. Check Omya Szolnok for a three-way model.", "risks": "Szolnok status unknown, liner strength limits.", "next_steps": ["Propose a tissue trial to Vajda-Papír", "Confirm Szolnok mill and PCC status"], "key_numbers": [{"label": "Vajda-Papír", "value": "115 kt tissue base paper"}, {"label": "Hamburger Hungária", "value": "700 kt (PM3 210 + PM7 490)"}, {"label": "Omya Szolnok PCC", "value": "about 40 kt (1999)"}], "files": ["seed_20261016zx_hungary_mills_fillers"]}$cm$::jsonb,
   $cm$Vajda-Papír 티슈(11.5만 t, Dunaföldvár)·Hamburger Hungária 재생 라이너(70만 t) — Omya Szolnok 위성 PCC 이력$cm$,
   $cm$헝가리 원지 생산은 Vajda-Papír 티슈(Dunaföldvár, 2라인 11.5만 t)와 Hamburger Hungária 재생 라이너·골심지(Dunaújváros, 70만 t). Sofidel Hungary·Piszke·Duna Papír 는 주로 가공. Omya 가 1999년부터 Szolnok 비도공지 공장에 위성 PCC(약 4만 t) 운영 — 현재 상태 확인 필요. Omya Hungária(Eger) 활동 중(2025 매출 132억 HUF). Carbonát Kft. 98~99% 석회석 분쇄.$cm$,
   3450, 5750,
   $cm$Vajda-Papír 11.5만 t × FCC 3~5% (Hamburger 제외)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('vajda', 'dunaf[oö]ldv[aá]r', 'vajda'),
  ('hamburger.*hung|hamburger.*duna', 'duna[uú]jv[aá]ros', 'hamburger|prinzhorn'),
  ('sofidel.*hung|sofidel.*l[aá]batlan', null, 'sofidel.*hung|sofidel.*l[aá]batlan'),
  ('piszke', null, 'piszke'),
  ('duna pap[ií]r', null, 'duna pap[ií]r'),
  ('dunafin', null, 'dunafin'),
  ('szolnok', null, 'szolnok')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'hungary_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'HU'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'hungary_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'omya.*(hung|eger|szolnok)' or p.party_name ~* 'carbon[aá]t kft|carbonatkft')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'HU'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'HU'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'HU'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'HU'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    