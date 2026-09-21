-- ============================================================
-- migration_ipo_todo_calendar.sql
-- !! Ctrl+A (select ALL) then Run -- the editor runs only highlighted text !!
--
-- Goal: IPO work shows up on /todo and /calendar, month by month.
--   /todo and the calendar "To-Do" source both read app.todo_items,
--   so IPO milestones are mirrored there (no app code change needed).
--
--   A. app.v_ipo_month_plan    -- DB view: every month x milestone
--                                 (due / starts / active) for the whole plan
--   B. app.ipo_sync_todo()     -- mirrors into the To-Do board:
--        * one item per open milestone that is due, starting or in progress
--          in the current or next month  ("IPO · F-IP-01 · ...")
--        * one "IPO plan · <Month YYYY>" summary item per month, dated the 1st,
--          listing that month's milestones  -> the monthly list on the calendar
--   C. triggers
--        milestone change  -> re-sync To-Do
--        To-Do item ticked -> milestone done + deal task completed (and back)
--
-- Idempotent. No org UUID in this file -- safe to commit.
-- Month roll-over: run migration_ipo_todo_cron.sql once (daily pg_cron job),
--   or run  SELECT app.ipo_sync_todo();  at the start of each month.
-- ============================================================

-- ---------- A. monthly plan view ----------
CREATE OR REPLACE VIEW app.v_ipo_month_plan WITH (security_invoker = true) AS
SELECT pg.organization_id,
       m.program_id,
       mo.month_start::date                                   AS month,
       to_char(mo.month_start, 'YYYY-MM')                     AS month_label,
       CASE WHEN m.target_date BETWEEN mo.month_start::date AND (mo.month_start + interval '1 month' - interval '1 day')::date THEN 'due'
            WHEN m.start_date  BETWEEN mo.month_start::date AND (mo.month_start + interval '1 month' - interval '1 day')::date THEN 'starts'
            ELSE 'active' END                                 AS bucket,
       m.code, m.title, ph.code AS phase_code, m.is_gate, m.status,
       m.start_date, m.target_date, m.task_id
  FROM app.ipo_milestones m
  JOIN app.ipo_programs pg ON pg.id = m.program_id
  LEFT JOIN app.ipo_phases ph ON ph.id = m.phase_id
  CROSS JOIN LATERAL generate_series(
         date_trunc('month', coalesce(m.start_date, m.target_date)),
         date_trunc('month', m.target_date),
         interval '1 month') AS mo(month_start)
 WHERE m.target_date IS NOT NULL;

-- ---------- helpers ----------
CREATE OR REPLACE FUNCTION app.ipo_todo_board(p_org uuid) RETURNS uuid
LANGUAGE sql STABLE AS $$
  SELECT id FROM app.todo_boards
   WHERE organization_id = p_org
   ORDER BY (kind = 'todo') DESC, position
   LIMIT 1
$$;

-- p_kind: open | in_progress | done
CREATE OR REPLACE FUNCTION app.ipo_todo_status_key(p_board uuid, p_kind text) RETURNS text
LANGUAGE sql STABLE AS $$
  SELECT coalesce(
    CASE p_kind
      WHEN 'done'        THEN (SELECT key FROM app.todo_status_options WHERE board_id = p_board AND is_done ORDER BY position LIMIT 1)
      WHEN 'in_progress' THEN (SELECT key FROM app.todo_status_options WHERE board_id = p_board AND NOT is_done AND key IN ('in_progress','doing','working') ORDER BY position LIMIT 1)
    END,
    (SELECT key FROM app.todo_status_options WHERE board_id = p_board AND NOT is_done ORDER BY position LIMIT 1),
    'todo')
$$;

-- ---------- B. sync ----------
CREATE OR REPLACE FUNCTION app.ipo_sync_todo(p_today date DEFAULT current_date) RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path = app, public AS $$
DECLARE
  pr       record;
  v_board  uuid;
  v_ms     date := date_trunc('month', p_today)::date;
  v_me     date := (date_trunc('month', p_today) + interval '2 months' - interval '1 day')::date;
  v_open   text;
  v_prog   text;
  v_done   text;
  mo       date;
  v_desc   text;
  n        integer := 0;
  k        integer;
