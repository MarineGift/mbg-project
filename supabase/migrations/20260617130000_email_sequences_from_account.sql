-- ============================================================
-- 20260617130000_email_sequences_from_account.sql
-- Account-based sender routing for app.email_sequences.
--
-- Replaces the env-kind approach (from_kind) with from_account_id, an
-- app.inbound_mailboxes id -- the SAME accounts the compose/reply From
-- dropdown lists. The processor delegates to sendOutboundEmail(), which
-- resolves this account, decrypts its SMTP password and sends from it.
--   from_account_id = <account id>  -> send from that account
--   from_account_id = NULL          -> org default account
--
-- Investor cold-outreach sequence -> yunyoung.heo@marinebiogroup.com.
--
-- IMPORTANT: record only. Run in the Supabase SQL Editor; pushing the file
-- does NOT apply it.
-- ============================================================

ALTER TABLE app.email_sequences
  ADD COLUMN IF NOT EXISTS from_account_id uuid REFERENCES app.inbound_mailboxes(id);

-- Investor cold-outreach sequence -> yunyoung.heo@ (resolved by address)
UPDATE app.email_sequences
SET from_account_id = (
  SELECT id FROM app.inbound_mailboxes
  WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
    AND lower(address) = 'yunyoung.heo@marinebiogroup.com'
    AND is_active = true
  LIMIT 1
)
WHERE id = '151d5454-8efc-4ecb-90a6-ff4f0d18520d';

-- Drop the now-unused env-kind column (superseded by from_account_id).
ALTER TABLE app.email_sequences DROP CONSTRAINT IF EXISTS email_sequences_from_kind_check;
ALTER TABLE app.email_sequences DROP COLUMN IF EXISTS from_kind;

-- verify: from_address should be yunyoung.heo@marinebiogroup.com
SELECT s.id, s.name, s.from_account_id,
       mb.address AS from_address, mb.display_name
FROM app.email_sequences s
LEFT JOIN app.inbound_mailboxes mb ON mb.id = s.from_account_id
WHERE s.id = '151d5454-8efc-4ecb-90a6-ff4f0d18520d';
