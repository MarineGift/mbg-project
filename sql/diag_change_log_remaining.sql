-- diag_change_log_remaining.sql (READ ONLY) - how much slim work is left after id 58000
select count(*) as rows_total,
       max(id) as max_id,
       count(*) filter (where id > 58000) as rows_after_58000,
       count(*) filter (where id > 58000
                          and (pg_column_size(old_data) > 2000 or pg_column_size(new_data) > 2000)) as candidates_after_58000,
       pg_size_pretty(pg_total_relation_size('audit.change_log')) as total_size
  from audit.change_log;