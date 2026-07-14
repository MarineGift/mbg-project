-- =====================================================================
-- 20260714180000_extend_do_not_send_contacted.sql
-- Purpose: make "already contacted via a form OR already replied" flow
--          into the same do-not-send gate that enrollment SQL uses, so
--          those recipients are dropped from the NEXT send automatically.
--
-- Two new exclusion sources, added to the existing view:
--   (A) application_forms.status IN ('submitted','decided')
--       -> we already applied to that investor via their web form.
--   (B) email_send_outcomes with a human reply / decline
--       (reply_positive, reply_neutral, rejected_sector/stage/other,
--        unsubscribe_request) -> they already answered; do not cold-mail again.
--   (the original view already covered bounce_hard / unsubscribe / suppress
--    / resend_later cooldown - kept as-is.)
--
-- Matching:
--   The old view keyed on email only. Forms are party-level and may have
--   no email, so the new view resolves BOTH:
--     * email_lower  (for the enrollment-SQL guard, unchanged shape)
--     * party_id     (new column, for party-level bulk exclusion)
--   Every party's contact emails are expanded so a form submission blocks
--   all of that party's addresses on the next send.
--
-- reply_positive is excluded from cold sends too, but flagged as a
-- follow-up so it is not mistaken for a dead end.
--
-- Idempotent: CREATE OR REPLACE VIEW. Enrollment guard SQL keeps working
-- unchanged (still selects dns.email_lower). Run in Supabase SQL Editor.
-- =====================================================================

CREATE OR REPLACE VIEW app.v_email_do_not_send AS
WITH outcome_block AS (
  -- (B) + original outcome-based blocks, now party-aware
  SELECT
    lower(o.recipient_email)                      AS email_lower,
    o.party_id                                    AS party_id,
    MAX(o.occurred_at)                            AS last_event_at,
    STRING_AGG(DISTINCT o.outcome, ', ')          AS reasons,
    bool_or(o.outcome = 'reply_positive'
         OR o.next_action = 'follow_up')          AS is_follow_up
  FROM app.email_send_outcomes o
  WHERE o.outcome IN (
          'bounce_hard', 'unsubscribe_request',
          'reply_positive', 'reply_neutral',
          'rejected_sector', 'rejected_stage', 'rejected_other'
        )
     OR o.next_action = 'suppress'
     OR (o.next_action = 'resend_later' AND o.resend_not_before > CURRENT_DATE)
  GROUP BY lower(o.recipient_email), o.party_id
),
form_block AS (
  -- (A) submitted / decided web-form applications, expanded to the
  -- party's contact emails.
  SELECT
    lower(c.email)                                AS email_lower,
    af.party_id                                   AS party_id,
    MAX(COALESCE(af.submitted_at, af.updated_at)) AS last_event_at,
    'form_' || MIN(af.status)                     AS reasons,
    false                                         AS is_follow_up
  FROM app.application_forms af
  JOIN app.contacts c ON c.party_id = af.party_id
  WHERE af.status IN ('submitted', 'decided')
    AND c.email IS NOT NULL
    AND btrim(c.email) <> ''
  GROUP BY lower(c.email), af.party_id
),
form_block_partyonly AS (
  -- form submissions where the party has NO contact email: party-level
  -- block only (email_lower NULL). Keeps the party out of party-based
  -- bulk sends even without a resolvable address.
  SELECT
    NULL::text                                    AS email_lower,
    af.party_id                                   AS party_id,
    MAX(COALESCE(af.submitted_at, af.updated_at)) AS last_event_at,
    'form_' || MIN(af.status)                     AS reasons,
    false                                         AS is_follow_up
  FROM app.application_forms af
  WHERE af.status IN ('submitted', 'decided')
    AND NOT EXISTS (
      SELECT 1 FROM app.contacts c
      WHERE c.party_id = af.party_id
        AND c.email IS NOT NULL
        AND btrim(c.email) <> ''
    )
  GROUP BY af.party_id
),
unioned AS (
  SELECT * FROM outcome_block
  UNION ALL
  SELECT * FROM form_block
  UNION ALL
  SELECT * FROM form_block_partyonly
)
SELECT
  email_lower,
  party_id,
  MAX(last_event_at)                 AS last_event_at,
  STRING_AGG(DISTINCT reasons, ', ') AS outcomes,
  bool_or(is_follow_up)              AS is_follow_up
FROM unioned
GROUP BY email_lower, party_id;

-- ---------------------------------------------------------------------
-- VERIFY 1: shape unchanged for the enrollment guard (email_lower still
-- present). The guard `WHERE dns.email_lower = lower(candidate.email)`
-- keeps working; the extra party_id / is_follow_up columns are additive.
-- ---------------------------------------------------------------------
SELECT email_lower, party_id, outcomes, is_follow_up, last_event_at
FROM app.v_email_do_not_send
ORDER BY last_event_at DESC NULLS LAST
LIMIT 50;

-- VERIFY 2: how many NEW blocks came from forms vs outcomes.
SELECT
  COUNT(*) FILTER (WHERE outcomes LIKE 'form_%')              AS from_forms,
  COUNT(*) FILTER (WHERE outcomes NOT LIKE '%form_%')         AS from_outcomes_only,
  COUNT(*) FILTER (WHERE is_follow_up)                        AS follow_up_flagged,
  COUNT(*)                                                    AS total_blocked
FROM app.v_email_do_not_send;

-- ---------------------------------------------------------------------
-- VERIFY 3: party-level guard usage example for FUTURE enrollment SQL.
-- Old email-only guard still valid; this is the stronger party-level one:
--
--   AND NOT EXISTS (
--     SELECT 1 FROM app.v_email_do_not_send dns
--     WHERE dns.email_lower = lower(candidate.email)
--        OR dns.party_id    = candidate.party_id
--   )
--
-- Use the party_id branch when you want a single form submission to block
-- every address at that firm, not just the one you happened to mail.
-- ---------------------------------------------------------------------
SELECT 'see comment above for the party-level guard snippet' AS note;
