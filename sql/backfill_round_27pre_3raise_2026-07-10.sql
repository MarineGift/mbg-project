-- ============================================================
-- backfill_round_27pre_3raise_2026-07-10.sql
-- Round restructure v2: 5M raise @ 30M pre / 35M post
--   ->  3M raise @ 27M pre / 30M post (10 pct dilution).
--
-- New use of funds (3M total):
--   1M  FCC applied research and commercialization
--        (flame-retardant wallpaper, copy paper, packaging, tissue)
--   1M  patents / IP
--   1M  operations
--
-- Valuation logic shifts 1.3x -> 1.2x of the validated Y3
-- royalty projection (22.4M USD).
--
-- Scope: answer_library keys capital_seeking, deal_terms,
-- use_of_funds, ask_use_of_funds, valuation_rationale
-- (all variants, en + ko) PLUS the raise / pre-money /
-- use-of-funds fields already seeded on the CEV and Anzu forms.
-- Deck V3.0 slides 18/19 are a separate file task - handoff todo.
--
-- Supabase SQL Editor safe: no do-blocks, no temp tables,
-- no semicolons or SQL keywords inside string literals
-- ============================================================

-- ------------------------------------------------------------
-- 1. answer_library: overwrite body_en + body_ko for every
--    variant of the five affected keys
-- ------------------------------------------------------------
update app.answer_library al
set body_en    = v.body_en,
    body_ko    = v.body_ko,
    updated_at = now()
from (values
  ('capital_seeking',
   'We are raising a 3M USD Series A at a 27M USD pre-money valuation (30M USD post).',
   '300만 달러 규모의 Series A 라운드를 진행 중입니다(프리머니 2,700만 달러, 포스트머니 3,000만 달러).'),

  ('deal_terms',
   'Series A priced equity - 3M USD total, 27M USD pre-money / 30M USD post-money, about 10 pct dilution, no outstanding convertible securities.',
   'Series A 프라이스드 에쿼티 - 총 300만 달러, 프리머니 2,700만 달러 / 포스트머니 3,000만 달러, 지분 희석 약 10퍼센트, 기존 전환증권 없음.'),

  ('use_of_funds',
   '1.0M USD FCC applied research and commercialization across flame-retardant wallpaper, copy paper, packaging and tissue, 1.0M USD patents and IP, 1.0M USD operations (3M USD total).',
   'FCC 추가 적용 연구 및 상용화(난연벽지, 복사지, 패키징, 티슈 등) 100만 달러, 특허 및 IP 100만 달러, 운영비 100만 달러(총 300만 달러).'),

  ('ask_use_of_funds',
   'We are raising 3M USD in a Series A at a 27M USD pre-money valuation. Use of funds: 1.0M USD FCC applied research and commercialization for new grades such as flame-retardant wallpaper, copy paper, packaging and tissue, 1.0M USD patents and IP, and 1.0M USD operations.',
   '프리머니 2,700만 달러 기준 300만 달러 Series A를 요청합니다. 자금 사용처는 난연벽지, 복사지, 패키징, 티슈 등 신규 등급을 위한 FCC 적용 연구 및 상용화 100만 달러, 특허 및 IP 100만 달러, 운영비 100만 달러입니다.'),

  ('valuation_rationale',
   '27M USD pre-money - about 1.2x our validated Year 3 royalty projection of 22.4M USD, conservative against the 5-15x multiples typical of royalty deals. A confirmed 9,000-ton order accrues royalty at 350 USD per ton, with roughly 10,000 more tons in progress.',
   '프리머니 2,700만 달러 - 검증된 트랙 기준 3년차 예상 로열티 2,240만 달러의 약 1.2배로, 로열티 사업의 통상 5~15배 거래 대비 보수적입니다. 톤당 350달러 로열티가 자동 발생하는 9,000톤 오더가 확정되어 있고 약 10,000톤이 추가 진행 중입니다.')
) as v(answer_key, body_en, body_ko)
where al.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and al.answer_key = v.answer_key;


