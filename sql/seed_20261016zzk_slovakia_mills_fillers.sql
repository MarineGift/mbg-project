-- ============================================================
-- seed_20261016zzk_slovakia_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Slovakia update (reports 2026-10-16). Fixed generator.
-- 1) Fillers if missing (4): Specialty Minerals Slovakia (PCC), Omya
--    Slovakia, Carmeuse Slovakia, Calmit Slovakia.
-- 2) Mills if missing (4) + plant blocks, priority 1-4: Mondi SCP, Metsä
--    Tissue Žilina, SHP Harmanec, SHP Slavošovce. Context (2): Essity
--    Gemerská Hôrka, BUKOCEL.
-- 3) app.country_markets SK row (priority high). No SMI link until the host
--    mill is confirmed.
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
           v.party_name, 'SK', v.region, v.city, v.website, 'active', 'slovakia_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('(specialty minerals|minerals technologies).*(slovak|ru[zž]omberok)', 'Specialty Minerals Slovakia (PCC)', 'Slovakia', null, null, 'MTI 슬로바키아 법인 — 2019~2020 PCC 생산능력 확대 설계(CELPROJEKT PLUS) 발주처, 실제 PCC 설비 운영.', 'Specialty Minerals Slovakia s.r.o. (Minerals Technologies) - client of CELPROJEKT PLUS for PCC capacity-expansion permits (2019) and detailed design (2020), so it runs a PCC plant in Slovakia.', 'SK check 2026-10-16: plant site, capacity and host mill to confirm - Mondi SCP Ružomberok is the obvious candidate (not confirmed, no link yet). SMI is the MBG tissue-track partner (NDA).'),
  ('omya.*(slovak|bratislava)', 'Omya Slovakia - Bratislava', 'Bratislava', 'Bratislava', null, 'Omya s.r.o.(Karadžičova 8/A, 브라티슬라바) — 펄프·제지 서비스, 제조공장 미확인.', 'Omya s.r.o., Karadžičova 8/A, Bratislava - serves pulp and paper among other industries.', 'SK check 2026-10-16: no Slovak plant identified. Royalty licensee at Omya HQ level.'),
  ('carmeuse.*(slovak|ko[sš]ice|slavec)', 'Carmeuse Slovakia - Košice', 'Košice', 'Košice', null, 'Carmeuse Slovakia(Rozvojová 2/B, Košice) — Slavec·Košice-Šaca·Trebejov·Včeláre 석회석·석회, PCC 담당 부서 별도.', 'Carmeuse Slovakia s.r.o., Rozvojová 2/B, Košice - limestone and lime at Slavec, Košice-Šaca, Trebejov and Včeláre, with a separate Environment, Chemical Industry and PCC desk.', 'SK check 2026-10-16: PCC lime supplier (likely to the SMI plant). mpetras@carmeuse.sk, +421 910 706 993.'),
  ('calmit.*(slovak|tisovec|[zž][ií]rany|margecany|spol)', 'Calmit Slovakia - Tisovec', 'Banská Bystrica', 'Tisovec', null, 'Calmit spol. s r.o.(본사 Gaštanová 15, 브라티슬라바) — Tisovec·Žírany·Margecany 석회석·석회.', 'Calmit spol. s r.o., Gaštanová 15, Bratislava - limestone and lime plants at Tisovec, Žírany and Margecany.', 'SK check 2026-10-16: no paper GCC slurry confirmed. office@calmit.sk. Same Calmit group as Bad Ischl (AT row). Not added: EUROTALC (talc).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%SK check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('(specialty minerals|minerals technologies).*(slovak|ru[zž]omberok)', 'Specialty Minerals Slovakia (PCC)', 'Slovakia', null, null, 'MTI 슬로바키아 법인 — 2019~2020 PCC 생산능력 확대 설계(CELPROJEKT PLUS) 발주처, 실제 PCC 설비 운영.', 'Specialty Minerals Slovakia s.r.o. (Minerals Technologies) - client of CELPROJEKT PLUS for PCC capacity-expansion permits (2019) and detailed design (2020), so it runs a PCC plant in Slovakia.', 'SK check 2026-10-16: plant site, capacity and host mill to confirm - Mondi SCP Ružomberok is the obvious candidate (not confirmed, no link yet). SMI is the MBG tissue-track partner (NDA).'),
  ('omya.*(slovak|bratislava)', 'Omya Slovakia - Bratislava', 'Bratislava', 'Bratislava', null, 'Omya s.r.o.(Karadžičova 8/A, 브라티슬라바) — 펄프·제지 서비스, 제조공장 미확인.', 'Omya s.r.o., Karadžičova 8/A, Bratislava - serves pulp and paper among other industries.', 'SK check 2026-10-16: no Slovak plant identified. Royalty licensee at Omya HQ level.'),
  ('carmeuse.*(slovak|ko[sš]ice|slavec)', 'Carmeuse Slovakia - Košice', 'Košice', 'Košice', null, 'Carmeuse Slovakia(Rozvojová 2/B, Košice) — Slavec·Košice-Šaca·Trebejov·Včeláre 석회석·석회, PCC 담당 부서 별도.', 'Carmeuse Slovakia s.r.o., Rozvojová 2/B, Košice - limestone and lime at Slavec, Košice-Šaca, Trebejov and Včeláre, with a separate Environment, Chemical Industry and PCC desk.', 'SK check 2026-10-16: PCC lime supplier (likely to the SMI plant). mpetras@carmeuse.sk, +421 910 706 993.'),
  ('calmit.*(slovak|tisovec|[zž][ií]rany|margecany|spol)', 'Calmit Slovakia - Tisovec', 'Banská Bystrica', 'Tisovec', null, 'Calmit spol. s r.o.(본사 Gaštanová 15, 브라티슬라바) — Tisovec·Žírany·Margecany 석회석·석회.', 'Calmit spol. s r.o., Gaštanová 15, Bratislava - limestone and lime plants at Tisovec, Žírany and Margecany.', 'SK check 2026-10-16: no paper GCC slurry confirmed. office@calmit.sk. Same Calmit group as Bad Ischl (AT row). Not added: EUROTALC (talc).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'slovakia_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Specialty Minerals Slovakia (PCC)', 'PCC producer', 'SMI PCC plant (expanded 2019-2020) - partner route', 'satellite', 'B', 'pcc'),
  ('Omya Slovakia - Bratislava', 'GCC and PCC supplier', 'Omya Slovakia - sales office, licensee group', 'merchant', 'C', 'gcc'),
  ('Carmeuse Slovakia - Košice', 'Lime producer', 'Lime for PCC - raw-material partner', 'merchant', 'C', 'pcc'),
  ('Calmit Slovakia - Tisovec', 'Lime producer', 'Limestone and lime - raw material', 'merchant', 'C', 'pcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'slovakia_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'SK', v.region, v.city, v.website, 'active', 'slovakia_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('mondi.*(scp|ru[zž]omberok)|\mscp\M', 'ru[zž]omberok', 'mondi|scp', 'Mondi SCP - Ružomberok', 'Žilina', 'Ružomberok', null, 'Mondi SCP(Tatranská cesta 3) 슬로바키아 최대 통합 펄프·제지 — 초지기 5대, 비도공지 58만·컨테이너보드 31만·크라프트 6.7만 t(합 95.7만 t), 판매 펄프 약 10만 t, 1,300명+.', 'Mondi SCP a.s., Tatranská cesta 3, Ružomberok - largest Slovak integrated pulp and paper mill, five machines (PS1, PS16-PS19): uncoated fine paper 580,000 t, containerboard 310,000 t, kraft paper 67,000 t per year (957,000 t), plus about 100,000 t market pulp, over 1,300 staff.', 'SK check 2026-10-16: filler supplier unknown - check the SMI Slovakia PCC link. mondi.scp@mondigroup.com, +421 44 436 2222.'),
  ('mets[aä].*[zž]ilina|[zž]ilina.*tissue', '[zž]ilina', 'mets[aä]', 'Metsä Tissue Slovakia - Žilina', 'Žilina', 'Žilina', null, 'Metsä Tissue Žilina(1905~) 티슈 2대·가공 6라인, 연 약 8.1만 t(협회 7만 t), 270명 — Lambi·Serla·Mola·Tento.', 'Metsä Tissue Slovakia s.r.o., Žilina (mill since 1905) - two tissue machines and six converting lines, about 81,000 t/yr (company, 70,000 t on the association page), about 270 staff, Lambi, Serla, Mola, Tento.', 'SK check 2026-10-16: metsatissue.sk@metsagroup.com.'),
  ('shp.*harmanec|harmanec', 'harmanec', 'shp|harmanec', 'SHP Harmanec', 'Banská Bystrica', 'Harmanec', null, 'SHP Group Harmanec(Harmony) — PS7 15~29 g/m²·1,550 m/분, 재생원료 약 90%(과거), 2026-01 TL2 가공라인(390만 유로+, 1.22만 t). SHP 2개 공장 합 약 6만 t.', 'SHP Harmanec (SHP Group, Harmony brand), Harmanec - PS7 tissue machine 15-29 g/m2 at about 1,550 m/min, about 90 pct recovered fibre in older data, toilet, towel and facial converting. New TL2 converting line 2026-01 (over EUR 3.9 m, 12,230 t/yr). SHP Harmanec plus Slavošovce about 60,000 t/yr output.', 'SK check 2026-10-16: TL2 is converting, not base paper. +421 48 4322 535. Same group as Paloma (SI) and SHP Celex (BA).'),
  ('shp.*slavo[sš]ovce|slavo[sš]ovce', 'slavo[sš]ovce', 'shp|slavo', 'SHP Slavošovce', 'Košice', 'Slavošovce', null, 'SHP Slavošovce(298) — PS8 15~25 g/m²·790 m/분, 고백색 버진 펄프, 컬러·인쇄 냅킨, 가공 약 1.04만 t.', 'SHP Slavošovce, Slavošovce 298 - PS8 15-25 g/m2 at about 790 m/min on high-white virgin pulp, coloured and printed napkins and table products, about 10,400 t/yr converting.', 'SK check 2026-10-16: print, colour, dust and food-contact checks. slavosovce@shpgroup.eu.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SK'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%SK check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SK'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('mondi.*(scp|ru[zž]omberok)|\mscp\M', 'ru[zž]omberok', 'mondi|scp', 'Mondi SCP(Tatranská cesta 3) 슬로바키아 최대 통합 펄프·제지 — 초지기 5대, 비도공지 58만·컨테이너보드 31만·크라프트 6.7만 t(합 95.7만 t), 판매 펄프 약 10만 t, 1,300명+.', 'Mondi SCP a.s., Tatranská cesta 3, Ružomberok - largest Slovak integrated pulp and paper mill, five machines (PS1, PS16-PS19): uncoated fine paper 580,000 t, containerboard 310,000 t, kraft paper 67,000 t per year (957,000 t), plus about 100,000 t market pulp, over 1,300 staff.', 'SK check 2026-10-16: filler supplier unknown - check the SMI Slovakia PCC link. mondi.scp@mondigroup.com, +421 44 436 2222.'),
  ('mets[aä].*[zž]ilina|[zž]ilina.*tissue', '[zž]ilina', 'mets[aä]', 'Metsä Tissue Žilina(1905~) 티슈 2대·가공 6라인, 연 약 8.1만 t(협회 7만 t), 270명 — Lambi·Serla·Mola·Tento.', 'Metsä Tissue Slovakia s.r.o., Žilina (mill since 1905) - two tissue machines and six converting lines, about 81,000 t/yr (company, 70,000 t on the association page), about 270 staff, Lambi, Serla, Mola, Tento.', 'SK check 2026-10-16: metsatissue.sk@metsagroup.com.'),
  ('shp.*harmanec|harmanec', 'harmanec', 'shp|harmanec', 'SHP Group Harmanec(Harmony) — PS7 15~29 g/m²·1,550 m/분, 재생원료 약 90%(과거), 2026-01 TL2 가공라인(390만 유로+, 1.22만 t). SHP 2개 공장 합 약 6만 t.', 'SHP Harmanec (SHP Group, Harmony brand), Harmanec - PS7 tissue machine 15-29 g/m2 at about 1,550 m/min, about 90 pct recovered fibre in older data, toilet, towel and facial converting. New TL2 converting line 2026-01 (over EUR 3.9 m, 12,230 t/yr). SHP Harmanec plus Slavošovce about 60,000 t/yr output.', 'SK check 2026-10-16: TL2 is converting, not base paper. +421 48 4322 535. Same group as Paloma (SI) and SHP Celex (BA).'),
  ('shp.*slavo[sš]ovce|slavo[sš]ovce', 'slavo[sš]ovce', 'shp|slavo', 'SHP Slavošovce(298) — PS8 15~25 g/m²·790 m/분, 고백색 버진 펄프, 컬러·인쇄 냅킨, 가공 약 1.04만 t.', 'SHP Slavošovce, Slavošovce 298 - PS8 15-25 g/m2 at about 790 m/min on high-white virgin pulp, coloured and printed napkins and table products, about 10,400 t/yr converting.', 'SK check 2026-10-16: print, colour, dust and food-contact checks. slavosovce@shpgroup.eu.'),
  ('essity.*(slovak|gemersk)', null, 'essity.*(slovak|gemersk)', null, null, 'SK check 2026-10-16: Gemerská Hôrka - personal care products, not a base-paper machine - context only.'),
  ('bukocel|hencovce', null, 'bukocel|hencovce', null, null, 'SK check 2026-10-16: Chemical pulp, Hencovce - bankruptcy opened 2025-01, declared 2025-04 - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'slovakia_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SK'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('mondi.*(scp|ru[zž]omberok)|\mscp\M', 'ru[zž]omberok', 'mondi|scp'),
  ('mets[aä].*[zž]ilina|[zž]ilina.*tissue', '[zž]ilina', 'mets[aä]'),
  ('shp.*harmanec|harmanec', 'harmanec', 'shp|harmanec'),
  ('shp.*slavo[sš]ovce|slavo[sš]ovce', 'slavo[sš]ovce', 'shp|slavo'),
  ('essity.*(slovak|gemersk)', null, 'essity.*(slovak|gemersk)'),
  ('bukocel|hencovce', null, 'bukocel|hencovce')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SK'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('mondi.*(scp|ru[zž]omberok)|\mscp\M', 'ru[zž]omberok', 'mondi|scp', false,
   $pj${"owner": "Mondi", "priority": 1, "products": "Uncoated fine paper, containerboard, kraft", "grades": ["UWF", "Copy paper", "Testliner", "Kraft paper"], "machines": 5, "capacity": {"value": 957000, "unit": "metric_t", "year": "Company figure (all paper)", "source": "mondigroup.com"}, "capacity_split": [{"label": "Uncoated fine", "value_t": 580000}, {"label": "Containerboard", "value_t": 310000}, {"label": "Kraft paper", "value_t": 67000}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 0.6, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 0.6, "fcc_loading": 0.05}], "note": "UWF share about 60 pct of output."}, "pitch": "Mondi + SMI + MBG UWF trial", "approach": "Lead Slovak account - Mondi group link (Neusiedler AT, Štětí CZ, Świecie PL).", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('mets[aä].*[zž]ilina|[zž]ilina.*tissue', '[zž]ilina', 'mets[aä]', false,
   $pj${"owner": "Metsä Group", "priority": 2, "products": "Toilet tissue, kitchen towel", "grades": ["Tissue"], "machines": 2, "capacity": {"value": 81000, "unit": "metric_t", "year": "Company output figure", "source": "metsatissue.com"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.01}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}], "note": "Tissue low-dose range."}, "approach": "Metsä group tissue trial (FI, SE, PL).", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('shp.*harmanec|harmanec', 'harmanec', 'shp|harmanec', false,
   $pj${"owner": "SHP Group", "priority": 3, "products": "Recycled tissue", "grades": ["Tissue"], "capacity_split": [{"label": "SHP Slovakia total (2 mills, output)", "value_t": 60000}], "approach": "SHP group tissue trial - ash in recycled furnish first.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('shp.*slavo[sš]ovce|slavo[sš]ovce', 'slavo[sš]ovce', 'shp|slavo', false,
   $pj${"owner": "SHP Group", "priority": 4, "products": "Coloured and printed napkins", "grades": ["Tissue"], "approach": "Virgin-pulp saving trial on napkins.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('essity.*(slovak|gemersk)', null, 'essity.*(slovak|gemersk)', true,
   $pj${"owner": "Essity", "products": "Gemerská Hôrka - personal care products, not a base-paper machine", "approach": "Not a paper machine or bankrupt.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('bukocel|hencovce', null, 'bukocel|hencovce', true,
   $pj${"owner": "BUKOCEL", "products": "Chemical pulp, Hencovce - bankruptcy opened 2025-01, declared 2025-04", "approach": "Not a paper machine or bankrupt.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'SK', 'Slovakia', 'high',
   $cm$Mondi SCP Ružomberok (957 kt, 580 kt UWF) with an SMI PCC plant in Slovakia, Metsä Tissue Žilina (81 kt), SHP Harmanec and Slavošovce$cm$,
   $cm$Slovakia's paper output is concentrated at Mondi SCP Ružomberok (five machines: 580 kt uncoated fine, 310 kt containerboard, 67 kt kraft) plus tissue at Metsä Tissue Žilina (about 81 kt) and SHP Harmanec and Slavošovce (about 60 kt together). Specialty Minerals Slovakia expanded a PCC plant in 2019-2020 - site and host mill to confirm, Mondi SCP is the likely host. Omya Slovakia is a sales office, Carmeuse (Slavec, Košice, PCC desk) and Calmit (Tisovec, Žírany, Margecany) supply lime. Essity Gemerská Hôrka is personal care, BUKOCEL pulp is bankrupt.$cm$,
   $cm${"fillers": "PCC: Specialty Minerals Slovakia (expanded 2019-2020). Sales: Omya Slovakia. Lime: Carmeuse Slovakia (PCC desk), Calmit Slovakia. Not added: EUROTALC.", "mills": "UWF, liner, kraft: Mondi SCP. Tissue: Metsä Tissue Žilina, SHP Harmanec, SHP Slavošovce. Context: Essity Gemerská Hôrka (personal care), BUKOCEL (bankrupt).", "strategy": "Confirm the SMI PCC host - if Mondi SCP, run an SMI + Mondi + MBG UWF trial. Tissue trials via Metsä and SHP groups.", "risks": "SMI site unknown, Omya competing tech.", "next_steps": ["Ask SMI about the site and customers of its Slovak PCC plant", "Propose a UWF trial to Mondi SCP"], "key_numbers": [{"label": "Mondi SCP", "value": "957 kt (580 kt UWF)"}, {"label": "Metsä Tissue Žilina", "value": "about 81 kt"}, {"label": "Report scenario at 3 pct", "value": "about 32,940 t FCC"}], "files": ["seed_20261016zzk_slovakia_mills_fillers"]}$cm$::jsonb,
   $cm$Mondi SCP Ružomberok(95.7만 t, UWF 58만 t)·슬로바키아 SMI PCC 공장, Metsä Tissue Žilina(8.1만 t), SHP Harmanec·Slavošovce$cm$,
   $cm$슬로바키아 생산은 Mondi SCP Ružomberok(5대: 비도공지 58만·컨테이너보드 31만·크라프트 6.7만 t)에 집중, 티슈 Metsä Tissue Žilina(약 8.1만 t)·SHP Harmanec·Slavošovce(합 약 6만 t). Specialty Minerals Slovakia 가 2019~2020 PCC 공장 증설 — 위치·공급 제지사 확인 필요(Mondi SCP 유력). Omya 영업소, Carmeuse(PCC 담당 부서)·Calmit 석회. Essity Gemerská Hôrka 는 위생용품, BUKOCEL 파산.$cm$,
   10980, 54900,
   $cm$Mondi·Metsä·SHP 109.8만 t × FCC 1~5% (보고서 시나리오, 3% 시 약 3.3만 t)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('mondi.*(scp|ru[zž]omberok)|\mscp\M', 'ru[zž]omberok', 'mondi|scp'),
  ('mets[aä].*[zž]ilina|[zž]ilina.*tissue', '[zž]ilina', 'mets[aä]'),
  ('shp.*harmanec|harmanec', 'harmanec', 'shp|harmanec'),
  ('shp.*slavo[sš]ovce|slavo[sš]ovce', 'slavo[sš]ovce', 'shp|slavo'),
  ('essity.*(slovak|gemersk)', null, 'essity.*(slovak|gemersk)'),
  ('bukocel|hencovce', null, 'bukocel|hencovce')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'slovakia_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SK'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'slovakia_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* '(specialty minerals|minerals technologies).*(slovak|ru[zž]omberok)' or p.party_name ~* 'omya.*(slovak|bratislava)' or p.party_name ~* 'carmeuse.*(slovak|ko[sš]ice|slavec)' or p.party_name ~* 'calmit.*(slovak|tisovec|[zž][ií]rany|margecany|spol)')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'SK'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'SK'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'SK'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SK'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    