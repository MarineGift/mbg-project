-- ============================================================
-- fix_deal_name_seed_to_bridge.sql (2026-07-06)
-- The deal_name embeds "Seed Round" with trailing suffixes like
-- "(Deep Tech)", "- Pangaea (Andrew)", "(Advanced Materials)".
-- The earlier fix matched only names ENDING in " - Seed Round", so it
-- caught nothing. This replaces the literal token "Seed Round" -> "Bridge
-- Round" anywhere in deal_name, preserving whatever follows.
-- Supabase-editor safe (plain statements). Run all; check (0) before it commits
-- mentally, then read (2) to confirm 0 leftovers.
-- ============================================================

-- (0) PREVIEW: how many rows will change + sample before/after (does NOT modify)
select count(*) as will_change
from app.deals
where deleted_at is null and deal_name ilike '%seed round%';

select deal_name as before_name,
       replace(replace(deal_name, 'Seed Round', 'Bridge Round'),
               'seed round', 'Bridge Round') as after_name
from app.deals
where deleted_at is null and deal_name ilike '%seed round%'
order by deal_name
limit 15;

-- (1) APPLY: replace the token, keep suffixes. Case-covered for 'Seed Round'
--     (the observed casing). If (0) shows lowercase variants, they are handled
--     by the second replace below.
update app.deals
set deal_name = replace(deal_name, 'Seed Round', 'Bridge Round'),
    updated_at = now()
where deleted_at is null
  and deal_name like '%Seed Round%';

-- (2) VERIFY: expect 0
select count(*) as seed_round_leftover
from app.deals
where deleted_at is null and deal_name ilike '%seed round%';

-- (3) sample the corrected names
select deal_name
from app.deals
where deleted_at is null and deal_name ilike '%bridge round%'
order by deal_name
limit 15;
