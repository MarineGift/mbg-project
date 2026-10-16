-- ============================================================
-- seed_20261015z_guyana_market.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Guyana update - paper-company report (2026-10-15). No running paper
-- machine: CCI closed its recycled liner mill in 2021, tissue makers convert
-- imported rolls. No mill or filler rows are created.
-- 1) Context, match only (5): Caribbean Container Inc., Nova High
--    Technology, Cuddles Touch, NPN Enterprise, Fullworks Packaging -
--    memo and plant note added only if the row already exists.
-- 2) app.country_markets GY row (priority none).
-- Idempotent. Last statement is a verification select.
-- ============================================================

-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%GY check 2026-10-15%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('caribbean container|\mcci\M.*guyana', null, 'caribbean container|\mcci\M.*guyana', null, null, 'GY check 2026-10-15: Corrugated boxes. Own recycled liner and medium mill ran 2003-2017 (about 4,000 t/yr OCC in 2017, 145 staff), stopped 2017-06, permanently closed 2021 - now converts imported base paper - context only.'),
  ('nova high', null, 'nova high', null, null, 'GY check 2026-10-15: Tissue products since 2023-10 (toilet, napkins, facial, kitchen rolls), Made in Guyana mark 2025-07 - own tissue machine not confirmed - context only.'),
  ('cuddles touch', null, 'cuddles touch', null, null, 'GY check 2026-10-15: Toilet tissue and towels on imported base paper (China, Mexico), restarted 2014 - status unknown - context only.'),
  ('\mnpn enterprise', null, '\mnpn enterprise', null, null, 'GY check 2026-10-15: Tissue converting interest, sought jumbo rolls - status unknown - context only.'),
  ('fullworks', null, 'fullworks', null, null, 'GY check 2026-10-15: Packaging distributor - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'guyana_update_20261015';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('caribbean container|\mcci\M.*guyana', null, 'caribbean container|\mcci\M.*guyana'),
  ('nova high', null, 'nova high'),
  ('cuddles touch', null, 'cuddles touch'),
  ('\mnpn enterprise', null, '\mnpn enterprise'),
  ('fullworks', null, 'fullworks')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('caribbean container|\mcci\M.*guyana', null, 'caribbean container|\mcci\M.*guyana',
   $pj${"owner": "Caribbean Container Inc. (CCI), Farm, East Bank Demerara", "products": "Corrugated boxes. Own recycled liner and medium mill ran 2003-2017 (about 4,000 t/yr OCC in 2017, 145 staff), stopped 2017-06, permanently closed 2021 - now converts imported base paper", "approach": "No paper machine running - converter. Watch for a machine restart or new tissue machine.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('nova high', null, 'nova high',
   $pj${"owner": "Nova High Technology", "products": "Tissue products since 2023-10 (toilet, napkins, facial, kitchen rolls), Made in Guyana mark 2025-07 - own tissue machine not confirmed", "approach": "No paper machine running - converter. Watch for a machine restart or new tissue machine.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('cuddles touch', null, 'cuddles touch',
   $pj${"owner": "Cuddles Touch Inc.", "products": "Toilet tissue and towels on imported base paper (China, Mexico), restarted 2014 - status unknown", "approach": "No paper machine running - converter. Watch for a machine restart or new tissue machine.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('\mnpn enterprise', null, '\mnpn enterprise',
   $pj${"owner": "NPN Enterprise", "products": "Tissue converting interest, sought jumbo rolls - status unknown", "approach": "No paper machine running - converter. Watch for a machine restart or new tissue machine.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('fullworks', null, 'fullworks',
   $pj${"owner": "Fullworks Packaging Products", "products": "Packaging distributor", "approach": "No paper machine running - converter. Watch for a machine restart or new tissue machine.", "checked_at": "2026-10-15"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'GY', 'Guyana', 'none',
   $cm$No running paper machine - CCI closed its recycled liner mill in 2021, tissue makers convert imported rolls$cm$,
   $cm$Guyana has no running paper machine. Caribbean Container Inc. made recycled liner and medium 2003-2017 and closed the mill for good in 2021 - it now converts imported base paper. Nova High Technology (tissue since 2023, Made in Guyana mark 2025) has no confirmed machine. Others are converters or distributors. Jacana Paper is in Trinidad and Tobago, not Guyana.$cm$,
   $cm${"fillers": "No paper-grade PCC or GCC maker (filler report not provided).", "mills": "Closed: Caribbean Container Inc. recycled liner and medium mill (2003-2017, closed 2021). Converters (context only): CCI box plant, Nova High Technology, Cuddles Touch, NPN Enterprise, Fullworks Packaging.", "strategy": "No local FCC customer. Target the Trinidad, Brazil and Colombia mills that ship tissue and liner to Guyana. Re-check if CCI restarts or Nova adds a tissue machine.", "risks": "No paper machine.", "next_steps": ["Ask Nova High Technology whether it makes its own base paper"], "key_numbers": [{"label": "Tissue and hygiene market 2025", "value": "USD 24.68 m (Statista)"}, {"label": "Toilet paper market 2025", "value": "USD 7.61 m"}, {"label": "Tissue volume 2029F", "value": "about 9,900 t (consumption)"}], "files": ["seed_20261015z_guyana_market"]}$cm$::jsonb,
   $cm$가동 초지기 없음 — CCI 재생 라이너 공장 2021 영구 폐쇄, 티슈업체는 수입 원지 가공$cm$,
   $cm$가이아나에는 가동 중인 초지기가 없음. Caribbean Container Inc. 는 2003~2017 재생 라이너·골심지를 만들다 2021 영구 폐쇄, 현재 수입 원지 가공. Nova High Technology(2023 티슈, 2025 Made in Guyana)는 초지기 미확인. Jacana Paper 는 트리니다드토바고 업체.$cm$,
   null, null,
   $cm$초지기 없음 — 산정 불가$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('caribbean container|\mcci\M.*guyana', null, 'caribbean container|\mcci\M.*guyana'),
  ('nova high', null, 'nova high'),
  ('cuddles touch', null, 'cuddles touch'),
  ('\mnpn enterprise', null, '\mnpn enterprise'),
  ('fullworks', null, 'fullworks')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'guyana_update_20261015' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'guyana_update_20261015' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (false)
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'GY'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'GY'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'GY'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    