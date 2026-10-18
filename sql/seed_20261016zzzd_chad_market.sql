-- ============================================================
-- seed_20261016zzzd_chad_market.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Chad update (reports 2026-10-17). No paper machine - no mill rows.
-- 1) Filler if missing (1): CIM-Tchad (ex SONACIM, limestone).
-- 2) Context, match only (3): ASHIA PACK, IDT, Bouchra Printing.
-- 3) app.country_markets TD row (priority none).
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
           v.party_name, 'TD', v.region, v.city, v.website, 'active', 'chad_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('cim.?tchad|sonacim|baor[eé]', 'CIM-Tchad (ex SONACIM) - Baoré', 'Mayo-Kebbi Ouest', 'Baoré', null, 'CIM-Tchad(CIMAF 70%·정부 30%, 2026-03-06 구 SONACIM 자산 인수) Baoré/Bissi Kéda 석회석 광산·시멘트 공장(과거 약 20만~21만 t), 현대화·재가동 계획. 2007 자료 석회석 약 700만 t.', 'CIM-Tchad (CIMAF 70 pct, Chad state and local authorities 30 pct) took over the former SONACIM industrial and quarry assets on 2026-03-06 - Baoré / Bissi Kéda limestone quarry and cement plant (about 200,000-210,000 t/yr design), modernisation and restart planned. About 7 Mt limestone cited in 2007 data.', 'TD check 2026-10-16: paper-grade quality untested. Not added: CIMAF Tchad Lamadji (cement grinding 500 kt). 2024 CaCO3 imports about 246 t. No paper PCC or GCC. Raw-material lead for a later GCC trial.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%TD check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('cim.?tchad|sonacim|baor[eé]', 'CIM-Tchad (ex SONACIM) - Baoré', 'Mayo-Kebbi Ouest', 'Baoré', null, 'CIM-Tchad(CIMAF 70%·정부 30%, 2026-03-06 구 SONACIM 자산 인수) Baoré/Bissi Kéda 석회석 광산·시멘트 공장(과거 약 20만~21만 t), 현대화·재가동 계획. 2007 자료 석회석 약 700만 t.', 'CIM-Tchad (CIMAF 70 pct, Chad state and local authorities 30 pct) took over the former SONACIM industrial and quarry assets on 2026-03-06 - Baoré / Bissi Kéda limestone quarry and cement plant (about 200,000-210,000 t/yr design), modernisation and restart planned. About 7 Mt limestone cited in 2007 data.', 'TD check 2026-10-16: paper-grade quality untested. Not added: CIMAF Tchad Lamadji (cement grinding 500 kt). 2024 CaCO3 imports about 246 t. No paper PCC or GCC. Raw-material lead for a later GCC trial.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'chad_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('CIM-Tchad (ex SONACIM) - Baoré', 'Limestone owner (cement)', 'Limestone quarry - raw-material lead', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'chad_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%TD check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TD'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('ashia', null, 'ashia', null, null, 'TD check 2026-10-16: ASHIA PACK, Klemat N''Djamena - cartons, bags and packaging (3 units, 80+ staff), no paper machine - context only.'),
  ('\midt\M', null, '\midt\M', null, null, 'TD check 2026-10-16: IDT, N''Djamena - commercial printing - context only.'),
  ('bouchra', null, 'bouchra', null, null, 'TD check 2026-10-16: Digital and offset printing, N''Djamena - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'chad_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TD'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('ashia', null, 'ashia'),
  ('\midt\M', null, '\midt\M'),
  ('bouchra', null, 'bouchra')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TD'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('ashia', null, 'ashia', true,
   $pj${"owner": "ASHIA GROUP", "products": "ASHIA PACK, Klemat N'Djamena - cartons, bags and packaging (3 units, 80+ staff), no paper machine", "approach": "Converter or printer.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\midt\M', null, '\midt\M', true,
   $pj${"owner": "IDT", "products": "IDT, N'Djamena - commercial printing", "approach": "Converter or printer.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('bouchra', null, 'bouchra', true,
   $pj${"owner": "Bouchra Printing", "products": "Digital and offset printing, N'Djamena", "approach": "Converter or printer.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'TD', 'Chad', 'none',
   $cm$No paper machine, no paper PCC or GCC - CIM-Tchad limestone (CIMAF, 2026) - packaging and printing on imported paper$cm$,
   $cm$Chad has no paper mill. Paper-related firms are ASHIA PACK (cartons and packaging) and printers (IDT, Bouchra). Paper and board imports were about 588 t in 2024 (FAO, 62 pct printing and writing). CaCO3 imports about 246 t (2024). Carbonate potential: CIM-Tchad, which CIMAF (70 pct) took over of SONACIM in 2026-03 at Baoré, plus CIMAF's Lamadji grinding plant. Landlocked - served via the Douala-N'Djamena corridor (Cameroon).$cm$,
   $cm${"fillers": "Limestone: CIM-Tchad (Baoré). Not added: CIMAF Tchad Lamadji. No PCC or GCC.", "mills": "No paper machine. Context: ASHIA PACK, IDT, Bouchra Printing.", "strategy": "None direct - look at Cameroon and Nigeria mills.", "risks": "Tiny market, landlocked.", "next_steps": [], "key_numbers": [{"label": "Paper and board imports 2024", "value": "about 588 t"}, {"label": "CaCO3 imports 2024", "value": "about 246 t"}], "files": ["seed_20261016zzzd_chad_market"]}$cm$::jsonb,
   $cm$초지기·제지용 PCC·GCC 없음 — CIM-Tchad 석회석(CIMAF, 2026) — 수입 종이로 포장·인쇄$cm$,
   $cm$차드에는 제지공장 없음. 종이 관련은 ASHIA PACK(상자·포장)과 인쇄업체(IDT, Bouchra). 종이·판지 수입 2024 약 588 t(FAO, 인쇄·필기 62%). CaCO3 수입 약 246 t. 탄산칼슘 잠재력: 2026-03 CIMAF(70%)가 SONACIM 자산을 인수한 CIM-Tchad Baoré, CIMAF Lamadji 분쇄. 내륙국 — Douala-N'Djamena 회랑(카메룬) 경유.$cm$,
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
      ('ashia', null, 'ashia'),
  ('\midt\M', null, '\midt\M'),
  ('bouchra', null, 'bouchra')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'chad_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TD'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'chad_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'cim.?tchad|sonacim|baor[eé]')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'TD'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'TD'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'TD'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TD'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    