-- ============================================================
-- seed_20261016zzzh_somalia_market.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Somalia update (reports 2026-10-17). Memos carry a sanctions and
-- Somaliland note. No confirmed paper machine - no mill rows.
-- 1) Fillers if missing (2): Red Sea Cement (idle), Berbera Marble and Granite.
-- 2) Context, match only (4): Nadiif, AADCO, Noor Industrials, Sompack.
-- 3) app.country_markets SO row (priority none).
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
           v.party_name, 'SO', v.region, v.city, v.website, 'active', 'somalia_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('red sea cement', 'Red Sea Cement - Berbera', 'Somaliland', 'Berbera', null, 'Red Sea Cement(Berbera) 시멘트 공장 과거 연 약 20만 t — USGS 2019 기준 비가동.', 'Red Sea Cement Company, Berbera (Somaliland) - cement plant of about 200,000 t/yr historical capacity, idle in USGS 2019 data.', 'SO check 2026-10-16: raw material and idle-site lead only. Berbera port (DP World) and Berbera Economic Zone (2023) with the corridor to Ethiopia. Screen against UN and US Somalia (al-Shabaab) sanctions lists, Somaliland permits are separate.'),
  ('berbera marble', 'Berbera Marble and Granite Factory', 'Somaliland', 'Berbera', null, 'Berbera 대리석·화강암 채석(USGS 과거 자료).', 'Berbera Marble and Granite Factory, Berbera - marble and granite quarrying (USGS records).', 'SO check 2026-10-16: marble chemistry and brightness untested. No Somali paper PCC or GCC. Screen against UN and US Somalia (al-Shabaab) sanctions lists, Somaliland permits are separate.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%SO check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('red sea cement', 'Red Sea Cement - Berbera', 'Somaliland', 'Berbera', null, 'Red Sea Cement(Berbera) 시멘트 공장 과거 연 약 20만 t — USGS 2019 기준 비가동.', 'Red Sea Cement Company, Berbera (Somaliland) - cement plant of about 200,000 t/yr historical capacity, idle in USGS 2019 data.', 'SO check 2026-10-16: raw material and idle-site lead only. Berbera port (DP World) and Berbera Economic Zone (2023) with the corridor to Ethiopia. Screen against UN and US Somalia (al-Shabaab) sanctions lists, Somaliland permits are separate.'),
  ('berbera marble', 'Berbera Marble and Granite Factory', 'Somaliland', 'Berbera', null, 'Berbera 대리석·화강암 채석(USGS 과거 자료).', 'Berbera Marble and Granite Factory, Berbera - marble and granite quarrying (USGS records).', 'SO check 2026-10-16: marble chemistry and brightness untested. No Somali paper PCC or GCC. Screen against UN and US Somalia (al-Shabaab) sanctions lists, Somaliland permits are separate.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'somalia_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Red Sea Cement - Berbera', 'Limestone owner (cement, idle)', 'Idle cement site - raw-material lead', 'merchant', 'C', 'gcc'),
  ('Berbera Marble and Granite Factory', 'Marble quarry', 'Marble - possible GCC feed', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'somalia_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%SO check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('nadiif', null, 'nadiif', null, null, 'SO check 2026-10-16: Nadiif Paper Mills, Mogadishu (2018-07) - facial tissue and napkins, imports tissue base rolls (HS 4803, as Nadiif Tissue) - context only. Screen against UN and US Somalia (al-Shabaab) sanctions lists, Somaliland permits are separate.'),
  ('aadco', null, 'aadco', null, null, 'SO check 2026-10-16: AADCO Paper Factory, Hargeisa (2013) - A4 / A3 copy paper, notebooks, egg trays, supplies Ethiopia and Djibouti (10.2 k copy-paper and 36.1 k notebook cartons in 2017) - context only. Screen against UN and US Somalia (al-Shabaab) sanctions lists, Somaliland permits are separate.'),
  ('noor industrial', null, 'noor industrial', null, null, 'SO check 2026-10-16: Alpha Plus napkins, over 16,000 boxes/day stated - context only. Screen against UN and US Somalia (al-Shabaab) sanctions lists, Somaliland permits are separate.'),
  ('sompack', null, 'sompack', null, null, 'SO check 2026-10-16: Sompack, Mogadishu - retail and industrial boxes, 50+ staff - context only. Screen against UN and US Somalia (al-Shabaab) sanctions lists, Somaliland permits are separate.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'somalia_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('nadiif', null, 'nadiif'),
  ('aadco', null, 'aadco'),
  ('noor industrial', null, 'noor industrial'),
  ('sompack', null, 'sompack')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('nadiif', null, 'nadiif', true,
   $pj${"owner": "Nadiif", "products": "Nadiif Paper Mills, Mogadishu (2018-07) - facial tissue and napkins, imports tissue base rolls (HS 4803, as Nadiif Tissue)", "approach": "Converter - trace base-paper suppliers.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('aadco', null, 'aadco', true,
   $pj${"owner": "AADCO Group", "products": "AADCO Paper Factory, Hargeisa (2013) - A4 / A3 copy paper, notebooks, egg trays, supplies Ethiopia and Djibouti (10.2 k copy-paper and 36.1 k notebook cartons in 2017)", "approach": "Converter - trace base-paper suppliers.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('noor industrial', null, 'noor industrial', true,
   $pj${"owner": "Noor Industrials", "products": "Alpha Plus napkins, over 16,000 boxes/day stated", "approach": "Converter - trace base-paper suppliers.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('sompack', null, 'sompack', true,
   $pj${"owner": "Sompack", "products": "Sompack, Mogadishu - retail and industrial boxes, 50+ staff", "approach": "Converter - trace base-paper suppliers.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'SO', 'Somalia', 'none',
   $cm$No confirmed paper machine or paper filler plant - tissue, copy paper and box converters (Nadiif, AADCO, Noor, Sompack) - Berbera limestone and marble, port to Ethiopia$cm$,
   $cm$Somalia (incl. Somaliland) has converters, not paper mills: Nadiif Paper Mills (tissue, imports base rolls), AADCO Hargeisa (copy paper and notebooks, also sold to Ethiopia and Djibouti), Noor Industrials (Alpha Plus napkins), Sompack (boxes). HS 48 supplied mainly by China, Türkiye, Oman (2024). No paper PCC or GCC - Red Sea Cement Berbera (idle, about 200 kt) and Berbera Marble and Granite are raw-material leads. Berbera port and economic zone link to Ethiopia.$cm$,
   $cm${"fillers": "Leads: Red Sea Cement (idle), Berbera Marble and Granite. No PCC or GCC.", "mills": "No confirmed paper machine. Context: Nadiif, AADCO, Noor Industrials, Sompack.", "strategy": "No direct sales - reach the base-paper suppliers, watch Berbera as a long-term GCC and logistics site for Ethiopia.", "risks": "Security, sanctions screening, Somaliland legal status.", "next_steps": [], "key_numbers": [{"label": "HS 48 supply 2024", "value": "China USD 18.1 m, Türkiye 13.2 m, Oman 9.5 m"}], "files": ["seed_20261016zzzh_somalia_market"]}$cm$::jsonb,
   $cm$초지기·제지용 충전제 공장 미확인 — 티슈·복사용지·상자 가공(Nadiif, AADCO, Noor, Sompack) — Berbera 석회석·대리석, 에티오피아행 항만$cm$,
   $cm$소말리아(소말릴란드 포함)는 제지공장이 아닌 가공업체 중심: Nadiif Paper Mills(티슈, 원지 롤 수입), AADCO Hargeisa(복사용지·공책, 에티오피아·지부티 판매), Noor Industrials(Alpha Plus 냅킨), Sompack(상자). HS 48 공급 주로 중국·튀르키예·오만(2024). 제지용 PCC·GCC 없음 — Red Sea Cement Berbera(비가동, 약 20만 t)·Berbera Marble and Granite 는 원료 후보. Berbera 항·경제특구가 에티오피아 연결.$cm$,
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
      ('nadiif', null, 'nadiif'),
  ('aadco', null, 'aadco'),
  ('noor industrial', null, 'noor industrial'),
  ('sompack', null, 'sompack')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'somalia_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'somalia_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'red sea cement' or p.party_name ~* 'berbera marble')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'SO'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'SO'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'SO'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    