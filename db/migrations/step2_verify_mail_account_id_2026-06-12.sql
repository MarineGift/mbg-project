-- ============================================================
-- Step 2 VERIFY - communications.mail_account_id recording
-- Multi-Account Mail Hub / 2026-06-12
-- Read-only. Run in Supabase SQL editor AFTER the worker redeploy,
-- and AFTER sending at least one test mail to one of the 6 accounts
-- (from a whitelisted sender).
-- ============================================================

-- [1] Recent inbound rows + which account received them
SELECT
  c.received_at,
  c.from_address,
  c.to_addresses,
  c.mail_account_id,
  m.address AS account_address,
  c.external_data ->> 'mailcarrier_account_kind' AS acct_kind
FROM app.communications c
LEFT JOIN app.inbound_mailboxes m ON m.id = c.mail_account_id
WHERE c.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND c.direction = 'inbound'
  AND c.channel = 'email'
ORDER BY c.received_at DESC
LIMIT 20;

-- [2] Coverage since deploy (expect with_account = total for new rows;
--     rows ingested before Step 2 deploy stay NULL - that is fine)
SELECT
  count(*) FILTER (WHERE mail_account_id IS NOT NULL) AS with_account,
  count(*)                                            AS total
FROM app.communications
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND direction = 'inbound'
  AND channel = 'email'
  AND received_at >= now() - interval '1 day';

-- [3] Per-account inbound distribution (sanity: each polled mailbox shows up)
SELECT
  m.address,
  count(c.id) AS inbound_count,
  max(c.received_at) AS last_received
FROM app.inbound_mailboxes m
LEFT JOIN app.communications c
  ON c.mail_account_id = m.id
 AND c.direction = 'inbound'
WHERE m.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND m.is_active
GROUP BY m.address
ORDER BY m.address;
