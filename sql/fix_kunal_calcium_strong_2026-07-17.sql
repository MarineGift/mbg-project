-- ============================================================
-- fix_kunal_calcium_strong_2026-07-17.sql
--
-- KUNAL CALCIUM - STRONG. A dedicated PCC producer whose own paper page states
-- the FCC argument more exactly than any target so far.
--
-- ------------------------------------------------------------
-- THEIR PAPER PAGE, kunalcalcium.com/calcium-carbonate-paper.php:
--   "Precipitated Calcium Carbonate is used as a filler and surface coating agent
--    in Paper Industry such as OFFICE PAPER and CIGARETTE/TISSUE PAPER for
--    premium quality paper products. It enhances brightness, smoothness and
--    improves opacity. PCC improves paper machine productivity and can REDUCE
--    PAPER MAKING COSTS THROUGH THE REPLACEMENT OF MORE EXPENSIVE PULP FIBER and
--    optical brightening agents."
--
-- "Replacement of more expensive pulp fiber." That is what filler loading does,
-- and it is the exact thing FCC extends. Kunal already sells fibre replacement to
-- paper mills - they do not need the concept explained, only the ceiling raised.
--
-- SIXTH time in this sweep a target's own marketing states our case - after
-- Bihoku (neutral papermaking, cost-down), 20 Microns (TiO2 replacement), Zantat
-- (cost-saving as the company concept), MLC (TiO2 extension in paper filling) and
-- Mumal (whose version was copied). Kunal's is the most precise of the six.
--
-- ------------------------------------------------------------
-- COMPANY-SPECIFIC FACTS - the kind the Mumal lesson says to weigh, because
-- nobody copies these:
--   Established 1997. Founder named on their own site: Mr Ashok Nayyar.
--   INITIAL CAPACITY 10,000 MT PER ANNUM, reaching 50,000 MT PER ANNUM IN UNDER
--     TEN YEARS. Dated, specific, theirs.
--   Limestone from HIMACHAL PRADESH MINES - a named source.
--   Named grades: KC-11, KC-1 Super PCC.
--   Based in Haryana.
--   "core competency being the manufacturing of Precipitated Calcium Carbonate" -
--     PCC is the business, not a sideline. They also run a GCC line, describing
--     themselves as one of India's largest GCC manufacturers and exporters.
--
-- ------------------------------------------------------------
-- AND A FINDING THAT APPLIES BEYOND THIS ROW: THERE IS A SHARED INDIAN PCC
-- BOILERPLATE IN CIRCULATION.
--
--   Gulshan Polyols: "bulk densities from 0.40 gms/cc to 0.9 gms/cc"
--   Mumal Microns:   "bulk densities from 0.40 gms/cc to 0.9 gms/cc"
--   Kunal Calcium:   "bulk densities ranging from 0.40 gms/cc to 0.90 gms/cc"
--
-- Three companies, one sentence. Mumal's whole PCC page was Gulshan's text; now
-- the same density range turns up at Kunal. That phrase is worth nothing as
-- evidence about any of the three.
--
-- Kunal survives it easily - the capacity history, the named founder, the named
-- mines, the named grades and the specific paper grades are all its own. Gulshan
-- survives it on the Limca record, the satellite page, the BSE listing and the
-- CIN. Mumal did not survive it, because boilerplate was all it had.
--
-- THE RULE HOLDS AND IS NOW TESTED: a claim counts only if it is specific to that
-- company. It just correctly separated three companies sharing one sentence.
--
-- ------------------------------------------------------------
-- THREE DOMAINS AGAIN: kunalcalcium.com is the main site. calcium.co.in carries
-- the identical paper page. kunalcalciumindia.com is a marketplace storefront
-- listing KC-11. This roster's Indian rows keep having two or three live domains
-- each - Mumal had three, Bihoku had two structures, Zantat had an old and a new
-- site. Recorded so the domain-mismatch scan does not fire on it.
--
-- mineral_class='pcc' is RIGHT here - the first Indian row today where the class
-- field and the company agree. market_role "Domestic carbonate producer" is
-- understated but not wrong.
--
-- NO CONTACT RECORDED. No address surfaced in the search - only a marketplace
-- enquiry widget, which is not their inbox. Their own site certainly has a
-- contact page. One look finishes this row, exactly like Wolkem.
--
-- IDEMPOTENT. Name-targeted. Nothing inserted.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

