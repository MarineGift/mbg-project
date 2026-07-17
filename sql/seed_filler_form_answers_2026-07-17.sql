-- ============================================================
-- seed_filler_form_answers_2026-07-17.sql
--
-- The answer set for filler contact_inquiry forms. Omya, Specialty Minerals and
-- Taekyung are OUT - Omya and SMI are already partners and already contacted,
-- Taekyung is an adverse party in the EP4579034 dispute.
--
-- TARGET COUNT: 83 companies. That is the 156 reachable filler rows minus 73
-- Omya / Specialty Minerals / Taekyung rows. Evidence spread A 3, B 20, C 59.
-- ZERO of the 83 currently have a contact_form_url. None have a contact either -
-- 4 of 242 filler parties do, and all 4 are Omya or SMI.
--
-- WHY THESE ANSWERS ARE SHORTER AND BLANDER THAN THE INVESTOR SET
-- An investor reading the pitch is a funder. A filler producer reading it is a
-- potential licensee AND a potential competitor - Taekyung is literally both,
-- and Omya and Imerys jointly own FiberLean while Specialty Minerals sells
-- FulFill. The people best placed to license FCC are the people best placed to
-- work around it. So this set carries capability and outcome and nothing else:
--   NO royalty rate, NO per-ton figure, NO price
--   NO patent numbers, NO ownership structure, NO affiliate names
--   NO named partners or mill customers
--   NO order volumes, NO counterparty deal stage
--   NO process parameters, NO formulations, NO yields
-- Everything asserted below is either already published in the peer-reviewed
-- literature or already in a public answer. Nothing here is new disclosure.
--
-- Every row is tagged filler_safe. Nothing else in the library is, and the
-- binding rule is deny-by-default:
--     disclosure_level = 'public' AND tags @> ARRAY['filler_safe']
--
-- created_by IS SET EXPLICITLY, and the first attempt failed because it was not.
-- The column is `created_by uuid NOT NULL DEFAULT auth.uid()`. In the Supabase
-- SQL Editor the statement runs as postgres, auth.uid() returns null, and the
-- NOT NULL constraint fires - 23502. I flagged this risk, then checked
-- seed_answer_library.sql, saw that it omits created_by, and read that as proof
-- the convention works. It is not proof - that seed almost certainly ran through
-- the application, where auth.uid() resolves. I did the check and then read an
-- ambiguous answer as confirmation.
-- No uuid is invented here. The value is taken from the library's own oldest row,
-- which is accurate for a solo developer, and auth.uid() still wins if present.
-- Keys checked against all 75 existing answer_keys. No collisions.
-- UNIQUE is (organization_id, answer_key, variant) since 027 dropped the old
-- answer_library_key_uq, so one key can carry several lengths.
--
-- IDEMPOTENT via NOT EXISTS on (answer_key, variant).
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 1) SUBJECT LINE - for Subject fields ----------
insert into app.answer_library (organization_id, answer_key, variant, target_length, title, body_en, body_ko, disclosure_level, tags, created_by)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, 'fcc_inquiry_subject', 'short', 70,
  'Filler inquiry - subject line',
  'Technology licensing - calcium carbonate grown in situ on pulp fiber',
  '기술 라이선싱 - 펄프 섬유 위에 in-situ로 성장시킨 탄산칼슘',
  'public', ARRAY['licensing','filler','filler_safe'],
  coalesce(auth.uid(), (select al.created_by from app.answer_library al where al.created_by is not null order by al.created_at limit 1))
where not exists (select 1 from app.answer_library where answer_key = 'fcc_inquiry_subject' and variant = 'short');


