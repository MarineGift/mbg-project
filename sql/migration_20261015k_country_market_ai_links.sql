-- ============================================================
-- migration_20261015k_country_market_ai_links.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Three fixed AI-analysis link fields on app.country_markets (one row per
-- country, so every mill and filler of that country shares them):
--   chatgpt_url, claude_url, gemini_url  (text, https only)
-- Copies any link already saved in report_links into the matching field
-- (by domain), then the Market tab uses only the three fields.
-- report_links is kept, no longer shown.
-- Re-running is safe.
-- ============================================================

alter table app.country_markets add column if not exists chatgpt_url text;
alter table app.country_markets add column if not exists claude_url  text;
alter table app.country_markets add column if not exists gemini_url  text;

alter table app.country_markets drop constraint if exists country_markets_ai_url_check;
alter table app.country_markets add constraint country_markets_ai_url_check check (
  (chatgpt_url is null or chatgpt_url ~* '^https://') and
  (claude_url  is null or claude_url  ~* '^https://') and
  (gemini_url  is null or gemini_url  ~* '^https://')
);

update app.country_markets cm
set chatgpt_url = coalesce(cm.chatgpt_url, (
      select l ->> 'url' from jsonb_array_elements(cm.report_links) l
      where l ->> 'url' ~* '^https://(chatgpt\.com|chat\.openai\.com)/' limit 1)),
    claude_url = coalesce(cm.claude_url, (
      select l ->> 'url' from jsonb_array_elements(cm.report_links) l
      where l ->> 'url' ~* '^https://claude\.ai/' limit 1)),
    gemini_url = coalesce(cm.gemini_url, (
      select l ->> 'url' from jsonb_array_elements(cm.report_links) l
      where l ->> 'url' ~* '^https://(gemini\.google\.com|g\.co)/' limit 1)),
    updated_at = now()
where jsonb_array_length(coalesce(cm.report_links, '[]'::jsonb)) > 0;

notify pgrst, 'reload schema';

select country_code, country_name,
       chatgpt_url is not null as has_chatgpt,
       claude_url  is not null as has_claude,
       gemini_url  is not null as has_gemini,
       jsonb_array_length(coalesce(report_links, '[]'::jsonb)) as old_links
from app.country_markets
where deleted_at is null
order by country_code;
