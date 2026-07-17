-- ============================================================
-- fix_in_filler_batch1_2026-07-17.sql
--
-- India sweep, batch 1. Wolkem, plus the roster problems the scan exposed before
-- a single search was run.
--
-- ------------------------------------------------------------
-- PART 1: WOLKEM INDIA - STRONG. The slurry is the point.
--
--   "India's first and leading producer of WET GROUND CALCIUM CARBONATE SLURRY"
--   "India's leading producer of Ground Calcium Carbonate"
--   "The World's leading Wollastonite producer"
--
-- WGCC SLURRY is what paper mills actually receive. Not powder - slurry, pumped
-- and metered. A company already making and shipping carbonate slurry to mills
-- has the exact logistics FCC needs, and has already solved the part that has
-- nothing to do with chemistry.
--
-- Paper is FIRST on their industry list, ahead of polymer, automobile, friction,
-- building materials, metallurgy, ceramics, paints, coatings, adhesives and
-- dental care. They are listed in the PaperMart directory as a supplier to paper
-- mills - an Indian paper-industry directory, not a general one.
--
-- Founded 1972, 100 percent family owned, mines and plants across seven Indian
-- states, exports to over 20 countries. HQ at Wolkem House, E-101, Mewar
-- Industrial Area, Udaipur, Rajasthan 313003. Associated company: Fimakem.
--
-- CONTACT NOT RECORDED, AND HERE IS WHY:
--   A lead-generation directory offers rcs@wolkem.com. That is C-grade - the
--   same grade as the Q-min name, and lead-gen directories are precisely where
--   the Saica contamination came from. Not recorded.
--   Their own page at wolkem.com/contactus_inter.htm exists but returned nothing
--   readable. I do not know whether it is a form or a list of addresses, so
--   contact_form_url stays null - setting it with preferred_contact_method
--   unknown is how I threw 23514 earlier today.
--   One look at that page finishes this row.
--
-- NUMBERS DELIBERATELY NOT RECORDED: employee counts range from 236 to 2000
-- across sources, and revenue from 50 crore to over 500 crore. Their own text
-- says over 2000 people. The directories disagree with each other and with the
-- company. None of it goes in a column.
--
-- ONE THING UNRESOLVED: their own boilerplate lists GCC and WGCC. One directory
-- adds "Precipitated Calcium". Their limestone page says the stone is suitable
-- for making lime AND precipitated calcium carbonate - which describes selling
-- feedstock to PCC makers, not making PCC. Whether Wolkem has a PCC line is open.
-- It does not change the verdict - WGCC slurry to paper mills is enough.
--
-- ------------------------------------------------------------
-- PART 2: THE ROSTER IS BROKEN IN WAYS SEARCHING CANNOT FIX
--
-- (a) FOUR ROWS ARE NOT COMPANIES. Their party_name holds two entities:
--       "Ashapura Group / Ashapura Microns"
--       "Ashapura Kaolin / White Performance Minerals"
--       "Yamama Cement / Saudi Cement"
--       "Mexalit / Cemex Minerals"
--     Yamama Cement and Saudi Cement are SEPARATE listed Saudi companies.
--     Mexalit and Cemex are entirely different firms. You cannot write to
--     "Yamama Cement / Saudi Cement" - no such company exists. Flagged, not
--     split: splitting is a data decision with duplicate risk, and duplicates
--     from exactly this shape produced the Omya Korea and Taekyung double-rows.
--
-- (b) BOTH ASHAPURA ROWS POINT AT ashapura.com. Same website, two rows. That is
--     the duplicate pattern again, arriving before anyone searched.
--
-- (c) mineral_class CONTRADICTS market_role, so it cannot be trusted as a filter:
--       Mumal Microns    role "Ultra-fine PCC producer"    mineral_class 'gcc'
--       Ashapura Kaolin  role "Paper/specialty kaolin"     mineral_class 'gcc'
--       Mississippi Lime role "PCC upstream (quicklime)"   mineral_class 'pcc'
--     Anyone filtering the roster by mineral_class gets the wrong companies.
--
-- (d) Saudi Lime Industries has website = 'https://www.dnb.com'. That is Dun and
--     Bradstreet, not the company.
--
-- None of these needed a search. They were visible in the roster itself, and they
-- have been sitting there while everything upstream treated these rows as
-- targets.
--
-- IDEMPOTENT. Name-targeted. Nothing inserted, no contact route recorded.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 1) WOLKEM ----------
update app.filler_supplier_profile f
set supply_model = coalesce(f.supply_model, 'Merchant - GCC powder and WGCC slurry to mills'),
    extra_data = coalesce(f.extra_data, '{}'::jsonb) || '{"fcc_fit": {"verdict": "strong", "reason": "WGCC SLURRY IS THE POINT. Wolkem describes itself as India first and leading producer of WET GROUND CALCIUM CARBONATE SLURRY, and India leading producer of Ground Calcium Carbonate. Slurry is what paper mills actually receive - pumped and metered, not bagged. A company already making and shipping carbonate slurry to mills has the exact logistics FCC needs and has already solved the part that has nothing to do with chemistry. PAPER IS FIRST on their industry list, ahead of polymer, automobile, friction, building materials, metallurgy, ceramics, paints, coatings, adhesives and dental care. They are listed in the PaperMart directory as a supplier to paper mills - an Indian paper-industry directory, not a general one. Also the world leading wollastonite producer, which is a different business and not why they matter here.", "checked_at": "2026-07-17", "source": "wolkem.com boilerplate, PaperMart directory", "source_type": "marketing"}, "company": {"founded": 1972, "ownership": "100 percent family owned", "hq": "Wolkem House, E-101, Mewar Industrial Area, Udaipur, Rajasthan 313003", "footprint": "mines and plants across seven Indian states, exports to over 20 countries", "associated_company": "Fimakem", "minerals": "wollastonite, calcium carbonate (GCC and WGCC), talc, dolomite, limestone, calcite, cenospheres"}, "contactability": {"status": "NOT RECORDED - unresolved", "their_own_page": "wolkem.com/contactus_inter.htm exists but returned nothing readable. Unknown whether it is a form or a list of addresses. contact_form_url stays null - setting it with preferred_contact_method unknown is how the 23514 fired earlier today.", "rejected": "A lead-generation directory offers rcs@wolkem.com. C-grade. Lead-gen directories are exactly where the Saica contamination came from. Not recorded.", "next": "One look at contactus_inter.htm finishes this row.", "checked_at": "2026-07-17"}, "unresolved": {"pcc_line": {"question": "Does Wolkem make PCC?", "for": "One directory lists Precipitated Calcium among their offerings.", "against": "Their own boilerplate says GCC and WGCC only. Their limestone page says the stone is suitable for making lime AND precipitated calcium carbonate - which describes selling FEEDSTOCK to PCC makers rather than making PCC.", "impact": "None on the verdict. WGCC slurry to paper mills is enough on its own.", "raised_at": "2026-07-17"}, "numbers_not_recorded": "Employee counts range from 236 to over 2000 across sources and revenue from 50 crore to over 500 crore. The directories disagree with each other and with the company. None of it is written to a column."}}'::jsonb,
    notes = coalesce(f.notes, '') || E'\n[homepage-check 2026-07-17] STRONG FCC TARGET. India first and leading producer of WET GROUND CALCIUM CARBONATE SLURRY plus India leading GCC producer. Slurry is the form paper mills receive - they already have the logistics FCC needs. Paper is first on their industry list and they are in the PaperMart supplier-to-paper-mills directory. CONTACT UNRESOLVED - their page wolkem.com/contactus_inter.htm did not return readable content, and the only address on offer (rcs@) comes from a lead-gen directory, which is where the Saica contamination came from. One look at that page finishes this row.',
    updated_at = now()