-- ---------- 2) WHAT IT IS - one paragraph, no how ----------
insert into app.answer_library (organization_id, answer_key, variant, target_length, title, body_en, body_ko, disclosure_level, tags, created_by)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, 'fcc_what_it_is', 'short', 260,
  'FCC in one paragraph - filler audience',
  'FCC is a paper filler in which calcium carbonate is grown in situ on pulp fiber, so mineral and fiber form a single composite particle rather than a physical blend. It lets mills replace costly pulp with low-cost filler without losing sheet strength.',
  'FCC는 탄산칼슘을 펄프 섬유 위에 in-situ로 성장시킨 제지용 충전제로, 광물과 섬유가 물리적 혼합이 아니라 하나의 복합 입자를 이룹니다. 제지사는 비싼 펄프를 저가 충전제로 대체하면서도 지력을 잃지 않습니다.',
  'public', ARRAY['licensing','filler','filler_safe'],
  coalesce(auth.uid(), (select al.created_by from app.answer_library al where al.created_by is not null order by al.created_at limit 1))
where not exists (select 1 from app.answer_library where answer_key = 'fcc_what_it_is' and variant = 'short');


-- ---------- 3) THE MESSAGE - short variant, for tight fields ----------
insert into app.answer_library (organization_id, answer_key, variant, target_length, title, body_en, body_ko, disclosure_level, tags, created_by)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, 'fcc_inquiry_intro', 'short', 200,
  'Filler inquiry - short message',
  'Marinebio Group licenses FCC, a paper filler grown in situ on pulp fiber that lets mills replace pulp with filler without losing strength. It runs on existing PCC and GCC plant assets. Open to a short technical call under NDA.',
  'Marinebio Group은 펄프 섬유 위에 in-situ로 성장시킨 제지용 충전제 FCC를 라이선싱합니다. 제지사는 지력 손실 없이 펄프를 충전제로 대체할 수 있습니다. 기존 PCC·GCC 설비에서 생산됩니다. NDA 하에 짧은 기술 미팅을 요청드립니다.',
  'public', ARRAY['licensing','filler','filler_safe'],
  coalesce(auth.uid(), (select al.created_by from app.answer_library al where al.created_by is not null order by al.created_at limit 1))
where not exists (select 1 from app.answer_library where answer_key = 'fcc_inquiry_intro' and variant = 'short');


-- ---------- 4) THE MESSAGE - medium variant, the workhorse ----------
insert into app.answer_library (organization_id, answer_key, variant, target_length, title, body_en, body_ko, disclosure_level, tags, created_by)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, 'fcc_inquiry_intro', 'medium', 900,
  'Filler inquiry - standard message',
  'Marinebio Group is a technology licensor in paper fillers. We have developed FCC, a filler in which calcium carbonate is grown in situ on pulp fiber, so that mineral and fiber form a single composite particle rather than a physical blend. For the mill the effect is direct - costly pulp is replaced by low-cost filler without losing sheet strength.

We are contacting you because FCC is produced on existing PCC and GCC plant assets. It is not a greenfield proposition. For a filler producer it is an upgrade to a line you already run and to mill relationships you already hold, sold as a specialty grade rather than a commodity one. We license the technology - you produce it and you sell it.

The underlying work is patented and published in the peer-reviewed literature, including two articles in ACS journals, and the technology is certified under Korea''s NET New Excellent Technology programme.

We would welcome a short technical conversation under NDA. We do not discuss process detail outside an agreement and we would expect the same of you.',
  'Marinebio Group은 제지용 충전제 기술 라이선서입니다. 저희는 탄산칼슘을 펄프 섬유 위에 in-situ로 성장시킨 충전제 FCC를 개발했습니다. 광물과 섬유가 물리적 혼합이 아니라 하나의 복합 입자를 이룹니다. 제지사 입장에서 효과는 직접적입니다 - 비싼 펄프를 저가 충전제로 대체하면서 지력을 잃지 않습니다.

연락드리는 이유는 FCC가 기존 PCC·GCC 설비에서 생산되기 때문입니다. 신규 공장을 짓는 제안이 아닙니다. 충전제 제조사에게는 이미 운영 중인 라인과 이미 보유한 제지사 관계에 대한 업그레이드이며, 범용재가 아니라 특수재로 판매됩니다. 저희는 기술을 라이선싱하고, 생산과 판매는 귀사가 합니다.

