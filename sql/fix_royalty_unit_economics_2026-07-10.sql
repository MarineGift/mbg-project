-- ============================================================
-- fix_royalty_unit_economics_2026-07-10.sql
-- CRITICAL consistency fix. The IR deck (correct) defines the
-- royalty as 3-5 pct of the FCC price of 250-350 USD per ton,
-- so roughly 10 USD per ton - Year-3 royalty 22.4M USD on
-- 2.24M tons checks out exactly. But answer_library texts
-- (round v2 backfill + refined GCC story) said the royalty
-- itself is 350 USD per ton, and labeled 10.5-16.8B USD/yr as
-- a royalty pool. 350 USD is the PRICE (and the mill saving),
-- not the royalty. 10.5-16.8B USD/yr = 30-48M tons x 350 USD
-- price = the FCC VALUE pool. The royalty pool at 3-5 pct is
-- 0.3-0.8B USD per year. An analyst multiplying the deck and
-- the library texts together would break the story in minutes.
--
-- Touches: valuation_rationale, royalty_economics (explicit
-- overwrite), plus a relabel sweep of any other row using the
-- royalty-pool wording. Resyncs bound CEV + Anzu answers.
--
-- Supabase SQL Editor safe: no do-blocks, no temp tables,
-- no semicolons or SQL keywords inside string literals.
-- ============================================================

-- ------------------------------------------------------------
-- 1. valuation_rationale: royalty accrues at 3-5 pct of the
--    350 USD price - not at 350 USD per ton
-- ------------------------------------------------------------
update app.answer_library
set body_en    = '27M USD pre-money rests on two legs. First, about 1.2x our validated Year 3 royalty projection of 22.4M USD - conservative against the 5-15x multiples typical of royalty deals - anchored by a confirmed 9,000-ton order at 350 USD per ton with a 3-5 pct royalty accruing automatically, plus roughly 10,000 more tons in progress. Second, a patent-backed expansion option: our new GCC production route (regular filing 2023-07-12, national phase across 7 countries) grows the accessible market roughly 5-10x versus PCC-only (GCC 51.1B USD vs PCC 5.4B USD by 2030, Grand View Research).',
    body_ko    = '프리머니 2,700만 달러는 두 축에 기반합니다. 첫째, 검증된 트랙 기준 3년차 예상 로열티 2,240만 달러의 약 1.2배로, 로열티 사업의 통상 5~15배 거래 대비 보수적입니다. 톤당 350달러 가격에 3~5퍼센트 로열티가 자동 발생하는 9,000톤 오더가 확정되어 있고 약 10,000톤이 추가 진행 중입니다. 둘째, 특허 기반 확장 옵션으로 신규 GCC 생산 공정(2023년 7월 12일 정규 출원, 7개국 개별국 진입)을 통해 접근 시장이 PCC 단독 대비 약 5~10배 확대됩니다(2030년 GCC 511억 달러, PCC 54억 달러 - Grand View Research 기준).',
    updated_at = now()
where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and answer_key = 'valuation_rationale';

-- ------------------------------------------------------------
-- 2. royalty_economics: correct unit chain
--    price 250-350 -> royalty 3-5 pct (~10/ton) -> value pool
--    10.5-16.8B -> royalty pool 0.3-0.8B -> gross margin 80+
-- ------------------------------------------------------------
update app.answer_library
set body_en    = 'Our royalty is 3-5 pct of the mill-validated FCC price of 250-350 USD per ton - roughly 10 USD per ton, accruing automatically on licensed production. The validated track reaches 22.4M USD in annual royalty by Year 3 on 2.24M tons. Paper consumes 30-48M tons of CaCO3 filler per year, an FCC value pool of 10.5-16.8B USD per year at current pricing, implying a royalty pool of 0.3-0.8B USD per year at full penetration. Royalties carry minimal delivery cost, so gross margin on royalty revenue exceeds 80 percent.',
    body_ko    = '당사 로열티는 제지사 검증 FCC 가격 톤당 250~350달러의 3~5퍼센트, 즉 톤당 약 10달러로 라이선스 생산량에 자동 발생합니다. 검증 트랙 기준 3년차 224만 톤에서 연 2,240만 달러 로열티에 도달합니다. 제지 산업은 연 3,000만~4,800만 톤의 탄산칼슘 필러를 소비하며, 현재 가격 기준 연 105억~168억 달러의 FCC 가치 풀에 해당하고, 완전 침투 시 연 3억~8억 달러의 로열티 풀을 의미합니다. 로열티는 이행 비용이 거의 들지 않아 매출총이익률이 80퍼센트를 상회합니다.',
    updated_at = now()
where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and answer_key = 'royalty_economics'
  and variant = 'medium';

-- ------------------------------------------------------------
-- 3. Relabel sweep: any other row calling the 10.5-16.8B pool
--    a royalty pool gets relabeled as the FCC value pool
--    (market_context and friends - exact bodies unknown here)
-- ------------------------------------------------------------
update app.answer_library
set body_en    = replace(replace(body_en, 'royalty pool', 'FCC value pool'), 'Royalty Pool', 'FCC Value Pool'),
    updated_at = now()
where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and answer_key not in ('royalty_economics')
  and (body_en ilike '%royalty pool%');

update app.answer_library
set body_ko    = replace(body_ko, '로열티 풀', 'FCC 가치 풀'),
    updated_at = now()
where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and answer_key not in ('royalty_economics')
  and (body_ko like '%로열티 풀%');

-- ------------------------------------------------------------
-- 4. Resync bound answers on CEV + Anzu for touched keys
-- ------------------------------------------------------------
update app.application_field_answers fa
set final_text = al.body_en,
    updated_at = now()
from app.application_form_fields ff,
     app.application_forms f,
     app.parties pt,
     app.answer_library al
where ff.id = fa.field_id
  and f.id  = ff.form_id
  and pt.id = f.party_id
  and al.id = fa.answer_id
  and f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and (pt.party_name ilike '%clean energy ventures%' or pt.party_name ilike '%anzu%')
  and al.answer_key in
      ('valuation_rationale','royalty_economics','market_context','gcc_expansion')
  and al.body_en is not null
  and fa.final_text is distinct from al.body_en;

-- ------------------------------------------------------------
-- VERIFY 1: no row may still claim a 350 USD per ton ROYALTY
-- (expect 0 rows)
-- ------------------------------------------------------------
select answer_key, variant, left(body_en, 70) as en_head
from app.answer_library
where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and (body_en ilike '%royalty at 350%' or body_en ilike '%royalty of 350%'
       or body_en ilike '%accrues royalty at 350%' or body_en ilike '%accruing royalty at 350%'
       or body_ko like '%톤당 350달러 로열티%')
order by answer_key;

-- ------------------------------------------------------------
-- VERIFY 2: remaining royalty-pool mentions (only
-- royalty_economics with the corrected 0.3-0.8B figure)
-- ------------------------------------------------------------
select answer_key, variant, left(body_en, 90) as en_head
from app.answer_library
where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and (body_en ilike '%royalty pool%' or body_ko like '%로열티 풀%')
order by answer_key;

-- ------------------------------------------------------------
-- VERIFY 3: touched keys read back
-- ------------------------------------------------------------
select answer_key, variant, left(body_en, 70) as en_head, updated_at
from app.answer_library
where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and answer_key in ('valuation_rationale','royalty_economics','market_context')
order by answer_key, variant;
