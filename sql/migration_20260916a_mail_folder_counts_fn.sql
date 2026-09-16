-- ###########################################################################
-- ##  SUPABASE SQL EDITOR:  Ctrl+A  (SELECT ALL)  THEN  Run                 ##
-- ###########################################################################
-- migration_20260916a_mail_folder_counts_fn.sql   (LIGHT - run first)
--
-- Replaces app.mail_folder_counts() with a version that reads inbound mail
-- once and matches folders with plain equality joins, instead of one full
-- scan of app.communications per folder node.
-- Same signature, same result. No index build, no data change.
-- IDEMPOTENT: safe to re-run.
-- Heavy index build is in migration_20260916b (run later).
-- ###########################################################################

drop function if exists app.mail_folder_counts();

create function app.mail_folder_counts()
returns table (folder_id uuid, inbound bigint, unread bigint)
language sql
stable
security invoker
set search_path = app, public
as $fn$
  with recursive tree as (
    select f.id as root, f.id as node, 0 as depth
      from app.mail_folders f
     where f.deleted_at is null
    union all
    select t.root, c.id, t.depth + 1
      from tree t
      join app.mail_folders c
        on c.parent_id = t.node
       and c.deleted_at is null
     where t.depth < 5
  ),
  nodes as (
    select t.root, n.organization_id, n.party_id, n.match_domains, n.match_addresses
      from tree t
      join app.mail_folders n on n.id = t.node
  ),
  party_keys as (
    select distinct root, organization_id, party_id
      from nodes
     where party_id is not null
  ),
  domain_keys as (
    select distinct nd.root, nd.organization_id, lower(d) as dom
      from nodes nd
     cross join lateral unnest(nd.match_domains) as d
  ),
  address_keys as (
    select distinct nd.root, nd.organization_id, lower(a) as addr
      from nodes nd
     cross join lateral unnest(nd.match_addresses) as a
  ),
  inb as materialized (
    select c.id,
           c.organization_id,
           c.party_id,
           c.read_at,
           lower(c.from_address) as addr,
           split_part(lower(c.from_address), '@', 2) as dom
      from app.communications c
     where c.deleted_at is null
       and c.direction = 'inbound'
       and c.organization_id in (select organization_id from nodes)
  ),
  hits as (
    select pk.root, i.id, i.read_at
      from party_keys pk
      join inb i
        on i.organization_id = pk.organization_id
       and i.party_id = pk.party_id
    union
    select dk.root, i.id, i.read_at
      from domain_keys dk
      join inb i
        on i.organization_id = dk.organization_id
       and i.dom = dk.dom
    union
    select ak.root, i.id, i.read_at
      from address_keys ak
      join inb i
        on i.organization_id = ak.organization_id
       and i.addr = ak.addr
  ),
  roots as (
    select distinct root from tree
  )
  select r.root,
         count(h.id) as inbound,
         count(h.id) filter (where h.read_at is null) as unread
    from roots r
    left join hits h on h.root = r.root
   group by r.root
$fn$;

grant execute on function app.mail_folder_counts() to authenticated;

select count(*) as folder_rows from app.mail_folder_counts();
