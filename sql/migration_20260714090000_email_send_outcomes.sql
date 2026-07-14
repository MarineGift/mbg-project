-- =====================================================================
-- migration_20260714090000_email_send_outcomes.sql
--
-- !! ALREADY APPLIED to production DB on 2026-07-14 !!
-- This copy was reconstructed from the session transcript on 2026-07-14
-- after the original download was lost, and is committed for schema
-- history / reproducibility. Part 1 is safe to re-run (IF NOT EXISTS /
-- OR REPLACE); Part 2 is a TEMPLATE and must not be run as-is.
--
-- Design notes:
--   * log/derived table -> NO created_by (per mbg SaaS conventions)
--   * organization_id carried for org scoping (copied from party)
--   * outcome vocabulary is a CHECK constraint (not enum) so new
--     outcome kinds never require a type migration
-- Run each part separately in Supabase SQL Editor.
-- =====================================================================

-- ---------------------------------------------------------------------
-- PART 0a: check for existing bounce/suppression infra (avoid duplication)
-- ---------------------------------------------------------------------
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'app'
  AND (table_name ILIKE '%bounce%'
    OR table_name ILIKE '%suppress%'
    OR table_name ILIKE '%blocklist%'
    OR table_name ILIKE '%outcome%')
ORDER BY table_name;

-- PART 0b: RLS policy convention on a sibling table (mirror it later)
SELECT policyname, cmd, qual
FROM pg_policies
WHERE schemaname = 'app'
  AND tablename = 'email_sequence_enrollments';

-- ---------------------------------------------------------------------
-- PART 1: outcome log table + indexes + do-not-send view
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS app.email_send_outcomes (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id  uuid,
  party_id         uuid REFERENCES app.parties(id),
  recipient_email  text NOT NULL,
  sequence_id      uuid,
  step_order       int,
  outcome          text NOT NULL CHECK (outcome IN (
                     'bounce_hard',        -- undeliverable, bad address
                     'bounce_soft',        -- mailbox full, temp failure
                     'send_failure',       -- SMTP/worker failure (MailCarrier alert)
                     'rejected_sector',    -- reply: not our sector / wrong fit
                     'rejected_stage',     -- reply: stage mismatch
                     'rejected_other',     -- reply: other decline
                     'unsubscribe_request',-- reply: asked to be removed
                     'auto_reply',         -- OOO / automated acknowledgement
                     'reply_positive',     -- human reply, interested
                     'reply_neutral'       -- human reply, unclear
                   )),
  reason           text,        -- free text: why / quote from the reply
  evidence_ref     text,        -- mail subject or message-id for audit
  next_action      text CHECK (next_action IN (
                     'suppress',           -- never email again
                     'resend_later',       -- retry after resend_not_before
                     'switch_deck',        -- re-approach with different deck
                     'switch_contact',     -- find another person at the firm
                     'follow_up',          -- positive: human follow-up owed
                     'none'
                   )) DEFAULT 'none',
  resend_not_before date,       -- only for resend_later
  source           text DEFAULT 'manual', -- manual | mailcarrier | worker
  occurred_at      timestamptz NOT NULL DEFAULT now(),
  created_at       timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_eso_recipient ON app.email_send_outcomes (lower(recipient_email));
CREATE INDEX IF NOT EXISTS idx_eso_party ON app.email_send_outcomes (party_id);
CREATE INDEX IF NOT EXISTS idx_eso_outcome ON app.email_send_outcomes (outcome);

-- Do-not-send view: one row per email address that must be excluded.
-- suppress rules: any hard bounce, unsubscribe, explicit suppress action,
-- or a resend_later still inside its cooling window.
CREATE OR REPLACE VIEW app.v_email_do_not_send AS
SELECT
  lower(recipient_email) AS email_lower,
  MAX(occurred_at) AS last_event_at,
  STRING_AGG(DISTINCT outcome, ', ') AS outcomes
FROM app.email_send_outcomes
WHERE outcome IN ('bounce_hard', 'unsubscribe_request')
   OR next_action = 'suppress'
   OR (next_action = 'resend_later' AND resend_not_before > CURRENT_DATE)
GROUP BY lower(recipient_email);

-- ---------------------------------------------------------------------
-- PART 2: TEMPLATE - record known outcomes. Fill in the real recipient
-- addresses from the mailbox before running. party_id is resolved by
-- name; adjust names if needed. Each INSERT is self-contained.
-- (The actual 2026-07-14 rows were recorded via this template and then
--  corrected/extended by 20260714100000_record_send_outcomes_batch1.sql)
-- ---------------------------------------------------------------------

-- 2a. Hard bounce: Undeliverable from postmaster@eclipsevc.onmicrosoft.com
INSERT INTO app.email_send_outcomes
  (organization_id, party_id, recipient_email, outcome, reason, evidence_ref, next_action, source)
SELECT p.organization_id, p.id, '[BOUNCED ADDRESS]', 'bounce_hard',
       'NDR from recipient mail system', 'Undeliverable: Re: 9,000-ton order confirmed (Seed round)',
       'suppress', 'manual'
FROM app.parties p
WHERE p.party_name = 'Eclipse Ventures';   -- adjust to the exact party_name

-- ---------------------------------------------------------------------
-- PART 3: send guard - REQUIRED in every future enrollment SQL.
-- Add this NOT EXISTS clause to the candidate WHERE block so any address
-- in the do-not-send view is excluded at query time.
-- ---------------------------------------------------------------------
-- AND NOT EXISTS (
--   SELECT 1 FROM app.v_email_do_not_send dns
--   WHERE dns.email_lower = lower(candidate.email)
-- )
