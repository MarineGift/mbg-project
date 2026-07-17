-- ============================================================
-- fix_20microns_contact_2026-07-17.sql
--
-- Contacts 0, Email -, Contact method -, Form URL - on a company that publishes
-- all three on its own contact page. This is the shape of the whole filler
-- problem: 4 of 242 filler parties have a contact, and the information was never
-- missing, just never fetched.
--
-- FROM 20microns.com/contact-us, THE COMPANY'S OWN PAGE:
--   Industrial Minerals and Speciality Chemicals - www.20microns.com
--     enquiry@20microns.com        the business enquiry inbox
--   investors@20microns.com        investor relations
--   9-10, GIDC Industrial Estate, Waghodia - 391760, Dist. Vadodara, Gujarat
--   Tel +91 2668 292297 and +91 7574806350, toll free +91 1800 233 2735
--   "For product related assistance or inquiry submit your details below - Send"
--     -> a web form on the same page
--   Group: 20 Microns Nano Minerals (20nano.com, enquiry@20nano.com, filed a
--   DRHP for NSE EMERGE), 20 MCC and MinFert (20mcc.in, minfert.in),
--   Dorfner-20 Microns Private Limited (silcol.com) - a JV with Dorfner.
--
-- enquiry@20microns.com is corroborated on the company's LinkedIn and Facebook
-- pages, both of which publish it as the contact address.
--
-- WHY THIS COMPANY MATTERS FOR FCC
--   * makes PCC and GCC, and PaperIndex records it as an exporter of paper
--     coating pigments including coating-grade ground calcium carbonate
--   * already sells partial TiO2 replacement - a filler company whose customers
--     already buy "replace an expensive input with a mineral" needs no education
--     on the FCC argument, only on the mineral
--   * BSE and NSE listed, roughly 93m USD revenue, so DART-equivalent Indian
--     filings name officers if a named contact is wanted later
--   * India is a growth paper market and this is its largest white minerals
--     producer
--   * not Omya, not Specialty Minerals, not Taekyung, not Imerys
--
-- THE ADDRESS IS GENERIC AND STAYS THAT WAY. enquiry@ is an inbox, not a person.
-- full_name is left null - yesterday's derivation preview proved that naming a
-- generic local-part invents fictional people (geral.celbi became "Geral Celbi",
-- info.jkpaper became "Info Jkpaper" - 14 of 16 would have been wrong). One
-- deliberate message to one published inbox is fine. What is not fine is
-- pretending there is a person there.
--
-- contact_type_id 2 follows the observed convention - all 41 generic inboxes
-- found yesterday carry contact_type_id 2, without exception.
--
-- IDEMPOTENT. No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 1) The party: form URL, contact method, address ----------
update app.parties p
set contact_form_url         = 'https://www.20microns.com/contact-us',
    preferred_contact_method = 'web_form',
    city         = coalesce(p.city, 'Vadodara'),
    region       = coalesce(p.region, 'Gujarat'),
    country_code = coalesce(p.country_code, 'IN'),
    phone_e164   = coalesce(p.phone_e164, '+912668292297'),
    updated_at = now()
where p.party_name = '20 Microns Limited'
  and p.party_type_id = 3 and p.deleted_at is null;


-- ---------- 2) The published business enquiry inbox ----------
insert into app.contacts
  (organization_id, party_id, contact_type_id, email, is_primary, source, notes)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, p.id, 2,
       'enquiry@20microns.com', true, 'homepage',
       'GENERIC INBOX - not a person, full_name deliberately null. Published by the company on 20microns.com/contact-us as the contact for its Industrial Minerals and Speciality Chemicals business, and corroborated on its LinkedIn and Facebook pages. Address 9-10, GIDC Industrial Estate, Waghodia 391760, Dist. Vadodara, Gujarat. Tel +91 2668 292297, toll free +91 1800 233 2735. A web form sits on the same page - "For product related assistance or inquiry submit your details below" - so either door works. investors@20microns.com is the IR inbox and is NOT for this. Group inboxes exist for other entities and must not be used for FCC - enquiry@20nano.com for 20 Microns Nano Minerals, admin@20mcc.in, customercare@minfert.in, info@silcol.com for the Dorfner JV.'
