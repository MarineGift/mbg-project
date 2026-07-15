-- =====================================================================
-- fix_20260715003000_record_hard_bounces.sql
--
-- Stop sending to dead addresses. Sender reputation is already suffering.
--
-- Problem (read from inbound bodies on 2026-07-15)
--   MailCarrier delivers the NDR to us, so the bounce notification lands in
--   app.communications with from_address = postmaster@marinebiogroup.com and
--   party_id = MarineBio Group -- OUR OWN party, not the party that bounced.
--   Nothing ever links the NDR back to the target, so app.email_send_outcomes
--   has ZERO bounce_hard rows and the sequence keeps hammering dead boxes.
--   Same addresses bounced on 06-24 AND again on 06-30.
--
--   Consequence, observed: techventures@chevron.com now answers with
--     554 Connection rejected -- blocked using Trend Micro Email Reputation
--     Services -- for this 49.254.118.167
--   Repeatedly mailing dead boxes lowers reputation, which causes more
--   blocking. This file breaks the first half of that loop. The IP listing
--   itself is an infra job, not a data job -- see PART E of the handoff.
--
-- Scope decision: ADDRESS level, not party level
--   party_id is left NULL ON PURPOSE. app.v_email_do_not_send groups by
--   (email_lower, party_id) and the guards match party and address
--   separately, so a NULL party_id blocks exactly one address and nothing
--   else. That is what a bounce means: the mailbox is dead, the FIRM has
--   said nothing. Blocking emailinquiries@archventure.com must not kill ARCH
--   Venture -- a partner direct address may still be reachable. Contrast
--   with fix_20260715002000, where a human declined and party level is right.
--
-- Excluded on purpose
--   * Trend Micro 554 (techventures@chevron.com) -- OUR ip is listed, the
--     recipient is fine. Recording bounce_hard would kill a live lead over
--     our own infrastructure problem. Same trap as the World Fund
--     autoresponder: never let a machine failure retire a prospect.
--   * test@test.com -- test data that reached production, not a party.
--   * Undeliverable notices from foreign postmasters (e.g.
--     postmaster@eclipsevc.onmicrosoft.com for admin@eclipse.capital, an
--     admin mail-flow rule). Different body shape, handled separately.
--
-- Classification from the NDR body
--   RCPT: 550 ...          -> hard_bounce   mailbox unknown / inactive / denied
--   DNS lookup failure     -> domain_dead   domain does not resolve
--   Connect failure        -> unreachable   host refuses connections
--   All three are recorded as bounce_hard. unreachable is the softest of the
--   three -- if a domain comes back, delete its row by evidence_ref.
--
-- PREVIEW FIRST. Run the grouped SELECT from the handoff before this file.
-- If failed_recipient comes back NULL the regex does not match this NDR
-- format and this INSERT is a no-op -- harmless, but know it beforehand.
--
-- Idempotent: NOT EXISTS on (recipient_email, outcome) for org-scoped rows
-- with a NULL party_id. Self-contained single statement, no do-block.
--
-- Rollback:
--   DELETE FROM app.email_send_outcomes
--   WHERE source = 'ndr_parse' AND outcome = 'bounce_hard'
-- =====================================================================

INSERT INTO app.email_send_outcomes
  (organization_id, party_id, recipient_email, outcome, reason, evidence_ref, next_action, source, occurred_at)
SELECT DISTINCT ON (lower(substring(coalesce(c.body_plain, c.body_summary, '') from '<([^<>]+@[^<>]+)>')))
       c.organization_id,
       NULL::uuid,
       lower(substring(coalesce(c.body_plain, c.body_summary, '') from '<([^<>]+@[^<>]+)>')),
       'bounce_hard',
       CASE
         WHEN coalesce(c.body_plain, c.body_summary, '') LIKE '%DNS lookup failure%' THEN 'NDR - domain does not resolve'
         WHEN coalesce(c.body_plain, c.body_summary, '') LIKE '%Connect failure%'    THEN 'NDR - host refused connection'
         ELSE 'NDR - 550 mailbox unknown, inactive or access denied'
       END,
       c.id::text,
       'suppress',
       'ndr_parse',
       c.occurred_at
FROM app.communications c
WHERE c.channel::text     = 'email'
  AND c.direction::text   = 'inbound'
  AND c.from_address      = 'postmaster@marinebiogroup.com'
  AND c.deleted_at IS NULL
  AND c.occurred_at      >= now() - INTERVAL '120 days'
  -- must have parsed a recipient
  AND substring(coalesce(c.body_plain, c.body_summary, '') from '<([^<>]+@[^<>]+)>') IS NOT NULL
  -- our own IP reputation problem, NOT the recipient. Keep the lead alive.
  AND coalesce(c.body_plain, c.body_summary, '') NOT LIKE '%Trend Micro%'
  -- test data, not a real party
  AND lower(substring(coalesce(c.body_plain, c.body_summary, '') from '<([^<>]+@[^<>]+)>')) <> 'test@test.com'
  -- a permanent failure of one of the three known shapes
  AND (
        coalesce(c.body_plain, c.body_summary, '') LIKE '%RCPT: 550%'
     OR coalesce(c.body_plain, c.body_summary, '') LIKE '%DNS lookup failure%'
     OR coalesce(c.body_plain, c.body_summary, '') LIKE '%Connect failure%'
      )
  AND NOT EXISTS (
    SELECT 1
    FROM app.email_send_outcomes o
    WHERE o.organization_id = c.organization_id
      AND o.party_id IS NULL
      AND o.outcome = 'bounce_hard'
      AND lower(o.recipient_email) = lower(substring(coalesce(c.body_plain, c.body_summary, '') from '<([^<>]+@[^<>]+)>'))
  )
ORDER BY lower(substring(coalesce(c.body_plain, c.body_summary, '') from '<([^<>]+@[^<>]+)>')),
         c.occurred_at DESC;
