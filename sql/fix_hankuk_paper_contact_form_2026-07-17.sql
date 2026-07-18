-- ============================================================
-- fix_hankuk_paper_contact_form_2026-07-17.sql
--
-- THE FIRST PAPER MILL contact_inquiry FORM IN THIS DATABASE, and the first
-- application_form_fields ever recorded off a mill page.
--
-- Migration 027 built this machinery and said so in its own header - it
-- generalized the form system to "any party that communicates via a web form
-- (mills included)". Artemyn got the first contact_inquiry row yesterday but
-- NO FIELDS, because its page is a HubSpot embed and a server fetch sees an
-- empty shell. Hankuk Paper renders server-side. The fields below are read off
-- the live page on 2026-07-17. Not one of them is guessed.
--
-- CONFIRMED DIRECTLY, 2026-07-17:
--   form      https://www.hankukpaper.com/ko/cs/addViewCsqna.do
--   FAQ       https://www.hankukpaper.com/ko/cs/listCsfaq.do
--   R&D page  https://www.hankukpaper.com/ko/management/rnd.do
--   plant     온산공장, 울산시 울주군 온산읍 원산로 40 (footer, its own site)
--   CEO       강준석 (footer)
--
-- WHY THIS DOOR AND NOT A GUESS AT A DOOR. Hankuk Paper's own FAQ publishes a
-- 신규 납품 절차 under the question 설비/자재를 납품하고 싶습니다:
--   1) 설비/자재 제안 - submit your material, meet a person if needed
--   2) 당사 수요 발생 시 견적서 요청
--   3) 품질, 가격경쟁력을 포함한 구입타당성 검토
-- and then it says, in its own words:
--   "설비/자재 관련 납품을 원하시면 위 절차를 확인하신 후,
--    홈페이지 고객센터 > 고객문의 > 기타로 문의 바랍니다."
-- The company names the form AND the dropdown option to pick. That is a
-- company-specific instruction, not process boilerplate - it does not travel,
-- which is the only test that mattered yesterday. Compare Zantat, whose contact
-- page assigns sales@ to partnership collaborations. Same shape of evidence.
--
-- GRADE FIT, also off its own site and not off filler_use_intensity:
--   인쇄용지 (아트지, 백상지) · 정보용지 (복사지 miilk) · 특수지 · 팬시용지 ·
--   식품기능용지 · 전사지
-- 백상지 and 복사지 are uncoated woodfree. 아트지 is coated woodfree. Those are
-- the highest filler-loading grades made - the grades where swapping pulp fiber
-- for filler is worth real money, which is the entire FCC argument. Kunal
-- Calcium's own page said it out loud yesterday: "replacement of more expensive
-- pulp fiber". Hankuk is the mill side of that same sentence.
--
-- WHAT IS NOT RECORDED AND WAS NOT INVENTED:
--   * max_length on every field. The page is server-rendered so labels, types
--     and required markers are real, but the maxlength attributes were not
--     readable. A browser must capture them. The variant system picks a body
--     against a REAL max_length - a guessed number defeats the whole point.
--   * selector - left null, no attribute was read.
--
-- ONE CONTRADICTION ON THE PAGE, left as-is rather than resolved by preference.
-- The required markers mark 문의분야, 제품종류, 이름, 이메일 and 제목. The privacy
-- notice underneath lists 필수항목 as 문의분야, 이름, 이메일 only, and does not
-- mark 내용. is_required below follows the markers, which is what the browser
-- will actually enforce.
--
-- ANSWERS ARE DELIBERATELY NOT BOUND HERE. seed_filler_form_answers is tagged
-- filler_safe and was written blander on purpose, because a filler producer is
-- a potential licensee AND a potential competitor. A mill is neither - it is the
-- customer. The mill answer set is a different argument to a different reader
-- and it is a separate file and a separate decision. canonical_key is set on the
-- two fields that will carry it so the mapping is ready.
--
-- do_not_contact guard included. migration_028 asked for exactly this - "no
-- contact_inquiry form is ever created against a flagged party in the first
-- place". This is the first file to honour it. If block 1 throws 42703 the
-- column does not exist yet, which means 028 is committed but NOT applied - run
-- it first. That is the plant_supply_links trap.
--
-- created_by is set explicitly. application_forms declares
-- created_by uuid NOT NULL DEFAULT auth.uid(), and auth.uid() is null in the
-- SQL Editor - that is the 23502 that hit the answer seed yesterday.
--
-- IDEMPOTENT. No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================


