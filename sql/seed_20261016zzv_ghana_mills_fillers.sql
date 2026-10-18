-- ============================================================
-- seed_20261016zzv_ghana_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Ghana update (reports 2026-10-16). Fixed generator.
-- 1) Fillers if missing (3): Alkaboat Plus, Carmeuse Ghana, Ghani ChemWorld.
-- 2) Mill if missing (1) + plant block: Akosombo Paper Mill. Context (6):
--    converters (Belpak, Delta, FON, Fine Print, Prak, Jay Kay).
-- 3) app.country_markets GH row (priority none).
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
           v.party_name, 'GH', v.region, v.city, v.website, 'active', 'ghana_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('alkaboat', 'Alkaboat Plus Production - Accra', 'Greater Accra', 'Accra', null, 'Alkaboat Plus 산업광물 채굴·분쇄·정제 — GCC·석영·실리카샌드, 제지·도료·플라스틱 용도 명시.', 'Alkaboat Plus Production Ltd, Accra - mining, grinding and refining of industrial minerals incl. GCC, quartz and silica sand, paper, paint and plastics named.', 'GH check 2026-10-16: D50, brightness and capacity unknown - sample test. info@alkaboatplusgh.com.'),
  ('carmeuse.*(ghana|takoradi)', 'Carmeuse Lime Products Ghana - Takoradi', 'Western', 'Takoradi', null, 'Carmeuse 가나(1995 첫 소석회 시설, Takoradi) — 석회·돌로마이트·농업용 탄산염, 2020 자료 연 1.3만 t.', 'Carmeuse Lime Products (Ghana) Ltd, Takoradi - first hydrated-lime plant 1995, lime, dolomite and agricultural carbonates, about 13,000 t/yr in 2020 data (not paper grades).', 'GH check 2026-10-16: PCC lime route. 2020 contact Faisal Iddrisu (recheck).'),
  ('ghani chem', 'Ghani ChemWorld (PCC supply)', 'Ghana', null, null, 'Ghani ChemWorld PCC 제지용 소개 — CaCO3 99.34%, 중앙 입도 약 5.0 μm, L* 95.55.', 'Ghani ChemWorld Limited - offers PCC for paper with published data: 99.34 pct CaCO3, median about 5.0 micron, L* 95.55, MgCO3 0.41 pct.', 'GH check 2026-10-16: maker and origin unknown (possibly imported). Not added: Ghacem (cement grinding at Tema, Takoradi). No Ghanaian paper PCC plant found - possible imports: Egypt (HERBOCAL), Nigeria (Lafarge Africa).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%GH check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('alkaboat', 'Alkaboat Plus Production - Accra', 'Greater Accra', 'Accra', null, 'Alkaboat Plus 산업광물 채굴·분쇄·정제 — GCC·석영·실리카샌드, 제지·도료·플라스틱 용도 명시.', 'Alkaboat Plus Production Ltd, Accra - mining, grinding and refining of industrial minerals incl. GCC, quartz and silica sand, paper, paint and plastics named.', 'GH check 2026-10-16: D50, brightness and capacity unknown - sample test. info@alkaboatplusgh.com.'),
  ('carmeuse.*(ghana|takoradi)', 'Carmeuse Lime Products Ghana - Takoradi', 'Western', 'Takoradi', null, 'Carmeuse 가나(1995 첫 소석회 시설, Takoradi) — 석회·돌로마이트·농업용 탄산염, 2020 자료 연 1.3만 t.', 'Carmeuse Lime Products (Ghana) Ltd, Takoradi - first hydrated-lime plant 1995, lime, dolomite and agricultural carbonates, about 13,000 t/yr in 2020 data (not paper grades).', 'GH check 2026-10-16: PCC lime route. 2020 contact Faisal Iddrisu (recheck).'),
  ('ghani chem', 'Ghani ChemWorld (PCC supply)', 'Ghana', null, null, 'Ghani ChemWorld PCC 제지용 소개 — CaCO3 99.34%, 중앙 입도 약 5.0 μm, L* 95.55.', 'Ghani ChemWorld Limited - offers PCC for paper with published data: 99.34 pct CaCO3, median about 5.0 micron, L* 95.55, MgCO3 0.41 pct.', 'GH check 2026-10-16: maker and origin unknown (possibly imported). Not added: Ghacem (cement grinding at Tema, Takoradi). No Ghanaian paper PCC plant found - possible imports: Egypt (HERBOCAL), Nigeria (Lafarge Africa).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'ghana_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Alkaboat Plus Production - Accra', 'GCC producer', 'Local GCC, paper named - sample first', 'merchant', 'C', 'gcc'),
  ('Carmeuse Lime Products Ghana - Takoradi', 'Lime producer', 'Lime - PCC raw material', 'merchant', 'C', 'pcc'),
  ('Ghani ChemWorld (PCC supply)', 'PCC supplier', 'PCC supply lead - maker to trace', 'merchant', 'C', 'pcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'ghana_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'GH', v.region, v.city, v.website, 'active', 'ghana_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('akosombo', 'akosombo', 'akosombo|tgrg', 'Akosombo Paper Mill - Akosombo', 'Eastern', 'Akosombo', null, 'Akosombo Paper Mill — 폐지 회수·재생펄프 티슈 점보롤, 약 10 t/일·연 약 4,000 t, 정상 시 약 40명, 8.31 에이커(UNIDO 2023). TGRG Pulp 연계.', 'Akosombo Paper Mill, Akosombo (Eastern Region) - collects waste paper, makes recycled pulp and tissue jumbo rolls, about 10 t/day or 4,000 t/yr, about 40 staff when running, 8.31-acre site (UNIDO 2023 case study). TGRG Pulp Company is linked to the site.', 'GH check 2026-10-16: 2026 running status unknown - the only confirmed base-paper machine in Ghana.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GH'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%GH check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GH'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('akosombo', 'akosombo', 'akosombo|tgrg', 'Akosombo Paper Mill — 폐지 회수·재생펄프 티슈 점보롤, 약 10 t/일·연 약 4,000 t, 정상 시 약 40명, 8.31 에이커(UNIDO 2023). TGRG Pulp 연계.', 'Akosombo Paper Mill, Akosombo (Eastern Region) - collects waste paper, makes recycled pulp and tissue jumbo rolls, about 10 t/day or 4,000 t/yr, about 40 staff when running, 8.31-acre site (UNIDO 2023 case study). TGRG Pulp Company is linked to the site.', 'GH check 2026-10-16: 2026 running status unknown - the only confirmed base-paper machine in Ghana.'),
  ('belpak', null, 'belpak', null, null, 'GH check 2026-10-16: Belpak - tissue converting 20,000-25,000 t/yr (Fabio Perini), no paper machine confirmed - context only.'),
  ('delta paper', null, 'delta paper', null, null, 'GH check 2026-10-16: Delta Paper Mill, Tema - converts jumbo rolls (Flora, Delta Smile), exports to CI, LR, BJ, TG - context only.'),
  ('\mfon\M', null, '\mfon\M', null, null, 'GH check 2026-10-16: FON, Alajo Accra - tissue (FONTISSUE, ADEPA, TEMPLE) and copy paper, machine not confirmed - context only.'),
  ('fine print', null, 'fine print', null, null, 'GH check 2026-10-16: Fine Print, Tema - converting, Soft Touch tissue, egg trays, paper sacks - context only.'),
  ('prak', null, 'prak', null, null, 'GH check 2026-10-16: Prak Industries, Kasoa - tissue products, machine not confirmed - context only.'),
  ('jay ?kay', null, 'jay ?kay', null, null, 'GH check 2026-10-16: Jay Kay, North Industrial Area Accra - copy paper, exercise books, cartons, printing - backward integration to pulp and paper stated - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'ghana_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GH'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('akosombo', 'akosombo', 'akosombo|tgrg'),
  ('belpak', null, 'belpak'),
  ('delta paper', null, 'delta paper'),
  ('\mfon\M', null, '\mfon\M'),
  ('fine print', null, 'fine print'),
  ('prak', null, 'prak'),
  ('jay ?kay', null, 'jay ?kay')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GH'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('akosombo', 'akosombo', 'akosombo|tgrg', false,
   $pj${"owner": "Akosombo Paper Mill", "priority": 1, "products": "Recycled tissue jumbo rolls", "grades": ["Tissue"], "capacity": {"value": 4000, "unit": "metric_t", "year": "UNIDO 2023", "source": "unido.org"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.01}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Trial 1-3-5 pct."}, "approach": "Technical proof site for West Africa.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('belpak', null, 'belpak', true,
   $pj${"owner": "Blow Group", "products": "Belpak - tissue converting 20,000-25,000 t/yr (Fabio Perini), no paper machine confirmed", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('delta paper', null, 'delta paper', true,
   $pj${"owner": "Delta Paper Mill", "products": "Delta Paper Mill, Tema - converts jumbo rolls (Flora, Delta Smile), exports to CI, LR, BJ, TG", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mfon\M', null, '\mfon\M', true,
   $pj${"owner": "FON Ltd", "products": "FON, Alajo Accra - tissue (FONTISSUE, ADEPA, TEMPLE) and copy paper, machine not confirmed", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('fine print', null, 'fine print', true,
   $pj${"owner": "Fine Print", "products": "Fine Print, Tema - converting, Soft Touch tissue, egg trays, paper sacks", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('prak', null, 'prak', true,
   $pj${"owner": "Prak Industries", "products": "Prak Industries, Kasoa - tissue products, machine not confirmed", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('jay ?kay', null, 'jay ?kay', true,
   $pj${"owner": "Jay Kay Industries", "products": "Jay Kay, North Industrial Area Accra - copy paper, exercise books, cartons, printing - backward integration to pulp and paper stated", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'GH', 'Ghana', 'none',
   $cm$One small base-paper mill (Akosombo recycled tissue, about 4 kt) - converters around Accra and Tema - no paper PCC or GCC plant$cm$,
   $cm$Ghana's only confirmed paper machine is Akosombo Paper Mill (recycled tissue jumbo rolls, about 10 t/day, UNIDO 2023). Belpak (20-25 kt converting), Delta Paper Mill, FON, Fine Print, Prak and Jay Kay convert imported or local jumbo rolls and sheets. Fillers: Alkaboat Plus (local GCC, paper named), Carmeuse Takoradi (lime 13 kt), Ghani ChemWorld (PCC offer, maker unknown). Printing paper is imported. Value is a technical proof site and a West African sales base.$cm$,
   $cm${"fillers": "GCC: Alkaboat Plus. Lime: Carmeuse Ghana. PCC offer: Ghani ChemWorld. Possible imports: EG and NG.", "mills": "Base paper: Akosombo Paper Mill. Converters: Belpak, Delta, FON, Fine Print, Prak, Jay Kay.", "strategy": "Small tissue trial at Akosombo, trace jumbo-roll suppliers of Belpak and Delta, watch Jay Kay backward integration.", "risks": "Tiny volume, mill status uncertain.", "next_steps": ["Confirm Akosombo running status"], "key_numbers": [{"label": "Akosombo", "value": "about 4 kt/yr (2023)"}, {"label": "Belpak converting", "value": "20-25 kt/yr"}], "files": ["seed_20261016zzv_ghana_mills_fillers"]}$cm$::jsonb,
   $cm$소형 원지공장 1곳(Akosombo 재생 티슈 약 4천 t) — Accra·Tema 가공업체 — 제지용 PCC·GCC 공장 없음$cm$,
   $cm$가나의 확인된 초지기는 Akosombo Paper Mill(재생 티슈 점보롤, 약 10 t/일, UNIDO 2023)뿐. Belpak(가공 2만~2.5만 t)·Delta·FON·Fine Print·Prak·Jay Kay 는 점보롤·시트 가공. 충전제: Alkaboat Plus(현지 GCC, 제지 명시), Carmeuse Takoradi(석회 1.3만 t), Ghani ChemWorld(PCC 공급, 제조사 불명). 인쇄용지는 수입. 기술 실증·서아프리카 영업 거점으로서 가치.$cm$,
   40, 200,
   $cm$Akosombo 4천 t × FCC 1~5%$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('akosombo', 'akosombo', 'akosombo|tgrg'),
  ('belpak', null, 'belpak'),
  ('delta paper', null, 'delta paper'),
  ('\mfon\M', null, '\mfon\M'),
  ('fine print', null, 'fine print'),
  ('prak', null, 'prak'),
  ('jay ?kay', null, 'jay ?kay')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'ghana_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GH'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'ghana_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'alkaboat' or p.party_name ~* 'carmeuse.*(ghana|takoradi)' or p.party_name ~* 'ghani chem')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'GH'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'GH'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'GH'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GH'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    