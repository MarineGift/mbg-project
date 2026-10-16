-- ============================================================
-- seed_20261015y_suriname_mills.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Suriname update - paper-company report (2026-10-15). No confirmed paper
-- machine - converters are not created as mills.
-- 1) Mill if missing + plant block (no priority): Yeung Papier Fabriek
--    (Wanica) - listed paper mill, machine unconfirmed.
--    Context, match only (6): Shen Long, Devnan, Clear Packaging, Q-Pack,
--    C W K Plastic, Wanda / Wang Da Paper.
-- 2) app.country_markets SR row (priority low). No fillers.
-- Idempotent. Last statement is a verification select.
-- ============================================================

-- ---------- 2) MILL ROWS IF MISSING ----------
    insert into app.parties
      (party_type_id, entity_type_id, party_name, country_code, region, city,
       website, status, source, intro_ko, intro_en, notes, organization_id)
    select 2::smallint,
           coalesce((select x.entity_type_id from app.parties x
                     where x.party_type_id = 2 and x.deleted_at is null
                     order by x.created_at limit 1), 1)::smallint,
           v.party_name, 'SR', v.region, v.city, v.website, 'active', 'suriname_update_20261015',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('yeung papier', 'wanica', 'yeung', 'Yeung Papier Fabriek (Wanica)', 'Wanica', 'Wanica', null, 'D&B 에 펄프·종이·판지 공장(NAICS 3221)으로 등재된 수리남 유일 업체(Wanica). 직원 6명 등재, 초지기·지종·생산능력 미확인.', 'Yeung Papier Fabriek, Wanica District - the only Surinamese company listed by D&B as a pulp, paper and paperboard mill (NAICS 3221), about 6 staff listed (owner Yuet Ming Yeung).', 'SR check 2026-10-15: paper machine, grades and output not confirmed. Revenue figures conflict (USD 0.49 m vs 3.63 m). +597 875 5008.')
    ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
    
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%SR check 2026-10-15%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('yeung papier', 'wanica', 'yeung', 'D&B 에 펄프·종이·판지 공장(NAICS 3221)으로 등재된 수리남 유일 업체(Wanica). 직원 6명 등재, 초지기·지종·생산능력 미확인.', 'Yeung Papier Fabriek, Wanica District - the only Surinamese company listed by D&B as a pulp, paper and paperboard mill (NAICS 3221), about 6 staff listed (owner Yuet Ming Yeung).', 'SR check 2026-10-15: paper machine, grades and output not confirmed. Revenue figures conflict (USD 0.49 m vs 3.63 m). +597 875 5008.'),
  ('shen long', null, 'shen long', null, null, 'SR check 2026-10-15: Tissue converter (Snow-Kleen), Nieuw Amsterdam / Paramaribo - about 40,000 packs of 24 rolls/month and about 60 pct toilet tissue share (2018), ISO 9001, imports jumbo tissue rolls (37 t and 71 t shipments 2024-08) - converter or distributor, context only.'),
  ('devnan', null, 'devnan', null, null, 'SR check 2026-10-15: Envelopes, paper and board distribution (Double A, Explorer) - converter or distributor, context only.'),
  ('clear packaging', null, 'clear packaging', null, null, 'SR check 2026-10-15: Paper bags and LDPE recycling - converter or distributor, context only.'),
  ('\mq-?pack\M', null, '\mq-?pack\M', null, null, 'SR check 2026-10-15: Listed under paper manufacturing - products unknown - converter or distributor, context only.'),
  ('c ?w ?k plastic', null, 'c ?w ?k plastic', null, null, 'SR check 2026-10-15: Listed under paper manufacturing - products unknown - converter or distributor, context only.'),
  ('wanda paper|wang da paper', null, 'wanda paper|wang da paper', null, null, 'SR check 2026-10-15: Tissue and diapers - supplier, machine unknown - converter or distributor, context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'suriname_update_20261015';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('yeung papier', 'wanica', 'yeung'),
  ('shen long', null, 'shen long'),
  ('devnan', null, 'devnan'),
  ('clear packaging', null, 'clear packaging'),
  ('\mq-?pack\M', null, '\mq-?pack\M'),
  ('c ?w ?k plastic', null, 'c ?w ?k plastic'),
  ('wanda paper|wang da paper', null, 'wanda paper|wang da paper')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('yeung papier', 'wanica', 'yeung',
   $pj${"owner": "Yeung Papier Fabriek", "products": "Paper (grade unknown)", "approach": "Confirm a paper machine first - otherwise no FCC customer in Suriname.", "to_collect": ["Paper machine yes or no", "Grade and output"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('shen long', null, 'shen long',
   $pj${"owner": "Shen Long Company", "products": "Tissue converter (Snow-Kleen), Nieuw Amsterdam / Paramaribo - about 40,000 packs of 24 rolls/month and about 60 pct toilet tissue share (2018), ISO 9001, imports jumbo tissue rolls (37 t and 71 t shipments 2024-08)", "approach": "Converter - buys base paper abroad.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('devnan', null, 'devnan',
   $pj${"owner": "Devnan Enveloppenfabriek / Devnan Group", "products": "Envelopes, paper and board distribution (Double A, Explorer)", "approach": "Converter - buys base paper abroad.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('clear packaging', null, 'clear packaging',
   $pj${"owner": "Clear Packaging and Recycling", "products": "Paper bags and LDPE recycling", "approach": "Converter - buys base paper abroad.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('\mq-?pack\M', null, '\mq-?pack\M',
   $pj${"owner": "Q-Pack", "products": "Listed under paper manufacturing - products unknown", "approach": "Converter - buys base paper abroad.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('c ?w ?k plastic', null, 'c ?w ?k plastic',
   $pj${"owner": "C W K Plastic Industry", "products": "Listed under paper manufacturing - products unknown", "approach": "Converter - buys base paper abroad.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('wanda paper|wang da paper', null, 'wanda paper|wang da paper',
   $pj${"owner": "Suriname Wanda / Wang Da Paper", "products": "Tissue and diapers - supplier, machine unknown", "approach": "Converter - buys base paper abroad.", "checked_at": "2026-10-15"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'SR', 'Suriname', 'low',
   $cm$No confirmed paper machine - tissue converters on imported jumbo rolls (mostly Chinese)$cm$,
   $cm$Suriname converts imported base paper. Shen Long (Snow-Kleen) is the main tissue maker but imports jumbo rolls. Yeung Papier Fabriek (Wanica) is listed as a paper mill, machine unconfirmed. 2024 imports: 1,934 t tissue base paper (HS 4803, 83.6 pct China, 12.7 pct Indonesia) and 3,735 t finished hygiene paper (HS 4818). No paper filler maker.$cm$,
   $cm${"fillers": "No paper-grade PCC or GCC maker found (filler report not provided).", "mills": "Listed paper mill: Yeung Papier Fabriek (Wanica) - machine unconfirmed. Converters (context only): Shen Long (Snow-Kleen, jumbo-roll imports), Devnan, Clear Packaging and Recycling, Q-Pack, C W K Plastic, Wanda / Wang Da Paper.", "strategy": "Target the Chinese and Indonesian mills that ship tissue base paper to Suriname, not Suriname itself.", "risks": "No confirmed machine, about 2 kt base-paper demand.", "next_steps": ["Confirm whether Yeung Papier Fabriek runs a paper machine"], "key_numbers": [{"label": "Tissue base paper imports 2024", "value": "1,934 t (USD 2.19 m), China 83.6 pct"}, {"label": "Hygiene paper product imports 2024", "value": "3,735 t (USD 10.42 m)"}], "files": ["seed_20261015y_suriname_mills"]}$cm$::jsonb,
   $cm$초지기 미확인 — 수입 점보롤(주로 중국산)을 쓰는 티슈 가공업체 중심$cm$,
   $cm$수리남은 수입 원지 가공 시장. 최대 티슈업체 Shen Long(Snow-Kleen)은 점보 원지 수입. Yeung Papier Fabriek(Wanica)은 제지공장으로 등재됐으나 초지기 미확인. 2024 티슈 원지 수입 1,934 t(중국 83.6%), 위생용지 완제품 3,735 t. 제지용 충전제 업체 없음.$cm$,
   null, null,
   $cm$초지기 미확인 — 산정 불가$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('yeung papier', 'wanica', 'yeung'),
  ('shen long', null, 'shen long'),
  ('devnan', null, 'devnan'),
  ('clear packaging', null, 'clear packaging'),
  ('\mq-?pack\M', null, '\mq-?pack\M'),
  ('c ?w ?k plastic', null, 'c ?w ?k plastic'),
  ('wanda paper|wang da paper', null, 'wanda paper|wang da paper')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'suriname_update_20261015' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'suriname_update_20261015' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (false)
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'SR'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'SR'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'SR'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    