-- ============================================================
-- fix_20261011_greentown_dual_domain.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Problem
--   Greentown Labs staff mail comes from two domains, greentownlabs.com and
--   greentownlabs.org. URM only knew the .com one:
--     - the inbound gate (email_whitelist + known-counterpart check) did not
--       recognise @greentownlabs.org, so such mail could be skipped at ingest
--     - the Greentown Labs Houston mail folder pinned only greentownlabs.com
--     - staff contacts carry one address, e.g. Chloe is stored as .com while
--       she now writes from .org, so her new mail matched no contact
--
-- What this does (idempotent, safe to re-run)
--   1. email_whitelist: both Greentown domains as active domain rules
--   2. mail_folders: every folder pinning one Greentown domain gets the other
--   3. contact_emails: each Greentown staff contact gets its current address
--      (primary) plus the twin on the other domain (label alias)
--   4. contacts.email_secondary: the twin, when empty and unused elsewhere
--   5. communications: inbound Greentown mail with no party is linked to the
--      staff contact (or to the Greentown Labs Houston party when no contact
--      owns the address). Will intro mail is excluded on purpose - it is
--      investor-classified. Mail the old domain fallback pinned on a
--      colleague contact is re-pointed to the real owner.
--   6. VERIFY - one result set
--
-- Nothing is deleted. No contact is merged.
-- ============================================================


-- ------------------------------------------------------------
-- 1) whitelist: both domains, active
-- ------------------------------------------------------------
insert into app.email_whitelist (organization_id, pattern, kind, notes, is_active)
select gt.organization_id, v.d, 'domain', 'Greentown Labs staff domain (dual .com and .org)', true
  from (values ('greentownlabs.com'), ('greentownlabs.org')) as v(d)
 cross join lateral (
        select p.organization_id
          from app.parties p
         where p.party_name = 'Greentown Labs Houston'
           and p.deleted_at is null
         order by p.updated_at desc
         limit 1
       ) gt
 where not exists (
        select 1
          from app.email_whitelist w
         where w.organization_id = gt.organization_id
           and lower(w.pattern) = v.d
           and w.kind = 'domain'
       );

update app.email_whitelist w
   set is_active = true
 where w.kind = 'domain'
   and lower(w.pattern) in ('greentownlabs.com', 'greentownlabs.org')
   and w.is_active = false;


-- ------------------------------------------------------------
-- 2) mail folders: pin the twin domain next to the one already pinned
-- ------------------------------------------------------------
update app.mail_folders f
   set match_domains = array_append(f.match_domains, 'greentownlabs.org'),
       updated_at    = now()
 where f.deleted_at is null
   and 'greentownlabs.com' = any (f.match_domains)
   and not ('greentownlabs.org' = any (f.match_domains));

update app.mail_folders f
   set match_domains = array_append(f.match_domains, 'greentownlabs.com'),
       updated_at    = now()
 where f.deleted_at is null
   and 'greentownlabs.org' = any (f.match_domains)
   and not ('greentownlabs.com' = any (f.match_domains));


-- ------------------------------------------------------------
-- 3a) contact_emails: the contact's own address as primary
--     (only when the contact has no contact_emails rows yet, so the staff
--      panel keeps showing it once the alias row exists)
-- ------------------------------------------------------------
with staff as (
  select c.id,
         lower(trim(c.email)) as addr
    from app.contacts c
    join app.parties p on p.id = c.party_id
   where c.deleted_at is null
     and p.deleted_at is null
     and p.party_name ilike 'greentown labs%'
     and split_part(lower(trim(c.email)), '@', 2) in ('greentownlabs.com', 'greentownlabs.org')
)
insert into app.contact_emails (contact_id, email, label, is_primary, source)
select s.id, s.addr, null, true, 'fix_20261011_greentown_dual_domain'
  from staff s
 where not exists (
        select 1 from app.contact_emails ce where ce.contact_id = s.id
       );


