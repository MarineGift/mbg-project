-- ============================================================
-- seed_20261016zzzs_burundi_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Burundi update (reports 2026-10-17).
-- 1) Filler if missing (1): BUCECO (cement).
-- 2) Mill if missing (1, no priority): BUMAC. Context (6): converters.
-- 3) app.country_markets BI row (priority none).
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
           v.party_name, 'BI', v.region, v.city, v.website, 'active', 'burundi_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('buceco|burundi cement', 'BUCECO (Burundi Cement)', 'Burundi', null, null, 'BUCECO 시멘트 — 2019 USGS 추정 약 7.5만 t. Rusizi 평야 탄산염 원료 약 200만 t(과거 조사).', 'BUCECO (Burundi Cement Company) - cement, about 75,000 t in 2019 (USGS estimate). Rusizi Plain carbonate deposit of about 2 Mt cited in older World Bank work.', 'BI check 2026-10-16: no paper GCC or PCC line. Quarry permits via Office Burundais des Mines et Carrières (OBM). 2023 CaCO3 imports about 400 t (UAE, Tanzania, Kenya, Jordan, Türkiye). No Burundian paper PCC or GCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%BI check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('buceco|burundi cement', 'BUCECO (Burundi Cement)', 'Burundi', null, null, 'BUCECO 시멘트 — 2019 USGS 추정 약 7.5만 t. Rusizi 평야 탄산염 원료 약 200만 t(과거 조사).', 'BUCECO (Burundi Cement Company) - cement, about 75,000 t in 2019 (USGS estimate). Rusizi Plain carbonate deposit of about 2 Mt cited in older World Bank work.', 'BI check 2026-10-16: no paper GCC or PCC line. Quarry permits via Office Burundais des Mines et Carrières (OBM). 2023 CaCO3 imports about 400 t (UAE, Tanzania, Kenya, Jordan, Türkiye). No Burundian paper PCC or GCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'burundi_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('BUCECO (Burundi Cement)', 'Limestone owner (cement)', 'Cement - raw-material lead', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'burundi_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'BI', v.region, v.city, v.website, 'active', 'burundi_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('\mbumac\M|burundi manufacturing actions', 'bujumbura', 'bumac', 'BUMAC - Bujumbura', 'Bujumbura', 'Bujumbura', null, 'BUMAC(2013, 부줌부라) A4·A3·A1 복사용지·오프셋지·아트지 제조·공급 — 초지기·생산능력 미공개.', 'Burundi Manufacturing Actions SA (BUMAC, 2013), Bujumbura - copy paper (A4, A3, A1), offset and art paper, own brand, paper machine and capacity not public.', 'BI check 2026-10-16: machine vs sheeting of imported reels to confirm. info@bumac.bi, +257 79 195 932.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BI'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%BI check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BI'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('\mbumac\M|burundi manufacturing actions', 'bujumbura', 'bumac', 'BUMAC(2013, 부줌부라) A4·A3·A1 복사용지·오프셋지·아트지 제조·공급 — 초지기·생산능력 미공개.', 'Burundi Manufacturing Actions SA (BUMAC, 2013), Bujumbura - copy paper (A4, A3, A1), offset and art paper, own brand, paper machine and capacity not public.', 'BI check 2026-10-16: machine vs sheeting of imported reels to confirm. info@bumac.bi, +257 79 195 932.'),
  ('pacobu|paper converter burundi', null, 'pacobu|paper converter burundi', null, null, 'BI check 2026-10-16: PACOBU, Ngagara Bujumbura (2016) - notebooks (over 10,000/day at opening), kraft packaging, printing - context only.'),
  ('inter ?pack burundi', null, 'inter ?pack burundi', null, null, 'BI check 2026-10-16: INTER PACK Burundi, Maramvya (opened 2024-10-14, about BIF 30 bn) - board packaging, labels, straws - recycling plan - context only.'),
  ('environmental protectors', null, 'environmental protectors', null, null, 'BI check 2026-10-16: Environmental Protectors Group, Bujumbura - paper and non-woven bags - context only.'),
  ('imprimerie mex', null, 'imprimerie mex', null, null, 'BI check 2026-10-16: Commercial printing, Rohero Bujumbura - context only.'),
  ('hope design', null, 'hope design', null, null, 'BI check 2026-10-16: Design, printing, paper boxes - context only.'),
  ('itrapack', null, 'itrapack', null, null, 'BI check 2026-10-16: Itrapack - industrial sacks and packaging - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'burundi_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BI'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('\mbumac\M|burundi manufacturing actions', 'bujumbura', 'bumac'),
  ('pacobu|paper converter burundi', null, 'pacobu|paper converter burundi'),
  ('inter ?pack burundi', null, 'inter ?pack burundi'),
  ('environmental protectors', null, 'environmental protectors'),
  ('imprimerie mex', null, 'imprimerie mex'),
  ('hope design', null, 'hope design'),
  ('itrapack', null, 'itrapack')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BI'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('\mbumac\M|burundi manufacturing actions', 'bujumbura', 'bumac', false,
   $pj${"owner": "BUMAC", "products": "Copy, offset and art paper (to confirm)", "grades": ["UWF"], "approach": "Confirm paper machine first.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('pacobu|paper converter burundi', null, 'pacobu|paper converter burundi', true,
   $pj${"owner": "PACOBU", "products": "PACOBU, Ngagara Bujumbura (2016) - notebooks (over 10,000/day at opening), kraft packaging, printing", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('inter ?pack burundi', null, 'inter ?pack burundi', true,
   $pj${"owner": "INTER PACK", "products": "INTER PACK Burundi, Maramvya (opened 2024-10-14, about BIF 30 bn) - board packaging, labels, straws - recycling plan", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('environmental protectors', null, 'environmental protectors', true,
   $pj${"owner": "EPG", "products": "Environmental Protectors Group, Bujumbura - paper and non-woven bags", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('imprimerie mex', null, 'imprimerie mex', true,
   $pj${"owner": "MEX", "products": "Commercial printing, Rohero Bujumbura", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('hope design', null, 'hope design', true,
   $pj${"owner": "Hope Design", "products": "Design, printing, paper boxes", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('itrapack', null, 'itrapack', true,
   $pj${"owner": "ITRACOM", "products": "Itrapack - industrial sacks and packaging", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'BI', 'Burundi', 'none',
   $cm$No confirmed paper machine - BUMAC copy paper (to confirm), notebook and box converters (PACOBU, INTER PACK) - cement limestone only$cm$,
   $cm$Burundi's paper firms sit in Bujumbura: BUMAC (copy, offset and art paper - machine to confirm), PACOBU (notebooks, kraft packaging), INTER PACK (board packaging, opened 2024-10), EPG (paper bags) and printers. HS 48 imports about USD 18.1 m in 2023. No paper PCC or GCC - BUCECO cement and the Rusizi carbonate deposit, and CaCO3 imports about 400 t (2023). Rwanda leads noted: Mingyang Paper (fluting), Bonus Industries.$cm$,
   $cm${"fillers": "Cement: BUCECO. No PCC or GCC.", "mills": "To confirm: BUMAC. Context: PACOBU, INTER PACK, EPG, MEX, Hope Design, Itrapack.", "strategy": "Confirm BUMAC's machine, else serve via Tanzania and Kenya suppliers.", "risks": "Tiny market, landlocked.", "next_steps": ["Ask BUMAC whether it runs a paper machine"], "key_numbers": [{"label": "HS 48 imports 2023", "value": "about USD 18.1 m"}, {"label": "CaCO3 imports 2023", "value": "about 400 t"}], "files": ["seed_20261016zzzs_burundi_mills_fillers"]}$cm$::jsonb,
   $cm$초지기 미확인 — BUMAC 복사용지(확인 필요), 노트·상자 가공(PACOBU, INTER PACK) — 시멘트용 석회석뿐$cm$,
   $cm$부룬디 종이 업체는 부줌부라 집중: BUMAC(복사·오프셋·아트지 — 초지기 확인), PACOBU(노트·크라프트 포장), INTER PACK(판지 포장, 2024-10 개장), EPG(종이봉투), 인쇄업체. HS 48 수입 2023 약 1,809만 달러. 제지용 PCC·GCC 없음 — BUCECO 시멘트·Rusizi 탄산염 매장, CaCO3 수입 약 400 t(2023). 르완다 후보 메모: Mingyang Paper(골심지), Bonus Industries.$cm$,
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
      ('\mbumac\M|burundi manufacturing actions', 'bujumbura', 'bumac'),
  ('pacobu|paper converter burundi', null, 'pacobu|paper converter burundi'),
  ('inter ?pack burundi', null, 'inter ?pack burundi'),
  ('environmental protectors', null, 'environmental protectors'),
  ('imprimerie mex', null, 'imprimerie mex'),
  ('hope design', null, 'hope design'),
  ('itrapack', null, 'itrapack')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'burundi_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BI'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'burundi_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'buceco|burundi cement')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'BI'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'BI'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'BI'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BI'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    