-- ============================================================
-- seed_20261016zh_kosovo_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Kosovo update (reports 2026-10-16). Country code XK (user-assigned, not in
-- the ISO list) - section 0 adds it to app.countries if missing.
-- No paper machine found - no mills created.
-- 0) app.countries XK row if missing.
-- 1) Filler if missing (1): Alba Lime Factory (lime, future PCC base).
-- 2) Context, match only (12): Top Soft Papers, M-Group, KOHA, Mare Group,
--    ORTO Paper, LB Group, Papperlapapp, DG PACK, Hilzna Plus, Nord Ecopack,
--    Nori Group, DAKU P S.
-- 3) app.country_markets XK row (priority none).
-- Idempotent. Last statement is a verification select.
-- ============================================================

-- ---------- 0) Kosovo in app.countries (XK is not in the ISO 3166-1 list)
insert into app.countries (code, name_en)
select 'XK', 'Kosovo'
where not exists (select 1 from app.countries where code = 'XK');

-- 1) FILLER ROWS IF MISSING ----------
    insert into app.parties
      (party_type_id, entity_type_id, party_name, country_code, region, city,
       website, status, source, intro_ko, intro_en, notes, organization_id)
    select 3::smallint,
           coalesce((select x.entity_type_id from app.parties x
                     where x.party_type_id = 3 and x.deleted_at is null
                     order by x.created_at limit 1), 1)::smallint,
           v.party_name, 'XK', v.region, v.city, v.website, 'active', 'kosovo_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('alba lime|alba group.*lime', 'Alba Lime Factory - Hani i Elezit', 'Ferizaj', 'Hani i Elezit', null, 'Alba Group 의 Hani i Elezit 현대식 석회 공장(2025, Maerz PFR 소성로) — 코소보·발칸 산업용 석회. 그룹 Guri i Bekur 채석장 보유.', 'Alba Lime Factory (Alba Group), Hani i Elezit - modern lime plant built 2025 on a Maerz PFR kiln for Kosovo and Balkan industrial lime, with the group quarry Guri i Bekur supplying stone (also to Sharrcem).', 'XK check 2026-10-16: lime only - CaO purity, CO2 capture, slaking and carbonation not present. Owner Sherif Ramuka, general manager Mamer Vila (municipal visit 2025-08). Not added: TITAN Sharrcem (cement), New Kosova Lime (2024 project, status unknown), Green Power (dolomitic stone), Fox Marble (dimension stone, licence disputes). No paper PCC or GCC in Kosovo.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%XK check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('alba lime|alba group.*lime', 'Alba Lime Factory - Hani i Elezit', 'Ferizaj', 'Hani i Elezit', null, 'Alba Group 의 Hani i Elezit 현대식 석회 공장(2025, Maerz PFR 소성로) — 코소보·발칸 산업용 석회. 그룹 Guri i Bekur 채석장 보유.', 'Alba Lime Factory (Alba Group), Hani i Elezit - modern lime plant built 2025 on a Maerz PFR kiln for Kosovo and Balkan industrial lime, with the group quarry Guri i Bekur supplying stone (also to Sharrcem).', 'XK check 2026-10-16: lime only - CaO purity, CO2 capture, slaking and carbonation not present. Owner Sherif Ramuka, general manager Mamer Vila (municipal visit 2025-08). Not added: TITAN Sharrcem (cement), New Kosova Lime (2024 project, status unknown), Green Power (dolomitic stone), Fox Marble (dimension stone, licence disputes). No paper PCC or GCC in Kosovo.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'kosovo_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Alba Lime Factory - Hani i Elezit', 'Lime producer', 'Lime base - future PCC line candidate', 'merchant', 'C', 'pcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'kosovo_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%XK check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'XK'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('top soft', null, 'top soft', null, null, 'XK check 2026-10-16: Tissue converting (Rivea), Graçanica, 24 staff - converting line 2024, no paper machine - context only.'),
  ('m-group|\mm group\M', null, 'm-group|\mm group\M', null, null, 'XK check 2026-10-16: Tissue and jumbo-roll trade and converting, Ferizaj - context only.'),
  ('koha group|spoppy', null, 'koha group|spoppy', null, null, 'XK check 2026-10-16: Spoppy tissue products - own machine not confirmed - context only.'),
  ('mare group', null, 'mare group', null, null, 'XK check 2026-10-16: Mare and Tiss tissue, Lipjan - own machine not confirmed - context only.'),
  ('orto paper|lirimi', null, 'orto paper|lirimi', null, null, 'XK check 2026-10-16: Paper bags and industrial sacks, Malishevë - converter - context only.'),
  ('\mlb group\M', null, '\mlb group\M', null, null, 'XK check 2026-10-16: Paper and board packaging, Prishtina - converter - context only.'),
  ('papperlapapp', null, 'papperlapapp', null, null, 'XK check 2026-10-16: Custom paper packaging, Fushë Kosovë - converter - context only.'),
  ('dg pack', null, 'dg pack', null, null, 'XK check 2026-10-16: Spiral paper tubes on imported Italian, Greek and Turkish paper - context only.'),
  ('hilzna', null, 'hilzna', null, null, 'XK check 2026-10-16: Paper tubes, Prizren - converter - context only.'),
  ('nord ecopack', null, 'nord ecopack', null, null, 'XK check 2026-10-16: Paper cups, Prishtina - converter - context only.'),
  ('nori group', null, 'nori group', null, null, 'XK check 2026-10-16: Paper cups (3 m/week) - converter - context only.'),
  ('daku p', null, 'daku p', null, null, 'XK check 2026-10-16: Registered for pulp and paper (NACE 1711, 1712), Gjilan - 1 employee, no mill seen - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'kosovo_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'XK'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('top soft', null, 'top soft'),
  ('m-group|\mm group\M', null, 'm-group|\mm group\M'),
  ('koha group|spoppy', null, 'koha group|spoppy'),
  ('mare group', null, 'mare group'),
  ('orto paper|lirimi', null, 'orto paper|lirimi'),
  ('\mlb group\M', null, '\mlb group\M'),
  ('papperlapapp', null, 'papperlapapp'),
  ('dg pack', null, 'dg pack'),
  ('hilzna', null, 'hilzna'),
  ('nord ecopack', null, 'nord ecopack'),
  ('nori group', null, 'nori group'),
  ('daku p', null, 'daku p')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'XK'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('top soft', null, 'top soft',
   $pj${"owner": "Top Soft Papers", "products": "Tissue converting (Rivea), Graçanica, 24 staff - converting line 2024, no paper machine", "approach": "Converter - trace base-paper suppliers abroad.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('m-group|\mm group\M', null, 'm-group|\mm group\M',
   $pj${"owner": "M-Group", "products": "Tissue and jumbo-roll trade and converting, Ferizaj", "approach": "Converter - trace base-paper suppliers abroad.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('koha group|spoppy', null, 'koha group|spoppy',
   $pj${"owner": "KOHA Group", "products": "Spoppy tissue products - own machine not confirmed", "approach": "Converter - trace base-paper suppliers abroad.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('mare group', null, 'mare group',
   $pj${"owner": "Mare Group", "products": "Mare and Tiss tissue, Lipjan - own machine not confirmed", "approach": "Converter - trace base-paper suppliers abroad.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('orto paper|lirimi', null, 'orto paper|lirimi',
   $pj${"owner": "ORTO Paper (Lirimi Group)", "products": "Paper bags and industrial sacks, Malishevë - converter", "approach": "Converter - trace base-paper suppliers abroad.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mlb group\M', null, '\mlb group\M',
   $pj${"owner": "LB Group", "products": "Paper and board packaging, Prishtina - converter", "approach": "Converter - trace base-paper suppliers abroad.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('papperlapapp', null, 'papperlapapp',
   $pj${"owner": "Papperlapapp", "products": "Custom paper packaging, Fushë Kosovë - converter", "approach": "Converter - trace base-paper suppliers abroad.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('dg pack', null, 'dg pack',
   $pj${"owner": "DG PACK", "products": "Spiral paper tubes on imported Italian, Greek and Turkish paper", "approach": "Converter - trace base-paper suppliers abroad.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('hilzna', null, 'hilzna',
   $pj${"owner": "Hilzna Plus", "products": "Paper tubes, Prizren - converter", "approach": "Converter - trace base-paper suppliers abroad.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('nord ecopack', null, 'nord ecopack',
   $pj${"owner": "Nord Ecopack", "products": "Paper cups, Prishtina - converter", "approach": "Converter - trace base-paper suppliers abroad.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('nori group', null, 'nori group',
   $pj${"owner": "Nori Group", "products": "Paper cups (3 m/week) - converter", "approach": "Converter - trace base-paper suppliers abroad.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('daku p', null, 'daku p',
   $pj${"owner": "DAKU P S", "products": "Registered for pulp and paper (NACE 1711, 1712), Gjilan - 1 employee, no mill seen", "approach": "Converter - trace base-paper suppliers abroad.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'XK', 'Kosovo', 'none',
   $cm$No paper machine - tissue and packaging converters on imported rolls, new lime plant (Alba, 2025) as a possible PCC base$cm$,
   $cm$Kosovo has no confirmed paper machine: Top Soft Papers, M-Group, KOHA and Mare convert tissue, ORTO, LB Group, Papperlapapp, DG PACK and Hilzna Plus convert paper and board (DG PACK uses imported Italian, Greek and Turkish paper), Nord Ecopack and Nori make cups. No paper PCC or GCC. Alba Lime Factory (Maerz PFR kiln, 2025) is the only lime base for a future PCC line - its economics would depend on Balkan mills, not Kosovo.$cm$,
   $cm${"fillers": "Lime: Alba Lime Factory Hani i Elezit. Not added: TITAN Sharrcem, New Kosova Lime, Green Power, Fox Marble.", "mills": "No paper machine. Context: Top Soft Papers, M-Group, KOHA Group, Mare Group, ORTO Paper, LB Group, Papperlapapp, DG PACK, Hilzna Plus, Nord Ecopack, Nori Group, DAKU P S.", "strategy": "Indirect - trace converters' base-paper suppliers. Alba lime only as part of a Balkan PCC or FCC plan.", "risks": "No direct volume.", "next_steps": ["Ask Top Soft Papers and M-Group for the source of their jumbo rolls"], "key_numbers": [{"label": "Alba Lime Factory", "value": "Maerz PFR kiln (2025)"}], "files": ["seed_20261016zh_kosovo_fillers"]}$cm$::jsonb,
   $cm$초지기 없음 — 수입 원지 티슈·포장 가공업체, 신규 석회공장(Alba, 2025)은 PCC 기반 후보$cm$,
   $cm$코소보에는 초지기 확인 없음: Top Soft Papers·M-Group·KOHA·Mare 는 티슈 가공, ORTO·LB Group·Papperlapapp·DG PACK·Hilzna Plus 는 종이·판지 가공(DG PACK 은 이탈리아·그리스·튀르키예 원지 수입), Nord Ecopack·Nori 는 종이컵. 제지용 PCC·GCC 없음. Alba Lime Factory(Maerz PFR, 2025)가 향후 PCC 라인의 유일한 석회 기반 — 경제성은 발칸 제지공장 수요에 달림.$cm$,
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
      ('top soft', null, 'top soft'),
  ('m-group|\mm group\M', null, 'm-group|\mm group\M'),
  ('koha group|spoppy', null, 'koha group|spoppy'),
  ('mare group', null, 'mare group'),
  ('orto paper|lirimi', null, 'orto paper|lirimi'),
  ('\mlb group\M', null, '\mlb group\M'),
  ('papperlapapp', null, 'papperlapapp'),
  ('dg pack', null, 'dg pack'),
  ('hilzna', null, 'hilzna'),
  ('nord ecopack', null, 'nord ecopack'),
  ('nori group', null, 'nori group'),
  ('daku p', null, 'daku p')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'kosovo_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'XK'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'kosovo_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'alba lime|alba group.*lime')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'XK'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'XK'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'XK'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'XK'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    