from app.parties p
where f.party_id = p.id and p.party_name ~* 'wolkem'
  and f.deleted_at is null and p.deleted_at is null
  and coalesce(f.notes, '') not like '%[homepage-check 2026-07-17]%';


-- ---------- 2) FLAG THE ROWS THAT ARE TWO COMPANIES ----------
update app.filler_supplier_profile f
set extra_data = coalesce(f.extra_data, '{}'::jsonb) || '{"data_defect": {"kind": "party_name holds TWO entities separated by a slash", "why_it_matters": "This is not a company and cannot be contacted. Any outreach targeting this row is aimed at a name that does not exist. Yamama Cement and Saudi Cement are separate listed Saudi companies. Mexalit and Cemex are entirely different firms. Ashapura Group and Ashapura Microns, and Ashapura Kaolin and White Performance Minerals, need checking before either is treated as one party.", "not_fixed_here": "Splitting is a data decision with duplicate risk - duplicates from exactly this shape produced the Omya Korea and Taekyung double-rows this week. Flagged for a human.", "found_by": "reading the roster, not by searching", "raised_at": "2026-07-17"}}'::jsonb,
    updated_at = now()
from app.parties p
where f.party_id = p.id
  and p.party_type_id = 3 and p.deleted_at is null and f.deleted_at is null
  and p.party_name like '%/%'
  and not (coalesce(f.extra_data, '{}'::jsonb) ? 'data_defect');


