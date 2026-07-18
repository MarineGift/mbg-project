-- ============================================================
-- fix_sylvamo_contact_form_2026-07-17.sql
--
-- THE PUREST TARGET ON THE ROSTER, and its form says something uncomfortable.
--
-- WHY SYLVAMO IS THE TARGET. Block 2 of the worklist scan: 7 rows, filler
-- relevance HIGH ON ALL SEVEN, one company-level row, zero emails. Sylvamo
-- Corporation (NYSE: SLVM) was spun out of International Paper in 2021 and does
-- ONE THING - uncoated freesheet. Its own site calls it "the world's paper
-- company", 6,500 colleagues, $3.7bn of 2023 net sales, mills in Europe, Latin
-- America and North America, brands Rey, Hammermill, Chamex, Accent Opaque,
-- Springhill, Williamsburg, HP Papers, Pro-Design, Jetstar, Chambril.
-- UNCOATED FREESHEET IS THE GRADE FCC EXISTS FOR. There is no company on this
-- roster whose entire revenue sits in the target band the way Sylvamo's does.
-- THE COUNTRY VIEW HID IT. Block 4 sorted by country and Sylvamo splits across
-- BR, SE, US and FR - it never appeared in any country's top line. Block 2 found
-- it by brand. Sorting a roster by geography hides the companies that are global.
--
-- CONFIRMED DIRECTLY, sylvamo.com/us/en/contact-us, 2026-07-17:
--   Server-rendered, fully readable, EXPLICIT REQUIRED MARKERS - the page states
--   "* indicates Required Fields". FIRST FORM TODAY WITH REAL is_required DATA.
--   Hankuk, Andhra, Hansol and TNPL all had markers that were absent, ambiguous
--   or contradicted by their own privacy notices.
--   NO CAPTCHA. First non-Korean mill form today without one.
--   Phones published: corporate 1-901-519-8000, product 1-800-472-6109.
--
-- 🔴 THE TOPIC DROPDOWN, and it is the emptiest one yet:
--     Branding · Careers · Community Engagement
--     Customer Support - North America / Latin America / Europe
--     Ethics & Compliance · Government Relations · Investor Relations
--     Media Relations · Sustainability · Supplier Diversity · Other
--   NO research. NO technology. NO innovation. NO procurement. NO supplier.
--
--   ⛔ SUPPLIER DIVERSITY IS NOT OUR OPTION AND MUST NOT BE USED. It is a
--   programme for minority-owned, women-owned and comparable businesses. Picking
--   it to reach purchasing would be claiming a status we do not hold, to a
--   Fortune-listed company, in writing, on an ethics-and-compliance-adjacent
--   form. That is not a shortcut, it is a misrepresentation.
--
--   That leaves Other, or Sustainability. Sustainability is genuinely arguable -
--   FCC's case is that filler replaces pulp fibre, and less fibre is less wood
--   and less energy, and Sylvamo publishes 2030 Goals and a 2025 Sustainability
--   Performance Review. The counter is that sustainability at a listed company is
--   a REPORTING function, not an evaluating one - it writes the review, it does
--   not run mill trials. Other is honest and lands nowhere in particular.
--   RECORDED RECOMMENDATION: Other. Weakly held. This is the Artemyn question for
--   the fourth time and the answer keeps being the same.
--
-- ⭐ THE FINDING THAT IS BIGGER THAN THE FORM. SYLVAMO PUBLISHES NO R&D.
-- Its entire menu: About Us · Where We Are · Our Brands · Copy and Printer Papers
-- · Commercial Printing Papers · Converting Papers · Specialty Papers ·
-- Sustainability · Careers · Investors. There is no technology page, no R&D page,
-- no innovation page, no laboratory. Compare what the sweep has already found:
--   Hankuk     publishes an R&D page AND a supply procedure that promises a meeting
--   West Coast publishes an R&D/QC page and a tender page
--   TNPL       publishes a research centre routing option
--   Artemyn    publishes Par Moor, a paper and board laboratory
-- The company with the highest grade fit on the roster has the fewest technical
-- doors. Its own homepage explains why: "Our exclusive focus on the promise of
-- paper enables us to create long-term value for shareowners." IP spun it out in
-- 2021 to return cash on a mature asset, not to develop processes.
-- THE READ, and it is a hypothesis rather than a verdict: a company with no R&D
-- either licenses instead of building, or does not evaluate at all. Those are
-- opposite conclusions and this file does not settle which. What is certain is
-- that the form is the only published door, and it routes to communications.
--
-- NOT RECORDED, NOT INVENTED. hans.bjorkman@sylvamo.com appears as investor
-- relations in Sylvamo press-release boilerplate republished by a trade site. It
-- was NOT read off sylvamo.com, and IR is the wrong department for a process
-- pitch. sylvamo.com/us/en/sales-and-purchase-policies sits in the footer and has
-- not been opened - if any procurement door exists, it starts there.
-- max_length: not readable. Fifth company in a row.
--
-- THIS ROW IS THE COMPANY, NOT A MILL. da71948a is party_name 'Sylvamo'.
-- e0457d0e is 'Sylvamo Saillat-sur-Vienne', a French mill row, and it does NOT
-- get a form - one corporate form, one worklist item.
--
-- Last statement is an UNCOMMENTED select. IDEMPOTENT.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================


