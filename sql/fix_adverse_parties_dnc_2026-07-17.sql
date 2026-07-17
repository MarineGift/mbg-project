-- ============================================================
-- fix_adverse_parties_dnc_2026-07-17.sql
--
-- Sets do_not_contact on the three parties in the EP4579034 dispute.
--
--   Kleannara (깨끗한나라)                     party_type_id 2 - PAPER MILL
--   Taekyung BK Co. (태경비케이)               party_type_id 3
--   Taekyung Industrial Co. (태경산업)          party_type_id 3
--
-- Kleannara is the reason this needs to be on app.parties rather than on a
-- profile table. It sits in the paper mill roster, and per block 4 of
-- scan_form_system_state, 868 of 888 paper mills already have a contact. That
-- roster is the reachable one. An adverse party inside it, unmarked, is the
-- single most dangerous row in the database.
--
-- Nothing has gone out yet - all three show form_rows = 0 and the two Taekyung
-- rows have zero contacts. That is luck, not design, the same luck that spared
-- MTI and Specialty Minerals Inc. from entity_enrollment.
--
-- SUPERSEDES the extra_data flag written on 2026-07-16 into
-- app.filler_supplier_profile.extra_data.adverse_party. That flag stays as a
-- record but it only ever covered filler rows and it could not cover Kleannara.
-- The column is now the source of truth.
--
-- Depends on: migration_028_do_not_contact_2026-07-17.sql
-- Targeted by exact party_name. IDEMPOTENT. Reversible - set do_not_contact
-- false and clear the reason.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 0) PRE-FLIGHT (run separately) ----------
-- select id, party_name, party_type_id, do_not_contact,
--        (select count(*) from app.contacts c where c.party_id = p.id and c.deleted_at is null) as contacts,
--        (select count(*) from app.application_forms af where af.party_id = p.id) as form_rows,
--        (select count(*) from app.deals d where d.party_id = p.id and d.deleted_at is null) as deals
-- from app.parties p
-- where p.party_name ~* 'kleannara|깨끗한나라|대한펄프|taekyung|태경' and p.deleted_at is null;
-- EXPECT 3 rows, do_not_contact false, form_rows 0. If contacts or deals are
-- non-zero on any of them, STOP and tell me - something already reached them.


-- ---------- 1) Kleannara - the paper mill, and the urgent one ----------
update app.parties p
set do_not_contact = true,
    do_not_contact_reason = 'ADVERSE PARTY - live patent dispute. Co-filer with Taekyung Industrial of the competing patent family EP4579034 and its US/JP/KR counterparts, covering flexible calcium carbonate, the technology this company licenses. A Japanese opposition is in preparation for August 2026 and US/EP filings are already submitted. No cold email, no sequence enrolment, no deal, no contact_inquiry form. A web form submission would be worse than an email - it is deliberate, attributable, timestamped and archived by the recipient, which makes it a voluntary written disclosure to a litigation opponent on their own record. Any communication goes through counsel, not through this CRM. Review only when the dispute closes.',
    do_not_contact_set_at = now(),
    notes = coalesce(p.notes, '') || E'\n[adverse-party 2026-07-17] do_not_contact set. This row is a PAPER MILL, so it sits in the roster where 868 of 888 parties already have a contact and where the outreach machine is live. It carried no marking at all until now because the adverse flag written on 2026-07-16 lived in app.filler_supplier_profile.extra_data, and a mill has no such profile. That gap is why migration_028 put the flag on app.parties instead.',
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


-- ---------- 4) VERIFY ----------
-- select p.party_name, p.party_type_id, p.do_not_contact,
--        left(p.do_not_contact_reason, 60) as reason_head,
--        (select count(*) from app.contacts c where c.party_id = p.id and c.deleted_at is null) as contacts,
--        (select count(*) from app.application_forms af where af.party_id = p.id) as form_rows
-- from app.parties p
-- where p.do_not_contact is true and p.deleted_at is null
-- order by p.party_name;
-- EXPECT exactly 3 rows: Kleannara, Taekyung BK, Taekyung Industrial.


-- ---------- 5) DELETE THE RETRACTED FILE FROM THE REPO ----------
-- sql/enrich_taekyung_bk_fcc_fit_2026-07-16.sql is still sitting untracked in
-- the working tree. It ranks Taekyung BK as the number 1 FCC licensing target
-- and instructs "sequence the group, not the row". It must not be committed and
-- must not be run. From C:\dev\mbg-project -
--
--   Remove-Item -LiteralPath 'sql\enrich_taekyung_bk_fcc_fit_2026-07-16.sql' -Force
--
-- If it was already run, fix_taekyung_adverse_party_2026-07-16.sql corrects the
-- intro text and the fcc_fit verdict. This file plus that one leave the record
-- accurate either way.


-- ---------- 6) STILL NEEDED - two consumers of this flag ----------
-- The column is now the place to put the fact. Nothing reads it yet.
--   1. app.v_email_do_not_send should gain a do_not_contact branch. Adverse
--      parties belong in that view - it is a suppression list, and this is
--      suppression sourced from a decision rather than an event. Generic inboxes
--      still do not belong there: those are hygiene, and hygiene belongs at
--      enrolment. I will write the patch against the real definition rather than
--      from memory.
--   2. entity_enrollment must check the flag BEFORE creating a deal, a sequence
--      enrolment or a contact_inquiry form. Send me the source - grep for
--      entity_enrollment under src/lib - and I will read it instead of guessing.
