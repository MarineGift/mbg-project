-- fix_20260715170000_fcc_climate_tech_day_offset_and_archive.sql
--
-- Pending item 2 (FCC Climate Tech day_offset 0,0 landmine) + part of item 7.
-- Root cause: step_order=1 day_offset was entered as 0 instead of 7.
--   Sibling sequence "Investor Cold Outreach - FCC Seed" (922b57e2) has the
--   intended pattern 0/7/14/21 with identical subjects.
--   FCC Climate Tech (81a3cd10) had 0/0/14/21 -> two emails on day 0 if enrolled.
-- Defense in depth: sequence archived (applied manually 2026-07-15, recorded
--   here idempotently) AND offset corrected so a future revival is safe.
--
-- Supabase SQL Editor safe: self-contained statements, no do-blocks,
-- no semicolons or bare keywords inside string literals.
-- Idempotent: every UPDATE carries its own precondition guard.

-- 1) Archive record (already applied manually on 2026-07-15 -- re-run is a no-op)
UPDATE app.email_sequences
SET status = 'archived'
WHERE id = '81a3cd10-bd46-42e4-ae1e-3c734ab1a438'
  AND status = 'active'
  AND NOT EXISTS (
    SELECT 1
    FROM app.email_sequence_enrollments e
    WHERE e.sequence_id = '81a3cd10-bd46-42e4-ae1e-3c734ab1a438'
  );

-- 2) Defuse the landmine itself: step_order 1 day_offset 0 -> 7
--    Guard: only fires while the bad value is present. Enrollments = 0,
--    so no next_send_at recomputation is needed.
UPDATE app.email_sequence_steps
SET day_offset = 7
WHERE sequence_id = '81a3cd10-bd46-42e4-ae1e-3c734ab1a438'
  AND step_order = 1
  AND day_offset = 0;

-- 3) OPTIONAL housekeeping (item 7 name-duplication cleanup).
--    Both sequences have only terminal enrollments (completed/cancelled).
--    Archiving blocks new enrollment via UI and the G3 worker guard.
--    Delete this section before running if you want to keep them active.

-- 3a) "15 min on a filler tech two mineral giants gave up on" (active copy)
--     enrollments: completed 29 + cancelled 2 -- all terminal
UPDATE app.email_sequences
SET status = 'archived'
WHERE id = '151d5454-8efc-4ecb-90a6-ff4f0d18520d'
  AND status = 'active'
  AND NOT EXISTS (
    SELECT 1
    FROM app.email_sequence_enrollments e
    WHERE e.sequence_id = '151d5454-8efc-4ecb-90a6-ff4f0d18520d'
      AND e.status = 'active'::app.enrollment_status
  );

-- 3b) "Investor Cold Outreach -- Intel Inside"
--     enrollments: completed 9 -- all terminal
UPDATE app.email_sequences
SET status = 'archived'
WHERE id = 'ceccfb05-f735-4ebb-a28b-d352bd6b8aae'
  AND status = 'active'
  AND NOT EXISTS (
    SELECT 1
    FROM app.email_sequence_enrollments e
    WHERE e.sequence_id = 'ceccfb05-f735-4ebb-a28b-d352bd6b8aae'
      AND e.status = 'active'::app.enrollment_status
  );

-- 4) Verify (read-only). Expected after full run:
--    81a3cd10 archived with offsets 0/7/14/21
--    151d5454 archived, ceccfb05 archived (if section 3 was run)
--    63737c08 (Climate Investor Cold Outreach -- FCC) untouched: active, 0/7/14/21
SELECT s.id, s.name, s.status, st.step_order, st.day_offset
FROM app.email_sequences s
JOIN app.email_sequence_steps st ON st.sequence_id = s.id
WHERE s.id IN (
  '81a3cd10-bd46-42e4-ae1e-3c734ab1a438',
  '151d5454-8efc-4ecb-90a6-ff4f0d18520d',
  'ceccfb05-f735-4ebb-a28b-d352bd6b8aae',
  '63737c08-16df-4145-a813-08398cde835c'
)
ORDER BY s.name, st.step_order;
