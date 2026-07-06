-- ============================================================
-- probe_campaign_pipeline_link.sql (2026-07-06) -- READ ONLY
-- Confirms the exact campaign<->deal wiring before we write a trigger.
-- Run all, send back every result set. Nothing is modified.
-- ============================================================

-- (1) campaigns table: columns (find the name column + pk)
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'app' and table_name = 'campaigns'
order by ordinal_position;

-- (2) deals table: columns (confirm campaign_id exists + its exact name,
--     and whether deal_name is the field that embeds the campaign name)
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'app' and table_name = 'deals'
  and (column_name ilike '%campaign%' or column_name ilike '%name%' or column_name = 'id')
order by ordinal_position;

-- (3) FK from deals -> campaigns (exact column + target)
select tc.constraint_name, kcu.column_name as deals_col,
       ccu.table_name as ref_table, ccu.column_name as ref_col
from information_schema.table_constraints tc
join information_schema.key_column_usage kcu
  on tc.constraint_name = kcu.constraint_name and tc.table_schema = kcu.table_schema
join information_schema.constraint_column_usage ccu
  on tc.constraint_name = ccu.constraint_name and tc.table_schema = ccu.table_schema
where tc.constraint_type = 'FOREIGN KEY'
  and tc.table_schema = 'app' and tc.table_name = 'deals'
  and (kcu.column_name ilike '%campaign%' or ccu.table_name = 'campaigns');

-- (4) The Seed/Bridge campaigns in question (see current names + ids + dupes)
select id, name,
       (select count(*) from app.deals d
          where d.campaign_id = c.id and d.deleted_at is null) as active_deals
from app.campaigns c
where c.name ilike '%bridge%' or c.name ilike '%seed%' or c.name ilike '%pangaea%'
   or c.name ilike '%advanced material%'
order by c.name;

-- (5) Deals whose deal_name still embeds "Seed Round" (what needs fixing)
select d.id, d.deal_name, d.campaign_id, c.name as campaign_name, p.code as pipeline
from app.deals d
left join app.campaigns c on c.id = d.campaign_id
left join app.pipelines p on p.id = d.pipeline_id
where d.deleted_at is null
  and (d.deal_name ilike '%seed round%' or d.deal_name ilike '%bridge round%'
       or d.deal_name ilike '%pangaea%')
order by d.deal_name;

-- (6) Duplicate Pangaea campaigns: list them so we pick which to delete
select c.id, c.name, c.status, c.created_at,
       (select count(*) from app.deals d where d.campaign_id = c.id and d.deleted_at is null) as active_deals,
       (select string_agg(distinct pp.party_name, ', ')
          from app.deals d join app.parties pp on pp.id = d.party_id
          where d.campaign_id = c.id and d.deleted_at is null) as companies
from app.campaigns c
where c.name ilike '%pangaea%'
   or exists (
     select 1 from app.deals d join app.parties pp on pp.id = d.party_id
     where d.campaign_id = c.id and d.deleted_at is null and pp.party_name ilike '%pangaea%')
order by c.created_at;