기반 기술은 특허를 받았고 동료심사 문헌에 게재돼 있습니다. ACS 저널 2편이 포함됩니다. 또한 한국 NET 신기술 인증을 받았습니다.

NDA 하에 짧은 기술 논의를 희망합니다. 저희는 계약 밖에서 공정 세부를 논의하지 않으며, 귀사에도 같은 것을 기대합니다.',
  'public', ARRAY['licensing','filler','filler_safe'],
  coalesce(auth.uid(), (select al.created_by from app.answer_library al where al.created_by is not null order by al.created_at limit 1))
where not exists (select 1 from app.answer_library where answer_key = 'fcc_inquiry_intro' and variant = 'medium');


-- ---------- 5) THE MESSAGE - long variant, first use of 'long' in this library ----------
insert into app.answer_library (organization_id, answer_key, variant, target_length, title, body_en, body_ko, disclosure_level, tags, created_by)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, 'fcc_inquiry_intro', 'long', 1900,
  'Filler inquiry - long message',
  'Marinebio Group is a technology licensor in paper fillers, and we are writing about a licensing opportunity that sits on plant assets you already operate.

WHAT FCC IS. FCC is a filler in which calcium carbonate is grown in situ on pulp fiber. Mineral and fiber form a single composite particle rather than a physical blend of two materials. The distinction matters because the strength penalty that normally caps filler loading comes from mineral displacing fiber-to-fiber bonding. When the mineral is grown on the fiber instead of mixed alongside it, that trade-off changes.

WHAT IT DOES FOR THE MILL. Pulp is the largest cost line in most paper grades and filler is among the smallest. FCC lets a mill move volume from the first to the second without giving up sheet strength. The mill needs no capital expenditure - it buys a filler grade instead of buying pulp.

WHY WE ARE CONTACTING A FILLER PRODUCER RATHER THAN A MILL. FCC is produced on existing PCC and GCC plant assets. It is not a greenfield proposition and it does not ask you to enter a new business. It is an upgrade to a line you already run, sold to mill customers you already hold, at a specialty price rather than a commodity one. Our model is licensing - we license the technology, you produce it and you sell it.

WHAT IS ESTABLISHED. The underlying work is patented and published in the peer-reviewed literature, including two articles in ACS journals, so the science is on the public record and can be assessed independently before any commercial discussion. The technology is certified under Korea''s NET New Excellent Technology programme.

WHAT WE ARE ASKING FOR. A short technical conversation under NDA - roughly fifteen minutes to establish whether this is worth either side''s time. We do not discuss process detail, formulations or operating parameters outside an agreement, and we would expect the same discipline from you. If the fit is not there we would rather find that out quickly.',
  'Marinebio Group은 제지용 충전제 기술 라이선서이며, 귀사가 이미 운영 중인 설비 위에서 성립하는 라이선싱 건으로 연락드립니다.

FCC란. FCC는 탄산칼슘을 펄프 섬유 위에 in-situ로 성장시킨 충전제입니다. 두 재료의 물리적 혼합이 아니라 광물과 섬유가 하나의 복합 입자를 이룹니다. 이 차이가 중요한 이유는, 충전제 함량을 제한하는 지력 저하가 광물이 섬유 간 결합을 밀어내는 데서 오기 때문입니다. 광물을 섬유 옆에 섞는 대신 섬유 위에 성장시키면 그 트레이드오프가 달라집니다.

제지사에게 주는 것. 대부분의 지종에서 펄프는 가장 큰 원가 항목이고 충전제는 가장 작은 축에 듭니다. FCC는 지력을 포기하지 않으면서 물량을 앞에서 뒤로 옮기게 합니다. 제지사는 설비 투자가 필요 없습니다 - 펄프를 사는 대신 충전제 등급을 사면 됩니다.

왜 제지사가 아니라 충전제 제조사에 연락하는가. FCC는 기존 PCC·GCC 설비에서 생산됩니다. 신규 공장 제안이 아니고, 새로운 사업에 진입하라는 요구도 아닙니다. 이미 운영 중인 라인에 대한 업그레이드이며, 이미 보유한 제지사 고객에게 범용가가 아니라 특수재 가격으로 판매됩니다. 저희 모델은 라이선싱입니다 - 저희가 기술을 라이선싱하고 생산과 판매는 귀사가 합니다.

