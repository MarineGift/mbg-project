-- ============================================================
-- seed_20261016zzx_sudan_market.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Sudan update (reports 2026-10-16). WAR HOLD - every memo carries a war
-- and sanctions note. No paper mill data in the reports (only the filler
-- report, twice) - no mill rows.
-- 1) Fillers if missing (2): Sudan Chemical (supplier), Nile Cement Rabak.
-- 2) app.country_markets SD row (priority none).
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
           v.party_name, 'SD', v.region, v.city, v.website, 'active', 'sudan_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('sudan chemical', 'Sudan Chemical (CaCO3 supply)', 'Khartoum', 'Khartoum', null, 'Sudan Chemical — 탄산칼슘 분말·대리석 칩(25 kg) 공급, 제지·플라스틱·도료·건축 용도. 제품 페이지에 인도 제조·수출업체·+91 연락처 → 현지 제조사로 보기 어려움.', 'Sudan Chemical - supplies calcium carbonate powder and marble chips (25 kg bags) for paper, plastics, paint and building in Khartoum and Omdurman. Its product page names an Indian maker and exporter with a +91 number, so it is a supplier, not a confirmed local producer.', 'SD check 2026-10-16: food-grade 99.5 pct / 96 brightness spec is not a paper spec. mail@sudanchemical.com. WAR RISK: civil war since 2023 (about 10 pct of factories restarted, 1,800 damaged - 2026-04), screen US and EU Sudan conflict sanctions before any contact.'),
  ('nile cement|rabak', 'Nile Cement (Carawan) - Rabak', 'White Nile', 'Rabak', null, 'Carawan 그룹 Nile Cement Rabak 시멘트 공장 — Al-Jabalian 석회석 약 2.5억 t.', 'Nile Cement Company (Carawan Group, Carawan Industrial Company 2003), Rabak cement plant - about 250 Mt limestone reserves at Al-Jabalian.', 'SD check 2026-10-16: cement, no GCC line. Long-term raw-material lead. A government investment sheet lists a 20 t/day carbonate project (USD 1.5 m, 35,000 m2, Atbara / Sennar / Jabal Marra / Gabalain) for plastics, farming and toothpaste - not built as far as known. WAR RISK: civil war since 2023 (about 10 pct of factories restarted, 1,800 damaged - 2026-04), screen US and EU Sudan conflict sanctions before any contact.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%SD check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('sudan chemical', 'Sudan Chemical (CaCO3 supply)', 'Khartoum', 'Khartoum', null, 'Sudan Chemical — 탄산칼슘 분말·대리석 칩(25 kg) 공급, 제지·플라스틱·도료·건축 용도. 제품 페이지에 인도 제조·수출업체·+91 연락처 → 현지 제조사로 보기 어려움.', 'Sudan Chemical - supplies calcium carbonate powder and marble chips (25 kg bags) for paper, plastics, paint and building in Khartoum and Omdurman. Its product page names an Indian maker and exporter with a +91 number, so it is a supplier, not a confirmed local producer.', 'SD check 2026-10-16: food-grade 99.5 pct / 96 brightness spec is not a paper spec. mail@sudanchemical.com. WAR RISK: civil war since 2023 (about 10 pct of factories restarted, 1,800 damaged - 2026-04), screen US and EU Sudan conflict sanctions before any contact.'),
  ('nile cement|rabak', 'Nile Cement (Carawan) - Rabak', 'White Nile', 'Rabak', null, 'Carawan 그룹 Nile Cement Rabak 시멘트 공장 — Al-Jabalian 석회석 약 2.5억 t.', 'Nile Cement Company (Carawan Group, Carawan Industrial Company 2003), Rabak cement plant - about 250 Mt limestone reserves at Al-Jabalian.', 'SD check 2026-10-16: cement, no GCC line. Long-term raw-material lead. A government investment sheet lists a 20 t/day carbonate project (USD 1.5 m, 35,000 m2, Atbara / Sennar / Jabal Marra / Gabalain) for plastics, farming and toothpaste - not built as far as known. WAR RISK: civil war since 2023 (about 10 pct of factories restarted, 1,800 damaged - 2026-04), screen US and EU Sudan conflict sanctions before any contact.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'sudan_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Sudan Chemical (CaCO3 supply)', 'Carbonate supplier', 'Carbonate supply (likely imported) - distribution only', 'merchant', 'C', 'gcc'),
  ('Nile Cement (Carawan) - Rabak', 'Limestone owner (cement)', 'Limestone reserve - long-term raw material', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'sudan_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'SD', 'Sudan', 'none',
   $cm$War hold - no paper PCC or GCC plant, no paper machine identified - carbonate only via Sudan Chemical (likely imported) and cement limestone (Nile Cement)$cm$,
   $cm$Sudan has no identified paper PCC or GCC maker and no paper mill data in this research. Sudan Chemical sells calcium carbonate but appears to source it in India. Nile Cement (Carawan) holds about 250 Mt limestone at Al-Jabalian. A 20 t/day carbonate investment project is listed by the government (not built). The civil war since 2023 left about 10 pct of factories running (2026-04) and 1,800 sites damaged, and a Khartoum industrial-area recovery committee formed 2026-08. Supply, if any, would be by Egyptian GCC makers (Alfacarb, ACCM, Arab Company for Calcium Carbonate, El Sayaad).$cm$,
   $cm${"fillers": "Supplier: Sudan Chemical (likely imported). Limestone: Nile Cement Rabak. Nearest paper GCC: Egypt (Minya cluster).", "mills": "No paper machine identified - paper-company report not yet received.", "strategy": "Hold. Revisit after recovery - serve via Egyptian GCC makers and Egyptian mills (QPIC exports to Sudan).", "risks": "Civil war, sanctions, power, logistics and payment.", "next_steps": ["Get the Sudan paper-company report", "Add Arab Company for Calcium Carbonate to EG"], "key_numbers": [{"label": "Factories restarted (2026-04)", "value": "about 10 pct"}, {"label": "Nile Cement limestone", "value": "about 250 Mt"}], "files": ["seed_20261016zzx_sudan_market"]}$cm$::jsonb,
   $cm$내전 보류 — 제지용 PCC·GCC 공장·초지기 미확인 — Sudan Chemical(수입 추정)·Nile Cement 석회석뿐$cm$,
   $cm$수단에는 제지용 PCC·GCC 제조사가 확인되지 않고, 이번 자료에 제지사 정보 없음. Sudan Chemical 은 탄산칼슘을 팔지만 인도산 공급으로 보임. Nile Cement(Carawan)가 Al-Jabalian 석회석 약 2.5억 t 보유. 정부 투자목록에 20 t/일 탄산칼슘 사업(미건설). 2023년 이후 내전으로 공장 약 10%만 재가동(2026-04), 1,800곳 피해, 2026-08 하르툼 산업단지 복구 위원회. 공급은 이집트 GCC(Alfacarb·ACCM·Arab Company for Calcium Carbonate·El Sayaad) 경유.$cm$,
   null, null,
   $cm$내전·초지기 미확인 — 산정 안 함$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
select 'filler' as kind, p.party_name as name,
       case when p.source = 'sudan_update_20261016' then 'added now' else 'already there' end as status, coalesce(p.country_code, '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'sudan chemical' or p.party_name ~* 'nile cement|rabak')
union all
select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
       coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
from app.country_markets cm
where cm.country_code = 'SD'
union all
select 'existing mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'), '-', p.id::text
from app.parties p
where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'SD'
order by 1, 2;
