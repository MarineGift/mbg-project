-- ============================================================
-- fix_spb_email_over_form_2026-07-17.sql
--
-- INDIA BATCH, 4 of 6. NO FORM ROW. Third company in a row where the sweep list
-- was wrong about the door.
--
-- CONFIRMED DIRECTLY, spbltd.com/contact-us/index.html, 2026-07-17:
--   * edoff@spbltd.com is published in the HEADER OF EVERY PAGE as a mailto link,
--     and again under Registered Office - Pallipalayam, Cauvery R.S P.O, Erode
--     638007, Tamilnadu, phone +91 4288 240221-240228, cable ESPEEBE.
--     edoff reads as EXECUTIVE DIRECTOR'S OFFICE. That is not a sales queue and
--     not a switchboard. It is the best door found in this batch.
--   * An "Enquiry" form does exist on the same page - WordPress Contact Form 7,
--     and it serves a CAPTCHA image out of wp-content/uploads/wpcf7_captcha/.
--   * Two units: Erode and Tirunelveli. Part of the SPB-ESVIN group, alongside
--     Ponni Sugars, High Energy Batteries and SPB Projects and Consultants.
--
-- 🔴 THE CAPTCHA IS A FACT THE FORM SYSTEM CANNOT HOLD.
-- application_form_fields.input_kind allows fill, check, select_option, upload.
-- There is no captcha member and there should not be one - a captcha means the
-- form CANNOT be submitted by anything except a human at a browser. Every form
-- registered today has quietly assumed otherwise. SPB is the first one that says
-- out loud that the worklist item is a person-task, not an automation target.
-- WORTH CHECKING ON THE OTHERS: Hankuk, Andhra and Hansol were all read server
-- side, and a captcha rendered client side would not have shown.
--
-- WHY NO application_forms ROW.
-- The form is real and its URL is recorded. It is not the door. edoff@ is an
-- executive office address published on every page - it has a reply-to, it makes
-- a thread, and it does not need a captcha solved. Creating a form row would put
-- a captcha-blocked task on a worklist for a company that publishes a better
-- door. Today's whole lesson is not to build worklist items for doors we should
-- not walk through.
-- contact_form_url IS still set, because the form existing is a fact.
-- preferred_contact_method is 'email', because which door to use is a judgment.
-- The two columns are allowed to disagree - parties_contact_form_url_chk only
-- forces a URL when the METHOD is web_form or portal, not the reverse.
--
-- ⛔ WHAT IS NOT RECORDED, AND WAS NOT INVENTED.
-- spbltd.com/locations lists three more addresses - mdoff@ (Managing Director's
-- office, 109 Nungambakkam High Road, Chennai), cmo@ (ASMA Building, TTK Road,
-- Alwarpet, Chennai) and spbtn@ (Madurai) - plus NAMED people with mobile
-- numbers. Those came back in a SEARCH SNIPPET of SPB's own page, not in a page I
-- fetched and read. mdoff@ is probably the single best address in this entire
-- India batch and it is not going in on a snippet. Open the page. Yesterday a
-- batch of 14 people was nearly invented out of local-parts, and
-- enrich_mlc_us_filler still owes a source check.
--
-- 🔴 THE INDIA SCORECARD, four companies in, and it indicts the list itself.
--   Andhra Paper   form only, zero emails anywhere      LIST WAS RIGHT
--   BILT x2        website was a New York fintech       LIST WAS WRONG
--   West Coast     eight emails, NO FORM AT ALL         LIST WAS WRONG
--   SPB            executive-office email, captcha form LIST WAS WRONG
-- The 248-company sweep list selects on "no email in OUR database". Three of four
-- publish emails openly. The filter measures our gap. Sweeping for forms is
-- finding inboxes, and that is a better outcome than the one asked for, but it
-- means the count of 248 form targets is not a count of form targets.
--
-- Last statement is an UNCOMMENTED select. IDEMPOTENT.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================


