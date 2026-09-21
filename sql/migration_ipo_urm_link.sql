-- ============================================================
-- migration_ipo_urm_link.sql
-- Wire the IPO module into URM's deal engine:
--   ipo_programs.deal_id      -> app.deals      (one program deal)
--   ipo_milestones.task_id    -> app.tasks      (one task per milestone)
--   phase <-> stage           by stage.code = phase.code inside the program's pipeline
--
-- Rules enforced here:
--   1. ipo_milestones owns dates/gates; tasks are the execution view.
--      status syncs both ways; due_at -> target_date syncs task->milestone only.
--   2. Moving the program deal into P5 requires a recorded Gate 2 decision;
--      into P6 requires Gate 3. Enforced by trigger on app.deals.
-- Requires: migration_ipo_module.sql
-- ============================================================
BEGIN;

ALTER TABLE app.ipo_programs   ADD COLUMN IF NOT EXISTS deal_id uuid REFERENCES app.deals(id) ON DELETE SET NULL;
ALTER TABLE app.ipo_milestones ADD COLUMN IF NOT EXISTS task_id uuid REFERENCES app.tasks(id) ON DELETE SET NULL;
CREATE UNIQUE INDEX IF NOT EXISTS ipo_milestones_task_uniq ON app.ipo_milestones (task_id) WHERE task_id IS NOT NULL;

-- ------------------------------------------------------------
-- status vocabulary maps (tasks use text: pending/todo/in_progress/blocked/done/completed/cancelled)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION app.ipo_task_status_to_milestone(p text) RETURNS app.ipo_item_status
LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE p
    WHEN 'in_progress' THEN 'in_progress'::app.ipo_item_status
    WHEN 'blocked'     THEN 'blocked'
    WHEN 'done'        THEN 'done'
    WHEN 'completed'   THEN 'done'
    WHEN 'cancelled'   THEN 'waived'
    ELSE 'not_started' END
$$;

CREATE OR REPLACE FUNCTION app.ipo_milestone_status_to_task(p app.ipo_item_status) RETURNS text
LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE p
    WHEN 'in_progress' THEN 'in_progress'
    WHEN 'blocked'     THEN 'blocked'
    WHEN 'done'        THEN 'done'
    WHEN 'waived'      THEN 'cancelled'
    ELSE 'pending' END
$$;

-- ------------------------------------------------------------
-- task -> milestone
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION app.ipo_sync_task_to_milestone() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF pg_trigger_depth() > 1 THEN RETURN NEW; END IF;   -- called from the mirror trigger
  UPDATE app.ipo_milestones m
     SET status      = app.ipo_task_status_to_milestone(NEW.status),
         actual_date = CASE WHEN NEW.status IN ('done','completed')
                            THEN coalesce(NEW.completed_at::date, current_date) ELSE NULL END,
         target_date = coalesce(NEW.due_at::date, m.target_date)
   WHERE m.task_id = NEW.id
     AND (m.status <> app.ipo_task_status_to_milestone(NEW.status)
          OR m.target_date IS DISTINCT FROM coalesce(NEW.due_at::date, m.target_date));
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS ipo_sync_task_to_milestone ON app.tasks;
CREATE TRIGGER ipo_sync_task_to_milestone
  AFTER UPDATE OF status, due_at, completed_at ON app.tasks
  FOR EACH ROW EXECUTE FUNCTION app.ipo_sync_task_to_milestone();

-- ------------------------------------------------------------
-- milestone -> task (status only; dates flow the other way)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION app.ipo_sync_milestone_to_task() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF pg_trigger_depth() > 1 OR NEW.task_id IS NULL THEN RETURN NEW; END IF;
  UPDATE app.tasks t
     SET status       = app.ipo_milestone_status_to_task(NEW.status),
         completed_at = CASE WHEN NEW.status = 'done' THEN coalesce(t.completed_at, now()) ELSE NULL END,
         started_at   = CASE WHEN NEW.status IN ('in_progress','done') THEN coalesce(t.started_at, now()) ELSE t.started_at END
   WHERE t.id = NEW.task_id
     AND t.status IS DISTINCT FROM app.ipo_milestone_status_to_task(NEW.status);
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS ipo_sync_milestone_to_task ON app.ipo_milestones;
CREATE TRIGGER ipo_sync_milestone_to_task
  AFTER UPDATE OF status ON app.ipo_milestones
  FOR EACH ROW EXECUTE FUNCTION app.ipo_sync_milestone_to_task();

-- ------------------------------------------------------------
-- stage guard on the program deal
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION app.ipo_guard_program_stage() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
  v_prog  uuid;
  v_code  text;
  v_need  text;
  v_ok    boolean;
BEGIN
  IF NEW.current_stage_id IS NOT DISTINCT FROM OLD.current_stage_id THEN RETURN NEW; END IF;
  SELECT id INTO v_prog FROM app.ipo_programs WHERE deal_id = NEW.id;
  IF v_prog IS NULL THEN RETURN NEW; END IF;                      -- not the program deal
  SELECT code INTO v_code FROM app.stages WHERE id = NEW.current_stage_id;
  v_need := CASE v_code WHEN 'P5' THEN 'gate2' WHEN 'P6' THEN 'gate3' ELSE NULL END;
  IF v_need IS NULL THEN RETURN NEW; END IF;
  SELECT EXISTS (
    SELECT 1 FROM app.ipo_decision_reviews r
     WHERE r.program_id = v_prog AND r.stage = v_need
       AND r.window_decision IN ('accelerated_2029q4','base_2030q2')
  ) INTO v_ok;
  IF NOT v_ok THEN
    RAISE EXCEPTION 'Cannot move the IPO program deal to % without a recorded % decision (ipo_decision_reviews).', v_code, v_need;
  END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS ipo_guard_program_stage ON app.deals;
CREATE TRIGGER ipo_guard_program_stage
  BEFORE UPDATE OF current_stage_id ON app.deals
  FOR EACH ROW EXECUTE FUNCTION app.ipo_guard_program_stage();

COMMIT;

-- ------------------------------------------------------------
-- view: milestone with its task and engagement count
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW app.v_ipo_milestone_tasks
WITH (security_invoker = true) AS
SELECT m.organization_id, m.program_id, m.code, m.title, m.status, m.target_date, m.actual_date, m.is_gate,
       m.task_id, t.status AS task_status, t.due_at, t.assigned_to_user_id,
       (SELECT count(*) FROM app.engagements e WHERE e.task_id = m.task_id AND e.deleted_at IS NULL) AS engagements,
       (SELECT max(e.occurred_at) FROM app.engagements e WHERE e.task_id = m.task_id AND e.deleted_at IS NULL) AS last_engagement_at
FROM app.ipo_milestones m
LEFT JOIN app.tasks t ON t.id = m.task_id;