from app.parties p
where p.party_name = '20 Microns Limited' and p.party_type_id = 3 and p.deleted_at is null
  and not exists (select 1 from app.contacts c
                  where c.party_id = p.id and c.email = 'enquiry@20microns.com' and c.deleted_at is null);


-- ---------- 3) The form row ----------
insert into app.application_forms
  (organization_id, party_id, form_url, form_type, submission_method,
   login_required, status, notes, created_by)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, p.id,
       'https://www.20microns.com/contact-us',
       'contact_inquiry', 'web_form', false, 'not_started',
       'Form sits on the same page as the published address, under "For product related assistance or inquiry submit your details below" with a Send button. FIELDS NOT RECORDED - nobody has opened the page and I will not guess labels or max_length, because guessing max_length defeats the variant selector entirely. Note this form is framed as PRODUCT ASSISTANCE, which reads like a sales queue. enquiry@20microns.com may be the better door here, and it costs nothing to try both.',
       coalesce(auth.uid(), (select pp.created_by from app.parties pp where pp.created_by is not null limit 1))
from app.parties p
where p.party_name = '20 Microns Limited' and p.party_type_id = 3 and p.deleted_at is null
  and not exists (select 1 from app.application_forms af
                  where af.party_id = p.id and af.form_type = 'contact_inquiry');


-- ---------- 4) Profile ----------
update app.filler_supplier_profile f
set extra_data = coalesce(f.extra_data, '{}'::jsonb) || '{"fcc_fit": {"verdict": "strong", "reason": "Produces PCC and GCC and exports paper coating pigments including coating-grade ground calcium carbonate. Already sells partial TiO2 replacement, so its customers already buy the argument that a mineral can displace an expensive input - the FCC conversation starts one step ahead. India is a growth paper market and this is its largest white minerals producer. Outside every exclusion.", "checked_at": "2026-07-17"}, "contactability": {"business_inbox": "enquiry@20microns.com", "ir_inbox": "investors@20microns.com", "form": "https://www.20microns.com/contact-us", "phone": "+91 2668 292297", "tollfree": "+91 1800 233 2735", "source": "20microns.com/contact-us, corroborated on the company LinkedIn and Facebook pages", "source_type": "marketing", "checked_at": "2026-07-17", "note": "The company publishes its contact routes openly. This party read Contacts 0 / Email - / Form URL - until today. The data was never missing, only unfetched."}, "group": {"listed": "BSE and NSE", "revenue_usd_m_approx": 93, "ceo_md": "Atil Parikh - from a third-party directory, NOT verified against a filing. Do not use without checking.", "entities": ["20 Microns Nano Minerals - 20nano.com, DRHP filed for NSE EMERGE", "20 MCC - 20mcc.in", "MinFert - minfert.in", "Dorfner-20 Microns Private Limited - silcol.com, JV with Dorfner"]}}'::jsonb,
    notes = coalesce(f.notes, '') || E'\n[contact 2026-07-17] Business enquiry inbox and contact form both recorded from the company''s own contact page. Listed on BSE and NSE, so Indian filings will name officers if a named human is wanted - the same route as DART for Taekyung. Atil Parikh appears as CEO and MD in a third-party directory and is NOT verified here.',
    updated_at = now()
from app.parties p
where f.party_id = p.id and p.party_name = '20 Microns Limited'
  and f.deleted_at is null and p.deleted_at is null
  and not (coalesce(f.extra_data, '{}'::jsonb) ? 'contactability');


-- ---------- 5) VERIFY ----------
-- select p.party_name, p.city, p.preferred_contact_method, p.contact_form_url,
--        c.email, c.full_name, c.is_primary,
--        af.form_type, af.status
-- from app.parties p
-- left join app.contacts c on c.party_id = p.id and c.deleted_at is null
-- left join app.application_forms af on af.party_id = p.id
-- where p.party_name = '20 Microns Limited';
-- EXPECT - Vadodara, web_form, the contact-us URL, enquiry@20microns.com with
-- full_name NULL, and one contact_inquiry form at not_started.
