-- ============================================================
-- seed_20261016zzzk_botswana_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Botswana update (reports 2026-10-17). ILCCMCo is Jordanian - not added here.
-- 1) Fillers if missing (2): PPC Botswana, Matsiloje (limestone).
-- 2) Mill if missing (1, no priority): Pulp and Paper Industries. Context (9):
--    converters.
-- 3) app.country_markets BW row (priority none).
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
           v.party_name, 'BW', v.region, v.city, v.website, 'active', 'botswana_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('ppc botswana', 'PPC Botswana - Gaborone', 'South-East', 'Gaborone', null, 'PPC Botswana(Gaborone West) 시멘트 혼합·포장 — Naka-la-Phala(Palapye·Serowe 사이) 석회석.', 'PPC Botswana, Plot 22034 Takatokwane Way, Gaborone West - cement blending and bagging, limestone identified at Naka-la-Phala (between Palapye and Serowe).', 'BW check 2026-10-16: no paper GCC or PCC. +267 390 1553.'),
  ('matsiloje', 'Matsiloje Portland Cement', 'North-East', 'Matsiloje', null, 'Matsiloje Portland Cement(Francistown 남동 45 km) 시멘트 연 3.6만 t(2016), KCL Technologies 석회석 채굴(1999~, 연 약 3만 t).', 'Matsiloje Portland Cement, Matsiloje (about 45 km SE of Francistown) - cement about 36,000 t/yr (2016 USGS), limestone quarried nearby by KCL Technologies since 1999 (about 30,000 t/yr then).', 'BW check 2026-10-16: status to confirm. ILCCMCo (GCC and PCC offer) is in Aqaba, Jordan - not Botswana. No Botswana paper PCC or GCC - Idwala Carbonates ships calcium products here (79 shipments 2024-07 to 2025-06).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%BW check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('ppc botswana', 'PPC Botswana - Gaborone', 'South-East', 'Gaborone', null, 'PPC Botswana(Gaborone West) 시멘트 혼합·포장 — Naka-la-Phala(Palapye·Serowe 사이) 석회석.', 'PPC Botswana, Plot 22034 Takatokwane Way, Gaborone West - cement blending and bagging, limestone identified at Naka-la-Phala (between Palapye and Serowe).', 'BW check 2026-10-16: no paper GCC or PCC. +267 390 1553.'),
  ('matsiloje', 'Matsiloje Portland Cement', 'North-East', 'Matsiloje', null, 'Matsiloje Portland Cement(Francistown 남동 45 km) 시멘트 연 3.6만 t(2016), KCL Technologies 석회석 채굴(1999~, 연 약 3만 t).', 'Matsiloje Portland Cement, Matsiloje (about 45 km SE of Francistown) - cement about 36,000 t/yr (2016 USGS), limestone quarried nearby by KCL Technologies since 1999 (about 30,000 t/yr then).', 'BW check 2026-10-16: status to confirm. ILCCMCo (GCC and PCC offer) is in Aqaba, Jordan - not Botswana. No Botswana paper PCC or GCC - Idwala Carbonates ships calcium products here (79 shipments 2024-07 to 2025-06).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'botswana_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('PPC Botswana - Gaborone', 'Limestone owner (cement)', 'Limestone - raw-material lead', 'merchant', 'C', 'gcc'),
  ('Matsiloje Portland Cement', 'Limestone owner (cement)', 'Limestone - raw-material lead', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'botswana_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'BW', v.region, v.city, v.website, 'active', 'botswana_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('pulp and paper industries|strides for success', 'mogoditshane', 'pulp and paper industries|strides', 'Pulp and Paper Industries (Strides for Success) - Mogoditshane', 'Kweneng', 'Mogoditshane', null, 'Strides for Success 자회사 Pulp and Paper Industries(Mogoditshane) — 폐지 월 약 2,000 t 수거(2022)·재활용 원료·화장지, 2023-09 공장 공식 출범.', 'Pulp and Paper Industries (Strides for Success), Mogoditshane - waste-paper recycling (about 2,000 t/month collected in 2022), recycled fibre for tissue, packaging and bags, toilet tissue sold to public bodies, plant launched 2023-09.', 'BW check 2026-10-16: paper machine and output to confirm - collection volume is not paper output.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BW'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%BW check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BW'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('pulp and paper industries|strides for success', 'mogoditshane', 'pulp and paper industries|strides', 'Strides for Success 자회사 Pulp and Paper Industries(Mogoditshane) — 폐지 월 약 2,000 t 수거(2022)·재활용 원료·화장지, 2023-09 공장 공식 출범.', 'Pulp and Paper Industries (Strides for Success), Mogoditshane - waste-paper recycling (about 2,000 t/month collected in 2022), recycled fibre for tissue, packaging and bags, toilet tissue sold to public bodies, plant launched 2023-09.', 'BW check 2026-10-16: paper machine and output to confirm - collection volume is not paper output.'),
  ('general packaging|genpack', null, 'general packaging|genpack', null, null, 'BW check 2026-10-16: General Packaging Industries (1980), Broadhurst Gaborone - corrugated boxes and plastic packaging, about 100 k boxes/month - context only.'),
  ('jewel paper', null, 'jewel paper', null, null, 'BW check 2026-10-16: Jewel Paper Products (2010), Phakalane - toilet tissue, napkins, towels incl. private labels - context only.'),
  ('fu ?qiang', null, 'fu ?qiang', null, null, 'BW check 2026-10-16: Fu Qiang, Gaborone - toilet tissue, wipes, diapers - context only.'),
  ('calm tissue', null, 'calm tissue', null, null, 'BW check 2026-10-16: Calm Tissue, Selebi-Phikwe (2025) - jumbo-roll converting - context only.'),
  ('\mslae\M', null, '\mslae\M', null, null, 'BW check 2026-10-16: Slae, Selebi-Phikwe - toilet tissue and cores - context only.'),
  ('enviro drive', null, 'enviro drive', null, null, 'BW check 2026-10-16: Tissue, towels, napkins, Mochudi area - context only.'),
  ('jubilation', null, 'jubilation', null, null, 'BW check 2026-10-16: Toilet paper, Gaborone - context only.'),
  ('xhumatshikhu|xuuxoo', null, 'xhumatshikhu|xuuxoo', null, null, 'BW check 2026-10-16: Small toilet-paper maker, Boteti - context only.'),
  ('holly fern', null, 'holly fern', null, null, 'BW check 2026-10-16: Tissue products, Selebi-Phikwe - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'botswana_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BW'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('pulp and paper industries|strides for success', 'mogoditshane', 'pulp and paper industries|strides'),
  ('general packaging|genpack', null, 'general packaging|genpack'),
  ('jewel paper', null, 'jewel paper'),
  ('fu ?qiang', null, 'fu ?qiang'),
  ('calm tissue', null, 'calm tissue'),
  ('\mslae\M', null, '\mslae\M'),
  ('enviro drive', null, 'enviro drive'),
  ('jubilation', null, 'jubilation'),
  ('xhumatshikhu|xuuxoo', null, 'xhumatshikhu|xuuxoo'),
  ('holly fern', null, 'holly fern')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BW'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('pulp and paper industries|strides for success', 'mogoditshane', 'pulp and paper industries|strides', false,
   $pj${"owner": "Strides for Success", "products": "Recycled fibre, toilet tissue", "grades": ["Tissue"], "approach": "Confirm paper machine first.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('general packaging|genpack', null, 'general packaging|genpack', true,
   $pj${"owner": "Genpack", "products": "General Packaging Industries (1980), Broadhurst Gaborone - corrugated boxes and plastic packaging, about 100 k boxes/month", "approach": "Converter - trace jumbo-roll supplier (likely ZA).", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('jewel paper', null, 'jewel paper', true,
   $pj${"owner": "Jewel Paper", "products": "Jewel Paper Products (2010), Phakalane - toilet tissue, napkins, towels incl. private labels", "approach": "Converter - trace jumbo-roll supplier (likely ZA).", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('fu ?qiang', null, 'fu ?qiang', true,
   $pj${"owner": "Fu Qiang", "products": "Fu Qiang, Gaborone - toilet tissue, wipes, diapers", "approach": "Converter - trace jumbo-roll supplier (likely ZA).", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('calm tissue', null, 'calm tissue', true,
   $pj${"owner": "Calm Tissue", "products": "Calm Tissue, Selebi-Phikwe (2025) - jumbo-roll converting", "approach": "Converter - trace jumbo-roll supplier (likely ZA).", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mslae\M', null, '\mslae\M', true,
   $pj${"owner": "Slae Manufactures", "products": "Slae, Selebi-Phikwe - toilet tissue and cores", "approach": "Converter - trace jumbo-roll supplier (likely ZA).", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('enviro drive', null, 'enviro drive', true,
   $pj${"owner": "Enviro Drive", "products": "Tissue, towels, napkins, Mochudi area", "approach": "Converter - trace jumbo-roll supplier (likely ZA).", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('jubilation', null, 'jubilation', true,
   $pj${"owner": "Jubilation", "products": "Toilet paper, Gaborone", "approach": "Converter - trace jumbo-roll supplier (likely ZA).", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('xhumatshikhu|xuuxoo', null, 'xhumatshikhu|xuuxoo', true,
   $pj${"owner": "Xuuxoo", "products": "Small toilet-paper maker, Boteti", "approach": "Converter - trace jumbo-roll supplier (likely ZA).", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('holly fern', null, 'holly fern', true,
   $pj${"owner": "Holly Fern", "products": "Tissue products, Selebi-Phikwe", "approach": "Converter - trace jumbo-roll supplier (likely ZA).", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'BW', 'Botswana', 'none',
   $cm$No confirmed paper machine or paper filler plant - tissue and box converters, recycling start-up (Pulp and Paper Industries) - supplied by South Africa$cm$,
   $cm$Botswana's paper sector is mainly converters: Genpack (corrugated), Jewel Paper, Fu Qiang, Calm Tissue, Slae and other small tissue makers on imported jumbo rolls. Pulp and Paper Industries (Strides for Success, Mogoditshane) recycles waste paper and makes toilet tissue since 2023 - paper machine to confirm. No paper PCC or GCC - limestone at PPC Botswana (Naka-la-Phala) and Matsiloje. Idwala Carbonates (ZA) already ships calcium products to Botswana. Treat as part of a South Africa - Botswana - Zimbabwe supply zone.$cm$,
   $cm${"fillers": "Limestone: PPC Botswana, Matsiloje. Note: ILCCMCo is Jordanian. Supply: Idwala / Omya Idwala (ZA).", "mills": "To confirm: Pulp and Paper Industries. Context: Genpack, Jewel, Fu Qiang, Calm Tissue, Slae and small tissue makers.", "strategy": "Trace jumbo-roll suppliers (South African mills), check the Mogoditshane machine. Serve via ZA.", "risks": "No direct volume.", "next_steps": ["Ask Pulp and Paper Industries about its paper machine"], "key_numbers": [{"label": "Waste-paper collection (2022)", "value": "about 2,000 t/month"}], "files": ["seed_20261016zzzk_botswana_mills_fillers"]}$cm$::jsonb,
   $cm$초지기·제지용 충전제 공장 미확인 — 티슈·상자 가공, 재활용 신생업체(Pulp and Paper Industries) — 남아공 공급$cm$,
   $cm$보츠와나 제지업은 주로 가공: Genpack(골판지), Jewel Paper, Fu Qiang, Calm Tissue, Slae 등 수입 점보롤 티슈 업체. Pulp and Paper Industries(Strides for Success, Mogoditshane)가 2023년부터 폐지 재활용·화장지 — 초지기 확인 필요. 제지용 PCC·GCC 없음 — PPC Botswana(Naka-la-Phala)·Matsiloje 석회석. Idwala Carbonates(ZA)가 이미 칼슘 제품 공급. 남아공-보츠와나-짐바브웨 공급권역으로 관리.$cm$,
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
      ('pulp and paper industries|strides for success', 'mogoditshane', 'pulp and paper industries|strides'),
  ('general packaging|genpack', null, 'general packaging|genpack'),
  ('jewel paper', null, 'jewel paper'),
  ('fu ?qiang', null, 'fu ?qiang'),
  ('calm tissue', null, 'calm tissue'),
  ('\mslae\M', null, '\mslae\M'),
  ('enviro drive', null, 'enviro drive'),
  ('jubilation', null, 'jubilation'),
  ('xhumatshikhu|xuuxoo', null, 'xhumatshikhu|xuuxoo'),
  ('holly fern', null, 'holly fern')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'botswana_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BW'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'botswana_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'ppc botswana' or p.party_name ~* 'matsiloje')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'BW'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'BW'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'BW'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BW'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    