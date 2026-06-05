-- ============================================================
-- Pipeline Batch 1: stage semantics + deal lifecycle fields
--                   + stage-change trigger + analytics views
-- Apply in Supabase SQL editor (DB change).
-- ------------------------------------------------------------
-- CONFIRM TOKENS:
--   deals table  -> app.deals   | value col -> amount | stage FK -> stage_id
--   stages table -> app.stages  | ordering col -> sort_order (added below;
--                   if you already order by position/sort_index, use that in views)
-- ============================================================

-- 1) STAGE SEMANTICS -----------------------------------------
alter table app.stages
  add column if not exists is_won     boolean not null default false,
  add column if not exists is_lost    boolean not null default false,
  add column if not exists sort_order integer not null default 0;

-- EXAMPLE: flag your closed stages (edit name matches to YOUR stages):
-- update app.stages set is_won  = true where name ilike 'won%'  or name ilike '%수주%';
-- update app.stages set is_lost = true where name ilike 'lost%' or name ilike '%실주%';

-- 2) DEAL LIFECYCLE FIELDS -----------------------------------
alter table app.deals
  add column if not exists owner_id           uuid,          -- no hard FK (set to your users table if desired)
  add column if not exists priority           text,          -- 'low' | 'medium' | 'high' (free text)
  add column if not exists expected_close_date date,
  add column if not exists next_step          text,
  add column if not exists next_step_date     date,
  add column if not exists won_reason         text,
  add column if not exists lost_reason        text,
  add column if not exists closed_at          timestamptz,
  add column if not exists stage_entered_at   timestamptz,
  add column if not exists last_activity_at   timestamptz;   -- touch this from your activity/email logging

-- backfill stage_entered_at for existing rows
update app.deals
   set stage_entered_at = coalesce(stage_entered_at, updated_at, created_at)
 where stage_entered_at is null;

-- 3) STAGE-CHANGE TRIGGER ------------------------------------
-- On insert or when stage_id changes: stamp stage_entered_at,
-- and set/clear closed_at based on the new stage's won/lost flags.
create or replace function app.deals_track_stage_change()
returns trigger language plpgsql as $$
declare
  v_is_won  boolean;
  v_is_lost boolean;
begin
  if (TG_OP = 'INSERT')
     or (TG_OP = 'UPDATE' and NEW.stage_id is distinct from OLD.stage_id) then
    NEW.stage_entered_at := now();
    select s.is_won, s.is_lost into v_is_won, v_is_lost
      from app.stages s where s.id = NEW.stage_id;
    if coalesce(v_is_won, false) or coalesce(v_is_lost, false) then
      NEW.closed_at := coalesce(NEW.closed_at, now());
    else
      NEW.closed_at := null;  -- deal reopened into an active stage
    end if;
  end if;
  return NEW;
end $$;

drop trigger if exists trg_deals_stage_change on app.deals;
create trigger trg_deals_stage_change
  before insert or update on app.deals
  for each row execute function app.deals_track_stage_change();

-- 4) FUNNEL VIEW: count / value / weighted by stage ----------
create or replace view app.pipeline_funnel
with (security_invoker = on) as
select
  d.organization_id,
  d.stage_id,
  s.name       as stage_name,
  s.sort_order,
  count(*)                          as deal_count,
  coalesce(sum(d.amount), 0)        as total_value,
  coalesce(sum(round(coalesce(d.amount,0)
        * coalesce(d.probability, s.default_probability, 0) / 100.0, 2)), 0) as weighted_value
from app.deals d
left join app.stages s on s.id = d.stage_id
group by d.organization_id, d.stage_id, s.name, s.sort_order;

-- 5) AGING VIEW: time in stage / since last touch / stale flag
create or replace view app.deal_aging
with (security_invoker = on) as
select
  d.id,
  d.organization_id,
  d.stage_id,
  s.name as stage_name,
  d.amount,
  coalesce(d.last_activity_at, d.stage_entered_at, d.created_at) as last_touch,
  greatest(0, extract(day from now() - d.stage_entered_at)::int) as days_in_stage,
  greatest(0, extract(day from now()
      - coalesce(d.last_activity_at, d.stage_entered_at, d.created_at))::int) as days_since_touch,
  (coalesce(s.is_won,false) or coalesce(s.is_lost,false)) as is_closed,
  -- stale = open deal untouched > 14 days (adjust threshold to taste)
  (not (coalesce(s.is_won,false) or coalesce(s.is_lost,false))
   and coalesce(d.last_activity_at, d.stage_entered_at, d.created_at) < now() - interval '14 days')
     as is_stale
from app.deals d
left join app.stages s on s.id = d.stage_id;

-- 6) SUMMARY VIEW: win rate / avg deal / cycle / counts ------
create or replace view app.pipeline_summary
with (security_invoker = on) as
select
  d.organization_id,
  count(*) filter (where not coalesce(s.is_won,false) and not coalesce(s.is_lost,false)) as open_count,
  count(*) filter (where coalesce(s.is_won,false))  as won_count,
  count(*) filter (where coalesce(s.is_lost,false)) as lost_count,
  coalesce(sum(d.amount) filter
     (where not coalesce(s.is_won,false) and not coalesce(s.is_lost,false)), 0) as open_value,
  coalesce(round(avg(d.amount) filter (where coalesce(s.is_won,false)), 2), 0)  as avg_won_value,
  case
    when count(*) filter (where coalesce(s.is_won,false) or coalesce(s.is_lost,false)) = 0 then 0
    else round(100.0 * count(*) filter (where coalesce(s.is_won,false))
         / count(*) filter (where coalesce(s.is_won,false) or coalesce(s.is_lost,false)), 1)
  end as win_rate_pct,
  coalesce(round(avg(extract(day from d.closed_at - d.created_at))
     filter (where coalesce(s.is_won,false)), 1), 0) as avg_cycle_days
from app.deals d
left join app.stages s on s.id = d.stage_id
group by d.organization_id;

-- Sales velocity (compute in app):
--   velocity_per_day = open_count * avg_won_value * (win_rate_pct/100) / NULLIF(avg_cycle_days,0)
