-- ============================================================
-- DROP: investor_profile.geographic_focus (2026-07-04)
-- Country/region data already lives on app.parties -> field redundant.
-- !! RUN ONLY AFTER the layout patch is DEPLOYED (14ac12c+layout commit):
-- the previous code selects this column and would 500 on party detail.
-- ============================================================

alter table app.investor_profile drop column if exists geographic_focus;

-- verify
select column_name from information_schema.columns
where table_schema = 'app' and table_name = 'investor_profile'
order by ordinal_position;
