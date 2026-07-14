-- =============================================================================
-- 20260713170000_investor_send_audit.sql   (READ-ONLY — safe to run anytime)
-- =============================================================================
-- Answers: "who can we still send to?"  Run each block in the Supabase SQL
-- Editor and read the counts. Nothing is written.
--
-- Definitions:
--   sendable   = investor party with a non-empty email, not soft-deleted.
--   enrolled   = already active/completed in ANY email sequence
--                (so we don't double-send).
--   reachable-but-not-yet-sent = sendable AND not enrolled anywhere.
--   no-email   = investor party with NULL/'' email (needs backfill first).
-- =============================================================================

-- 0) One-line summary of the whole investor base.
WITH inv AS (
  SELECT DISTINCT p.id, p.party_name, NULLIF(TRIM(p.email), '') AS email
  FROM app.parties p
  JOIN app.investor_profile ip ON ip.party_id = p.id
  WHERE p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
    AND p.deleted_at IS NULL
),
enr AS (
  SELECT DISTINCT party_id
  FROM app.email_sequence_enrollments
  WHERE status IN ('active','completed')
)
SELECT
  COUNT(*)                                                       AS total_investors,
  COUNT(*) FILTER (WHERE email IS NOT NULL)                      AS have_email,
  COUNT(*) FILTER (WHERE email IS NULL)                          AS missing_email,
  COUNT(*) FILTER (WHERE email IS NOT NULL
                     AND id IN (SELECT party_id FROM enr))       AS already_enrolled,
  COUNT(*) FILTER (WHERE email IS NOT NULL
                     AND id NOT IN (SELECT party_id FROM enr))   AS reachable_not_sent
FROM inv;


-- 1) REACHABLE-BUT-NOT-YET-SENT — the actual "we can still send to these" list.
--    (has email, not enrolled in any sequence yet)
WITH enr AS (
  SELECT DISTINCT party_id
  FROM app.email_sequence_enrollments
  WHERE status IN ('active','completed')
)
SELECT p.party_name, LOWER(TRIM(p.email)) AS email,
       COALESCE(string_agg(DISTINCT s.code, ', '), '(no sector)') AS sectors
FROM app.parties p
JOIN app.investor_profile ip           ON ip.party_id = p.id
LEFT JOIN app.investor_sector_focus isf ON isf.investor_profile_id = ip.id
LEFT JOIN app.sectors s                 ON s.id = isf.sector_id
WHERE p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND p.deleted_at IS NULL
  AND NULLIF(TRIM(p.email), '') IS NOT NULL
  AND p.id NOT IN (SELECT party_id FROM enr)
GROUP BY p.party_name, p.email
ORDER BY p.party_name;


-- 2) MISSING EMAIL — investors we cannot reach until an email is added.
--    Ordered so the biggest climate names surface (edit ORDER BY as you like).
SELECT p.party_name,
       COALESCE(string_agg(DISTINCT s.code, ', '), '(no sector)') AS sectors,
       p.website
FROM app.parties p
JOIN app.investor_profile ip            ON ip.party_id = p.id
LEFT JOIN app.investor_sector_focus isf ON isf.investor_profile_id = ip.id
LEFT JOIN app.sectors s                  ON s.id = isf.sector_id
WHERE p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND p.deleted_at IS NULL
  AND NULLIF(TRIM(p.email), '') IS NULL
GROUP BY p.party_name, p.website
ORDER BY p.party_name;


-- 3) ALREADY ENROLLED — sanity check of who is already in a sequence + where.
SELECT p.party_name, seq.name AS sequence_name, e.status,
       e.next_step_order,
       e.next_send_at AT TIME ZONE 'America/Los_Angeles' AS next_send_pt
FROM app.email_sequence_enrollments e
JOIN app.parties p          ON p.id = e.party_id
JOIN app.email_sequences seq ON seq.id = e.sequence_id
WHERE e.status IN ('active','completed')
ORDER BY p.party_name, seq.name;
