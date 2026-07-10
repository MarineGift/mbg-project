-- ============================================================
-- fix_answer_library_short_variants_round2_2026-07-10.sql
-- VERIFY B (2026-07-10) exposed short variants the amount-based
-- stale check missed:
--   discount_rate        - old SAFE MFN clause (20 pct discount)
--   valuation_rationale  - old SAFE cap logic (1000만 without comma)
--   already_raised       - internal placeholder memo
--   cost_structure       - 289 chars of pre Series A text
--   deck_url             - body_ko was NULL
-- Since the Series A backfill touched medium only, body_en of
-- these shorts is presumed stale as well, so this statement
-- overwrites BOTH body_en and body_ko for every short-variant
-- round key (8 keys). Idempotent - safe to rerun.
--
-- Supabase SQL Editor safe:
--   * single UPDATE with inline VALUES, no do-blocks
--   * no semicolons inside string literals
-- ===============================================================

update app.answer_library al
set body_en    = v.body_en,
    body_ko    = v.body_ko,
    updated_at = now()
from (values
  ('capital_seeking',
   'We are raising a 5M USD Series A at a 30M USD pre-money valuation (35M USD post).',
   '500만 달러 규모의 Series A 라운드를 진행 중입니다(프리머니 3,000만 달러, 포스트머니 3,500만 달러).'),

  ('deal_terms',
   'Series A priced equity - 5M USD total, 30M USD pre-money / 35M USD post-money, no outstanding convertible securities.',
   'Series A 프라이스드 에쿼티 - 총 500만 달러, 프리머니 3,000만 달러 / 포스트머니 3,500만 달러, 기존 전환증권 없음.'),

  ('use_of_funds',
   '2.0M USD production scale-up, 1.5M USD US market validation, 1.5M USD IP and operations (5M USD total).',
   '생산 스케일업 200만 달러, 미국 시장 검증 150만 달러, IP 및 운영 150만 달러(총 500만 달러).'),

  ('valuation_rationale',
   '30M USD pre-money - about 1.3x our validated Year 3 royalty projection of 22.4M USD, conservative against typical 5-15x multiples on royalty deals.',
   '프리머니 3,000만 달러 - 검증된 트랙 기준 3년차 예상 로열티 2,240만 달러의 약 1.3배(로열티 사업의 통상 5~15배 거래 대비 보수적).'),

  ('already_raised',
   'No outside capital raised to date - bootstrapped, common stock only, no convertible securities outstanding.',
   '외부 조달 이력 없음 - 부트스트랩 운영, 보통주만 존재, 전환증권 없음.'),

  ('discount_rate',
   'Not applicable - this is a priced Series A round, no SAFE discount or valuation cap applies.',
   '해당 없음 - 프라이스드 Series A 라운드로 SAFE 디스카운트나 밸류에이션 캡이 적용되지 않습니다.'),

  ('cost_structure',
   'Asset-light royalty model - production facilities and capex sit with our partner, monthly burn is about 5,000 USD.',
   '자산 경량 로열티 모델 - 생산 설비와 CAPEX는 파트너 측 부담, 월 소진액 약 5,000달러.'),

  ('deck_url',
   'IR deck (V3.0, Series A): https://drive.google.com/file/d/1alGPNW-LafjgszrRkj0ATkQ86bFy7GNN/view?usp=drive_link',
   'IR 덱(V3.0, Series A): https://drive.google.com/file/d/1alGPNW-LafjgszrRkj0ATkQ86bFy7GNN/view?usp=drive_link')
) as v(answer_key, body_en, body_ko)
where al.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and al.answer_key = v.answer_key
  and al.variant = 'short';


-- ------------------------------------------------------------
-- VERIFY A: every short variant of the round keys, both
-- languages - expect 8 rows, all updated_at = today 16:xx or
-- later, en_head and ko_head all on Series A message
-- ------------------------------------------------------------
select answer_key, variant,
       left(body_en, 40) as en_head,
       left(body_ko, 40) as ko_head,
       updated_at
from app.answer_library
where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and answer_key in
      ('capital_seeking','deal_terms','use_of_funds','valuation_rationale',
       'already_raised','discount_rate','company_one_liner','ask_use_of_funds',
       'cost_structure','burn_rate','runway_months','deck_url')
  and variant = 'short'
order by answer_key;


-- ------------------------------------------------------------
-- VERIFY B: widened stale sweep over ALL variants and BOTH
-- languages - catches uncomma 1000만, SAFE cap phrasing, the
-- 20 pct MFN clause and the old 100K ask (expect 0 rows)
-- ------------------------------------------------------------
select answer_key, variant
from app.answer_library
where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and answer_key in
      ('capital_seeking','deal_terms','use_of_funds','valuation_rationale',
       'already_raised','discount_rate','company_one_liner','ask_use_of_funds',
       'cost_structure','burn_rate','runway_months','deck_url')
  and (
       body_ko like '%1000만%' or body_ko like '%1,000만%'
    or body_ko like '%10만 달러%' or body_ko like '%확정하지 않%'
    or body_ko like '%유리한 쪽%'
    or body_en like '%100,000%' or body_en like '%100K%'
    or body_en like '%10M cap%' or body_en like '%10,000,000%'
    or body_en like '%20%% discount%' or body_en like '%MFN%'
  );
