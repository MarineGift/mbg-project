-- ============================================================
-- seed_ctan_market.sql
-- CTAN application on Dealum, step 5 of 9: Market
-- Four required fields: customers summary, market size (USD M),
-- unique value proposition, competitors (repeating widget).
--
-- Same rerun-safe structure: fields 501-504, answer_library
-- entries (UPDATE then INSERT per key), bindings.
--
-- Market size rationale (chat log 2026-07-09): paper-grade
-- calcium carbonate filler market approx 14-15B USD
-- (GCC pulp-and-paper share approx 11B + paper PCC approx 3B).
--
-- Supabase SQL Editor safe: self-contained statements,
-- no apostrophes or semicolons inside string literals,
-- no standalone SQL keywords inside string literals.
-- ============================================================


-- ------------------------------------------------------------
-- 1. Fields 501-504
-- ------------------------------------------------------------
INSERT INTO app.application_form_fields
  (organization_id, form_id, seq, label, field_type, max_length,
   is_required, help_text, canonical_key, input_kind, selector_type)
SELECT
  f.organization_id, f.id, v.seq, v.label, v.field_type, NULL::integer,
  true, v.help_text, v.canonical_key, 'fill', 'css'
FROM app.application_forms f
JOIN (
  VALUES
    (501, 'Summary of the customers and market in a few sentences', 'textarea',
     'Who are your customers - briefly describe customers and users',
     'market_customers'),
    (502, 'How large is your market, approximately, in millions (USD)', 'number',
     'Enter 5 for five million, 10 for ten million, etc',
     'market_size_musd'),
    (503, 'What is your unique value proposition - what is new about what you are doing', 'textarea',
     'Features or benefits that differentiate you versus competitors and existing solutions',
     'uvp'),
    (504, 'Please list your competitors', 'textarea',
     'Repeating add-new widget on the portal - one competitor per entry. If no direct competitors, list what customers use today. CAUTION: never indicate any competitor is an NDA partner',
     'competitors')
) AS v(seq, label, field_type, help_text, canonical_key)
  ON true
WHERE f.form_url LIKE '%dealum.com%'
  AND NOT EXISTS (
    SELECT 1 FROM app.application_form_fields x
    WHERE x.form_id = f.id AND x.label = v.label
  );


-- ------------------------------------------------------------
-- 2. Answers (UPDATE then INSERT per key, variant short)
-- ------------------------------------------------------------

-- 2.1 market_customers
UPDATE app.answer_library
SET body_en = 'Our direct customers are the industrial filler producers that already supply calcium carbonate to paper mills worldwide - they license FCC, produce it in their existing plants with no new capex, and pay a royalty on every ton sold. The end users are paper, board and tissue mills seeking lower production cost without quality loss. Global paper production runs at roughly 350M tons per year (84M graphic plus 267M packaging), and the 40-45M ton per year tissue segment is a brand-new opportunity because tissue has never been able to use filler.',
    body_ko = '직접 고객은 이미 전 세계 제지사에 탄산칼슘을 공급 중인 산업용 충전제 제조사입니다. 이들은 FCC를 라이선스해 기존 공장에서 신규 설비투자 없이 생산하고, 판매되는 톤마다 로열티를 지불합니다. 최종 사용자는 품질 저하 없이 생산원가를 낮추려는 제지, 판지, 티슈 공장입니다. 세계 종이 생산량은 연간 약 3.5억 톤(그래픽 8400만 + 포장 2.67억)이며, 연 4000-4500만 톤 규모의 티슈는 충전제를 전혀 쓰지 못하던 완전히 새로운 기회입니다.',
    target_length = 550, updated_at = now()
WHERE answer_key = 'market_customers' AND variant = 'short';

INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko,
   disclosure_level, tags, variant, target_length, created_by)
