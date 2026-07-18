-- ============================================================
-- fix_bilt_wrong_website_2026-07-17.sql
--
-- INDIA BATCH, 2 of 6. NO FORM IS CREATED. Opening the page was the point.
--
-- THE SAICA BUG AGAIN, IN THE WEBSITE COLUMN THIS TIME.
--
--   Ballarpur Industries Ltd.  ->  website  https://www.bilt.com
--   BILT Sewa Unit             ->  website  https://www.bilt.com
--
-- www.bilt.com IS BILT TECHNOLOGIES, INC. - a New York rent-rewards fintech.
-- Fetched 2026-07-17: the page sells points on rent payments, Bilt Card, Lyft
-- and Walgreens partners, and its footer reads "Bilt Payments LLC (NMLS ID
-- 2527740) - Bilt Mortgages LLC (NMLS ID 2676904)". There is no paper on it.
--
-- Ballarpur Industries is Indian, founded 1945 by Lala Karamchand Thapar, and
-- ITS OWN SEBI FILING says where it lives. The letterhead of its 30 December
-- 2024 trading-window notice to NSE and BSE, hosted on the domain itself at
-- biltpaper.in/wp-content/uploads/2024/12/Closure-of-Trading-Window.pdf, reads:
--     "CIN: L21010MH1945PLC010337 · Regd Address: 602, Boston House, 6th Floor,
--      Suren Road, Andheri East, Mumbai 400093 · Tel.: 022-4000 2600
--      Email: sectdiv@biltpaper.in  Website: www.biltpaper.in"
-- biltpaper.in is live and its footer reads "© 2024 Ballarpur Industries
-- Limited. All Rights Reserved."
-- THIS IS NOT A GUESSED REPLACEMENT. It is the company's own regulatory filing,
-- served from the domain in question. The Saica rule holds - do not invent a
-- replacement - and it is not being broken here.
--
-- WHEN IT MOVED: an OLDER BILT filing still shows "Email: info@bilt.com Website:
-- www.bilt.com". The domain changed hands between filings. That is exactly how
-- this contamination is invisible - the roster was right once.
--
-- 🔴 info@bilt.com MUST NEVER BE MAILED. It resolves to the fintech now. Nobody
-- has mailed it because these two rows have no contact - which is the only
-- reason this is a near miss and not a repeat of Saica, where a Spanish mill's
-- approach was pointed at an Italian competitor's live inbox. Here the recipient
-- would have been a US consumer-credit company. Had anyone swept bilt.com for a
-- contact form, they would have recorded a rent-rewards signup as an Indian
-- paper mill's door. Two of India's six high-grade targets pointed at it.
--
-- THE VERDICT: NOT A FORM TARGET. NOT NOW.
-- BILT was once India's largest writing and printing producer - 375,000 TPA, over
-- 50 percent of the coated woodfree market, 85 percent of bond. Then NCLT Mumbai
-- admitted it to CIRP on 17 January 2020. Finquest Financial Solutions' plan was
-- approved 31 March 2023, equity trading was suspended 23 June 2023, and the
-- company confirmed completion of the CIRP at its 80th AGM on 11 MAY 2026 - nine
-- weeks ago - with the Shree Gopal unit at Yamuna Nagar restarting. Employees:
-- 189. A company nine weeks out of a six-year insolvency, restarting one mill
-- under a financial owner, does not license a filler technology. It has no capex
-- and no R&D. The grade fit is perfect and the timing is absurd.
-- REVISIT IN A YEAR. If Shree Gopal runs and Finquest recapitalises, the same
-- grade logic makes BILT a top-five Indian target again.
--
-- ⭐ AND THE THING WORTH MORE THAN THE FORM WOULD HAVE BEEN.
-- Minerals Technologies' own press release, filed with the SEC on 23 April 2009:
--   "Specialty Minerals Inc. has entered into an agreement with Ballarpur
--    Industries Limited (BILT) to construct a satellite precipitated calcium
--    carbonate (PCC) facility at BILT's Ballarshah Unit in the state of
--    Maharashtra, India... approximately 65,000 metric tons of PCC per year...
--    owned by a newly formed joint venture company, SMI NewQuest India Private
--    Ltd."
-- A SATELLITE PCC PLANT INSIDE AN INDIAN MILL, JOINTLY OWNED BY SMI. The
-- satellite operator list in this database runs Specialty Minerals, Taekyung BK,
-- Double A, Fimatec, Artemyn, Gulshan, Mississippi Lime. SMI NewQuest India is
-- not on it, and a joint venture is a different animal from a wholly owned
-- satellite - it means BILT took equity in its own filler supply.
-- STATUS UNKNOWN. 2009 is seventeen years ago and the company has been through
-- CIRP since. Recorded as a lead, not a fact. This belongs in the satellite work,
-- not the form work.
--
-- ALSO: BILT Sewa Unit is not BILT. Wikipedia and bgppl.com place Sewa, Ballarpur,
-- Bhigwan and Ashti under BILT Graphic Paper Products Ltd (bgppl.com) after an
-- internal restructuring. Two rows, two legal entities, one wrong domain on both.
-- The merge-or-split call is a human decision - same as Ashapura yesterday.
--
-- NEW CONVENTION STARTS HERE: the last statement is an UNCOMMENTED select.
-- Supabase shows the final result set, so this file answers its own question and
-- 'Success. No rows returned' cannot happen. It has been the answer three times
-- today and meant nothing each time.
--
-- IDEMPOTENT. No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================


