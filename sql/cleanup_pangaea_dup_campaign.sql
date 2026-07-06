-- ============================================================
-- cleanup_pangaea_dup_campaign.sql (2026-07-06)
-- (A) Retroactive fix: rename existing deal_names left as "Seed Round"
--     to the campaign's current name (the trigger only covers FUTURE renames).
-- (B) Remove the duplicate archived Pangaea campaign (0 active deals).
-- Supabase-editor safe: plain statements, no do-block/temp/semicolon-in-string.
-- Run all; the final VERIFY block confirms the outcome.
--
-- Duplicate identified from probe (6):
--   KEEP : e0000000-...-00000000000a  Bridge Round - Advanced Materials (active, 120 deals, incl. Pangaea Ventures)
--   DROP : d0000000-...-0000000000fe  "Bridge Round - Pangaea (Andrew)"  (archived, 0 active deals)
-- ============================================================

-- (0) SAFETY CHECK: does the DROP campaign have ANY deals (incl. soft-deleted)?
--     If total_deals > 0, STOP and review before deleting.
select 'drop_campaign_deal_audit' as check_name,
       count(*) filter (where d.deleted_at is null) as active_deals,
       count(*) filter (where d.deleted_at is not null) as soft_deleted_deals,
       count(*) as total_deals
from app.deals d
where d.campaign_id = 'd0000000-0000-4000-8000-0000000000fe'::uuid;

-- (A) RETROACTIVE deal_name fix for the KEEP campaign:
--     any deal still carrying " - Seed Round" gets moved to the current name.
--     (The trigger handles future renames; this catches the one already done.)
update app.deals d
set deal_name = replace(d.deal_name, ' - Seed Round', ' - ' || c.name),
    updated_at = now()
from app.campaigns c
where c.id = d.campaign_id
  and d.deleted_at is null
  and d.deal_name like '% - Seed Round'
  and c.name <> 'Seed Round';

-- (B) DELETE the duplicate archived campaign.
--     Guarded: only deletes if it truly has zero non-deleted deals, so a
--     surprise from (0) cannot cause data loss. Uses hard delete because an
--     archived, deal-less campaign has nothing to preserve; switch to a
--     soft-delete (set deleted_at) instead if app.campaigns has that column
--     and you prefer recoverability.
delete from app.campaigns c
where c.id = 'd0000000-0000-4000-8000-0000000000fe'::uuid
  and not exists (
    select 1 from app.deals d
    where d.campaign_id = c.id and d.deleted_at is null);

-- (3) VERIFY
-- 3a: duplicate campaign should be gone (0 rows)
select 'dup_campaign_still_present' as check_name, count(*) as rows
from app.campaigns where id = 'd0000000-0000-4000-8000-0000000000fe'::uuid;

-- 3b: no active deal should still say "Seed Round"
select 'deals_still_seed_round' as check_name, count(*) as rows
from app.deals where deleted_at is null and deal_name like '% - Seed Round';

-- 3c: show remaining Bridge campaigns for a final eyeball
select id, name, status,
       (select count(*) from app.deals d where d.campaign_id = c.id and d.deleted_at is null) as active_deals
from app.campaigns c
where c.name ilike '%bridge%'
order by c.name;
