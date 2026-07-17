-- ============================================================
-- fix_gulshan_contact_2026-07-17.sql
--
-- GULSHAN POLYOLS - STRONG, and a SIXTH SATELLITE OPERATOR.
--
-- Their own site navigation carries a dedicated page:
--   Mineral Processing Division > Calcium Carbonate > Onsite / Satellite PCC Plant
-- And their own profile says:
--   "GPL has been recorded in Limca Book of Records, 2010, for PIONEERING IN
--    SETTING UP THE FIRST ON-SITE PCC PLANT IN THE COUNTRY."
-- Their Locate Us page lists sites including a "...Papers Ltd." - satellite
-- plants sitting at paper mills, which is the whole point.
--
-- scan_fcc_target_ranking put four companies in Tier 1 as satellite operators -
-- Specialty Minerals, Taekyung BK, Double A Specialty Minerals, Fimatec. Artemyn
-- made five. Gulshan makes SIX. Two of the six were found by opening websites
-- today, and both were sitting in this database misdescribed.
--
-- WHAT THEY ARE
--   One of India's largest PCC producers and a market leader by their own
--   account. Over 19 grades of calcium carbonate. Activated (stearic-coated),
--   precipitated and ground - so PCC, GCC and surface-treated. PCC assay around
--   98 percent, bulk densities from 0.40 to 0.9 g/cc.
--   Listed on the BSE. CIN L24231UP2000PLC034918. Incorporated 1981 as Gulshan
--   Sugars and Chemicals whose PRIMARY BUSINESS WAS CALCIUM CARBONATE at
--   Muzaffarnagar, demerged in 2000. Calcium carbonate is the founding business.
--
-- BUT READ THE DIVERSIFICATION. Three segments - grain processing, bio-fuel and
-- distillery, and mineral processing. The corporate theme is "Expanding
-- Potential" and the growth emphasis is on Indian bio-ethanol. Same shape as
-- Artemyn, whose CEO is expanding beyond its legacy in paper and board. In both,
-- the mineral business is the older line and the money is being aimed elsewhere.
--   The read, and it is a read: FCC gives the older line a growth story of its
--   own. Recorded as a hypothesis, not a fact.
--
-- ------------------------------------------------------------
-- THE TRAP, AND IT IS A REAL ONE
--
--   gulshanindia.com/distillery.html publishes:
--       ENA enquiry        -> indussales@gulshanindia.com
--       SANITIZER enquiry  -> sales@gulshanindia.com
--   and the site footer publishes:
--       investor queries and grievances -> cs@gulshanindia.com
--
--   NOT ONE PUBLISHED EMAIL IS FOR CALCIUM CARBONATE.
--   sales@gulshanindia.com looks like the obvious business address on a company
--   with a mineral division. It is the SANITIZER inbox.
--
-- This is the Saica failure in miniature. That row carried Burgo's live
-- competitor inbox because somebody reached for a plausible-looking address. Here
-- the plausible-looking address is in-house but points at hand sanitiser. A
-- letter about licensing flexible calcium carbonate landing in a sanitiser queue
-- is not a disaster - it is just the one approach, spent.
--
-- SO THE DOOR IS THE FORM: gulshanindia.com/enquiry.html
-- "Customers can contact us by using our online enquiry form for their queries
--  and suggestions."
-- NO CONTACT ROW IS CREATED. There is no calcium carbonate address to create one
-- with, and recording sales@ would be recording the wrong door.
--
-- The site also has Board of Directors, Key Executives and Management pages, and
-- the company is BSE-listed, so Indian filings name officers - the same route
-- noted for 20 Microns. That is the better second option if the form stalls.
--
-- IDEMPOTENT. contact_form_url and preferred_contact_method are set TOGETHER -
-- migration 027's parties_contact_form_url_chk requires the pair, and it caught
-- me declaring web_form with a null URL earlier today.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 1) Party: the form, the method, the addresses ----------
update app.parties p
set contact_form_url         = 'https://www.gulshanindia.com/enquiry.html',
    preferred_contact_method = 'web_form',
    country_code = coalesce(p.country_code, 'IN'),
    city         = coalesce(p.city, 'Delhi'),
    phone_e164   = coalesce(p.phone_e164, '+911149999200'),
    updated_at = now()
where p.party_name ~* 'gulshan' and p.party_type_id = 3 and p.deleted_at is null;


-- ---------- 2) The form row ----------
insert into app.application_forms
  (organization_id, party_id, form_url, form_type, submission_method,
   login_required, status, notes, created_by)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, p.id,
       'https://www.gulshanindia.com/enquiry.html',
       'contact_inquiry', 'web_form', false, 'not_started',
       'THE FORM IS THE DOOR HERE BECAUSE NO PUBLISHED EMAIL IS FOR CALCIUM CARBONATE. sales@gulshanindia.com is the SANITIZER enquiry inbox per their own distillery page. indussales@ is for ENA ethanol. cs@ is the company secretary for investor grievances. Reaching for sales@ because it looks like a business address is exactly how the Saica row ended up carrying a competitor inbox. FIELDS NOT RECORDED - nobody has opened the page and max_length must not be guessed, because guessing it defeats the variant selector. Second option if the form stalls - GPL is BSE-listed and the site carries Board of Directors and Key Executives pages, so a named technical or mineral-division officer is findable through Indian filings.',
       coalesce(auth.uid(), (select pp.created_by from app.parties pp where pp.created_by is not null limit 1))
from app.parties p
where p.party_name ~* 'gulshan' and p.party_type_id = 3 and p.deleted_at is null
  and not exists (select 1 from app.application_forms af
                  where af.party_id = p.id and af.form_type = 'contact_inquiry');


