-- ============================================================
-- seed_20261016zi_bulgaria_update.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Bulgaria second report (2026-10-16) on top of seed_20261016zg.
-- 1) Fillers if missing (4): Zlatna Panega Cement, SMA Mineral Burgas Var,
--    Ognyanovo K, Skalni Materiali.
-- 2) Mills: plant blocks refreshed - GFF priority 1, Kostenets HHI 2,
--    Belovo priority removed (in liquidation 2026-10-15). New note line
--    marked 'BG check 2026-10-16b'. Context (4): Lipo-Hart, Tri-Wall, EMA,
--    Kostenets Paper Mill AD.
-- 3) app.country_markets BG row refreshed (FCC 670 - 3,350 t).
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
           v.party_name, 'BG', v.region, v.city, v.website, 'active', 'bulgaria_update_20261016b',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('zlatna panega', 'Zlatna Panega Cement (TITAN) - Zlatna Panega', 'Lovech', 'Zlatna Panega', null, 'TITAN 그룹 Zlatna Panega 시멘트 — 2017 통합보고서에 미분 석회석(Micronized Limestone) 제지·도료·플라스틱 용도 명시.', 'Zlatna Panega Cement AD (TITAN Group), Zlatna Panega (Lovech) - cement, concrete and aggregates, its 2017 integrated report lists Micronized Limestone (ground natural calcium carbonate) for paper, paint and plastics.', 'BG check 2026-10-16b: current micronized product and paper sales not confirmed. office@titan.bg, +359 2 882 01 22.'),
  ('sma mineral|burgas var', 'SMA Mineral Burgas Var', 'Burgas', 'Dobromir', null, 'SMA Mineral 계열 석회석·석회 업체 — Dobromir·Malko Tarnovo·Troitsa, 생석회·소석회·분쇄 석회석.', 'SMA Mineral Burgas Var (SMA Mineral group, Sweden) - limestone quarrying and lime at Dobromir, Malko Tarnovo and Troitsa: quicklime, hydrated lime, ground limestone.', 'BG check 2026-10-16b: lime base for a future PCC line - no paper grades.'),
  ('ognyanovo', 'Ognyanovo K', 'Pazardzhik', 'Ognyanovo', null, '불가리아 주요 석회 생산업체 Ognyanovo K(Ognyanovo·Puklina).', 'Ognyanovo K JSC, Ognyanovo and Puklina - one of the main Bulgarian lime producers, lime and limestone products.', 'BG check 2026-10-16b: raw material and lime only.'),
  ('skalni materiali', 'Skalni Materiali', 'Ruse', 'Ruse', null, 'Ruse·Razgrad·Dobrich 석회석 채굴·가공 — 분쇄 석회석·사료용 탄산칼슘·골재.', 'Skalni Materiali AD, Ruse, Razgrad and Dobrich - limestone quarrying, ground limestone, feed calcium carbonate, aggregates.', 'BG check 2026-10-16b: raw material only. Kaolin EAD detail: owned by Quarzwerke since 2013, HQ Senovo, limestone at Dimitrovgrad, office@kaolin.bg.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%BG check 2026-10-16b%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('zlatna panega', 'Zlatna Panega Cement (TITAN) - Zlatna Panega', 'Lovech', 'Zlatna Panega', null, 'TITAN 그룹 Zlatna Panega 시멘트 — 2017 통합보고서에 미분 석회석(Micronized Limestone) 제지·도료·플라스틱 용도 명시.', 'Zlatna Panega Cement AD (TITAN Group), Zlatna Panega (Lovech) - cement, concrete and aggregates, its 2017 integrated report lists Micronized Limestone (ground natural calcium carbonate) for paper, paint and plastics.', 'BG check 2026-10-16b: current micronized product and paper sales not confirmed. office@titan.bg, +359 2 882 01 22.'),
  ('sma mineral|burgas var', 'SMA Mineral Burgas Var', 'Burgas', 'Dobromir', null, 'SMA Mineral 계열 석회석·석회 업체 — Dobromir·Malko Tarnovo·Troitsa, 생석회·소석회·분쇄 석회석.', 'SMA Mineral Burgas Var (SMA Mineral group, Sweden) - limestone quarrying and lime at Dobromir, Malko Tarnovo and Troitsa: quicklime, hydrated lime, ground limestone.', 'BG check 2026-10-16b: lime base for a future PCC line - no paper grades.'),
  ('ognyanovo', 'Ognyanovo K', 'Pazardzhik', 'Ognyanovo', null, '불가리아 주요 석회 생산업체 Ognyanovo K(Ognyanovo·Puklina).', 'Ognyanovo K JSC, Ognyanovo and Puklina - one of the main Bulgarian lime producers, lime and limestone products.', 'BG check 2026-10-16b: raw material and lime only.'),
  ('skalni materiali', 'Skalni Materiali', 'Ruse', 'Ruse', null, 'Ruse·Razgrad·Dobrich 석회석 채굴·가공 — 분쇄 석회석·사료용 탄산칼슘·골재.', 'Skalni Materiali AD, Ruse, Razgrad and Dobrich - limestone quarrying, ground limestone, feed calcium carbonate, aggregates.', 'BG check 2026-10-16b: raw material only. Kaolin EAD detail: owned by Quarzwerke since 2013, HQ Senovo, limestone at Dimitrovgrad, office@kaolin.bg.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'bulgaria_update_20261016b';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Zlatna Panega Cement (TITAN) - Zlatna Panega', 'GCC producer', 'Micronised limestone (cement group)', 'merchant', 'C', 'gcc'),
  ('SMA Mineral Burgas Var', 'Lime producer', 'Limestone and lime - PCC raw material', 'merchant', 'C', 'pcc'),
  ('Ognyanovo K', 'Lime producer', 'Lime - PCC raw material', 'merchant', 'C', 'pcc'),
  ('Skalni Materiali', 'Carbonate raw material', 'Limestone - raw material', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'bulgaria_update_20261016b'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'BG', v.region, v.city, v.website, 'active', 'bulgaria_update_20261016b',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('\mgff\M|gff paper', 'nikopol', 'gff', 'GFF Paper Mill - Nikopol', 'Pleven', 'Nikopol', null, 'Nikopol 티슈 공장(2010 판지→티슈 전환) — PM1 Voith 평망 4,500 mm 2만 t + PM2 Recard 크레센트 2,800 mm 2만 t = 연 4만 t, 재생·버진 펄프.', 'GFF Paper Mill, Industrial Zone Nikopol / Cherkovitsa (Pleven) - former board mill, tissue since 2010: PM1 Voith flat-wire 4,500 mm (20,000 t/yr) and PM2 Recard crescent former 2,800 mm (20,000 t/yr), 40,000 t/yr tissue on recycled and virgin pulp, about 273,000 m2 site.', 'BG check 2026-10-16b: priority raised to 1 - Belovo is in liquidation. Grades: facial 14.5-16, toilet 15.5-21, napkin 17-22, kitchen 16-28, hand towel 19-35 gsm, virgin and recycled. Suggested trial FCC 3, 5, 7 pct on 15 gsm virgin tissue.'),
  ('kostenets|\mhhi\M', 'kostenets', 'kostenets|hhi', 'Kostenets HHI - Kostenets', 'Sofia Province', 'Kostenets', null, 'Kostenets HHI — PM1 재생 플루팅(8,000 t+), PM2 MG지 1.5만 t 또는 티슈 9,000 t, PM3 크레센트 티슈(15~35 gsm, 1,800 m/분) 2만~2.7만 t.', 'Kostenets HHI AD, 2 Saedinenie St, Kostenets - PM1 Voith recycled fluting 80-220 gsm (over 8,000 t/yr), PM2 MG paper 15,000 t/yr or tissue 9,000 t/yr (17-70 gsm), PM3 OverMeccanica crescent-former tissue 15-35 gsm at 1,800 m/min (20,000-27,000 t/yr), virgin and recycled tissue.', 'BG check 2026-10-16b: several legal entities share the Kostenets site (Kostenets Paper Mill AD active in the register, Kostenets Paper AD holds mill real estate, Kostenets-HHI AD) - confirm which one runs PM1-PM3.'),
  ('belovo|belana', 'belovo', 'belovo|belana', 'Belovo Paper Mill (Belana) - Belovo', 'Pazardzhik', 'Belovo', null, '1900년 설립 불가리아 최대 티슈 제조사(Belana) — 초지기 4대, 티슈·포장지 연 약 5.8만 t, 원지~완제품 통합, 수출.', 'Belovo Paper Mill (1900, brand Belana), 1A Dabravsko Shose, Belovo (Pazardzhik) - largest Bulgarian tissue maker: four paper machines, about 58,000 t/yr tissue and packaging paper, integrated jumbo rolls to toilet, kitchen, napkins, facial and pocket tissue, exports in Europe.', 'BG check 2026-10-16b: Finansi.bg shows Belovo Paper Mill AD in liquidation (2026-10-15) - 58 kt is historical, priority removed until a restart or new owner is confirmed.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%BG check 2026-10-16b%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('\mgff\M|gff paper', 'nikopol', 'gff', 'Nikopol 티슈 공장(2010 판지→티슈 전환) — PM1 Voith 평망 4,500 mm 2만 t + PM2 Recard 크레센트 2,800 mm 2만 t = 연 4만 t, 재생·버진 펄프.', 'GFF Paper Mill, Industrial Zone Nikopol / Cherkovitsa (Pleven) - former board mill, tissue since 2010: PM1 Voith flat-wire 4,500 mm (20,000 t/yr) and PM2 Recard crescent former 2,800 mm (20,000 t/yr), 40,000 t/yr tissue on recycled and virgin pulp, about 273,000 m2 site.', 'BG check 2026-10-16b: priority raised to 1 - Belovo is in liquidation. Grades: facial 14.5-16, toilet 15.5-21, napkin 17-22, kitchen 16-28, hand towel 19-35 gsm, virgin and recycled. Suggested trial FCC 3, 5, 7 pct on 15 gsm virgin tissue.'),
  ('kostenets|\mhhi\M', 'kostenets', 'kostenets|hhi', 'Kostenets HHI — PM1 재생 플루팅(8,000 t+), PM2 MG지 1.5만 t 또는 티슈 9,000 t, PM3 크레센트 티슈(15~35 gsm, 1,800 m/분) 2만~2.7만 t.', 'Kostenets HHI AD, 2 Saedinenie St, Kostenets - PM1 Voith recycled fluting 80-220 gsm (over 8,000 t/yr), PM2 MG paper 15,000 t/yr or tissue 9,000 t/yr (17-70 gsm), PM3 OverMeccanica crescent-former tissue 15-35 gsm at 1,800 m/min (20,000-27,000 t/yr), virgin and recycled tissue.', 'BG check 2026-10-16b: several legal entities share the Kostenets site (Kostenets Paper Mill AD active in the register, Kostenets Paper AD holds mill real estate, Kostenets-HHI AD) - confirm which one runs PM1-PM3.'),
  ('belovo|belana', 'belovo', 'belovo|belana', '1900년 설립 불가리아 최대 티슈 제조사(Belana) — 초지기 4대, 티슈·포장지 연 약 5.8만 t, 원지~완제품 통합, 수출.', 'Belovo Paper Mill (1900, brand Belana), 1A Dabravsko Shose, Belovo (Pazardzhik) - largest Bulgarian tissue maker: four paper machines, about 58,000 t/yr tissue and packaging paper, integrated jumbo rolls to toilet, kitchen, napkins, facial and pocket tissue, exports in Europe.', 'BG check 2026-10-16b: Finansi.bg shows Belovo Paper Mill AD in liquidation (2026-10-15) - 58 kt is historical, priority removed until a restart or new owner is confirmed.'),
  ('lipo-?hart', null, 'lipo-?hart', null, null, 'BG check 2026-10-16b: Corrugated and micro-flute boxes, Kostinbrod - converter - context only.'),
  ('tri-?wall', null, 'tri-?wall', null, null, 'BG check 2026-10-16b: New corrugated packaging plant at Trakia Economic Zone (EUR 30 m+, groundbreaking 2026-01-28) - converter - context only.'),
  ('\mema\M.*(paper|хартия)', null, '\mema\M.*(paper|хартия)', null, null, 'BG check 2026-10-16b: Paper distribution and converting, Pleven - context only.'),
  ('kostenets paper', null, 'kostenets paper', null, null, 'BG check 2026-10-16b: Registered paper and board entity on the Kostenets site - see Kostenets HHI row - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'bulgaria_update_20261016b';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('\mgff\M|gff paper', 'nikopol', 'gff'),
  ('kostenets|\mhhi\M', 'kostenets', 'kostenets|hhi'),
  ('belovo|belana', 'belovo', 'belovo|belana'),
  ('lipo-?hart', null, 'lipo-?hart'),
  ('tri-?wall', null, 'tri-?wall'),
  ('\mema\M.*(paper|хартия)', null, '\mema\M.*(paper|хартия)'),
  ('kostenets paper', null, 'kostenets paper')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('\mgff\M|gff paper', 'nikopol', 'gff',
   $pj${"owner": "GFF", "priority": 1, "products": "Tissue jumbo rolls, toilet, kitchen, napkins", "grades": ["Tissue"], "machines": 2, "capacity": {"value": 40000, "unit": "metric_t", "year": "Company figure", "source": "gffpapermill.com"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.01}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Report scenario 1-5 pct."}, "pitch": "Compare FCC on flat-wire and crescent machines", "approach": "Virgin vs recycled furnish trial.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('kostenets|\mhhi\M', 'kostenets', 'kostenets|hhi',
   $pj${"owner": "Kostenets HHI", "priority": 2, "products": "Tissue, MG paper, recycled fluting", "grades": ["Tissue", "MG paper", "Medium"], "machines": 3, "capacity": {"value": 50000, "unit": "metric_t", "year": "Company (PM1 8 + PM2 15 + PM3 27, upper)", "source": "hhi-bg.eu"}, "capacity_split": [{"label": "PM3 tissue", "value_t": 27000}, {"label": "PM2 MG or tissue", "value_t": 15000}, {"label": "PM1 fluting", "value_t": 8000}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 0.54, "fcc_loading": 0.01}, {"label": "Base", "utilization": 1, "fcc_share": 0.54, "fcc_loading": 0.05}], "note": "PM3 tissue share only."}, "approach": "PM3 tissue trial, compare with PM2.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('belovo|belana', 'belovo', 'belovo|belana',
   $pj${"owner": "Belovo", "products": "Tissue, packaging paper", "grades": ["Tissue"], "machines": 4, "capacity": {"value": 58000, "unit": "metric_t", "year": "Company figure", "source": "belana.bg"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.01}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Report scenario 1-5 pct."}, "pitch": "Tissue FCC 1-3-5 pct trial", "approach": "Lead Bulgarian account - Calcit PCC or Kaolin as local producer.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('lipo-?hart', null, 'lipo-?hart',
   $pj${"owner": "Lipo-Hart", "products": "Corrugated and micro-flute boxes, Kostinbrod - converter", "approach": "Converter or related entity.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('tri-?wall', null, 'tri-?wall',
   $pj${"owner": "Tri-Wall Bulgaria", "products": "New corrugated packaging plant at Trakia Economic Zone (EUR 30 m+, groundbreaking 2026-01-28) - converter", "approach": "Converter or related entity.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mema\M.*(paper|хартия)', null, '\mema\M.*(paper|хартия)',
   $pj${"owner": "EMA", "products": "Paper distribution and converting, Pleven", "approach": "Converter or related entity.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('kostenets paper', null, 'kostenets paper',
   $pj${"owner": "Kostenets Paper Mill AD", "products": "Registered paper and board entity on the Kostenets site - see Kostenets HHI row", "approach": "Converter or related entity.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'BG', 'Bulgaria', 'medium',
   $cm$Tissue at GFF Nikopol (40 kt) and Kostenets PM3 (27 kt) - Belovo in liquidation - local PCC maker Calcit Asenovgrad$cm$,
   $cm$Bulgaria is a tissue market, now led by GFF Nikopol (40 kt, two machines) and Kostenets HHI (PM3 tissue 27 kt plus MG and fluting) - Belovo (Belana, 58 kt historical) shows as in liquidation (2026-10). Nova Knizhna Fabrika makes recycled fluting. Mondi Stambolijski closed after the 2024 fire (residual assets sold 2026-04), Svilocell pulp stopped (2026). Fillers: Calcit JSC PCC at Asenovgrad (coarse, paper named in SDS), Kaolin EAD (Quarzwerke), Bulterra marble GCC, Zlatna Panega micronized limestone (TITAN), lime at SMA Mineral and Ognyanovo K, Omya Bulgaria sales office.$cm$,
   $cm${"fillers": "PCC: Calcit JSC Asenovgrad. GCC: Kaolin EAD (Quarzwerke since 2013), Bulterra S, Zlatna Panega Cement (TITAN micronized limestone). Lime: SMA Mineral Burgas Var, Ognyanovo K. Raw: Skalni Materiali. Licensee office: Omya Bulgaria. Not added: Heidelberg Materials Devnya, Carboplast. 2024 carbonate imports mainly Greece, Turkey, Germany, Serbia, Netherlands.", "mills": "Tissue: GFF Nikopol, Kostenets HHI, Belovo (in liquidation). Recycled fluting: Nova Knizhna Fabrika. Closed or stopped: Mondi Stambolijski, Svilocell. Converters: Dunapack-Rodina, Velpa 91, Vitavel, Lipo-Hart, Tri-Wall (new 2026), EMA.", "strategy": "Tissue trial at GFF (15 gsm virgin, FCC 3-5-7 pct) and Kostenets PM3, with Calcit PCC or Kaolin as local producer. Watch Belovo for a new owner.", "risks": "Calcit PCC is coarse - may need a new fine line.", "next_steps": ["Propose a tissue trial to Belovo", "Ask Calcit for paper-grade PCC and slurry capacity"], "key_numbers": [{"label": "Active tissue nameplate", "value": "about 67 kt (GFF 40 + Kostenets PM3 27)"}, {"label": "Belovo", "value": "58 kt historical, in liquidation"}], "files": ["seed_20261016zg_bulgaria_mills_fillers", "seed_20261016zi_bulgaria_update"]}$cm$::jsonb,
   $cm$GFF Nikopol(4만 t)·Kostenets PM3(2.7만 t) 티슈 — Belovo 청산 절차 — 현지 PCC 제조사 Calcit Asenovgrad$cm$,
   $cm$불가리아 티슈 시장은 이제 GFF Nikopol(4만 t)·Kostenets HHI(PM3 2.7만 t) 중심 — Belovo(과거 5.8만 t)는 청산 절차(2026-10). Nova Knizhna 재생 플루팅. Mondi Stambolijski 폐쇄(2026-04 잔여자산 매각), Svilocell 중단. 충전제: Calcit JSC PCC, Kaolin EAD(Quarzwerke), Bulterra, Zlatna Panega(TITAN) 미분 석회석, SMA Mineral·Ognyanovo K 석회, Omya Bulgaria 영업소.$cm$,
   670, 3350,
   $cm$GFF 4만 + Kostenets PM3 2.7만 t × FCC 1~5% (Belovo 제외)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('\mgff\M|gff paper', 'nikopol', 'gff'),
  ('kostenets|\mhhi\M', 'kostenets', 'kostenets|hhi'),
  ('belovo|belana', 'belovo', 'belovo|belana'),
  ('lipo-?hart', null, 'lipo-?hart'),
  ('tri-?wall', null, 'tri-?wall'),
  ('\mema\M.*(paper|хартия)', null, '\mema\M.*(paper|хартия)'),
  ('kostenets paper', null, 'kostenets paper')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'bulgaria_update_20261016b' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'bulgaria_update_20261016b' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'zlatna panega' or p.party_name ~* 'sma mineral|burgas var' or p.party_name ~* 'ognyanovo' or p.party_name ~* 'skalni materiali')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'BG'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'BG'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'BG'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    