-- ============================================================
-- seed_answer_library.sql
-- Reusable answers for investor / accelerator web forms.
--
-- RUN AFTER: migration_025_application_forms.sql
--
-- disclosure_level:
--   'public'   -> safe to paste into a third-party web form
--   'nda_only' -> partner names. In-person use only. The UI must
--                 refuse to copy these and show a warning.
--
-- Supabase SQL Editor safe: no semicolons, no apostrophes and no
-- standalone SQL keywords inside any string literal.
-- Idempotent: guarded by ON CONFLICT on (organization_id, answer_key).
-- ============================================================

-- ------------------------------------------------------------
-- 1. Answer library
-- ------------------------------------------------------------
INSERT INTO app.answer_library (organization_id, answer_key, title, body_en, body_ko, disclosure_level, tags)
VALUES
(
  'b25de8f2-1020-482f-9012-183f63883169'::uuid,
  'company_one_liner',
  'One-liner',
  'Marinebio Group licenses FCC, a patented calcium carbonate paper filler that replaces expensive wood pulp at lower cost and better quality. We earn a royalty on every ton produced.',
  '마린바이오그룹은 특허받은 탄산칼슘 제지용 충전제 FCC를 라이선싱한다. 값비싼 목재 펄프를 더 낮은 비용과 더 나은 품질로 대체하며, 생산된 모든 톤수에 대해 로열티를 받는다.',
  'public',
  ARRAY['pitch','core']
),
(
  'b25de8f2-1020-482f-9012-183f63883169'::uuid,
  'problem',
  'Problem',
  'Paper mills need bulk, stiffness, smoothness and strength at once. Conventional fillers cost 2 to 8 times less than pulp, but adding more of them collapses paper quality. Mills are stuck between cost and quality.',
  '제지사는 벌크, 강성, 평활도, 강도를 동시에 만족해야 한다. 기존 충전제는 펄프보다 2~8배 저렴하지만, 함량을 늘리면 종이 품질이 무너진다. 원가와 품질 사이에 갇혀 있다.',
  'public',
  ARRAY['pitch','core']
),
(
  'b25de8f2-1020-482f-9012-183f63883169'::uuid,
  'solution',
  'Solution and technology',
  'FCC grows calcium carbonate in-situ on a cellulose fibril core, creating a strong mineral-to-fiber bond instead of a loose mix. Bulk and strength rise together, so the loading ceiling disappears. The mechanism is published in two peer-reviewed ACS journals.',
  'FCC는 셀룰로오스 피브릴 코어 위에 탄산칼슘을 in-situ로 성장시켜, 단순 혼합이 아닌 강력한 광물-섬유 결합을 만든다. 벌크와 강도가 함께 상승해 충전 한계가 사라진다. 이 메커니즘은 ACS 저널 2편에 게재되었다.',
  'public',
  ARRAY['pitch','tech']
),
(
  'b25de8f2-1020-482f-9012-183f63883169'::uuid,
  'traction',
  'Traction',
  'A confirmed 9,000-ton order at 350 USD per ton now enters production with a global top-3 filler producer. Royalty accrues automatically as they supply the mill. First royalties are expected in 1 to 3 months.',
  '톤당 350달러로 확정된 9,000톤 오더가 글로벌 상위 3위 충전제 제조사를 통해 생산에 들어간다. 해당 제조사가 제지사에 공급하면 로열티가 자동 발생한다. 첫 로열티는 1~3개월 내 예상된다.',
  'public',
  ARRAY['pitch','traction']
),
(
  'b25de8f2-1020-482f-9012-183f63883169'::uuid,
  'business_model',
  'Business model',
  'We license the technology to filler manufacturers. They pay a royalty of 3 to 5 percent of sales. Paper mills pay no capex and simply purchase FCC in place of conventional filler. Target contracts run 10 to 15 years.',
  '충전제 제조사에 기술을 라이선싱하고, 그들이 매출의 3~5%를 로열티로 지급한다. 제지사는 설비 투자 없이 기존 충전제 대신 FCC를 구매하기만 하면 된다. 목표 계약 기간은 10~15년이다.',
  'public',
  ARRAY['pitch','model']
),
(
  'b25de8f2-1020-482f-9012-183f63883169'::uuid,
  'market',
  'Market size',
  'The paper filler market is about 5.7 billion USD and calcium carbonate is roughly 60 percent of it. Tissue uses no filler today because conventional minerals fail on retention and dusting, so FCC opens a brand-new market of about 2 million tons a year.',
  '제지용 충전제 시장은 약 57억 달러이며 그중 탄산칼슘이 약 60%를 차지한다. 티슈는 기존 광물의 보류율과 분진 문제로 충전제를 전혀 쓰지 못하는데, FCC는 연 200만 톤 규모의 완전히 새로운 시장을 연다.',
  'public',
  ARRAY['pitch','market']
),
(
  'b25de8f2-1020-482f-9012-183f63883169'::uuid,
  'team',
  'Team',
  'CTO Professor Seo holds a PhD and postdoc at State University of New York and has over 50 patents in marine nanofiber. CPO Mr. Lee has over 30 patents and a paper engineering background at a national pulp research center. CEO Yun-Young Heo has an engineering degree and Samsung Group experience.',
  'CTO 서융범 교수는 뉴욕주립대 박사·박사후 과정을 마쳤고 해양 나노섬유 분야 특허 50건 이상을 보유한다. CPO 이윤우는 특허 30건 이상과 국가 펄프연구센터 제지공학 경력을 갖췄다. CEO 허윤영은 공학사 학위와 삼성그룹 경력을 보유한다.',
  'public',
  ARRAY['pitch','team']
),
(
  'b25de8f2-1020-482f-9012-183f63883169'::uuid,
  'ip',
  'Intellectual property',
  'Five granted patents and seven pending applications across Korea, PCT and the United States. A competitor tried to patent FCC for tissue and the application was finally rejected, citing our own published paper as prior art.',
  '한국·PCT·미국에 걸쳐 등록특허 5건, 출원 7건을 보유한다. 한 경쟁사가 티슈용 FCC 특허를 시도했으나, 우리 논문이 선행기술로 인용되어 최종 거절되었다.',
  'public',
  ARRAY['pitch','ip']
),
(
  'b25de8f2-1020-482f-9012-183f63883169'::uuid,
  'impact',
  'Climate impact',
  'Each ton of FCC replaces about one ton of wood pulp. On the confirmed 9,000-ton volume alone that avoids roughly 3,700 to 4,600 tons of CO2 and 270,000 cubic meters of water a year. Adoption is driven by cost savings, so the impact needs no subsidy.',
  'FCC 1톤은 목재 펄프 약 1톤을 대체한다. 확정된 9,000톤 물량만으로도 연간 약 3,700~4,600톤의 CO2와 27만 세제곱미터의 물을 절감한다. 채택 동기가 원가 절감이므로 보조금이 필요 없다.',
  'public',
  ARRAY['pitch','impact','climate']
),
(
  'b25de8f2-1020-482f-9012-183f63883169'::uuid,
  'ask_use_of_funds',
  'Ask and use of funds',
  'We are raising a bridge round. The first 100K USD funds an independent tissue test at a national paper lab in the United States, producing validation data we own. On completion the lab introduces us to the major US tissue manufacturers.',
  '브릿지 라운드를 조달 중이다. 첫 10만 달러는 미국 국립 제지 연구소에서 진행하는 독립 티슈 테스트에 투입되며, 우리가 소유하는 검증 데이터를 만든다. 완료 시 해당 연구소가 미국 주요 티슈 제조사를 소개해 준다.',
  'public',
  ARRAY['pitch','ask']
),
(
  'b25de8f2-1020-482f-9012-183f63883169'::uuid,
  'why_now',
  'Why now',
  'The bottleneck was plant type, not our product. FCC drops in with no new investment at a PCC plant. Our earlier local partner ran a GCC plant and needed 30,000 tons to justify a facility expansion. A global top-3 producer now executes the order directly.',
  '병목은 우리 제품이 아니라 공장 타입이었다. FCC는 PCC 공장에서 추가 투자 없이 바로 생산된다. 기존 로컬 파트너는 GCC 공장이라 증설을 정당화할 3만 톤이 필요했다. 이제 글로벌 상위 3위 제조사가 오더를 직접 수행한다.',
  'public',
  ARRAY['pitch','traction']
),
(
  'b25de8f2-1020-482f-9012-183f63883169'::uuid,
  'competition',
  'Competition',
  'Two global giants mix minerals physically. FCC is the only strong fiber-mineral bond, and the only filler validated for tissue.',
  '두 글로벌 공룡은 광물을 물리적으로 혼합한다. FCC는 유일한 강력 섬유-광물 결합이며, 티슈에서 검증된 유일한 충전제다.',
  'public',
  ARRAY['pitch','competition']
),
(
  'b25de8f2-1020-482f-9012-183f63883169'::uuid,
  'partner_names',
  'Partner names - NDA ONLY',
  'Filler producers: Omya for the paper filler track and Specialty Minerals for the tissue track. Mill customer: Moorim Paper. US tissue lab: TPIL at NC State.',
  '충전제 제조사: 페이퍼 필러 트랙은 Omya, 티슈 트랙은 Specialty Minerals. 제지사 고객: 무림제지. 미국 티슈 연구소: NC State TPIL.',
  'nda_only',
  ARRAY['nda','partners']
)
ON CONFLICT (organization_id, answer_key) DO UPDATE
SET title            = EXCLUDED.title,
    body_en          = EXCLUDED.body_en,
    body_ko          = EXCLUDED.body_ko,
    disclosure_level = EXCLUDED.disclosure_level,
    tags             = EXCLUDED.tags,
    updated_at       = now();


