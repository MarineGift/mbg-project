-- ============================================================
-- fix_adverse_parties_dnc_2026-07-17.sql   [REISSUED - verify uncommented]
--
-- ⚠️ TWO THINGS CHANGED, AND BOTH ARE STATED HERE RATHER THAN BURIED.
--   (1) Block 4 was a COMMENT and is now a SELECT.
--   (2) 🔴 ONE STRING IN STATEMENT 1 IS REWORDED - and it may be the bug.
--       The committed original's Kleannara notes text reads:
--         "...it sits in the roster WHERE 868 of 888 parties already have a
--          contact and WHERE the outreach machine is live."
--       TWO BARE `where` KEYWORDS INSIDE A QUOTED STRING. That breaks this
--       project's own Supabase SQL Editor rule, and yesterday's mistake log
--       records the failure mode in another language: a parse failure CANCELS THE
--       WHOLE BLOCK. Three statements, zero applied, is exactly what an aborted
--       script looks like.
--       So there are two candidate explanations and the fix makes the question
--       moot: either the file was never run, or IT WAS RUN AND THE PARSER KILLED
--       IT SILENTLY. The second is the better hypothesis - it explains why all
--       three failed together when only the first carried the trap.
--       Reworded to carry no keyword. The MEANING is identical. do_not_contact,
--       do_not_contact_reason and every WHERE clause are untouched.
--
-- 🔴 WHY THIS FILE IS BEING REISSUED. IT NEVER RAN.
-- At roughly 20:30 on 2026-07-17, block 1 of scan_mill_filler_pairs printed:
--     Taekyung BK Co. (태경비케이, ex-Baekkwang Materials)  do_not_contact = FALSE
--     ... holding 1 mill link, 1 high-grade: Hansol Paper - Janghang Mill
--     adverse holders across all 73 high-grade pairs: NONE
-- The regex in block 3 below matches that row name THREE separate ways -
-- 'taekyung bk', '태경비케이' and 'baekkwang'. It cannot miss. The file was
-- written, committed to sql/, and never executed.
-- THAT IS THE plant_supply_links TRAP EXACTLY: migration 024 also sits in sql/
-- and was also never applied. A file in the repository is not a row in the
-- database, and this project has now been bitten by that twice.
--
-- WHAT IT COST. Every `and p.do_not_contact is false` guard written today - on
-- Hankuk, Hansol, Andhra, BILT, West Coast, SPB, TNPL, Sylvamo and Domtar -
-- passed. They were decoration. Not one of them was ever tested, because the
-- flag they test was never set. scan_paper_mill_form_cohort block 8 predicted
-- this in writing: "If Kleannara still reads false, fix_adverse_parties_dnc has
-- not run and every do_not_contact is false guard written today passes on the one
-- party it was written for."
--
-- WHY THE VERIFY BEING A COMMENT IS THE ROOT CAUSE AND NOT A DETAIL. Supabase
-- prints 'Success. No rows returned' for any DML without RETURNING, whether it
-- matched three rows or zero. This file's proof was sitting four lines below the
-- statements, behind two dashes. Running it and reading 'Success' would have
-- looked identical to running it and having it work. THE RULE ESTABLISHED TODAY -
-- the last statement of every fix file is an uncommented select - exists because
-- of this file, and this file is the one that most needed it.
--
-- THE HEADER LINE BELOW IS NOW STALE AND IS LEFT IN ON PURPOSE:
--   "Nothing has gone out yet - all three show form_rows = 0 and the two Taekyung
--    rows have zero contacts. That is luck, not design."
-- That was true when it was written. Block 4 now re-checks it INSTEAD of
-- asserting it, and it checks sequence enrolments and deals as well, because the
-- sequence worker is always on and the roster these rows sit in is the live one.
--
-- Depends on: migration_028_do_not_contact_2026-07-17.sql - CONFIRMED APPLIED
-- (nine fix files referenced do_not_contact today without throwing 42703).
-- Targeted by exact party_name. IDEMPOTENT - each statement carries
-- `and p.do_not_contact is false`, so a second run is a no-op, not a failure.
-- Reversible - set do_not_contact false and clear the reason.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================


-- ---------- 1) Kleannara - the paper mill, and the urgent one ----------
update app.parties p
set do_not_contact = true,
    do_not_contact_reason = 'ADVERSE PARTY - live patent dispute. Co-filer with Taekyung Industrial of the competing patent family EP4579034 and its US/JP/KR counterparts, covering flexible calcium carbonate, the technology this company licenses. A Japanese opposition is in preparation for August 2026 and US/EP filings are already submitted. No cold email, no sequence enrolment, no deal, no contact_inquiry form. A web form submission would be worse than an email - it is deliberate, attributable, timestamped and archived by the recipient, which makes it a voluntary written disclosure to a litigation opponent on their own record. Any communication goes through counsel, not through this CRM. Review only when the dispute closes.',
    do_not_contact_set_at = now(),
    notes = coalesce(p.notes, '') || E'\n[adverse-party 2026-07-17] do_not_contact set. This row is a PAPER MILL, so it sits in the roster that holds 868 of 888 parties with a contact already, and the outreach machine there is live. It carried no marking at all until now because the adverse flag written on 2026-07-16 lived in app.filler_supplier_profile.extra_data, and a mill has no such profile. That gap is why migration_028 put the flag on app.parties instead.',
    updated_at = now()
