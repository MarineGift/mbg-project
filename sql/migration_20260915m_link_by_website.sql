-- ===========================================================================
--  migration_20260915m_link_by_website.sql
--  URM - attach unlinked mail to parties using the normalised website domain
-- ---------------------------------------------------------------------------
--  !! SUPABASE SQL EDITOR: press Ctrl+A (SELECT ALL) BEFORE pressing Run. !!
--  STEP 1 and 2 are read-only. STEP 3 writes.
-- ---------------------------------------------------------------------------
--  Requires migration_20260915l_normalize_websites.sql to have run, so that
--  app.parties.website is a bare lower-case domain.
--
--  WHY
--    party_id is decided once, at ingest. Mail that arrived before the party
--    (or before its website) existed stays unlinked forever - which is why
--    activate.org has 12 unlinked messages while an Activate party exists.
--    The earlier backfill only looked at mail-folder pins, so it covered
--    Greentown and nothing else.
--
--  WHAT THIS DOES
--    Matches sender domain to parties.website, exactly and for subdomains
--    (insight.carmeuse.com -> carmeuse.com), and fills party_id where it is
--    null. Existing links are never overwritten.
--
--  WHAT IT REFUSES TO DO
--    - public mailbox providers (naver.com, gmail.com ...) - not evidence of
--      anything
--    - our own domains - those are self-sent or forwarded mail, and stamping
--      them with a counterparty would be wrong
--    - any domain that matches MORE THAN ONE party. Those are the duplicate
--      records from the last report (Oxy, Texas HALO Fund, Clean Energy
--      Ventures ...). Merge them first, then re-run this; guessing a survivor
--      here would scatter one company's history across two records.
--
--  IDEMPOTENT: safe to re-run. Re-run after adding websites or merging parties.
--  (v2: array_agg instead of min(uuid) - 42883 on the first run.)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- STEP 1 - what would be linked, and to whom. Read this first.
-- ---------------------------------------------------------------------------
with own_domains as (
  select unnest(array[
    'marinebiogroup.com','marinepad.kr','marinepad.com'
  ]) as d
),
public_domains as (
  select unnest(array[
    'gmail.com','googlemail.com','yahoo.com','yahoo.co.kr','hotmail.com',
    'outlook.com','live.com','msn.com','icloud.com','me.com','aol.com',
    'proton.me','protonmail.com','naver.com','daum.net','hanmail.net',
    'kakao.com','qq.com','163.com','126.com'
  ]) as d
),
candidates as (
  select c.id                                        as comm_id,
         split_part(lower(c.from_address), '@', 2)    as sender_domain,
         p.id                                         as party_id,
         p.party_name
  from app.communications c
  join app.parties p
    on p.deleted_at is null
   and p.organization_id = c.organization_id
   and coalesce(p.website, '') <> ''
   and (
     split_part(lower(c.from_address), '@', 2) = lower(p.website)
     or split_part(lower(c.from_address), '@', 2) like '%.' || lower(p.website)
   )
  where c.deleted_at is null
    and c.party_id is null
    and split_part(lower(c.from_address), '@', 2) not in (select d from own_domains)
    and split_part(lower(c.from_address), '@', 2) not in (select d from public_domains)
)
select sender_domain,
       count(*)                              as messages,
       count(distinct party_id)              as matching_parties,
       string_agg(distinct party_name, ' | ') as parties,
       case when count(distinct party_id) > 1
            then 'SKIPPED - duplicate parties, merge first'
            else 'will link' end             as verdict
from candidates
group by sender_domain
order by messages desc;

-- ---------------------------------------------------------------------------
-- STEP 2 - how many messages that adds up to
-- ---------------------------------------------------------------------------
select count(*) as unlinked_inbound_now
from app.communications
where deleted_at is null and party_id is null and direction = 'inbound';

-- ---------------------------------------------------------------------------
-- STEP 3 - the link. Only domains that resolve to exactly one party.
-- ---------------------------------------------------------------------------
with own_domains as (
  select unnest(array[
    'marinebiogroup.com','marinepad.kr','marinepad.com'
  ]) as d
),
public_domains as (
  select unnest(array[
    'gmail.com','googlemail.com','yahoo.com','yahoo.co.kr','hotmail.com',
    'outlook.com','live.com','msn.com','icloud.com','me.com','aol.com',
    'proton.me','protonmail.com','naver.com','daum.net','hanmail.net',
    'kakao.com','qq.com','163.com','126.com'
  ]) as d
),
pairs as (
  select c.id as comm_id, p.id as party_id
  from app.communications c
  join app.parties p
    on p.deleted_at is null
   and p.organization_id = c.organization_id
   and coalesce(p.website, '') <> ''
   and (
     split_part(lower(c.from_address), '@', 2) = lower(p.website)
     or split_part(lower(c.from_address), '@', 2) like '%.' || lower(p.website)
   )
  where c.deleted_at is null
    and c.party_id is null
    and split_part(lower(c.from_address), '@', 2) not in (select d from own_domains)
    and split_part(lower(c.from_address), '@', 2) not in (select d from public_domains)
),
unambiguous as (
  -- Postgres has no min(uuid), and there is nothing to choose anyway: HAVING
  -- keeps only the messages that matched exactly one party, so take that one.
  select comm_id, (array_agg(distinct party_id))[1] as party_id
  from pairs
  group by comm_id
  having count(distinct party_id) = 1
)
update app.communications c
   set party_id = u.party_id,
       updated_at = now()
  from unambiguous u
 where c.id = u.comm_id
   and c.party_id is null;

-- ---------------------------------------------------------------------------
-- VERIFY 1 - how many are still unlinked
-- ---------------------------------------------------------------------------
select count(*) as unlinked_inbound_after
from app.communications
where deleted_at is null and party_id is null and direction = 'inbound';

-- ---------------------------------------------------------------------------
-- VERIFY 2 - the biggest remaining unlinked senders. Anything here with real
-- volume needs a party, a website on an existing party, or a contact record.
-- ---------------------------------------------------------------------------
select split_part(lower(from_address), '@', 2) as sender_domain,
       count(*)                                as messages,
       max(occurred_at)                        as latest
from app.communications
where deleted_at is null
  and party_id is null
  and direction = 'inbound'
group by sender_domain
having count(*) >= 3
order by messages desc
limit 40;
