-- ============================================================
-- fix_wcpm_emails_and_andhra_link_2026-07-17.sql
--
-- INDIA BATCH, 3 of 6. NO FORM IS CREATED, AND THE REASON MATTERS MORE THAN A
-- FORM WOULD HAVE.
--
-- 🔴 THE SWEEP LIST IS BUILT ON A FILTER THAT IS WRONG HERE.
-- Block 3 of scan_paper_mill_sweep_worklist selected 248 companies on the rule
-- "no email in the database, so a form is the only door". West Coast Paper Mills
-- passed that filter. Its own contact page, fetched 2026-07-17, publishes EIGHT
-- addresses and NO FORM AT ALL:
--     sales.ho@westcoastpaper.com    Corporate Office, 31 Jawaharlal Nehru Road,
--                                    Kolkata 700016, tel 033 71500 500
--     pro@westcoastpaper.com         Regd Office and Works, Bangur Nagar Dandeli
--     wcpm.north@                    New Delhi
--     wcpm.east@                     Kolkata
--     wcpm.west@                     Mumbai
--     wcpm.south@                    Chennai
--     wcpm.south2@                   Bengaluru
--     wcpm.south3@                   Hyderabad
-- The database said no email. The company says eight. THE FILTER MEASURED OUR
-- GAP, NOT THEIR DOOR. Some unknown share of the other 247 are the same, and
-- every one of them is a homepage that would be opened looking for a form that
-- does not exist. Sweeping for forms finds emails.
--
-- ⭐ AND THE SIX ADDRESSES ANSWER THE QUESTION I LEFT OPEN THIS MORNING.
-- fix_andhra_paper_contact_form said: Saurabh Bangur chairs Andhra Paper and also
-- chairs West Coast Paper Mills, both are in today's India six, if one group then
-- India is not six companies - UNCONFIRMED, do not merge on that note.
-- IT IS NOW CONFIRMED, off BOTH companies' OWN contact pages, and it is not a
-- name overlap. It is the same desks.
--
--   HYDERABAD - character for character
--     Andhra  "Door No.1-89/3/B/40 to 42/KS/107/A, 1st Floor, MSR Block,
--              Krishe Sapphire Building, Hi Tech City Main Road, Madhapur,
--              Hyderabad -500081"
--     WCPM    "D No.1-89/3/B/40 to 42/KS/107/A, 1st Floor, MSR Block,
--              Krishe Sapphire Building, Hi-Tech City Main Road, Madhapur,
--              Hyderabad -500081"
--   KOLKATA   Andhra 31 Chowringee Road 700016, tel +91-33-71500500
--             WCPM   31 Jawaharlal Nehru Road 700016, tel 033 71500 500
--             Chowringhee Road WAS RENAMED Jawaharlal Nehru Road. SAME PHONE.
--   NEW DELHI Andhra "6 E, 6th Floor, Hansalaya Building, 15 Barakhamba Road",
--                    tel +91-11-40110101
--             WCPM   "6 C, D, E, Hansalaya Building, 15 Barakhamba Road",
--                    tel (011) 40110101          SAME PHONE.
--   MUMBAI    both Free Press House, 2nd Floor, 215 Nariman Point 400021
--   CHENNAI   both 23/1 Kanakasri Nagar, Off Cathedral Road 600086
--   BENGALURU both Chandrakiran, 4th Floor, 10/A Kasturba Road 560001
--
-- SIX offices shared. TWO phone numbers shared outright. ANDHRA PAPER AND WEST
-- COAST PAPER MILLS RUN ONE SALES ORGANISATION. India's six rows are: BILT twice
-- (one company, out on timing), Andhra and WCPM (one commercial group), SPB, TNPL.
-- FOUR targets, and one of them answers for two mills.
--
-- 🔴 THE PART THAT INVERTS THIS MORNING'S WORK. Andhra Paper publishes ZERO email
-- addresses across eight offices. West Coast publishes eight, AT THE SAME DESKS.
-- wcpm.south3@westcoastpaper.com is answered in the same Hyderabad room as Andhra
-- Paper's Hyderabad office. I built Andhra a procurement vendor form this morning
-- and it is still its published door - but the better door to Andhra may be West
-- Coast's inbox, one company over, with a reply-to and a thread.
--
-- ⛔ WHAT I DID NOT DO, AND WHY IT WOULD HAVE BEEN THE SAICA BUG.
-- I did NOT attach any westcoastpaper.com address to Andhra Paper. Shared desks
-- are not shared mailboxes, and the whole point of fix_saica_wrong_contact is
-- that a string match put an Italian competitor's inbox on a Spanish mill. Same
-- building is a weaker link than a similar name, not a stronger one. The finding
-- is recorded as a NOTE on both rows. Merging or linking them is a human decision.
--
-- GRADE, off WCPM's own product menu: printing and writing 52 to 120 gsm,
-- business stationery, premium printing, security and hi-value grades, cup stock
-- and coated duplex 230 to 600 gsm, MG 80 to 250 gsm. FIFTY-TWO GSM printing
-- paper is lighter than Andhra's 65 and every point of opacity in it comes out of
-- filler. It also runs a 750 TPD Metso ECF fibre line and publishes an R&D/QC
-- page and a Latest Tender page - three doors better than a dropdown.
--
-- NO NAMES ARE INVENTED. All eight are generic desks, recorded as such, with
-- full_name null - the rule that held eight times yesterday.
--
-- Last statement is an UNCOMMENTED select. IDEMPOTENT.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================


