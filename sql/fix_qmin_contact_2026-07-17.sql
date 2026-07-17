-- ============================================================
-- fix_qmin_contact_2026-07-17.sql
--
-- Q-MIN - MODERATE, not strong. Read the company, not the country tag.
--
-- WHAT THEY ACTUALLY SELL, from qmin.co.th/products/:
--   "a full range of high quality GROUND calcium carbonate both coated and
--    uncoated grades. Total production capacity is 180,000 tons per year."
--   GCC ONLY. NO PCC ANYWHERE ON THE SITE.
--   Other lines - calcium masterbatch, white titanium dioxide masterbatch,
--   polyethylene wax, 12,000 t/yr of plastic compound.
--
-- AND THEIR HEADLINE CLAIM IS ABOUT PLASTICS, not paper. The homepage banner
-- reads "the first and only calcium carbonate manufacturer in Thailand to obtain
-- the industrial standard for PLASTIC APPLICATION", granted by the Thai
-- Industrial Standard Institute. Their masterbatch and PE wax lines say the same
-- thing. This is a plastics-first GCC house.
--
-- BUT PAPER IS NOT DEAD HERE, AND ONE CREDENTIAL IS REMARKABLE:
--   "The company is proud of being selected by THE BANK OF THAILAND to use its
--    calcium carbonate as one of the essential elements in the THAI BANK NOTES
--    SINCE 1999."
--   Banknote paper is the grade where sheet strength IS the product - it is
--   handled, folded and soaked for years. A filler qualified into banknotes has
--   passed a strength bar that ordinary printing grades never set. Their
--   applications list also names printing and writing paper.
--
-- GCC-ONLY IS NOT A DEAD END. The public gcc_expansion answer says our FCC
-- process was first validated on PCC plant infrastructure and that a newly
-- developed production route addresses GCC. Q-min is exactly the company that
-- route exists for. So the verdict is moderate rather than no - real paper
-- presence, real strength credential, wrong primary focus.
--
-- THE EMAIL IS UNUSUAL AND NEEDS CARE.
-- qmin.co.th/contact-us/ publishes exactly one address - mungkorn@qmin.co.th.
-- Not info@, not sales@. That local-part looks like a person.
-- A third-party chemical directory lists "MUNGKORN KRIENGWATANA, Project
-- Manager" at this company.
--
-- SO THE EVIDENCE SPLITS, AND THE RECORD SPLITS WITH IT:
--   the ADDRESS is from the company's own contact page  -> recorded
--   the NAME is from one third-party directory          -> notes only, NOT full_name
-- This is the geral.celbi rule holding in a harder case. Yesterday the rule
-- stopped a regex turning info.jkpaper into "Info Jkpaper". Here the local-part
-- probably IS a real person's given name - and it still does not go in
-- full_name, because a directory is not the company saying so. If Mungkorn
-- Kriengwatana is confirmed, promote it in one line.
--
-- Established 1995, public since 2004, registered capital 365.75m baht, about
-- 12m USD. Office in Bangkok, plant at Lopburi 150km north - the same calcite
-- belt as F.M.T. Thailand at Singburi. Machinery from Germany, technical support
-- from MTEC, NSTDA and NIA. Calcite purity around 98 percent, 99.3 percent for
-- food and pharma grade. SGS tested, RoHS compliant.
--
-- Capacity conflict noted, not resolved: the products page says 180,000 t/yr and
-- an older page at qmin.co.th/ContactUs/index.php says 108,000 t/yr with 45 to 8
-- micron fineness. Two live pages on one domain disagree - the same two-sites
-- problem as Bihoku. Recorded as a conflict rather than picked.
--
-- preferred_contact_method NOT set - the allowed values of
-- parties_preferred_contact_method_chk are unknown to me and I threw 23514 on
-- the neighbouring constraint earlier today.
--
-- IDEMPOTENT. No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 1) Address and phone from their own contact page ----------
update app.parties p
set country_code = coalesce(p.country_code, 'TH'),
    city         = coalesce(p.city, 'Bangkok'),
    phone_e164   = coalesce(p.phone_e164, '+6620902722'),
    updated_at = now()
