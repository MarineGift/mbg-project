-- ============================================================
-- seed_20261016zzzx_gabon_market.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Gabon update (reports 2026-10-17). No paper machine - no mill rows.
-- CIMAF guard is country-scoped (CIMAF also in ML, MR, TD).
-- 1) Fillers if missing (2): CIMAF Gabon, CIMGABON (limestone permits).
-- 2) Context, match only (3): SATOGA, Cartonnerie du Gabon, PROPACK.
-- 3) app.country_markets GA row (priority none).
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
           v.party_name, 'GA', v.region, v.city, v.website, 'active', 'gabon_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('cimaf.*gabon|ciments de l.afrique.*gabon|m[eé]ba', 'CIMAF Gabon - Méba', 'Estuaire', 'Méba', null, 'CIMAF 가봉 — Estuaire Méba 석회석 채석 허가 약 9.20 km²(EITI 2021, 2024-02-24 만료 — 갱신 확인).', 'Ciments de l''Afrique (CIMAF) Gabon - limestone quarry permit of about 9.20 km2 at Méba (Estuaire), EITI 2021, expiry 2024-02-24 - renewal to check.', 'GA check 2026-10-16: cement stone - CaCO3, brightness, Fe untested.'),
  ('cimgabon|ciment du gabon', 'CIMGABON - Ntoum', 'Estuaire', 'Ntoum', null, 'CIMGABON Ntoum 석회석 채석 허가 약 1.99 km²(1979~2054, EITI).', 'Ciment du Gabon (CIMGABON), Ntoum (Estuaire) - limestone quarry permit of about 1.99 km2 valid 1979-2054 (EITI).', 'GA check 2026-10-16: raw-material lead. Kéri quarry near Mouila (Nyanga basin) is mainly dolomite. No Gabonese paper PCC or GCC, no Omya, MTI, Imerys or Sibelco plant.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%GA check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('cimaf.*gabon|ciments de l.afrique.*gabon|m[eé]ba', 'CIMAF Gabon - Méba', 'Estuaire', 'Méba', null, 'CIMAF 가봉 — Estuaire Méba 석회석 채석 허가 약 9.20 km²(EITI 2021, 2024-02-24 만료 — 갱신 확인).', 'Ciments de l''Afrique (CIMAF) Gabon - limestone quarry permit of about 9.20 km2 at Méba (Estuaire), EITI 2021, expiry 2024-02-24 - renewal to check.', 'GA check 2026-10-16: cement stone - CaCO3, brightness, Fe untested.'),
  ('cimgabon|ciment du gabon', 'CIMGABON - Ntoum', 'Estuaire', 'Ntoum', null, 'CIMGABON Ntoum 석회석 채석 허가 약 1.99 km²(1979~2054, EITI).', 'Ciment du Gabon (CIMGABON), Ntoum (Estuaire) - limestone quarry permit of about 1.99 km2 valid 1979-2054 (EITI).', 'GA check 2026-10-16: raw-material lead. Kéri quarry near Mouila (Nyanga basin) is mainly dolomite. No Gabonese paper PCC or GCC, no Omya, MTI, Imerys or Sibelco plant.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'gabon_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('CIMAF Gabon - Méba', 'Limestone owner (cement)', 'Limestone permit - raw-material lead', 'merchant', 'C', 'gcc'),
  ('CIMGABON - Ntoum', 'Limestone owner (cement)', 'Limestone permit - raw-material lead', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'gabon_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%GA check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('satoga', null, 'satoga', null, null, 'GA check 2026-10-16: SATOGA, Z.I. Oloumi Libreville - tissue converting (Papyrus, Santa Barbara, Lilas, Sanitex, Dallas), imports paper of Côte d''Ivoire - machine not confirmed - context only.'),
  ('cartonnerie du gabon|foberd', null, 'cartonnerie du gabon|foberd', null, null, 'GA check 2026-10-16: Cartonnerie du Gabon, Nkok SEZ (2023) - corrugator, printing and die-cutting, 25 staff - context only.'),
  ('propack', null, 'propack', null, null, 'GA check 2026-10-16: PROPACK Gabon, Libreville - corrugated and printed packaging - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'gabon_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('satoga', null, 'satoga'),
  ('cartonnerie du gabon|foberd', null, 'cartonnerie du gabon|foberd'),
  ('propack', null, 'propack')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('satoga', null, 'satoga', true,
   $pj${"owner": "SATOGA", "products": "SATOGA, Z.I. Oloumi Libreville - tissue converting (Papyrus, Santa Barbara, Lilas, Sanitex, Dallas), imports paper of Côte d'Ivoire - machine not confirmed", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('cartonnerie du gabon|foberd', null, 'cartonnerie du gabon|foberd', true,
   $pj${"owner": "FOBERD Gabon", "products": "Cartonnerie du Gabon, Nkok SEZ (2023) - corrugator, printing and die-cutting, 25 staff", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('propack', null, 'propack', true,
   $pj${"owner": "PROPACK Gabon", "products": "PROPACK Gabon, Libreville - corrugated and printed packaging", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'GA', 'Gabon', 'none',
   $cm$No paper machine - SATOGA tissue and two corrugated converters (Cartonnerie du Gabon, PROPACK) - cement limestone permits only$cm$,
   $cm$Gabon converts imported paper: SATOGA (Oloumi, tissue brands, imports paper of Côte d'Ivoire), Cartonnerie du Gabon (Nkok SEZ, 2023, FOBERD group corrugator) and PROPACK (Libreville, packaging). HS 48 supply mainly China, France, Tunisia, Türkiye, Morocco (2024). No paper PCC or GCC - CIMAF (Méba) and CIMGABON (Ntoum) hold limestone permits, Kéri (Mouila) is dolomite.$cm$,
   $cm${"fillers": "Limestone: CIMAF Gabon, CIMGABON. No PCC or GCC.", "mills": "No paper machine. Context: SATOGA, Cartonnerie du Gabon, PROPACK.", "strategy": "Ask SATOGA about its jumbo-roll source (likely Ivorian mills).", "risks": "No direct volume.", "next_steps": ["Ask SATOGA about tissue machine or jumbo-roll supplier"], "key_numbers": [], "files": ["seed_20261016zzzx_gabon_market"]}$cm$::jsonb,
   $cm$초지기 없음 — SATOGA 티슈·골판지 가공 2곳(Cartonnerie du Gabon, PROPACK) — 시멘트 석회석 허가뿐$cm$,
   $cm$가봉은 수입 종이 가공: SATOGA(Oloumi, 티슈 브랜드, 코트디부아르산 종이 수입), Cartonnerie du Gabon(Nkok 특구, 2023, FOBERD 그룹 골판지), PROPACK(Libreville, 포장재). HS 48 주로 중국·프랑스·튀니지·튀르키예·모로코(2024). 제지용 PCC·GCC 없음 — CIMAF(Méba)·CIMGABON(Ntoum) 석회석 허가, Kéri(Mouila)는 백운석.$cm$,
   null, null,
   $cm$초지기 없음 — 직접 수요 없음$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('satoga', null, 'satoga'),
  ('cartonnerie du gabon|foberd', null, 'cartonnerie du gabon|foberd'),
  ('propack', null, 'propack')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'gabon_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'gabon_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'cimaf.*gabon|ciments de l.afrique.*gabon|m[eé]ba' or p.party_name ~* 'cimgabon|ciment du gabon')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'GA'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'GA'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'GA'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    