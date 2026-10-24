-- ============================================================
-- seed_20261017a_benin_market.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Benin update (filler report 2026-10-17). The paper part of the paste was
-- Cameroon again - no Benin mill data, no mill rows.
-- 1) Fillers if missing (2): SCB-Lafarge, NOCIBE (limestone).
-- 2) app.country_markets BJ row (priority none).
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
           v.party_name, 'BJ', v.region, v.city, v.website, 'active', 'benin_update_20261017',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('scb.?lafarge|onigbolo', 'SCB-Lafarge - Onigbolo', 'Plateau', 'Onigbolo', null, 'SCB-Lafarge(Onigbolo, Pobè) 석회석 채굴·클링커·시멘트 — 초기 매장 9,000만 t+, 광산 약 1,924 ha, 시멘트 연 약 60만 t(2025).', 'SCB-Lafarge Benin, Onigbolo (Pobè) - limestone quarry, clinker and cement, initial reserve over 90 Mt, mine about 1,924 ha, about 600,000 t/yr cement (2025 press).', 'BJ check 2026-10-17: clay bands between limestone beds - test CaCO3, colour and silicates. Raw-material lead 1.'),
  ('nocibe|nouvelle cimenterie du b[eé]nin', 'NOCIBE - Massé', 'Plateau', 'Massé', null, 'NOCIBE(Massé) 석회석 채굴·클링커·시멘트 — 설비 연 약 150만 t.', 'Nouvelle Cimenterie du Bénin (NOCIBE), Massé - limestone quarry, clinker and cement, about 1.5 Mt/yr cement capacity.', 'BJ check 2026-10-17: raw-material lead 2. Not added: CALCIM SA (Bakpodji-Fongba deposit, status unknown), CIMBENIN and SCB Cotonou (grinding). No Beninese paper PCC or GCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%BJ check 2026-10-17%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('scb.?lafarge|onigbolo', 'SCB-Lafarge - Onigbolo', 'Plateau', 'Onigbolo', null, 'SCB-Lafarge(Onigbolo, Pobè) 석회석 채굴·클링커·시멘트 — 초기 매장 9,000만 t+, 광산 약 1,924 ha, 시멘트 연 약 60만 t(2025).', 'SCB-Lafarge Benin, Onigbolo (Pobè) - limestone quarry, clinker and cement, initial reserve over 90 Mt, mine about 1,924 ha, about 600,000 t/yr cement (2025 press).', 'BJ check 2026-10-17: clay bands between limestone beds - test CaCO3, colour and silicates. Raw-material lead 1.'),
  ('nocibe|nouvelle cimenterie du b[eé]nin', 'NOCIBE - Massé', 'Plateau', 'Massé', null, 'NOCIBE(Massé) 석회석 채굴·클링커·시멘트 — 설비 연 약 150만 t.', 'Nouvelle Cimenterie du Bénin (NOCIBE), Massé - limestone quarry, clinker and cement, about 1.5 Mt/yr cement capacity.', 'BJ check 2026-10-17: raw-material lead 2. Not added: CALCIM SA (Bakpodji-Fongba deposit, status unknown), CIMBENIN and SCB Cotonou (grinding). No Beninese paper PCC or GCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'benin_update_20261017';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('SCB-Lafarge - Onigbolo', 'Limestone owner (cement)', 'Large limestone quarry - raw-material lead', 'merchant', 'C', 'gcc'),
  ('NOCIBE - Massé', 'Limestone owner (cement)', 'Limestone quarry - raw-material lead', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'benin_update_20261017'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'BJ', 'Benin', 'none',
   $cm$No paper PCC or GCC - cement limestone at Onigbolo (SCB-Lafarge, 90 Mt) and Massé (NOCIBE) - paper-company report pending$cm$,
   $cm$Benin has limestone quarried for cement at Onigbolo (SCB-Lafarge, over 90 Mt reserve, clay bands) and Massé (NOCIBE, 1.5 Mt cement), plus CALCIM SA (Bakpodji-Fongba) and Cotonou grinders - no paper PCC or GCC. Cotonou is a port for Nigeria, Togo, Burkina Faso and Niger. Paper-company data not yet received.$cm$,
   $cm${"fillers": "Limestone: SCB-Lafarge, NOCIBE. Not added: CALCIM, CIMBENIN, SCB Cotonou. No PCC or GCC.", "mills": "Not yet researched - report pending.", "strategy": "Treat with Nigeria and Togo. Limestone test only if a regional mill needs local GCC.", "risks": "No known demand.", "next_steps": ["Get the Benin paper-company report"], "key_numbers": [{"label": "Onigbolo reserve", "value": "over 90 Mt"}, {"label": "NOCIBE", "value": "about 1.5 Mt/yr cement"}], "files": ["seed_20261017a_benin_market"]}$cm$::jsonb,
   $cm$제지용 PCC·GCC 없음 — Onigbolo(SCB-Lafarge, 9,000만 t)·Massé(NOCIBE) 시멘트 석회석 — 제지사 보고서 대기$cm$,
   $cm$베냉은 Onigbolo(SCB-Lafarge, 매장 9,000만 t+, 점토층 협재)·Massé(NOCIBE, 시멘트 150만 t)에서 시멘트용 석회석 채굴, CALCIM SA(Bakpodji-Fongba)와 Cotonou 분쇄공장 — 제지용 PCC·GCC 없음. Cotonou 는 나이지리아·토고·부르키나파소·니제르 물류항. 제지사 자료 미수령.$cm$,
   null, null,
   $cm$제지사 자료 미수령 — 산정 안 함$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
select 'filler' as kind, p.party_name as name,
       case when p.source = 'benin_update_20261017' then 'added now' else 'already there' end as status, coalesce(p.country_code, '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'scb.?lafarge|onigbolo' or p.party_name ~* 'nocibe|nouvelle cimenterie du b[eé]nin')
union all
select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
       coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
from app.country_markets cm
where cm.country_code = 'BJ'
union all
select 'existing mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'), '-', p.id::text
from app.parties p
where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'BJ'
order by 1, 2;
