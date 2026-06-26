-- =============================================================================
-- 20260627000000_pangaea_andrew_backfill.sql
-- =============================================================================
-- Pangaea Ventures / Andrew Haughian thread backfill.
--
-- URM already captured (via IMAP polling):
--   - Sequence sends (6/17, 6/21, 6/24)
--   - Andrew's "Feel free to send presentation" reply (6/25 13:17 UTC)
--   - Andrew's "Would 9:30-10am on July 8 work?" reply (6/25 18:16 UTC)
--   - User's "It would works for me. Thanks" reply (6/25 18:53 UTC)
--
-- Missing -- inserted by this migration:
--   - User's IR deck send (6/25 14:18 UTC / 09:18 CDT) -- was sent from
--     external mail client and not captured by Sent-folder polling.
--
-- Also enriches:
--   - Andrew Haughian contact (email, title, phone)
--   - Pangaea Ventures party (email)
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Part 1: Enrich Andrew Haughian contact
-- -----------------------------------------------------------------------------
UPDATE app.contacts SET
  email         = COALESCE(NULLIF(email,''),         'andrew@pangaeaventures.com'),
  title_text    = COALESCE(NULLIF(title_text,''),    'Partner'),
  phone_mobile  = COALESCE(NULLIF(phone_mobile,''),  '+1.604.787.3478'),
  is_decision_maker = COALESCE(is_decision_maker, true),
  is_primary    = COALESCE(is_primary, true),
  updated_at    = NOW()
WHERE id = '7b954ce5-17bc-4282-b50e-9180660651d8';


-- -----------------------------------------------------------------------------
-- Part 2: Enrich Pangaea Ventures party
-- -----------------------------------------------------------------------------
UPDATE app.parties SET
  email      = COALESCE(NULLIF(email,''),      'info@pangaeaventures.com'),
  website    = COALESCE(NULLIF(website,''),    'https://www.pangaeaventures.com'),
  updated_at = NOW()
WHERE id = '97d63e5e-5e8d-4719-b170-588f1d184d99';


-- -----------------------------------------------------------------------------
-- Part 3: Insert missing deck-send engagement
-- Guard: skip if a similar outbound already exists in the 6/24-6/26 window.
-- -----------------------------------------------------------------------------
INSERT INTO app.engagements (
  id, organization_id, party_id, engagement_type_id, channel, direction,
  title, content, occurred_at,
  recorded_by_user_id, created_by, updated_by,
  created_at, updated_at
)
SELECT
  gen_random_uuid(),
  'b25de8f2-1020-482f-9012-183f63883169',
  '97d63e5e-5e8d-4719-b170-588f1d184d99',     -- Pangaea Ventures
  3,                                            -- email type (matches other rows)
  'email',
  'outbound',
  'Marinebio — Investor Presentation (FCC paper filler)',
$body$Hi, Mr. Andrew Haughian,

Thanks — appreciate you taking a look. The seed-round investor presentation is attached.

Quick framing in case it's useful before you dig in: we license FCC (Flexible Calcium Carbonate), a paper filler technology. A global top-tier mill recently wrapped multi-year trials, dropped the incumbent competing technology, and placed a 9,000-ton order. The deck walks through the technology, the licensing model, market size, and the raise.

Once you've had a chance to review, I'm happy to grab 30 minutes whenever works on your end.

Best regards,
Yun-Young Heo
CEO, MarineBio Group Inc.

[Manual external send recorded retroactively. Original send time: 2026-06-25 09:18 CDT (= 14:18 UTC). Attachment: Marinebio_IR_Seed_Ver1_6.pdf]$body$,
  '2026-06-25 14:18:00+00',
  '551fc4a0-b365-47eb-bf2f-0c3f594001c0',
  '551fc4a0-b365-47eb-bf2f-0c3f594001c0',
  '551fc4a0-b365-47eb-bf2f-0c3f594001c0',
  NOW(), NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM app.engagements
   WHERE party_id    = '97d63e5e-5e8d-4719-b170-588f1d184d99'
     AND direction   = 'outbound'
     AND title       = 'Marinebio — Investor Presentation (FCC paper filler)'
     AND occurred_at BETWEEN '2026-06-25 00:00:00+00' AND '2026-06-25 17:00:00+00'
);


-- -----------------------------------------------------------------------------
-- Verification: full Pangaea thread in chronological order
-- -----------------------------------------------------------------------------
SELECT 
  e.direction,
  e.channel,
  e.title,
  e.occurred_at,
  LEFT(COALESCE(e.content,''), 80) AS content_preview
FROM app.engagements e
WHERE e.party_id = '97d63e5e-5e8d-4719-b170-588f1d184d99'
  AND e.deleted_at IS NULL
ORDER BY e.occurred_at;

-- Expected 9 rows in order:
--   1. 6/17 19:34  out  "15 min..."                      Day 0
--   2. 6/21 04:33  out  "15 min..."                      Day 4
--   3. 6/21 04:36  out  "Re: 15 min..."                  Day 4 Re:
--   4. 6/24 18:18  out  "Closing the loop..."            Day 7
--   5. 6/25 13:17   in  "Re: 15 min..."                  Andrew: feel free to send
--   6. 6/25 14:18  out  "Marinebio — Investor..."        DECK SEND  <-- NEW
--   7. 6/25 18:16   in  "Re: Marinebio — Investor..."    Andrew: Would 9:30-10am?
--   8. 6/25 18:53  out  "Re: Marinebio — Investor..."    User: It would works
--   9. (any later replies)

-- And contact enrichment check:
SELECT id, full_name, email, title_text, phone_mobile, is_decision_maker, is_primary
FROM app.contacts
WHERE id = '7b954ce5-17bc-4282-b50e-9180660651d8';
