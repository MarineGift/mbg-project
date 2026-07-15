-- =====================================================================
-- fix_20260715002000_block_declined_investors.sql
--
-- Record three explicit investor passes so the cold sequence stops.
-- Read from app.communications inbound bodies on 2026-07-15.
--
-- Effect
--   app.v_email_do_not_send picks these up by party_id AND email_lower.
--   public.get_due_enrollments() then drops the enrollment, and
--   sendOutboundEmail blocks any cold send. A DIRECT send (compose, manual,
--   AI reply) is NOT blocked -- sendClass = direct only honours
--   blocks_direct, which is false here. A courtesy reply still goes out.
--
-- URGENT: NFX and Aristos are both due for the next Seed step on 2026-07-20.
-- Apply before then or they get another cold mail after passing.
--
-- Not included, deliberately -- these are autoresponders or interest, NOT
-- passes. Recording them would permanently kill a live lead, which is the
-- mistake the World Fund brightfuture+noreply case already flagged:
--   Playground Global   info+noreply@playground.global   we will review in 7 days
--   Lux Capital         info+noreply@luxcapital.com      cannot reply individually
--   Breakout Ventures   contact@breakout.vc              routing acknowledgement
--   Founder Collective  contact@foundercollective.com    volume acknowledgement
--   CTAN                Director@ctan.com                apply at our site
--   Azolla Ventures     nolan@azollaventures.com         asked us to fill their form
--   Pangaea Ventures    andrew@pangaeaventures.com       a human, meeting booked 07-08
--
-- Already recorded, no action: Extantia (rejected_other, declined twice),
-- Energy Transition Ventures (rejected_sector), First Bight (rejected_stage),
-- Azolla (form_submitted), World Fund (auto_reply cooldown).
--
-- recipient_email carries the address the human replied FROM, matching the
-- convention of the existing rows. Party-level blocking does the real work:
-- the sequence sends to the intake address, not to the replier.
--
-- Each statement is self-contained and idempotent (NOT EXISTS guard).
-- Run the file as-is -- no do-block, no temp table.
--
-- Rollback: DELETE the row by evidence_ref.
-- =====================================================================

-- 1) NFX -- 2026-07-01
--    Not going to pursue discussions at this time for an investment.
--    Could not get conviction that this is the right fit for NFX.
INSERT INTO app.email_send_outcomes
  (organization_id, party_id, recipient_email, outcome, reason, evidence_ref, next_action, source, occurred_at)
SELECT c.organization_id,
       c.party_id,
       'qed@nfx.com',
       'rejected_other',
       'Explicit pass by email - strong application but not the right fit for NFX at this time',
       c.id::text,
       'none',
       'manual',
       c.occurred_at
FROM app.communications c
WHERE c.id = '3cdd9ca7-c62b-42b1-beb4-229dc20ad083'::uuid
  AND NOT EXISTS (
    SELECT 1
    FROM app.email_send_outcomes o
    WHERE o.party_id = c.party_id
      AND lower(o.recipient_email) = 'qed@nfx.com'
      AND o.outcome = 'rejected_other'
  );

-- 2) Aristos Ventures -- 2026-07-15
--    The Aristos Partnerships will no longer make new investments.
--    Firm is winding down, not a fit judgement. Permanent.
INSERT INTO app.email_send_outcomes
  (organization_id, party_id, recipient_email, outcome, reason, evidence_ref, next_action, source, occurred_at)
SELECT c.organization_id,
       c.party_id,
       'info@aristosventures.com',
       'rejected_other',
       'Firm no longer makes new investments - winding down after partner death, per John Jaggers',
       c.id::text,
       'none',
       'manual',
       c.occurred_at
FROM app.communications c
WHERE c.id = 'e289cb2c-a705-49ed-a285-c60f76d22189'::uuid
  AND NOT EXISTS (
    SELECT 1
    FROM app.email_send_outcomes o
    WHERE o.party_id = c.party_id
      AND lower(o.recipient_email) = 'info@aristosventures.com'
      AND o.outcome = 'rejected_other'
  );

-- 3) Circulate Capital -- 2026-07-14
--    After thorough evaluation, with regret, not proceeding at this time.
--    NOTE: the stored excerpt truncates mid-sentence. The decline is clear
--    but the exact wording of the tail was not read. If it turns out to say
--    reapply later, delete this row and use next_action resend_later instead.
INSERT INTO app.email_send_outcomes
  (organization_id, party_id, recipient_email, outcome, reason, evidence_ref, next_action, source, occurred_at)
SELECT c.organization_id,
       c.party_id,
       'arosas@circulatecapital.com',
       'rejected_other',
       'Explicit pass by email after evaluation of submitted proposal',
       c.id::text,
       'none',
       'manual',
       c.occurred_at
FROM app.communications c
WHERE c.id = '130865a4-9fd4-4100-b2aa-6ba0435cd1b9'::uuid
  AND NOT EXISTS (
    SELECT 1
    FROM app.email_send_outcomes o
    WHERE o.party_id = c.party_id
      AND lower(o.recipient_email) = 'arosas@circulatecapital.com'
      AND o.outcome = 'rejected_other'
  );
