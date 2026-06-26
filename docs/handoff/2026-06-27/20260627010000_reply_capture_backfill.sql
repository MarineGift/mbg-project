-- =============================================================================
-- 20260627010000_reply_capture_backfill.sql
-- =============================================================================
-- Fix: replies / received emails not counted on the party Communications tab.
--
-- Root causes (code side fixed in src/lib/email/mailcarrier.ts):
--   1) A reply from a non-whitelisted address was dropped before storage.
--   2) An inbound reply whose sender is not a registered contact was stored
--      with party_id = NULL, so it never appeared on the party tab.
--   3) The original outbound's replied_at was never set, so "Replied" = 0.
--
-- This script is the RETROACTIVE half (code fix is forward-only):
--   Part A  diagnostics (read-only) -- find which case Founder Collective is in.
--   Part B  backfill (idempotent)   -- link orphan inbound replies + set replied_at.
--   Part C  verification.
--
-- Run in Supabase SQL Editor. Safe to re-run (only touches NULL party_id inbound
-- and NULL replied_at outbound rows).
--
-- Founder Collective party_id = 5acf0405-9888-460b-a7cd-594c159b2ec4
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Part A: DIAGNOSTICS (read-only) -- run these first, read the output.
-- -----------------------------------------------------------------------------

-- A1) Everything currently linked to Founder Collective.
--     If the reply is missing here, it is either orphaned (A2) or was never
--     stored (whitelist drop -> see handoff note on re-ingesting via UID reset).
SELECT id, direction, status, from_address, to_addresses, subject,
       occurred_at, replied_at, party_id, thread_id, in_reply_to
FROM app.communications
WHERE party_id = '5acf0405-9888-460b-a7cd-594c159b2ec4'
  AND deleted_at IS NULL
ORDER BY occurred_at;

-- A2) Orphan inbound (party_id NULL) that looks like a Founder Collective reply.
--     If a row shows up here, Part B will link it.
SELECT id, direction, from_address, subject, occurred_at,
       party_id, thread_id, in_reply_to
FROM app.communications
WHERE direction = 'inbound'
  AND deleted_at IS NULL
  AND party_id IS NULL
  AND (from_address ILIKE '%foundercollective.com'
       OR subject ILIKE '%Intel Inside%')
ORDER BY occurred_at DESC
LIMIT 20;


-- -----------------------------------------------------------------------------
-- Part B: BACKFILL (idempotent).
-- -----------------------------------------------------------------------------

-- B1) Link orphan inbound replies to the party/contact/engagement of the
--     outbound they reply to (exact in_reply_to match, else shared thread_id).
WITH orphan AS (
  SELECT DISTINCT ON (i.id)
         i.id          AS inbound_id,
         o.party_id    AS party_id,
         o.contact_id  AS contact_id,
         o.engagement_id AS engagement_id
  FROM app.communications i
  JOIN app.communications o
    ON o.organization_id = i.organization_id
   AND o.direction = 'outbound'
   AND o.deleted_at IS NULL
   AND o.party_id IS NOT NULL
   AND o.occurred_at <= i.occurred_at
   AND (
        (i.in_reply_to IS NOT NULL AND o.message_id = i.in_reply_to)
     OR (i.thread_id   IS NOT NULL AND o.thread_id   = i.thread_id)
       )
  WHERE i.direction = 'inbound'
    AND i.deleted_at IS NULL
    AND i.party_id IS NULL
  ORDER BY i.id, o.occurred_at DESC   -- nearest preceding outbound wins
)
UPDATE app.communications c
SET party_id      = orphan.party_id,
    contact_id    = COALESCE(c.contact_id, orphan.contact_id),
    engagement_id = COALESCE(c.engagement_id, orphan.engagement_id)
FROM orphan
WHERE c.id = orphan.inbound_id;

-- B2) Set replied_at on outbound messages that have an inbound reply.
WITH replied AS (
  SELECT o.id AS outbound_id, MIN(i.occurred_at) AS first_reply_at
  FROM app.communications o
  JOIN app.communications i
    ON i.organization_id = o.organization_id
   AND i.direction = 'inbound'
   AND i.deleted_at IS NULL
   AND i.occurred_at >= o.occurred_at
   AND (
        (i.in_reply_to IS NOT NULL AND i.in_reply_to = o.message_id)
     OR (i.thread_id   IS NOT NULL AND i.thread_id   = o.thread_id)
       )
  WHERE o.direction = 'outbound'
    AND o.deleted_at IS NULL
    AND o.replied_at IS NULL
  GROUP BY o.id
)
UPDATE app.communications c
SET replied_at = replied.first_reply_at
FROM replied
WHERE c.id = replied.outbound_id;


-- -----------------------------------------------------------------------------
-- Part C: VERIFICATION.
-- -----------------------------------------------------------------------------

-- C1) Founder Collective thread after backfill (expect an inbound row now,
--     and the outbound replied_at populated).
SELECT direction, status, from_address, subject,
       occurred_at, replied_at, party_id
FROM app.communications
WHERE party_id = '5acf0405-9888-460b-a7cd-594c159b2ec4'
  AND deleted_at IS NULL
ORDER BY occurred_at;

-- C2) Stats RPC the Communications tab reads (expect received >= 1, replied >= 1).
SELECT * FROM app.get_communications_stats_per_party(
  '5acf0405-9888-460b-a7cd-594c159b2ec4'
);

-- =============================================================================
-- If A1 + A2 are BOTH empty for the reply, the message was never stored
-- (whitelist drop). After deploying the mailcarrier.ts fix, re-ingest it by
-- resetting the IMAP checkpoint for the receiving mailbox so the carrier
-- re-reads recent UIDs, e.g. (adjust the kind/account to the receiving box):
--
--   UPDATE app.mailcarrier_state
--   SET last_processed_uid = GREATEST(last_processed_uid - 20, 0)
--   WHERE kind = 'account';   -- and/or filter by the specific mailbox id
--
-- Then let the carrier run one cycle and re-check Part C.
-- =============================================================================