-- ---------- 3) Profile ----------
update app.filler_supplier_profile f
set supply_model  = coalesce(f.supply_model, 'Merchant + on-site satellite PCC at paper mills'),
    mineral_class = coalesce(f.mineral_class, 'PCC + GCC + activated (stearic-coated) CaCO3, 19+ grades'),
    extra_data = coalesce(f.extra_data, '{}'::jsonb) || '{"fcc_fit": {"verdict": "strong", "reason": "A SATELLITE PCC OPERATOR, and the pioneer of on-site PCC in India - recorded in the Limca Book of Records 2010 for setting up the first on-site PCC plant in the country. Their site carries a dedicated Onsite / Satellite PCC Plant page under the Mineral Processing Division, and the Locate Us page lists sites at a Papers Ltd. One of India largest PCC producers with over 19 grades, covering precipitated, ground and activated stearic-coated. Calcium carbonate is the FOUNDING business - the company began in 1981 as Gulshan Sugars and Chemicals whose primary business was CaCO3 at Muzaffarnagar. BSE-listed, so filings name officers.", "checked_at": "2026-07-17", "source": "gulshanindia.com", "source_type": "marketing"}, "satellite_operator": {"claim": "Sixth satellite operator identified in this database", "the_others": ["Specialty Minerals", "Taekyung BK", "Double A Specialty Minerals", "Fimatec", "Artemyn", "Gulshan Polyols"], "evidence": "Their own navigation has a dedicated Onsite / Satellite PCC Plant page, and their profile claims the Limca Book of Records 2010 entry for the first on-site PCC plant in India.", "note": "scan_fcc_target_ranking counted four. Two more were found by opening websites today, and both were already in this database misdescribed - Artemyn as a kaolin merchant, Gulshan without a supply_model.", "checked_at": "2026-07-17"}, "contactability": {"form_url": "https://www.gulshanindia.com/enquiry.html", "why_the_form": "NO PUBLISHED EMAIL IS FOR CALCIUM CARBONATE. This is the whole point.", "DO_NOT_USE": {"sales@gulshanindia.com": "THE SANITIZER ENQUIRY INBOX per their own distillery page. It looks like the obvious business address on a company with a mineral division. It is not.", "indussales@gulshanindia.com": "ENA / ethanol enquiries", "cs@gulshanindia.com": "company secretary, investor queries and grievances"}, "registered_office": "9th K.M., Jansath Road, Muzaffarnagar 251001, Uttar Pradesh, tel 0131-3201231", "corporate_office": "G-81, Preet Vihar, Delhi 110092, tel +91 11 49999200", "cin": "L24231UP2000PLC034918", "second_route": "BSE-listed with Board of Directors and Key Executives pages on the site - Indian filings will name a mineral-division officer, the same route noted for 20 Microns.", "checked_at": "2026-07-17"}, "diversification_read": {"segments": "grain processing, bio-fuel and distillery, mineral processing", "observation": "The corporate theme is Expanding Potential and the growth emphasis is Indian bio-ethanol. Calcium carbonate is the founding line but not where the expansion story points. Same shape as Artemyn, whose CEO is expanding beyond its legacy in paper and board.", "hypothesis": "FCC gives the older mineral line a growth story of its own, which is a thing a diversifying board can hear. HYPOTHESIS, not a fact from the site.", "raised_at": "2026-07-17"}}'::jsonb,
    notes = coalesce(f.notes, '') || E'\n[homepage-check 2026-07-17] STRONG - SIXTH SATELLITE OPERATOR. Pioneered on-site PCC in India, Limca Book of Records 2010, dedicated Onsite/Satellite PCC Plant page, 19+ CaCO3 grades, BSE-listed, CaCO3 is the founding business from 1981. WARNING - sales@gulshanindia.com is the SANITIZER inbox, indussales@ is ethanol, cs@ is investor relations. No published email is for calcium carbonate. Use the enquiry form or go through BSE filings for a named officer.',
    updated_at = now()
from app.parties p
where f.party_id = p.id and p.party_name ~* 'gulshan'
  and f.deleted_at is null and p.deleted_at is null
  and coalesce(f.notes, '') not like '%[homepage-check 2026-07-17]%';


-- ---------- 4) VERIFY ----------
-- select p.party_name, p.country_code, p.city, p.contact_form_url,
--        p.preferred_contact_method, f.supply_model,
--        f.extra_data #>> '{fcc_fit,verdict}' as fcc_fit,
--        af.form_type, af.status,
--        (select count(*) from app.contacts c where c.party_id = p.id and c.deleted_at is null) as contacts
-- from app.parties p
-- left join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
-- left join app.application_forms af on af.party_id = p.id
-- where p.party_name ~* 'gulshan' and p.deleted_at is null;
-- EXPECT - IN, the enquiry URL, web_form, 'strong', one contact_inquiry form,
-- and contacts 0. Zero is correct - there is no CaCO3 address to hold.


-- ---------- 5) THE SWEEP ----------
--   Artemyn            TOP      - 17 carbonate plants, Chris Nutbeem at Par Moor
--   Okutama Kogyo      STRONG   - 90%+ of Japanese paper PCC, departments named
--   Gulshan Polyols    STRONG   - satellite operator, pioneered on-site PCC in India
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
-- TWELVE OPENED. SEVEN STRONG OR BETTER.
-- Contact routes recorded today - 20 Microns enquiry@, Zantat sales@ (their named
-- partnership door), Q-min mungkorn@, plus contact_inquiry forms for Artemyn,
-- 20 Microns and Gulshan. This morning the entire filler roster had four
-- contacts and every one of them was Omya or SMI.
--
-- Four of the twelve were removed or held before a message was sent. Every one
-- of those four looked like a target in this database and was ruled out by one
-- page on the company's own website.
