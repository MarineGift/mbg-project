-- Verify the LinkedIn messages import into app.communications.
-- Run in Supabase SQL Editor (UTF-8). Save WITHOUT BOM.

-- 1) counts by direction
select direction, count(*) as n
from app.communications
where channel = 'linkedin' and deleted_at is null
group by direction
order by direction;

-- 2) linked-to-contact coverage
select count(*) filter (where contact_id is not null) as linked_to_contact,
       count(*) filter (where contact_id is null)     as unlinked,
       count(*)                                        as total
from app.communications
where channel = 'linkedin' and deleted_at is null;

-- 3) most recent 15 messages (preview)
select occurred_at, direction, from_name,
       left(coalesce(subject, body_plain), 60) as preview,
       (contact_id is not null) as linked
from app.communications
where channel = 'linkedin' and deleted_at is null
order by occurred_at desc nulls last
limit 15;
