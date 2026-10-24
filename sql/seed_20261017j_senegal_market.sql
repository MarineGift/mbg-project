-- ============================================================
-- seed_20261017j_senegal_market.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Senegal (SN) update (reports 2026-10-17). No confirmed paper machine -
-- no mill rows. Klingele guard is country-scoped (also MR).
-- 1) Fillers if missing (2): Les Sablières du Sahel (GCC), SOCOCIM.
-- 2) Context, match only (10): converters.
-- 3) app.country_markets SN row (priority none).
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
           v.party_name, 'SN', v.region, v.city, v.website, 'active', 'senegal_update_20261017',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('sabli[eè]res du sahel|\msds\M.*s[eé]n[eé]gal', 'Les Sablières du Sahel - Tassette', 'Thiès', 'Tassette', null, 'Les Sablières du Sahel(Tassette Km1) GCC 제조 — Standard 90~95%·0~100 μm, Micronisé 95~98%·2~40 μm(도료·PVC·플라스틱), 사료용, E170 식품 등급 예정.', 'Les Sablières du Sahel (SDS), Tassette Km1 - makes GCC: Standard 90-95 pct CaCO3, 0-100 micron, Micronisé 95-98 pct, 2-40 micron for paint, PVC and plastics, a feed grade, E170 food grade planned. Cites about 36 kt/yr Senegalese CaCO3 imports.', 'SN check 2026-10-17: no paper grade - ask ISO brightness, D50 / D90, under-2-micron share, Fe2O3, abrasion, wet grinding. contact@sablieresdusahel.com, +221 77 557 69 38. Only confirmed GCC maker in Senegal - candidate 1.'),
  ('sococim', 'SOCOCIM (Vicat) - Rufisque', 'Dakar', 'Rufisque', null, 'Vicat 계열 SOCOCIM(Rufisque) 시멘트 — Bandia 석회석 채굴권. Pout–Bandia–Thiès 일부 석회석층 평균 CaCO3 약 96.6%.', 'SOCOCIM Industries (Vicat), Rufisque cement plant with the Bandia limestone concession. Some Pout-Bandia-Thiès beds average about 96.6 pct CaCO3.', 'SN check 2026-10-17: raw-material lead. Not added: Les Ciments du Sahel (Kirène), Dangote Cement Sénégal (Pout). No Senegalese paper PCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%SN check 2026-10-17%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('sabli[eè]res du sahel|\msds\M.*s[eé]n[eé]gal', 'Les Sablières du Sahel - Tassette', 'Thiès', 'Tassette', null, 'Les Sablières du Sahel(Tassette Km1) GCC 제조 — Standard 90~95%·0~100 μm, Micronisé 95~98%·2~40 μm(도료·PVC·플라스틱), 사료용, E170 식품 등급 예정.', 'Les Sablières du Sahel (SDS), Tassette Km1 - makes GCC: Standard 90-95 pct CaCO3, 0-100 micron, Micronisé 95-98 pct, 2-40 micron for paint, PVC and plastics, a feed grade, E170 food grade planned. Cites about 36 kt/yr Senegalese CaCO3 imports.', 'SN check 2026-10-17: no paper grade - ask ISO brightness, D50 / D90, under-2-micron share, Fe2O3, abrasion, wet grinding. contact@sablieresdusahel.com, +221 77 557 69 38. Only confirmed GCC maker in Senegal - candidate 1.'),
  ('sococim', 'SOCOCIM (Vicat) - Rufisque', 'Dakar', 'Rufisque', null, 'Vicat 계열 SOCOCIM(Rufisque) 시멘트 — Bandia 석회석 채굴권. Pout–Bandia–Thiès 일부 석회석층 평균 CaCO3 약 96.6%.', 'SOCOCIM Industries (Vicat), Rufisque cement plant with the Bandia limestone concession. Some Pout-Bandia-Thiès beds average about 96.6 pct CaCO3.', 'SN check 2026-10-17: raw-material lead. Not added: Les Ciments du Sahel (Kirène), Dangote Cement Sénégal (Pout). No Senegalese paper PCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'senegal_update_20261017';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Les Sablières du Sahel - Tassette', 'GCC producer', 'Micronised GCC (no paper grade yet) - candidate 1', 'merchant', 'C', 'gcc'),
  ('SOCOCIM (Vicat) - Rufisque', 'Limestone owner (cement)', 'Limestone concession - raw-material lead', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'senegal_update_20261017'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%SN check 2026-10-17%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SN'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('rochette', null, 'rochette', null, null, 'SN check 2026-10-17: La Rochette Dakar, Km 13.7 Route de Rufisque - corrugated, folding cartons, kraft bags, about 80 pct of Senegal boxes (2018), BOBST lines - no paper machine - context only.'),
  ('\msips\M|industrielle de papeterie au s[eé]n[eé]gal', null, '\msips\M|industrielle de papeterie au s[eé]n[eé]gal', null, null, 'SN check 2026-10-17: SIPS, Km 11 Route de Rufisque - notebooks and paper products - machine not confirmed - context only.'),
  ('\mmsp\M.*dakar|papiers transform[eé]s', null, '\mmsp\M.*dakar|papiers transform[eé]s', null, null, 'SN check 2026-10-17: MSP (DISTINGO notebooks), Km 14 Route de Rufisque - context only.'),
  ('transpaps', null, 'transpaps', null, null, 'SN check 2026-10-17: TRANSPAPS, Bd du Centenaire Dakar - toilet tissue, facial, towels, diapers - tissue machine to confirm - context only.'),
  ('rufsac', null, 'rufsac', null, null, 'SN check 2026-10-17: RUFSAC, Cap des Biches - multiwall kraft sacks and paper bags - context only.'),
  ('\mseis\M', null, '\mseis\M', null, null, 'SN check 2026-10-17: SEIS SARL, Diamniadio (2021) - corrugated packaging of kraft and testliner - context only.'),
  ('mondial paper', null, 'mondial paper', null, null, 'SN check 2026-10-17: Mondial Paper, Km 2.5 Route de Rufisque - reel import, sheeting and slitting, about 4.5 kt/yr handled - context only.'),
  ('sipexs', null, 'sipexs', null, null, 'SN check 2026-10-17: SIPEXS (ESPOIR, TERANGA notebooks), Dakar - context only.'),
  ('polykrome', null, 'polykrome', null, null, 'SN check 2026-10-17: Polykrome, Keur Moussa - labels and printed packaging - context only.'),
  ('klingele.*s[eé]n[eé]gal', null, 'klingele.*s[eé]n[eé]gal', null, null, 'SN check 2026-10-17: Klingele Emballage Senegal, Deni Mali Gueye - corrugated packaging - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'senegal_update_20261017';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SN'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('rochette', null, 'rochette'),
  ('\msips\M|industrielle de papeterie au s[eé]n[eé]gal', null, '\msips\M|industrielle de papeterie au s[eé]n[eé]gal'),
  ('\mmsp\M.*dakar|papiers transform[eé]s', null, '\mmsp\M.*dakar|papiers transform[eé]s'),
  ('transpaps', null, 'transpaps'),
  ('rufsac', null, 'rufsac'),
  ('\mseis\M', null, '\mseis\M'),
  ('mondial paper', null, 'mondial paper'),
  ('sipexs', null, 'sipexs'),
  ('polykrome', null, 'polykrome'),
  ('klingele.*s[eé]n[eé]gal', null, 'klingele.*s[eé]n[eé]gal')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SN'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('rochette', null, 'rochette', true,
   $pj${"owner": "La Rochette Dakar", "products": "La Rochette Dakar, Km 13.7 Route de Rufisque - corrugated, folding cartons, kraft bags, about 80 pct of Senegal boxes (2018), BOBST lines - no paper machine", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('\msips\M|industrielle de papeterie au s[eé]n[eé]gal', null, '\msips\M|industrielle de papeterie au s[eé]n[eé]gal', true,
   $pj${"owner": "SIPS", "products": "SIPS, Km 11 Route de Rufisque - notebooks and paper products - machine not confirmed", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('\mmsp\M.*dakar|papiers transform[eé]s', null, '\mmsp\M.*dakar|papiers transform[eé]s', true,
   $pj${"owner": "MSP", "products": "MSP (DISTINGO notebooks), Km 14 Route de Rufisque", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('transpaps', null, 'transpaps', true,
   $pj${"owner": "TRANSPAPS", "products": "TRANSPAPS, Bd du Centenaire Dakar - toilet tissue, facial, towels, diapers - tissue machine to confirm", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('rufsac', null, 'rufsac', true,
   $pj${"owner": "RUFSAC", "products": "RUFSAC, Cap des Biches - multiwall kraft sacks and paper bags", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('\mseis\M', null, '\mseis\M', true,
   $pj${"owner": "SEIS", "products": "SEIS SARL, Diamniadio (2021) - corrugated packaging of kraft and testliner", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('mondial paper', null, 'mondial paper', true,
   $pj${"owner": "Mondial Paper", "products": "Mondial Paper, Km 2.5 Route de Rufisque - reel import, sheeting and slitting, about 4.5 kt/yr handled", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('sipexs', null, 'sipexs', true,
   $pj${"owner": "SIPEXS", "products": "SIPEXS (ESPOIR, TERANGA notebooks), Dakar", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('polykrome', null, 'polykrome', true,
   $pj${"owner": "Polykrome", "products": "Polykrome, Keur Moussa - labels and printed packaging", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('klingele.*s[eé]n[eé]gal', null, 'klingele.*s[eé]n[eé]gal', true,
   $pj${"owner": "Klingele Group", "products": "Klingele Emballage Senegal, Deni Mali Gueye - corrugated packaging", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-17"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'SN', 'Senegal', 'none',
   $cm$No confirmed paper machine - Dakar-Rufisque converting belt (La Rochette, SIPS, TRANSPAPS, RUFSAC, Mondial Paper) - SDS micronised GCC, Pout-Bandia limestone$cm$,
   $cm$Senegal has a sizeable converting belt along the Route de Rufisque but no confirmed paper machine: La Rochette Dakar (corrugated, about 80 pct of boxes in 2018), SEIS, Klingele (corrugated), RUFSAC (kraft sacks), SIPS, MSP, SIPEXS (notebooks), TRANSPAPS (tissue - machine to confirm), Mondial Paper (reel sheeting, about 4.5 kt/yr), Polykrome. HS 48 imports about USD 139.8 m in 2024 (Morocco, Spain, China, Germany, Sweden). Fillers: Les Sablières du Sahel makes GCC (micronised 2-40 micron, not paper grade) and SOCOCIM holds Bandia limestone - no paper PCC. Senegal supplies paper to Gambia and Guinea-Bissau.$cm$,
   $cm${"fillers": "GCC: Les Sablières du Sahel. Limestone: SOCOCIM. Not added: Ciments du Sahel, Dangote. No PCC.", "mills": "No confirmed machine. Context: La Rochette Dakar, SIPS, MSP, TRANSPAPS, RUFSAC, SEIS, Mondial Paper, SIPEXS, Polykrome, Klingele Senegal.", "strategy": "Confirm TRANSPAPS and SIPS processes, ask Mondial Paper and La Rochette which foreign mills supply them (Moroccan, Spanish, Swedish mills).", "risks": "No local machine confirmed.", "next_steps": ["Ask TRANSPAPS whether it runs a tissue machine", "Request SDS fine-grade data"], "key_numbers": [{"label": "HS 48 imports 2024", "value": "about USD 139.8 m"}, {"label": "Mondial Paper", "value": "about 4.5 kt/yr handled"}], "files": ["seed_20261017j_senegal_market"]}$cm$::jsonb,
   $cm$초지기 미확인 — 다카르-루피스크 가공벨트(La Rochette, SIPS, TRANSPAPS, RUFSAC, Mondial Paper) — SDS 미분 GCC, Pout-Bandia 석회석$cm$,
   $cm$세네갈은 Route de Rufisque 에 큰 가공벨트가 있으나 초지기 미확인: La Rochette Dakar(골판지, 2018 상자 80%), SEIS·Klingele(골판지), RUFSAC(크라프트 포대), SIPS·MSP·SIPEXS(공책), TRANSPAPS(티슈 — 초지기 확인), Mondial Paper(원지 재단 약 4.5천 t), Polykrome. HS 48 수입 2024 약 1.398억 달러(모로코·스페인·중국·독일·스웨덴). 충전제: Les Sablières du Sahel GCC(미분 2~40 μm, 제지용 아님), SOCOCIM Bandia 석회석 — 제지용 PCC 없음. 감비아·기니비사우에 종이 공급.$cm$,
   null, null,
   $cm$초지기 미확인 — 산정 안 함$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('rochette', null, 'rochette'),
  ('\msips\M|industrielle de papeterie au s[eé]n[eé]gal', null, '\msips\M|industrielle de papeterie au s[eé]n[eé]gal'),
  ('\mmsp\M.*dakar|papiers transform[eé]s', null, '\mmsp\M.*dakar|papiers transform[eé]s'),
  ('transpaps', null, 'transpaps'),
  ('rufsac', null, 'rufsac'),
  ('\mseis\M', null, '\mseis\M'),
  ('mondial paper', null, 'mondial paper'),
  ('sipexs', null, 'sipexs'),
  ('polykrome', null, 'polykrome'),
  ('klingele.*s[eé]n[eé]gal', null, 'klingele.*s[eé]n[eé]gal')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'senegal_update_20261017' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SN'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'senegal_update_20261017' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'sabli[eè]res du sahel|\msds\M.*s[eé]n[eé]gal' or p.party_name ~* 'sococim')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'SN'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'SN'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'SN'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SN'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    