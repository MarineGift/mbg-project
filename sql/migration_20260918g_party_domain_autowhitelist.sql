-- ============================================================
-- migration_20260918g_party_domain_autowhitelist.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Problem
--   createParty and updateParty already auto-register a party's website
--   domain in app.email_whitelist (added 2026-06-12). That hook lives in
--   the server action, so any row written another way -- a SQL import, a
--   bulk enrichment, a direct UPDATE -- skips it silently.
--
--   The 2026-09-16 to -18 enrichment set websites via SQL, so 19 of the 27
--   domains never reached the whitelist. Inbound mail from those investors
--   would not be accepted.
--
-- What this does
--   1. Adds a trigger on app.parties that keeps the whitelist in sync on
--      INSERT and on any change to website or domain_normalized, whatever
--      wrote the row. The application hook still works; this catches
--      everything else. Duplicates are impossible thanks to the NOT EXISTS
--      guard, so the two paths cannot fight.
--   2. Applies the same skip list the app uses (free mail and social
--      domains), so a party whose "website" is a LinkedIn page never
--      whitelists linkedin.com.
--   3. Backfills every party domain that is currently missing.
--
-- IMPORTANT, and not fixed by this file
--   A whitelist entry only decides whether inbound mail is ACCEPTED. The
--   party a message is attached to is resolved from app.contacts -- exact
--   address first, then contacts.email LIKE '%@domain'. parties.website is
--   never consulted for that. So a party with a whitelisted domain but no
--   contact row still produces communications with party_id NULL, which
--   never appear on the party's Communications tab. Section 4 lists the
--   parties in that state.
--
-- Idempotent.
-- ============================================================


-- ------------------------------------------------------------
-- 1) domain extraction, mirroring the app's WHITELIST_SKIP_DOMAINS
-- ------------------------------------------------------------
create or replace function app.fn_whitelistable_domain(p_website text)
returns text
language plpgsql
immutable
as $fn$
declare
  v text;
begin
  if p_website is null or btrim(p_website) = '' then
    return null;
  end if;

  v := lower(btrim(p_website));
  v := regexp_replace(v, '^[a-z]+://', '');   -- strip scheme
  v := split_part(v, '/', 1);                  -- strip path
  v := split_part(v, '?', 1);
  if position('@' in v) > 0 then
    v := split_part(v, '@', 2);                -- strip any userinfo
  end if;
  v := split_part(v, ':', 1);                  -- strip port
  if v like 'www.%' then
    v := substring(v from 5);
  end if;

  if v is null or position('.' in v) = 0 then
    return null;
  end if;

  if v in (
    'gmail.com', 'naver.com', 'daum.net', 'kakao.com', 'yahoo.com',
    'hotmail.com', 'outlook.com', 'icloud.com', 'qq.com', '163.com',
    'linkedin.com', 'facebook.com', 'twitter.com', 'x.com', 'instagram.com',
    'youtube.com', 'crunchbase.com', 'pitchbook.com', 'wikipedia.org',
    'medium.com', 'github.com', 'angel.co', 'notion.site'
  ) then
    return null;
  end if;

  return v;
end;
$fn$;


-- ------------------------------------------------------------
-- 2) the trigger function
-- ------------------------------------------------------------
create or replace function app.fn_party_domain_autowhitelist()
returns trigger
language plpgsql
security definer
set search_path = app, public
as $fn$
declare
  v_domain text;
begin
  v_domain := app.fn_whitelistable_domain(
                coalesce(new.domain_normalized, new.website));

  if v_domain is null then
    return new;
  end if;

  insert into app.email_whitelist (organization_id, pattern, kind, notes, is_active)
  select new.organization_id,
         v_domain,
         'domain',
         'auto: party domain (' || new.party_name || ')',
         true
  where not exists (
    select 1
    from app.email_whitelist w
    where w.organization_id = new.organization_id
      and w.kind = 'domain'
      and lower(w.pattern) = v_domain
  );

  return new;
end;
$fn$;

drop trigger if exists trg_party_domain_autowhitelist on app.parties;

create trigger trg_party_domain_autowhitelist
  after insert or update of website, domain_normalized on app.parties
  for each row
  execute function app.fn_party_domain_autowhitelist();


-- ------------------------------------------------------------
-- 3) backfill every missing party domain
-- ------------------------------------------------------------
insert into app.email_whitelist (organization_id, pattern, kind, notes, is_active)
select distinct on (p.organization_id, d.domain)
       p.organization_id,
       d.domain,
       'domain',
       'auto: party domain backfill (' || p.party_name || ')',
       true
from app.parties p
cross join lateral (
  select app.fn_whitelistable_domain(
           coalesce(p.domain_normalized, p.website)) as domain
) d
where p.deleted_at is null
  and d.domain is not null
  and not exists (
    select 1
    from app.email_whitelist w
    where w.organization_id = p.organization_id
      and w.kind = 'domain'
      and lower(w.pattern) = d.domain
  )
order by p.organization_id, d.domain, p.party_name;


-- ------------------------------------------------------------
-- 4) Verification
-- ------------------------------------------------------------

-- 4a) any party domain still missing from the whitelist (expect 0 rows)
select p.party_name, p.domain_normalized
from app.parties p
where p.deleted_at is null
  and app.fn_whitelistable_domain(coalesce(p.domain_normalized, p.website)) is not null
  and not exists (
    select 1 from app.email_whitelist w
    where w.organization_id = p.organization_id
      and w.kind = 'domain'
      and lower(w.pattern) = app.fn_whitelistable_domain(
                               coalesce(p.domain_normalized, p.website))
  )
order by p.party_name;

-- 4b) whitelist size by kind
select kind, count(*) filter (where is_active) as active, count(*) as total
from app.email_whitelist
group by kind
order by kind;

-- 4c) THE REMAINING GAP: greentown parties with a whitelisted domain but
--     no contact row. Inbound mail from these will be accepted but will
--     land with party_id NULL until a contact exists.
select p.party_name,
       p.domain_normalized,
       (select count(*) from app.contacts c
         where c.party_id = p.id and c.deleted_at is null) as contacts
from app.parties p
where p.deleted_at is null
  and p.source ilike 'greentown%'
  and p.created_at >= date '2026-09-16'
order by contacts, p.party_name;
