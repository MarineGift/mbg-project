-- ============================================================
-- seed_20261016zzw_libya_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Libya update (reports 2026-10-16). Fixed generator.
-- Every memo carries a sanctions-screening note (UN and US Libya lists).
-- 1) Fillers if missing (4): Osol Elnomow, Alhilal First, Al-Mokawelon,
--    Valley Mining (planned).
-- 2) Mills if missing (2, no priority, machine to confirm): National Paper
--    and Cardboard Factory, Al-Jesr Al-Feddi. Context (10): converters.
-- 3) app.country_markets LY row (priority none).
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
           v.party_name, 'LY', v.region, v.city, v.website, 'active', 'libya_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('osol elnomow|osol-elnomow', 'Osol Elnomow - Tripoli', 'Tripoli', 'Tripoli', null, 'Osol Elnomow(트리폴리) 분쇄 탄산칼슘·실리카 — 도료·플라스틱·종이·건축 용도 명시.', 'Osol Elnomow for Raw Materials Manufacturing, Tripoli - ground calcium carbonate and silica for paint, plastics, paper and building.', 'LY check 2026-10-16: capacity, mills supplied and wet slurry unknown. info@osol-elnomow.com, +218 91 216 1903. An unnamed Libyan customer of Epic Powder commissioned an ultrafine GCC line (ball mill + ITC classifier, D97 about 10-12 micron, paint and plastics) in 2026-05 - ask Epic Powder who. Screen counterparties against UN and US Libya sanctions lists.'),
  ('alhilal first|al-hilal', 'Alhilal First - Misrata', 'Misrata', 'Misrata', null, 'Alhilal First(미스라타) 플라스틱용 탄산칼슘·PE/PP 컴파운드.', 'Alhilal First Company, Misrata - calcium carbonate for plastics and PE / PP compounds.', 'LY check 2026-10-16: coated plastics grades - uncoated GCC to confirm. Screen counterparties against UN and US Libya sanctions lists.'),
  ('mokawelon', 'Al-Mokawelon - Misrata', 'Misrata', 'Misrata', null, 'Al-Mokawelon(2003, 미스라타) 2015~ 석회석·카올린·벤토나이트·탄산칼슘·석고 개발·가공 계획, 튀니지 Golden Gate 통해 수출.', 'Al-Mokawelon Company (2003), Misrata - since 2015 developing limestone, kaolin, bentonite, calcium carbonate and gypsum with refining and grinding projects, exports via Golden Gate International Trading (Tunisia).', 'LY check 2026-10-16: raw-material partner. Screen counterparties against UN and US Libya sanctions lists.'),
  ('valley mining', 'Valley Mining (eastern Libya, planned GCC)', 'Eastern Libya', null, null, 'Valley Mining 리비아 동부 석회석·대리석 기반 GCC 공장 설립 구상.', 'Valley Mining - plans a GCC plant on limestone and marble deposits in eastern Libya.', 'LY check 2026-10-16: plan only. Not added: Elwaseet (chemical distributor). No Libyan paper PCC. Screen counterparties against UN and US Libya sanctions lists.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%LY check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('osol elnomow|osol-elnomow', 'Osol Elnomow - Tripoli', 'Tripoli', 'Tripoli', null, 'Osol Elnomow(트리폴리) 분쇄 탄산칼슘·실리카 — 도료·플라스틱·종이·건축 용도 명시.', 'Osol Elnomow for Raw Materials Manufacturing, Tripoli - ground calcium carbonate and silica for paint, plastics, paper and building.', 'LY check 2026-10-16: capacity, mills supplied and wet slurry unknown. info@osol-elnomow.com, +218 91 216 1903. An unnamed Libyan customer of Epic Powder commissioned an ultrafine GCC line (ball mill + ITC classifier, D97 about 10-12 micron, paint and plastics) in 2026-05 - ask Epic Powder who. Screen counterparties against UN and US Libya sanctions lists.'),
  ('alhilal first|al-hilal', 'Alhilal First - Misrata', 'Misrata', 'Misrata', null, 'Alhilal First(미스라타) 플라스틱용 탄산칼슘·PE/PP 컴파운드.', 'Alhilal First Company, Misrata - calcium carbonate for plastics and PE / PP compounds.', 'LY check 2026-10-16: coated plastics grades - uncoated GCC to confirm. Screen counterparties against UN and US Libya sanctions lists.'),
  ('mokawelon', 'Al-Mokawelon - Misrata', 'Misrata', 'Misrata', null, 'Al-Mokawelon(2003, 미스라타) 2015~ 석회석·카올린·벤토나이트·탄산칼슘·석고 개발·가공 계획, 튀니지 Golden Gate 통해 수출.', 'Al-Mokawelon Company (2003), Misrata - since 2015 developing limestone, kaolin, bentonite, calcium carbonate and gypsum with refining and grinding projects, exports via Golden Gate International Trading (Tunisia).', 'LY check 2026-10-16: raw-material partner. Screen counterparties against UN and US Libya sanctions lists.'),
  ('valley mining', 'Valley Mining (eastern Libya, planned GCC)', 'Eastern Libya', null, null, 'Valley Mining 리비아 동부 석회석·대리석 기반 GCC 공장 설립 구상.', 'Valley Mining - plans a GCC plant on limestone and marble deposits in eastern Libya.', 'LY check 2026-10-16: plan only. Not added: Elwaseet (chemical distributor). No Libyan paper PCC. Screen counterparties against UN and US Libya sanctions lists.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'libya_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Osol Elnomow - Tripoli', 'GCC producer', 'Local GCC, paper named - candidate 1', 'merchant', 'C', 'gcc'),
  ('Alhilal First - Misrata', 'GCC producer', 'Plastics carbonate - processing option', 'merchant', 'C', 'gcc'),
  ('Al-Mokawelon - Misrata', 'Mineral developer', 'Limestone and minerals - raw material', 'merchant', 'C', 'gcc'),
  ('Valley Mining (eastern Libya, planned GCC)', 'GCC producer (planned)', 'Planned GCC plant - long-term JV', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'libya_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'LY', v.region, v.city, v.website, 'active', 'libya_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('national paper.*(cardboard|libya)|المصنع الوطني للورق', 'tripoli', 'national paper', 'National Paper & Cardboard Factory - Tripoli', 'Tripoli', 'Tripoli', null, '트리폴리 종이·판지 제조 등록(디렉터리) — 초지기·생산능력·현황 미확인.', 'National Paper and Cardboard Factory, Tripoli - listed as a paper and board maker in Libyan directories, machines, capacity and status unknown.', 'LY check 2026-10-16: +218 21 462 2221. Screen counterparties against UN and US Libya sanctions lists.'),
  ('jesr|aljesrelfede', 'tajoura', 'jesr', 'Al-Jesr Al-Feddi - Tajoura', 'Tripoli', 'Tajoura', null, 'Al-Jesr Al-Feddi(Tajoura) 폐지 수거·재활용 — 재생 원료 100% 티슈, 골판지·크라프트 포장지.', 'Al-Jesr Al-Feddi, Tajoura - collects and recycles waste paper, 100 pct recycled tissue plus corrugated and kraft packaging.', 'LY check 2026-10-16: own machine not confirmed. Screen counterparties against UN and US Libya sanctions lists.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%LY check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('national paper.*(cardboard|libya)|المصنع الوطني للورق', 'tripoli', 'national paper', '트리폴리 종이·판지 제조 등록(디렉터리) — 초지기·생산능력·현황 미확인.', 'National Paper and Cardboard Factory, Tripoli - listed as a paper and board maker in Libyan directories, machines, capacity and status unknown.', 'LY check 2026-10-16: +218 21 462 2221. Screen counterparties against UN and US Libya sanctions lists.'),
  ('jesr|aljesrelfede', 'tajoura', 'jesr', 'Al-Jesr Al-Feddi(Tajoura) 폐지 수거·재활용 — 재생 원료 100% 티슈, 골판지·크라프트 포장지.', 'Al-Jesr Al-Feddi, Tajoura - collects and recycles waste paper, 100 pct recycled tissue plus corrugated and kraft packaging.', 'LY check 2026-10-16: own machine not confirmed. Screen counterparties against UN and US Libya sanctions lists.'),
  ('emtiaz', null, 'emtiaz', null, null, 'LY check 2026-10-16: Al-Taj tissues - base-paper source unknown - context only. Screen counterparties against UN and US Libya sanctions lists.'),
  ('azhar', null, 'azhar', null, null, 'LY check 2026-10-16: Tissue products since 2009, Souq Al Jumaa Tripoli - context only. Screen counterparties against UN and US Libya sanctions lists.'),
  ('sandiyan', null, 'sandiyan', null, null, 'LY check 2026-10-16: Kitchen towels and tissues, Tajoura - context only. Screen counterparties against UN and US Libya sanctions lists.'),
  ('nahda', null, 'nahda', null, null, 'LY check 2026-10-16: Corrugated boxes (2002, 22,600 m2, about 180 staff) - context only. Screen counterparties against UN and US Libya sanctions lists.'),
  ('\mal.?badr\M|bader-pcc', null, '\mal.?badr\M|bader-pcc', null, null, 'LY check 2026-10-16: Corrugated, boxes, tissue, paper cups, Misrata - context only. Screen counterparties against UN and US Libya sanctions lists.'),
  ('warrak', null, 'warrak', null, null, 'LY check 2026-10-16: Tissue and packaging, Benghazi - context only. Screen counterparties against UN and US Libya sanctions lists.'),
  ('tahdi', null, 'tahdi', null, null, 'LY check 2026-10-16: Copy paper and corrugated, Benghazi - sheeting or own machine to confirm - context only. Screen counterparties against UN and US Libya sanctions lists.'),
  ('tamina', null, 'tamina', null, null, 'LY check 2026-10-16: Corrugated boxes, Misrata - context only. Screen counterparties against UN and US Libya sanctions lists.'),
  ('misrata paper', null, 'misrata paper', null, null, 'LY check 2026-10-16: Corrugated boxes, Misrata - context only. Screen counterparties against UN and US Libya sanctions lists.'),
  ('jawda', null, 'jawda', null, null, 'LY check 2026-10-16: Corrugated, Misrata - context only. Screen counterparties against UN and US Libya sanctions lists.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'libya_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('national paper.*(cardboard|libya)|المصنع الوطني للورق', 'tripoli', 'national paper'),
  ('jesr|aljesrelfede', 'tajoura', 'jesr'),
  ('emtiaz', null, 'emtiaz'),
  ('azhar', null, 'azhar'),
  ('sandiyan', null, 'sandiyan'),
  ('nahda', null, 'nahda'),
  ('\mal.?badr\M|bader-pcc', null, '\mal.?badr\M|bader-pcc'),
  ('warrak', null, 'warrak'),
  ('tahdi', null, 'tahdi'),
  ('tamina', null, 'tamina'),
  ('misrata paper', null, 'misrata paper'),
  ('jawda', null, 'jawda')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('national paper.*(cardboard|libya)|المصنع الوطني للورق', 'tripoli', 'national paper', false,
   $pj${"owner": "National Paper and Cardboard Factory", "products": "Paper and board (to confirm)", "grades": [], "approach": "Confirm paper machine first.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('jesr|aljesrelfede', 'tajoura', 'jesr', false,
   $pj${"owner": "Al-Jesr Al-Feddi", "products": "Recycled tissue, kraft, corrugated", "grades": ["Tissue"], "approach": "Confirm recycling line and machine.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('emtiaz', null, 'emtiaz', true,
   $pj${"owner": "Al-Emtiaz Al-Awal", "products": "Al-Taj tissues - base-paper source unknown", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('azhar', null, 'azhar', true,
   $pj${"owner": "Azhar Al-Rabie", "products": "Tissue products since 2009, Souq Al Jumaa Tripoli", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('sandiyan', null, 'sandiyan', true,
   $pj${"owner": "Al-Sandiyan International", "products": "Kitchen towels and tissues, Tajoura", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('nahda', null, 'nahda', true,
   $pj${"owner": "Al-Nahda Al-Libiya", "products": "Corrugated boxes (2002, 22,600 m2, about 180 staff)", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mal.?badr\M|bader-pcc', null, '\mal.?badr\M|bader-pcc', true,
   $pj${"owner": "Al-Badr", "products": "Corrugated, boxes, tissue, paper cups, Misrata", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('warrak', null, 'warrak', true,
   $pj${"owner": "Al-Warrak", "products": "Tissue and packaging, Benghazi", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('tahdi', null, 'tahdi', true,
   $pj${"owner": "Al-Tahdi Al-Awal", "products": "Copy paper and corrugated, Benghazi - sheeting or own machine to confirm", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('tamina', null, 'tamina', true,
   $pj${"owner": "Tamina", "products": "Corrugated boxes, Misrata", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('misrata paper', null, 'misrata paper', true,
   $pj${"owner": "Misrata Paper and Cardboard", "products": "Corrugated boxes, Misrata", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('jawda', null, 'jawda', true,
   $pj${"owner": "Al-Jawda Carton", "products": "Corrugated, Misrata", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'LY', 'Libya', 'none',
   $cm$No confirmed running paper machine - converters (tissue, corrugated) - planned 200 t/day recycled mill - small GCC makers (Osol Elnomow)$cm$,
   $cm$Libya's paper sector is mostly converting imported base paper: tissue (Al-Emtiaz, Azhar Al-Rabie, Al-Sandiyan, Al-Warrak) and corrugated (Al-Nahda, Al-Badr, Tamina, Misrata Paper and Cardboard). National Paper and Cardboard Factory (Tripoli) and Al-Jesr Al-Feddi (Tajoura, recycled tissue) may have machines - to confirm. A 200 t/day recycled paper mill (about 66 kt/yr, 40,000 m2) was planned with Chinese suppliers for 2025-06 - no start-up evidence. Carbonate: Osol Elnomow (GCC, paper named), Alhilal First, Al-Mokawelon, Valley Mining plan, and an unnamed ultrafine GCC line commissioned 2026-05. No paper PCC. Libyan tissue may be better reached via Azur Papier (TN).$cm$,
   $cm${"fillers": "GCC: Osol Elnomow, Alhilal First, Al-Mokawelon, Valley Mining (plan), unnamed Epic Powder customer (2026-05). Not added: Elwaseet. No PCC.", "mills": "To confirm: National Paper and Cardboard Factory, Al-Jesr Al-Feddi. Context: ten tissue and corrugated converters.", "strategy": "Find a running machine first (the 200 t/day project, National Paper). Serve Libyan tissue demand via Azur Papier / SAH (TN). Sanctions screening on every counterparty.", "risks": "Political instability, UN and US Libya sanctions on listed persons, payment risk.", "next_steps": ["Check whether the 200 t/day recycled mill started"], "key_numbers": [{"label": "Planned recycled mill", "value": "200 t/day (about 66 kt/yr)"}], "files": ["seed_20261016zzw_libya_mills_fillers"]}$cm$::jsonb,
   $cm$가동 초지기 미확인 — 티슈·골판지 가공업체 — 200 t/일 재생 제지공장 계획 — 소형 GCC 업체(Osol Elnomow)$cm$,
   $cm$리비아 제지업은 주로 수입 원지 가공: 티슈(Al-Emtiaz·Azhar·Al-Sandiyan·Al-Warrak), 골판지(Al-Nahda·Al-Badr·Tamina·Misrata). National Paper & Cardboard(트리폴리)·Al-Jesr Al-Feddi(Tajoura 재생 티슈)는 초지기 확인 필요. 200 t/일(약 6.6만 t) 재생 제지공장이 중국 설비로 2025-06 목표 계획 — 가동 근거 없음. 탄산칼슘: Osol Elnomow(GCC, 제지 명시), Alhilal First, Al-Mokawelon, Valley Mining 계획, 2026-05 익명 초미분 GCC 라인. 제지용 PCC 없음. 리비아 티슈는 튀니지 Azur Papier 경유가 더 직접적.$cm$,
   null, null,
   $cm$가동 초지기 미확인 — 산정 안 함$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('national paper.*(cardboard|libya)|المصنع الوطني للورق', 'tripoli', 'national paper'),
  ('jesr|aljesrelfede', 'tajoura', 'jesr'),
  ('emtiaz', null, 'emtiaz'),
  ('azhar', null, 'azhar'),
  ('sandiyan', null, 'sandiyan'),
  ('nahda', null, 'nahda'),
  ('\mal.?badr\M|bader-pcc', null, '\mal.?badr\M|bader-pcc'),
  ('warrak', null, 'warrak'),
  ('tahdi', null, 'tahdi'),
  ('tamina', null, 'tamina'),
  ('misrata paper', null, 'misrata paper'),
  ('jawda', null, 'jawda')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'libya_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'libya_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'osol elnomow|osol-elnomow' or p.party_name ~* 'alhilal first|al-hilal' or p.party_name ~* 'mokawelon' or p.party_name ~* 'valley mining')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'LY'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'LY'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'LY'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'LY'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    