where p.party_name ~* 'quality minerals|q-min|qmin' and p.party_type_id = 3 and p.deleted_at is null;


-- ---------- 2) The published address. NAME NOT ASSERTED. ----------
insert into app.contacts
  (organization_id, party_id, contact_type_id, email, is_primary, source, notes)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, p.id, 2,
       'mungkorn@qmin.co.th', true, 'homepage',
       'full_name DELIBERATELY NULL despite the local-part looking like a person. This is the ONLY address published on qmin.co.th/contact-us/ - not info@, not sales@. A third-party chemical directory names MUNGKORN KRIENGWATANA, Project Manager, at this company, which makes the address probably personal. THE ADDRESS is A-grade, from their own contact page. THE NAME is C-grade, from one directory. A directory is not the company saying so, and yesterday this same rule stopped a regex turning info.jkpaper to a fictional Info Jkpaper. If the name is confirmed, promote it in one line. Office - 9/13-17 Yarnphaholyothin Road, Jatujak, Bangkok 10900, tel 02-090-2722, Mon-Fri 8.30-18.00. Plant - 31 Moo 12 Saitoe, Koktoom, Amphur Muang, Lopburi, tel 063-202-5348-49.'
from app.parties p
where p.party_name ~* 'quality minerals|q-min|qmin' and p.party_type_id = 3 and p.deleted_at is null
  and not exists (select 1 from app.contacts c
                  where c.party_id = p.id and c.email = 'mungkorn@qmin.co.th' and c.deleted_at is null);


-- ---------- 3) Profile ----------
update app.filler_supplier_profile f
set mineral_class = coalesce(f.mineral_class, 'GCC only (coated and uncoated) - no PCC line'),
    extra_data = coalesce(f.extra_data, '{}'::jsonb) || '{"fcc_fit": {"verdict": "moderate", "reason": "GCC ONLY - no PCC anywhere on the site - and the company headline is a PLASTICS credential, the first and only Thai CaCO3 maker to hold the Thai Industrial Standard Institute standard for plastic application. Masterbatch, white TiO2 masterbatch and PE wax confirm a plastics-first house. BUT paper is real here and one credential is remarkable - the Bank of Thailand has used their calcium carbonate in THAI BANK NOTES SINCE 1999. Banknote paper is the grade where sheet strength IS the product. A filler qualified for banknotes has cleared a strength bar ordinary printing grades never set. Printing and writing paper is also on their applications list. GCC-only is not a dead end - the public gcc_expansion answer describes exactly the route for a producer like this. Moderate, not strong - real paper presence, real strength credential, wrong primary focus.", "checked_at": "2026-07-17", "source": "qmin.co.th", "source_type": "marketing"}, "banknote_credential": {"claim": "Selected by the Bank of Thailand, calcium carbonate used in Thai bank notes since 1999", "why_it_matters": "Banknotes are handled, folded and soaked for years. Qualifying a filler for that grade means the strength conversation is one they have already had with a demanding customer.", "source": "qmin.co.th/our-commitment/", "source_type": "marketing"}, "contactability": {"published_address": "mungkorn@qmin.co.th - the ONLY address on their contact page", "name_unverified": "A third-party directory names Mungkorn Kriengwatana, Project Manager. NOT written to full_name - the company site publishes the address without a name, and a directory is not the company saying so.", "office": "9/13-17 Yarnphaholyothin Road, Jatujak, Bangkok 10900, tel 02-090-2722, fax 02-090-2710", "plant": "31 Moo 12 Saitoe, Koktoom, Amphur Muang, Lopburi, tel 063-202-5348-49", "hours": "Mon-Fri 8.30-18.00, Friday to 17.30", "checked_at": "2026-07-17"}, "company": {"established": "1995-11-09, public company since 2004-08-20", "registered_capital": "365.75 million baht, about 12 million USD", "plant_location": "Lopburi, about 150km north of Bangkok - the same calcite belt as F.M.T. Thailand at Singburi", "raw_material": "calcite at about 98 percent purity, 99.3 percent for food and pharmaceutical grade", "provenance": "initial machinery from Germany, training from German, Japanese and Canadian specialists, technical support from MTEC, NSTDA and NIA under the ITAP programme", "compliance": "SGS tested, no heavy metals per Thailand Ministry of Health, RoHS 2002/95/EC"}, "capacity_conflict": {"products_page": "180,000 tonnes per year GCC, plus 12,000 t/yr plastic compound", "older_page": "qmin.co.th/ContactUs/index.php says 108,000 tonnes per year, fineness 45 micron down to 8 micron", "status": "TWO LIVE PAGES ON ONE DOMAIN DISAGREE - the same two-sites problem found at Bihoku. Recorded as a conflict rather than picked. Neither number is written to a scalar column.", "raised_at": "2026-07-17"}}'::jsonb,
    notes = coalesce(f.notes, '') || E'\n[homepage-check 2026-07-17] MODERATE, not strong. GCC only, no PCC, and the company leads with a plastics standard. But the Bank of Thailand has used their CaCO3 in Thai banknotes since 1999 - a strength-critical paper grade - and printing and writing paper is on their list. Contact is mungkorn@qmin.co.th, the only address on their contact page. Name unverified, left out of full_name. Capacity conflicts between two live pages, 180k vs 108k t/yr - not resolved.',
    updated_at = now()
