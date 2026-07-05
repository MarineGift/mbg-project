-- =============================================================================
-- 20260627030000_mailrun_scheduled_at.sql
-- =============================================================================
-- Adds optional scheduled-send support to the per-recipient bulk path (mail_runs).
-- When scheduled_at IS NULL the run sends as soon as the mailrun-worker picks it
-- up (current behaviour). When set, the worker holds the run until now() has
-- reached scheduled_at. Run in the Supabase SQL Editor. Idempotent.
-- =============================================================================

ALTER TABLE app.mail_runs
  ADD COLUMN IF NOT EXISTS scheduled_at timestamptz;

COMMENT ON COLUMN app.mail_runs.scheduled_at IS
  'NULL = send immediately. When set, mailrun-worker holds the queued run until now() >= scheduled_at (UTC).';

-- Partial index so the worker''s "due queued runs" lookup stays cheap.
CREATE INDEX IF NOT EXISTS idx_mail_runs_queued_scheduled
  ON app.mail_runs (scheduled_at)
  WHERE status = 'queued';

-- Verify (expect the column to exist; lists any currently-scheduled future runs).
SELECT id, status, scheduled_at, total_count, created_at
FROM app.mail_runs
WHERE scheduled_at IS NOT NULL
ORDER BY scheduled_at
LIMIT 20;