-- ---------- 1) The party: form URL and contact method ----------
update app.parties p
set contact_form_url         = 'https://www.hankukpaper.com/ko/cs/addViewCsqna.do',
    preferred_contact_method = 'web_form',
    updated_at = now()
where p.id = '028f9b56-3780-4bb2-91f4-ca3514025484'::uuid
  and p.party_type_id = 2
  and p.deleted_at is null
  and p.do_not_contact is false;
-- Both columns move together. parties_contact_form_url_chk fires 23514 if
-- preferred_contact_method is web_form and the URL is null - that is what threw
-- yesterday when a URL was declared without one being read.


-- ---------- 2) THE FORM ROW ----------
insert into app.application_forms
  (organization_id, party_id, form_url, form_type, submission_method,
   login_required, status, notes, created_by)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid,
       p.id,
       'https://www.hankukpaper.com/ko/cs/addViewCsqna.do',
       'contact_inquiry',
       'web_form',
       false,
       'not_started',
       'FIRST MILL FORM. Hankuk Paper Mfg (한국제지), Onsan mill, Ulsan. Uncoated and coated woodfree printing plus copy paper - the highest filler-loading grades made, which is the grade band FCC is for. THE COMPANY NAMED THIS DOOR ITSELF. Its FAQ answer to 설비/자재를 납품하고 싶습니다 publishes a three-step supply procedure starting with 설비/자재 제안, and closes with 설비/자재 관련 납품을 원하시면 위 절차를 확인하신 후, 홈페이지 고객센터 > 고객문의 > 기타로 문의 바랍니다. So 문의분야 = 기타문의 is not a guess, it is the routing the company published. FIELDS ARE REAL, read off the live page 2026-07-17. MAX_LENGTH IS NOT - every field carries null and a browser must capture the maxlength attributes before any answer is bound. ANSWERS ARE NOT BOUND. The filler_safe set is the wrong register for a mill - it was written flat because filler producers compete with us, and a mill does not. Merged 세하(주) in August 2023, roughly 1 trillion KRW of sales. Also note 시험성적요청문의 in the same dropdown - a mill that has a published route for test-report requests has a lab, and a lab is a better second door than a sales queue.',
       coalesce(auth.uid(), (select pp.created_by from app.parties pp where pp.created_by is not null limit 1))
from app.parties p
where p.id = '028f9b56-3780-4bb2-91f4-ca3514025484'::uuid
  and p.party_type_id = 2
  and p.deleted_at is null
  and p.do_not_contact is false
  and not exists (
    select 1 from app.application_forms af
    where af.party_id = p.id and af.form_type = 'contact_inquiry');


-- ---------- 3) THE FIELDS - every one read off the page ----------
insert into app.application_form_fields
  (organization_id, form_id, seq, label, field_type, max_length,
   is_required, help_text, input_kind, canonical_key)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid,
       f.id, v.seq, v.label, v.field_type, v.max_length,
       v.is_required, v.help_text, v.input_kind, v.canonical_key
