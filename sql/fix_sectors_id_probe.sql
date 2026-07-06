-- READ ONLY: how is app.sectors.id generated? (identity? serial? default? none?)
select column_name, data_type, is_nullable, column_default, is_identity, identity_generation
from information_schema.columns
where table_schema='app' and table_name='sectors'
order by ordinal_position;

-- current max id + a couple sample rows to see the id shape
select max(id) as max_id, count(*) as n from app.sectors;
select id, code, label_en, sort_order from app.sectors order by id limit 5;
