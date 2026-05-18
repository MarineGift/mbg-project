-- Phase 22b: read_at for unread message badge
ALTER TABLE app.communications
  ADD COLUMN IF NOT EXISTS read_at timestamptz DEFAULT NULL;

-- All outbound (sent) messages are considered read
UPDATE app.communications
  SET read_at = occurred_at
  WHERE direction = 'outbound' AND read_at IS NULL;

-- Fast index for unread count queries
CREATE INDEX IF NOT EXISTS idx_comm_unread
  ON app.communications (read_at)
  WHERE read_at IS NULL;