from app.application_forms f
cross join (values
  (10, '문의분야', 'dropdown', null::int, true,
       'Options as published: 제품문의 / 구입문의 / 시험성적요청문의 / 채용문의 / 사보/샘플북 / 기타문의. PICK 기타문의 - the company FAQ routes 설비/자재 제안 there by name. 시험성적요청문의 is the lab route and is the fallback worth testing.',
       'select_option', null),
  (20, '제품종류', 'dropdown', null::int, true,
       'Options as published: 제품선택 / 인쇄용지 / 정보용지(복사지) / 산업용지 / 팬시용지 / 식품기능용지 / 전사지 / 특수지 / 고객불편사항(품질). 인쇄용지 or 정보용지(복사지) are the filler-loaded grades. Which one is a positioning decision - 정보용지 is the copy-paper line miilk, 인쇄용지 covers 아트지 and 백상지.',
       'select_option', null),
  (30, '이름', 'text', null::int, true, null, 'fill', null),
  (40, '이메일', 'text', null::int, true,
       'SPLIT FIELD. Local-part box plus a domain box plus a service dropdown - dreamwiz.com / empal.com / hanmail.net / hanmir.com / hotmail.com / korea.com / nate.com / naver.com / netian.com / paran.com / sayclub.com / yahoo.co.kr / 직접입력. A company domain needs 직접입력 and then typing the domain. Any automation must handle three inputs, not one.',
       'fill', null),
  (50, '휴대폰', 'text', null::int, false,
       'Three boxes. Not marked required on the page. The privacy notice calls 연락처(휴대폰) the only 선택항목.',
       'fill', null),
  (60, '주소', 'text', null::int, false, null, 'fill', null),
  (70, '제목', 'text', null::int, true,
       'max_length UNKNOWN. Subject lines on Korean forms are commonly capped well under 100 characters, which is a reason to check and not a reason to assume.',
       'fill', 'fcc_inquiry_subject'),
  (80, '내용', 'textarea', null::int, false,
       'NOT marked required on the page, which is almost certainly a page defect rather than an intent - the form is useless empty. max_length UNKNOWN and this is the field that matters most, because the short / medium / long variant is chosen against it.',
       'fill', 'fcc_inquiry_intro'),
  (90, '첨부파일', 'file', null::int, false,
       'Accepted types and size cap were not stated on this page. Hansol states 10MB and jpg gif png pdf doc hwp on its equivalent page. Hankuk does not, so nothing is recorded.',
       'upload', null),
  (100, '개인정보 수집 및 이용 동의', 'dropdown', null::int, true,
       'A 동의 / 동의하지 않음 pair, mandatory. field_type has no radio member - the allowed set is text, textarea, dropdown, url, number, file, date - so dropdown carries it and input_kind check records what it actually is. Retention stated as 6개월 after receipt.',
       'check', null)
) as v(seq, label, field_type, max_length, is_required, help_text, input_kind, canonical_key)
where f.party_id = '028f9b56-3780-4bb2-91f4-ca3514025484'::uuid
  and f.form_type = 'contact_inquiry'
  and not exists (
    select 1 from app.application_form_fields ff
    where ff.form_id = f.id and ff.seq = v.seq);


-- ---------- 4) VERIFY ----------
-- select p.party_name, p.preferred_contact_method, p.contact_form_url,
--        af.form_type, af.submission_method, af.status,
--        (select count(*) from app.application_form_fields ff where ff.form_id = af.id) as fields
-- from app.parties p
-- join app.application_forms af on af.party_id = p.id and af.form_type = 'contact_inquiry'
-- where p.id = '028f9b56-3780-4bb2-91f4-ca3514025484'::uuid;
-- EXPECT one row, web_form, not_started, 10 fields.
--
-- select seq, label, field_type, is_required, max_length, canonical_key, input_kind
-- from app.v_application_field_status
-- where party_name ~* 'hankuk' order by seq;
-- EXPECT field_state 'empty' on all ten - correct. Nothing is bound yet.


-- ---------- 5) NEXT, IN ORDER ----------
-- (a) Open the page and capture max_length on 제목 and 내용. Those two numbers
--     are what the variant system runs on. Until they exist the form cannot be
--     filled correctly, only filled.
-- (b) Decide the mill answer set. It is NOT the filler set. The filler set
--     carries capability and outcome and nothing else because the reader might
--     work around the patent. A mill reader wants the fiber-substitution number
--     and the runnability answer. It is a different letter.
--     COUNTER-ARGUMENT, and it is not weak: a mill tells its incumbent PCC
--     supplier everything. Pitching Hansol Janghang reaches Taekyung BK, which
--     is the other side of EP4579034. The mill set needs its own gate, not just
--     a warmer tone.
-- (c) 시험성적요청문의 as the second door. A published test-report route implies a
--     lab that takes outside requests. That is closer to Par Moor than any
--     sales queue is.
