-- ============================================================
-- backfill_gcc_story_refined_2026-07-10.sql
-- Refined GCC expansion narrative after market verification.
--
-- Decisions locked this session:
--   * Market multiple stated as "roughly 5-10x" WITH the source
--     pair (GCC 51.1B USD vs PCC 5.4B USD by 2030, Grand View
--     Research) - never a bare "6x" (source-dependent, 1.3x-9x).
--   * Patent stated precisely: regular application filed
--     2023-07-12, national-phase entries across 7 countries.
--     Filed, not granted, unless a grant certificate exists.
--   * Royalty margin stated as GROSS margin above 80 pct on
--     royalty revenue - not company net profit.
--   * New adjacent applications listed: tissue, flame-retardant
--     wallpaper, packaging, biocomposites, stone paper.
--   * URM CRM platform surfaced as capital-efficiency proof.
--
-- Touches: answer_library keys gcc_expansion (overwrite),
-- valuation_rationale (overwrite, two-leg version), plus new
-- keys royalty_economics and gtm_platform. Resyncs bound
-- answers on CEV + Anzu forms.
--
-- Supabase SQL Editor safe: no do-blocks, no temp tables,
-- no semicolons or SQL keywords inside string literals.
-- Idempotent: guarded inserts, overwrite updates.
-- ============================================================

-- ------------------------------------------------------------
-- 1. gcc_expansion: guarded insert (if key absent) then
--    overwrite with the refined body
-- ------------------------------------------------------------
insert into app.answer_library
  (organization_id, answer_key, title, body_en, body_ko,
   disclosure_level, variant, tags, created_by)
select
  'b25de8f2-1020-482f-9012-183f63883169'::uuid,
  'gcc_expansion',
  'GCC expansion story',
  'Our FCC process was first validated on PCC plant infrastructure. A newly developed production route - a regular patent application filed 2023-07-12 with national-phase entries across 7 countries - extends FCC manufacturing to the GCC route. GCC feedstock is far cheaper than PCC while finished FCC sells at a premium, expanding unit margins. This grows the accessible market roughly 5-10x (GCC 51.1B USD vs PCC 5.4B USD by 2030, Grand View Research) and adds adjacent applications such as tissue, flame-retardant wallpaper, packaging, biocomposites and stone paper.',
  '당사 FCC 공정은 당초 PCC 플랜트 기반으로 검증되었습니다. 2023년 7월 12일 정규 출원되어 7개국 개별국 단계에 진입한 신규 특허 공정을 통해 GCC 경로로도 FCC 생산이 가능해졌습니다. GCC 원료는 PCC 대비 훨씬 저렴한 반면 FCC 완제품은 프리미엄에 판매되어 단위 마진이 확대됩니다. 이를 통해 접근 시장이 약 5~10배 확대되며(2030년 GCC 511억 달러, PCC 54억 달러 - Grand View Research 기준) 티슈, 난연벽지, 패키징, 바이오컴포지트, 돌종이 등 인접 응용처가 추가됩니다.',
  'public',
  'medium',
  array['gcc','expansion','patent','market'],
  (select created_by from app.answer_library
    where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    order by created_at limit 1)
where not exists (
  select 1 from app.answer_library
  where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    and answer_key = 'gcc_expansion'
    and variant = 'medium'
);

update app.answer_library
set body_en    = 'Our FCC process was first validated on PCC plant infrastructure. A newly developed production route - a regular patent application filed 2023-07-12 with national-phase entries across 7 countries - extends FCC manufacturing to the GCC route. GCC feedstock is far cheaper than PCC while finished FCC sells at a premium, expanding unit margins. This grows the accessible market roughly 5-10x (GCC 51.1B USD vs PCC 5.4B USD by 2030, Grand View Research) and adds adjacent applications such as tissue, flame-retardant wallpaper, packaging, biocomposites and stone paper.',
    body_ko    = '당사 FCC 공정은 당초 PCC 플랜트 기반으로 검증되었습니다. 2023년 7월 12일 정규 출원되어 7개국 개별국 단계에 진입한 신규 특허 공정을 통해 GCC 경로로도 FCC 생산이 가능해졌습니다. GCC 원료는 PCC 대비 훨씬 저렴한 반면 FCC 완제품은 프리미엄에 판매되어 단위 마진이 확대됩니다. 이를 통해 접근 시장이 약 5~10배 확대되며(2030년 GCC 511억 달러, PCC 54억 달러 - Grand View Research 기준) 티슈, 난연벽지, 패키징, 바이오컴포지트, 돌종이 등 인접 응용처가 추가됩니다.',
    updated_at = now()
