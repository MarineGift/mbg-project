-- ==========================================================================
-- backfill_20260927_investor_cev_cooper.sql
--
--   !!! Ctrl+A (SELECT ALL) then Run !!!
--   (the editor runs only highlighted text when something is selected)
--
-- Purpose
--   Cooper Bates (Director, Clean Energy Ventures, cbates@cleanenergyventures.com)
--   mail was not tagged Investors. Cause: the Greentown intro subject
--   "Introduction: Cooper Bates (Clean Energy Ventures) <> Yun-Young Heo
--   (MarineBio Group)" did not parse (firm in parentheses), and his Calendly
--   invites came from a new sender with no MarineBio mention.
--   Same rules as src/lib/email/investor-intro.ts (2026-09-27). No AI.
--
-- Steps
--   1  Cooper Bates contact on the Clean Energy Ventures investor party
--   2  cleanenergyventures.com domain whitelist
--   3  rule D2  intro subject "Person (Firm) <> Person (MarineBio Group)",
--      firm = exactly one investor party -> tag + relink (also Greentown-linked)
--   4  rule G   sender domain label = investor party name
--      (cleanenergyventures = Clean Energy Ventures), personal sender only
--   5  rule E2  sender named in the subject / on To-Cc of earlier investor mail
--   6  verification grid (the only grid the editor shows)
--
-- Idempotent. Whole file = one transaction. No org UUID needed except step 2.
-- ==========================================================================


-- 1) contact -----------------------------------------------------------------
insert into app.contacts
  (organization_id, party_id, contact_type_id,
   full_name, given_name, family_name, email, title_text,
   is_primary, is_active, source, notes)
select p.organization_id,
       p.id,
       coalesce(
         (select ct.id from app.contact_types ct
           where ct.code in ('primary', 'contact', 'general') limit 1),
         (select min(ct.id) from app.contact_types ct)
       ),
       'Cooper Bates', 'Cooper', 'Bates',
       'cbates@cleanenergyventures.com',
       'Director',
       not exists (
         select 1 from app.contacts c2
         where c2.party_id = p.id
           and c2.is_primary
           and c2.deleted_at is null
       ),
       true,
       'greentown_intro_2026',
       $gt$Director at Clean Energy Ventures. Introduced by Greentown Labs (Introduction thread, Sept 2026). Meeting booked via Calendly (Zoom).$gt$
from (
  select p0.id, p0.organization_id
  from app.parties p0
  join app.party_types pt on pt.id = p0.party_type_id and pt.code = 'investor'
  where p0.deleted_at is null
    and lower(btrim(p0.party_name)) in ('clean energy ventures', 'clean energy ventures group')
  order by (lower(btrim(p0.party_name)) = 'clean energy ventures') desc, p0.created_at
  limit 1
) p
where not exists (
  select 1 from app.contacts c
  where c.organization_id = p.organization_id
    and lower(c.email) = 'cbates@cleanenergyventures.com'
    and c.deleted_at is null
);


-- 2) domain whitelist ----------------------------------------------------------
insert into app.email_whitelist (organization_id, pattern, kind, notes, is_active)
select 'b25de8f2-1020-482f-9012-183f63883169', 'cleanenergyventures.com', 'domain',
       'auto: investor contact domain (Clean Energy Ventures)', true
where not exists (
  select 1 from app.email_whitelist w
  where w.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
    and w.kind = 'domain'
    and lower(w.pattern) = 'cleanenergyventures.com'
);