SELECT
  o.organization_id, 'market_customers', 'Market - customers and users summary',
  'Our direct customers are the industrial filler producers that already supply calcium carbonate to paper mills worldwide - they license FCC, produce it in their existing plants with no new capex, and pay a royalty on every ton sold. The end users are paper, board and tissue mills seeking lower production cost without quality loss. Global paper production runs at roughly 350M tons per year (84M graphic plus 267M packaging), and the 40-45M ton per year tissue segment is a brand-new opportunity because tissue has never been able to use filler.',
  '직접 고객은 이미 전 세계 제지사에 탄산칼슘을 공급 중인 산업용 충전제 제조사입니다. 이들은 FCC를 라이선스해 기존 공장에서 신규 설비투자 없이 생산하고, 판매되는 톤마다 로열티를 지불합니다. 최종 사용자는 품질 저하 없이 생산원가를 낮추려는 제지, 판지, 티슈 공장입니다. 세계 종이 생산량은 연간 약 3.5억 톤(그래픽 8400만 + 포장 2.67억)이며, 연 4000-4500만 톤 규모의 티슈는 충전제를 전혀 쓰지 못하던 완전히 새로운 기회입니다.',
  'public', ARRAY['investor','pitch_core'], 'short', 550,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (
  SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id
    AND a.answer_key = 'market_customers' AND a.variant = 'short'
);

-- 2.2 market_size_musd (plain number for the form)
UPDATE app.answer_library
SET body_en = '15000',
    body_ko = '15000 (제지용 탄산칼슘 충전제 시장 약 150억 달러 - GCC 제지 부문 약 110억 + 제지용 PCC 약 30억. 티슈 신시장 미포함이라 보수적)',
    target_length = 10, updated_at = now()
WHERE answer_key = 'market_size_musd' AND variant = 'short';

INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko,
   disclosure_level, tags, variant, target_length, created_by)
SELECT
  o.organization_id, 'market_size_musd', 'Market size in USD millions - paper filler TAM',
  '15000',
  '15000 (제지용 탄산칼슘 충전제 시장 약 150억 달러 - GCC 제지 부문 약 110억 + 제지용 PCC 약 30억. 티슈 신시장 미포함이라 보수적)',
  'public', ARRAY['investor','company_facts'], 'short', 10,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (
  SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id
    AND a.answer_key = 'market_size_musd' AND a.variant = 'short'
);

-- 2.3 uvp
UPDATE app.answer_library
SET body_en = 'FCC is the only papermaking filler with true fiber-mineral bonding - the mineral is grown in place on a cellulose core rather than mixed in, and no competitor does this. That one difference removes the industry trade-off: paper keeps strength, bulk, stiffness and smoothness at the same time, at filler loadings above 50 percent versus the conventional 25-35 percent ceiling, with 15-20 percent higher tensile strength than GCC at equal ash content (peer-reviewed ACS publications co-authored by our CTO). It is also the only filler validated in tissue, confirmed by an independent third-party mill trial. The model is asset-light - producers make FCC in their existing plants with zero new capex - and the patented structure is visible under a standard SEM image of the paper itself, making infringement fast to prove.',
    body_ko = 'FCC는 진정한 섬유-광물 결합을 가진 유일한 제지용 충전제입니다. 광물을 섞는 것이 아니라 셀룰로오스 코어 위에 직접 성장시키며, 어떤 경쟁사도 이 방식을 쓰지 않습니다. 이 하나의 차이가 업계의 트레이드오프를 제거합니다. 강도, 벌크, 강성, 평활도가 동시에 유지되고, 기존 25-35퍼센트 상한 대비 50퍼센트 이상의 충전이 가능하며, 동일 회분 기준 GCC 대비 인장강도가 15-20퍼센트 높습니다(CTO가 공저한 ACS 동료심사 논문). 독립적인 제3자 밀 트라이얼로 검증된 유일한 티슈용 충전제이기도 합니다. 생산자는 기존 공장에서 신규 설비투자 없이 FCC를 만들 수 있고, 특허받은 구조는 종이의 표준 SEM 이미지만으로 확인되어 침해 입증이 빠릅니다.',
    target_length = 800, updated_at = now()
WHERE answer_key = 'uvp' AND variant = 'short';

INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko,
   disclosure_level, tags, variant, target_length, created_by)