where p.party_name ~* 'kleannara|깨끗한나라'
  and p.deleted_at is null
  and p.do_not_contact is false;


-- ---------- 2) Taekyung Industrial - the co-filer ----------
update app.parties p
set do_not_contact = true,
    do_not_contact_reason = 'ADVERSE PARTY - live patent dispute. Co-filer with Kleannara Co., Ltd. of the competing patent family EP4579034 and its US/JP/KR counterparts on flexible calcium carbonate. Japanese opposition in preparation for August 2026. No outreach of any kind through this CRM - counsel decides any contact. Its KFTC decision 2019-109 status and its Korean paper GCC market position remain accurate and useful for market analysis. Keep the intelligence. Send nothing.',
    do_not_contact_set_at = now(),
    updated_at = now()
where p.party_name ~* 'taekyung industrial|태경산업'
  and p.deleted_at is null
  and p.do_not_contact is false;


-- ---------- 3) Taekyung BK - same group, same building ----------
update app.parties p
set do_not_contact = true,
    do_not_contact_reason = 'ADVERSE PARTY BY GROUP - sister company of Taekyung Industrial, co-filer of EP4579034 with Kleannara on flexible calcium carbonate. Taekyung Group shares one HQ at the Songwon Building, 467 Gonghang-daero, Gangseo-gu, Seoul, so an approach to this row is an approach to the group in dispute. RETRACTS the ranking recorded on 2026-07-16, which put this row first among FCC licensing targets. That ranking was wrong: every field in filler_supplier_profile measures commercial fit and none measures conflict, so a ranking query returned a litigation opponent and nothing objected. The operational facts stay true - 60000 t/yr PCC at Danyang, on-site at Hansol Paper Janghang, own research institute publishing on calcium carbonate synthesis. That last item is why this is a competitor rather than a licensee. Counsel decides any contact.',
    do_not_contact_set_at = now(),
    updated_at = now()
where p.party_name ~* 'taekyung bk|태경비케이|baekkwang|백광소재'
  and p.deleted_at is null
  and p.do_not_contact is false;


-- ---------- 4) VERIFY - UNCOMMENTED. This is the whole point of the reissue. ----------
select p.party_name,
       p.party_type_id,
       p.do_not_contact,
       p.do_not_contact_set_at,
       left(coalesce(p.do_not_contact_reason, ''), 45) as reason_head,
       (select count(*) from app.contacts c
        where c.party_id = p.id and c.deleted_at is null) as contacts,
       (select count(*) from app.contacts c
        where c.party_id = p.id and c.deleted_at is null
          and nullif(btrim(c.email), '') is not null) as emails,
       (select count(*) from app.application_forms af
        where af.party_id = p.id) as form_rows,
       (select count(*) from app.email_sequence_enrollments e
        where e.party_id = p.id) as enrolments,
       (select count(*) from app.deals d
        where d.party_id = p.id and d.deleted_at is null) as deals,
       (select count(*) from app.party_supply_links s
        where s.filler_party_id = p.id or s.mill_party_id = p.id) as supply_links
from app.parties p
where p.deleted_at is null
  and (p.do_not_contact is true
       or p.party_name ~* 'kleannara|깨끗한나라|대한펄프|taekyung|태경')
order by p.do_not_contact desc, p.party_type_id, p.party_name;

-- HOW TO READ IT.
--
-- ✅ PASS: THREE rows, do_not_contact TRUE on all three, do_not_contact_set_at
--    carrying today's timestamp.
--      Kleannara               party_type_id 2  (paper mill)
--      Taekyung Industrial     party_type_id 3
--      Taekyung BK             party_type_id 3
--    If a fourth row appears with do_not_contact true, something else flagged it -
--    say so, that is new information.
--
-- ❌ FAIL, and it is the only failure that matters: a row still reading FALSE.
--    The three regexes are 'kleannara|깨끗한나라', 'taekyung industrial|태경산업'
--    and 'taekyung bk|태경비케이|baekkwang|백광소재'. If a row named differently
--    exists - 대한펄프, a Kleannara subsidiary, an English-only Taekyung entity -
--    it will show in this list with FALSE and no reason. SEND THE NAME BACK. It
--    gets its own statement rather than a widened regex, because a wide regex on
--    'taekyung' would catch unrelated Korean companies.
--
-- 🔴 THE COLUMNS THAT DECIDE WHETHER THIS WAS A CLOSE CALL OR AN INCIDENT:
--    enrolments · deals · form_rows · contacts · emails.
--    The original header claimed all three were clean and called it luck. It said
--    so BEFORE today, and today nine files ran against this roster. If enrolments
--    or deals is anything but 0 on ANY of the three rows, STOP - a live sequence
--    reaching the opposing party in a patent dispute two months before a Japanese
--    opposition is not a data-quality issue, it is a legal one, and the next call
--    is to counsel rather than to me.
--    supply_links is expected to be non-zero on Taekyung BK - it holds Hansol
--    Paper Janghang Mill. The flag does not remove the link and should not. The
--    pair is real and it is exactly the configuration FCC needs. It is simply the
--    one pair we cannot enter.
