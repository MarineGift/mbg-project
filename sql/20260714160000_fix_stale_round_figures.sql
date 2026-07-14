-- =====================================================================
-- 20260714160000_fix_stale_round_figures.sql
-- Purpose: replace the old $5M / $30M-pre / $35M-post round terms with
--          the current $3M / $27M-pre / $30M-post across the 10 affected
--          per-field answers (1955 Capital, 3M Ventures, Lowercarbon).
--
-- Why full-string replacement (not str_replace on the number):
--   "$30,000,000" is the OLD pre-money AND the NEW post-money, so a
--   token replace would corrupt correct text. Each field below is set
--   to a complete, correct final_text matched by its exact old value.
--
-- Scope guard: matched by exact old final_text, so only stale rows change.
-- CTAN ($100k SAFE @ $10M cap) has different text and is never touched.
-- char_count is a GENERATED column - it recomputes automatically.
--
-- IMPORTANT - Lowercarbon Capital form is already 'submitted' with $5M.
--   This UPDATE fixes the stored record for consistency, but the investor
--   already received $5M. See the handoff for the one-line correction to
--   send if that thread reopens ("adjusted to $3M at $27M pre").
--
-- Run each part separately. Each UPDATE prints affected rows via RETURNING.
-- =====================================================================

-- ---------------------------------------------------------------------
-- PART 0: preview - the exact rows that will change (should be 10)
-- ---------------------------------------------------------------------
SELECT p.party_name, aff.label, af.status, afa.char_count
FROM app.application_field_answers afa
JOIN app.application_form_fields aff ON aff.id = afa.field_id
JOIN app.application_forms af        ON af.id = aff.form_id
JOIN app.parties p                   ON p.id = af.party_id
WHERE p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND p.party_name NOT ILIKE '%central texas angel%'
  AND (afa.final_text ILIKE '%5,000,000%'
    OR afa.final_text ILIKE '%35,000,000%'
    OR afa.final_text ILIKE '%30,000,000 USD pre%')
ORDER BY p.party_name, aff.seq, aff.label;

-- ---------------------------------------------------------------------
-- PART 1: "How much are you raising?"  (3 rows: 1955, 3M, Lowercarbon)
-- old: 5,000,000 @ 30,000,000 pre  ->  new: 3,000,000 @ 27,000,000 pre
-- ---------------------------------------------------------------------
UPDATE app.application_field_answers
SET final_text = '3,000,000 USD Series A at a 27,000,000 USD pre-money valuation.'
WHERE final_text = '5,000,000 USD Series A at a 30,000,000 USD pre-money valuation.'
RETURNING id, left(final_text, 60) AS new_text;

-- ---------------------------------------------------------------------
-- PART 2: "Deal terms / instrument"  (3 rows)
-- old: 5M @ 30M pre (35M post)  ->  new: 3M @ 27M pre (30M post)
-- ---------------------------------------------------------------------
UPDATE app.application_field_answers
SET final_text = 'Series A priced equity round: 3,000,000 USD at a 27,000,000 USD pre-money (30,000,000 USD post-money). Terms negotiable with a lead investor. Clean cap table: founder common shares only - no preferred stock, options, warrants, notes or other convertible securities outstanding.'
WHERE final_text = 'Series A priced equity round: 5,000,000 USD at a 30,000,000 USD pre-money (35,000,000 USD post-money). Terms negotiable with a lead investor. Clean cap table: founder common shares only - no preferred stock, options, warrants, notes or other convertible securities outstanding.'
RETURNING id, left(final_text, 70) AS new_text;

-- ---------------------------------------------------------------------
-- PART 3: "Use of funds"  (3 rows)
-- old: 5M split 2M/1.5M/1.5M  ->  new: 3M split 1M/1M/1M
--   (matches the Anzu answer already in the DB: applied R&D / IP / ops)
-- ---------------------------------------------------------------------
UPDATE app.application_field_answers
SET final_text = 'The 3,000,000 USD deploys across three workstreams over a 24-month runway. 1,000,000 USD: FCC applied research and commercialization across flame-retardant wallpaper, copy paper, packaging and tissue. 1,000,000 USD: patents and IP, including US patent prosecution and completion of the patent transfer. 1,000,000 USD: operations, covering US market validation, mill trials and business development.'
WHERE final_text = 'The 5,000,000 USD deploys across three workstreams over a 24-month runway. 2,000,000 USD: US production scale-up and pilot line. 1,500,000 USD: US market validation - an independent test at a national paper laboratory, commercial mill trials, and business development. 1,500,000 USD: IP consolidation including US patent prosecution and completion of the patent transfer, plus core operations.'
RETURNING id, left(final_text, 70) AS new_text;

-- ---------------------------------------------------------------------
-- PART 4: 3M Ventures "One-line company description" (1 row)
-- This field was mis-mapped: it holds the 480-char asset-light COST text
-- (also carrying $5M) instead of the real one-liner. Re-point it to the
-- correct 196-char one-liner (identical to the one used on every other
-- form) so it fits the 200-char limit AND drops the stale figure.
-- ---------------------------------------------------------------------
UPDATE app.application_field_answers afa
SET final_text = 'Marinebio Group makes FCC, a calcium carbonate filler grown in-situ on pulp fibers, letting paper mills replace costly pulp with low-cost filler without losing sheet strength. Patented, in market.'
FROM app.application_form_fields aff,
     app.application_forms af,
     app.parties p
WHERE aff.id = afa.field_id
  AND af.id = aff.form_id
  AND p.id  = af.party_id
  AND p.party_name = '3M Ventures'
  AND aff.label ILIKE '%one-line%'
  AND afa.final_text ILIKE '%asset-light%'
RETURNING afa.id, afa.char_count, left(afa.final_text, 60) AS new_text;

-- ---------------------------------------------------------------------
-- PART 5: verify - zero stale figures should remain (CTAN excluded)
-- Expect 0 rows.
-- ---------------------------------------------------------------------
SELECT p.party_name, aff.label, afa.char_count, afa.final_text
FROM app.application_field_answers afa
JOIN app.application_form_fields aff ON aff.id = afa.field_id
JOIN app.application_forms af        ON af.id = aff.form_id
JOIN app.parties p                   ON p.id = af.party_id
WHERE p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND p.party_name NOT ILIKE '%central texas angel%'
  AND (afa.final_text ILIKE '%5,000,000%'
    OR afa.final_text ILIKE '%35,000,000%'
    OR afa.final_text ILIKE '%30,000,000 USD pre%')
ORDER BY p.party_name, aff.label;

-- ---------------------------------------------------------------------
-- PART 6: over-limit re-check on the affected forms (expect 0 rows)
-- ---------------------------------------------------------------------
SELECT p.party_name, aff.label, aff.max_length, afa.char_count
FROM app.application_field_answers afa
JOIN app.application_form_fields aff ON aff.id = afa.field_id
JOIN app.application_forms af        ON af.id = aff.form_id
JOIN app.parties p                   ON p.id = af.party_id
WHERE p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND p.party_name IN ('1955 Capital', '3M Ventures', 'Lowercarbon Capital')
  AND aff.max_length IS NOT NULL
  AND afa.char_count > aff.max_length
ORDER BY p.party_name, aff.label;