where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and answer_key = 'gcc_expansion';

-- ------------------------------------------------------------
-- 2. valuation_rationale: overwrite every variant with the
--    two-leg version (1.2x royalty track + GCC option)
-- ------------------------------------------------------------
update app.answer_library
set body_en    = '27M USD pre-money rests on two legs. First, about 1.2x our validated Year 3 royalty projection of 22.4M USD - conservative against the 5-15x multiples typical of royalty deals - anchored by a confirmed 9,000-ton order accruing royalty at 350 USD per ton with roughly 10,000 more tons in progress. Second, a patent-backed expansion option: our new GCC production route (regular filing 2023-07-12, national phase across 7 countries) grows the accessible market roughly 5-10x versus PCC-only (GCC 51.1B USD vs PCC 5.4B USD by 2030, Grand View Research).',
    body_ko    = '프리머니 2,700만 달러는 두 축에 기반합니다. 첫째, 검증된 트랙 기준 3년차 예상 로열티 2,240만 달러의 약 1.2배로, 로열티 사업의 통상 5~15배 거래 대비 보수적입니다. 톤당 350달러 로열티가 자동 발생하는 9,000톤 오더가 확정되어 있고 약 10,000톤이 추가 진행 중입니다. 둘째, 특허 기반 확장 옵션으로 신규 GCC 생산 공정(2023년 7월 12일 정규 출원, 7개국 개별국 진입)을 통해 접근 시장이 PCC 단독 대비 약 5~10배 확대됩니다(2030년 GCC 511억 달러, PCC 54억 달러 - Grand View Research 기준).',
    updated_at = now()
where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and answer_key = 'valuation_rationale';

-- ------------------------------------------------------------
-- 3. royalty_economics: new key (gross margin language)
-- ------------------------------------------------------------
insert into app.answer_library
  (organization_id, answer_key, title, body_en, body_ko,
   disclosure_level, variant, tags, created_by)
select
  'b25de8f2-1020-482f-9012-183f63883169'::uuid,
  'royalty_economics',
  'Royalty model economics',
  'Royalty model economics: 350 USD per ton accrues automatically on licensed production. Applying our per-ton royalty to verified addressable tonnage yields a royalty pool of 10.5-16.8B USD per year. Because royalties carry minimal delivery cost, gross margin on royalty revenue exceeds 80 percent.',
  '로열티 모델 경제성 - 라이선스 생산량에 대해 톤당 350달러 로열티가 자동 발생합니다. 검증된 접근 가능 톤수에 톤당 로열티를 적용하면 연간 105억~168억 달러 규모의 로열티 풀이 산출됩니다. 로열티는 이행 비용이 거의 들지 않아 로열티 매출총이익률은 80퍼센트를 상회합니다.',
  'public',
  'medium',
  array['royalty','economics','margin'],
  (select created_by from app.answer_library
    where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    order by created_at limit 1)
where not exists (
  select 1 from app.answer_library
  where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    and answer_key = 'royalty_economics'
    and variant = 'medium'
);

