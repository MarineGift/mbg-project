select now() as db_time, (select count(*) from pg_stat_activity where state = 'active') as active_queries
