-- ============================================================
-- seed_20261016p_jamaica_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Jamaica filler report (2026-10-15). Mills were done in seed_20261015x.
-- 1) Fillers if missing (3): Lydford Mining, Hodges Aggregates and Powders,
--    Chemical Lime. Cement and dolomite firms not added.
-- 2) app.country_markets JM row refreshed with the filler findings.
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
           v.party_name, 'JM', v.region, v.city, v.website, 'active', 'jamaica_fillers_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('lydford', 'Lydford Mining - St. Ann', 'St. Ann', 'Lydford', null, '1990년대 초 설립 고순도 탄산칼슘 전문기업(Lydford·Golden Grove, St. Ann). 채굴·분쇄·분급·수출, GCC(도료)·식품·의약·FGD·사료용, 미국·카리브 수출. 2014 GCC 합작 제조사업 400만 달러 발표.', 'Lydford Mining Company Limited (early 1990s, founders Vincent Hill and Leo Cousins), Lydford / Golden Grove, St. Ann - high-purity limestone quarrying, grinding, screening and export: GCC for paint, food and pharma grades, industrial grade (flue-gas desulphurisation), feed, aggregates, sold to the US and the Caribbean. USD 4 m GCC manufacturing JV announced 2014. National whiting output rose about 245 kt in 2023 on US exports.', 'JM check 2026-10-16: paper-grade size, brightness, slurry and mill customers not public. +1 876-927-6306. FCC producer candidate 1 for the Caribbean.'),
  ('hodges aggregates', 'Hodges Aggregates & Powders - St. Elizabeth', 'St. Elizabeth', 'Hodges', null, '1965년 설립 GCC 업체(Hodges, St. Elizabeth). 400 mesh 99.5% 통과 미분, 도료용 GCC 카리브 9개국 수출.', 'Hodges Aggregates and Powders Limited (1965), Hodges, St. Elizabeth - GCC in several sizes up to 99.5 pct passing 400 mesh, for paint, plaster and feed, paint-grade GCC exported to nine Caribbean countries (2025), plus aggregates.', 'JM check 2026-10-16: not paper-filler fineness. +1 876-965-2980, mineralsinja@hotmail.com.'),
  ('chemical lime company of jamaica', 'Chemical Lime Company of Jamaica - Clarendon', 'Clarendon', 'Four Paths', null, 'Clarendon(Braziletto·Four Paths) 석회석·석회 광업권(ML129·ML152) 보유.', 'Chemical Lime Company of Jamaica Limited, Braziletto / Four Paths, Clarendon - limestone and lime mining leases (ML129, ML152).', 'JM check 2026-10-16: no GCC or PCC plant confirmed - raw material or new PCC project partner. Not added: CEMEX Jamaica and Caribbean Cement (cement), Caribbean Mining (whiting quarry, unverified), Limecore (dolomitic, 75.7 pct CaCO3, brightness 78.6).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%JM check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('lydford', 'Lydford Mining - St. Ann', 'St. Ann', 'Lydford', null, '1990년대 초 설립 고순도 탄산칼슘 전문기업(Lydford·Golden Grove, St. Ann). 채굴·분쇄·분급·수출, GCC(도료)·식품·의약·FGD·사료용, 미국·카리브 수출. 2014 GCC 합작 제조사업 400만 달러 발표.', 'Lydford Mining Company Limited (early 1990s, founders Vincent Hill and Leo Cousins), Lydford / Golden Grove, St. Ann - high-purity limestone quarrying, grinding, screening and export: GCC for paint, food and pharma grades, industrial grade (flue-gas desulphurisation), feed, aggregates, sold to the US and the Caribbean. USD 4 m GCC manufacturing JV announced 2014. National whiting output rose about 245 kt in 2023 on US exports.', 'JM check 2026-10-16: paper-grade size, brightness, slurry and mill customers not public. +1 876-927-6306. FCC producer candidate 1 for the Caribbean.'),
  ('hodges aggregates', 'Hodges Aggregates & Powders - St. Elizabeth', 'St. Elizabeth', 'Hodges', null, '1965년 설립 GCC 업체(Hodges, St. Elizabeth). 400 mesh 99.5% 통과 미분, 도료용 GCC 카리브 9개국 수출.', 'Hodges Aggregates and Powders Limited (1965), Hodges, St. Elizabeth - GCC in several sizes up to 99.5 pct passing 400 mesh, for paint, plaster and feed, paint-grade GCC exported to nine Caribbean countries (2025), plus aggregates.', 'JM check 2026-10-16: not paper-filler fineness. +1 876-965-2980, mineralsinja@hotmail.com.'),
  ('chemical lime company of jamaica', 'Chemical Lime Company of Jamaica - Clarendon', 'Clarendon', 'Four Paths', null, 'Clarendon(Braziletto·Four Paths) 석회석·석회 광업권(ML129·ML152) 보유.', 'Chemical Lime Company of Jamaica Limited, Braziletto / Four Paths, Clarendon - limestone and lime mining leases (ML129, ML152).', 'JM check 2026-10-16: no GCC or PCC plant confirmed - raw material or new PCC project partner. Not added: CEMEX Jamaica and Caribbean Cement (cement), Caribbean Mining (whiting quarry, unverified), Limecore (dolomitic, 75.7 pct CaCO3, brightness 78.6).')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'jamaica_fillers_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Lydford Mining - St. Ann', 'GCC producer', 'High-purity GCC exporter - FCC producer candidate 1', 'merchant', 'B', 'gcc'),
  ('Hodges Aggregates & Powders - St. Elizabeth', 'GCC producer', 'GCC grinder and exporter - candidate 2', 'merchant', 'C', 'gcc'),
  ('Chemical Lime Company of Jamaica - Clarendon', 'Carbonate raw material', 'Limestone and lime - raw material', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'jamaica_fillers_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'JM', 'Jamaica', 'low',
   $cm$No running paper machine found - tissue and box converters on imported base paper$cm$,
   $cm$Jamaica converts imported base paper: tissue (Sanmerna over 120,000 rolls/day, Quality Incorporations VII, Choi's, HDB) and corrugated boxes (Jamaica Packaging Industries, AMG, Sterling). The only papermaking history is West Indies Pulp and Paper at Freetown, Clarendon - current status unknown. Sanmerna plans a new plant near Kingston port (construction targeted 2028). Local GCC: Lydford Mining (high-purity, US exports) and Hodges Aggregates and Powders - a possible Caribbean FCC production base.$cm$,
   $cm${"fillers": "GCC: Lydford Mining (St. Ann, high-purity, US exports), Hodges Aggregates and Powders (St. Elizabeth, 400 mesh). Raw material: Chemical Lime (Clarendon). Not added: CEMEX Jamaica, Caribbean Cement, Caribbean Mining, Limecore (dolomitic). No PCC plant. National whiting output +245 kt in 2023.", "mills": "Papermaking history: West Indies Pulp and Paper (Freetown, Clarendon) - status unknown. Converters (context only): Sanmerna, Quality Incorporations VII, Choi's, HDB, Jiffy, Seven Industries, Jamaica Packaging Industries (ex Corrpak), AMG Packaging and Paper, Sterling Packaging.", "strategy": "No direct FCC customer unless a machine runs. Lydford as a Caribbean FCC production base supplying regional mills. Watch the Sanmerna new plant.", "risks": "No paper machine confirmed.", "next_steps": ["Confirm the Freetown machine", "Follow the Sanmerna new-plant plan", "Ask Lydford for paper-grade specs and wet grinding"], "files": ["seed_20261015x_jamaica_mills", "seed_20261016p_jamaica_fillers"]}$cm$::jsonb,
   $cm$가동 중인 초지기 미확인 — 수입 원지를 쓰는 티슈·골판지 가공업체 중심$cm$,
   $cm$자메이카는 수입 원지 가공 시장(티슈 Sanmerna 일 12만 롤+·Quality Incorporations VII·Choi's·HDB, 골판지 JPI·AMG·Sterling). 원지 제조 이력은 West Indies Pulp & Paper(Freetown, Clarendon) 뿐이고 현재 가동 미확인. Sanmerna 가 킹스턴항 인근 신공장 검토(2028 착공 목표). 현지 GCC: Lydford Mining(고순도, 미국 수출)·Hodges — 카리브 FCC 생산 거점 후보.$cm$,
   null, null,
   $cm$가동 초지기 미확인 — 산정 불가$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
select 'filler' as kind, p.party_name as name,
       case when p.source = 'jamaica_fillers_20261016' then 'added now' else 'already there' end as status, coalesce(p.country_code, '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'lydford' or p.party_name ~* 'hodges aggregates' or p.party_name ~* 'chemical lime company of jamaica')
union all
select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
       coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
from app.country_markets cm
where cm.country_code = 'JM'
union all
select 'existing mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'), '-', p.id::text
from app.parties p
where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'JM'
order by 1, 2;
