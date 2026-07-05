-- ============================================================
-- PROBE (FK only): tables referencing app.parties(id) (2026-07-04) READ ONLY
-- Probe #61 returned only investor_profile columns. This returns the FK list
-- the merge's reparent do-block relies on. Send this result back to confirm
-- every child table is covered.
-- ============================================================
select tc.table_name, kcu.column_name
from information_schema.table_constraints tc
join information_schema.key_column_usage kcu
  on tc.constraint_name = kcu.constraint_name and tc.table_schema = kcu.table_schema
join information_schema.constraint_column_usage ccu
  on tc.constraint_name = ccu.constraint_name and tc.table_schema = ccu.table_schema
where tc.constraint_type = 'FOREIGN KEY'
  and ccu.table_schema = 'app' and ccu.table_name = 'parties'
  and ccu.column_name = 'id'
order by tc.table_name, kcu.column_name;
