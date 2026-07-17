-- ============================================================
-- fix_imifabi_no_caco3_2026-07-17.sql
--
-- IMI FABI - NO CALCIUM CARBONATE. Talc only. The Thiele pattern exactly.
--
-- imifabi.com describes itself in one line: a leading mining and minerals
-- company SPECIALISING IN THE PRODUCTION OF TALC. The products page offers a
-- broad range of TALC grades, dark and coarse through ultrafine and high
-- brightness. Talc is hydrated magnesium silicate. It is not calcium carbonate,
-- and there is no calcium carbonate anywhere on the site.
--
-- FCC is a calcium carbonate grown on fibre. There is no plant here to license.
--
-- THEY DO SERVE PAPER - and that is what makes this row dangerous rather than
-- obviously wrong. imifabi.com/74-Paper.html sells talc for PITCH CONTROL and as
-- a DE-INKING agent, absorbing sticky resinous particles so they cannot
-- re-agglomerate, plus talc in paper coating. Real paper business, real mill
-- relationships, real technical service. Every signal this database can read says
-- target. The mineral is wrong.
--
-- AND THEIR PRODUCT DEVELOPMENT PAGE SETTLES IT:
--   "An expert team works to broaden the opportunities for new applications, TO
--    REPLACE OTHER MINERALS for more valuable opportunities rather than to
--    discover brand new applications for talc."
--   Replacing other minerals is the stated job. In the paper filler slot, talc
--   and PCC compete for the same position - Fimatec's own paper page says talc
--   and PCC both go to filler while GCC and kaolin go to coating.
--   IMI Fabi is a competitor for the slot FCC occupies, not a licensee for it.
--
-- Scale, for the record: six mining sites, seven production and administrative
-- sites, two joint ventures, across Italy (Valmalenco, since the 1950s), Western
-- Australia (Mount Seabrook), West Virginia, China, Singapore, Pakistan and
-- Brazil. A serious company. Serious about the wrong mineral.
--
-- ------------------------------------------------------------
-- THE PATTERN THIS COMPLETES, AND IT IS WORTH STATING PLAINLY
--
-- The 242-row filler roster fails on THREE DIFFERENT AXES, and this database
-- measures none of them:
--
--   WRONG MINERAL     Thiele Kaolin - kaolin, no CaCO3 line
--                     IMI Fabi      - talc, no CaCO3 line
--   WRONG MARKET      Maruo Calcium - CaCO3, no paper in its applications
--                     Takehara      - CaCO3, no paper in its applications
--   WRONG POSITION    Nittetsu Mining - limestone by the centimetre, upstream of
--                     the filler industry rather than in it
--
-- evidence_level asks how well WE researched a row. market_role records what they
-- sell in prose nobody parses. fcc_fit was, until this week, mostly empty. Not
-- one of them separates these five from Okutama.
--
-- Add the two conflict axes found today - Taekyung is ADVERSE and Fimatec is
-- ENTANGLED with our own partner - and the roster has FIVE ways of being wrong,
-- against a schema that only knows how to be more or less confident.
--
-- Every single one was caught by opening the company's own website. Not one was
-- caught by a column.
-- ------------------------------------------------------------
--
-- No contact route recorded. Fourth time today. Maruo, Nittetsu, Takehara, and
-- now IMI Fabi - four companies with published addresses that stay out of this
-- database because a contact route on a non-target is how a wrong target becomes
-- a sent message.
--
-- IDEMPOTENT. Name-targeted. Nothing inserted.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

