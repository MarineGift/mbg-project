-- ============================================================
-- migration_20261015j_country_market_links.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Report links for the Market tab: app.country_markets.report_links jsonb
-- array of {label, url, added_at}. Links are added and removed on the Market
-- tab ("링크 추가"), e.g. a ChatGPT shared-conversation URL per country.
-- Re-running is safe.
-- ============================================================

alter table app.country_markets
  add column if not exists report_links jsonb not null default '[]'::jsonb;

notify pgrst, 'reload schema';

select country_code, country_name, jsonb_array_length(report_links) as links
from app.country_markets
where deleted_at is null
order by country_code;
