-- ============================================================
-- fix_answer_library_short_variants_ko_2026-07-10.sql
-- VERIFY 3 (2026-07-10) flagged 3 stale short variants whose
-- body_ko still carries the old SAFE amounts:
--   capital_seeking / deal_terms / use_of_funds (variant short)
-- This rewrites them to Series A terms in condensed form.
--
-- Supabase SQL Editor safe:
--   * single UPDATE with inline VALUES, no do-blocks
--   * no semicolons inside string literals
-- ============================================================

update app.answer_library al
set body_ko    = v.body_ko,
    updated_at = now()
from (values
  ('capital_seeking',
   '500만 달러 규모의 Series A 라운드를 진행 중입니다(프리머니 3,000만 달러, 포스트머니 3,500만 달러).'),

  ('deal_terms',
   'Series A 프라이스드 에쿼티 - 총 500만 달러, 프리머니 3,000만 달러 / 포스트머니 3,500만 달러, 기존 전환증권 없음.'),

  ('use_of_funds',
   '생산 스케일업 200만 달러, 미국 시장 검증 150만 달러, IP 및 운영 150만 달러(총 500만 달러).')
) as v(answer_key, body_ko)
where al.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and al.answer_key = v.answer_key
  and al.variant = 'short';


-- ------------------------------------------------------------
-- VERIFY A: stale amount check across ALL variants of the 12
-- round keys (expect 0 rows now)
-- ------------------------------------------------------------
select answer_key, variant
from app.answer_library
where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and answer_key in
      ('capital_seeking','deal_terms','use_of_funds','valuation_rationale',
       'already_raised','discount_rate','company_one_liner','ask_use_of_funds',
       'cost_structure','burn_rate','runway_months','deck_url')
  and (body_ko like '%10만 달러%' or body_ko like '%1,000만 달러%'
       or body_ko like '%100,000%' or body_ko like '%10,000,000%');


-- ------------------------------------------------------------
-- VERIFY B: eyeball every non-medium variant of the 12 keys -
-- confirms nothing else off-message survives (heads shown)
-- ------------------------------------------------------------
select answer_key, variant, length(body_ko) as ko_chars,
       left(body_ko, 40) as ko_head, updated_at
from app.answer_library
where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and answer_key in
      ('capital_seeking','deal_terms','use_of_funds','valuation_rationale',
       'already_raised','discount_rate','company_one_liner','ask_use_of_funds',
       'cost_structure','burn_rate','runway_months','deck_url')
  and variant <> 'medium'
order by answer_key, variant;
