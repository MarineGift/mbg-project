-- =============================================================================
-- 20260627040000_sequence_quiet_hours.sql
-- =============================================================================
-- Adds an optional send-window / quiet-hours policy to email sequences.
-- NULL = no policy (send a step whenever it is due, current behaviour).
-- When set, the sequence processor defers a due step that falls inside the
-- quiet window or on a blocked weekend to the next allowed time.
-- Shape: {"timezone":"America/New_York","start":"18:00","end":"08:00","weekends_blocked":true}
-- Run in the Supabase SQL Editor. Idempotent.
-- =============================================================================

ALTER TABLE app.email_sequences
  ADD COLUMN IF NOT EXISTS quiet_hours jsonb;

COMMENT ON COLUMN app.email_sequences.quiet_hours IS
  'NULL = no quiet hours. When set {timezone,start,end,weekends_blocked}, the sequence processor holds a due step until the next allowed time.';

-- Verify (expect the column to exist).
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'app' AND table_name = 'email_sequences' AND column_name = 'quiet_hours';
