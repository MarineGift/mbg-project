-- ============================================================
-- fix_andhra_paper_contact_form_2026-07-17.sql
--
-- INDIA BATCH, 1 of 6. The first non-Korean mill form in this database, and a
-- DOOR TYPE THAT DID NOT EXIST IN THE FILLER SWEEP.
--
-- CONFIRMED DIRECTLY, 2026-07-17:
--   contact page  https://andhrapaper.com/contact-us/
--   THE FORM      https://andhrapaper.com/become-our-supplier/
--   also          /enquiries-product-query-page/ and /enquiries-sample-request/
--   dealer portal http://ipaper.force.com/ (Salesforce, login)
--   units         Rajahmundry and Kadiam, Andhra Pradesh
--   offices       Kolkata HQ, plus Delhi, Mumbai, Bengaluru, Kochi, Chennai,
--                 Hyderabad - all listed with phone numbers
--
-- THE CONTACT PAGE PUBLISHES NOT ONE EMAIL ADDRESS. Eight offices, two mills,
-- fifteen phone numbers, zero mailboxes. The database said Andhra Paper has no
-- email and the database was right - this is one of the 248 where a form really
-- is the only public door, not the lazy door.
--
-- WHY THIS FORM AND NOT THE OTHER TWO. Andhra publishes three enquiry forms.
-- Product Query and Sample Request are for people BUYING paper. Become Our
-- Supplier is for people selling INTO the mill. FCC is the second thing.
-- The company put the door in its own menu and labelled it.
--
-- BUT READ THE DROPDOWN BEFORE CELEBRATING. Supplier Interest offers:
--     Chemicals · Fuels · Maintenance Spare Parts · Packaging ·
--     Services & Contractors · Waste Paper · Wood
-- There is no minerals option, no pigments option, no technology option and no
-- R&D option. Filler is procured as a wet-end chemical at most mills, so
-- Chemicals is the only plausible pick - but this list is a PROCUREMENT VENDOR
-- REGISTRATION. It routes to purchasing. FCC is a licence and a process, not a
-- drum of something with a price per tonne, and purchasing has no authority over
-- either.
-- THIS IS THE ARTEMYN QUESTION AGAIN, and the honest answer is the same as
-- Hansol's: there is no right option, only a least-wrong one. Recorded as the
-- door because it IS the door the company published. Whether it is the RIGHT
-- door is section 5 and it is not settled by this file.
--
-- GRADE FIT, off its own product menu, which is the only evidence that counts:
--   SS Maplitho - Primavera, TruPrint, CCS, Writechoice, Splendor, Pearlwhite
--   Copier - Reflection 65 / 70 / 75 / 80 / 100 GSM, SuperPrint
--   plus poster, cupstock, pharma print, thermal base, coating base
-- Copier paper at 65 to 80 GSM is the most filler-loaded grade in commercial
-- papermaking. A 65 GSM sheet that still has to be opaque is carrying every
-- point of filler it can hold. That is the FCC argument in one product line, and
-- the database already knew: grade UWF, filler_relevance high.
--
-- TWO THINGS I FOUND AND DID NOT WRITE, because they are not mine to decide.
--   1. Andhra Paper WAS International Paper APPM. IP took 75 percent in 2011,
--      renamed it in December 2013, and later exited. Saurabh Bangur appears as
--      chairman - the same name as West Coast Paper Mills, which is ALSO in
--      today's India six. If those two are one group, India is not six companies.
--      NOT CONFIRMED off either company page. Do not merge on my say-so.
--   2. Ballarpur Industries and BILT Sewa Unit are both bilt.com. Two rows, one
--      company, same shape as Ashapura yesterday. A merge is a human decision.
--
-- IDEMPOTENT. No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================


-- ---------- 1) The party: form URL and contact method ----------
update app.parties p
set contact_form_url         = 'https://andhrapaper.com/become-our-supplier/',
    preferred_contact_method = 'web_form',
    updated_at = now()
where p.id = '6ad04789-209f-4df1-b185-24a50c60717d'::uuid
  and p.party_type_id = 2
  and p.deleted_at is null
  and p.do_not_contact is false;


