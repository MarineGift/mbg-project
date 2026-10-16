-- ============================================================
-- seed_20261016o_elsalvador_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- El Salvador update (filler report 2026-10-16, Alas Doradas from the
-- Nicaragua and El Salvador reports). Paper-company report still to come.
-- 1) Filler if missing (1): Fábrica Bonanza (to verify). Distributors not added.
-- 2) Mill if missing + plant block: Alas Doradas San Juan Opico (priority 1).
-- 3) app.country_markets SV row (priority medium).
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
           v.party_name, 'SV', v.region, v.city, v.website, 'active', 'elsalvador_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('f[aá]brica bonanza', 'Fábrica Bonanza', 'San Salvador', 'Mejicanos', null, 'San Salvador Mejicanos(Calle a Mariona) 의 고순도 탄산칼슘 생산·판매 업체(디렉터리 기준).', 'Fábrica Bonanza, Calle a Mariona, Mejicanos (San Salvador) - listed as producer and seller of high-purity calcium carbonate.', 'SV check 2026-10-16: process and plant not verified - listing also links feed concentrates. +503 2564-9208. Not added: Pochteca, Brenntag, Química Industrial El Salvador (distributors). Nearest paper GCC maker is GUAMINSA (Guatemala, GT row). No paper PCC plant.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%SV check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('f[aá]brica bonanza', 'Fábrica Bonanza', 'San Salvador', 'Mejicanos', null, 'San Salvador Mejicanos(Calle a Mariona) 의 고순도 탄산칼슘 생산·판매 업체(디렉터리 기준).', 'Fábrica Bonanza, Calle a Mariona, Mejicanos (San Salvador) - listed as producer and seller of high-purity calcium carbonate.', 'SV check 2026-10-16: process and plant not verified - listing also links feed concentrates. +503 2564-9208. Not added: Pochteca, Brenntag, Química Industrial El Salvador (distributors). Nearest paper GCC maker is GUAMINSA (Guatemala, GT row). No paper PCC plant.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'elsalvador_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Fábrica Bonanza', 'GCC producer', 'Local carbonate - plant to verify', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'elsalvador_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'SV', v.region, v.city, v.website, 'active', 'elsalvador_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('alas doradas', 'opico', 'alas doradas|coen', 'Alas Doradas - San Juan Opico', 'La Libertad', 'San Juan Opico', null, 'Grupo Coen(니카라과계) 계열 Alas Doradas — San Juan Opico 재생섬유 티슈·크라프트지, 그룹 공개 연 약 6.5만 t. 2020 Valmet Advantage DCT100HS 티슈 라인(탈묵 포함).', 'Alas Doradas S.A. de C.V. (Grupo Coen / Central America Paper Group), San Juan Opico - toilet tissue, napkins, kitchen towel and kraft on 100 pct recycled fibre, about 65,000 t/yr (group figure). Valmet supplied an Advantage DCT100HS tissue line with deinking (contract 2020). One of the top 3 retail tissue players in Honduras.', 'SV check 2026-10-16: mill-level split not public - El Salvador paper-company report still to enter. +503 2304-2200, pedidosventas@alas-doradas.com.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SV'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%SV check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SV'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('alas doradas', 'opico', 'alas doradas|coen', 'Grupo Coen(니카라과계) 계열 Alas Doradas — San Juan Opico 재생섬유 티슈·크라프트지, 그룹 공개 연 약 6.5만 t. 2020 Valmet Advantage DCT100HS 티슈 라인(탈묵 포함).', 'Alas Doradas S.A. de C.V. (Grupo Coen / Central America Paper Group), San Juan Opico - toilet tissue, napkins, kitchen towel and kraft on 100 pct recycled fibre, about 65,000 t/yr (group figure). Valmet supplied an Advantage DCT100HS tissue line with deinking (contract 2020). One of the top 3 retail tissue players in Honduras.', 'SV check 2026-10-16: mill-level split not public - El Salvador paper-company report still to enter. +503 2304-2200, pedidosventas@alas-doradas.com.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'elsalvador_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SV'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('alas doradas', 'opico', 'alas doradas|coen')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SV'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('alas doradas', 'opico', 'alas doradas|coen',
   $pj${"owner": "Grupo Coen", "priority": 1, "products": "Toilet tissue, napkins, towels, kraft (recycled)", "grades": ["Tissue", "Kraft paper"], "capacity": {"value": 65000, "unit": "metric_t", "year": "Grupo Coen figure", "source": "grupocoen.com"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Report example 3-5 pct (Nicaragua report) - planning only."}, "pitch": "Recycled tissue FCC on the Valmet DCT line", "approach": "Regional anchor for Central American tissue - supply via GUAMINSA (Guatemala) as licensed producer.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'SV', 'El Salvador', 'medium',
   $cm$Alas Doradas recycled tissue (about 65 kt, Valmet DCT) - no paper filler maker, GCC via Guatemala$cm$,
   $cm$El Salvador has no paper PCC or confirmed paper GCC plant - Fábrica Bonanza is listed as a carbonate maker, others distribute (Pochteca, Brenntag, Química Industrial). The key mill is Alas Doradas (Grupo Coen, San Juan Opico): recycled tissue and kraft, about 65 kt/yr, Valmet Advantage DCT line. Paper-company report still to enter.$cm$,
   $cm${"fillers": "Fábrica Bonanza (Mejicanos, to verify). Distributors not added: Pochteca, Brenntag, Química Industrial. Regional paper GCC: GUAMINSA (Guatemala).", "mills": "Alas Doradas San Juan Opico (Grupo Coen). Full mill report pending.", "strategy": "Alas Doradas tissue trial with GUAMINSA as producer - anchor for Central America (Nicaragua, Honduras sales).", "risks": "Single mill, group capacity split unknown.", "next_steps": ["Enter the El Salvador paper-company report", "Propose a DCT-line trial to Alas Doradas"], "key_numbers": [{"label": "Alas Doradas", "value": "about 65 kt/yr (Grupo Coen)"}], "files": ["seed_20261016o_elsalvador_mills_fillers"]}$cm$::jsonb,
   $cm$Alas Doradas 재생 티슈(약 6.5만 t, Valmet DCT) — 제지용 충전제 업체 없음, GCC 는 과테말라에서$cm$,
   $cm$엘살바도르에는 제지용 PCC·GCC 공장 없음 — Fábrica Bonanza 는 탄산칼슘 업체로 등재(확인 필요), 나머지는 유통. 핵심 제지사 Alas Doradas(Grupo Coen, San Juan Opico) 재생 티슈·크라프트 약 6.5만 t, Valmet DCT 라인. 제지기업 보고서 입력 대기.$cm$,
   1950, 3250,
   $cm$Alas Doradas 6.5만 t × FCC 3~5% (그룹 공개 수치)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('alas doradas', 'opico', 'alas doradas|coen')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'elsalvador_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SV'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'elsalvador_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'f[aá]brica bonanza')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'SV'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'SV'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'SV'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SV'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    