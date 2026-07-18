-- ============================================================
-- scan_paper_mill_form_cohort_2026-07-17.sql
--
-- THE SAME SWEEP AS THE FILLER SIDE, POINTED AT THE MILL ROSTER.
--
-- WHAT IS ALREADY KNOWN, and where it came from.
--   * migration_028 block 4 counted 888 paper mill parties, 868 of them with a
--     contact - 97.7 percent. The mill roster is the reachable half of this
--     database. The filler roster is 4 of 242.
--   * migration_028 also recorded Kleannara at party_type_id = 2, calling it a
--     paper mill. Block 0 below re-proves that mapping rather than trusting it.
--   * Three committed batches wrote a bare marker row for mills whose only
--     public route is a web form - app.contacts with source = 'form',
--     email null, title_text 'Form 입력 (web contact form)':
--       paper-mill-contacts-batch2-KC-IP-form.sql   Kimberly-Clark 33 + IP 23
--       paper-mill-contacts-batch3-KR.sql           Hansol 5 + Hankuk 1
--       paper-mill-contacts-batch17-PT-independents.sql   Renova 1
--     Those rows predate migration_027. NOT ONE OF THEM CARRIES THE URL. The
--     database knows a form exists and does not know where it is.
--
-- THAT IS THE WHOLE GAP. 027 shipped contact_form_url, application_forms with
-- form_type contact_inquiry, and application_form_fields, and said in its own
-- header that it was generalizing the machinery to "any party that communicates
-- via a web form (mills included)". No mill has ever used it.
--
-- THE PART THAT NEEDS A HUMAN, not a query. Batch 2 recorded a form route for
-- 56 Kimberly-Clark and International Paper rows. Those are tissue and
-- containerboard producers. Filler loading on tissue is near zero and on
-- kraftliner it is near zero, because FCC earns its money by replacing pulp
-- fiber in grades that carry 15-25 percent filler - uncoated and coated
-- woodfree printing, copy and fine paper. Blocks 2 and 3 put the numbers on
-- that. If they hold, the mill form cohort is inverted exactly the way the
-- filler pipeline was yesterday - 56 rows of contact route on the wrong grades,
-- and a bare marker with no URL on the right ones.
--
-- DO NOT read the verdict off filler_use_intensity alone. Yesterday market_role
-- was wrong three times out of three on the filler side. Block 2 prints the
-- field next to main_products so the two can be compared, and the company page
-- decides.
--
-- READ-ONLY. Writes nothing. Run each block SEPARATELY.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================


-- ---------- 0) PROVE THE TYPE MAPPING - do not trust the 2 ----------
select t.id, t.code, t.category, t.label_en, t.label_ko,
       (select count(*) from app.parties p
        where p.party_type_id = t.id and p.deleted_at is null) as parties
from app.party_types t
order by t.id;
-- Expect a row whose label says paper mill. Note its id. Every block below uses
-- 2 for that. If the id is NOT 2, stop and tell me - every number after this is
-- wrong and so is every fix file built on it.


-- ---------- 1) THE FORM COHORT - who was marked, and what is missing ----------
select p.id, p.country_code, p.party_name,
       p.website,
       p.preferred_contact_method,
       p.contact_form_url,
       (select count(*) from app.application_forms af
        where af.party_id = p.id and af.form_type = 'contact_inquiry') as form_rows,
       m.main_product_category,
       m.filler_use_intensity,
       m.evidence_level
from app.parties p
left join app.paper_mill_profile m on m.party_id = p.id and m.deleted_at is null
where p.party_type_id = 2
  and p.deleted_at is null
  and exists (select 1 from app.contacts c
              where c.party_id = p.id and c.source = 'form' and c.deleted_at is null)
order by p.country_code, p.party_name;
-- EXPECT roughly 63 rows, every one with contact_form_url null, preferred_
-- contact_method null and form_rows 0. That is the gap this handoff closes.
-- If any row already carries a URL, tell me - something else has been writing.


-- ---------- 2) IS THE COHORT ON THE RIGHT GRADES ----------
select coalesce(m.filler_use_intensity, '(null)') as filler_intensity,
       coalesce(m.main_product_category, '(null)') as category,
       count(*) as mills,
       string_agg(p.party_name, ' | ' order by p.party_name) as who
from app.parties p
left join app.paper_mill_profile m on m.party_id = p.id and m.deleted_at is null
where p.party_type_id = 2
  and p.deleted_at is null
  and exists (select 1 from app.contacts c
              where c.party_id = p.id and c.source = 'form' and c.deleted_at is null)
group by 1, 2
order by count(*) desc, 1, 2;
-- THE QUESTION THIS ANSWERS. If Kimberly-Clark and International Paper land on
-- tissue and containerboard, then 56 of the 63 form-route rows are recorded
-- against grades that do not buy filler, and the rule broken is the one saved
-- eight times yesterday - do not record a contact route on a non-target.


-- ---------- 3) THE INVERSE - high filler grades with no form route ----------
select p.id, p.country_code, p.party_name,
       m.filler_use_intensity, m.main_product_category, m.main_products,
       p.contact_form_url,
       (select count(*) from app.contacts c
        where c.party_id = p.id and c.deleted_at is null and c.email is not null) as email_contacts,
       (select count(*) from app.contacts c
        where c.party_id = p.id and c.deleted_at is null and c.source = 'form') as form_markers