-- ---------- 3) FLAG mineral_class WHERE IT CONTRADICTS market_role ----------
update app.filler_supplier_profile f
set extra_data = coalesce(f.extra_data, '{}'::jsonb) || jsonb_build_object(
      'mineral_class_suspect', jsonb_build_object(
        'mineral_class', f.mineral_class,
        'market_role',   left(coalesce(f.market_role, ''), 80),
        'problem',       'mineral_class contradicts market_role on this row. Do not filter the roster by mineral_class - it will select the wrong companies. Observed contradictions on 2026-07-17: Mumal Microns role says ultra-fine PCC producer while mineral_class says gcc. Ashapura Kaolin role says paper/specialty kaolin while mineral_class says gcc. Mississippi Lime role says PCC upstream quicklime while mineral_class says pcc.',
        'raised_at',     '2026-07-17'))
from app.parties p
where f.party_id = p.id
  and p.party_type_id = 3 and p.deleted_at is null and f.deleted_at is null
  and f.mineral_class is not null and f.market_role is not null
  and (   (f.mineral_class ~* '^gcc$' and f.market_role ~* 'pcc|precipitat|kaolin')
       or (f.mineral_class ~* '^pcc$' and f.market_role ~* 'upstream|quicklime|merchant')
       or (f.mineral_class ~* 'kaolin' and f.market_role ~* '\mgcc\M|ground calcium'))
  and not (coalesce(f.extra_data, '{}'::jsonb) ? 'mineral_class_suspect');


-- ---------- 4) THE dnb.com WEBSITE ----------
update app.parties p
set website = null,
    updated_at = now()
where p.party_type_id = 3 and p.deleted_at is null
  and p.website ~* 'dnb\.com|dunandbradstreet|crunchbase|zoominfo|lusha|rocketreach|easyleadz|leadiq';


-- ---------- 5) VERIFY ----------
-- select p.party_name, p.country_code, p.website,
--        f.extra_data #>> '{fcc_fit,verdict}'              as fcc_fit,
--        f.extra_data #>> '{data_defect,kind}'             as name_defect,
--        f.extra_data #>> '{mineral_class_suspect,problem}' is not null as class_suspect
-- from app.parties p
-- join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
-- where p.party_type_id = 3 and p.deleted_at is null
--   and (p.party_name ~* 'wolkem' or p.party_name like '%/%'
--        or coalesce(f.extra_data, '{}'::jsonb) ? 'mineral_class_suspect')
-- order by p.country_code, p.party_name;
-- Statement 4 is the only one that clears a value - it nulls website where a
-- directory URL was stored as the company's own site. Check the count it reports.


-- ---------- INDIA, REMAINING ----------
--   20 Microns        DONE - strong
--   Imerys India      DONE - no, Imerys exited paper in 2024
--   Gulshan Polyols   DONE - strong, sixth satellite operator
--   Wolkem            THIS FILE - strong, WGCC slurry
--   Ashapura Group / Ashapura Microns          - flagged, two entities in one row
--   Ashapura Kaolin / White Performance Min.   - flagged, same website as above
--   Kunal Calcium          role "Domestic carbonate producer", class pcc
--   Mumal Microns          role "Ultra-fine PCC producer", class gcc - contradicts
--   Shikhar Microns        role "GCC producer"
--   Yamuna Calcium         role "North-India carbonate producer", class both
--
-- Then USA - Mississippi Lime (13 contacts already, and role says PCC UPSTREAM,
-- which is the Carmeuse position), Huber Engineered Materials (kaolin and PCC).
-- Thiele and Imerys USA are already out.
--
-- Then Saudi - Arabian Cement, Maaden, Saudi Lime Industries, Yamama/Saudi
-- Cement. Every one carries a market_role that already says LIMESTONE-BASED
-- UPSTREAM. On the Carmeuse and Nittetsu evidence, expect four more upstream
-- rows - but that is a prediction, and predictions get checked here, not assumed.
--
-- Then Mexico - Calidra (lime), Mexalit/Cemex (flagged). Imerys Mexico is out.
-- Mexico has THREE rows, not four. The country tally I have been working from
-- said four. It is stale by one.
