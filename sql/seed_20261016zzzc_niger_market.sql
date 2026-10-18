-- ============================================================
-- seed_20261016zzzc_niger_market.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Niger update (reports 2026-10-17). Filler report only (the second report
-- was Mali again) - no mill rows.
-- 1) Filler if missing (1): Malbaza Cement (limestone).
-- 2) app.country_markets NE row (priority none).
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
           v.party_name, 'NE', v.region, v.city, v.website, 'active', 'niger_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('malbaza', 'Malbaza Cement Company - Malbaza', 'Tahoua', 'Malbaza', null, 'Malbaza Cement(Tahoua) 포틀랜드 시멘트 연 65만 t — 채석·분쇄·품질실험실(2026-08 정부 방문). Karni-Ouest 석회석 CaCO3 72~83.5%(2025 연구).', 'Malbaza Cement Company S.A., Malbaza (Tahoua) - Portland cement 650,000 t/yr with own quarry, grinding, QC lab and bagging (government visit 2026-08). Karni-Ouest limestone measured 72-83.5 pct CaCO3 (2025 study) - below paper GCC purity without upgrading.', 'NE check 2026-10-16: raw-material lead only. Not added: Mango Ciment (Badaguichiri, about 4,500 t/day cement 2025), Dangote Mining Niger, SOCINIC, CITEC (old limestone permits). Limestone belt: Ader Doutchi (Malbaza, Garadaoua, Bourdi, Bouza, Keita, Karni). No paper PCC or GCC - nearest GCC in Nigeria (IzeCarb, Lafarge Africa, Freedom Group, NovaCore).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%NE check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('malbaza', 'Malbaza Cement Company - Malbaza', 'Tahoua', 'Malbaza', null, 'Malbaza Cement(Tahoua) 포틀랜드 시멘트 연 65만 t — 채석·분쇄·품질실험실(2026-08 정부 방문). Karni-Ouest 석회석 CaCO3 72~83.5%(2025 연구).', 'Malbaza Cement Company S.A., Malbaza (Tahoua) - Portland cement 650,000 t/yr with own quarry, grinding, QC lab and bagging (government visit 2026-08). Karni-Ouest limestone measured 72-83.5 pct CaCO3 (2025 study) - below paper GCC purity without upgrading.', 'NE check 2026-10-16: raw-material lead only. Not added: Mango Ciment (Badaguichiri, about 4,500 t/day cement 2025), Dangote Mining Niger, SOCINIC, CITEC (old limestone permits). Limestone belt: Ader Doutchi (Malbaza, Garadaoua, Bourdi, Bouza, Keita, Karni). No paper PCC or GCC - nearest GCC in Nigeria (IzeCarb, Lafarge Africa, Freedom Group, NovaCore).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'niger_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Malbaza Cement Company - Malbaza', 'Limestone owner (cement)', 'Low-purity limestone - raw-material lead', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'niger_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'NE', 'Niger', 'none',
   $cm$No paper PCC or GCC, no paper machine identified - cement limestone only (Malbaza, Mango) - supply via Nigeria$cm$,
   $cm$Niger has limestone in the Ader Doutchi belt (Tahoua) used by Malbaza Cement (650 kt cement) and Mango Ciment (about 4,500 t/day), but measured CaCO3 is only 72-83.5 pct at Karni-Ouest. No paper PCC or GCC producer and no paper mill identified (paper-company report not yet received). Nigerian GCC makers (IzeCarb, Lafarge Africa, Freedom Group, NovaCore) are the nearest supply.$cm$,
   $cm${"fillers": "Limestone: Malbaza Cement. Not added: Mango Ciment and old permit holders. Nearest GCC: Nigeria.", "mills": "No paper machine identified - report pending.", "strategy": "No action - covered by the Nigeria row.", "risks": "No demand, low limestone purity, landlocked.", "next_steps": ["Get the Niger paper-company report"], "key_numbers": [{"label": "Malbaza Cement", "value": "650 kt/yr cement"}, {"label": "Karni-Ouest CaCO3", "value": "72-83.5 pct"}], "files": ["seed_20261016zzzc_niger_market"]}$cm$::jsonb,
   $cm$제지용 PCC·GCC·초지기 없음 — 시멘트용 석회석뿐(Malbaza, Mango) — 나이지리아 경유$cm$,
   $cm$니제르 Tahoua 의 Ader Doutchi 석회석대는 Malbaza Cement(시멘트 65만 t)·Mango Ciment(약 4,500 t/일)가 사용하나 Karni-Ouest CaCO3 72~83.5% 로 낮음. 제지용 PCC·GCC 제조사·제지공장 미확인(제지사 보고서 미수령). 가장 가까운 공급은 나이지리아 GCC(IzeCarb, Lafarge Africa, Freedom Group, NovaCore).$cm$,
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
select 'filler' as kind, p.party_name as name,
       case when p.source = 'niger_update_20261016' then 'added now' else 'already there' end as status, coalesce(p.country_code, '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'malbaza')
union all
select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
       coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
from app.country_markets cm
where cm.country_code = 'NE'
union all
select 'existing mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'), '-', p.id::text
from app.parties p
where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'NE'
order by 1, 2;
