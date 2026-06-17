-- ============================================================
-- 20260617120000_email_sequences_from_kind.sql
-- Per-sequence sender routing for app.email_sequences.
--
-- from_kind selects which MAIL_<KIND>_* mailbox the sequence-processor
-- authenticates as and sends From:
--   'role'     -> MAIL_ROLE_*     (e.g. ceo@marinebiogroup.com)
--   'personal' -> MAIL_PERSONAL_* (e.g. yunyoung.heo@marinebiogroup.com)
--   'shared'   -> MAIL_SHARED_*
--
-- Default 'personal' => existing/other sequences send from yunyoung.heo@.
-- Investor cold-outreach sequence is set to 'role' => ceo@.
--
-- IMPORTANT: this file is a record only. Run it in the Supabase SQL Editor;
-- pushing the migration file does NOT apply it to the live database.
-- ============================================================

ALTER TABLE app.email_sequences
  ADD COLUMN IF NOT EXISTS from_kind text NOT NULL DEFAULT 'personal';

ALTER TABLE app.email_sequences
  DROP CONSTRAINT IF EXISTS email_sequences_from_kind_check;

ALTER TABLE app.email_sequences
  ADD CONSTRAINT email_sequences_from_kind_check
  CHECK (from_kind IN ('personal', 'role', 'shared'));

-- Investor cold-outreach sequence -> ceo@ (role)
UPDATE app.email_sequences
SET from_kind = 'role'
WHERE id = '151d5454-8efc-4ecb-90a6-ff4f0d18520d';

-- verify: investor sequence should show from_kind = 'role', others 'personal'
SELECT id, name, status, from_kind
FROM app.email_sequences
ORDER BY from_kind, name;
