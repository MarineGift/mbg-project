-- ============================================================
-- seed_ctan_business_model.sql
-- CTAN application on Dealum, step 6 of 9: Business Model
-- Four required textareas: business model summary, customer
-- acquisition plan, cost structure, growth barriers.
--
-- Rerun-safe: fields 601-604, answer_library (UPDATE then
-- INSERT per key, variant short), bindings via canonical_key.
--
-- Supabase SQL Editor safe: self-contained statements,
-- no apostrophes or semicolons inside string literals,
-- no standalone SQL keywords inside string literals.
--
-- FIX 2026-07-09: the phrase designed <into> a mill in growth_barriers
-- made the editor parser treat it as INSERT INTO and split the
-- statement, raising 42P01 relation a does not exist.
-- Reworded to specified at a mill. Rerun this whole file.
-- ============================================================


-- ------------------------------------------------------------
-- 1. Fields 601-604
-- ------------------------------------------------------------
INSERT INTO app.application_form_fields
  (organization_id, form_id, seq, label, field_type, max_length,
   is_required, help_text, canonical_key, input_kind, selector_type)
SELECT
  f.organization_id, f.id, v.seq, v.label, 'textarea', NULL::integer,
  true, v.help_text, v.canonical_key, 'fill', 'css'
FROM app.application_forms f
JOIN (
  VALUES
    (601, 'Summarize the business model in a few sentences - how do you make money',
     'Summary for the short profile',
     'business_model'),
    (602, 'How do you plan to acquire more customers',
     NULL,
     'customer_acquisition'),
    (603, 'Cost structure (customer acquisition cost, distribution costs, hosting, people)',
     'Outline the proportions of the main fixed and variable costs the project incurs',
     'cost_structure'),
    (604, 'What is hindering your growth potential - what do you foresee as a barrier',
     NULL,
     'growth_barriers')
) AS v(seq, label, help_text, canonical_key)
  ON true
WHERE f.form_url LIKE '%dealum.com%'
  AND NOT EXISTS (
    SELECT 1 FROM app.application_form_fields x
    WHERE x.form_id = f.id AND x.label = v.label
  );


-- ------------------------------------------------------------
-- 2. Answers
-- ------------------------------------------------------------

-- 2.1 business_model
UPDATE app.answer_library
SET body_en = 'We are a technology licensor with a royalty model. Filler manufacturers license FCC, produce it in their existing plants, sell it to paper mills at 250-350 USD per ton, and pay us a 3-5 percent royalty - 7.5 to 17.5 USD per ton sold - secured by 10-15 year supply contracts. A confirmed 9,000-ton order is already executing at 350 USD per ton with royalties accruing automatically, and royalties are near-pure margin, so the business self-funds after launch.',
    body_ko = '우리는 로열티 모델의 기술 라이선서입니다. 충전제 제조사가 FCC를 라이선스해 기존 공장에서 생산하고, 제지사에 톤당 250-350달러에 판매하며, 판매 톤당 3-5퍼센트(7.5-17.5달러)의 로열티를 지불합니다. 10-15년 공급계약으로 확보되는 구조입니다. 이미 확정된 9,000톤 주문이 톤당 350달러로 집행 중이며 로열티가 자동으로 발생하고 있고, 로열티는 순마진에 가까워 출시 이후 사업이 자체 자금으로 돌아갑니다.',
    target_length = 500, updated_at = now()
WHERE answer_key = 'business_model' AND variant = 'short';

INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko,
   disclosure_level, tags, variant, target_length, created_by)