-- ------------------------------------------------------------
-- 2. Example form: CTAN  (party already exists as investor)
-- ------------------------------------------------------------
INSERT INTO app.application_forms (organization_id, party_id, form_url, form_type, status, notes)
SELECT
  'b25de8f2-1020-482f-9012-183f63883169'::uuid,
  'cda9557d-6501-4583-9917-29e53f1b5c34'::uuid,
  'https://www.ctan.com/entrepreneurs/',
  'application',
  'not_started',
  'Tier 1 bridge target. Austin-local, so in-person meeting can carry the NDA-only partner names.'
WHERE NOT EXISTS (
  SELECT 1 FROM app.application_forms
  WHERE party_id = 'cda9557d-6501-4583-9917-29e53f1b5c34'::uuid
);


-- ------------------------------------------------------------
-- 3. Example form: Venture For ClimateTech  (party matched by name)
-- ------------------------------------------------------------
INSERT INTO app.application_forms (organization_id, party_id, form_url, form_type, status, notes)
SELECT
  'b25de8f2-1020-482f-9012-183f63883169'::uuid,
  p.id,
  'https://forclimatetech.org/apply/',
  'accelerator',
  'not_started',
  'Non-dilutive, up to 50K USD, zero equity. Values quantified climate impact, so lead with the impact answer.'
