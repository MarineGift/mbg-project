-- ============================================================
-- backfill_answer_library_body_ko_series_a_2026-07-10.sql
-- Round keys body_ko: SAFE era -> 5M USD Series A at 30M pre
-- Target: 1955 Capital (Korea bridge) and future KR investor forms
--
-- Scope: 9 round keys + burn_rate + runway_months + deck_url
-- Written rule kept: partner stays anonymous in all written
-- answers, competitor names only where already public
--
-- Supabase SQL Editor safe:
--   * single UPDATE with inline VALUES, no do-blocks
--   * no semicolons inside string literals
--   * variant medium only - VERIFY 2 exposes any other variants
--     of these keys that would still be stale
-- ============================================================

update app.answer_library al
set body_ko    = v.body_ko,
    updated_at = now()
from (values
  ('capital_seeking',
   '당사는 500만 달러 규모의 Series A 라운드를 진행하고 있습니다. 프리머니 밸류에이션 3,000만 달러(포스트머니 3,500만 달러) 기준의 프라이스드 에쿼티 라운드입니다.'),

  ('deal_terms',
   'Series A 프라이스드 에쿼티 라운드, 총 500만 달러, 프리머니 3,000만 달러 / 포스트머니 3,500만 달러. SAFE나 컨버터블 노트가 아닌 신주 발행 방식이며, 기존 발행 전환증권은 없습니다.'),

  ('use_of_funds',
   '조달 자금 500만 달러의 사용 계획은 다음과 같습니다 - 생산 스케일업 200만 달러, 미국 시장 검증(파일럿 및 인증) 150만 달러, IP 강화 및 운영 150만 달러.'),

  ('valuation_rationale',
   '프리머니 3,000만 달러는 검증된 트랙 기준 3년차 예상 로열티 매출 2,240만 달러의 약 1.3배 수준입니다. 로열티 기반 사업이 통상 로열티 매출의 5~15배에 거래되는 점을 감안하면 보수적인 밸류에이션입니다. 현재 톤당 350달러 로열티가 자동 발생하는 9,000톤 오더가 실행 중이며 약 10,000톤이 추가 진행 중입니다.'),

  ('already_raised',
   '외부 투자 유치 이력은 없으며 부트스트랩으로 운영해 왔습니다. 자본 구조는 보통주만으로 구성되어 있고 SAFE, 컨버터블 노트 등 전환증권은 존재하지 않습니다. 창업자 지분은 Heo 51%, Seo 34%입니다.'),

  ('discount_rate',
   '해당 없음 - 본 라운드는 프라이스드 Series A로, SAFE 디스카운트나 밸류에이션 캡 개념이 적용되지 않습니다.'),

  ('company_one_liner',
   '해양 바이오소재 기반 기능성 탄산칼슘(FCC)으로 제지 산업의 펄프 일부를 대체해 원가 절감과 탄소 저감을 동시에 구현하는 소재 라이선싱 기업입니다. 세계 최상위 필러 제조사와의 파트너십 하에 톤당 로열티 모델로 확장합니다.'),

  ('ask_use_of_funds',
   '500만 달러 Series A를 요청합니다(프리머니 3,000만 달러). 자금 사용처는 생산 스케일업 200만 달러, 미국 시장 검증 150만 달러, IP 및 운영 150만 달러이며, 목표는 현재 실행 중인 로열티 트랙을 미국 시장으로 확장하는 것입니다.'),

  ('cost_structure',
   '자산 경량(asset-light) 로열티 모델로 고정비가 매우 낮습니다. 현재 월 소진액은 약 5,000달러이며, 생산 설비와 대규모 CAPEX는 파트너 측이 부담하는 구조입니다.'),

  ('burn_rate',
   '월 약 5,000달러(자산 경량 구조). 생산 및 설비 투자가 파트너 측에 있어 소진율이 매우 낮게 유지됩니다.'),

  ('runway_months',
   '약 10개월(보유 현금 5만 달러, 월 소진 5,000달러 기준). 실행 중인 오더의 로열티 유입이 시작되면 런웨이는 추가로 연장됩니다.'),

  ('deck_url',
   'IR 덱(V3.0, Series A): https://drive.google.com/file/d/1alGPNW-LafjgszrRkj0ATkQ86bFy7GNN/view?usp=drive_link')
) as v(answer_key, body_ko)
where al.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and al.answer_key = v.answer_key
  and al.variant = 'medium';


-- ------------------------------------------------------------
-- VERIFY 1: 12 keys updated today with ko lengths
-- ------------------------------------------------------------
select answer_key, variant, length(body_ko) as ko_chars,
       left(body_ko, 30) as ko_head, updated_at
from app.answer_library
where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and answer_key in
      ('capital_seeking','deal_terms','use_of_funds','valuation_rationale',
       'already_raised','discount_rate','company_one_liner','ask_use_of_funds',
       'cost_structure','burn_rate','runway_months','deck_url')
  and variant = 'medium'
order by answer_key;


-- ------------------------------------------------------------
-- VERIFY 2: other variants of the same keys, if any exist they
-- were NOT touched above and may still carry SAFE era Korean
-- ------------------------------------------------------------
select answer_key, variant, length(body_ko) as ko_chars, updated_at
from app.answer_library
where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and answer_key in
      ('capital_seeking','deal_terms','use_of_funds','valuation_rationale',
       'already_raised','discount_rate','company_one_liner','ask_use_of_funds',
       'cost_structure','burn_rate','runway_months','deck_url')
  and variant <> 'medium'
order by answer_key, variant;


-- ------------------------------------------------------------
-- VERIFY 3: stale check - round keys whose Korean still mentions
-- the old 10만 달러 SAFE ask or the 1,000만 달러 cap (expect 0 rows,
-- discount_rate legitimately mentions the word SAFE so it is
-- checked only on amounts)
-- ------------------------------------------------------------
select answer_key, variant
from app.answer_library
where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and answer_key in
      ('capital_seeking','deal_terms','use_of_funds','valuation_rationale',
       'already_raised','discount_rate','company_one_liner','ask_use_of_funds',
       'cost_structure')
  and (body_ko like '%10만 달러%' or body_ko like '%1,000만 달러%'
       or body_ko like '%100,000%' or body_ko like '%10,000,000%');
