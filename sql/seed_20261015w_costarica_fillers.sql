-- ============================================================
-- seed_20261015w_costarica_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Costa Rica update - filler report only (paper-mill report still to come).
-- 1) Fillers if missing (4): Grupo Sur Química El Níspero, PRODECAL,
--    CCC / Cales CR, Carbotico. Distributors not added. No PCC plant.
-- 2) app.country_markets CR row (priority low for now) - the mill seed
--    will update it.
-- Verify also lists existing CR mills.
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
           v.party_name, 'CR', v.region, v.city, v.website, 'active', 'costarica_update_20261015',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('grupo sur', 'Grupo Sur Química - El Níspero', 'Guanacaste', 'El Níspero', null, 'Grupo Sur Química 의 Guanacaste El Níspero 탄산칼슘 공장(2007 가동). 석회석 파쇄·분쇄·입도 조절, Carbonato de Calcio Industrial 325 (CaCO3 약 97.87%).', 'Grupo Sur Química - calcium carbonate plant at El Níspero, Guanacaste (since 2007): limestone crushing, grinding, sizing and QC, Carbonato de Calcio Industrial 325 (about 97.87 pct CaCO3), markets paint, coatings, detergents, mortar, agriculture.', 'CR check 2026-10-15: paper grade and slurry line not confirmed. +506 2211-3700, informacion@gruposur.com. FCC co-production candidate 1.'),
  ('prodecal', 'PRODECAL', 'Cartago', 'Cartago', null, 'Cartago 의 GCC 전문 제조사(1974년). 고순도·고백색·미세 입도 강조, 건설·페인트·비누·세제 공급.', 'PRODECAL, Cartago (since 1974, 11-50 staff) - ground calcium carbonate, high purity, brightness and fine size, for construction, paint, soap and detergent.', 'CR check 2026-10-15: paper supply not confirmed - ask d50 / d90, wet grinding, slurry. +506 8379-5539, info@prodecalcr.com.'),
  ('cales cr|\mccc\M.*costa', 'CCC / Cales CR', null, null, null, '미분화 탄산칼슘·생석회·소석회 업체. 플라스틱·도료·제지 충전제 명시.', 'CCC / Cales CR - micronised calcium carbonate, quicklime and hydrated lime, carbonate named as a filler for plastics, paint and paper.', 'CR check 2026-10-15: plant location, capacity and mill customers not public.'),
  ('carbotico', 'Carbotico', 'Guanacaste', 'Abangares', null, 'Guanacaste Abangares(Santa Lucía, Colorado) 석회석 가공·탄산칼슘 공급 업체. 굵은 입도·골재·Marmolina.', 'Carbotico, Santa Lucía, Colorado, Abangares, Guanacaste - limestone processing, calcium carbonate in several sizes, aggregates and Marmolina.', 'CR check 2026-10-15: fine paper GCC not confirmed - raw-material source. ventas@carbotico.com. Also supplies Nicaragua.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%CR check 2026-10-15%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('grupo sur', 'Grupo Sur Química - El Níspero', 'Guanacaste', 'El Níspero', null, 'Grupo Sur Química 의 Guanacaste El Níspero 탄산칼슘 공장(2007 가동). 석회석 파쇄·분쇄·입도 조절, Carbonato de Calcio Industrial 325 (CaCO3 약 97.87%).', 'Grupo Sur Química - calcium carbonate plant at El Níspero, Guanacaste (since 2007): limestone crushing, grinding, sizing and QC, Carbonato de Calcio Industrial 325 (about 97.87 pct CaCO3), markets paint, coatings, detergents, mortar, agriculture.', 'CR check 2026-10-15: paper grade and slurry line not confirmed. +506 2211-3700, informacion@gruposur.com. FCC co-production candidate 1.'),
  ('prodecal', 'PRODECAL', 'Cartago', 'Cartago', null, 'Cartago 의 GCC 전문 제조사(1974년). 고순도·고백색·미세 입도 강조, 건설·페인트·비누·세제 공급.', 'PRODECAL, Cartago (since 1974, 11-50 staff) - ground calcium carbonate, high purity, brightness and fine size, for construction, paint, soap and detergent.', 'CR check 2026-10-15: paper supply not confirmed - ask d50 / d90, wet grinding, slurry. +506 8379-5539, info@prodecalcr.com.'),
  ('cales cr|\mccc\M.*costa', 'CCC / Cales CR', null, null, null, '미분화 탄산칼슘·생석회·소석회 업체. 플라스틱·도료·제지 충전제 명시.', 'CCC / Cales CR - micronised calcium carbonate, quicklime and hydrated lime, carbonate named as a filler for plastics, paint and paper.', 'CR check 2026-10-15: plant location, capacity and mill customers not public.'),
  ('carbotico', 'Carbotico', 'Guanacaste', 'Abangares', null, 'Guanacaste Abangares(Santa Lucía, Colorado) 석회석 가공·탄산칼슘 공급 업체. 굵은 입도·골재·Marmolina.', 'Carbotico, Santa Lucía, Colorado, Abangares, Guanacaste - limestone processing, calcium carbonate in several sizes, aggregates and Marmolina.', 'CR check 2026-10-15: fine paper GCC not confirmed - raw-material source. ventas@carbotico.com. Also supplies Nicaragua.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'costarica_update_20261015';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Grupo Sur Química - El Níspero', 'GCC producer', 'Local GCC plant - FCC co-production candidate 1', 'merchant', 'C', 'gcc'),
  ('PRODECAL', 'GCC producer', 'Fine GCC specialist - FCC partner candidate 2', 'merchant', 'C', 'gcc'),
  ('CCC / Cales CR', 'GCC and lime producer', 'Micronised carbonate, paper named', 'merchant', 'C', 'gcc'),
  ('Carbotico', 'Carbonate raw material', 'Raw-material source only', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'costarica_update_20261015'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'CR', 'Costa Rica', 'low',
   $cm$Local GCC grinders (Grupo Sur, PRODECAL, CCC) - no paper PCC, mill research pending$cm$,
   $cm$No paper PCC plant and no Omya or SMI site. Local GCC: Grupo Sur Química (El Níspero, 325 grade, about 97.9 pct CaCO3), PRODECAL (Cartago), CCC / Cales CR (paper named), Carbotico (raw material). Distributors Brenntag, Pochteca and Sun Products not added. Paper-mill report still to come.$cm$,
   $cm${"fillers": "GCC: Grupo Sur Química (El Níspero, Guanacaste, since 2007), PRODECAL (Cartago, since 1974), CCC / Cales CR (micronised, paper named), Carbotico (Abangares, raw material). Not added: Sun Products Internacional (supplier, own plant unconfirmed), Pochteca and Brenntag (distributors). No PCC plant, no Omya or SMI site.", "mills": "Paper-mill report not yet entered.", "strategy": "Local GCC partner (Grupo Sur first) as a licensed FCC producer for Costa Rica and Nicaragua - confirm paper grades and slurry.", "risks": "Local GCC serves paint and construction - paper specs unproven.", "next_steps": ["Enter the Costa Rica paper-mill report", "Ask Grupo Sur and PRODECAL for d50, brightness and slurry capability"], "files": ["seed_20261015w_costarica_fillers"]}$cm$::jsonb,
   $cm$현지 GCC 분쇄업체(Grupo Sur·PRODECAL·CCC) — 제지용 PCC 없음, 제지사 조사 대기$cm$,
   $cm$제지용 PCC 공장·Omya·SMI 거점 없음. 현지 GCC 는 Grupo Sur Química(El Níspero), PRODECAL(Cartago), CCC(제지 명시), Carbotico(원료). 유통사(Brenntag·Pochteca·Sun Products) 제외. 제지기업 보고서 입력 대기.$cm$,
   null, null,
   $cm$제지사 미입력 — 산정 보류$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
select 'filler' as kind, p.party_name as name,
       case when p.source = 'costarica_update_20261015' then 'added now' else 'already there' end as status, coalesce(p.country_code, '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'grupo sur' or p.party_name ~* 'prodecal' or p.party_name ~* 'cales cr|\mccc\M.*costa' or p.party_name ~* 'carbotico')
union all
select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
       coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
from app.country_markets cm
where cm.country_code = 'CR'
union all
select 'existing mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'), '-', p.id::text
from app.parties p
where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'CR'
order by 1, 2;