-- ---------- 1) WCPM: the eight desks, exactly as published ----------
insert into app.contacts
  (organization_id, party_id, contact_type_id, email,
   given_name, family_name, full_name, title_text,
   is_primary, is_decision_maker, source, notes)
select v.organization_id, v.party_id, v.contact_type_id, v.email,
       null, null, null, v.title_text,
       v.is_primary, false, 'homepage', v.notes
from (values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'3596af41-c22c-420b-b4b4-52f44188afe3'::uuid,2,
   'sales.ho@westcoastpaper.com','Corporate Office sales desk - Kolkata',true,
   'westcoastpaper.com/contact 2026-07-17. Corporate Office, 31 Jawaharlal Nehru Road, Kolkata 700016, tel 033 71500 500. Also shown in the site header on every page. Generic sales desk - it sells paper outward. Right company, and probably the wrong department for a licence.'),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'3596af41-c22c-420b-b4b4-52f44188afe3'::uuid,2,
   'pro@westcoastpaper.com','Registered Office and Works - Dandeli mill',false,
   'westcoastpaper.com/contact 2026-07-17. Bangur Nagar, Dandeli 581325, Uttara Kannada, Karnataka, tel 08284-231391-395. THE MILL ITSELF. pro likely means public relations officer, so treat it as a switchboard rather than a technical desk - but it is the only address on the site that sits at the paper machines.'),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'3596af41-c22c-420b-b4b4-52f44188afe3'::uuid,2,
   'wcpm.north@westcoastpaper.com','Zonal - North, New Delhi',false,
   'westcoastpaper.com/contact 2026-07-17. 6 C D E Hansalaya Building, 15 Barakhamba Road, New Delhi 110001, tel (011) 40110101. SAME BUILDING AND SAME PHONE as Andhra Paper north office.'),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'3596af41-c22c-420b-b4b4-52f44188afe3'::uuid,2,
   'wcpm.east@westcoastpaper.com','Zonal - East, Kolkata',false,
   'westcoastpaper.com/contact 2026-07-17. 31 Chowringhee Road, Kolkata 700016, tel 033 2226 4451. Andhra Paper east office is also 31 Chowringee Road, Kolkata 700016.'),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'3596af41-c22c-420b-b4b4-52f44188afe3'::uuid,2,
   'wcpm.west@westcoastpaper.com','Zonal - West, Mumbai',false,
   'westcoastpaper.com/contact 2026-07-17. Free Press House, Office Nos 23 to 24, 2nd Floor, 215 Nariman Point, Mumbai 400021. Andhra Paper west office is Free Press House, 2nd Floor, 215 Nariman Point.'),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'3596af41-c22c-420b-b4b4-52f44188afe3'::uuid,2,
   'wcpm.south@westcoastpaper.com','Zonal - South 1, Chennai',false,
   'westcoastpaper.com/contact 2026-07-17. 23/1 Kanakasri Nagar, St George Cathedral Lane, Off Cathedral Road, Chennai 600086. Andhra Paper Tamil Nadu office is 23/1 Kanakasri Nagar, Off Cathedral Road, Chennai 600086.'),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'3596af41-c22c-420b-b4b4-52f44188afe3'::uuid,2,
   'wcpm.south2@westcoastpaper.com','Zonal - South 2, Bengaluru',false,
   'westcoastpaper.com/contact 2026-07-17. Chandrakiran, 4th Floor, 10/A Kasturba Road, Bangalore 560001. Andhra Paper Karnataka office is Chandrakiran 10/A, 4th Floor, Kasturba Road, Bengaluru 560001.'),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'3596af41-c22c-420b-b4b4-52f44188afe3'::uuid,2,
   'wcpm.south3@westcoastpaper.com','Zonal - South 3, Hyderabad (AP and Telangana)',false,
   'westcoastpaper.com/contact 2026-07-17. D No 1-89/3/B/40 to 42/KS/107/A, 1st Floor, MSR Block, Krishe Sapphire Building, Hi-Tech City Main Road, Madhapur, Hyderabad 500081. THE EXACT DOOR NUMBER Andhra Paper publishes for its own Hyderabad office. This desk is in the room with Andhra Paper. Do NOT record it as an Andhra contact - shared desks are not shared mailboxes.')
) as v(organization_id, party_id, contact_type_id, email, title_text, is_primary, notes)
where not exists (
  select 1 from app.contacts c
  where c.party_id = v.party_id and lower(c.email) = lower(v.email) and c.deleted_at is null
);


