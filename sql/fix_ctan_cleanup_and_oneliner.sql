-- ============================================================
-- fix_ctan_cleanup_and_oneliner.sql
--
-- Two jobs.
--
-- 1. Remove the 8 placeholder questions at seq 1-8. They were
--    estimates made before the real Dealum form was captured.
--    The real form has 9 steps and none of those 8 questions
--    exist on it. They distort the progress count and show up
--    as unanswered required fields forever.
--    Deleting a field cascades to its answer row, and these
--    have no answers, so nothing of value is lost.
--
-- 2. Seed and bind the company one-liner to field 104, using the
--    Dealum formula: company is developing a defined offering to
--    help a defined audience solve a problem with a secret sauce.
--
-- Rerun-safe. Supabase SQL Editor safe: self-contained statements,
-- no apostrophes or semicolons inside string literals,
-- no standalone SQL keywords inside string literals.
-- ============================================================


-- ------------------------------------------------------------
-- 1. Delete the stale placeholder questions
-- ------------------------------------------------------------
DELETE FROM app.application_form_fields ff
USING app.application_forms f
WHERE ff.form_id = f.id
  AND f.form_url LIKE '%dealum.com%'
  AND ff.seq BETWEEN 1 AND 8;


-- ------------------------------------------------------------
-- 2. One-liner answer, medium variant (the Dealum wording)
-- ------------------------------------------------------------
UPDATE app.answer_library
SET body_en = 'Marinebio Group is developing FCC, a calcium carbonate filler grown in-situ on pulp fibers, to help paper mills cut fiber costs by raising filler content without losing sheet strength, with a patented in-situ crystallization process.',
    body_ko = '마린바이오그룹은 펄프 섬유 위에 탄산칼슘을 직접 성장시키는 FCC 충전제를 개발하여, 제지사가 종이 강도 저하 없이 충전제 함량을 높여 섬유 원가를 절감할 수 있게 합니다.',
    target_length = 260,
    updated_at = now()
WHERE answer_key = 'company_one_liner' AND variant = 'short';

INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko,
   disclosure_level, tags, variant, target_length, created_by)
SELECT o.organization_id, 'company_one_liner', 'Company one-liner - Dealum formula',
  'Marinebio Group is developing FCC, a calcium carbonate filler grown in-situ on pulp fibers, to help paper mills cut fiber costs by raising filler content without losing sheet strength, with a patented in-situ crystallization process.',
  '마린바이오그룹은 펄프 섬유 위에 탄산칼슘을 직접 성장시키는 FCC 충전제를 개발하여, 제지사가 종이 강도 저하 없이 충전제 함량을 높여 섬유 원가를 절감할 수 있게 합니다.',
  'public', ARRAY['investor','pitch_core'], 'short', 260,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id
    AND a.answer_key = 'company_one_liner' AND a.variant = 'short');


-- ------------------------------------------------------------
-- 3. Bind every field whose canonical_key now has an answer
--    and is still unbound. Picks up 104.
-- ------------------------------------------------------------
INSERT INTO app.application_field_answers
  (organization_id, field_id, answer_id, final_text)
SELECT
  ff.organization_id, ff.id, al.id, al.body_en
FROM app.application_form_fields ff
JOIN app.application_forms f ON f.id = ff.form_id
JOIN app.answer_library al
  ON al.organization_id = ff.organization_id
 AND al.answer_key = ff.canonical_key AND al.variant = 'short'
WHERE f.form_url LIKE '%dealum.com%'
  AND NOT EXISTS (
    SELECT 1 FROM app.application_field_answers x WHERE x.field_id = ff.id
  );


-- ------------------------------------------------------------
-- 4. Verify: progress and what remains
-- ------------------------------------------------------------
SELECT field_state, count(*) AS fields
FROM app.v_application_field_status
WHERE form_url LIKE '%dealum.com%' AND field_id IS NOT NULL
GROUP BY field_state
ORDER BY field_state;

SELECT seq, label, field_type, is_required
FROM app.v_application_field_status
WHERE form_url LIKE '%dealum.com%' AND field_state = 'empty'
ORDER BY seq;
