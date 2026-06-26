-- =============================================================================
-- 20260627010000_reply_capture_backfill.sql  (v2)
-- =============================================================================
-- Fix: replies / received emails not counted on the party Communications tab.
--
-- Confirmed root cause (Founder Collective): the sequence was sent to the firm's
-- general inbox (parties.email = contact@foundercollective.com) with NO contact
-- row. matchSenderToContactAndParty only matched contacts.email, so the reply
-- from that same address landed orphaned (party_id = NULL) and never showed on
-- the party tab. (Code fix: header-parser.ts now matches parties.email too;
-- mailcarrier.ts bypasses whitelist for thread replies + sets replied_at.)
--
-- This is the RETROACTIVE half (code fix is forward-only). Idempotent.
-- Run in Supabase SQL Editor: read Part A, run Part B, confirm Part C.
--
-- Founder Collective party_id = 5acf0405-9888-460b-a7cd-594c159b2ec4
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Part A: DIAGNOSTICS (read-only)
-- -----------------------------------------------------------------------------

-- A1) The orphan inbound reply we can see in the inbox
--     (from contact@foundercollective.com). Expect party_id = NULL.
SELECT id, direction, status, from_address, subject,
       occurred_at, party_id, thread_id, in_reply_to
FROM app.communications
WHERE direction = 'inbound'
  AND deleted_at IS NULL
  AND from_address ILIKE '%foundercollective.com'
ORDER BY occurred_at DESC;

-- A2) Every orphan inbound whose sender equals some party's email
--     (the whole party-level-outreach pattern, not just FC).
SELECT i.id, i.from_address, i.subject, i.occurred_at, p.party_name
FROM app.communications i
JOIN app.parties p
  ON p.organization_id = i.organization_id
 AND p.deleted_at IS NULL
 AND LOWER(p.email) = LOWER(i.from_address)
WHERE i.direction = 'inbound'
  AND i.deleted_at IS NULL
  AND i.party_id IS NULL
ORDER BY i.occurred_at DESC;


-- -----------------------------------------------------------------------------
-- Part B: BACKFILL (idempotent)
-- -----------------------------------------------------------------------------

-- B1) Link orphan inbound to the party whose email matches the sender
--     (mirrors the new parties.email match in code). Fixes FC and all
--     party-level-outreach replies at once.
UPDATE app.communications i
SET party_id = p.id
FROM app.parties p
WHERE i.direction = 'inbound'
  AND i.deleted_at IS NULL
  AND i.party_id IS NULL
  AND p.deleted_at IS NULL
  AND p.email IS NOT NULL
  AND LOWER(i.from_address) = LOWER(p.email);

-- B2) Link any remaining orphans via the thread (in_reply_to -> message_id,
--     else shared thread_id) using the original outbound's party.
WITH orphan AS (
  SELECT DISTINCT ON (i.id)
         i.id AS inbound_id,
         o.party_id, o.contact_id, o.engagement_id
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
  ORDER BY i.id, o.occurred_at DESC
)
UPDATE app.communications c
SET party_id      = orphan.party_id,
    contact_id    = COALESCE(c.contact_id, orphan.contact_id),
    engagement_id = COALESCE(c.engagement_id, orphan.engagement_id)
FROM orphan
WHERE c.id = orphan.inbound_id;

-- B3) Set replied_at on outbound messages that have an inbound reply in the
--     same party. Matches by thread headers OR by normalized subject, so
--     auto-responders ("Thanks for your email Re: ...") are covered even when
--     they carry no In-Reply-To / References headers.
WITH replied AS (
  SELECT o.id AS outbound_id, MIN(i.occurred_at) AS first_reply_at
  FROM app.communications o
  JOIN app.communications i
    ON i.organization_id = o.organization_id
   AND i.party_id        = o.party_id
   AND i.direction = 'inbound'
   AND i.deleted_at IS NULL
   AND i.occurred_at >= o.occurred_at
   AND (
        (i.in_reply_to IS NOT NULL AND i.in_reply_to = o.message_id)
     OR (i.thread_id IS NOT NULL AND i.thread_id = o.thread_id)
     OR (
          regexp_replace(lower(coalesce(i.subject,'')),
            '^((re|fwd?|aw|antwort)\s*:\s*|thanks for your email\s+re\s*:\s*)+', '')
          =
          regexp_replace(lower(coalesce(o.subject,'')),
            '^((re|fwd?|aw|antwort)\s*:\s*)+', '')
        )
       )
  WHERE o.direction = 'outbound'
    AND o.deleted_at IS NULL
    AND o.party_id IS NOT NULL
    AND o.replied_at IS NULL
  GROUP BY o.id
)
UPDATE app.communications c
SET replied_at = replied.first_reply_at
FROM replied
WHERE c.id = replied.outbound_id;


-- -----------------------------------------------------------------------------
-- Part C: VERIFICATION
-- -----------------------------------------------------------------------------

-- C1) Founder Collective thread (expect an inbound row now + outbound replied_at set).
SELECT direction, status, from_address, subject,
       occurred_at, replied_at, party_id
FROM app.communications
WHERE party_id = '5acf0405-9888-460b-a7cd-594c159b2ec4'
  AND deleted_at IS NULL
ORDER BY occurred_at;

-- C2) Stats RPC the Communications tab reads. In raw SQL the uuid literal must
--     be cast explicitly (PostgREST does this for the app automatically).
SELECT * FROM app.get_communications_stats_per_party(
  '5acf0405-9888-460b-a7cd-594c159b2ec4'::uuid
);

-- C3) Function-independent verification (use this if C2's signature differs).
--     Expect received >= 1 and replied >= 1 after the backfill.
SELECT
  count(*) FILTER (WHERE direction = 'inbound')                              AS received,
  count(*) FILTER (WHERE direction = 'outbound')                            AS sent,
  count(*) FILTER (WHERE direction = 'outbound' AND replied_at IS NOT NULL) AS replied
FROM app.communications
WHERE party_id = '5acf0405-9888-460b-a7cd-594c159b2ec4'
  AND deleted_at IS NULL;

-- =============================================================================
-- If A1 returns NOTHING, the reply was never stored (dropped before insert).
-- Deploy the mailcarrier.ts fix, then re-ingest by nudging the IMAP checkpoint
-- back so the carrier re-reads recent UIDs (adjust to the receiving mailbox):
--
--   UPDATE app.mailcarrier_state
--   SET last_processed_uid = GREATEST(last_processed_uid - 20, 0)
--   WHERE kind = 'account';
--
-- Then let one carrier cycle run and re-check Part C.
-- =============================================================================
