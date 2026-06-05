-- ============================================================
-- Deal forecasting (weighted pipeline) + deal-copy support.
-- Apply in Supabase SQL editor (DB change; git push only versions the file).
-- ------------------------------------------------------------
-- CONFIRM TOKENS:
--   deals table  -> app.deals        (swap to app.engagements if canonical)
--   value column -> app.deals.amount (rename in the views if it is value/deal_value)
--   stage FK     -> app.deals.stage_id
--   stages table -> app.stages
-- ============================================================

-- 1) per-stage default win probability (0-100)
alter table app.stages
  add column if not exists default_probability numeric(5,2) not null default 0;

-- 2) per-deal override (null = inherit the stage default)
alter table app.deals
  add column if not exists probability numeric(5,2);

-- (optional) only if deals has no monetary column yet:
-- alter table app.deals add column if not exists amount numeric(14,2);

-- 3) EXAMPLE: seed sensible stage defaults. Edit the name matches to YOUR stages.
-- update app.stages set default_probability = 10  where name ilike 'prospect%';
-- update app.stages set default_probability = 25  where name ilike 'qualif%';
-- update app.stages set default_probability = 50  where name ilike 'propos%';
-- update app.stages set default_probability = 75  where name ilike 'negoti%';
-- update app.stages set default_probability = 100 where name ilike 'won%';
-- update app.stages set default_probability = 0   where name ilike 'lost%';

-- 4) per-deal forecast view (security_invoker => respects deals RLS)
create or replace view app.deal_forecast
with (security_invoker = on) as
select
  d.id,
  d.organization_id,
  d.campaign_id,
  d.stage_id,
  d.amount,
  coalesce(d.probability, s.default_probability, 0) as effective_probability,
  round(coalesce(d.amount, 0)
        * coalesce(d.probability, s.default_probability, 0) / 100.0, 2) as forecast_value
from app.deals d
left join app.stages s on s.id = d.stage_id;

-- 5) per-campaign rollup: deal count, total value, weighted forecast
create or replace view app.campaign_forecast
with (security_invoker = on) as
select
  c.id   as campaign_id,
  c.organization_id,
  c.name,
  count(d.id) as deal_count,
  coalesce(sum(d.amount), 0) as total_value,
  coalesce(sum(round(coalesce(d.amount, 0)
        * coalesce(d.probability, s.default_probability, 0) / 100.0, 2)), 0) as weighted_forecast
from app.campaigns c
left join app.deals  d on d.campaign_id = c.id
left join app.stages s on s.id = d.stage_id
group by c.id, c.organization_id, c.name;
