-- ============================================================
-- fix_20260918h_relink_orphan_communications.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Problem
--   Party matching runs once, when a message is ingested. A contact
--   created later never re-attaches the messages that arrived before it.
--   Chemical Angels is the clear case: DC Palter's contact was created on
--   the evening of 2026-09-18, his three messages arrived that morning,
--   and they are still party_id NULL.
--
--   Ingest-time matching also consults contacts only -- exact address,
--   then contacts.email LIKE '%@domain'. parties.website and
--   parties.domain_normalized are never used, so a party with a known
--   domain but no contact row can never be matched.
--
-- What this does, in widening order, never overwriting an existing link
--   1. inbound: sender address matches a contact exactly
--   2. outbound: a recipient address matches a contact exactly
--   3. inbound: sender domain matches a contact's email domain
--   4. inbound: sender domain matches parties.domain_normalized
--      -- the rule the ingest path is missing; only applied where exactly
--      one live party owns that domain, so shared domains such as
--      omya.com are left alone
--   Free-mail domains are excluded from every domain-based rule; only the
--   exact-address rules can attach a gmail sender.
--
-- contact_id is filled alongside party_id wherever the match came from a
-- contact, so the party's contact timeline is correct too.
--
-- Section 0 is a dry run. Read it first: it shows what each rule would
-- attach, before anything is written.
--
-- Idempotent -- only rows with party_id IS NULL are touched.
-- ============================================================


-- ------------------------------------------------------------
-- 0) DRY RUN -- orphaned messages and the best available match
-- ------------------------------------------------------------
with orphan as (
  select c.id, c.direction, c.from_address, c.to_addresses, c.subject, c.occurred_at
  from app.communications c
  where c.deleted_at is null
    and c.party_id is null
),
resolved as (
  select o.id, o.subject, o.occurred_at, o.direction, o.from_address,
         coalesce(
           (select p.party_name from app.contacts ct
              join app.parties p on p.id = ct.party_id
             where ct.deleted_at is null
               and lower(ct.email) = lower(o.from_address)
             limit 1),
           (select p.party_name from app.contacts ct
              join app.parties p on p.id = ct.party_id
             where ct.deleted_at is null
               and o.direction = 'outbound'
               and exists (select 1 from unnest(o.to_addresses) a
                            where lower(a) = lower(ct.email))
             limit 1),
           (select p.party_name from app.contacts ct
              join app.parties p on p.id = ct.party_id
             where ct.deleted_at is null
               and split_part(lower(o.from_address), '@', 2) not in (
                     'gmail.com','yahoo.com','hotmail.com','outlook.com',
                     'icloud.com','naver.com','daum.net','kakao.com',
                     'qq.com','163.com')
               and lower(ct.email) like '%@' || split_part(lower(o.from_address), '@', 2)
             limit 1),
           (select p.party_name from app.parties p
             where p.deleted_at is null
               and p.domain_normalized is not null
               and lower(p.domain_normalized) = split_part(lower(o.from_address), '@', 2)
               and split_part(lower(o.from_address), '@', 2) not in (
                     'gmail.com','yahoo.com','hotmail.com','outlook.com',
                     'icloud.com','naver.com','daum.net','kakao.com',
                     'qq.com','163.com')
             limit 1)
         ) as would_attach_to
  from orphan o
)
select coalesce(would_attach_to, '(no match)') as party,
       count(*) as messages,
       min(occurred_at) as earliest,
       max(occurred_at) as latest
from resolved
group by coalesce(would_attach_to, '(no match)')
order by messages desc;


-- ------------------------------------------------------------
-- 1) inbound: sender address matches a contact exactly
-- ------------------------------------------------------------
update app.communications c
set party_id   = ct.party_id,
    contact_id = coalesce(c.contact_id, ct.id)
from app.contacts ct
where c.deleted_at is null
  and c.party_id is null
  and ct.deleted_at is null
  and c.from_address is not null
  and lower(c.from_address) = lower(ct.email);


-- ------------------------------------------------------------
-- 2) outbound: a recipient address matches a contact exactly
-- ------------------------------------------------------------
update app.communications c
set party_id   = ct.party_id,
    contact_id = coalesce(c.contact_id, ct.id)
from app.contacts ct
where c.deleted_at is null
  and c.party_id is null
  and c.direction = 'outbound'
  and ct.deleted_at is null
  and ct.email is not null
  and exists (
    select 1 from unnest(c.to_addresses) a
    where lower(a) = lower(ct.email)
  );


-- ------------------------------------------------------------
-- 3) inbound: sender domain matches a contact's email domain
-- ------------------------------------------------------------
update app.communications c
set party_id   = ct.party_id,
    contact_id = coalesce(c.contact_id, ct.id)
from app.contacts ct
where c.deleted_at is null
  and c.party_id is null
  and c.from_address is not null
  and ct.deleted_at is null
  and ct.email is not null
  and split_part(lower(c.from_address), '@', 2) not in (
        'gmail.com','yahoo.com','hotmail.com','outlook.com',
        'icloud.com','naver.com','daum.net','kakao.com','qq.com','163.com')
  and lower(ct.email) like '%@' || split_part(lower(c.from_address), '@', 2);


-- ------------------------------------------------------------
-- 4) inbound: sender domain matches parties.domain_normalized
--    Only where exactly one live party owns the domain.
-- ------------------------------------------------------------
update app.communications c
set party_id = p.id
from app.parties p
where c.deleted_at is null
  and c.party_id is null
  and c.from_address is not null
  and p.deleted_at is null
  and p.domain_normalized is not null
  and lower(p.domain_normalized) = split_part(lower(c.from_address), '@', 2)
  and split_part(lower(c.from_address), '@', 2) not in (
        'gmail.com','yahoo.com','hotmail.com','outlook.com',
        'icloud.com','naver.com','daum.net','kakao.com','qq.com','163.com')
  and (select count(*) from app.parties q
        where q.deleted_at is null
          and lower(q.domain_normalized) = lower(p.domain_normalized)) = 1;


-- ------------------------------------------------------------
-- 5) Verification -- what is still orphaned, by sender domain
-- ------------------------------------------------------------
select split_part(lower(c.from_address), '@', 2) as sender_domain,
       count(*) as messages,
       max(c.occurred_at) as latest
from app.communications c
where c.deleted_at is null
  and c.party_id is null
  and c.from_address is not null
group by split_part(lower(c.from_address), '@', 2)
order by messages desc
limit 30;


-- ------------------------------------------------------------
-- 6) Verification -- the Seed deals' threads
-- ------------------------------------------------------------
select p.party_name,
       count(*) filter (where c.direction = 'inbound')  as inbound,
       count(*) filter (where c.direction = 'outbound') as outbound
from app.communications c
join app.parties p on p.id = c.party_id
where c.deleted_at is null
  and c.occurred_at >= date '2026-09-18'
group by p.party_name
order by inbound desc, p.party_name;
