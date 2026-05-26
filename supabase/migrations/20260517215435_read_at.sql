-- Phase 22b: read_at for unread badge
ALTER TABLE app.communications
  ADD COLUMN IF NOT EXISTS read_at timestamptz DEFAULT NULL;

UPDATE app.communications
  SET read_at = occurred_at
  WHERE direction = 'outbound' AND read_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_comm_unread
  ON app.communications (read_at) WHERE read_at IS NULL;