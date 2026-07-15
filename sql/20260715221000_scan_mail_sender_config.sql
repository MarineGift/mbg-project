-- =====================================================================
-- 20260715221000_scan_mail_sender_config.sql
--
-- Supports 미결 3 (IP 49.254.118.167 / Trend Micro ERS / SPF-DKIM-DMARC).
-- READ-ONLY. Nothing is written. No secrets are selected -- password
-- columns are reported as a boolean "is it set", never as a value.
--
-- WHY: DNS says everything outbound leaves 49.254.118.167 (marinebiogroup.com
-- SPF is a single ip4: mechanism, and mail.marinebiogroup.com resolves to
-- exactly that IP). The one thing DNS CANNOT tell us is whether the app is
-- actually sending direct-to-MX from that box or relaying through something
-- else. smtp_host lives in the DB, not in env (see src/lib/email/mail-accounts.ts).
-- That answer decides whether ERS delisting is even the right move.
--
-- Supabase SQL Editor safe: self-contained statements, no semicolons or
-- bare SQL keywords inside strings.
-- =====================================================================


-- ---------------------------------------------------------------------
-- Q1. What columns does app.inbound_mailboxes really have?
--     src/types/database.ts is stale here (mail-accounts.ts says so in a
--     comment and uses `as never` to work around it), so read the catalog
--     rather than trusting the generated types.
-- ---------------------------------------------------------------------
SELECT
  c.column_name,
  c.data_type,
  c.is_nullable
FROM information_schema.columns c
WHERE c.table_schema = 'app'
  AND c.table_name   = 'inbound_mailboxes'
ORDER BY c.ordinal_position;


-- ---------------------------------------------------------------------
-- Q2. The actual outbound relay per account. THE key row is smtp_host.
--       smtp_host = mail.marinebiogroup.com (or the bare IP, or localhost)
--           -> sending direct-to-MX from the Korean box. ERS listing is
--              about OUR IP and delisting is the right lever.
--       smtp_host = smtp.gmail.com / smtp.office365.com / *.sendgrid.net /
--                   *.amazonaws.com / smtp.postmarkapp.com / an ISP relay
--           -> we are NOT the listed sender, the relay is. ERS delisting
--              would be aimed at the wrong IP entirely.
-- ---------------------------------------------------------------------
SELECT
  m.id,
  m.address,
  m.label,
  m.is_active,
  m.smtp_host,
  m.smtp_port,
  m.smtp_use_tls,
  m.smtp_username,
  m.smtp_auth_method,
  m.is_default,
  (m.smtp_password_encrypted IS NOT NULL)             AS smtp_password_is_set,
  m.imap_host,
  m.imap_port
FROM app.inbound_mailboxes m
ORDER BY m.is_default DESC, m.address;
-- If this errors 42703 on a column, that column does not exist -- take the
-- real list from Q1 and re-select. Do not assume.


-- ---------------------------------------------------------------------
-- Q3. Which account is actually sending the Climate sequence, and how much?
--     Volume per From-address over the last 30 days = the reputation
--     footprint that ERS is scoring.
-- ---------------------------------------------------------------------
SELECT
  c.from_address,
  count(*)                                            AS sent_30d,
  min(c.created_at)                                   AS first_send,
  max(c.created_at)                                   AS last_send
FROM app.communications c
WHERE c.created_at >= now() - interval '30 days'
  AND c.direction = 'outbound'
GROUP BY c.from_address
ORDER BY sent_30d DESC;
-- If `direction` errors 42703, list app.communications columns via
-- information_schema the same way Q1 does, then re-select.


-- ---------------------------------------------------------------------
-- Q4. Bounce/deliverability picture per outcome type, last 30 days.
--     Baseline to compare against after Tuesday's 40-message send.
-- ---------------------------------------------------------------------
SELECT
  o.outcome,
  count(*)                                            AS n,
  max(o.created_at)                                   AS most_recent
FROM app.email_send_outcomes o
WHERE o.created_at >= now() - interval '30 days'
GROUP BY o.outcome
ORDER BY n DESC;


-- ---------------------------------------------------------------------
-- Q5. Sanity: still exactly one active sequence before Tuesday fires?
--     This is the 07-15 archive pass holding. If this returns anything
--     other than one row (63737c08), something re-activated.
-- ---------------------------------------------------------------------
SELECT
  s.id,
  s.name,
  s.status,
  s.updated_at,
  count(e.id) FILTER (WHERE e.status::text = 'active')  AS active_enrollments,
  min(e.next_send_at) FILTER (WHERE e.status::text = 'active') AS next_send_at
FROM app.email_sequences s
LEFT JOIN app.email_sequence_enrollments e ON e.sequence_id = s.id
WHERE s.status::text = 'active'
GROUP BY s.id, s.name, s.status, s.updated_at
ORDER BY s.name;