-- ------------------------------------------------------------
-- 3b) contact_emails: the twin on the other domain as alias
--     skipped when any contact already owns the twin address
-- ------------------------------------------------------------
with staff as (
  select c.id,
         split_part(lower(trim(c.email)), '@', 1)
           || '@'
           || case split_part(lower(trim(c.email)), '@', 2)
                when 'greentownlabs.com' then 'greentownlabs.org'
                else 'greentownlabs.com'
              end as twin
    from app.contacts c
    join app.parties p on p.id = c.party_id
   where c.deleted_at is null
     and p.deleted_at is null
     and p.party_name ilike 'greentown labs%'
     and split_part(lower(trim(c.email)), '@', 2) in ('greentownlabs.com', 'greentownlabs.org')
)
insert into app.contact_emails (contact_id, email, label, is_primary, source)
select s.id, s.twin, 'alias', false, 'fix_20261011_greentown_dual_domain'
  from staff s
 where not exists (
        select 1 from app.contact_emails ce where lower(ce.email) = s.twin
       )
   and not exists (
        select 1
          from app.contacts o
         where o.deleted_at is null
           and o.id <> s.id
           and (lower(trim(o.email)) = s.twin or lower(trim(o.email_secondary)) = s.twin)
       );


-- ------------------------------------------------------------
-- 4) contacts.email_secondary: the twin, only when empty
-- ------------------------------------------------------------
with staff as (
  select c.id,
         split_part(lower(trim(c.email)), '@', 1)
           || '@'
           || case split_part(lower(trim(c.email)), '@', 2)
                when 'greentownlabs.com' then 'greentownlabs.org'
                else 'greentownlabs.com'
              end as twin
    from app.contacts c
    join app.parties p on p.id = c.party_id
   where c.deleted_at is null
     and p.deleted_at is null
     and p.party_name ilike 'greentown labs%'
     and split_part(lower(trim(c.email)), '@', 2) in ('greentownlabs.com', 'greentownlabs.org')
)
update app.contacts c
   set email_secondary = s.twin,
       updated_at      = now()
  from staff s
 where c.id = s.id
   and coalesce(trim(c.email_secondary), '') = ''
   and not exists (
        select 1
          from app.contacts o
         where o.deleted_at is null
           and o.id <> s.id
           and (lower(trim(o.email)) = s.twin or lower(trim(o.email_secondary)) = s.twin)
       );


-- ------------------------------------------------------------
-- 5a) orphaned Greentown inbound mail -> the staff contact owning the address
-- ------------------------------------------------------------
with addr_map as (
  select distinct on (a.addr) a.addr, a.contact_id, a.party_id
    from (
          select lower(trim(c.email)) as addr, c.id as contact_id, c.party_id, c.updated_at
            from app.contacts c
           where c.deleted_at is null
             and c.email is not null
          union all
          select lower(trim(c.email_secondary)), c.id, c.party_id, c.updated_at
            from app.contacts c
           where c.deleted_at is null
             and c.email_secondary is not null
          union all
          select lower(trim(ce.email)), c.id, c.party_id, c.updated_at
            from app.contact_emails ce
            join app.contacts c on c.id = ce.contact_id
           where c.deleted_at is null
         ) a
   where split_part(a.addr, '@', 2) in ('greentownlabs.com', 'greentownlabs.org')
   order by a.addr, a.updated_at desc
)
update app.communications cm
   set party_id   = m.party_id,
       contact_id = m.contact_id,
       updated_at = now()
  from addr_map m
 where cm.deleted_at is null
   and cm.direction = 'inbound'
   and cm.party_id is null
   and lower(cm.from_address) = m.addr
   and lower(cm.from_address) not in ('will@greentownlabs.org', 'will@greentownlabs.com');


