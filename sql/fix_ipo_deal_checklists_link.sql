-- ============================================================
-- fix_ipo_deal_checklists_link.sql   (ALREADY APPLIED 2026-09-21 -- kept for the record)
-- !! Ctrl+A (select ALL) then Run -- the editor runs only highlighted text !!
--
-- Symptom: IPO Program deal showed no checklist.
-- Cause: seed_ipo_urm_link.sql wrote stage_checklist_templates only.
--   The deal page reads app.deal_checklists, filled by app.apply_stage_playbook()
--   on stage entry -- the deal already existed, so nothing was copied.
-- Fix:
--   1. Re-point every milestone task at the program deal (safety net).
--   2. Copy the templates of all 7 IPO stages onto the deal (idempotent).
--   3. Group gate tasks under their gate checklist item (tasks.checklist_id).
-- Result on 2026-09-21: 66 tasks, 43 with checklist, 28 deal checklists.
-- No org UUID in this file -- safe to commit.
-- ============================================================

UPDATE app.tasks t
   SET deal_id = p.deal_id,
       deleted_at = NULL
  FROM app.ipo_milestones m
  JOIN app.ipo_programs p ON p.id = m.program_id
 WHERE m.task_id = t.id
   AND p.deal_id IS NOT NULL
   AND (t.deal_id IS DISTINCT FROM p.deal_id OR t.deleted_at IS NOT NULL);

SELECT app.apply_stage_playbook(p.deal_id, s.id)
  FROM app.ipo_programs p
  JOIN app.deals d  ON d.id = p.deal_id
  JOIN app.stages s ON s.pipeline_id = d.pipeline_id
 ORDER BY s.sort_order;

UPDATE app.tasks t
   SET checklist_id = x.cl_id
  FROM (
    SELECT DISTINCT ON (m.task_id) m.task_id, dc.id AS cl_id
      FROM app.ipo_milestones m
      JOIN app.ipo_programs p         ON p.id = m.program_id
      JOIN app.ipo_gate_milestones gm ON gm.milestone_id = m.id
      JOIN app.ipo_readiness_gates g  ON g.id = gm.gate_id
      JOIN app.deal_checklists dc     ON dc.deal_id = p.deal_id
                                     AND dc.deleted_at IS NULL
                                     AND dc.title LIKE g.code || ' · %'
     WHERE m.task_id IS NOT NULL
     ORDER BY m.task_id, g.code
  ) x
 WHERE t.id = x.task_id
   AND t.checklist_id IS NULL;

SELECT 'deal_tasks' AS k, count(*)::text AS v
  FROM app.ipo_programs p JOIN app.tasks t ON t.deal_id = p.deal_id AND t.deleted_at IS NULL
UNION ALL
SELECT 'deal_checklists', count(*)::text
  FROM app.ipo_programs p JOIN app.deal_checklists dc ON dc.deal_id = p.deal_id AND dc.deleted_at IS NULL;