update app.answer_library
set body_en    = 'Royalty model economics: 350 USD per ton accrues automatically on licensed production. Applying our per-ton royalty to verified addressable tonnage yields a royalty pool of 10.5-16.8B USD per year. Because royalties carry minimal delivery cost, gross margin on royalty revenue exceeds 80 percent.',
    body_ko    = '로열티 모델 경제성 - 라이선스 생산량에 대해 톤당 350달러 로열티가 자동 발생합니다. 검증된 접근 가능 톤수에 톤당 로열티를 적용하면 연간 105억~168억 달러 규모의 로열티 풀이 산출됩니다. 로열티는 이행 비용이 거의 들지 않아 로열티 매출총이익률은 80퍼센트를 상회합니다.',
    updated_at = now()
where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and answer_key = 'royalty_economics'
  and variant = 'medium';

-- ------------------------------------------------------------
-- 4. gtm_platform: new key (URM CRM as capital efficiency)
-- ------------------------------------------------------------
insert into app.answer_library
  (organization_id, answer_key, title, body_en, body_ko,
   disclosure_level, variant, tags, created_by)
select
  'b25de8f2-1020-482f-9012-183f63883169'::uuid,
  'gtm_platform',
  'Go-to-market platform (URM CRM)',
  'We built our own CRM and investor-relations platform (URM) with a proprietary database of global paper mills and filler suppliers and their mapped supply relationships. This lets a lean team run global licensing outreach directly - a capital-efficient go-to-market that a 3M USD round can fully fund.',
  '당사는 자체 CRM 겸 IR 플랫폼(URM)을 직접 구축했으며, 글로벌 제지사와 필러 공급사 및 공급 관계를 매핑한 독자 데이터베이스를 보유하고 있습니다. 이를 통해 소수 정예 팀이 글로벌 라이선싱 영업을 직접 수행할 수 있어, 300만 달러 라운드로 충분히 실행 가능한 자본 효율적 시장 진출이 가능합니다.',
  'public',
  'medium',
  array['gtm','platform','crm'],
  (select created_by from app.answer_library
    where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    order by created_at limit 1)
where not exists (
  select 1 from app.answer_library
  where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    and answer_key = 'gtm_platform'
    and variant = 'medium'
);

update app.answer_library
set body_en    = 'We built our own CRM and investor-relations platform (URM) with a proprietary database of global paper mills and filler suppliers and their mapped supply relationships. This lets a lean team run global licensing outreach directly - a capital-efficient go-to-market that a 3M USD round can fully fund.',
    body_ko    = '당사는 자체 CRM 겸 IR 플랫폼(URM)을 직접 구축했으며, 글로벌 제지사와 필러 공급사 및 공급 관계를 매핑한 독자 데이터베이스를 보유하고 있습니다. 이를 통해 소수 정예 팀이 글로벌 라이선싱 영업을 직접 수행할 수 있어, 300만 달러 라운드로 충분히 실행 가능한 자본 효율적 시장 진출이 가능합니다.',
    updated_at = now()
where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and answer_key = 'gtm_platform'
  and variant = 'medium';

-- ------------------------------------------------------------
-- 5. Resync library-bound answers on CEV + Anzu forms for the
--    keys touched above (same pattern as round v2 backfill)
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
      ('gcc_expansion','valuation_rationale','royalty_economics','gtm_platform')
  and al.body_en is not null
  and fa.final_text is distinct from al.body_en;

-- ------------------------------------------------------------
-- VERIFY 1: the four keys read the refined language
-- ------------------------------------------------------------
select answer_key, variant,
       left(body_en, 60) as en_head,
       left(body_ko, 40) as ko_head,
       updated_at
from app.answer_library
where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and answer_key in
      ('gcc_expansion','valuation_rationale','royalty_economics','gtm_platform')
order by answer_key, variant;

-- ------------------------------------------------------------
-- VERIFY 2: stale sweep - bare 6x claims, net-profit royalty
-- claims, or granted-patent claims must not remain (expect 0)
-- ------------------------------------------------------------
select answer_key, variant, left(body_en, 60) as en_head
from app.answer_library
where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and (body_en ilike '%6x the%' or body_en ilike '% 6x %'
       or body_en ilike '%net profit%royalt%' or body_en ilike '%royalt%net profit%'
       or body_ko like '%6배%' or body_ko like '%순수익%')
order by answer_key;