SELECT
  o.organization_id, 'business_model', 'Business model - royalty licensing summary',
  'We are a technology licensor with a royalty model. Filler manufacturers license FCC, produce it in their existing plants, sell it to paper mills at 250-350 USD per ton, and pay us a 3-5 percent royalty - 7.5 to 17.5 USD per ton sold - secured by 10-15 year supply contracts. A confirmed 9,000-ton order is already executing at 350 USD per ton with royalties accruing automatically, and royalties are near-pure margin, so the business self-funds after launch.',
  '우리는 로열티 모델의 기술 라이선서입니다. 충전제 제조사가 FCC를 라이선스해 기존 공장에서 생산하고, 제지사에 톤당 250-350달러에 판매하며, 판매 톤당 3-5퍼센트(7.5-17.5달러)의 로열티를 지불합니다. 10-15년 공급계약으로 확보되는 구조입니다. 이미 확정된 9,000톤 주문이 톤당 350달러로 집행 중이며 로열티가 자동으로 발생하고 있고, 로열티는 순마진에 가까워 출시 이후 사업이 자체 자금으로 돌아갑니다.',
  'public', ARRAY['investor','pitch_core'], 'short', 500,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (
  SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id
    AND a.answer_key = 'business_model' AND a.variant = 'short'
);

-- 2.2 customer_acquisition
UPDATE app.answer_library
SET body_en = 'Our acquisition is B2B and leverage-based: one licensed filler producer brings dozens of mill customers through its existing plants and sales network, so we sell to a handful of producers rather than thousands of mills. The beachhead is secured - two global filler producers are engaged under NDA and a confirmed order is in live supply through one of them. Next, a 100K USD independent validation at a US national paper laboratory converts our Korean commercial data to US data, and on completion the lab introduces us directly to major US tissue manufacturers (the Kimberly-Clark and P&G tier). In parallel we present at industry technical conferences and use the forensic SEM detectability of FCC to keep the licensing model enforceable.',
    body_ko = '고객 확보는 B2B 레버리지 방식입니다. 라이선스를 받은 충전제 제조사 한 곳이 기존 공장과 영업망을 통해 수십 개 제지사 고객을 데려오므로, 우리는 수천 개 제지사가 아니라 소수의 제조사를 상대합니다. 교두보는 이미 확보되어 있습니다. 글로벌 충전제 제조사 두 곳이 NDA 하에 협의 중이고, 그중 한 곳을 통해 확정 주문이 공급되고 있습니다. 다음 단계로 10만 달러 규모의 미국 국립 제지연구소 독립 검증이 한국 상업 데이터를 미국 데이터로 전환하며, 완료 시 연구소가 주요 미국 티슈 제조사(킴벌리클라크, P&G급)에 직접 소개합니다. 병행하여 업계 기술 컨퍼런스에서 발표하고, SEM 판독으로 침해를 입증할 수 있는 특성으로 라이선스 모델의 집행력을 유지합니다.',
    target_length = 750, updated_at = now()
WHERE answer_key = 'customer_acquisition' AND variant = 'short';

INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko,
   disclosure_level, tags, variant, target_length, created_by)
SELECT
  o.organization_id, 'customer_acquisition', 'Customer acquisition plan',
  'Our acquisition is B2B and leverage-based: one licensed filler producer brings dozens of mill customers through its existing plants and sales network, so we sell to a handful of producers rather than thousands of mills. The beachhead is secured - two global filler producers are engaged under NDA and a confirmed order is in live supply through one of them. Next, a 100K USD independent validation at a US national paper laboratory converts our Korean commercial data to US data, and on completion the lab introduces us directly to major US tissue manufacturers (the Kimberly-Clark and P&G tier). In parallel we present at industry technical conferences and use the forensic SEM detectability of FCC to keep the licensing model enforceable.',
  '고객 확보는 B2B 레버리지 방식입니다. 라이선스를 받은 충전제 제조사 한 곳이 기존 공장과 영업망을 통해 수십 개 제지사 고객을 데려오므로, 우리는 수천 개 제지사가 아니라 소수의 제조사를 상대합니다. 교두보는 이미 확보되어 있습니다. 글로벌 충전제 제조사 두 곳이 NDA 하에 협의 중이고, 그중 한 곳을 통해 확정 주문이 공급되고 있습니다. 다음 단계로 10만 달러 규모의 미국 국립 제지연구소 독립 검증이 한국 상업 데이터를 미국 데이터로 전환하며, 완료 시 연구소가 주요 미국 티슈 제조사(킴벌리클라크, P&G급)에 직접 소개합니다. 병행하여 업계 기술 컨퍼런스에서 발표하고, SEM 판독으로 침해를 입증할 수 있는 특성으로 라이선스 모델의 집행력을 유지합니다.',
  'public', ARRAY['investor','pitch_core'], 'short', 750,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (
  SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id
    AND a.answer_key = 'customer_acquisition' AND a.variant = 'short'
);

