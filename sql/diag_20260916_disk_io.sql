-- ###########################################################################
-- ##  SUPABASE SQL EDITOR:  Ctrl+A  (SELECT ALL)  THEN  Run                 ##
-- ###########################################################################
-- diag_20260916_disk_io.sql   (READ ONLY - changes nothing)
--
-- One result grid, four sections:
--   1_top_io_queries   queries that read the most blocks from disk
--   2_seq_scans        tables read by full scan most often
--   3_table_size       biggest tables (heap + toast + index)
--   4_unused_index     indexes never used (write cost only)
-- Paste the grid (or a screenshot) back into the chat.
-- ###########################################################################

with q (section, name, metric_a, metric_b, detail, rn) as (
  select '1_top_io_queries'::text as section,
         left(regexp_replace(s.query, '\s+', ' ', 'g'), 160) as name,
         s.shared_blks_read::bigint as metric_a,
         s.calls::bigint as metric_b,
         round(s.total_exec_time::numeric / 1000, 1)::text || ' s total' as detail,
         row_number() over (order by s.shared_blks_read desc) as rn
    from extensions.pg_stat_statements s
),
sq (section, name, metric_a, metric_b, detail, rn) as (
  select '2_seq_scans'::text,
         t.schemaname || '.' || t.relname,
         t.seq_tup_read::bigint,
         t.seq_scan::bigint,
         'idx_scan ' || coalesce(t.idx_scan, 0)::text || ' / live rows ' || t.n_live_tup::text,
         row_number() over (order by t.seq_tup_read desc)
    from pg_stat_user_tables t
),
sz (section, name, metric_a, metric_b, detail, rn) as (
  select '3_table_size'::text,
         t.schemaname || '.' || t.relname,
         pg_total_relation_size(t.relid)::bigint,
         t.n_live_tup::bigint,
         pg_size_pretty(pg_total_relation_size(t.relid)),
         row_number() over (order by pg_total_relation_size(t.relid) desc)
    from pg_stat_user_tables t
),
ui (section, name, metric_a, metric_b, detail, rn) as (
  select '4_unused_index'::text,
         i.schemaname || '.' || i.indexrelname,
         pg_relation_size(i.indexrelid)::bigint,
         i.idx_scan::bigint,
         'on ' || i.relname,
         row_number() over (order by pg_relation_size(i.indexrelid) desc)
    from pg_stat_user_indexes i
    join pg_index x on x.indexrelid = i.indexrelid
   where i.idx_scan = 0
     and not x.indisunique
     and not x.indisprimary
     and i.schemaname in ('app', 'ai', 'public')
)
select section, name, metric_a, metric_b, detail from q  where rn <= 15
union all
select * from (select section, name, metric_a, metric_b, detail from sq where rn <= 10) a
union all
select * from (select section, name, metric_a, metric_b, detail from sz where rn <= 10) b
union all
select * from (select section, name, metric_a, metric_b, detail from ui where rn <= 10) c
order by section, metric_a desc;
