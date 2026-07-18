-- ============================================================
-- fix_domtar_emails_over_form_2026-07-17.sql
--
-- NO FORM ROW. FOURTH OF SIX COMPANIES WHERE THE SWEEP LIST WAS WRONG.
--
-- CONFIRMED DIRECTLY, domtar.com/contact-us, 2026-07-17. The contact page IS AN
-- EMAIL DIRECTORY. It publishes roughly SIXTEEN addresses, most with names and
-- titles. Our database holds ZERO for Domtar. Block 2 of the worklist scan said
-- all 24 multi-row brands have zero emails - International Paper, Kimberly-Clark,
-- WestRock, Georgia-Pacific, Oji, Nippon Paper, Domtar. That is now confirmed as
-- OUR GAP on at least one of them, and there is no reason to think Domtar is
-- special.
--
-- 🔴 THE FORM IS UNREADABLE, AND FOR A NEW REASON.
--   "Cookies must be accepted in order to view and access the contact form on
--    this page."
-- The page says it in plain text, and the only form asset on it is
-- info.domtar.com/l/396062/2023-05-30/cjzpwn - a PARDOT embed (Salesforce
-- Marketing Cloud Account Engagement). A server fetch sees an empty shell.
-- THE BLOCKER LIST IS NOW THREE DEEP and every one of them was found by opening
-- the page, not by querying:
--   HubSpot embed      Artemyn      - fields never read
--   Contact Form 7 captcha  SPB, TNPL  - human at a browser required
--   Pardot behind a cookie gate  Domtar  - fields never read
-- Three different vendors, three different failure modes, one consequence: the
-- form worklist cannot be built from a fetch for these companies.
--
-- WHY NO FORM ROW ANYWAY. The page hands out sixteen addresses. A cookie-gated
-- marketing-automation iframe is not the door when the company prints its own
-- directory above it.
--
-- ⭐ THE ARGUMENT THAT IS UNIQUE TO DOMTAR, and it is REASONING, NOT EVIDENCE.
-- Domtar sells MARKET PULP - Fluff Pulp and Papergrade Pulp are two of its five
-- product lines, with a named commercial representative and a dedicated contact
-- request page. It is an integrated producer: its own paper mills eat its own
-- pulp. FCC replaces pulp fibre with filler. AT AN INTEGRATED PRODUCER WITH A
-- MARKET PULP BUSINESS, EVERY TONNE OF FIBRE SAVED IN THE PAPER MILL BECOMES A
-- TONNE IT CAN SELL. The saving is not a cost line, it is a revenue line. No
-- other target on this roster has that shape - Hankuk, Andhra, TNPL and West
-- Coast all buy or make pulp for themselves alone.
-- ⛔ THIS IS NOT OFF A COMPANY PAGE. It is an economic argument built from their
-- product menu, and it depends on market pulp prices being worth having. Do not
-- put it in a letter as if Domtar said it. Yesterday Huber went in the mistake
-- log for exactly this - a market read placed above company material.
--
-- OWNERSHIP, and the part that is NOT confirmed. Domtar publishes a page titled
-- About Domtar Owner at domtar.com/about-jackson-wijaya - it is private, owned by
-- Jackson Wijaya, roughly 14,000 people, 60-plus facilities, and it absorbed
-- Resolute Forest Products. THE OPEN QUESTION NOBODY SHOULD ANSWER FROM MEMORY:
-- the China high-grade sweep list holds Gold East Paper, Gold Huasheng, Guangxi
-- Jingui, Hainan Jinhai and PT Indah Kiat, which are Asia Pulp and Paper mills.
-- Whether any ownership umbrella connects them to Domtar is NOT stated on any
-- company page read today, and the corporate separation there has been contested
-- in public. Record the question. Do not record an answer. The Andhra and West
-- Coast link was provable because six office addresses matched character for
-- character - this one has nothing like that behind it.
--
-- ⛔ NAMES PUBLISHED BUT NOT RECORDED. Seth Kursman, Blair Dickerson, Guillaume
-- Julien, Jan Martin, Dan Persica and Tammy Waters are all Public Affairs. Nancy
-- Klembus is General Counsel. Laura Ashley and Simon Zora sell packaging, Brian
-- Walsh and Jonathan Finch sell tissue, Beth Steck sells pulp, Lori Venn is at a
-- subsidiary. Real names, published with titles, and every one of them is the
-- wrong department for a process pitch. Recording thirteen people to write to
-- none of them is noise - the same call made on TNPL's nine marketers.
-- THERE IS NO R&D CONTACT ON THE PAGE. No technology contact. No innovation
-- contact. Same as Sylvamo. The two largest uncoated freesheet producers in North
-- America publish no route to anyone who could evaluate a process.
--
-- THE ROW TARGETING IS BY NAME AND IT IS DELIBERATE. The 248-company sweep list
-- returned only 'Domtar Cornwall', a mill row - the company row never reached the
-- list, so no uuid for it exists in anything sent back today. Every mill file in
-- sql/ targets by exact party_name and carries no uuid - fix_burgo_domain_verified
-- and fix_saica_wrong_contact both say so. The regexes below are tight: '^domtar'
-- for the URL, which every Domtar row honestly shares, and an anchored pattern
-- for the company row that cannot match 'Domtar Cornwall'. THE TRAILING SELECT
-- PRINTS EVERY DOMTAR ROW, so a miss or a double match is visible immediately
-- rather than silent.
--
-- Last statement is an UNCOMMENTED select. IDEMPOTENT.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================


