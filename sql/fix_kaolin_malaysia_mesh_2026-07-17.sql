-- ============================================================
-- fix_kaolin_malaysia_mesh_2026-07-17.sql
--
-- KAOLIN (MALAYSIA) - NO. Disqualified on a NUMBER from their own product page,
-- which is the cleanest kind of no this sweep has produced.
--
-- kaolin.com.my/calcium-carbonate/ states:
--   "Our Calcium Carbonate Powder is produced from high grade limestone...
--    Various particle sizes ranging from 325 MESH TO 1000 MESH are available for
--    a wide range of uses such as in Paints, Inks, PAPER, Rubber, Adhesive, PVC,
--    Plastic, Masterbatch and Latex."
--
-- 325 mesh is roughly 44 microns. 1000 mesh is roughly 13 microns.
-- Paper filler GCC runs 60 to 90 percent BELOW 2 MICRONS.
--
-- Their FINEST product is several times coarser than the COARSEST paper filler.
-- They cannot make the grade, and no licence changes that - FCC is grown on
-- fibre and still has to land in a paper machine's filler spec.
--
-- Paper is on their applications list. It is on the list for coarse grades that
-- go to board or coating extenders, not to the filler slot. This is the first
-- row today killed by a specification rather than by a market description, and it
-- is worth noticing that a number settled in one line what a paragraph of
-- marketing prose could not.
--
-- WHAT THEY ARE: a multi-mineral grinder and merchant. Calcium carbonate is ONE
-- OF SEVEN minerals they sell - kaolin clay, calcined kaolin, hard and brown
-- clay, sericite mica, pyrophyllite, talc, wollastonite, bentonite, magnesium
-- silicate, and CaCO3. GCC only, from limestone, coated and uncoated. Founded
-- 1970 with a factory at Tapah, Perak - the name came from the first mineral.
-- Now at Puchong, Selangor. Over half their output is exported across ASEAN,
-- Japan, Korea, China, India, the Middle East, Europe, South Africa and the USA.
--
-- A grinder is not a licensee. FCC needs someone with precipitation or fine-
-- grinding capability and a mill relationship. This company has a mill, seven
-- minerals and a mesh range.
--
-- ------------------------------------------------------------
-- A NOTE FOR THE DOMAIN-MISMATCH SCAN, so it does not fire later:
--   website: kaolin.com.my
--   email:   sales@kaolinmalaysia.com
-- Different domains, BOTH PUBLISHED BY THE COMPANY on its own pages. This is
-- legitimate, not the Saica contamination pattern where a row carried a
-- competitor's inbox. scan_contact_email_domain_mismatch would flag this as a
-- mismatch and be wrong. Recorded so the next person does not chase it.
-- Not recorded as a contact - this is a non-target, and that is the sixth address
-- today kept out of the database for that reason.
--
-- IDEMPOTENT. Name-targeted. Nothing inserted.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

update app.filler_supplier_profile f
set extra_data = coalesce(f.extra_data, '{}'::jsonb) || '{"fcc_fit": {"verdict": "no", "reason": "DISQUALIFIED ON A PHYSICAL SPEC FROM THEIR OWN PRODUCT PAGE. kaolin.com.my/calcium-carbonate/ offers particle sizes ranging from 325 MESH TO 1000 MESH - roughly 44 microns down to roughly 13 microns. Paper filler GCC runs 60 to 90 percent BELOW 2 MICRONS. Their finest product is several times coarser than the coarsest paper filler. They cannot make the grade, and a licence does not change that - FCC is grown on fibre and still has to land in a paper machine filler spec. Paper is on their applications list, but for coarse grades that go to board or as coating extenders, not to the filler slot.", "checked_at": "2026-07-17", "source": "kaolin.com.my/calcium-carbonate/", "source_type": "marketing", "note": "First row today killed by a NUMBER rather than by a market description. A single spec settled in one line what a paragraph of marketing prose could not."}, "what_they_are": {"model": "multi-mineral grinder and merchant, not a filler technology company", "minerals": ["kaolin clay", "calcined kaolin", "hard clay", "brown clay", "sericite mica", "pyrophyllite powder", "talc", "wollastonite", "bentonite", "magnesium silicate", "calcium carbonate"], "caco3_note": "CaCO3 is one of seven-plus minerals on the shelf. GCC only, from limestone, coated and uncoated - the coated line is stearic-acid treated.", "founded": "1970, first factory at Tapah, Perak - the company name came from its first mineral", "hq": "No.5 and 7, Jalan TPP 5/17, Taman Perindustrian Puchong, 47100 Puchong, Selangor", "exports": "over half of output, across ASEAN, Japan, Korea, China, India, the Middle East, Europe, South Africa and the USA", "why_not_a_licensee": "FCC needs precipitation or fine-grinding capability plus a mill relationship. This company has a mill, seven minerals and a mesh range."}, "domain_mismatch_is_legitimate": {"website": "kaolin.com.my", "email": "sales@kaolinmalaysia.com", "verdict": "DIFFERENT DOMAINS, BOTH PUBLISHED BY THE COMPANY on its own pages. Legitimate, not the Saica contamination pattern where a row carried a competitor inbox. scan_contact_email_domain_mismatch would flag this and be wrong. Recorded so nobody chases it.", "raised_at": "2026-07-17"}, "contactability": {"not_recorded": "sales@kaolinmalaysia.com is published. Not recorded - sixth non-target address today kept out of this database. A contact route on a non-target is how a wrong target becomes a sent message."}}'::jsonb,
    notes = coalesce(f.notes, '') || E'\n[homepage-check 2026-07-17] NOT AN FCC TARGET, on a spec. Their CaCO3 page offers 325 to 1000 mesh - roughly 44 down to 13 microns. Paper filler GCC is 60-90 percent below 2 microns. Their finest grade is several times coarser than the coarsest paper filler. A multi-mineral grinder selling CaCO3 as one of seven minerals. Note for the domain scan - website kaolin.com.my and email sales@kaolinmalaysia.com are DIFFERENT DOMAINS and BOTH are the company own. Legitimate, not contamination.',
    updated_at = now()
