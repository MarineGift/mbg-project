-- =====================================================================
-- 20260714140000_form_submission_worklist.sql   (READ-ONLY checklist)
-- Purpose: one-screen submission checklist for the form blitz, ordered
--          by the playbook priority. Pulls the form URL, status,
--          deadline, and stored form fields so you can fill each form
--          from the answer bank in handoff_form_submission_playbook.
--
-- No writes. Export to CSV from the SQL editor and work top-down.
-- Two sources of truth are joined:
--   * app.application_forms       (form_url / status / deadline)  -- if seeded
--   * app.parties.contact_form_url + preferred_contact_method     -- fallback
--
-- Submission order (playbook):
--   P1 (10): 1955, Azolla, CEV, Emerald, Lowercarbon, Newlab, GGC,
--            CTAN, mHUB, Toyota
--   Tier 2 : Anzu, Breakout, SOSV, P&G (conditional)
--   Non-dilutive: NSF (verify eligibility first), Third Derivative, VFC
--   Plus  : SWAN
-- =====================================================================

-- ---------------------------------------------------------------------
-- PART 0: confirm exact party_name spellings for the priority list.
-- Adjust the ILIKE fragments in Part 1 if any come back empty/renamed.
-- ---------------------------------------------------------------------
SELECT p.id, p.party_name,
       p.preferred_contact_method AS how,
       p.contact_form_url,
       p.website,
       (p.id IN (SELECT party_id FROM app.application_forms)) AS has_form_row
FROM app.parties p
WHERE p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND p.deleted_at IS NULL
  AND (
       p.party_name ILIKE '%1955%'
    OR p.party_name ILIKE '%azolla%'
    OR p.party_name ILIKE '%cev%' OR p.party_name ILIKE '%clean energy ventures%'
    OR p.party_name ILIKE '%emerald%'
    OR p.party_name ILIKE '%lowercarbon%'
    OR p.party_name ILIKE '%newlab%'
    OR p.party_name ILIKE '%ggc%' OR p.party_name ILIKE '%green generation%'
    OR p.party_name ILIKE '%ctan%' OR p.party_name ILIKE '%central texas angel%'
    OR p.party_name ILIKE '%mhub%'
    OR p.party_name ILIKE '%toyota%'
    OR p.party_name ILIKE '%anzu%'
    OR p.party_name ILIKE '%breakout%'
    OR p.party_name ILIKE '%sosv%'
    OR p.party_name ILIKE '%procter%' OR p.party_name ILIKE '%p&g%'
    OR p.party_name ILIKE '%third derivative%'
    OR p.party_name ILIKE '%venture for climate%' OR p.party_name ILIKE '%vfc%'
    OR p.party_name ILIKE '%swan%'
    OR p.party_name ILIKE '%nsf%' OR p.party_name ILIKE '%national science%'
  )
ORDER BY p.party_name;

-- ---------------------------------------------------------------------
-- PART 1: the actual submission checklist, in priority order.
-- prio: 1 = P1, 2 = tier2, 3 = non-dilutive, 4 = plus.
-- Uses a fixed priority CTE so the output is already in work order.
-- ---------------------------------------------------------------------
WITH prio(pat, prio, label) AS (
  VALUES
    ('%1955%',                  1, '1955 Capital'),
    ('%azolla%',                1, 'Azolla Ventures'),
    ('%clean energy ventures%', 1, 'Clean Energy Ventures (CEV)'),
    ('%emerald%',               1, 'Emerald Technology Ventures'),
    ('%lowercarbon%',           1, 'Lowercarbon Capital'),
    ('%newlab%',                1, 'Newlab'),
    ('%green generation%',      1, 'GGC / Green Generation'),
    ('%central texas angel%',   1, 'CTAN'),
    ('%mhub%',                  1, 'mHUB'),
    ('%toyota%',                1, 'Toyota Ventures'),
    ('%anzu%',                  2, 'Anzu Partners'),
    ('%breakout%',              2, 'Breakout Ventures'),
    ('%sosv%',                  2, 'SOSV'),
    ('%procter%',               2, 'P&G (conditional)'),
    ('%national science%',      3, 'NSF SBIR (verify eligibility!)'),
    ('%third derivative%',      3, 'Third Derivative'),
    ('%venture for climate%',   3, 'VFC'),
    ('%swan%',                  4, 'SWAN')
)
SELECT
  x.prio,
  x.label,
  p.party_name,
  COALESCE(af.status, 'no_form_row')                 AS form_status,
  COALESCE(af.form_url, p.contact_form_url, p.website) AS submit_url,
  af.deadline,
  CASE WHEN af.deadline IS NOT NULL
       THEN af.deadline - CURRENT_DATE END           AS days_to_deadline,
  p.preferred_contact_method                          AS how,
  af.notes
FROM prio x
LEFT JOIN app.parties p
       ON p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
      AND p.deleted_at IS NULL
      AND p.party_name ILIKE x.pat
LEFT JOIN app.application_forms af
       ON af.party_id = p.id
ORDER BY x.prio, x.label;

-- ---------------------------------------------------------------------
-- PART 2: stored form fields + bound answers for the seeded forms
--         (Anzu / Azolla / CEV / blitz batch1 were seeded on 7/10).
-- Shows each question, the answer you bound, its length, and the NDA
-- disclosure guard, so you can paste straight into the web form and
-- catch any over-limit or nda_only fields.
-- Column names confirmed against migration_025:
--   fields  : form_id, seq, label, max_length
--   answers : field_id, final_text, char_count (generated)
--   nda tag : answer_library.disclosure_level (via answer_id)
-- ---------------------------------------------------------------------
SELECT
  p.party_name,
  aff.label,
  aff.max_length,
  afa.char_count                       AS answer_len,
  CASE WHEN aff.max_length IS NOT NULL
        AND afa.char_count > aff.max_length
       THEN 'OVER LIMIT' ELSE 'ok' END AS fit,
  COALESCE(al.disclosure_level, 'unbound') AS disclosure,
  CASE WHEN al.disclosure_level = 'nda_only'
       THEN 'DO NOT PASTE' ELSE '' END  AS nda_guard,
  afa.final_text
FROM app.application_forms af
JOIN app.parties p                        ON p.id = af.party_id
JOIN app.application_form_fields aff       ON aff.form_id = af.id
LEFT JOIN app.application_field_answers afa ON afa.field_id = aff.id
LEFT JOIN app.answer_library al            ON al.id = afa.answer_id
WHERE p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
ORDER BY p.party_name, aff.seq, aff.label;

-- ---------------------------------------------------------------------
-- PART 3: deadline radar - anything with a deadline, soonest first,
-- not yet submitted. NSF full proposal 2026-11-04 should appear here.
-- ---------------------------------------------------------------------
SELECT p.party_name, af.form_type, af.status, af.deadline,
       af.deadline - CURRENT_DATE AS days_left, af.form_url
FROM app.application_forms af
JOIN app.parties p ON p.id = af.party_id
WHERE af.status <> 'decided'
  AND af.deadline IS NOT NULL
ORDER BY af.deadline;