-- ---------- 1) Three generic desks on the COMPANY row ----------
insert into app.contacts
  (organization_id, party_id, contact_type_id, email,
   given_name, family_name, full_name, title_text,
   is_primary, is_decision_maker, source, notes)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid,
       p.id, 2, v.email, null, null, null, v.title_text,
       v.is_primary, false, 'homepage', v.notes
from app.parties p
cross join (values
  ('CommercialPrinting@domtar.com', 'Paper Sales desk', true,
   'domtar.com/contact-us read directly 2026-07-17, listed under Sales / Paper Sales. Also shown on the Corporate Office Canada page. Generic desk, no name attached. It sells paper outward, which is the wrong direction, but it is the only address on the page that touches the paper business at all - every other one is public affairs, legal, tissue, packaging, pulp or careers.'),
  ('sustainability@domtar.com', 'Sustainability Department', false,
   'domtar.com/contact-us read directly 2026-07-17. Generic department desk. Worth having because the FCC case is a fibre and carbon case and Domtar publishes a 2025 Sustainability Report and a Climate, Carbon and Energy page. THE CAVEAT THAT APPLIES TO SYLVAMO TOO: sustainability at a company this size REPORTS, it does not run mill trials. It is a second door, not a first one.'),
  ('domtarcommunications@domtar.com', 'Website support and communications', false,
   'domtar.com/contact-us read directly 2026-07-17, printed twice - once under Support and once in the footer under Website Support. A catch-all. Recorded for completeness, not as a route.')
) as v(email, title_text, is_primary, notes)
where p.party_type_id = 2
  and p.deleted_at is null
  and p.do_not_contact is false
  and p.party_name ~* '^domtar( corporation| corp\.?| inc\.?)?$'
  and not exists (
    select 1 from app.contacts c
    where c.party_id = p.id and lower(c.email) = lower(v.email) and c.deleted_at is null);


