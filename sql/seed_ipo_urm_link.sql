-- ============================================================
-- seed_ipo_urm_link.sql
-- Creates the URM side of the IPO program and links it:
--   campaign  "IPO Program — Nasdaq Listing 2029"
--   pipeline  ipo_program, stages P0..P6 (code = ipo_phases.code)
--   deal      "Nasdaq Listing 2029" (party = Self / MarineBio Group)
--   tasks     one per milestone (66), linked via ipo_milestones.task_id
--   stage checklists = readiness-gate pass conditions, per phase
-- Requires: migration_ipo_urm_link.sql. Re-runnable.
-- ============================================================
DO $$
DECLARE
  -- >>> replace before running <<<
  v_org uuid := '00000000-0000-0000-0000-000000000000';
  -- >>> replace before running <<<
  v_prog uuid; v_self uuid; v_camp uuid; v_pipe uuid; v_deal uuid; v_stage uuid; v_task uuid;
  r record; n int := 0;
BEGIN
  IF v_org = '00000000-0000-0000-0000-000000000000' THEN
    RAISE EXCEPTION 'Replace v_org with the real organization_id before running.';
  END IF;
  SELECT id INTO v_prog FROM app.ipo_programs WHERE organization_id = v_org AND name = 'Nasdaq Listing 2029';
  IF v_prog IS NULL THEN RAISE EXCEPTION 'IPO program not found'; END IF;

  -- Self party (the issuer)
  SELECT p.id INTO v_self FROM app.parties p JOIN app.party_types t ON t.id = p.party_type_id
   WHERE p.organization_id = v_org AND t.code = 'self' AND p.deleted_at IS NULL ORDER BY p.created_at LIMIT 1;
  IF v_self IS NULL THEN RAISE EXCEPTION 'No party of type self found'; END IF;

  -- campaign
  SELECT id INTO v_camp FROM app.campaigns WHERE organization_id = v_org AND name = 'IPO Program — Nasdaq Listing 2029';
  IF v_camp IS NULL THEN
    INSERT INTO app.campaigns (organization_id, name, description, status, start_date, end_date, color)
    VALUES (v_org, 'IPO Program — Nasdaq Listing 2029',
            'Container for the Nasdaq listing program deal. Build-to 2029Q4, window 2029Q4–2030Q2.',
            'active', DATE '2026-09-01', DATE '2030-06-30', '#dc2626')
    RETURNING id INTO v_camp;
  END IF;

  -- pipeline + stages (code mirrors ipo_phases.code)
  SELECT id INTO v_pipe FROM app.pipelines WHERE organization_id = v_org AND code = 'ipo_program';
  IF v_pipe IS NULL THEN
    INSERT INTO app.pipelines (organization_id, code, name, description, is_default, is_active, sort_order)
    VALUES (v_org, 'ipo_program', 'IPO Program',
            'Nasdaq listing program. Stages = P0–P6 phases; one deal; tasks = milestones. Stage moves into P5/P6 require recorded Gate 2/3 decisions.',
            false, true, 89)
    RETURNING id INTO v_pipe;
  END IF;
  FOR r IN SELECT code, name, sort_order FROM app.ipo_phases ORDER BY sort_order LOOP
    INSERT INTO app.stages (organization_id, pipeline_id, code, name, sort_order, default_probability_pct, is_won, is_lost, is_terminal, is_active)
    SELECT v_org, v_pipe, r.code, r.name, r.sort_order + 1, LEAST(100, 10 + r.sort_order * 15), false, false, false, true
     WHERE NOT EXISTS (SELECT 1 FROM app.stages WHERE pipeline_id = v_pipe AND code = r.code);
  END LOOP;

  -- program deal
  SELECT deal_id INTO v_deal FROM app.ipo_programs WHERE id = v_prog;
  IF v_deal IS NULL THEN
    SELECT id INTO v_stage FROM app.stages WHERE pipeline_id = v_pipe AND code = 'P0';
    INSERT INTO app.deals (organization_id, party_id, pipeline_id, current_stage_id, deal_name, description, status,
                           value_currency, priority, campaign_id, start_date, end_date, expected_close_date, stage_entered_at, extra_data)
    VALUES (v_org, v_self, v_pipe, v_stage, 'Nasdaq Listing 2029',
            'IPO readiness program. Milestones, gates and criteria live in the IPO module (/ipo); this deal carries tasks, checklists and engagements.',
            'active', 'USD', 'high', v_camp, DATE '2026-09-01', DATE '2030-06-30', DATE '2029-11-30', now(),
            jsonb_build_object('ipo_program_id', v_prog))
    RETURNING id INTO v_deal;
    UPDATE app.ipo_programs SET deal_id = v_deal WHERE id = v_prog;
  END IF;

  -- tasks: one per milestone
  FOR r IN
    SELECT m.id, m.code, m.title, m.rule_ref, m.start_date, m.target_date, m.is_gate, m.status, ph.code AS phase_code
      FROM app.ipo_milestones m LEFT JOIN app.ipo_phases ph ON ph.id = m.phase_id
     WHERE m.program_id = v_prog AND m.task_id IS NULL
     ORDER BY m.sort_order
  LOOP
    SELECT id INTO v_stage FROM app.stages WHERE pipeline_id = v_pipe AND code = r.phase_code;
    INSERT INTO app.tasks (organization_id, deal_id, stage_id, title, description, status, priority, start_at, due_at, extra_data)
    VALUES (v_org, v_deal, v_stage, r.code || ' · ' || r.title,
            coalesce('Rule: ' || r.rule_ref || E'\n', '') || CASE WHEN r.is_gate THEN 'GATE milestone — blocks the phase until done.' ELSE 'Milestone.' END,
            app.ipo_milestone_status_to_task(r.status), CASE WHEN r.is_gate THEN 'high' ELSE 'medium' END,
            r.start_date::timestamptz, (r.target_date + 1)::timestamptz - interval '1 second',
            jsonb_build_object('ipo_milestone_code', r.code, 'ipo_gate', r.is_gate))
    RETURNING id INTO v_task;
    UPDATE app.ipo_milestones SET task_id = v_task WHERE id = r.id;
    n := n + 1;
  END LOOP;
  RAISE NOTICE 'tasks created: %', n;

  -- stage checklists = gate pass conditions, placed on the phase of the gate's linked milestones
  n := 0;
  FOR r IN
    SELECT DISTINCT ph.code AS phase_code, g.code AS gate_code, g.question, g.pass_condition
      FROM app.ipo_readiness_gates g
      JOIN app.ipo_gate_milestones gm ON gm.gate_id = g.id
      JOIN app.ipo_milestones m ON m.id = gm.milestone_id
      JOIN app.ipo_phases ph ON ph.id = m.phase_id
     WHERE g.program_id = v_prog
  LOOP
    SELECT id INTO v_stage FROM app.stages WHERE pipeline_id = v_pipe AND code = r.phase_code;
    INSERT INTO app.stage_checklist_templates (organization_id, stage_id, title)
    SELECT v_org, v_stage, r.gate_code || ' · ' || r.question || coalesce(' — ' || r.pass_condition, '')
     WHERE NOT EXISTS (SELECT 1 FROM app.stage_checklist_templates WHERE stage_id = v_stage AND title LIKE r.gate_code || ' · %');
    n := n + 1;
  END LOOP;
  RAISE NOTICE 'stage checklist rows processed: %', n;
  RAISE NOTICE 'IPO program linked: deal % in pipeline ipo_program', v_deal;
END $$;

-- Verify
-- SELECT code, status, task_status, due_at::date, engagements FROM app.v_ipo_milestone_tasks ORDER BY code LIMIT 10;
-- SELECT s.code, s.name, count(t.id) AS tasks FROM app.stages s LEFT JOIN app.tasks t ON t.stage_id = s.id
--   WHERE s.pipeline_id = (SELECT id FROM app.pipelines WHERE code='ipo_program') GROUP BY s.code, s.name, s.sort_order ORDER BY s.sort_order;
-- Sync test: mark task done in the UI -> milestone shows done with actual_date; set milestone done in /ipo -> task done.
-- Guard test: UPDATE app.deals SET current_stage_id = (P5 id) WHERE deal_name='Nasdaq Listing 2029';  -> raises until a gate2 decision is recorded.
