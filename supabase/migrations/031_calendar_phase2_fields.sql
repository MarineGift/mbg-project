-- ============================================================
-- 031_calendar_phase2_fields.sql
-- Calendar Phase 2: per-event color, reminders, free/busy (transparency).
-- recurrence_rule already exists (030_calendar_integration.sql) - NOT added here.
--
-- HOW TO RUN: paste this whole file into Supabase Studio > SQL Editor and Run.
-- Idempotent (ADD COLUMN IF NOT EXISTS) - safe to run more than once.
-- IMPORTANT: run this BEFORE deploying the Phase 2 code. The new code SELECTs
-- these columns; deploying first would make calendar fetch fail.
-- ============================================================

-- color: per-event hex color (e.g. '#33b679'); NULL = use default source/type color.
ALTER TABLE app.calendar_events
    ADD COLUMN IF NOT EXISTS color text;

-- reminders: array of { "minutes": <int>, "method": "popup" } objects.
-- e.g. [{"minutes":10},{"minutes":1440}]
ALTER TABLE app.calendar_events
    ADD COLUMN IF NOT EXISTS reminders jsonb NOT NULL DEFAULT '[]'::jsonb;

-- transparency: free/busy. 'opaque' = Busy (default), 'transparent' = Free.
ALTER TABLE app.calendar_events
    ADD COLUMN IF NOT EXISTS transparency text NOT NULL DEFAULT 'opaque';

-- constrain transparency to known values (guarded create)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_calendar_events_transparency'
    ) THEN
        ALTER TABLE app.calendar_events
            ADD CONSTRAINT chk_calendar_events_transparency
            CHECK (transparency IN ('opaque', 'transparent'));
    END IF;
END $$;

COMMENT ON COLUMN app.calendar_events.color IS
    'Phase 2: per-event hex color override; NULL falls back to source/type color';
COMMENT ON COLUMN app.calendar_events.reminders IS
    'Phase 2: jsonb array of {minutes,method} notification offsets';
COMMENT ON COLUMN app.calendar_events.transparency IS
    'Phase 2: opaque=Busy, transparent=Free (Google semantics)';
