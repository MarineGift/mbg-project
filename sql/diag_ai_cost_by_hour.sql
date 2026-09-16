-- diag_ai_cost_by_hour.sql (READ ONLY) - AI drafts / runs / cost per hour, last 2 days
with d as (
  select date_trunc('hour', created_at) as h, count(*) as n, count(distinct inbound_communication_id) as nd
    from ai.drafts where created_at >= now() - interval '2 days' group by 1
), r as (
  select date_trunc('hour', created_at) as h, count(*) as n, round(sum(cost_usd)::numeric, 2) as c
    from ai.runs where created_at >= now() - interval '2 days' group by 1
)
select coalesce(d.h, r.h) as hour_utc, d.n as drafts, d.nd as drafts_distinct_inbound,
       r.n as ai_runs, r.c as cost_usd
  from d full join r on r.h = d.h
 order by 1;