-- ---------- 1) The party ----------
update app.parties p
set contact_form_url         = 'https://www.sylvamo.com/us/en/contact-us',
    preferred_contact_method = 'web_form',
    updated_at = now()
where p.id = 'da71948a-39aa-4b3d-913a-7b8e44275167'::uuid
  and p.party_type_id = 2
  and p.deleted_at is null
  and p.do_not_contact is false;


-- ---------- 2) THE FORM ROW ----------
insert into app.application_forms
  (organization_id, party_id, form_url, form_type, submission_method,
   login_required, status, notes, created_by)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid,
       p.id,
       'https://www.sylvamo.com/us/en/contact-us',
       'contact_inquiry',
       'web_form',
       false,
       'not_started',
       'THE PUREST GRADE FIT ON THE ROSTER. Sylvamo Corporation, NYSE SLVM, spun out of International Paper in 2021, 6,500 colleagues, 3.7bn USD 2023 net sales, and it makes ONE THING - uncoated freesheet. Seven rows in this database, filler relevance high on all seven. The country-sorted view never surfaced it because it splits across BR, SE, US and FR. FIRST FORM TODAY WITH REAL REQUIRED MARKERS - the page states that an asterisk indicates required fields - and the FIRST non-Korean one with NO CAPTCHA. 🔴 THE TOPIC DROPDOWN HAS NO TECHNICAL DOOR: Branding, Careers, Community Engagement, three Customer Support regions, Ethics and Compliance, Government Relations, Investor Relations, Media Relations, Sustainability, Supplier Diversity, Other. ⛔ DO NOT PICK SUPPLIER DIVERSITY - it is a programme for minority-owned and women-owned businesses and claiming it would be a misrepresentation in writing. Pick Other. Sustainability is arguable, since FCC replaces pulp fibre and Sylvamo publishes 2030 Goals, but sustainability at a listed company reports rather than evaluates. ⭐ AND SYLVAMO PUBLISHES NO R&D AT ALL - no technology page, no lab, nothing, while Hankuk publishes an R&D page, West Coast an R&D/QC page, TNPL a research routing option and Artemyn the Par Moor paper and board lab. Its homepage says its exclusive focus on paper creates long-term value for shareowners. IP spun it out to return cash on a mature asset. Either it licenses rather than builds, or it does not evaluate - opposite conclusions, unsettled. NOT OPENED: sylvamo.com/us/en/sales-and-purchase-policies, the only procurement-shaped page on the site. max_length not readable on any field.',
       coalesce(auth.uid(), (select pp.created_by from app.parties pp where pp.created_by is not null limit 1))
from app.parties p
where p.id = 'da71948a-39aa-4b3d-913a-7b8e44275167'::uuid
  and p.party_type_id = 2
  and p.deleted_at is null
  and p.do_not_contact is false
  and not exists (
    select 1 from app.application_forms af
    where af.party_id = p.id and af.form_type = 'contact_inquiry');


