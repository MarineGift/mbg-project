-- ============================================================
-- fix_tnpl_contact_form_2026-07-17.sql
--
-- INDIA BATCH, 5 of 6. THE SWEEP LIST WAS RIGHT ABOUT THIS ONE, and this is the
-- best dropdown found in thirty-odd companies across two rosters.
--
-- ⭐ THE FINDING. TNPL's Area of Assistance dropdown, read off the live page:
--     Marketing - Paper · Marketing - Packaging Board · Marketing - Tissue Paper
--     Export - Paper · Export - Packaging Board · Marketing - Cement
--     Marketing - Eco-friendly GreenPal Notebooks
--     Potential Supplier
--     Farmer / Potential Supplier-Wood
--     INSTITUTES / UNIVERSITY / RESEARCH CENTER          <-- THIS ONE
--     Job Seeker · Human Resource · Investor / Shareholder
--     Grievance Redressal · Corporate Info
--
-- EVERY OTHER DROPDOWN SWEPT SO FAR HAD NO RESEARCH OPTION.
--   Hansol      전체 / 제품 / 한솔루션 / 투자 / 채용 / 기타
--   Hankuk      제품문의 / 구입문의 / 시험성적요청문의 / 채용문의 / 사보 / 기타문의
--   Andhra      Chemicals / Fuels / Spares / Packaging / Services / Waste Paper / Wood
--   Artemyn     unknown, HubSpot embed, never read
-- Each time the verdict was the same - no right option, only a least-wrong one,
-- and every least-wrong option routed to sales or to purchasing. TNPL publishes a
-- door to its research centre and a SEPARATE door for Potential Supplier. It is
-- the first form in this project where the correct option is not a compromise.
--
-- WHICH ONE IS OURS IS A REAL CHOICE, not a formality:
--   Institutes / University / Research Center - FCC is a process and a licence.
--     This routes to people who evaluate technology. But it may be built for
--     academic collaboration and student projects, and a company arriving through
--     it may be filed as a university.
--   Potential Supplier - honest about the commercial intent, and routes to
--     procurement, which is where Andhra's form ends and why that door is weak.
-- The Institutes option is recorded as the recommendation. Not settled.
--
-- 🔴 CAPTCHA. AGAIN. wp-content/uploads/wpcf7_captcha/1372320393.png - Contact
-- Form 7 with the captcha add-on, exactly like SPB an hour ago. TWO OF TWO
-- WordPress Indian mills. The captcha is recorded BELOW AS A FIELD rather than as
-- a comment, so v_application_field_status shows the blocker instead of hiding
-- it. A captcha means a human at a browser. No automation reaches this form.
--
-- NO REQUIRED MARKERS WERE RENDERED on any field. is_required is false on all
-- seven, which is what the page shows, not what the form probably enforces. A
-- browser will find asterisks that a server fetch does not. Do not read the
-- falses as confirmed.
--
-- max_length: NOT READABLE, null on every field. Fourth company in a row.
--
-- A SECOND DOOR, from the footer, NOT registered here:
--   tnpl.com/tnpl-vendor-registration-form/  New Vendor/Supplier Enrollment
--   tnpl.com/tenders/                        public tenders
-- TNPL IS OWNED BY THE GOVERNMENT OF TAMIL NADU. CIN L22121TN1979PLC007799. A
-- state enterprise buys through tender, and an unsolicited supply proposal has
-- nowhere to land in that process. That is exactly why the RESEARCH door matters
-- more here than at a private mill - it is the one entrance that is not
-- procurement, and procurement is the one that a government company cannot bend.
--
-- WHAT IS NOT RECORDED. The contact page names NINE marketing people with mobile
-- numbers and no emails - Saravana S AGM Mktg at the corporate office, Anant G.
-- Hegde DGM Mktg Bangalore, Arunkumar P DGM Mktg Ernakulam, T. N. Prasanna Kumar
-- CM Marketing Secunderabad, Anish DGM Mktg and Ganesh Shirodhkar CM Mktg Mumbai,
-- Sachin A Basarge CM Mktg Ahmedabad, Bijendar Sharma AGM Marketing Delhi, Rajib
-- B CM Mktg Kolkata. Real names, published by the company. They are ALL
-- MARKETING - they sell paper outward, which is the wrong department, and mobile
-- numbers are not an outreach channel this system has. Recording nine people to
-- contact none of them is noise. Separate decision.
--
-- THE PAGE READS "Last updated on: 17-Jul-2026, 17:51" - TODAY. This roster row
-- said TNPL has no email. TNPL published its contact page hours ago with zero
-- email addresses on it. THE DATABASE WAS RIGHT ABOUT THIS ONE.
-- India scorecard, five companies in: the list was right about Andhra and TNPL,
-- and wrong about BILT, West Coast and SPB. Two of five.
--
-- Last statement is an UNCOMMENTED select. IDEMPOTENT.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================


-- ---------- 1) The party ----------
update app.parties p
set contact_form_url         = 'https://tnpl.com/contact-us/',
    preferred_contact_method = 'web_form',
    updated_at = now()
where p.id = 'd3d18246-80e7-4f60-9aef-20c22713f75a'::uuid
  and p.party_type_id = 2
  and p.deleted_at is null
  and p.do_not_contact is false;


