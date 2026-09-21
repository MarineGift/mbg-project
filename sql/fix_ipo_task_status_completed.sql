-- ============================================================
-- fix_ipo_task_status_completed.sql
-- !! Ctrl+A (select ALL) then Run -- the editor runs only highlighted text !!
--
-- 1. Milestone->task status map: done now writes 'completed'
--    (the word /tasks and the deal Tasks tab use for finished tasks).
--    Before this fix a done milestone left its task looking open on /tasks.
-- 2. One-off: IPO tasks already sitting at 'done' become 'completed'.
-- 3. October milestones to in_progress: F-IP-01, F-IP-03, F-CM-01.
--    The mirror trigger moves the linked tasks to in_progress as well.
-- No org UUID and no patent numbers in this file -- safe to commit.
-- Requires: migration_ipo_urm_link.sql
-- ============================================================

CREATE OR REPLACE FUNCTION app.ipo_milestone_status_to_task(p app.ipo_item_status) RETURNS text
LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE p
    WHEN 'in_progress' THEN 'in_progress'
    WHEN 'blocked'     THEN 'blocked'
    WHEN 'done'        THEN 'completed'
    WHEN 'waived'      THEN 'cancelled'
    ELSE 'pending' END
$$;

UPDATE app.tasks t
   SET status = 'completed',
       completed_at = coalesce(t.completed_at, now())
  FROM app.ipo_milestones m
 WHERE m.task_id = t.id
   AND t.status = 'done';

UPDATE app.ipo_milestones
   SET status = 'in_progress'
 WHERE code IN ('F-IP-01', 'F-IP-03', 'F-CM-01')
   AND status = 'not_started';

-- verification (last statement = the one result grid you see)
SELECT 'task_status' AS section, t.status AS k, count(*)::text AS v
  FROM app.ipo_milestones m JOIN app.tasks t ON t.id = m.task_id
 GROUP BY t.status
UNION ALL
SELECT 'milestone', m.code || ' ' || m.status::text, coalesce(t.status, 'NO TASK')
  FROM app.ipo_milestones m LEFT JOIN app.tasks t ON t.id = m.task_id
 WHERE m.code IN ('F-IP-01', 'F-IP-03', 'F-CM-01')
ORDER BY 1, 2;
