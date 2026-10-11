-- ============================================================
-- fix_20261011b_greentown_org_domain.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Finding (2026-10-11 probe)
--   Chloe Rose actually writes from chloe@greentown.org - a THIRD domain,
--   not greentownlabs.org. Her 10-09 reply was stored and linked only
--   because it was a reply to our own thread. A fresh mail from that
--   address would still miss her contact.
--
-- What this does (idempotent)
--   1. whitelist: greentown.org as an active domain rule
--   2. Greentown mail folders: add greentown.org next to the other domains
--   3. Chloe alias: the guessed chloe@greentownlabs.org row becomes
--      chloe@greentown.org (or is added when the guess row is absent)
--   4. older inbound Greentown mail that has the party but no contact gets
--      the contact owning the sender address
--   5. VERIFY - one result set
-- ============================================================


-- 1) whitelist
insert into app.email_whitelist (organization_id, pattern, kind, notes, is_active)
select gt.organization_id, 'greentown.org', 'domain', 'Greentown Labs staff domain (third)', true
  from (
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
           and lower(w.pattern) = 'greentown.org'
           and w.kind = 'domain'
       );

update app.email_whitelist w
   set is_active = true
 where w.kind = 'domain'
   and lower(w.pattern) = 'greentown.org'
   and w.is_active = false;


-- 2) mail folders
update app.mail_folders f
   set match_domains = array_append(f.match_domains, 'greentown.org'),
       updated_at    = now()
 where f.deleted_at is null
   and f.match_domains && array['greentownlabs.com', 'greentownlabs.org']
   and not ('greentown.org' = any (f.match_domains));


-- 3a) rename the guessed alias row
update app.contact_emails ce
   set email      = 'chloe@greentown.org',
       updated_at = now()
 where lower(ce.email) = 'chloe@greentownlabs.org'
   and not exists (
        select 1 from app.contact_emails x where lower(x.email) = 'chloe@greentown.org'
       );

-- 3b) add it when there was no guessed row to rename
insert into app.contact_emails (contact_id, email, label, is_primary, source)
select c.id, 'chloe@greentown.org', 'alias', false, 'fix_20261011b_greentown_org_domain'
  from app.contacts c
  join app.parties p on p.id = c.party_id
 where c.deleted_at is null
   and p.party_name = 'Greentown Labs Houston'
   and lower(c.email) = 'crose@greentownlabs.com'
   and not exists (
        select 1 from app.contact_emails x where lower(x.email) = 'chloe@greentown.org'
       );


-- 4) party set, contact missing -> the contact owning the sender address
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
   where split_part(a.addr, '@', 2) in ('greentownlabs.com', 'greentownlabs.org', 'greentown.org')
   order by a.addr, a.updated_at desc
)
update app.communications cm
   set contact_id = m.contact_id,
       updated_at = now()
  from addr_map m
 where cm.deleted_at is null
   and cm.direction = 'inbound'
   and cm.contact_id is null
   and cm.party_id = m.party_id
   and lower(cm.from_address) = m.addr;


-- 5) VERIFY
select '1 whitelist' as section, w.pattern as item, 'active=' || w.is_active::text as detail
  from app.email_whitelist w
 where w.kind = 'domain'
   and lower(w.pattern) in ('greentownlabs.com', 'greentownlabs.org', 'greentown.org')
union all
select '2 folder', coalesce(f.label, '(no label)'), array_to_string(f.match_domains, ' ')
  from app.mail_folders f
 where f.deleted_at is null
   and f.match_domains && array['greentownlabs.com', 'greentownlabs.org', 'greentown.org']
union all
select '3 chloe emails', ce.email, coalesce(ce.label, case when ce.is_primary then 'primary' else '-' end)
  from app.contact_emails ce
  join app.contacts c on c.id = ce.contact_id
 where lower(c.email) = 'crose@greentownlabs.com'
union all
select '4 greentown mail', case when cm.contact_id is null then 'no contact' else 'contact linked' end, count(*)::text
  from app.communications cm
 where cm.deleted_at is null
   and cm.direction = 'inbound'
   and split_part(lower(cm.from_address), '@', 2) in ('greentownlabs.com', 'greentownlabs.org', 'greentown.org')
 group by 2
order by 1, 2;
