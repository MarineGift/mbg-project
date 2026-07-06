-- ============================================================
-- migration_campaign_rename_trigger.sql (2026-07-06)
-- Auto-sync app.deals.deal_name when app.campaigns.name is renamed.
-- MODE: token replacement (preserves the deal_name's existing shape, incl.
--       the parenthesised suffix like "(Advanced Materials)").
--
-- Problem the earlier trigger had:
--   deal_name embeds the campaign name but not verbatim -- the campaign
--   "Bridge Round - Advanced Materials" appears in deals as
--   "3M Ventures - Bridge Round (Advanced Materials)". A literal match on the
--   full old campaign name never fires.
--
-- This version diffs old.name vs new.name and replaces ONLY the changed
-- leading token inside deal_name, so the party prefix and the parenthesised
-- suffix are untouched.
--
-- How the diff works:
--   old.name = 'Seed Round - Advanced Materials'
--   new.name = 'Bridge Round - Advanced Materials'
--   -> common trailing part ' - Advanced Materials' is stripped from both,
--      leaving old_token='Seed Round', new_token='Bridge Round'.
--   Then every deal_name for that campaign has old_token -> new_token replaced.
--   deal "3M Ventures - Seed Round (Advanced Materials)"
--     -> "3M Ventures - Bridge Round (Advanced Materials)".
--
-- If old and new share no trailing part, the whole names are used as the
-- tokens (still correct, just broader).
--
-- Idempotent, Supabase-editor safe (single $$ body, no temp tables).
-- ============================================================

create or replace function app.sync_deal_name_on_campaign_rename()
returns trigger
language plpgsql
as $func$
declare
  v_old  text := old.name;
  v_new  text := new.name;
  v_oldt text;
  v_newt text;
  i int;
  min_len int;
  common_tail int := 0;
begin
  if v_new is not distinct from v_old then
    return new;
  end if;

  -- Find the length of the common trailing substring of old and new.
  min_len := least(length(v_old), length(v_new));
  i := 0;
  while i < min_len
        and substr(v_old, length(v_old) - i, 1) = substr(v_new, length(v_new) - i, 1)
  loop
    i := i + 1;
  end loop;
  common_tail := i;

  -- Tokens = names minus their shared tail. These are the parts that differ.
  v_oldt := left(v_old, length(v_old) - common_tail);
  v_newt := left(v_new, length(v_new) - common_tail);

  -- Guard: if the changed token is empty (e.g. only the tail differs, or names
  -- are equal after all), fall back to replacing the full name to stay correct.
  if v_oldt = '' or v_newt = '' then
    v_oldt := v_old;
    v_newt := v_new;
  end if;

  -- Replace only where the token follows the "<party> - " separator, so a
  -- token that also appears inside a company name (e.g. "Seedcamp") is left
  -- alone. The campaign name always sits after the first " - " in deal_name.
  update app.deals d
     set deal_name = replace(d.deal_name, ' - ' || v_oldt, ' - ' || v_newt),
         updated_at = now()
   where d.campaign_id = new.id
     and d.deleted_at is null
     and d.deal_name like '% - ' || v_oldt || '%';

  return new;
end
$func$;

-- Recreate the trigger cleanly (replaces the earlier hand-made one).
drop trigger if exists trg_sync_deal_name_on_campaign_rename on app.campaigns;

create trigger trg_sync_deal_name_on_campaign_rename
  after update of name on app.campaigns
  for each row
  execute function app.sync_deal_name_on_campaign_rename();

-- VERIFY: trigger present + enabled
select tgname, tgrelid::regclass as on_table, tgenabled
from pg_trigger
where tgname = 'trg_sync_deal_name_on_campaign_rename';