-- ---------- 3) THE FIELDS - required flags are REAL here ----------
insert into app.application_form_fields
  (organization_id, form_id, seq, label, field_type, max_length,
   is_required, help_text, input_kind, canonical_key)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid,
       f.id, v.seq, v.label, v.field_type, v.max_length,
       v.is_required, v.help_text, v.input_kind, v.canonical_key
from app.application_forms f
cross join (values
  (10, 'First Name', 'text', null::int, true, null, 'fill', null),
  (20, 'Last Name', 'text', null::int, true, null, 'fill', null),
  (30, 'Email', 'text', null::int, true,
       'The reply path. Sylvamo publishes no inbox on this page - two phone numbers and this form.',
       'fill', null),
  (40, 'Region', 'dropdown', null::int, true,
       'Options as published: North America / Latin America / Europe / Asia. Sylvamo has no Asian mills, so Asia routes somewhere unknown. Pick the region of the mill being addressed, not of the sender.',
       'select_option', null),
  (50, 'Topic', 'dropdown', null::int, true,
       'Options as published: Branding / Careers / Community Engagement / Customer Support - North America / Customer Support - Latin America / Customer Support - Europe / Ethics & Compliance / Government Relations / Investor Relations / Media Relations / Sustainability / Supplier Diversity / Other. NO research, NO technology, NO procurement. ⛔ SUPPLIER DIVERSITY IS NOT AN OPTION FOR US - it is a minority-owned and women-owned business programme and claiming it would be a misrepresentation. PICK Other. Sustainability is the arguable alternative and it reports rather than evaluates.',
       'select_option', null),
  (60, 'Message', 'textarea', null::int, false,
       'NOT required, and the required markers on this page are real. The entire argument goes in an optional box with no subject line above it. max_length UNKNOWN.',
       'fill', 'fcc_inquiry_intro'),
  (70, 'Phone', 'text', null::int, false, null, 'fill', null)
) as v(seq, label, field_type, max_length, is_required, help_text, input_kind, canonical_key)
where f.party_id = 'da71948a-39aa-4b3d-913a-7b8e44275167'::uuid
  and f.form_type = 'contact_inquiry'
  and not exists (
    select 1 from app.application_form_fields ff
    where ff.form_id = f.id and ff.seq = v.seq);


-- ---------- 4) The French mill row gets the URL, NOT a form ----------
update app.parties p
set contact_form_url         = 'https://www.sylvamo.com/us/en/contact-us',
    preferred_contact_method = 'web_form',
    updated_at = now()
where p.id = 'e0457d0e-8072-47c6-8663-a18892ce40bc'::uuid  -- Sylvamo Saillat-sur-Vienne
  and p.party_type_id = 2
  and p.deleted_at is null
  and p.do_not_contact is false
  and p.contact_form_url is null;
-- Saillat-sur-Vienne is a MILL. It shares the corporate form because that is the
-- only door it has, so the URL is true of it. It does not get a form row - one
-- corporate form is one task, not two. Same rule as Hansol's four mills.


-- ---------- 5) VERIFY - uncommented, on purpose ----------
select p.party_name,
       p.country_code,
       p.preferred_contact_method,
       p.contact_form_url,
       coalesce(af.form_type, '(none - correct for the mill row)') as form_type,
       af.status,
       (select count(*) from app.application_form_fields ff where ff.form_id = af.id) as fields
from app.parties p
left join app.application_forms af
  on af.party_id = p.id and af.form_type = 'contact_inquiry'
where p.id in (
        'da71948a-39aa-4b3d-913a-7b8e44275167'::uuid,  -- Sylvamo (company)
        'e0457d0e-8072-47c6-8663-a18892ce40bc'::uuid   -- Sylvamo Saillat-sur-Vienne (mill)
      )
order by p.party_name;
-- EXPECT two rows, both carrying the sylvamo.com contact URL and web_form.
--   Sylvamo                     contact_inquiry · not_started · FIELDS 7
--   Sylvamo Saillat-sur-Vienne  (none) · null · 0
-- If the mill row has a form, one corporate task became two.