-- ------------------------------------------------------------
-- 5a2) mail that the old domain fallback pinned on a colleague
--      (sender_match = party_email_domain: some other contact on the same
--       domain was picked). Re-point it to the contact that owns the address.
-- ------------------------------------------------------------
with addr_map as (
  select distinct on (a.addr) a.addr, a.contact_id, a.party_id
    from (
          select lower(trim(c.email)) as addr, c.id as contact_id, c.party_id, c.updated_at
            from app.contacts c
           where c.deleted_at is null
             and c.email is not null
          union all
          select lower(trim(c.email_secondary)), c.id, c.party_id, c.updated_at
            from app.contacts c
           where c.deleted_at is null
             and c.email_secondary is not null
          union all
          select lower(trim(ce.email)), c.id, c.party_id, c.updated_at
            from app.contact_emails ce
            join app.contacts c on c.id = ce.contact_id
           where c.deleted_at is null
         ) a
   where split_part(a.addr, '@', 2) in ('greentownlabs.com', 'greentownlabs.org')
   order by a.addr, a.updated_at desc
)
update app.communications cm
   set party_id   = m.party_id,
       contact_id = m.contact_id,
       updated_at = now()
  from addr_map m
 where cm.deleted_at is null
   and cm.direction = 'inbound'
   and lower(cm.from_address) = m.addr
   and cm.contact_id is distinct from m.contact_id
   and cm.external_data -> 'sender_match' ->> 'matched_by' = 'party_email_domain'
   and lower(cm.from_address) not in ('will@greentownlabs.org', 'will@greentownlabs.com');


-- ------------------------------------------------------------
-- 5b) still-orphaned Greentown inbound mail -> Greentown Labs Houston
-- ------------------------------------------------------------
update app.communications cm
   set party_id   = gt.id,
       updated_at = now()
  from (
        select p.id, p.organization_id
          from app.parties p
         where p.party_name = 'Greentown Labs Houston'
           and p.deleted_at is null
         order by p.updated_at desc
         limit 1
       ) gt
 where cm.deleted_at is null
   and cm.direction = 'inbound'
   and cm.party_id is null
   and cm.organization_id = gt.organization_id
   and split_part(lower(cm.from_address), '@', 2) in ('greentownlabs.com', 'greentownlabs.org')
   and lower(cm.from_address) not in ('will@greentownlabs.org', 'will@greentownlabs.com');


-- ------------------------------------------------------------
-- 6) VERIFY - one result set (section, item, detail)
--    expect: whitelist 2 rows active, folders listing both domains,
--    staff rows showing both addresses, chloe mail rows linked
-- ------------------------------------------------------------
select '1 whitelist' as section,
       w.pattern     as item,
       'active=' || w.is_active::text as detail
  from app.email_whitelist w
 where w.kind = 'domain'
   and lower(w.pattern) in ('greentownlabs.com', 'greentownlabs.org')
union all
select '2 folder',
       coalesce(f.label, '(no label)'),
       array_to_string(f.match_domains, ' ')
  from app.mail_folders f
 where f.deleted_at is null
   and f.match_domains && array['greentownlabs.com', 'greentownlabs.org']
union all
select '3 staff',
       coalesce(c.full_name, c.id::text) || ' / ' || p.party_name,
       coalesce(c.email, '-') || ' | sec ' || coalesce(c.email_secondary, '-')
         || ' | all ' || coalesce((
              select string_agg(ce.email || case when ce.is_primary then '*' else '' end, ' ' order by ce.is_primary desc, ce.email)
                from app.contact_emails ce
               where ce.contact_id = c.id
            ), '-')
  from app.contacts c
  join app.parties p on p.id = c.party_id
 where c.deleted_at is null
   and p.deleted_at is null
   and p.party_name ilike 'greentown labs%'
   and split_part(lower(trim(c.email)), '@', 2) in ('greentownlabs.com', 'greentownlabs.org')
union all
select '4 mail ' || split_part(lower(cm.from_address), '@', 2),
       case when cm.party_id is null then 'unlinked' else 'linked' end,
       count(*)::text
  from app.communications cm
 where cm.deleted_at is null
   and cm.direction = 'inbound'
   and split_part(lower(cm.from_address), '@', 2) in ('greentownlabs.com', 'greentownlabs.org')
 group by 1, 2
union all
select '5 chloe',
       to_char(cm.occurred_at, 'YYYY-MM-DD HH24:MI') || ' ' || cm.from_address,
       left(coalesce(cm.subject, ''), 60) || ' | ' || coalesce(p.party_name, 'NO PARTY')
         || ' | ' || coalesce(ct.full_name, 'no contact')
  from app.communications cm
  left join app.parties  p  on p.id  = cm.party_id
  left join app.contacts ct on ct.id = cm.contact_id
 where cm.deleted_at is null
   and lower(cm.from_address) like 'chloe%@greentownlabs.%'
order by 1, 2;