from app.parties p
join app.paper_mill_profile m on m.party_id = p.id and m.deleted_at is null
where p.party_type_id = 2
  and p.deleted_at is null
  and coalesce(m.filler_use_intensity, '') ~* 'high'
order by p.country_code, p.party_name;
-- The FCC-relevant mills. Compare this list against block 1. Anything here with
-- an email contact does not need a form at all - the form is the slow door and
-- is only worth opening where there is no other one.


-- ---------- 4) THE COMPANY / PLANT SPLIT INSIDE THE COHORT ----------
select case when p.party_name ~ ' - ' then 'plant row' else 'company row' end as row_kind,
       count(*) as rows_in_cohort
from app.parties p
where p.party_type_id = 2
  and p.deleted_at is null
  and exists (select 1 from app.contacts c
              where c.party_id = p.id and c.source = 'form' and c.deleted_at is null)
group by 1
order by 1;
-- WHY THIS MATTERS AND IS NOT PEDANTRY. contact_form_url is a property of a
-- party and every plant of a group honestly shares the group form, so the URL
-- belongs on all of them. An application_forms row is a WORKLIST ITEM. One
-- corporate form registered against 13 International Paper mill rows is 13
-- copies of one task, and fix_azolla_duplicate_form_2026-07-10 exists because
-- duplicate forms have already cost a day once.
-- RULE TAKEN FROM THIS: URL on every row of the group, form row on the company
-- row only.


-- ---------- 5) HANSOL - which row is the company ----------
select p.id, p.party_type_id, p.party_name, p.country_code, p.website,
       p.domain_normalized, p.contact_form_url, p.preferred_contact_method,
       (select count(*) from app.contacts c
        where c.party_id = p.id and c.deleted_at is null) as contacts,
       (select count(*) from app.party_supply_links s where s.mill_party_id = p.id) as filler_links
from app.parties p
where p.deleted_at is null and p.party_name ~* 'hansol|한솔'
order by p.party_type_id, p.party_name;
-- THE ONE ANSWER I NEED BACK. Batch 3 marked five Hansol rows - Cheonan,
-- Daejeon, Janghang, Shintanjin, Papertech. fix_supply_link_taekyung_enrich
-- uses 890ae7ee as mill_party_id for Janghang, so those four are MILL rows, not
-- the company. hansolpaper.co.kr/customer/inquiry is 한솔제지(주)'s form and the
-- counterparty for a materials licence is the company, not a machine hall.
-- If no company-level Hansol Paper row exists, creating one is a human decision
-- and I am not making it in a fix file.
-- SEPARATELY: Hansol Papertech runs its OWN domain, hansolpapertech.co.kr. Batch
-- 3 gave it the same 'Form 입력 (고객문의)' marker as the four mills. It has not
-- been swept and must not inherit the 한솔제지 URL.


-- ---------- 6) HANKUK - confirm the row before the fix file writes ----------
select p.id, p.party_type_id, p.party_name, p.country_code, p.website,
       p.domain_normalized, p.contact_form_url, p.preferred_contact_method,
       p.do_not_contact,
       m.main_product_category, m.filler_use_intensity, m.evidence_level
from app.parties p
left join app.paper_mill_profile m on m.party_id = p.id and m.deleted_at is null
where p.deleted_at is null and (p.party_name ~* 'hankuk paper|한국제지' or p.id = '028f9b56-3780-4bb2-91f4-ca3514025484'::uuid)
order by p.party_name;
-- EXPECT 028f9b56 = Hankuk Paper Mfg, party_type_id 2, do_not_contact false.
-- fix_hankuk_paper_contact_form_2026-07-17 writes against exactly that id.
-- If do_not_contact errors with 42703, migration_028 is committed but NOT
-- applied - run it first. That is the plant_supply_links trap again.
-- 한국제지 merged 세하(주) in August 2023. If a separate 세하 row exists it is now
-- the same company and is a merge decision, not a query result.


-- ---------- 7) THE ADVERSE PARTY IS IN THIS ROSTER ----------
select p.id, p.party_name, p.country_code, p.party_type_id,
       p.do_not_contact, p.do_not_contact_reason,
       p.contact_form_url,
       (select count(*) from app.application_forms af where af.party_id = p.id) as form_rows,
       (select count(*) from app.contacts c
        where c.party_id = p.id and c.deleted_at is null) as contacts
from app.parties p
where p.deleted_at is null
  and (p.do_not_contact is true or p.party_name ~* 'kleannara|깨끗한나라|taekyung|태경')
order by p.party_type_id, p.party_name;
-- migration_028 was written for this exact row. Kleannara is a paper mill AND
-- the other side of the EP4579034 family. Every mill form file after this one
-- carries `and p.do_not_contact is false`, and this block is what proves the
-- flag is actually set before that guard means anything.
-- If do_not_contact is still false on Kleannara, fix_adverse_parties_dnc has not
-- run and the guard is decoration.