-- ---------- 2) THE FORM ROW ----------
insert into app.application_forms
  (organization_id, party_id, form_url, form_type, submission_method,
   login_required, status, notes, created_by)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid,
       p.id,
       'https://andhrapaper.com/become-our-supplier/',
       'contact_inquiry',
       'web_form',
       false,
       'not_started',
       'INDIA BATCH 1 of 6. First non-Korean mill form. A SUPPLIER REGISTRATION, which is a door type the filler sweep never met - Artemyn, Zantat and the rest all had generic contact pages. Andhra publishes three enquiry forms and only this one faces inward: Product Query and Sample Request are for buying paper. THE PROBLEM WITH IT, stated so nobody discovers it at submission time: Supplier Interest offers Chemicals, Fuels, Maintenance Spare Parts, Packaging, Services and Contractors, Waste Paper, Wood. No minerals, no pigments, no technology, no R&D. Filler is bought as a wet-end chemical so Chemicals is the pick, but this routes to PURCHASING, and purchasing cannot license a process. Least-wrong option, same verdict as Hansol. GRADE, off its own menu: SS Maplitho and Reflection copier at 65 to 100 GSM. A 65 GSM copier sheet that must stay opaque carries every point of filler it can - that is the whole argument, sitting in their product list. CONTACT PAGE HAS ZERO EMAIL ADDRESSES across eight offices and two mills, only phones, so the form is genuinely the only public door. FIELDS ARE REAL, read off the live page. MAX_LENGTH IS NOT - WordPress theme, attributes not readable, a browser must capture them. History: this was International Paper APPM until IP exited. Saurabh Bangur chairs it and also chairs West Coast Paper Mills, which is also in today India six - if one group, India is not six companies. Unconfirmed, do not merge on this note.',
       coalesce(auth.uid(), (select pp.created_by from app.parties pp where pp.created_by is not null limit 1))
from app.parties p
where p.id = '6ad04789-209f-4df1-b185-24a50c60717d'::uuid
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
  (10, 'Supplier Name', 'text', null::int, true,
       'Our company name. The form calls the sender a supplier throughout - the frame is vendor registration, not a technical approach.',
       'fill', null),
  (20, 'Contact Person Name', 'text', null::int, true, null, 'fill', null),
  (30, 'Contact Address', 'text', null::int, false, null, 'fill', null),
  (40, 'City', 'text', null::int, false, null, 'fill', null),
  (50, 'Contact No.', 'text', null::int, true,
       'Mandatory. An Indian mill calling a US number is a real outcome - decide who answers before this is submitted.',
       'fill', null),
  (60, 'E-Mail', 'text', null::int, true,
       'Mandatory, and this is the reply path. The form has no reply-to of its own.',
       'fill', null),
  (70, 'Supplier Interest', 'dropdown', null::int, true,
       'Options as published: an empty placeholder, then Chemicals / Fuels / Maintenance Spare Parts / Packaging / Services & Contractors / Waste Paper / Wood. PICK Chemicals - filler is procured as a wet-end chemical and there is no minerals, pigments, technology or R&D option. It is the least-wrong pick, not a right one. This list is a purchasing taxonomy and purchasing cannot sign a licence.',
       'select_option', null),
  (80, 'Brief Description', 'textarea', null::int, false,
       'The only free-text field on the form. NOT marked mandatory, which means the whole argument lives in an optional box. max_length UNKNOWN and it matters most here - the short / medium / long variant is chosen against it. There is NO subject field, so the opening line of this box is the subject.',
       'fill', 'fcc_inquiry_intro')
) as v(seq, label, field_type, max_length, is_required, help_text, input_kind, canonical_key)
where f.party_id = '6ad04789-209f-4df1-b185-24a50c60717d'::uuid
  and f.form_type = 'contact_inquiry'
  and not exists (
    select 1 from app.application_form_fields ff
    where ff.form_id = f.id and ff.seq = v.seq);


-- ---------- 4) VERIFY ----------
-- select p.party_name, p.preferred_contact_method, p.contact_form_url,
--        af.form_type, af.status,
--        (select count(*) from app.application_form_fields ff where ff.form_id = af.id) as fields
-- from app.parties p
-- join app.application_forms af on af.party_id = p.id and af.form_type = 'contact_inquiry'
-- where p.id = '6ad04789-209f-4df1-b185-24a50c60717d'::uuid;
-- EXPECT one row, web_form, not_started, 8 fields.
-- 'Success. No rows returned' proves nothing - run this.


-- ---------- 5) THE OPEN QUESTION THIS FILE DOES NOT ANSWER ----------
-- Is a procurement vendor form the right door for a licence.
-- ARGUMENT FOR: it is the door Andhra published for inbound sellers, it reaches
--   a real queue, and Chemicals lands with the people who already buy filler.
--   Those people know what the mill pays per tonne for PCC today, which is the
--   only number that makes FCC interesting to them.
-- ARGUMENT AGAINST: purchasing evaluates price against a spec that already
--   exists. FCC has no spec at this mill and no line item. Hankuk's route was
--   better because its FAQ promised a MEETING at step one. Andhra promises a
--   vendor record.
-- THE THIRD PATH: andhrapaper.com/apl-management-team/ names the senior
--   leadership team. Yesterday's conclusion holds - a named technical contact
--   beats a dropdown every time. That page has not been opened yet.
-- Do not submit this form until that page has been read.