-- ---------- 2) THE FORM ROW ----------
insert into app.application_forms
  (organization_id, party_id, form_url, form_type, submission_method,
   login_required, status, notes, created_by)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid,
       p.id,
       'https://tnpl.com/contact-us/',
       'contact_inquiry',
       'web_form',
       false,
       'not_started',
       'INDIA BATCH 5 of 6. THE BEST DROPDOWN IN THE PROJECT. Area of Assistance carries INSTITUTES / UNIVERSITY / RESEARCH CENTER - the first research route found across roughly thirty companies on two rosters. Hansol, Hankuk, Andhra and Artemyn all had no research option and every least-wrong pick routed to sales or purchasing. It also carries Potential Supplier as a separate option, so the choice is real: Institutes reaches people who evaluate technology but may be built for academic collaboration, Potential Supplier is honest about intent but lands in procurement. RECOMMENDATION - Institutes. NOT settled. 🔴 CAPTCHA - Contact Form 7 with the captcha add-on, recorded below as field seq 70 so the blocker is visible rather than buried. A human at a browser is required. Second captcha today after SPB, and both are WordPress. NO REQUIRED MARKERS RENDERED - is_required false on all seven is what the page shows, not what it enforces. max_length not readable on any field. TNPL IS OWNED BY THE GOVERNMENT OF TAMIL NADU, CIN L22121TN1979PLC007799, bagasse-based, two paper units at Kagithapuram Karur and Mondipatti Tiruchirappalli plus a cement plant. A state enterprise buys through tender - tnpl.com/tenders - so an unsolicited supply proposal has nowhere to land, which is exactly why the research door matters more here than at a private mill. SECOND DOOR not registered: tnpl.com/tnpl-vendor-registration-form. The contact page names nine marketing people with mobiles and no emails - all marketing, all outbound, deliberately not recorded.',
       coalesce(auth.uid(), (select pp.created_by from app.parties pp where pp.created_by is not null limit 1))
from app.parties p
where p.id = 'd3d18246-80e7-4f60-9aef-20c22713f75a'::uuid
  and p.party_type_id = 2
  and p.deleted_at is null
  and p.do_not_contact is false
  and not exists (
    select 1 from app.application_forms af
    where af.party_id = p.id and af.form_type = 'contact_inquiry');


-- ---------- 3) THE FIELDS - read off the live page ----------
insert into app.application_form_fields
  (organization_id, form_id, seq, label, field_type, max_length,
   is_required, help_text, input_kind, canonical_key)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid,
       f.id, v.seq, v.label, v.field_type, v.max_length,
       v.is_required, v.help_text, v.input_kind, v.canonical_key
from app.application_forms f
cross join (values
  (10, 'Area of Assistance', 'dropdown', null::int, false,
       'Fifteen options behind a department placeholder: Marketing - Paper / Marketing - Packaging Board / Marketing - Tissue Paper / Export - Paper / Export - Packaging Board / Marketing - Cement / Marketing - Eco-friendly GreenPal Notebooks / Potential Supplier / Farmer or Potential Supplier-Wood / INSTITUTES - UNIVERSITY - RESEARCH CENTER / Job Seeker / Human Resource / Investor or Shareholder / Grievance Redressal / Corporate Info. PICK Institutes / University / Research Center. It is the only research route found on any mill or filler form so far. Potential Supplier is the alternative and it lands in procurement, which at a government company means the tender process.',
       'select_option', null),
  (20, 'Name', 'text', null::int, false, null, 'fill', null),
  (30, 'Email', 'text', null::int, false,
       'The reply path. The form has none of its own and TNPL publishes no email address anywhere on this page.',
       'fill', null),
  (40, 'Phone number', 'text', null::int, false, null, 'fill', null),
  (50, 'Address', 'text', null::int, false, null, 'fill', null),
  (60, 'Message', 'textarea', null::int, false,
       'The only free-text field. No subject field exists, so the opening line carries the subject. max_length UNKNOWN and it matters most here - the short / medium / long variant is picked against it.',
       'fill', 'fcc_inquiry_intro'),
  (70, 'Captcha', 'text', null::int, true,
       '🔴 THE BLOCKER, recorded as a field on purpose. Contact Form 7 captcha add-on, image served out of tnpl.com/wp-content/uploads/wpcf7_captcha/. input_kind has no captcha member and should not - the correct reading is that this form CANNOT be submitted by anything except a person at a browser. is_required is true here on judgment, not on a marker: a captcha that can be skipped is not a captcha.',
       'fill', null)
) as v(seq, label, field_type, max_length, is_required, help_text, input_kind, canonical_key)
where f.party_id = 'd3d18246-80e7-4f60-9aef-20c22713f75a'::uuid
  and f.form_type = 'contact_inquiry'
  and not exists (
    select 1 from app.application_form_fields ff
    where ff.form_id = f.id and ff.seq = v.seq);


-- ---------- 4) VERIFY - uncommented, on purpose ----------
select p.party_name,
       p.country_code,
       p.preferred_contact_method,
       p.contact_form_url,
       af.form_type,
       af.status,
       (select count(*) from app.application_form_fields ff where ff.form_id = af.id) as fields,
       (select ff.help_text from app.application_form_fields ff
        where ff.form_id = af.id and ff.seq = 70) is not null as captcha_recorded,
       (select count(*) from app.contacts c
        where c.party_id = p.id and c.deleted_at is null
          and nullif(btrim(c.email), '') is not null) as emails
from app.parties p
left join app.application_forms af
  on af.party_id = p.id and af.form_type = 'contact_inquiry'
where p.id = 'd3d18246-80e7-4f60-9aef-20c22713f75a'::uuid;
-- EXPECT one row: TNPL, IN, web_form, tnpl.com/contact-us/, contact_inquiry,
-- not_started, FIELDS 7, captcha_recorded true, emails 0.
-- emails 0 is CORRECT here and is the point - TNPL updated this page today and
-- published no address on it. The roster was right about this one.