-- 2.3 cost_structure
UPDATE app.answer_library
SET body_en = 'We are asset-light: no plants, no inventory, no meaningful hosting - production and distribution run inside licensee plants at their cost. Our cost base is mostly fixed and small. Intellectual property (patent transfer, global prosecution and defense) is the largest block at roughly half of planned spend, independent testing and validation about 20 percent, and lean operations - people, legal, business development travel - about 30 percent. Customer acquisition cost is business development and technical validation rather than paid marketing, and the variable cost of an incremental royalty dollar is near zero, which is why royalties are near-pure margin.',
    body_ko = '자산 경량 구조입니다. 공장도 재고도 의미 있는 호스팅 비용도 없으며, 생산과 유통은 라이선시 공장에서 그들의 비용으로 이뤄집니다. 비용 기반은 대부분 고정비이고 규모가 작습니다. 지식재산(특허 이전, 글로벌 출원과 방어)이 계획 지출의 약 절반으로 가장 크고, 독립 테스트와 검증이 약 20퍼센트, 인력, 법무, 사업개발 출장 등 린 운영이 약 30퍼센트입니다. 고객획득비용은 유료 마케팅이 아니라 사업개발과 기술 검증이며, 로열티 매출 1달러의 추가 변동비는 0에 가깝습니다. 로열티가 순마진에 가까운 이유입니다.',
    target_length = 700, updated_at = now()
WHERE answer_key = 'cost_structure' AND variant = 'short';

INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko,
   disclosure_level, tags, variant, target_length, created_by)
SELECT
  o.organization_id, 'cost_structure', 'Cost structure - asset-light licensor',
  'We are asset-light: no plants, no inventory, no meaningful hosting - production and distribution run inside licensee plants at their cost. Our cost base is mostly fixed and small. Intellectual property (patent transfer, global prosecution and defense) is the largest block at roughly half of planned spend, independent testing and validation about 20 percent, and lean operations - people, legal, business development travel - about 30 percent. Customer acquisition cost is business development and technical validation rather than paid marketing, and the variable cost of an incremental royalty dollar is near zero, which is why royalties are near-pure margin.',
  '자산 경량 구조입니다. 공장도 재고도 의미 있는 호스팅 비용도 없으며, 생산과 유통은 라이선시 공장에서 그들의 비용으로 이뤄집니다. 비용 기반은 대부분 고정비이고 규모가 작습니다. 지식재산(특허 이전, 글로벌 출원과 방어)이 계획 지출의 약 절반으로 가장 크고, 독립 테스트와 검증이 약 20퍼센트, 인력, 법무, 사업개발 출장 등 린 운영이 약 30퍼센트입니다. 고객획득비용은 유료 마케팅이 아니라 사업개발과 기술 검증이며, 로열티 매출 1달러의 추가 변동비는 0에 가깝습니다. 로열티가 순마진에 가까운 이유입니다.',
  'public', ARRAY['investor','pitch_core'], 'short', 700,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (
  SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id
    AND a.answer_key = 'cost_structure' AND a.variant = 'short'
);