-- ---------- 2) The company row: email is the door ----------
update app.parties p
set contact_form_url         = 'https://www.domtar.com/contact-us/',
    preferred_contact_method = 'email',
    notes = coalesce(p.notes, '') || E'\n[domtar-sweep 2026-07-17] Contact page opened and read. IT IS AN EMAIL DIRECTORY, roughly sixteen addresses, most with names and titles - and this database held zero. 🔴 THE FORM CANNOT BE READ: the page states in plain text that cookies must be accepted before the contact form is visible, and the only form asset on it is info.domtar.com/l/396062/2023-05-30/cjzpwn, a PARDOT embed. Third blocker class today after the Artemyn HubSpot embed and the Contact Form 7 captchas at SPB and TNPL. NO application_forms ROW - a cookie-gated marketing iframe is not the door when the company prints its own directory above it. NO R&D OR TECHNOLOGY CONTACT EXISTS ON THE PAGE, same as Sylvamo. The two largest North American uncoated freesheet producers publish no route to anyone who could evaluate a process. ⭐ ARGUMENT UNIQUE TO DOMTAR, and it is REASONING not evidence: Domtar sells MARKET PULP - fluff and papergrade, with its own commercial rep and contact page - and it is integrated, so its paper mills eat its own pulp. FCC replaces pulp fibre, which at an integrated producer with a market pulp business turns every tonne of fibre saved in the mill to a tonne it can SELL. The saving becomes revenue, not a cost line. No other target on the roster has that shape. ⛔ Domtar did not say this - do not put it in a letter as if it did. See the Huber entry in yesterday mistake log. OWNERSHIP: private, Jackson Wijaya, roughly 14,000 people, 60-plus facilities, absorbed Resolute Forest Products, and it publishes a page about its owner at domtar.com/about-jackson-wijaya. OPEN QUESTION, NOT AN ANSWER: the China high-grade sweep list holds Gold East Paper, Gold Huasheng, Guangxi Jingui, Hainan Jinhai and PT Indah Kiat, all Asia Pulp and Paper mills. No company page read today states any connection to Domtar and the separation there has been publicly contested. The Andhra and West Coast link was provable because six addresses matched character for character - this has nothing like that. NOT RECORDED: thirteen named people, all public affairs, legal, tissue, packaging or pulp. Wrong departments. NOT OPENED: domtar.com/resources/sales-and-purchase-policies and domtar.com/pulp/pulp-contact-request.',
    updated_at = now()
where p.party_type_id = 2
  and p.deleted_at is null
  and p.do_not_contact is false
  and p.party_name ~* '^domtar( corporation| corp\.?| inc\.?)?$'
  and coalesce(p.notes, '') not like '%[domtar-sweep 2026-07-17]%';


-- ---------- 3) Every Domtar mill row gets the URL, no form row ----------
update app.parties p
set contact_form_url         = 'https://www.domtar.com/contact-us/',
    preferred_contact_method = 'email',
    updated_at = now()
where p.party_type_id = 2
  and p.deleted_at is null
  and p.do_not_contact is false
  and p.party_name ~* '^domtar'
  and p.contact_form_url is null;
-- Mills share the corporate directory because it is the only door any of them
-- has. Same rule as Hansol's four and Sylvamo Saillat. No form rows - and here
-- there is no form row anywhere, because there is no readable form.


-- ---------- 4) VERIFY - uncommented, on purpose ----------
select p.party_name,
       p.country_code,
       p.preferred_contact_method,
       p.contact_form_url,
       (select count(*) from app.contacts c
        where c.party_id = p.id and c.deleted_at is null
          and nullif(btrim(c.email), '') is not null) as emails,
       (select string_agg(c.email, ' | ' order by c.is_primary desc, c.email)
        from app.contacts c
        where c.party_id = p.id and c.deleted_at is null
          and nullif(btrim(c.email), '') is not null) as which,
       (select count(*) from app.application_forms af
        where af.party_id = p.id and af.form_type = 'contact_inquiry') as form_rows,
       case when coalesce(p.notes, '') like '%[domtar-sweep 2026-07-17]%'
            then 'COMPANY ROW' else '' end as matched_company
from app.parties p
where p.party_type_id = 2
  and p.deleted_at is null
  and p.party_name ~* '^domtar'
order by p.party_name;
-- EXPECT roughly 11 rows, every one carrying domtar.com/contact-us and method
-- email, and form_rows 0 on ALL of them.
-- EXACTLY ONE row should read COMPANY ROW and carry emails 3. If ZERO do, the
-- company row is named something the regex misses - send the party_name list back
-- and the emails go on in one line. If TWO do, say so before anything else runs.
-- 'Domtar Cornwall' MUST show emails 0 and blank in the last column. It is a mill.
