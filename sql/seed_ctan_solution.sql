-- ============================================================
-- seed_ctan_solution.sql
-- CTAN application on Dealum, step 4 of 9: Solution
-- One required textarea: describe your solution in a few sentences
--
-- Same 3-part rerun-safe structure as seed_ctan_problem.sql:
--   1. field seq 401  2. answer_library solution/short  3. binding
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
  f.organization_id, f.id, 401,
  'Describe your solution in a few sentences',
  'textarea', NULL, true,
  'Explain in simple terms for readers who know nothing about this subject. What will the company make and how does it solve the customer problem',
  'solution', 'fill', 'css'
FROM app.application_forms f
WHERE f.form_url LIKE '%dealum.com%'
  AND NOT EXISTS (
    SELECT 1 FROM app.application_form_fields x
    WHERE x.form_id = f.id
      AND x.label = 'Describe your solution in a few sentences'
  );


-- 2a. Answer library: update if the short variant already exists
UPDATE app.answer_library
SET body_en = 'Marinebio Group makes FCC (Flexible Calcium Carbonate), a papermaking filler in which the mineral is grown directly on tiny cellulose fibers instead of being mixed in as loose powder. Because the mineral is locked to fiber, paper keeps its strength even at much higher filler content - so mills can replace expensive wood pulp (600-800 USD per ton) with low-cost mineral (250-350 USD per ton) and cut production cost with no new equipment. We license the technology to the filler producers that already supply the mills and earn a royalty on every ton sold, and the same no-dusting property opens tissue - a category that has never been able to use any filler at all.',
    body_ko = '마린바이오그룹은 FCC(플렉서블 탄산칼슘)를 만듭니다. 광물 가루를 종이에 섞는 방식이 아니라, 미세한 셀룰로오스 섬유 위에 탄산칼슘을 직접 성장시킨 제지용 충전제입니다. 광물이 섬유에 결합되어 있어 충전제 함량을 크게 높여도 종이 강도가 유지되며, 제지사는 비싼 목재 펄프(톤당 600-800달러)를 저가 광물(톤당 250-350달러)로 대체해 신규 설비 없이 생산원가를 절감합니다. 우리는 제지사에 이미 납품 중인 충전제 제조사에 기술을 라이선스하고 판매되는 톤마다 로열티를 받으며, 분진이 없다는 동일한 특성 덕분에 충전제를 전혀 쓰지 못하던 티슈 시장까지 열립니다.',
    target_length = 700,
    updated_at = now()
WHERE answer_key = 'solution' AND variant = 'short';

-- 2b. Insert if it did not exist
INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko,
   disclosure_level, tags, variant, target_length, created_by)
SELECT
  o.organization_id, 'solution', 'Solution - plain-language few sentences',
  'Marinebio Group makes FCC (Flexible Calcium Carbonate), a papermaking filler in which the mineral is grown directly on tiny cellulose fibers instead of being mixed in as loose powder. Because the mineral is locked to fiber, paper keeps its strength even at much higher filler content - so mills can replace expensive wood pulp (600-800 USD per ton) with low-cost mineral (250-350 USD per ton) and cut production cost with no new equipment. We license the technology to the filler producers that already supply the mills and earn a royalty on every ton sold, and the same no-dusting property opens tissue - a category that has never been able to use any filler at all.',
  '마린바이오그룹은 FCC(플렉서블 탄산칼슘)를 만듭니다. 광물 가루를 종이에 섞는 방식이 아니라, 미세한 셀룰로오스 섬유 위에 탄산칼슘을 직접 성장시킨 제지용 충전제입니다. 광물이 섬유에 결합되어 있어 충전제 함량을 크게 높여도 종이 강도가 유지되며, 제지사는 비싼 목재 펄프(톤당 600-800달러)를 저가 광물(톤당 250-350달러)로 대체해 신규 설비 없이 생산원가를 절감합니다. 우리는 제지사에 이미 납품 중인 충전제 제조사에 기술을 라이선스하고 판매되는 톤마다 로열티를 받으며, 분진이 없다는 동일한 특성 덕분에 충전제를 전혀 쓰지 못하던 티슈 시장까지 열립니다.',
  'public', ARRAY['investor','pitch_core'], 'short', 700,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (
  SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id
    AND a.answer_key = 'solution' AND a.variant = 'short'
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
 AND al.answer_key = 'solution' AND al.variant = 'short'
WHERE f.form_url LIKE '%dealum.com%'
  AND ff.seq = 401
  AND NOT EXISTS (
    SELECT 1 FROM app.application_field_answers x WHERE x.field_id = ff.id
  );


-- Verify
SELECT seq, label, field_state, char_count, answer_key
FROM app.v_application_field_status
WHERE form_url LIKE '%dealum.com%' AND seq IN (301, 401)
ORDER BY seq;
