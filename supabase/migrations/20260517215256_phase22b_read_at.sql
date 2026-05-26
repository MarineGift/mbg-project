-- Phase 22b: read_at column for unread tracking
-- Run in Supabase Dashboard > SQL Editor

-- 1. Add read_at column (null = unread)
ALTER TABLE app.communications
  ADD COLUMN IF NOT EXISTS read_at timestamptz DEFAULT NULL;

-- 2. Mark all existing outbound as read (sent items are always "read")
UPDATE app.communications
SET read_at = occurred_at
WHERE direction = 'outbound' AND read_at IS NULL;

-- 3. Index for fast unread count queries
CREATE INDEX IF NOT EXISTS idx_communications_read_at
  ON app.communications (read_at)
  WHERE read_at IS NULL;

-- 4. Helper function: unread count per org
CREATE OR REPLACE FUNCTION app.get_unread_count(p_org_id uuid)
RETURNS bigint
LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT COUNT(*)
  FROM app.communications
  WHERE party_id IN (
    SELECT id FROM app.parties WHERE org_id = p_org_id
  )
  AND direction = 'inbound'
  AND read_at IS NULL;
$$;