from app.parties p
where f.party_id = p.id and p.party_name ~* 'quality minerals|q-min|qmin'
  and f.deleted_at is null and p.deleted_at is null
  and coalesce(f.notes, '') not like '%[homepage-check 2026-07-17]%';


-- ---------- 4) VERIFY ----------
-- select p.party_name, p.country_code, p.city, c.email, c.full_name,
--        f.mineral_class, f.extra_data #>> '{fcc_fit,verdict}' as fcc_fit
-- from app.parties p
-- left join app.contacts c on c.party_id = p.id and c.deleted_at is null
-- left join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
-- where p.party_name ~* 'quality minerals|q-min|qmin' and p.deleted_at is null;
-- EXPECT - TH, Bangkok, mungkorn@qmin.co.th with full_name NULL, 'moderate'.


-- ---------- 5) THE SWEEP ----------
--   Artemyn            TOP      - 17 carbonate plants, Chris Nutbeem at Par Moor
--   Okutama Kogyo      STRONG   - 90%+ of Japanese paper PCC, departments named
--   Bihoku Funka       STRONG   - neutral papermaking filler, cost-down, own mine
--   Shiraishi Group    STRONG   - UFPCC+PCC+GCC, paper listed, open testing lab
--   20 Microns         STRONG   - PCC+GCC, paper coating pigments, TiO2 replacement
--   Zantat             STRONG   - names its own partnership inbox
--   Q-min              moderate - GCC only, plastics-first, but banknotes since 1999
--   Fimatec            HOLD     - runs on Specialty Minerals technology
--   F.M.T. (Thailand)  HOLD     - Fimatec subsidiary
--   Maruo Calcium      no       - paper not in its applications list
--   Nittetsu Mining    no       - limestone miner, sells rock by the centimetre
--
-- ELEVEN OPENED. SIX STRONG OR BETTER, ONE MODERATE, TWO HELD, TWO OUT.
-- Filler parties with a contact - was 4 this morning, all four Omya or SMI.
-- Now 7, and the three additions are addresses the companies published
-- themselves.
--
-- Still to sweep - Gulshan Polyols (IN), Takehara Chemical, and the rest of the
-- 78.