update app.filler_supplier_profile f
set extra_data = coalesce(f.extra_data, '{}'::jsonb) || '{"fcc_fit": {"verdict": "no", "reason": "NO CALCIUM CARBONATE. IMI Fabi describes itself as a mining and minerals company SPECIALISING IN THE PRODUCTION OF TALC, and its products page offers talc grades only - dark and coarse through ultrafine and high brightness. Talc is hydrated magnesium silicate. There is no CaCO3 line, so there is no plant for FCC to license. This is the Thiele Kaolin pattern exactly - a real mineral company with real paper business and the wrong mineral.", "checked_at": "2026-07-17", "source": "imifabi.com", "source_type": "marketing"}, "why_this_row_was_dangerous": {"they_do_serve_paper": "imifabi.com/74-Paper.html sells talc for PITCH CONTROL and DE-INKING - absorbing sticky resinous particles so they cannot re-agglomerate - plus talc in paper coating. Real paper business, real mill relationships, real technical service. Every signal this database can read says target.", "the_mineral_is_wrong": "FCC is a calcium carbonate grown on fibre. Talc cannot be that.", "checked_at": "2026-07-17"}, "they_are_a_competitor_not_a_licensee": {"their_words": "Their Product Development page states the expert team works to broaden opportunities for new applications, TO REPLACE OTHER MINERALS for more valuable opportunities rather than to discover brand new applications for talc.", "why_it_matters": "Replacing other minerals is the stated job. In the paper filler slot talc and PCC compete for the same position - Fimatec own paper page says talc and PCC both go to filler while GCC and kaolin go to coating. IMI Fabi competes for the slot FCC occupies.", "raised_at": "2026-07-17"}, "scale_for_the_record": {"founded": "1950s, Valmalenco, Sondrio, Italy", "footprint": "six mining sites, seven production and administrative sites, two joint ventures", "countries": ["Italy", "Western Australia - Mount Seabrook", "USA - West Virginia", "China", "Singapore", "Pakistan", "Brazil"], "industries": "plastic, paper, paints and fillers, animal feed, building coatings, ceramics, pharmaceuticals"}, "contactability": {"not_recorded": "No contact route recorded. Fourth time today after Maruo, Nittetsu and Takehara. A contact route on a non-target is how a wrong target becomes a sent message."}}'::jsonb,
    notes = coalesce(f.notes, '') || E'\n[homepage-check 2026-07-17] NOT AN FCC TARGET. IMI Fabi is a TALC company - no calcium carbonate anywhere on its site. The Thiele Kaolin pattern: real paper business (pitch control, de-inking, coating), real mill relationships, wrong mineral. Their own Product Development page says the job is to REPLACE OTHER MINERALS - in the paper filler slot, talc competes with PCC, so they are a competitor for the position FCC occupies rather than a licensee for it. Keep the row for market intelligence. Do not enrol, do not build a form.',
    updated_at = now()
from app.parties p
where f.party_id = p.id and p.party_name ~* 'imi ?fabi'
  and f.deleted_at is null and p.deleted_at is null
  and coalesce(f.notes, '') not like '%[homepage-check 2026-07-17]%';


-- ---------- VERIFY ----------
-- select p.party_name, p.country_code,
--        f.extra_data #>> '{fcc_fit,verdict}' as fcc_fit,
--        (select count(*) from app.contacts c where c.party_id = p.id and c.deleted_at is null) as contacts
-- from app.parties p
-- join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
-- where p.party_name ~* 'imi ?fabi' and p.deleted_at is null;


-- ---------- THE SWEEP, FOURTEEN OPENED ----------
--   Artemyn            TOP      - 17 carbonate plants, Chris Nutbeem at Par Moor
--   Okutama Kogyo      STRONG   - over 90% of Japanese paper PCC
--   Gulshan Polyols    STRONG   - satellite operator, pioneered on-site PCC in India
--   Bihoku Funka       STRONG   - neutral papermaking filler, cost-down, own mine
--   Shiraishi Group    STRONG   - UFPCC+PCC+GCC, open testing lab
--   20 Microns         STRONG   - PCC+GCC, sells TiO2 replacement already
--   Zantat             STRONG   - names its own partnership inbox
--   Q-min              moderate - GCC only, plastics-first, banknotes since 1999
--   Fimatec            HOLD     - runs on Specialty Minerals technology
--   F.M.T. (Thailand)  HOLD     - Fimatec subsidiary
--   Maruo Calcium      no       - CaCO3, no paper
--   Takehara Chemical  no       - CaCO3, no paper
--   Nittetsu Mining    no       - limestone, upstream of the filler industry
--   IMI Fabi           no       - talc, no CaCO3
--
-- FOURTEEN OPENED. SEVEN WORTH CONTACTING. SEVEN NOT.
-- Exactly half of what this database ranked as filler targets should not be
-- approached at all, and every removal came from one page on a company website.
--
-- Still unswept - Carmeuse USA, Kaolin (Malaysia), and roughly 63 more. The
-- country weights suggest where the next batches go: India 10, China 9, Poland 6,
-- Korea 5, Malaysia 5, Turkey 5, USA 4, Saudi 4, Mexico 4.
--
-- Carmeuse is worth doing next and worth doing carefully - it is a LIME company.
-- Quicklime and hydrated lime are the feedstock of PCC, not PCC. On the evidence
-- of Nittetsu, expect upstream rather than in.
