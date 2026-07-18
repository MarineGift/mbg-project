-- ============================================================
-- fix_hansol_paper_contact_route_2026-07-17.sql
--
-- Hansol Paper's form was swept and fully read. This file records the ROUTE and
-- deliberately does NOT create the form row. The reason is in section 3.
--
-- CONFIRMED DIRECTLY, 2026-07-17:
--   form (KR)  https://www.hansolpaper.co.kr/customer/inquiry
--   form (EN)  https://www.hansolpaper.co.kr/eng/customer/inquiry
--   HQ         서울 중구 을지로 100 파인애비뉴 B동 23~24층 (footer)
--   mills      Janghang, Daejeon, Cheonan, Sintanjin - four, named by Hansol
--              Group's own page, which also calls Hansol "Korea's only
--              comprehensive paper manufacturer that produces printing&writing
--              paper, carton board, specialty paper, and thermal paper"
--   portal     export.hansolpaper.co.kr - a separate login-required export site
--
-- THE FINDING THAT MATTERS, and it is not a small one. THE KOREAN FORM AND THE
-- ENGLISH FORM ARE NOT THE SAME FORM.
--
--   문의분야 (KR)          전체 / 제품 / 한솔루션 / 투자 / 채용 / 기타      6 options
--   Field of inquiry (EN) All / Product inquiry / Investment / Others   4 options
--
--   제품 (KR)   인스퍼 / 인쇄용지 / 산업용지 / 전사지 / 라벨 / POS / 기능지 /
--               신제품 / 프로테고 / 복사용지 / 테라바스
--   Products    Commercial Printing / Premium Printing / Functional Paper
--   (EN)        Packaging / Boxboard / Premium Packaging / Label Papers / Dye
--               Sublimation / Thermal / Flame Retardant Wallpaper / High-Gloss
--               / Biomaterials
--
--   KR fields   이름* 휴대폰* 이메일* 소속* 제목* 내용* 첨부(10MB, jpg gif png
--               pdf doc hwp)
--   EN fields   Name* Mobile* E-mail* Company* COUNTRY* Title* Details* File
--               (10MB, jpg gif png pdf doc - no hwp)
--
-- The English form adds Country and drops hwp. The Korean form carries two
-- routing options the English one does not - 한솔루션 and 채용. Whichever gets
-- registered, the other is a different worklist item with different fields, and
-- a single form_url on the party cannot represent both. That is a real choice,
-- not a formatting detail.
--
-- NEITHER DROPDOWN HAS A PARTNERSHIP, TECHNOLOGY OR R&D OPTION. The door is
-- 기타 / Others. This is the same question left open on Artemyn yesterday - if
-- the subject list only routes to sales, the form is the wrong door - except
-- here the list was actually read, and the answer is that there is no right
-- option, only a least-wrong one. Hansol's own privacy page corroborates the
-- field set exactly: 필수항목 - 이름, 휴대폰, 이메일, 소속, 제목, 내용.
--
-- WHY HANSOL IS WORTH THE TROUBLE ANYWAY. 890ae7ee is Hansol Janghang, and
-- fix_supply_link_taekyung_enrich_2026-07-16 links it to Taekyung BK as an
-- on-site satellite PCC plant. Hansol Janghang is the one mill in this database
-- known to have a satellite carbonate plant inside the fence. That is the exact
-- configuration FCC slots into - and it is also why the approach is delicate,
-- because Taekyung BK co-filed EP4579034 against us. Reaching the mill reaches
-- the adverse party's customer. That is a strategy decision and it is not made
-- in a fix file.
--
-- IDEMPOTENT. No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================


-- ---------- 1) The four MILL rows get the route ----------
-- The URL is a property of the party and every Hansol mill honestly shares the
-- corporate form - it is the only public door any of them has. This is safe and
-- it makes the 027 badge filter show them.
update app.parties p
set contact_form_url         = 'https://www.hansolpaper.co.kr/customer/inquiry',
    preferred_contact_method = 'web_form',
    updated_at = now()
where p.id in (
        'b2d7898e-1571-44c8-8db5-ce5f74f55334'::uuid,  -- Hansol Cheonan
        'a02f872c-2f9e-4863-b271-4ab9741d6be2'::uuid,  -- Hansol Daejeon
        '890ae7ee-12ae-4889-be24-c1f2155dbad0'::uuid,  -- Hansol Janghang - Taekyung BK satellite
        '5110d2b4-d248-4a0f-a6cc-9e0580dff060'::uuid   -- Hansol Shintanjin
      )
  and p.party_type_id = 2
  and p.deleted_at is null
  and p.do_not_contact is false
  and p.contact_form_url is null;


-- ---------- 2) HANSOL PAPERTECH IS NOT TOUCHED ----------
-- c318be29-8a39-4b42-a2dd-71f6085518cc got the same 'Form 입력 (고객문의)' marker
-- in paper-mill-contacts-batch3-KR, alongside the four mills. It runs its OWN
-- domain, hansolpapertech.co.kr. Giving it hansolpaper.co.kr's URL would record
-- a contact route that does not exist - the exact error class caught eight times
-- yesterday. It has not been swept. It stays null until someone opens its page.


-- ---------- 3) WHY THERE IS NO application_forms ROW HERE ----------
-- Because I do not know which party to hang it on, and inventing an answer is
-- how the filler roster ended up with 65 individual plants carrying deal rows.
--
-- All four ids above are MILL rows - fix_supply_link_taekyung_enrich uses
-- 890ae7ee as mill_party_id, which settles it. hansolpaper.co.kr/customer/inquiry
-- belongs to 한솔제지(주), the listed company. A form row is a WORKLIST ITEM, and
-- four copies of one corporate form is four copies of one task -
-- fix_azolla_duplicate_form_2026-07-10 exists because that already happened once.
--
-- Block 5 of scan_paper_mill_form_cohort_2026-07-17 lists every Hansol party.
-- Two outcomes, and both are decisions rather than queries:
--   * a company-level Hansol Paper row exists -> the form row goes there and I
--     write that file in one line
--   * it does not exist -> a party must be created, and creating a party for a
--     KOSPI-listed counterparty is not something a fix file should do quietly
-- Run the scan. Paste block 5 back. The form file follows.


-- ---------- 4) VERIFY ----------
-- select p.id, p.party_name, p.preferred_contact_method, p.contact_form_url
-- from app.parties p
-- where p.deleted_at is null and p.party_name ~* 'hansol|한솔'
-- order by p.party_name;
-- EXPECT exactly four rows carrying the URL. Papertech null. Any company-level
-- Hansol row null too - that one is section 3's open question.
