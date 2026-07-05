-- =============================================================================
-- 20260627011000_opened_backfill.sql
-- =============================================================================
-- "Opened" shows 0 even though the email was replied to. Open-tracking pixels
-- do not fire when the recipient blocks images (Founder Collective's reply view
-- showed "Pictures ... have been blocked"). A reply implies the message was
-- opened, so backfill opened_at from replied_at where no open was recorded.
--
-- Idempotent. Run in Supabase SQL Editor.
-- Founder Collective party_id = 5acf0405-9888-460b-a7cd-594c159b2ec4
-- =============================================================================

UPDATE app.communications
SET opened_at = replied_at
WHERE direction = 'outbound'
  AND deleted_at IS NULL
  AND replied_at IS NOT NULL
  AND opened_at IS NULL;

-- Verify Founder Collective funnel (expect sent=1, opened=1, replied=1, received=1).
SELECT
  count(*) FILTER (WHERE direction = 'inbound')                               AS received,
  count(*) FILTER (WHERE direction = 'outbound')                             AS sent,
  count(*) FILTER (WHERE direction = 'outbound' AND opened_at  IS NOT NULL)  AS opened,
  count(*) FILTER (WHERE direction = 'outbound' AND replied_at IS NOT NULL)  AS replied
FROM app.communications
WHERE party_id = '5acf0405-9888-460b-a7cd-594c159b2ec4'
  AND deleted_at IS NULL;
