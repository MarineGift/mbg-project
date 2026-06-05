-- ============================================================
-- Deal timeline: start_date / end_date for Gantt + Calendar views.
-- Apply in Supabase SQL editor.
-- CONFIRM TOKENS: deals table -> app.deals
-- ============================================================

alter table app.deals
  add column if not exists start_date date,
  add column if not exists end_date   date;

-- backfill so existing deals show on the timeline immediately:
update app.deals
   set start_date = coalesce(start_date, created_at::date)
 where start_date is null;

update app.deals
   set end_date = coalesce(end_date, expected_close_date)
 where end_date is null and expected_close_date is not null;

-- sanity: end >= start (NOT VALID so it won't fail on existing dirty rows;
-- run `alter table app.deals validate constraint deals_dates_chk;` later if you want).
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'deals_dates_chk'
  ) then
    alter table app.deals
      add constraint deals_dates_chk
      check (end_date is null or start_date is null or end_date >= start_date)
      not valid;
  end if;
end $$;