-- 3) rule D2 - firm in parentheses on the other side of our name -------------
with c0 as (
  select c.id, c.organization_id, c.contact_id,
         lower(coalesce(c.subject, '')) as subj,
         lower(coalesce(c.from_address, '')) as sender,
         pt.code as linked_type
  from app.communications c
  left join app.parties p on p.id = c.party_id
  left join app.party_types pt on pt.id = p.party_type_id
  where c.direction = 'inbound'
    and c.deleted_at is null
    and coalesce(c.external_data->'investor_intro'->>'relinked', 'false') <> 'true'
    and coalesce(pt.code, '') <> 'investor'
),
c1 as (
  select id, organization_id, linked_type, sender,
         btrim(coalesce(
           (regexp_match(subj, '\(([^()]+)\)\s*<-?>\s*[^()<>]*\(\s*(?:marine\s*bio[^)]*|mbg)\s*\)'))[1],
           (regexp_match(subj, '\(\s*(?:marine\s*bio[^)]*|mbg)\s*\)\s*<-?>\s*[^()<>]*\(([^()]+)\)'))[1]
         )) as firm
  from c0
),
m as (
  select c1.id, c1.firm, min(p.id::text)::uuid as party_id, count(*) as n
  from c1
  join app.parties p
    on p.organization_id = c1.organization_id
   and lower(btrim(p.party_name)) = c1.firm
   and p.deleted_at is null
  join app.party_types pt on pt.id = p.party_type_id and pt.code = 'investor'
  where coalesce(c1.firm, '') <> ''
    and (c1.linked_type is null
         or c1.linked_type = 'mentor'
         or c1.sender ~ '@([a-z0-9-]+\.)*greentownlabs\.(org|com)$')
  group by c1.id, c1.firm
)
update app.communications c
set party_id = m.party_id,
    contact_id = case
      when exists (select 1 from app.contacts k
                   where k.id = c.contact_id and k.party_id = m.party_id)
        then c.contact_id
      else null
    end,
    external_data = coalesce(c.external_data, '{}'::jsonb)
      || jsonb_build_object(
           'inferred_party_type', 'investor',
           'investor_intro', jsonb_build_object(
             'reason', 'subject_firm',
             'firm_hint', m.firm,
             'relinked', true,
             'backfilled', true))
from m
where c.id = m.id
  and m.n = 1;


-- 4) rule G - sender domain label is the investor name ---------------------
with inv as (
  select p.id, p.organization_id,
         regexp_replace(lower(replace(p.party_name, '&', 'and')), '[^a-z0-9]', '', 'g') as k0
  from app.parties p
  join app.party_types pt on pt.id = p.party_type_id and pt.code = 'investor'
  where p.deleted_at is null
),
inv_k as (
  select id, organization_id, k0,
         regexp_replace(k0, '(inc|llc|llp|lp|ltd|limited|corp|corporation|co|group|gmbh|ag|sa|bv|plc)$', '') as k1
  from inv
),
inv_keys as (
  select id, organization_id, k0 as k from inv_k
  union
  select id, organization_id, k1 from inv_k
  union
  select id, organization_id,
         regexp_replace(k1, '(inc|llc|llp|lp|ltd|limited|corp|corporation|co|group|gmbh|ag|sa|bv|plc)$', '')
  from inv_k
),
c0 as (
  select c.id, c.organization_id, c.contact_id,
         lower(coalesce(c.from_address, '')) as sender
  from app.communications c
  left join app.parties p on p.id = c.party_id
  left join app.party_types pt on pt.id = p.party_type_id
  where c.direction = 'inbound'
    and c.deleted_at is null
    and coalesce(c.external_data->>'inferred_party_type', '') = ''
    and coalesce(c.external_data->'raw_selected_headers'->>'list-unsubscribe', '') = ''
    and lower(coalesce(c.external_data->'raw_selected_headers'->>'precedence', '')) not in ('bulk', 'list', 'junk', 'auto_reply')
    and (pt.code is null or pt.code = 'mentor')
),
c1 as (
  select id, organization_id, sender,
         replace((regexp_match(split_part(sender, '@', 2), '([a-z0-9-]+)\.[a-z]{2,}$'))[1], '-', '') as label
  from c0
  where split_part(sender, '@', 2) !~ '(^|\.)(gmail|googlemail|yahoo|hotmail|outlook|live|msn|aol|icloud|me|proton|protonmail|naver|daum|kakao|qq|163|linkedin|facebook|twitter|x|instagram|youtube|medium|substack|github|crunchbase|google|microsoft|apple|amazon|samsung|mailchimp|hubspot|marinebiogroup|greentownlabs)\.[a-z.]+$'
    and split_part(sender, '@', 1) !~ '(^|[-_.+])(no-?reply|do-?not-?reply|notifications?|notify|alerts?|news(letter)?s?|marketing|promo|mailer|bounces?|digest|updates|info|hello|contact|support|team|admin|billing|security|account|invitations?|jobs|editors|messages|messaging|groups|events?|community|membership|sales|press|careers|office)([-_.+]|$)'
),
m as (
  select c1.id, min(k.id::text)::uuid as party_id, count(distinct k.id) as n
  from c1
  join inv_keys k
    on k.organization_id = c1.organization_id
   and k.k = c1.label
  where length(c1.label) >= 6
  group by c1.id
)
update app.communications c
set party_id = m.party_id,
    contact_id = coalesce(
      (select k.id from app.contacts k
        where k.party_id = m.party_id
          and lower(k.email) = lower(c.from_address)
          and k.deleted_at is null
        limit 1),
      case when exists (select 1 from app.contacts k
                        where k.id = c.contact_id and k.party_id = m.party_id)
           then c.contact_id end),
    external_data = coalesce(c.external_data, '{}'::jsonb)
      || jsonb_build_object(
           'inferred_party_type', 'investor',
           'investor_intro', jsonb_build_object(
             'reason', 'name_domain',
             'firm_hint', null,
             'relinked', true,
             'backfilled', true))
