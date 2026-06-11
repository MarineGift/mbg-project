-- ============================================================
-- 20260612010000_investors_remove_won_lost_stages.sql
-- Remove Won / Lost stages from the Investors pipeline.
--
-- Rationale: deal outcome is already tracked on app.deals
-- (status, won_lost_reason, actual_close_date). Terminal
-- outcomes do not need kanban columns.
--
-- Pipeline : Investors  de80525d-5537-4971-ad8f-d2080a8e65b0
-- Removes  : won  9651bc9f-2322-42a9-99d1-f6d6b4fed99c
--            lost 9adca6af-133d-4438-8d0b-ad45b8aac0b6
--
-- Verified before writing (DIAG 2026-06-12):
--   - 0 deals currently sit on won/lost (only stages
--     5e8737cc... 85 deals, 1147f55e... 1 deal are in use)
--   - app.stages has is_won / is_lost / is_terminal flags
-- ============================================================

begin;

-- 1) Guard: abort if any live deal sits on a won/lost stage
do $$
declare v_cnt int;
begin
  select count(*) into v_cnt
  from app.deals d
  join app.stages s on s.id = d.current_stage_id
  where s.pipeline_id = 'de80525d-5537-4971-ad8f-d2080a8e65b0'
    and (s.is_won or s.is_lost);
  if v_cnt > 0 then
    raise exception
      'Cannot remove stages: % deal(s) still on Won/Lost. Move them first.',
      v_cnt;
  end if;
end $$;

-- 2) Clean every table that references these stages via FK
--    (stage_checklist_templates, stage_task_templates,
--     deal_stage_history, ...) discovered dynamically so we do
--    not guess column names. app.deals is excluded on purpose
--    (guarded to be zero above).
do $$
declare r record;
begin
  for r in
    select con.conrelid::regclass::text as tbl, att.attname as col
    from pg_constraint con
    cross join lateral unnest(con.conkey) as k(attnum)
    join pg_attribute att
      on att.attrelid = con.conrelid and att.attnum = k.attnum
    where con.confrelid = 'app.stages'::regclass
      and con.contype = 'f'
      and con.conrelid <> 'app.deals'::regclass
  loop
    execute format(
      'delete from %s where %I in
         (select id from app.stages
           where pipeline_id = %L and (is_won or is_lost))',
      r.tbl, r.col, 'de80525d-5537-4971-ad8f-d2080a8e65b0');
    raise notice 'cleaned references in %.%', r.tbl, r.col;
  end loop;
end $$;

-- 3) Delete the two stages
delete from app.stages
where pipeline_id = 'de80525d-5537-4971-ad8f-d2080a8e65b0'
  and (is_won or is_lost);

commit;

-- Verify (expect 7 rows, no won/lost):
-- select code, name, sort_order, is_terminal
-- from app.stages
-- where pipeline_id = 'de80525d-5537-4971-ad8f-d2080a8e65b0'
-- order by sort_order;