BEGIN
  FOR pr IN SELECT id, organization_id FROM app.ipo_programs LOOP
    v_board := app.ipo_todo_board(pr.organization_id);
    CONTINUE WHEN v_board IS NULL;
    v_open := app.ipo_todo_status_key(v_board, 'open');
    v_prog := app.ipo_todo_status_key(v_board, 'in_progress');
    v_done := app.ipo_todo_status_key(v_board, 'done');

    -- 1. new mirror items for this month and next
    INSERT INTO app.todo_items (organization_id, board_id, title, description, status, priority,
                                start_date, due_date, position, custom)
    SELECT pr.organization_id, v_board,
           'IPO · ' || m.code || ' · ' || m.title,
           'Nasdaq IPO milestone ' || m.code || coalesce(' (phase ' || ph.code || ')', '') ||
             CASE WHEN m.is_gate THEN ' — GATE' ELSE '' END ||
             coalesce(E'\nRule: ' || m.rule_ref, '') ||
             E'\nDetails and documents: IPO Program deal > Tasks, or /ipo Timeline.',
           CASE WHEN m.status IN ('in_progress','blocked') THEN v_prog ELSE v_open END,
           CASE WHEN m.is_gate THEN 'high' ELSE 'medium' END,
           m.start_date, m.target_date, 1000 + coalesce(m.sort_order, 0),
           jsonb_build_object('src', 'ipo', 'ipo_milestone_id', m.id::text, 'ipo_code', m.code)
      FROM app.ipo_milestones m
      LEFT JOIN app.ipo_phases ph ON ph.id = m.phase_id
     WHERE m.program_id = pr.id
       AND m.status NOT IN ('done', 'waived')
       AND (m.target_date BETWEEN v_ms AND v_me
            OR m.start_date BETWEEN v_ms AND v_me
            OR m.status IN ('in_progress', 'blocked'))
       AND NOT EXISTS (SELECT 1 FROM app.todo_items ti
                        WHERE ti.organization_id = pr.organization_id
                          AND ti.custom->>'ipo_milestone_id' = m.id::text);
    GET DIAGNOSTICS k = ROW_COUNT; n := n + k;

    -- 2. keep mirrored items in step with their milestone (only rows that differ)
    WITH x AS (
      SELECT ti.id,
             'IPO · ' || m.code || ' · ' || m.title AS new_title,
             m.start_date, m.target_date,
             CASE
               WHEN m.status IN ('done','waived') THEN v_done
               WHEN coalesce(so.is_done, false)   THEN CASE WHEN m.status IN ('in_progress','blocked') THEN v_prog ELSE v_open END
               WHEN m.status IN ('in_progress','blocked') AND ti.status = v_open THEN v_prog
               ELSE ti.status END AS new_status
        FROM app.todo_items ti
        JOIN app.ipo_milestones m ON m.id::text = ti.custom->>'ipo_milestone_id' AND m.program_id = pr.id
        LEFT JOIN app.todo_status_options so ON so.board_id = ti.board_id AND so.key = ti.status
       WHERE ti.organization_id = pr.organization_id
    )
    UPDATE app.todo_items ti
       SET title = x.new_title, start_date = x.start_date, due_date = x.target_date, status = x.new_status
      FROM x
     WHERE ti.id = x.id
       AND (ti.title IS DISTINCT FROM x.new_title OR ti.start_date IS DISTINCT FROM x.start_date
            OR ti.due_date IS DISTINCT FROM x.target_date OR ti.status IS DISTINCT FROM x.new_status);

    -- 3. monthly summary items (current + next month)
    FOR mo IN SELECT generate_series(v_ms, v_me, interval '1 month')::date LOOP
      SELECT string_agg(
               CASE p.bucket WHEN 'due' THEN 'DUE     ' WHEN 'starts' THEN 'START   ' ELSE 'ONGOING ' END ||
               p.code || ' · ' || p.title ||
               ' (' || to_char(p.target_date, 'Mon DD') || CASE WHEN p.is_gate THEN ', gate' ELSE '' END || ')',
               E'\n' ORDER BY CASE p.bucket WHEN 'due' THEN 0 WHEN 'starts' THEN 1 ELSE 2 END, p.target_date, p.code)
        INTO v_desc
        FROM app.v_ipo_month_plan p
       WHERE p.program_id = pr.id AND p.month = mo
         AND p.status NOT IN ('done', 'waived')
         AND (p.bucket IN ('due', 'starts') OR p.status IN ('in_progress', 'blocked'));

      UPDATE app.todo_items
         SET description = coalesce(v_desc, 'No IPO milestones due or starting this month.')
       WHERE organization_id = pr.organization_id
         AND custom->>'src' = 'ipo_month' AND custom->>'month' = to_char(mo, 'YYYY-MM')
         AND description IS DISTINCT FROM coalesce(v_desc, 'No IPO milestones due or starting this month.');

      INSERT INTO app.todo_items (organization_id, board_id, title, description, status, priority,
                                  start_date, due_date, position, custom)
      SELECT pr.organization_id, v_board,
             'IPO plan · ' || to_char(mo, 'FMMonth YYYY'),
             coalesce(v_desc, 'No IPO milestones due or starting this month.'),
             v_open, 'high', mo, mo, 999,
             jsonb_build_object('src', 'ipo_month', 'month', to_char(mo, 'YYYY-MM'))
       WHERE NOT EXISTS (SELECT 1 FROM app.todo_items
                          WHERE organization_id = pr.organization_id
                            AND custom->>'src' = 'ipo_month' AND custom->>'month' = to_char(mo, 'YYYY-MM'));
      GET DIAGNOSTICS k = ROW_COUNT; n := n + k;
    END LOOP;

    -- 4. past monthly summaries are closed
    UPDATE app.todo_items
       SET status = v_done
     WHERE organization_id = pr.organization_id
       AND custom->>'src' = 'ipo_month'
       AND (custom->>'month') < to_char(v_ms, 'YYYY-MM')
       AND status IS DISTINCT FROM v_done;
  END LOOP;
  RETURN n;