from m
where c.id = m.id
  and m.n = 1;


-- 5) rule E2 - sender named / copied on an earlier investor intro -------------
with known as (
  select c.organization_id, c.party_id, c.occurred_at,
         lower(coalesce(c.subject, '')) as subj,
         (select array_agg(lower(a)) from unnest(coalesce(c.to_addresses, '{}') || coalesce(c.cc_addresses, '{}')) a) as addrs,
         pt.code as party_code
  from app.communications c
  left join app.parties p on p.id = c.party_id
  left join app.party_types pt on pt.id = p.party_type_id
  where c.deleted_at is null
    and c.external_data->>'inferred_party_type' = 'investor'
),
c0 as (
  select c.id, c.organization_id, c.contact_id,
         lower(coalesce(c.from_address, '')) as sender,
         lower(btrim(regexp_replace(coalesce(c.from_name, ''), '["'']', '', 'g'))) as person
  from app.communications c
  left join app.parties p on p.id = c.party_id
  left join app.party_types pt on pt.id = p.party_type_id
  where c.direction = 'inbound'
    and c.deleted_at is null
    and coalesce(c.external_data->>'inferred_party_type', '') = ''
    and coalesce(c.external_data->'raw_selected_headers'->>'list-unsubscribe', '') = ''
    and (pt.code is null or pt.code = 'mentor')
    and lower(coalesce(c.from_address, '')) !~ '@([a-z0-9-]+\.)*(marinebiogroup\.com|greentownlabs\.(org|com))$'
),
hit as (
  select distinct on (c0.id)
         c0.id, known.party_id, known.party_code
  from c0
  join known
    on known.organization_id = c0.organization_id
   and (
         c0.sender = any(known.addrs)
      or (c0.person ~ '^[a-z][a-z.-]+( [a-z][a-z.-]+){1,3}$'
          and c0.person !~ '\m(heo|yun ?young)\M'
          and position(c0.person in known.subj) > 0)
   )
  order by c0.id, (known.party_code = 'investor') desc, known.occurred_at desc
)
update app.communications c
set party_id = case when hit.party_code = 'investor' then hit.party_id else c.party_id end,
    contact_id = case
      when hit.party_code <> 'investor' or hit.party_code is null then c.contact_id
      else coalesce(
        (select k.id from app.contacts k
          where k.party_id = hit.party_id
            and lower(k.email) = lower(c.from_address)
            and k.deleted_at is null
          limit 1),
        case when exists (select 1 from app.contacts k
                          where k.id = c.contact_id and k.party_id = hit.party_id)
             then c.contact_id end)
    end,
    external_data = coalesce(c.external_data, '{}'::jsonb)
      || jsonb_build_object(
           'inferred_party_type', 'investor',
           'investor_intro', jsonb_build_object(
             'reason', 'intro_participant',
             'firm_hint', null,
             'relinked', coalesce(hit.party_code = 'investor', false),
             'backfilled', true))
from hit
where c.id = hit.id;


-- 6) verification ---------------------------------------------------------------
select 'contact' as kind,
       null::date as day,
       c.full_name as who,
       c.email as addr,
       c.title_text as subject_text,
       null as reason,
       p.party_name as linked_party,
       pt.code as linked_type
from app.contacts c
join app.parties p on p.id = c.party_id
left join app.party_types pt on pt.id = p.party_type_id
where c.deleted_at is null
  and lower(c.email) = 'cbates@cleanenergyventures.com'
union all
select 'mail',
       c.occurred_at::date,
       c.from_name,
       c.from_address,
       left(c.subject, 90),
       c.external_data->'investor_intro'->>'reason',
       p.party_name,
       coalesce(c.external_data->>'inferred_party_type', pt.code)
from app.communications c
left join app.parties p on p.id = c.party_id
left join app.party_types pt on pt.id = p.party_type_id
where c.deleted_at is null
  and c.external_data->'investor_intro'->>'reason' in ('subject_firm', 'name_domain', 'intro_participant')
  and coalesce((c.external_data->'investor_intro'->>'backfilled')::boolean, false)
order by 1, 2 desc nulls first;
