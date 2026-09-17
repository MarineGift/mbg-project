-- ============================================================
-- diag_20260916c_ai_model_cost.sql   (READ ONLY)
-- Ctrl+A (select all) then Run
-- AI runs by model and day for the last 7 days.
-- After the OpenAI switch, new rows show model_used = gpt-5-mini / gpt-5-nano
-- ============================================================
select date_trunc('day', created_at) as day_utc,
       model_used,
       count(*) as runs,
       sum(input_tokens) as input_tokens,
       sum(output_tokens) as output_tokens,
       round(sum(cost_usd)::numeric, 4) as cost_usd
  from ai.runs
 where created_at >= now() - interval '7 days'
 group by 1, 2
 order by 1 desc, 6 desc;