update app.filler_supplier_profile f
set market_role = 'Dedicated PCC producer, Haryana - PCC is the stated core competency, from 10,000 MT/annum at founding in 1997 to 50,000 MT/annum within ten years. Limestone from Himachal Pradesh mines. Also one of India largest GCC manufacturers and exporters. Paper filler and surface coating for office paper and cigarette/tissue grades.',
    extra_data = coalesce(f.extra_data, '{}'::jsonb) || '{"fcc_fit": {"verdict": "strong", "reason": "A DEDICATED PCC PRODUCER WHOSE OWN PAPER PAGE STATES THE FCC ARGUMENT. Their paper page says PCC is used as a filler and surface coating agent for office paper and cigarette/tissue paper, and that it can REDUCE PAPER MAKING COSTS THROUGH THE REPLACEMENT OF MORE EXPENSIVE PULP FIBER and optical brightening agents. That is what filler loading does and exactly what FCC extends - they already sell fibre replacement to mills and do not need the concept explained, only the ceiling raised. PCC is their stated core competency, not a sideline. They also run a GCC line.", "checked_at": "2026-07-17", "source": "kunalcalcium.com", "source_type": "marketing"}, "company_specific_facts": {"note": "The kind the Mumal lesson says to weigh, because nobody copies these.", "founded": "1997, as a private limited company", "founder_named_on_their_site": "Mr Ashok Nayyar", "capacity_history": "initial capacity 10,000 MT per annum, reaching 50,000 MT per annum in under ten years", "raw_material": "limestone from Himachal Pradesh mines - a named source", "named_grades": ["KC-11", "KC-1 Super PCC"], "location": "Haryana", "paper_grades_named": "office paper, cigarette and tissue paper", "purity": "PCC assay around 98 percent as CaCO3"}, "shared_indian_pcc_boilerplate": {"the_finding": "THREE companies carry one sentence. Gulshan Polyols - bulk densities from 0.40 gms/cc to 0.9 gms/cc. Mumal Microns - bulk densities from 0.40 gms/cc to 0.9 gms/cc. Kunal Calcium - bulk densities ranging from 0.40 gms/cc to 0.90 gms/cc. Mumal whole PCC page was Gulshan text, and now the same density range turns up at Kunal.", "consequence": "That phrase is worth nothing as evidence about any of the three. There is a shared Indian PCC boilerplate in circulation and it should be discounted wherever it appears.", "who_survives_it": "Kunal survives easily - capacity history, named founder, named mines, named grades and specific paper grades are all its own. Gulshan survives on the Limca record, the satellite page, the BSE listing and the CIN. Mumal did NOT survive, because boilerplate was all it had.", "the_rule_is_now_tested": "A claim counts only if it is specific to that company. It just correctly separated three companies sharing one sentence.", "raised_at": "2026-07-17"}, "domains": {"main": "kunalcalcium.com", "also_theirs": "calcium.co.in carries the identical paper page", "storefront": "kunalcalciumindia.com is a marketplace listing carrying KC-11", "note": "The Indian rows in this roster keep having two or three live domains each - Mumal had three, Bihoku had two structures, Zantat had an old and a new site. Recorded so the domain-mismatch scan does not fire on it."}, "contactability": {"status": "NOT RECORDED - unresolved", "why": "No address surfaced in the search, only a marketplace enquiry widget, which is not their inbox. Their own site certainly has a contact page. One look finishes this row, exactly like Wolkem.", "checked_at": "2026-07-17"}, "field_agreement": {"mineral_class": "pcc - RIGHT. The first Indian row today where the class field and the company agree.", "market_role_was": "Domestic carbonate producer - understated but not wrong. Expanded rather than corrected."}}'::jsonb,
    notes = coalesce(f.notes, '') || E'\n[homepage-check 2026-07-17] STRONG FCC TARGET. Kunal Calcium is a dedicated PCC producer - PCC is the stated core competency, 10,000 t/yr at founding in 1997 to 50,000 t/yr within ten years, limestone from Himachal Pradesh mines, grades KC-11 and KC-1 Super, plus a GCC line. THEIR OWN PAPER PAGE SAYS PCC can reduce paper making costs through the REPLACEMENT OF MORE EXPENSIVE PULP FIBER - the FCC argument, stated by them, for office and cigarette/tissue grades. NOTE - the 0.40 to 0.90 gms/cc bulk density sentence is SHARED BOILERPLATE also found at Gulshan and Mumal, and is worth nothing as evidence. Kunal stands on its own specifics. CONTACT UNRESOLVED - no address found, one look at their contact page finishes this row.',
    updated_at = now()
from app.parties p
where f.party_id = p.id and p.party_name ~* 'kunal'
  and f.deleted_at is null and p.deleted_at is null
  and coalesce(f.notes, '') not like '%[homepage-check 2026-07-17]%';


-- ---------- VERIFY ----------
-- select p.party_name, p.website, f.mineral_class,
--        f.extra_data #>> '{fcc_fit,verdict}'                            as fcc_fit,
--        f.extra_data #>> '{shared_indian_pcc_boilerplate,the_finding}' is not null as boilerplate_flagged,
--        (select count(*) from app.contacts c
--          where c.party_id = p.id and c.deleted_at is null)             as contacts
-- from app.parties p
-- join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
-- where p.party_name ~* 'kunal' and p.deleted_at is null;
-- EXPECT - 'strong', contacts 0.


-- ---------- INDIA: ONE LEFT ----------
--   20 Microns       STRONG   - PCC+GCC, TiO2 replacement already sold
--   Gulshan Polyols  STRONG   - sixth satellite operator, on-site PCC pioneer
--   Wolkem           STRONG   - India first WGCC slurry producer
--   Kunal Calcium    STRONG   - dedicated PCC, sells fibre replacement
--   Ashapura x2      moderate - one company, real GCC, pilot plants
--   Mumal Microns    weak     - copied PCC copy, multi-mineral grinder
--   Imerys India     no       - exited paper in 2024
--   Shikhar Microns  LAST     - role says "GCC producer"
--
-- INDIA IS 4 FOR 7 ON REAL COMPANIES, and the four are not small: 20 Microns is
-- BSE/NSE listed, Gulshan is BSE-listed and runs satellites, Wolkem is the world
-- wollastonite leader with 2000 people, Kunal makes 50,000 tonnes of PCC a year.
--
-- No other country in this roster is close. Japan went 3 for 7 and one of the
-- three is the 90-percent incumbent. The USA went 1 for 4. Malaysia 1 for 2.
-- Saudi 0 for 1 checked. Mexico 0 for 3.
--
-- If the FCC filler pipeline has a centre of gravity, the sweep says it is India.