-- 2.4 growth_barriers
UPDATE app.answer_library
SET body_en = 'Three things, each with a mitigation. First, validation localization: our commercial proof is Korean mill data, and conservative US buyers want US data - the independent US national-lab test funded by this round removes exactly that barrier and ends with direct introductions to US tissue makers. Second, partner-paced rollout: the royalty model scales through large licensees, so adoption speed partly depends on their internal decisions - mitigated by long-term volume contracts and by the fact that FCC gives producers new revenue instead of cannibalizing existing lines. Third, team bandwidth: the US commercial motion is founder-led today, and this round funds the advisory and operational support to run multiple licensee and mill conversations in parallel. The paper industry moves slowly - but that same conservatism locks FCC in once it is specified at a mill.',
    body_ko = '세 가지이며 각각 완화책이 있습니다. 첫째, 검증의 현지화. 우리의 상업적 증거는 한국 제지사 데이터인데 보수적인 미국 구매자는 미국 데이터를 원합니다. 이번 라운드로 진행하는 미국 국립연구소 독립 테스트가 정확히 이 장벽을 제거하며, 완료 시 미국 티슈 제조사 직접 소개로 이어집니다. 둘째, 파트너 주도 속도. 로열티 모델은 대형 라이선시를 통해 확장되므로 도입 속도가 그들의 내부 결정에 일부 좌우됩니다. 장기 물량 계약과, FCC가 기존 제품을 잠식하지 않고 새 매출을 만들어준다는 구조로 완화됩니다. 셋째, 팀 역량. 현재 미국 상업화는 창업자 주도이며, 이번 라운드가 복수의 라이선시, 제지사 협의를 병렬로 진행할 자문과 운영 지원에 투입됩니다. 제지 산업은 느리게 움직이지만, 같은 보수성이 일단 채택된 FCC를 지켜주는 방어막이 됩니다.',
    target_length = 850, updated_at = now()
WHERE answer_key = 'growth_barriers' AND variant = 'short';

INSERT INTO app.answer_library
  (organization_id, answer_key, title, body_en, body_ko,
   disclosure_level, tags, variant, target_length, created_by)
SELECT
  o.organization_id, 'growth_barriers', 'Growth barriers - honest with mitigations',
  'Three things, each with a mitigation. First, validation localization: our commercial proof is Korean mill data, and conservative US buyers want US data - the independent US national-lab test funded by this round removes exactly that barrier and ends with direct introductions to US tissue makers. Second, partner-paced rollout: the royalty model scales through large licensees, so adoption speed partly depends on their internal decisions - mitigated by long-term volume contracts and by the fact that FCC gives producers new revenue instead of cannibalizing existing lines. Third, team bandwidth: the US commercial motion is founder-led today, and this round funds the advisory and operational support to run multiple licensee and mill conversations in parallel. The paper industry moves slowly - but that same conservatism locks FCC in once it is specified at a mill.',
  '세 가지이며 각각 완화책이 있습니다. 첫째, 검증의 현지화. 우리의 상업적 증거는 한국 제지사 데이터인데 보수적인 미국 구매자는 미국 데이터를 원합니다. 이번 라운드로 진행하는 미국 국립연구소 독립 테스트가 정확히 이 장벽을 제거하며, 완료 시 미국 티슈 제조사 직접 소개로 이어집니다. 둘째, 파트너 주도 속도. 로열티 모델은 대형 라이선시를 통해 확장되므로 도입 속도가 그들의 내부 결정에 일부 좌우됩니다. 장기 물량 계약과, FCC가 기존 제품을 잠식하지 않고 새 매출을 만들어준다는 구조로 완화됩니다. 셋째, 팀 역량. 현재 미국 상업화는 창업자 주도이며, 이번 라운드가 복수의 라이선시, 제지사 협의를 병렬로 진행할 자문과 운영 지원에 투입됩니다. 제지 산업은 느리게 움직이지만, 같은 보수성이 일단 채택된 FCC를 지켜주는 방어막이 됩니다.',
  'public', ARRAY['investor','pitch_core'], 'short', 850,
  (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
FROM (SELECT DISTINCT organization_id FROM app.application_forms) o
WHERE NOT EXISTS (
  SELECT 1 FROM app.answer_library a
  WHERE a.organization_id = o.organization_id
    AND a.answer_key = 'growth_barriers' AND a.variant = 'short'
);


-- ------------------------------------------------------------
-- 3. Bindings 601-604 (canonical_key join)
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
  AND ff.seq IN (601, 602, 603, 604)
  AND NOT EXISTS (
    SELECT 1 FROM app.application_field_answers x WHERE x.field_id = ff.id
  );


-- Verify
SELECT seq, label, field_state, char_count, answer_key
FROM app.v_application_field_status
WHERE form_url LIKE '%dealum.com%' AND seq BETWEEN 301 AND 699
ORDER BY seq;
