-- ===========================================================================
--  migration_20260915k_whitelist_directory.sql
--  URM - stop dropping mail from companies that are already in the directory
-- ---------------------------------------------------------------------------
--  !! SUPABASE SQL EDITOR: press Ctrl+A (SELECT ALL) BEFORE pressing Run. !!
-- ---------------------------------------------------------------------------
--  WHY
--    persistInbound() drops anything that is neither whitelisted nor a reply to
--    one of our threads. A first reply from an investor - BASF Venture Capital
--    answering a Greentown introduction - is neither, so it never reached
--    app.communications and never appeared in URM.
--
--    The whitelist.ts change in the same commit fixes this properly: a sender
--    who is already a contact, a party address, or sits on a party's website
--    domain is accepted without a table entry.
--
--    This script adds explicit rows as well, for two reasons: the entries are
--    visible and auditable in one place, and they work even if the worker is
--    running an older build.
--
--  WHAT THIS DOES
--    Whitelists the website domain of every investor and partner party.
--    Public mailbox providers are excluded - a gmail.com row would open the
--    gate to everything.
--
--  IDEMPOTENT: safe to re-run. Re-run after adding investors in bulk.
--  (v2: de-duplicates cleaned domains and adds ON CONFLICT DO NOTHING - the
--   first version hit 23505 when two parties shared one website.)
-- ===========================================================================

with domains as (
  select p.organization_id,
         lower(
           regexp_replace(
             regexp_replace(coalesce(p.website, ''), '^https?://', '', 'i'),
             '^www\.',
             '',
             'i'
           )
         ) as raw
  from app.parties p
  join app.party_types t on t.id = p.party_type_id
  where p.deleted_at is null
    and coalesce(p.website, '') <> ''
    and t.code in ('investor', 'partner')
),
cleaned as (
  -- DISTINCT must come AFTER the cleanup: 'https://www.x.com/jp/' and 'x.com'
  -- are different raw strings but the same domain, and two parties sharing one
  -- website would otherwise produce two identical rows in a single INSERT,
  -- which NOT EXISTS cannot see (it only sees rows committed before the
  -- statement). That is the 23505 duplicate key on mitsubishicorp.com.
  select distinct
         organization_id,
         split_part(split_part(split_part(raw, '/', 1), '?', 1), ':', 1) as domain
  from domains
)
insert into app.email_whitelist (organization_id, pattern, kind, notes, is_active)
select c.organization_id, c.domain, 'domain',
       'Auto: investor / partner website domain', true
from cleaned c
where c.domain ~ '^[a-z0-9-]+(\.[a-z0-9-]+)+$'
  and c.domain not in (
    'gmail.com','googlemail.com','yahoo.com','hotmail.com','outlook.com',
    'live.com','msn.com','icloud.com','me.com','aol.com','proton.me',
    'protonmail.com','naver.com','daum.net','hanmail.net','kakao.com',
    'qq.com','163.com','126.com','linkedin.com','facebook.com','twitter.com',
    'x.com','crunchbase.com'
  )
  and not exists (
    select 1 from app.email_whitelist w
     where w.organization_id = c.organization_id
       and lower(w.pattern) = c.domain
       and w.kind = 'domain'
  )
-- belt and braces: the unique index is (organization_id, pattern, kind), so a
-- row inserted by someone else between the check and the write is ignored
-- rather than aborting the whole statement.
on conflict (organization_id, pattern, kind) do nothing;

-- ---------------------------------------------------------------------------
-- VERIFY 1 - how many rules exist now, by source
-- ---------------------------------------------------------------------------
select kind,
       count(*) filter (where notes ilike 'Auto:%') as auto_added,
       count(*)                                     as total
from app.email_whitelist
where is_active
group by kind
order by kind;

-- ---------------------------------------------------------------------------
-- VERIFY 2 - is BASF covered now? Expect at least one row.
-- ---------------------------------------------------------------------------
select pattern, kind, notes
from app.email_whitelist
where is_active and pattern ilike '%basf%';

-- ---------------------------------------------------------------------------
-- VERIFY 3 - investor / partner parties with NO website, so nothing could be
-- derived for them. Mail from these still depends on the whitelist.ts
-- contact/party lookup, or on someone adding a contact record.
-- ---------------------------------------------------------------------------
select t.code as party_type, p.party_name, p.email
from app.parties p
join app.party_types t on t.id = p.party_type_id
where p.deleted_at is null
  and t.code in ('investor', 'partner')
  and coalesce(p.website, '') = ''
order by t.code, p.party_name
limit 50;
