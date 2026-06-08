-- Migration: investor_stage_focus RLS policies
-- These 4 policies were applied directly to the live DB earlier (when stage
-- badges showed empty because RLS was enabled with zero policies -> deny-all
-- for the authenticated role). This file persists them in the repo so a fresh
-- environment / DB rebuild reproduces them. Idempotent (DROP IF EXISTS + CREATE).

BEGIN;

ALTER TABLE app.investor_stage_focus ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS pol_investor_stage_focus_select ON app.investor_stage_focus;
CREATE POLICY pol_investor_stage_focus_select ON app.investor_stage_focus
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS pol_investor_stage_focus_insert ON app.investor_stage_focus;
CREATE POLICY pol_investor_stage_focus_insert ON app.investor_stage_focus
  FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS pol_investor_stage_focus_update ON app.investor_stage_focus;
CREATE POLICY pol_investor_stage_focus_update ON app.investor_stage_focus
  FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS pol_investor_stage_focus_delete ON app.investor_stage_focus;
CREATE POLICY pol_investor_stage_focus_delete ON app.investor_stage_focus
  FOR DELETE TO authenticated USING (true);

COMMIT;

NOTIFY pgrst, 'reload schema';
