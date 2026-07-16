-- ============================================================
-- enrich_smi_contacts_2026-07-16.sql
--
-- The 3 contacts on Specialty Minerals (HQ) 9f161ff5-c369-4ca2-8a22-46a1ec40fd0d
-- came from inbound_backfill_2026Q2 as BARE EMAILS - full_name, title_text,
-- department, phone all null, is_primary and is_decision_maker both false.
-- Nobody knew who they were, so nobody could act on them.
--
-- THE FIND: sharad.mathur@mineralstech.com is Director, Research and New Product
-- and Business Development, PAPER AND PACKAGING at Minerals Technologies. At an
-- MTI investor day he presented on "crystal engineering" - MTI's proprietary
-- control of particle size, size distribution and SHAPE to hit a target
-- particle, explicitly including ground calcium carbonate from limestone, for
-- paper and packaging among other markets.
--
-- That is the FCC conversation, held by the incumbent, in public, on the record.
-- Of every human currently in this pipeline he is the most relevant single
-- contact for an FCC licensing discussion - he owns new product and business
-- development for paper at the company FCC has to displace.
--
-- CAUTION BEFORE OUTREACH: a January 2019 press release has a Dr Sharad Mathur
-- appointed CTO of Applied Minerals, and ResearchGate still lists him there.
-- theorg, ZoomInfo and the MTI investor transcript all place him at MTI in the
-- paper role. Same person moving between companies, or two people - VERIFY on
-- LinkedIn before contacting. Recorded as unconfirmed rather than asserted.
--
-- uuid-targeted UPDATE on app.contacts. NOTHING IS INSERTED.
-- Column names taken from enrich_mlc_us_filler_2026-07-16.sql, which inserted 13
-- contacts successfully - title_text not title, is_decision_maker not
-- decision_maker. The scan file guessed and got 42703.
--
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 1) Sharad Mathur - the one that matters ----------
update app.contacts c
set given_name  = coalesce(c.given_name, 'Sharad'),
    family_name = coalesce(c.family_name, 'Mathur'),
    full_name   = coalesce(c.full_name, 'Sharad Mathur'),
    title_text  = coalesce(c.title_text, 'Director, Research and New Product and Business Development, Paper and Packaging'),
    department  = coalesce(c.department, 'Paper and Packaging'),
    is_primary  = true,
    is_decision_maker = true,
    notes = coalesce(c.notes, '') || E'\n[smi-contact 2026-07-16] TOP FCC-RELEVANT CONTACT IN THE PIPELINE. Owns new product and business development for paper and packaging at Minerals Technologies - the incumbent satellite PCC operator. Presented at an MTI investor day on crystal engineering, MTI proprietary control of particle size, distribution and shape to reach a target particle, naming ground calcium carbonate from limestone and the paper and packaging market. Same technical territory as FCC. Based in Charlotte per LinkedIn. UNCONFIRMED - a 2019 release names a Dr Sharad Mathur as CTO of Applied Minerals and ResearchGate still shows that. Verify current employer on LinkedIn before any outreach. Sources - theorg, ZoomInfo, MTI investor day transcript on investors.mineralstech.com.',
    updated_at = now()
where c.id = '47a2532b-7870-4d1e-a672-515957fda4ad'::uuid
  and c.deleted_at is null
  and coalesce(c.notes, '') not like '%[smi-contact 2026-07-16]%';

-- ---------- 2) Raina Wickkiser ----------
update app.contacts c
set given_name  = coalesce(c.given_name, 'Raina'),
    family_name = coalesce(c.family_name, 'Wickkiser'),
    full_name   = coalesce(c.full_name, 'Raina Wickkiser'),
    title_text  = coalesce(c.title_text, 'Inside Sales and Systems Manager'),
    department  = coalesce(c.department, 'Sales'),
    notes = coalesce(c.notes, '') || E'\n[smi-contact 2026-07-16] Inside Sales and Systems Manager at Minerals Technologies since February 2014, previously Sales and Marketing Analyst at the same company. Operational sales rather than a decision maker - useful as a routing and logistics contact, not for a licensing conversation. Source - theorg.',
    updated_at = now()
where c.id = 'b2347bab-fc38-41f7-a201-8cc55c085dff'::uuid
  and c.deleted_at is null
  and coalesce(c.notes, '') not like '%[smi-contact 2026-07-16]%';

-- ---------- 3) Ken Mueller - name only, role unknown ----------
update app.contacts c
set given_name  = coalesce(c.given_name, 'Ken'),
    family_name = coalesce(c.family_name, 'Mueller'),
    full_name   = coalesce(c.full_name, 'Ken Mueller'),
    notes = coalesce(c.notes, '') || E'\n[smi-contact 2026-07-16] Name inferred from the email local-part only. No public role found for a Ken Mueller at Minerals Technologies in this pass. Title and department deliberately left null rather than guessed. Needs a LinkedIn check.',
    updated_at = now()
where c.id = 'a1e2263b-f712-4c25-a2b7-eb68e6edab78'::uuid
  and c.deleted_at is null
  and coalesce(c.notes, '') not like '%[smi-contact 2026-07-16]%';

-- ---------- 4) VERIFY ----------
-- select c.full_name, c.title_text, c.department, c.email,
--        c.is_primary, c.is_decision_maker
-- from app.contacts c
-- where c.party_id = '9f161ff5-c369-4ca2-8a22-46a1ec40fd0d'::uuid
--   and c.deleted_at is null
-- order by c.is_decision_maker desc, c.full_name;
-- expect 3 named rows, Sharad Mathur primary and decision maker

-- ---------- 5) WHY THIS SETTLES PART OF THE 4-ROW QUESTION ----------
-- These 3 contacts hang off 9f161ff5 Specialty Minerals (HQ). Whatever the merge
-- decides, 9f161ff5 is the KEEPER - it is the only one of the four SMI/MTI rows
-- with anything attached. The other three can be folded away, but blocks 1 and 2
-- of scan_us_smi_mti_structure are still needed before writing that file.