-- ---------- 1) Remove the contaminated website, both rows ----------
update app.parties p
set website = 'https://www.biltpaper.in',
    domain_normalized = 'biltpaper.in',
    notes = coalesce(p.notes, '') || E'\n[bilt-domain-contamination 2026-07-17] website was https://www.bilt.com. THAT DOMAIN IS BILT TECHNOLOGIES INC, a New York rent-rewards fintech - fetched and read, it sells points on rent payments and its footer carries NMLS licence numbers. It is not Ballarpur Industries. Replaced with www.biltpaper.in, taken out of BILT''s OWN 30 Dec 2024 trading-window notice to NSE and BSE, which that same domain serves, and which states Email sectdiv@biltpaper.in and Website www.biltpaper.in. NOT a guess. 🔴 NEVER MAIL info@bilt.com - an older BILT filing lists it, the domain has since changed hands, and it now reaches the fintech. sectdiv@biltpaper.in is a company-secretarial address for SEBI matters, NOT a commercial door - do not enrol it. VERDICT: not a form target and not a target at all right now. BILT completed its CIRP at the 80th AGM on 11 May 2026 after six years, Finquest Financial Solutions owns it, headcount 189, and one unit (Shree Gopal, Yamuna Nagar) is restarting. Grade fit is perfect - it once held over 50 percent of India''s coated woodfree market - and the timing is absurd. Revisit in a year. LEAD, unverified: Minerals Technologies told the SEC on 23 Apr 2009 that Specialty Minerals would build a 65,000 t/yr satellite PCC plant at BILT''s Ballarshah unit through a JV, SMI NewQuest India Private Ltd. If that plant still runs, BILT belongs in the satellite work, not the form work.',
    updated_at = now()
where p.id in (
        'de740c5b-323c-4a74-9a4a-7212ec9a7dd9'::uuid,  -- Ballarpur Industries Ltd.
        '4a2112db-b063-42c8-afb0-4126c0c7a38b'::uuid   -- BILT Sewa Unit
      )
  and p.party_type_id = 2
  and p.deleted_at is null
  and coalesce(p.notes, '') not like '%[bilt-domain-contamination 2026-07-17]%';


-- ---------- 2) Neither row gets a contact_form_url ----------
-- Nothing to do. Recording the absence so the next person does not re-sweep:
-- biltpaper.in was NOT opened for a contact form, because the verdict above makes
-- the form irrelevant. If BILT is revisited, start at biltpaper.in and note that
-- the site is a WordPress investor-relations shell - the visible menu is Contact,
-- Investor, Shareholder Information, Notices, Financial Information, Annual
-- Report, Policies, List of Operational Creditors. A company publishing its list
-- of operational creditors on the front page is telling you what it is doing this
-- year, and it is not evaluating filler.


-- ---------- 3) VERIFY - uncommented, on purpose ----------
select p.party_name,
       p.country_code,
       p.website,
       p.domain_normalized,
       p.contact_form_url,
       p.preferred_contact_method,
       (select count(*) from app.contacts c
        where c.party_id = p.id and c.deleted_at is null
          and nullif(btrim(c.email), '') is not null) as emails,
       (select count(*) from app.application_forms af where af.party_id = p.id) as form_rows,
       case when coalesce(p.notes, '') like '%[bilt-domain-contamination 2026-07-17]%'
            then 'note recorded' else 'NOTE MISSING - block 1 did not match' end as state,
       p.updated_at
from app.parties p
where p.id in (
        'de740c5b-323c-4a74-9a4a-7212ec9a7dd9'::uuid,
        '4a2112db-b063-42c8-afb0-4126c0c7a38b'::uuid
      )
order by p.party_name;
-- EXPECT two rows, website www.biltpaper.in, domain biltpaper.in, contact_form_url
-- null, emails 0, form_rows 0, state 'note recorded'.
-- If state says NOTE MISSING on a second run, that is correct - the guard is
-- idempotent and a rerun is a no-op. On the FIRST run it means nothing matched.
