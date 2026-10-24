-- ============================================================
-- seed_20261017d_cote_divoire_market.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Côte d'Ivoire (CI) update (reports 2026-10-17).
-- 1) Filler if missing (1): Gypse Abidjan (coarse GCC, unverified).
-- 2) Mill if missing (1, no priority): Nouvelle MICI-EMBACI (recycled pulp).
--    Context (7): converters.
-- 3) app.country_markets CI row (priority none).
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
           v.party_name, 'CI', v.region, v.city, v.website, 'active', 'cote_divoire_update_20261017',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('gypse abidjan', 'Gypse Abidjan (GCC grinding)', 'Abidjan', 'Abidjan', null, 'Gypse Abidjan 탄산칼슘 분쇄 공장 — Zenith Industrial 2020 프로젝트: Raymond 밀 3 t/h, 100~200 mesh, 시운전 완료(설비사 자료).', 'Gypse Abidjan - GCC grinding plant per a 2020 Zenith Industrial project note: Raymond mill, 3 t/h design (about 24 kt/yr theoretical), 100-200 mesh, commissioned.', 'CI check 2026-10-17: equipment-vendor source only - existence, status and fine grades to verify. 100-200 mesh is far too coarse for paper. SODEMI (state mining company, Cocody, labs) can point to limestone and grinders - infosodemi@sodemi.ci. Tunisian MBS lists CI exports. No Ivorian paper PCC or GCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%CI check 2026-10-17%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('gypse abidjan', 'Gypse Abidjan (GCC grinding)', 'Abidjan', 'Abidjan', null, 'Gypse Abidjan 탄산칼슘 분쇄 공장 — Zenith Industrial 2020 프로젝트: Raymond 밀 3 t/h, 100~200 mesh, 시운전 완료(설비사 자료).', 'Gypse Abidjan - GCC grinding plant per a 2020 Zenith Industrial project note: Raymond mill, 3 t/h design (about 24 kt/yr theoretical), 100-200 mesh, commissioned.', 'CI check 2026-10-17: equipment-vendor source only - existence, status and fine grades to verify. 100-200 mesh is far too coarse for paper. SODEMI (state mining company, Cocody, labs) can point to limestone and grinders - infosodemi@sodemi.ci. Tunisian MBS lists CI exports. No Ivorian paper PCC or GCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'cote_divoire_update_20261017';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Gypse Abidjan (GCC grinding)', 'GCC grinder (unverified)', 'Coarse GCC line - verify first', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'cote_divoire_update_20261017'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'CI', v.region, v.city, v.website, 'active', 'cote_divoire_update_20261017',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('mici.?embaci|nme\.com', 'koumassi|abidjan', 'mici|embaci', 'Nouvelle MICI-EMBACI - Koumassi', 'Abidjan', 'Koumassi', null, 'Nouvelle MICI-EMBACI(Koumassi 산업단지) 골판지·상자·인쇄·PP 포대 + 폐골판지·인쇄폐지 재활용 → 재생 펄프(파트너사 공정 투입).', 'Nouvelle MICI-EMBACI, Koumassi industrial zone, Abidjan - corrugated sheets and boxes, printing, labels, PP sacks, plus an integrated recycling plant turning old corrugated and print waste to recycled pulp for partner mills.', 'CI check 2026-10-17: pulp plant is not a paper machine - ask which partner mill uses the pulp. info@nme.com.ci, +225 27 21 59 88 00.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CI'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%CI check 2026-10-17%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CI'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('mici.?embaci|nme\.com', 'koumassi|abidjan', 'mici|embaci', 'Nouvelle MICI-EMBACI(Koumassi 산업단지) 골판지·상자·인쇄·PP 포대 + 폐골판지·인쇄폐지 재활용 → 재생 펄프(파트너사 공정 투입).', 'Nouvelle MICI-EMBACI, Koumassi industrial zone, Abidjan - corrugated sheets and boxes, printing, labels, PP sacks, plus an integrated recycling plant turning old corrugated and print waste to recycled pulp for partner mills.', 'CI check 2026-10-17: pulp plant is not a paper machine - ask which partner mill uses the pulp. info@nme.com.ci, +225 27 21 59 88 00.'),
  ('acipac', null, 'acipac', null, null, 'CI check 2026-10-17: ACIPAC (1993), Yopougon - converts tissue base (ouate de cellulose) to toilet tissue, napkins, notebooks, kraft bags, 3 sites, 500+ staff - context only.'),
  ('satoci', null, 'satoci', null, null, 'CI check 2026-10-17: SATOCI (1983), Yopougon - tissue converting (LOTUS, SANITEX, PAPYRUS, LILAS) - brands overlap with SATOGA (GA) - context only.'),
  ('sonaco', null, 'sonaco', null, null, 'CI check 2026-10-17: SONACO, Yopougon - corrugated boxes - context only.'),
  ('sivem', null, 'sivem', null, null, 'CI check 2026-10-17: SIVEM (1975), Yopougon - multiwall kraft sacks, reels of Smurfit and Billerud - context only.'),
  ('afripack', null, 'afripack', null, null, 'CI check 2026-10-17: AFRIPACK, Yopougon - corrugated - context only.'),
  ('siempa', null, 'siempa', null, null, 'CI check 2026-10-17: SIEMPA, Koumassi - paper packaging - context only.'),
  ('nouvelle de papier', null, 'nouvelle de papier', null, null, 'CI check 2026-10-17: La Nouvelle de Papier, Treichville - paper sector listing - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'cote_divoire_update_20261017';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CI'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('mici.?embaci|nme\.com', 'koumassi|abidjan', 'mici|embaci'),
  ('acipac', null, 'acipac'),
  ('satoci', null, 'satoci'),
  ('sonaco', null, 'sonaco'),
  ('sivem', null, 'sivem'),
  ('afripack', null, 'afripack'),
  ('siempa', null, 'siempa'),
  ('nouvelle de papier', null, 'nouvelle de papier')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CI'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('mici.?embaci|nme\.com', 'koumassi|abidjan', 'mici|embaci', false,
   $pj${"owner": "Nouvelle MICI-EMBACI", "products": "Corrugated, recycled pulp", "grades": [], "approach": "Trace the partner paper mill.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-17"}$pj$::jsonb),
  ('acipac', null, 'acipac', true,
   $pj${"owner": "ACIPAC", "products": "ACIPAC (1993), Yopougon - converts tissue base (ouate de cellulose) to toilet tissue, napkins, notebooks, kraft bags, 3 sites, 500+ staff", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('satoci', null, 'satoci', true,
   $pj${"owner": "SATOCI", "products": "SATOCI (1983), Yopougon - tissue converting (LOTUS, SANITEX, PAPYRUS, LILAS) - brands overlap with SATOGA (GA)", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('sonaco', null, 'sonaco', true,
   $pj${"owner": "SONACO", "products": "SONACO, Yopougon - corrugated boxes", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('sivem', null, 'sivem', true,
   $pj${"owner": "SIVEM", "products": "SIVEM (1975), Yopougon - multiwall kraft sacks, reels of Smurfit and Billerud", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('afripack', null, 'afripack', true,
   $pj${"owner": "AFRIPACK", "products": "AFRIPACK, Yopougon - corrugated", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('siempa', null, 'siempa', true,
   $pj${"owner": "SIEMPA", "products": "SIEMPA, Koumassi - paper packaging", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-17"}$pj$::jsonb),
  ('nouvelle de papier', null, 'nouvelle de papier', true,
   $pj${"owner": "La Nouvelle de Papier", "products": "La Nouvelle de Papier, Treichville - paper sector listing", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-17"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'CI', 'Côte d''Ivoire', 'none',
   $cm$No confirmed paper machine - Abidjan tissue, corrugated and sack converters (ACIPAC, SATOCI, SONACO, SIVEM) supply the Sahel - MICI-EMBACI recycled pulp$cm$,
   $cm$Côte d'Ivoire is West Africa's paper-products hub (main supplier to Mali, Burkina Faso, Gabon) but no paper machine is confirmed: ACIPAC and SATOCI convert tissue base, SONACO, AFRIPACK and SIEMPA make corrugated, SIVEM makes kraft sacks (Smurfit, Billerud reels), and Nouvelle MICI-EMBACI recycles OCC to pulp for partner mills. No paper PCC or GCC: Gypse Abidjan (coarse 100-200 mesh GCC, vendor source), SODEMI (state mining labs), Tunisian MBS imports.$cm$,
   $cm${"fillers": "Coarse GCC: Gypse Abidjan (unverified). Contacts: SODEMI. No PCC.", "mills": "To confirm: Nouvelle MICI-EMBACI (recycled pulp). Context: ACIPAC, SATOCI, SONACO, SIVEM, AFRIPACK, SIEMPA, La Nouvelle de Papier.", "strategy": "Find the reel suppliers behind ACIPAC, SATOCI and SIVEM and the partner mill using MICI-EMBACI pulp - those mills are the FCC targets for the whole Sahel.", "risks": "No local machine confirmed.", "next_steps": ["Ask MICI-EMBACI which mill uses its pulp", "Ask ACIPAC and SATOCI for jumbo-roll sources"], "key_numbers": [{"label": "Gypse Abidjan", "value": "3 t/h coarse GCC (vendor note)"}], "files": ["seed_20261017d_cote_divoire_market"]}$cm$::jsonb,
   $cm$초지기 미확인 — 아비장 티슈·골판지·포대 가공(ACIPAC, SATOCI, SONACO, SIVEM)이 사헬 공급 — MICI-EMBACI 재생 펄프$cm$,
   $cm$코트디부아르는 서아프리카 종이제품 거점(말리·부르키나·가봉 주 공급국)이나 초지기 미확인: ACIPAC·SATOCI 티슈 원지 가공, SONACO·AFRIPACK·SIEMPA 골판지, SIVEM 크라프트 포대(Smurfit·Billerud 원지), Nouvelle MICI-EMBACI 폐골판지 재생 펄프(파트너 제지사 공급). 제지용 PCC·GCC 없음: Gypse Abidjan(굵은 100~200 mesh GCC, 설비사 자료), SODEMI(국영 광업 실험실), 튀니지 MBS 수입.$cm$,
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
      ('mici.?embaci|nme\.com', 'koumassi|abidjan', 'mici|embaci'),
  ('acipac', null, 'acipac'),
  ('satoci', null, 'satoci'),
  ('sonaco', null, 'sonaco'),
  ('sivem', null, 'sivem'),
  ('afripack', null, 'afripack'),
  ('siempa', null, 'siempa'),
  ('nouvelle de papier', null, 'nouvelle de papier')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'cote_divoire_update_20261017' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CI'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'cote_divoire_update_20261017' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'gypse abidjan')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'CI'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'CI'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'CI'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CI'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    