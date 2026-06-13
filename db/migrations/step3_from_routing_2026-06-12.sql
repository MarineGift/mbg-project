-- ============================================================
-- Step 3 - From routing / per-account SMTP
-- Multi-Account Mail Hub / 2026-06-12
-- Part A: OPTIONAL display_name backfill (edit names, then run once)
-- Part B: read-only verification (run after deploy + test sends)
-- ============================================================

-- ─────────────────────────────────────────────
-- [A] OPTIONAL: From display names per account.
--     display_name is NULL after Step 1; when NULL the code falls back to
--     the caller-provided fromName. Edit the names below to taste, then run.
-- ─────────────────────────────────────────────
-- PRE-CHECK
SELECT address, display_name FROM app.inbound_mailboxes
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
ORDER BY address;

/*
UPDATE app.inbound_mailboxes SET display_name = v.dn, updated_at = now()
FROM (VALUES
  ('yunyoung.heo@marinebiogroup.com', 'YunYoung Heo'),
  ('ceo@marinebiogroup.com',          'YunYoung Heo, CEO MarineBio Group'),
  ('contact@marinebiogroup.com',      'MarineBio Group'),
  ('ceo@marinepad.com',               'YunYoung Heo, CEO MarinePad'),
  ('marinegift4u@gmail.com',          'Marine Gift'),
  ('marinepad@naver.com',             'MarinePad')
) AS v(addr, dn)
WHERE inbound_mailboxes.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND inbound_mailboxes.address = v.addr;
*/

-- POST-CHECK (after running the UPDATE)
-- SELECT address, display_name FROM app.inbound_mailboxes
-- WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169' ORDER BY address;

-- ─────────────────────────────────────────────
-- [B] VERIFICATION after deploy (read-only)
-- ─────────────────────────────────────────────

-- [B1] Recent outbound: which account actually sent, with what From
SELECT
  c.sent_at,
  c.status,
  c.from_address,
  c.from_name,
  m.address  AS sent_via_account,
  m.is_default,
  c.in_reply_to IS NOT NULL AS is_reply,
  c.to_addresses,
  c.error_message
FROM app.communications c
LEFT JOIN app.inbound_mailboxes m ON m.id = c.mail_account_id
WHERE c.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND c.direction = 'outbound'
  AND c.channel = 'email'
ORDER BY c.occurred_at DESC
LIMIT 20;

-- [B2] Routing rule spot-check for a reply:
--      pick an inbound row, then confirm the expected From account.
--      expected: default in to/cc -> default account;
--                else the persisting account (mail_account_id);
--                else reverse-match.
SELECT
  c.received_at,
  c.from_address  AS sender,
  c.to_addresses,
  c.cc_addresses,
  m.address       AS persisted_by_account,
  CASE
    WHEN EXISTS (
      SELECT 1 FROM app.inbound_mailboxes d
      WHERE d.organization_id = c.organization_id
        AND d.is_default AND d.is_active
        AND lower(d.address) = ANY (
          SELECT lower(x) FROM unnest(c.to_addresses || coalesce(c.cc_addresses, '{}')) AS x
        )
    ) THEN '-> default account'
    WHEN c.mail_account_id IS NOT NULL THEN '-> persisted account'
    ELSE '-> reverse-match / default'
  END AS expected_reply_from
FROM app.communications c
LEFT JOIN app.inbound_mailboxes m ON m.id = c.mail_account_id
WHERE c.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND c.direction = 'inbound'
  AND c.channel = 'email'
ORDER BY c.received_at DESC
LIMIT 10;

-- [B3] Failed sends since deploy (SMTP auth/TLS issues surface here;
--      gmail/naver plain-587 rejections are expected until app passwords + TLS)
SELECT occurred_at, from_address, to_addresses, error_message
FROM app.communications
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND direction = 'outbound'
  AND status = 'failed'
  AND occurred_at >= now() - interval '1 day'
ORDER BY occurred_at DESC;