-- ---------- 1) The executive office address ----------
insert into app.contacts
  (organization_id, party_id, contact_type_id, email,
   given_name, family_name, full_name, title_text,
   is_primary, is_decision_maker, source, notes)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid,
       'a7721ae3-e761-4b31-a6aa-d7b7610df205'::uuid, 2,
       'edoff@spbltd.com',
       null, null, null,
       'Executive Director office - Registered Office, Erode mill',
       true, false, 'homepage',
       'spbltd.com/contact-us read directly 2026-07-17. Published as a mailto link in the header of EVERY page and again under Registered Office - Pallipalayam, Cauvery R.S P.O, Erode 638007, Tamilnadu, phone +91 4288 240221-240228, cable ESPEEBE. The local-part edoff reads as executive director office. NOT a sales queue. Generic desk, so no name is attached. The same page also carries a Contact Form 7 enquiry box behind a captcha - the address is the better door and the reason this party has no form row.'
where not exists (
  select 1 from app.contacts c
  where c.party_id = 'a7721ae3-e761-4b31-a6aa-d7b7610df205'::uuid
    and lower(c.email) = 'edoff@spbltd.com'
    and c.deleted_at is null);


-- ---------- 2) The form exists. The email is the door. ----------
update app.parties p
set contact_form_url         = 'https://www.spbltd.com/contact-us/index.html',
    preferred_contact_method = 'email',
    notes = coalesce(p.notes, '') || E'\n[spb-sweep 2026-07-17] Contact page opened and read. IT HAS BOTH. An Enquiry form (WordPress Contact Form 7) sits on spbltd.com/contact-us behind a CAPTCHA served out of wp-content/uploads/wpcf7_captcha/ - the field list was not readable and is NOT recorded. And edoff@spbltd.com, an executive director office address, is published in the header of every page. NO application_forms ROW ON PURPOSE: a captcha means the form is a human-at-a-browser task, and an executive office inbox beats it on every axis - reply-to, thread, and no puzzle. contact_form_url is set because the form is a fact. preferred_contact_method is email because the door is a judgment. PENDING, not recorded: spbltd.com/locations shows mdoff@ (Managing Director office, 109 Nungambakkam High Road, Chennai), cmo@ (ASMA Building, TTK Road, Alwarpet, Chennai) and spbtn@ (Madurai), plus named people with mobile numbers. Those came back in a search snippet of SPB own page, not a page I read. mdoff@ may be the best address in the India batch - open the page before adding it. Two units, Erode and Tirunelveli. SPB-ESVIN group, alongside Ponni Sugars, High Energy Batteries and SPB Projects and Consultants.',
    updated_at = now()
where p.id = 'a7721ae3-e761-4b31-a6aa-d7b7610df205'::uuid
  and p.party_type_id = 2
  and p.deleted_at is null
  and p.do_not_contact is false
  and coalesce(p.notes, '') not like '%[spb-sweep 2026-07-17]%';


-- ---------- 3) VERIFY - uncommented, on purpose ----------
select p.party_name,
       p.country_code,
       p.preferred_contact_method,
       p.contact_form_url,
       (select count(*) from app.contacts c
        where c.party_id = p.id and c.deleted_at is null
          and nullif(btrim(c.email), '') is not null) as emails,
       (select string_agg(c.email, ' | ' order by c.email) from app.contacts c
        where c.party_id = p.id and c.deleted_at is null
          and nullif(btrim(c.email), '') is not null) as which,
       (select count(*) from app.application_forms af
        where af.party_id = p.id and af.form_type = 'contact_inquiry') as form_rows,
       case when coalesce(p.notes, '') like '%[spb-sweep 2026-07-17]%'
            then 'note recorded' else 'NOTE MISSING' end as state
from app.parties p
where p.id = 'a7721ae3-e761-4b31-a6aa-d7b7610df205'::uuid;
-- EXPECT one row: Seshasayee Paper & Boards Ltd., IN, method email,
-- contact_form_url the spbltd contact page, emails 1 (edoff@spbltd.com),
-- form_rows 0, state 'note recorded'.
-- form_rows MUST be 0. If a form row appears, something else created it.