SELECT
  o.organization_id, 'uvp', 'Unique value proposition',
  'FCC is the only papermaking filler with true fiber-mineral bonding - the mineral is grown in place on a cellulose core rather than mixed in, and no competitor does this. That one difference removes the industry trade-off: paper keeps strength, bulk, stiffness and smoothness at the same time, at filler loadings above 50 percent versus the conventional 25-35 percent ceiling, with 15-20 percent higher tensile strength than GCC at equal ash content (peer-reviewed ACS publications co-authored by our CTO). It is also the only filler validated in tissue, confirmed by an independent third-party mill trial. The model is asset-light - producers make FCC in their existing plants with zero new capex - and the patented structure is visible under a standard SEM image of the paper itself, making infringement fast to prove.',
  'FCC는 진정한 섬유-광물 결합을 가진 유일한 제지용 충전제입니다. 광물을 섞는 것이 아니라 셀룰로오스 코어 위에 직접 성장시키며, 어떤 경쟁사도 이 방식을 쓰지 않습니다. 이 하나의 차이가 업계의 트레이드오프를 제거합니다. 강도, 벌크, 강성, 평활도가 동시에 유지되고, 기존 25-35퍼센트 상한 대비 50퍼센트 이상의 충전이 가능하며, 동일 회분 기준 GCC 대비 인장강도가 15-20퍼센트 높습니다(CTO가 공저한 ACS 동료심사 논문). 독립적인 제3자 밀 트라이얼로 검증된 유일한 티슈용 충전제이기도 합니다. 생산자는 기존 공장에서 신규 설비투자 없이 FCC를 만들 수 있고, 특허받은 구조는 종이의 표준 SEM 이미지만으로 확인되어 침해 입증이 빠릅니다.',
  'public', ARRAY['investor','pitch_core'], 'short', 800,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (
  SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id
    AND a.answer_key = 'uvp' AND a.variant = 'short'
);

-- 2.4 competitors (one per line - paste each line as one widget entry)
UPDATE app.answer_library
SET body_en = 'FiberLean Technologies (Omya and Imerys JV) - MFC-based filler, physical mixing, loading-limited
Specialty Minerals / Minerals Technologies (FulFill) - high-loading PCC, solid particle approach
Status quo: conventional GCC and PCC filler suppliers - what mills use today',
    body_ko = '경쟁사 목록 - 위젯에 한 줄씩 개별 입력. 주의: 이들이 NDA 파트너라는 사실은 절대 폼에 쓰지 말 것(경쟁사로 명명하는 것은 덱 9p에 이미 공개된 정보라 안전)',
    target_length = 300, updated_at = now()
WHERE answer_key = 'competitors' AND variant = 'short';

INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko,
   disclosure_level, tags, variant, target_length, created_by)
SELECT
  o.organization_id, 'competitors', 'Competitors - one widget entry per line',
  'FiberLean Technologies (Omya and Imerys JV) - MFC-based filler, physical mixing, loading-limited
Specialty Minerals / Minerals Technologies (FulFill) - high-loading PCC, solid particle approach
Status quo: conventional GCC and PCC filler suppliers - what mills use today',
  '경쟁사 목록 - 위젯에 한 줄씩 개별 입력. 주의: 이들이 NDA 파트너라는 사실은 절대 폼에 쓰지 말 것(경쟁사로 명명하는 것은 덱 9p에 이미 공개된 정보라 안전)',
  'public', ARRAY['investor','pitch_core'], 'short', 300,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (
  SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id
    AND a.answer_key = 'competitors' AND a.variant = 'short'
);


-- ------------------------------------------------------------
-- 3. Bindings 501-504
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
  AND ff.seq IN (501, 502, 503, 504)
  AND NOT EXISTS (
    SELECT 1 FROM app.application_field_answers x WHERE x.field_id = ff.id
  );


-- Verify
SELECT seq, label, field_state, char_count, answer_key
FROM app.v_application_field_status
WHERE form_url LIKE '%dealum.com%' AND seq BETWEEN 301 AND 599
ORDER BY seq;
