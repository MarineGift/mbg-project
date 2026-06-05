-- Add color to campaigns (for board chips / swimlane headers).
-- If you have NOT yet run 20260604_add_campaigns.sql, you can instead
-- just add `  color text,` into that file's create table and skip this.
alter table app.campaigns
  add column if not exists color text;  -- hex string, e.g. '#2563eb'
