-- =====================================================================
-- migration_20260715010100_v_enrollment_send_health_sequence_status.sql
--
-- Companion to migration_20260715010000_guard_sequence_status_get_due_
-- enrollments.sql. Apply in the SAME session, right after it.
--
-- Why this file exists at all
--   migration_20260714235500 (the original view) says in its own header:
--       "This view REPLICATES that resolution exactly, so preflight and
--        the worker can never drift apart again. If get_due_enrollments
--        changes, change this view in the same commit."
--   010000 adds a guard to the function. Without this file the view would
--   report send_status = 'ok' for an enrollment sitting in a paused
--   sequence that the worker will now refuse to send. A preflight surface
--   that over-reports 'ok' is the exact failure the view was built to end.
--
-- Two changes, both additive.
--   1. New send_status value 'sequence_inactive' -- the parent sequence is
--      not 'active' (draft / paused / archived), so [G3] holds the send.
--      Ranked directly under 'inactive': if the sequence is off, nothing
--      about the address matters.
--   2. New TRAILING column sequence_status, so the reason is legible
--      without a second query.
--
-- CREATE OR REPLACE VIEW can only APPEND columns -- it cannot insert into
-- the middle or retype. sequence_status therefore goes last, after
-- send_status. Changing the VALUE of the existing send_status expression
-- is fine; its name, position and type are unchanged.
--
-- Consumer check (2026-07-15): grepped src/ for v_enrollment_send_health
-- -> zero hits. This view is read from the SQL Editor only, so the new
-- send_status value cannot break tsc. get_due_enrollments keeps its exact
-- return signature, so src/types/database.ts needs no regeneration either.
--
-- [G1] (48h min-gap) is still NOT modelled here. It is a function of when
-- the worker runs, not a standing property of the enrollment. The view
-- answers "would this send if it came due", not "will it send at 09:00".
--
-- Read-only view. Safe to re-run.
--
-- send_status vocabulary (updated):
--   ok                 -> will send
--   no_email           -> all three fallbacks NULL, worker marks it skipped
--   malformed_email    -> resolved address fails a basic shape check
--   no_matching_step   -> no step row at next_step_order, silently never due
--   do_not_send_party  -> app.v_email_do_not_send has a row for this party
--   do_not_send_email  -> app.v_email_do_not_send has a row for this address
--   sequence_inactive  -> parent sequence is not active  [NEW]
--   inactive           -> enrollment itself is not active (informational)
--
-- Rollback: re-run migration_20260714235500_v_enrollment_send_health.sql.
-- Note that dropping the trailing column requires DROP VIEW first, so the
-- rollback of this file alone is a DROP + CREATE, not a REPLACE.
-- =====================================================================

CREATE OR REPLACE VIEW app.v_enrollment_send_health AS
WITH resolved AS (
  SELECT
    e.id                                                       AS enrollment_id,
    e.organization_id,
    e.sequence_id,
    s.name                                                     AS sequence_name,
    s.status::text                                             AS sequence_status,
    e.party_id,
    p.party_name,
    e.status::text                                             AS enrollment_status,
    e.next_step_order,
    e.next_send_at,
    COALESCE(NULLIF(e.recipient_email, ''), ct.email, p.email) AS resolved_email,
    CASE
      WHEN NULLIF(e.recipient_email, '') IS NOT NULL THEN 'enrollment.recipient_email'
      WHEN ct.email IS NOT NULL                      THEN 'contacts.email'
      WHEN p.email IS NOT NULL                       THEN 'parties.email'
      ELSE 'none'
    END                                                        AS email_source,
    EXISTS (
      SELECT 1
      FROM app.email_sequence_steps st
      WHERE st.sequence_id = e.sequence_id
        AND st.step_order  = e.next_step_order
    )                                                          AS has_step
  FROM app.email_sequence_enrollments e
  JOIN app.email_sequences s ON s.id = e.sequence_id
  JOIN app.parties p         ON p.id = e.party_id
  -- identical LATERAL to get_due_enrollments: same filters, same ORDER BY.
  LEFT JOIN LATERAL (
    SELECT c.id, c.email
    FROM app.contacts c
    WHERE c.party_id = e.party_id
      AND c.deleted_at IS NULL
      AND c.email IS NOT NULL
      AND (e.contact_id IS NULL OR c.id = e.contact_id)
    ORDER BY
      (c.id = e.contact_id) DESC NULLS LAST,
      c.is_primary DESC NULLS LAST,
      c.created_at ASC
    LIMIT 1
  ) ct ON TRUE
)
SELECT
  r.enrollment_id,
  r.organization_id,
  r.sequence_id,
  r.sequence_name,
  r.party_id,
  r.party_name,
  r.enrollment_status,
  r.next_step_order,
  r.next_send_at,
  r.resolved_email,
  r.email_source,
  CASE
    WHEN r.enrollment_status <> 'active' THEN 'inactive'
    -- [G3] parent sequence off -> nothing else about this row matters.
    WHEN r.sequence_status   <> 'active' THEN 'sequence_inactive'
    WHEN NOT r.has_step                  THEN 'no_matching_step'
    WHEN r.resolved_email IS NULL        THEN 'no_email'
    WHEN r.resolved_email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'
                                         THEN 'malformed_email'
    WHEN EXISTS (
      SELECT 1 FROM app.v_email_do_not_send d
      WHERE d.party_id = r.party_id
    )                                    THEN 'do_not_send_party'
    WHEN EXISTS (
      SELECT 1 FROM app.v_email_do_not_send d
      WHERE d.email_lower = lower(r.resolved_email)
    )                                    THEN 'do_not_send_email'
    ELSE 'ok'
  END AS send_status,
  -- trailing column: CREATE OR REPLACE VIEW cannot insert mid-list.
  r.sequence_status
FROM resolved r;
