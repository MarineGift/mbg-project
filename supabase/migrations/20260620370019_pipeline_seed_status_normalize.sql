-- ============================================================
-- 20260620370019_pipeline_seed_status_normalize.sql
-- Records the option-A decision: normalize seeded deals' status from the
-- assumed 'open' to the project's existing convention 'active'.
-- 370018 created deals with status='open'; live convention is status='active'.
-- Idempotent: only touches source='pipeline_seed_2026Q3' rows still at 'open'.
-- Keeps repo in sync with the SQL-Editor change already applied.
-- ============================================================

begin;

update app.deals
set status = 'active', updated_at = now()
where source = 'pipeline_seed_2026Q3'
  and status = 'open'
  and deleted_at is null;

commit;

-- Verify: select status, count(*) from app.deals where source='pipeline_seed_2026Q3' group by status;
