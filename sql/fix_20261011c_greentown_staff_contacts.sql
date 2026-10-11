-- ============================================================
-- fix_20261011c_greentown_staff_contacts.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Greentown Labs staff who mailed us but had no URM contact:
--   mteixeira, ivelasco, ajaramillo, gcflatter, abonomi, hzanoni,
--   ewander, cguo  (all @greentownlabs.com)
-- Left alone on purpose:
--   no-reply / hello / connect  - system senders, not people
--   will                        - investor-intro mail, linked to investor firms
--
-- What this does (idempotent)
--   1. one contact per person, on the Greentown party their mail is linked to
--      (Houston or Boston), name taken from the mail display name,
--      email = the .com address, email_secondary = the .org twin
--   2. contact_emails: .com primary + .org alias
--   3. their existing inbound mail gets the new contact
--   4. VERIFY
-- Titles are unknown and left empty - fill in on the contact page.
-- ajaramillo had no display name, so the name is the mailbox name.
-- ============================================================


-- 1) contacts
with src as (
  select lower(cm.from_address) as addr,
         max(cm.from_name) as nm,
         (array_agg(cm.party_id order by cm.occurred_at desc))[1] as party_id,
         (array_agg(cm.organization_id))[1] as org_id
    from app.communications cm
   where cm.deleted_at is null
     and cm.direction = 'inbound'
     and cm.party_id is not null
     and lower(cm.from_address) in (
           'mteixeira@greentownlabs.com', 'ivelasco@greentownlabs.com',
           'ajaramillo@greentownlabs.com', 'gcflatter@greentownlabs.com',
           'abonomi@greentownlabs.com', 'hzanoni@greentownlabs.com',
           'ewander@greentownlabs.com', 'cguo@greentownlabs.com')
   group by 1
), named as (
  select s.addr, s.party_id, s.org_id,
         coalesce(nullif(trim(s.nm), ''), split_part(s.addr, '@', 1)) as full_name,
         nullif(trim(s.nm), '') as nm
    from src s
    join app.parties p on p.id = s.party_id
   where p.deleted_at is null
     and p.party_name ilike 'greentown labs%'
)
insert into app.contacts
  (organization_id, party_id, contact_type_id, full_name, given_name, family_name,
   email, email_secondary, source)
select n.org_id,
       n.party_id,
       1,
       n.full_name,
       case when n.nm is not null then split_part(n.nm, ' ', 1) end,
       case when n.nm is not null
            then nullif(trim(substr(n.nm, length(split_part(n.nm, ' ', 1)) + 2)), '') end,
       n.addr,
       split_part(n.addr, '@', 1) || '@greentownlabs.org',
       'fix_20261011c_greentown_staff_contacts'
  from named n
 where not exists (
        select 1
          from app.contacts c
         where c.deleted_at is null
           and (lower(trim(c.email)) = n.addr or lower(trim(c.email_secondary)) = n.addr)
       );


-- 2a) contact_emails primary
insert into app.contact_emails (contact_id, email, label, is_primary, source)
select c.id, lower(c.email), null, true, 'fix_20261011c_greentown_staff_contacts'
  from app.contacts c
 where c.deleted_at is null
   and c.source = 'fix_20261011c_greentown_staff_contacts'
   and not exists (select 1 from app.contact_emails ce where ce.contact_id = c.id);

-- 2b) contact_emails .org alias
insert into app.contact_emails (contact_id, email, label, is_primary, source)
select c.id, lower(c.email_secondary), 'alias', false, 'fix_20261011c_greentown_staff_contacts'
  from app.contacts c
 where c.deleted_at is null
   and c.source = 'fix_20261011c_greentown_staff_contacts'
   and c.email_secondary is not null
   and not exists (
        select 1 from app.contact_emails ce where lower(ce.email) = lower(c.email_secondary)
       );


-- 3) link their existing mail (same party only)
update app.communications cm
   set contact_id = c.id,
       updated_at = now()
  from app.contacts c
 where c.deleted_at is null
   and c.source = 'fix_20261011c_greentown_staff_contacts'
   and cm.deleted_at is null
   and cm.direction = 'inbound'
   and cm.contact_id is null
   and cm.party_id = c.party_id
   and lower(cm.from_address) in (lower(c.email), lower(c.email_secondary));


-- 4) VERIFY
select '1 new contact' as section,
       c.full_name || ' / ' || p.party_name as item,
       c.email || ' | ' || coalesce(c.email_secondary, '-')
         || ' | mails ' || (select count(*) from app.communications cm
                             where cm.contact_id = c.id and cm.deleted_at is null)::text as detail
  from app.contacts c
  join app.parties p on p.id = c.party_id
 where c.deleted_at is null
   and c.source = 'fix_20261011c_greentown_staff_contacts'
union all
select '2 still no contact',
       lower(cm.from_address),
       count(*)::text
  from app.communications cm
 where cm.deleted_at is null
   and cm.direction = 'inbound'
   and cm.contact_id is null
   and split_part(lower(cm.from_address), '@', 2) in ('greentownlabs.com', 'greentownlabs.org', 'greentown.org')
 group by 2
order by 1, 2;
