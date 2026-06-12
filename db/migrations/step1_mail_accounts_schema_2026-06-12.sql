-- ============================================================================
-- step1_mail_accounts_schema_2026-06-12.sql
-- Multi-account mail hub — Step 1: schema only (no behavior change).
--
-- Extends app.inbound_mailboxes (currently IMAP-receive only, 6 rows) to also
-- hold SMTP send credentials + display name + default-sender flag, and adds a
-- mail_account_id FK on communications so replies can auto-select the receiving
-- account as the From.
--
-- All new columns are nullable / defaulted -> existing IMAP polling + current
-- single-relay sending keep working unchanged. Idempotent (IF NOT EXISTS).
--
-- Confirmed values (2026-06-12):
--   IMAP: port 143, no TLS (existing)            SMTP: mail.<domain>:587, STARTTLS
--   SMTP password == IMAP password (same account) -> reuse password_encrypted
--   default sender: yunyoung.heo@marinebiogroup.com
-- ============================================================================

-- Keep table name inbound_mailboxes for now (rename to mail_accounts is a later,
-- separate step to avoid breaking the worker's PostgREST table reference today).

-- ---- 1) new columns on inbound_mailboxes -----------------------------------
ALTER TABLE app.inbound_mailboxes
  ADD COLUMN IF NOT EXISTS display_name             text,
  ADD COLUMN IF NOT EXISTS imap_username            text,
  ADD COLUMN IF NOT EXISTS smtp_host                text,
  ADD COLUMN IF NOT EXISTS smtp_port                integer,
  ADD COLUMN IF NOT EXISTS smtp_use_tls             boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS smtp_username            text,
  ADD COLUMN IF NOT EXISTS smtp_password_encrypted  bytea,
  ADD COLUMN IF NOT EXISTS smtp_auth_method         text NOT NULL DEFAULT 'login',
  ADD COLUMN IF NOT EXISTS is_default               boolean NOT NULL DEFAULT false;

-- ---- 2) only one default sender per org ------------------------------------
CREATE UNIQUE INDEX IF NOT EXISTS uq_inbound_mailboxes_default
  ON app.inbound_mailboxes (organization_id)
  WHERE is_default;

-- ---- 3) communications: which account received this mail -------------------
ALTER TABLE app.communications
  ADD COLUMN IF NOT EXISTS mail_account_id uuid;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_schema = 'app'
      AND table_name = 'communications'
      AND constraint_name = 'fk_communications_mail_account'
  ) THEN
    ALTER TABLE app.communications
      ADD CONSTRAINT fk_communications_mail_account
      FOREIGN KEY (mail_account_id) REFERENCES app.inbound_mailboxes (id)
      ON DELETE SET NULL;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS ix_communications_mail_account
  ON app.communications (mail_account_id);

-- ---- 4) backfill the 6 existing accounts -----------------------------------
-- imap_username := address; smtp host/port/username by rule; smtp password
-- reuses the already-encrypted IMAP password (same credentials).
UPDATE app.inbound_mailboxes
SET
  imap_username           = COALESCE(imap_username, address),
  smtp_username           = COALESCE(smtp_username, address),
  smtp_host               = COALESCE(smtp_host, 'mail.' || split_part(address, '@', 2)),
  smtp_port               = COALESCE(smtp_port, 587),
  smtp_password_encrypted = COALESCE(smtp_password_encrypted, password_encrypted),
  display_name            = COALESCE(display_name, label),
  updated_at              = now()
WHERE smtp_host IS NULL OR smtp_username IS NULL OR smtp_password_encrypted IS NULL;

-- Gmail / Naver use provider SMTP hosts, not mail.<domain> -> correct them.
UPDATE app.inbound_mailboxes
SET smtp_host = 'smtp.gmail.com', updated_at = now()
WHERE split_part(address,'@',2) = 'gmail.com';

UPDATE app.inbound_mailboxes
SET smtp_host = 'smtp.naver.com', updated_at = now()
WHERE split_part(address,'@',2) = 'naver.com';

-- ---- 5) set the default sender ---------------------------------------------
UPDATE app.inbound_mailboxes
SET is_default = false
WHERE is_default = true
  AND lower(address) <> 'yunyoung.heo@marinebiogroup.com';

UPDATE app.inbound_mailboxes
SET is_default = true, updated_at = now()
WHERE lower(address) = 'yunyoung.heo@marinebiogroup.com';

-- ============================================================================
-- POST-CHECK
-- ============================================================================
-- a) all 6 accounts have smtp host/port/username/password now?
SELECT 'accounts_smtp_ready' AS check, COUNT(*) AS n
FROM app.inbound_mailboxes
WHERE smtp_host IS NOT NULL AND smtp_port IS NOT NULL
  AND smtp_username IS NOT NULL AND smtp_password_encrypted IS NOT NULL;

-- b) exactly one default sender, and it's the intended one?
SELECT address AS default_sender
FROM app.inbound_mailboxes
WHERE is_default = true;

-- c) full readout (no secrets) for eyeball
SELECT address, display_name,
       imap_host, imap_port, use_tls AS imap_tls,
       smtp_host, smtp_port, smtp_use_tls, smtp_username,
       (smtp_password_encrypted IS NOT NULL) AS smtp_has_pw,
       is_default, is_active
FROM app.inbound_mailboxes
ORDER BY is_default DESC, address;

-- d) communications.mail_account_id column exists?
SELECT 'mail_account_fk' AS check, COUNT(*) AS n
FROM information_schema.columns
WHERE table_schema='app' AND table_name='communications' AND column_name='mail_account_id';

-- Expected: accounts_smtp_ready=6, default_sender=yunyoung.heo@marinebiogroup.com,
--           gmail/naver smtp_host = smtp.gmail.com/smtp.naver.com, mail_account_fk=1
