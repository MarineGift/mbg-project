-- ============================================================
-- seed_20261017c_burkina_market.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Burkina Faso (BF) update (reports 2026-10-17). No paper machine - no mill rows.
-- 1) Fillers if missing (2): SOFANEC, Carrières et Mines du Burkina (dolomite).
-- 2) Context, match only (6): packaging, printing, paper trade.
-- 3) app.country_markets BF row (priority none).
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
           v.party_name, 'BF', v.region, v.city, v.website, 'active', 'burkina_update_20261017',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('sofanec', 'SOFANEC - Bobo-Dioulasso', 'Hauts-Bassins', 'Bobo-Dioulasso', null, 'SOFANEC(Bobo-Dioulasso) 돌로마이트 파쇄·선별·시멘트 원료·농업용 광물, 서아프리카 유통.', 'SOFANEC (Société de Fabrique et de Négoce en Ciment), Bobo-Dioulasso - dolomite crushing and screening, cement raw materials and agricultural minerals, West African sales.', 'BF check 2026-10-17: dolomite (high Mg) - check CaCO3 before any GCC use. contact@sofanec.bf, +226 25 46 95 46.'),
  ('carri[eè]res et mines du burkina|dand[eé]', 'Carrières et Mines du Burkina - Dandé', 'Hauts-Bassins', 'Dandé', null, 'Carrières et Mines du Burkina — Houet Dandé 4·5 돌로마이트질 석회석 채석 허가(ITIE-BF, Dandé 5 갱신).', 'Carrières et Mines du Burkina SARL - dolomitic limestone quarry permits Dandé 4 and 5 (Houet), Dandé 5 renewed (ITIE-BF).', 'BF check 2026-10-17: raw-material lead. Not added: AF''Gri-culture (Ouagadougou carbonate seller), CIMAF Burkina (two grinding plants, 1 Mt, Souroukoudinga permit), Bobo Diamond Cement (Bouendé permit), Fluent Burkina (planned 1 Mt dolomite exports to CI). No Burkinabè paper PCC or GCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%BF check 2026-10-17%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('sofanec', 'SOFANEC - Bobo-Dioulasso', 'Hauts-Bassins', 'Bobo-Dioulasso', null, 'SOFANEC(Bobo-Dioulasso) 돌로마이트 파쇄·선별·시멘트 원료·농업용 광물, 서아프리카 유통.', 'SOFANEC (Société de Fabrique et de Négoce en Ciment), Bobo-Dioulasso - dolomite crushing and screening, cement raw materials and agricultural minerals, West African sales.', 'BF check 2026-10-17: dolomite (high Mg) - check CaCO3 before any GCC use. contact@sofanec.bf, +226 25 46 95 46.'),
  ('carri[eè]res et mines du burkina|dand[eé]', 'Carrières et Mines du Burkina - Dandé', 'Hauts-Bassins', 'Dandé', null, 'Carrières et Mines du Burkina — Houet Dandé 4·5 돌로마이트질 석회석 채석 허가(ITIE-BF, Dandé 5 갱신).', 'Carrières et Mines du Burkina SARL - dolomitic limestone quarry permits Dandé 4 and 5 (Houet), Dandé 5 renewed (ITIE-BF).', 'BF check 2026-10-17: raw-material lead. Not added: AF''Gri-culture (Ouagadougou carbonate seller), CIMAF Burkina (two grinding plants, 1 Mt, Souroukoudinga permit), Bobo Diamond Cement (Bouendé permit), Fluent Burkina (planned 1 Mt dolomite exports to CI). No Burkinabè paper PCC or GCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'burkina_update_20261017';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('SOFANEC - Bobo-Dioulasso', 'Dolomite processor', 'Dolomite crushing - raw-material lead', 'merchant', 'C', 'gcc'),
  ('Carrières et Mines du Burkina - Dandé', 'Dolomitic limestone quarry', 'Dolomitic limestone - raw-material lead', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'burkina_update_20261017'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%BF check 2026-10-17%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BF'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('sonaceb', null, 'sonaceb', null, null, 'BF check 2026-10-17: SONACEB (Société Nationale de Cartons et d''Emballages du Burkina) - board and packaging, machine not confirmed - context only.'),
  ('faso sachets', null, 'faso sachets', null, null, 'BF check 2026-10-17: Faso Sachets, Ouagadougou - D&B paper listing, process unknown - context only.'),
  ('kabre bassirou', null, 'kabre bassirou', null, null, 'BF check 2026-10-17: ETS Kabre Bassirou et Frères, Ouagadougou - D&B paper listing - context only.'),
  ('impricolor', null, 'impricolor', null, null, 'BF check 2026-10-17: Impricolor (2003), Ouagadougou - offset printing and printed packaging - context only.'),
  ('sogecop', null, 'sogecop', null, null, 'BF check 2026-10-17: SOGECOP, Ouaga 2000 - printing, paper supply - context only.'),
  ('prodiconseil', null, 'prodiconseil', null, null, 'BF check 2026-10-17: Prodiconseil - paper supply via Abidjan, Lomé and Tema ports - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'burkina_update_20261017';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BF'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('sonaceb', null, 'sonaceb'),
  ('faso sachets', null, 'faso sachets'),
  ('kabre bassirou', null, 'kabre bassirou'),
  ('impricolor', null, 'impricolor'),
  ('sogecop', null, 'sogecop'),
  ('prodiconseil', null, 'prodiconseil')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BF'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('sonaceb', null, 'sonaceb', true,
   $pj${"owner": "SONACEB", "products": "SONACEB (Société Nationale de Cartons et d'Emballages du Burkina) - board and packaging, machine not confirmed", "approach": "Converter or distributor.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('faso sachets', null, 'faso sachets', true,
   $pj${"owner": "Faso Sachets", "products": "Faso Sachets, Ouagadougou - D&B paper listing, process unknown", "approach": "Converter or distributor.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('kabre bassirou', null, 'kabre bassirou', true,
   $pj${"owner": "Kabre Bassirou", "products": "ETS Kabre Bassirou et Frères, Ouagadougou - D&B paper listing", "approach": "Converter or distributor.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('impricolor', null, 'impricolor', true,
   $pj${"owner": "Impricolor", "products": "Impricolor (2003), Ouagadougou - offset printing and printed packaging", "approach": "Converter or distributor.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('sogecop', null, 'sogecop', true,
   $pj${"owner": "SOGECOP", "products": "SOGECOP, Ouaga 2000 - printing, paper supply", "approach": "Converter or distributor.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('prodiconseil', null, 'prodiconseil', true,
   $pj${"owner": "Prodiconseil", "products": "Prodiconseil - paper supply via Abidjan, Lomé and Tema ports", "approach": "Converter or distributor.", "checked_at": "2026-10-17"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'BF', 'Burkina Faso', 'none',
   $cm$No paper machine - packaging, printing and paper trade (SONACEB, Impricolor, SOGECOP) - dolomitic limestone around Bobo-Dioulasso$cm$,
   $cm$Burkina Faso has no confirmed paper machine: SONACEB (board and packaging), D&B-listed small firms, Impricolor and SOGECOP (printing, paper supply). Paper arrives through Abidjan, Lomé and Tema - HS 48 imports about USD 60.0 m in 2024, mainly Côte d'Ivoire, China, Ghana, about 1.4 kt corrugating medium. No paper PCC or GCC: dolomite and dolomitic limestone at SOFANEC and Dandé (Carrières et Mines du Burkina), cement grinding at CIMAF. Benin's WAPACK (18 kt corrugated) also serves Burkina.$cm$,
   $cm${"fillers": "Dolomite: SOFANEC, Carrières et Mines du Burkina. Not added: AF'Gri-culture, CIMAF, Bobo Diamond, Fluent Burkina. No PCC or GCC.", "mills": "No paper machine. Context: SONACEB, Faso Sachets, Kabre Bassirou, Impricolor, SOGECOP, Prodiconseil.", "strategy": "None direct - focus on Ivorian and Ghanaian mills supplying Burkina.", "risks": "Landlocked, security.", "next_steps": [], "key_numbers": [{"label": "HS 48 imports 2024", "value": "about USD 60.0 m"}, {"label": "HS 480810 imports 2024", "value": "about 1.4 kt"}], "files": ["seed_20261017c_burkina_market"]}$cm$::jsonb,
   $cm$초지기 없음 — 포장·인쇄·종이 유통(SONACEB, Impricolor, SOGECOP) — Bobo-Dioulasso 일대 돌로마이트질 석회석$cm$,
   $cm$부르키나파소에는 확인된 초지기 없음: SONACEB(판지·포장), D&B 등록 소기업, Impricolor·SOGECOP(인쇄·종이 공급). 종이는 아비장·로메·테마항 경유 — HS 48 수입 2024 약 6,002만 달러(주로 코트디부아르·중국·가나), 골심지 약 1.4천 t. 제지용 PCC·GCC 없음: SOFANEC·Dandé(Carrières et Mines du Burkina) 돌로마이트, CIMAF 시멘트 분쇄. 베냉 WAPACK(골판지 1.8만 t)도 부르키나 공급.$cm$,
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
      ('sonaceb', null, 'sonaceb'),
  ('faso sachets', null, 'faso sachets'),
  ('kabre bassirou', null, 'kabre bassirou'),
  ('impricolor', null, 'impricolor'),
  ('sogecop', null, 'sogecop'),
  ('prodiconseil', null, 'prodiconseil')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'burkina_update_20261017' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BF'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'burkina_update_20261017' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'sofanec' or p.party_name ~* 'carri[eè]res et mines du burkina|dand[eé]')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'BF'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'BF'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'BF'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BF'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    