END $$;

-- ---------- C1. milestone change -> re-sync ----------
CREATE OR REPLACE FUNCTION app.ipo_milestone_to_todo() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = app, public AS $$
BEGIN
  PERFORM app.ipo_sync_todo();
  RETURN NULL;
END $$;

DROP TRIGGER IF EXISTS ipo_milestone_to_todo ON app.ipo_milestones;
CREATE TRIGGER ipo_milestone_to_todo
  AFTER UPDATE OF status, start_date, target_date, title ON app.ipo_milestones
  FOR EACH STATEMENT EXECUTE FUNCTION app.ipo_milestone_to_todo();

-- ---------- C2. To-Do item ticked -> milestone + deal task ----------
CREATE OR REPLACE FUNCTION app.ipo_todo_to_milestone() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = app, public AS $$
DECLARE
  v_is_done boolean;
  v_mid     uuid;
  v_new     app.ipo_item_status;
BEGIN
  IF pg_trigger_depth() > 1 THEN RETURN NEW; END IF;       -- came from ipo_sync_todo
  IF NOT (NEW.custom ? 'ipo_milestone_id') THEN RETURN NEW; END IF;
  v_mid := (NEW.custom->>'ipo_milestone_id')::uuid;
  SELECT is_done INTO v_is_done FROM app.todo_status_options
   WHERE board_id = NEW.board_id AND key = NEW.status LIMIT 1;
  v_is_done := coalesce(v_is_done, false);

  SELECT CASE
           WHEN v_is_done AND m.status NOT IN ('done','waived') THEN 'done'::app.ipo_item_status
           WHEN NOT v_is_done AND m.status = 'done'             THEN 'in_progress'::app.ipo_item_status
         END
    INTO v_new
    FROM app.ipo_milestones m WHERE m.id = v_mid;
  IF v_new IS NULL THEN RETURN NEW; END IF;

  UPDATE app.ipo_milestones
     SET status = v_new,
         actual_date = CASE WHEN v_new = 'done' THEN current_date ELSE NULL END
   WHERE id = v_mid;

  -- the milestone->task trigger skips nested calls, so update the deal task here
  UPDATE app.tasks t
     SET status       = app.ipo_milestone_status_to_task(v_new),
         completed_at = CASE WHEN v_new = 'done' THEN coalesce(t.completed_at, now()) ELSE NULL END
    FROM app.ipo_milestones m
   WHERE m.id = v_mid AND t.id = m.task_id
     AND t.status IS DISTINCT FROM app.ipo_milestone_status_to_task(v_new);
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS ipo_todo_to_milestone ON app.todo_items;
CREATE TRIGGER ipo_todo_to_milestone
  AFTER UPDATE OF status ON app.todo_items
  FOR EACH ROW EXECUTE FUNCTION app.ipo_todo_to_milestone();

-- ---------- first run ----------
SELECT app.ipo_sync_todo() AS items_created;

-- verification (last statement = the one result grid you see)
SELECT ti.custom->>'src' AS src, ti.due_date, ti.status, ti.title
  FROM app.todo_items ti
 WHERE ti.custom->>'src' IN ('ipo', 'ipo_month')
 ORDER BY (ti.custom->>'src') DESC, ti.due_date, ti.title;