확립된 것. 기반 기술은 특허를 받았고 동료심사 문헌에 게재돼 있습니다. ACS 저널 2편이 포함되며, 따라서 과학적 근거가 공개 기록으로 존재해 상업적 논의 전에 독립적으로 검토하실 수 있습니다. 또한 한국 NET 신기술 인증을 받았습니다.

요청드리는 것. NDA 하의 짧은 기술 논의 - 서로의 시간을 쓸 가치가 있는지 판단할 15분 정도면 됩니다. 저희는 계약 밖에서 공정 세부·배합·운전 조건을 논의하지 않으며 귀사에도 같은 규율을 기대합니다. 맞지 않는다면 빨리 확인하는 편이 낫다고 생각합니다.',
  'public', ARRAY['licensing','filler','filler_safe'],
  coalesce(auth.uid(), (select al.created_by from app.answer_library al where al.created_by is not null order by al.created_at limit 1))
where not exists (select 1 from app.answer_library where answer_key = 'fcc_inquiry_intro' and variant = 'long');


-- ---------- 6) THE NDA CLOSE - appended to every message ----------
insert into app.answer_library (organization_id, answer_key, variant, target_length, title, body_en, body_ko, disclosure_level, tags, created_by)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, 'nda_request_close', 'short', 180,
  'NDA request - close for filler inquiries',
  'We would welcome a short technical conversation under NDA. We do not discuss process detail, formulations or operating parameters outside an agreement, and we would expect the same of you.',
  'NDA 하에 짧은 기술 논의를 희망합니다. 저희는 계약 밖에서 공정 세부·배합·운전 조건을 논의하지 않으며, 귀사에도 같은 것을 기대합니다.',
  'public', ARRAY['licensing','filler','filler_safe','nda'],
  coalesce(auth.uid(), (select al.created_by from app.answer_library al where al.created_by is not null order by al.created_at limit 1))
where not exists (select 1 from app.answer_library where answer_key = 'nda_request_close' and variant = 'short');


-- ---------- 7) VERIFY ----------
-- select answer_key, variant, target_length, disclosure_level, tags,
--        length(body_en) as en, length(body_ko) as ko
-- from app.answer_library
-- where tags @> ARRAY['filler_safe']
-- order by answer_key, target_length;
-- Expect 6 rows. Everything else in the library stays unbindable to a filler
-- form, which is the point.


-- ---------- 8) TWO DECISIONS I DID NOT MAKE ----------
--
-- (a) MILL-SCALE VALIDATION. nda_achieved_full says the technology was validated
-- at commercial mill scale on a production machine in both GCC and PCC systems.
-- That answer is nda_only, so I did not put the claim in a public form even
-- though company_one_liner already says "in market" publicly. It is the single
-- strongest line available and it would lift the medium and long variants a lot.
-- If mill-scale validation is publicly claimable, add this sentence after the
-- ACS line and nothing else changes:
--   "The technology has been validated at commercial mill scale on a production
--    machine, in both GCC and PCC systems."
--   "본 기술은 상업 제지기 규모에서 GCC·PCC 양쪽 시스템으로 검증됐습니다."
-- I will not promote nda_only content to public on my own reading.
--
-- (b) IMERYS. The 83 targets include Imerys HQ, China, India, USA and Korea -
-- five rows. You excluded Omya, Specialty Minerals and Taekyung. You did not
-- mention Imerys, and I am not going to quietly decide it either way. But the
-- public `competitors` answer says FiberLean Technologies is an Omya AND IMERYS
-- joint venture, listed as a direct competitor. Approaching Imerys is
-- approaching the other half of the competing JV, and my "Imerys coverage hole"
-- from yesterday was probably not a hole at all - it may have been deliberate.
-- Tell me which and I will add or exclude them in one line.