-- ------------------------------------------------------------
-- 2. CEV form: raise / pre-money numeric fields carry literal
--    values, not library text - update those directly
--    (380 raise, 390 pre-money, 370 total-to-exit)
-- ------------------------------------------------------------
update app.application_field_answers fa
set final_text = case ff.seq
                   when 380 then '3000000'
                   when 390 then '27000000'
                   when 370 then '3000000'
                 end,
    updated_at = now()
from app.application_form_fields ff,
     app.application_forms f,
     app.parties pt
where ff.id = fa.field_id
  and f.id  = ff.form_id
  and pt.id = f.party_id
  and f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and pt.party_name ilike '%clean energy ventures%'
  and ff.seq in (370, 380, 390);


-- ------------------------------------------------------------
-- 3. Anzu form: raise / pre-money literal fields (180 raise,
--    220 pre-money) use the comma dollar format the form asks for
-- ------------------------------------------------------------
update app.application_field_answers fa
set final_text = case ff.label
                   when 'Raise amount USD'        then '$3,000,000'
                   when 'Pre-money valuation USD'  then '$27,000,000'
                 end,
    updated_at = now()
from app.application_form_fields ff
where ff.id = fa.field_id
  and ff.form_id = 'ce64cf37-9a02-498c-8b90-84bbddf5edba'::uuid
  and ff.label in ('Raise amount USD', 'Pre-money valuation USD');


-- ------------------------------------------------------------
-- 4. Resync library-bound answers on CEV + Anzu that copied the
--    old round text (use_of_funds bindings). Re-pulls current
--    body_en off the bound answer for any field whose answer_id
--    points at one of the five updated keys.
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
      ('capital_seeking','deal_terms','use_of_funds','ask_use_of_funds','valuation_rationale')
  and al.body_en is not null
  and fa.final_text is distinct from al.body_en;


-- ------------------------------------------------------------
-- VERIFY 1: the five keys now on 27/3/30 (expect no 5M / 30M pre
-- / 35M anywhere, valuation reads 1.2x)
-- ------------------------------------------------------------
select answer_key, variant,
       left(body_en, 45) as en_head,
       left(body_ko, 35) as ko_head
from app.answer_library
where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and answer_key in
      ('capital_seeking','deal_terms','use_of_funds','ask_use_of_funds','valuation_rationale')
order by answer_key, variant;


-- ------------------------------------------------------------
-- VERIFY 2: stale sweep for the OLD structure across library +
-- both form answer sets (expect 0 rows)
-- ------------------------------------------------------------
select 'library' as src, answer_key as ref, variant
from app.answer_library
where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and (body_en like '%5M USD Series A%' or body_en like '%30M USD pre%'
       or body_en like '%35M USD post%' or body_en like '%1.3x%'
       or body_ko like '%500만 달러%' or body_ko like '%3,000만 달러%'
       or body_ko like '%3,500만 달러%' or body_ko like '%1.3배%')
union all
select 'form_answer', pt.party_name, ff.label
from app.application_field_answers fa
join app.application_form_fields ff on ff.id = fa.field_id
join app.application_forms f        on f.id  = ff.form_id
join app.parties pt                 on pt.id = f.party_id
where f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and (pt.party_name ilike '%clean energy ventures%' or pt.party_name ilike '%anzu%')
  and (fa.final_text like '%5M USD Series A%' or fa.final_text like '%30M USD pre%'
       or fa.final_text like '%35M USD post%' or fa.final_text like '%1.3x%'
       or fa.final_text like '%5,000,000%' or fa.final_text like '%30000000%'
       or fa.final_text like '%$5,000,000%' or fa.final_text like '%$30,000,000%');


-- ------------------------------------------------------------
-- VERIFY 3: the numeric round fields on both forms
-- ------------------------------------------------------------
select pt.party_name, ff.seq, ff.label, fa.final_text
from app.application_field_answers fa
join app.application_form_fields ff on ff.id = fa.field_id
join app.application_forms f        on f.id  = ff.form_id
join app.parties pt                 on pt.id = f.party_id
where f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and (pt.party_name ilike '%clean energy ventures%' or pt.party_name ilike '%anzu%')
  and (ff.label ilike '%raise%' or ff.label ilike '%pre-money%'
       or ff.label ilike '%pre money%' or ff.label ilike '%capital raise%'
       or ff.label ilike '%total capital%')
order by pt.party_name, ff.seq;
