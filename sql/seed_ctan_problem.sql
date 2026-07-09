-- ============================================================
-- seed_ctan_problem.sql
-- CTAN application on Dealum, step 3 of 9: Problem
-- One required textarea: summarize the problem in 2-3 sentences
--
-- Does three things, each rerun-safe:
--   1. field seq 301 (NOT EXISTS on form_id + label)
--   2. answer_library key problem, variant short (UPDATE then INSERT)
--   3. binds the answer to the field with final_text
--
-- Supabase SQL Editor safe: self-contained statements,
-- no apostrophes or semicolons inside string literals,
-- no standalone SQL keywords inside string literals.
-- ============================================================


-- 1. Field
INSERT INTO app.application_form_fields
  (organization_id, form_id, seq, label, field_type, max_length,
   is_required, help_text, canonical_key, input_kind, selector_type)
SELECT
  f.organization_id, f.id, 301,
  'Summarize the problem you are solving in 2-3 sentences',
  'textarea', NULL, true,
  'Describe the customer problem you are trying to solve with your product or service',
  'problem', 'fill', 'css'
FROM app.application_forms f
WHERE f.form_url LIKE '%dealum.com%'
  AND NOT EXISTS (
    SELECT 1 FROM app.application_form_fields x
    WHERE x.form_id = f.id
      AND x.label = 'Summarize the problem you are solving in 2-3 sentences'
  );


-- 2a. Answer library: update if the short variant already exists
UPDATE app.answer_library
SET body_en = 'Paper mills face a hard trade-off. Mineral fillers cost 2-8x less than wood pulp (100-300 USD per ton vs 600-800), but adding more filler breaks the paper - conventional GCC and PCC particles block fiber-to-fiber bonding, so strength, bulk and stiffness collapse. This caps filler loading at roughly 25-35 percent, keeps mills dependent on expensive, forest-intensive pulp, and leaves high-value categories like tissue with zero filler penetration because conventional minerals dust and fail.',
    body_ko = '제지사는 어려운 트레이드오프에 직면해 있습니다. 광물 충전제는 목재 펄프보다 2-8배 저렴하지만(톤당 100-300달러 vs 600-800달러), 충전제를 늘리면 기존 GCC/PCC 입자가 섬유 간 결합을 방해해 강도, 벌크, 강성이 무너집니다. 그 결과 충전제 함량은 25-35퍼센트에 묶이고, 제지사는 비싼 펄프 의존에서 벗어나지 못하며, 티슈처럼 가치가 높은 영역은 분진 문제로 충전제 침투율이 0인 상태로 남아 있습니다.',
    target_length = 500,
    updated_at = now()
WHERE answer_key = 'problem' AND variant = 'short';

-- 2b. Insert if it did not exist
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko,
   disclosure_level, tags, variant, target_length, created_by)
SELECT
  o.organization_id, 'problem', 'Problem - 2 to 3 sentence summary',
  'Paper mills face a hard trade-off. Mineral fillers cost 2-8x less than wood pulp (100-300 USD per ton vs 600-800), but adding more filler breaks the paper - conventional GCC and PCC particles block fiber-to-fiber bonding, so strength, bulk and stiffness collapse. This caps filler loading at roughly 25-35 percent, keeps mills dependent on expensive, forest-intensive pulp, and leaves high-value categories like tissue with zero filler penetration because conventional minerals dust and fail.',
  '제지사는 어려운 트레이드오프에 직면해 있습니다. 광물 충전제는 목재 펄프보다 2-8배 저렴하지만(톤당 100-300달러 vs 600-800달러), 충전제를 늘리면 기존 GCC/PCC 입자가 섬유 간 결합을 방해해 강도, 벌크, 강성이 무너집니다. 그 결과 충전제 함량은 25-35퍼센트에 묶이고, 제지사는 비싼 펄프 의존에서 벗어나지 못하며, 티슈처럼 가치가 높은 영역은 분진 문제로 충전제 침투율이 0인 상태로 남아 있습니다.',
  'public', ARRAY['investor','pitch_core'], 'short', 500,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (
  SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id
    AND a.answer_key = 'problem' AND a.variant = 'short'
);


-- 3. Bind the answer to the field (final_text snapshot)
INSERT INTO app.application_field_answers
  (organization_id, field_id, answer_id, final_text)
SELECT
  ff.organization_id, ff.id, al.id, al.body_en
FROM app.application_form_fields ff
JOIN app.application_forms f  ON f.id = ff.form_id
JOIN app.answer_library al
  ON al.organization_id = ff.organization_id
 AND al.answer_key = 'problem' AND al.variant = 'short'
WHERE f.form_url LIKE '%dealum.com%'
  AND ff.seq = 301
  AND NOT EXISTS (
    SELECT 1 FROM app.application_field_answers x WHERE x.field_id = ff.id
  );


-- Verify
SELECT seq, label, field_state, char_count, answer_key
FROM app.v_application_field_status
WHERE form_url LIKE '%dealum.com%' AND seq = 301;