FROM app.parties p
WHERE p.party_name = 'Venture For ClimateTech'
  AND p.deleted_at IS NULL
  AND NOT EXISTS (
    SELECT 1 FROM app.application_forms af WHERE af.party_id = p.id
  );


-- ------------------------------------------------------------
-- 4. Example fields for the CTAN form
-- ------------------------------------------------------------
INSERT INTO app.application_form_fields (organization_id, form_id, seq, label, field_type, max_length, is_required)
SELECT
  'b25de8f2-1020-482f-9012-183f63883169'::uuid,
  af.id, v.seq, v.label, v.field_type, v.max_length, v.is_required
FROM app.application_forms af
CROSS JOIN (VALUES
  (1, 'Describe your company in one sentence', 'textarea', 300, true),
  (2, 'What problem are you solving',          'textarea', 1000, true),
  (3, 'Describe your solution',                'textarea', 1000, true),
  (4, 'Current traction',                      'textarea', 1000, true),
  (5, 'Business model',                        'textarea', 800,  true),
  (6, 'Market size',                           'textarea', 800,  true),
  (7, 'Team',                                  'textarea', 1000, true),
  (8, 'Amount raising and use of funds',       'textarea', 800,  true)
) AS v(seq, label, field_type, max_length, is_required)
WHERE af.party_id = 'cda9557d-6501-4583-9917-29e53f1b5c34'::uuid
  AND NOT EXISTS (
    SELECT 1 FROM app.application_form_fields ff WHERE ff.form_id = af.id
  );


-- ------------------------------------------------------------
-- 5. Verify
-- ------------------------------------------------------------
SELECT answer_key, title, disclosure_level, length(body_en) AS en_chars
FROM app.answer_library
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
ORDER BY disclosure_level, answer_key;
