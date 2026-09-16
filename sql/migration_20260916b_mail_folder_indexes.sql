-- ###########################################################################
-- ##  SUPABASE SQL EDITOR:  Ctrl+A  (SELECT ALL)  THEN  Run                 ##
-- ###########################################################################
-- migration_20260916b_mail_folder_indexes.sql   (HEAVY - run later)
--
-- Run only after migration_20260916a AND after the Disk IO graph has
-- recovered (the index build reads all of app.communications once).
-- Partial covering index lets app.mail_folder_counts() read a narrow index
-- instead of the wide mail rows. Plus a tiny index for the mailrun poll.
-- IDEMPOTENT: safe to re-run. No data change.
-- ###########################################################################

create index if not exists idx_communications_inbound_folder
  on app.communications (organization_id, party_id)
  include (from_address, read_at)
  where deleted_at is null and direction = 'inbound';

create index if not exists idx_mail_runs_active
  on app.mail_runs (created_at)
  where status in ('queued', 'running');

analyze app.communications;

select indexname
  from pg_indexes
 where schemaname = 'app'
   and indexname in ('idx_communications_inbound_folder', 'idx_mail_runs_active');