from app.parties p
where f.party_id = p.id and p.party_name ~* 'kaolin.*malaysia|malaysia.*kaolin'
  and f.deleted_at is null and p.deleted_at is null
  and coalesce(f.notes, '') not like '%[homepage-check 2026-07-17]%';


-- ---------- VERIFY ----------
-- select p.party_name, p.website,
--        f.extra_data #>> '{fcc_fit,verdict}' as fcc_fit,
--        left(f.extra_data #>> '{fcc_fit,reason}', 60) as why
-- from app.parties p
-- join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
-- where p.party_name ~* 'kaolin.*malaysia|malaysia.*kaolin' and p.deleted_at is null;


-- ---------- SIXTEEN OPENED ----------
--   Artemyn            TOP      - 17 carbonate plants, Chris Nutbeem at Par Moor
--   Okutama Kogyo      STRONG   - over 90% of Japanese paper PCC
--   Gulshan Polyols    STRONG   - satellite operator, on-site PCC pioneer in India
--   Bihoku Funka       STRONG   - neutral papermaking filler, cost-down, own mine
--   Shiraishi Group    STRONG   - UFPCC+PCC+GCC, open testing lab
--   20 Microns         STRONG   - PCC+GCC, sells TiO2 replacement already
--   Zantat             STRONG   - names its own partnership inbox
--   Q-min              moderate - GCC only, plastics-first, banknotes since 1999
--   Fimatec            HOLD     - runs on Specialty Minerals technology
--   F.M.T. (Thailand)  HOLD     - Fimatec subsidiary
--   Maruo Calcium      no       - CaCO3, no paper
--   Takehara Chemical  no       - CaCO3, no paper
--   Nittetsu Mining    no       - limestone, upstream
--   IMI Fabi           no       - talc, no CaCO3
--   Carmeuse           no       - lime, upstream (+ a Ventures lead)
--   Kaolin (Malaysia)  no       - 325-1000 mesh, cannot make filler grade
--
-- SIXTEEN OPENED. SEVEN WORTH CONTACTING. NINE NOT.
--
-- THE RATIO IS NOW THE FINDING. This database ranked all sixteen as filler
-- targets. It was right about seven. If the remaining ~62 rows hold anywhere near
-- this rate, roughly half of the FCC filler pipeline is companies that should
-- never receive a message - and every single removal so far came from one page on
-- a company's own website, in about two minutes each.
--
-- The nine failures split six ways and the schema expresses none of them:
--   wrong mineral   Thiele (kaolin), IMI Fabi (talc)
--   wrong market    Maruo, Takehara
--   wrong position  Nittetsu, Carmeuse
--   wrong grade     Kaolin (Malaysia) - the only one a number could catch
--   conflict        Taekyung
--   entanglement    Fimatec, F.M.T. Thailand
--
-- Note which one of those a query could have found: the mesh spec. Exactly one.
-- The rest needed a human, or a model, to read English and Japanese marketing
-- copy and notice what was missing from a list.