-- ---------- 2) WCPM: email is the method, and there is no form ----------
update app.parties p
set preferred_contact_method = 'email',
    notes = coalesce(p.notes, '') || E'\n[wcpm-sweep 2026-07-17] Contact page opened. NO CONTACT FORM EXISTS on westcoastpaper.com/contact - eight published email desks and nothing else. This row reached the 248-company sweep list because our database held no email, not because the company hides one. contact_form_url stays null on purpose. SHARED SALES NETWORK WITH ANDHRA PAPER, confirmed off both companies own contact pages: six identical office addresses (Hyderabad door number identical character for character, plus Kolkata, New Delhi, Mumbai, Chennai, Bengaluru) and two identical phone numbers (033-71500500 and 011-40110101). Saurabh Bangur chairs both. Merging or linking the two parties is a human decision and is not made here. Grade: printing and writing 52 to 120 gsm, business stationery, security grades, cup stock and coated duplex 230 to 600 gsm. A 52 gsm sheet buys its opacity with filler. Better doors than any inbox above: westcoastpaper.com/technology/rd-qc and westcoastpaper.com/latest-tender and westcoastpaper.com/management-team - none opened yet.',
    updated_at = now()
where p.id = '3596af41-c22c-420b-b4b4-52f44188afe3'::uuid
  and p.party_type_id = 2
  and p.deleted_at is null
  and p.do_not_contact is false
  and coalesce(p.notes, '') not like '%[wcpm-sweep 2026-07-17]%';


-- ---------- 3) Andhra: record the link, add NO email ----------
update app.parties p
set notes = coalesce(p.notes, '') || E'\n[wcpm-link 2026-07-17] SHARES ITS ENTIRE INDIAN SALES OFFICE NETWORK WITH WEST COAST PAPER MILLS (party 3596af41). Six offices identical off both companies own contact pages - Hyderabad (Krishe Sapphire, MSR Block, door 1-89/3/B/40 to 42/KS/107/A, identical character for character), Kolkata, New Delhi, Mumbai, Chennai, Bengaluru - plus two shared phone numbers, 033-71500500 and 011-40110101. Saurabh Bangur chairs both. This company was International Paper APPM until IP exited. CONSEQUENCE FOR OUTREACH: Andhra publishes ZERO email addresses across eight offices while West Coast publishes EIGHT at the same desks. The become-our-supplier form recorded on this row is Andhra own published door and stays, but the faster door to the same building may be a West Coast address. ⛔ NO westcoastpaper.com ADDRESS HAS BEEN ATTACHED TO THIS ROW. Shared desks are not shared mailboxes - see fix_saica_wrong_contact - a string match mailed a Spanish mill approach to an Italian competitor. Merging these two parties is a human decision.',
    updated_at = now()
where p.id = '6ad04789-209f-4df1-b185-24a50c60717d'::uuid
  and p.party_type_id = 2
  and p.deleted_at is null
  and coalesce(p.notes, '') not like '%[wcpm-link 2026-07-17]%';


-- ---------- 4) VERIFY - uncommented, on purpose ----------
select p.party_name,
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
       case when coalesce(p.notes, '') ~ 'wcpm-sweep 2026-07-17|wcpm-link 2026-07-17'
            then 'note recorded' else 'NOTE MISSING' end as state
from app.parties p
where p.id in (
        '3596af41-c22c-420b-b4b4-52f44188afe3'::uuid,  -- West Coast Paper Mills Ltd.
        '6ad04789-209f-4df1-b185-24a50c60717d'::uuid   -- Andhra Paper Limited
      )
order by p.party_name;
-- EXPECT
--   West Coast Paper Mills   method email · form url null · emails 8 · forms 0
--   Andhra Paper Limited     method web_form · become-our-supplier url · emails 0
--                            · forms 1
-- ANDHRA MUST STILL SHOW ZERO EMAILS. If it shows any westcoastpaper.com address,
-- something attached a neighbour's inbox to it and that is the bug this file went
-- out of its way not to commit.
