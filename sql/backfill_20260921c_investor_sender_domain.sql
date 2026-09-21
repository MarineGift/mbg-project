-- backfill_20260921c_investor_sender_domain.sql
-- !!! Ctrl+A (SELECT ALL) then Run !!!  Single statement, RETURNING shows changed rows.
-- Rule F: sender domain = website/email domain of exactly one investor party -> tag Investors + relink.
-- Touches untagged unlinked/mentor mail and tagged-but-unlinked mail. Idempotent. No org UUID.
with cand as (
  select c.id, c.organization_id,
         split_part(lower(coalesce(c.from_address, '')), '@', 2) as dom,
         coalesce(c.external_data->>'inferred_party_type', '') = 'investor' as tagged
  from app.communications c
  left join app.parties p on p.id = c.party_id
  left join app.party_types pt on pt.id = p.party_type_id
  where c.direction::text = 'inbound'
    and c.deleted_at is null
    and coalesce(c.external_data->'raw_selected_headers'->>'list-unsubscribe', '') = ''
    and lower(coalesce(c.from_address, '')) !~ '^(no[-_.]?reply|do[-_.]?not[-_.]?reply|notifications?|notify|alerts?|newsletters?|news|marketing|updates|digest|mailer-daemon)([-_.+][^@]*)?@'
    and (
      (coalesce(c.external_data->>'inferred_party_type', '') = '' and (pt.code is null or pt.code = 'mentor'))
      or (c.external_data->>'inferred_party_type' = 'investor' and c.party_id is null)
    )
),
inv as (
  select p.id, p.organization_id,
         nullif(regexp_replace(regexp_replace(regexp_replace(lower(btrim(coalesce(p.website, ''))),
           '^[a-z]+://', ''), '^www[0-9]*\.', ''), '[/?#: ].*$', ''), '') as host,
         nullif(split_part(lower(coalesce(p.email, '')), '@', 2), '') as edom
  from app.parties p
  join app.party_types pt on pt.id = p.party_type_id and pt.code = 'investor'
  where p.deleted_at is null
),
m as (
  select cand.id, cand.dom, min(inv.id::text)::uuid as party_id, count(distinct inv.id) as n
  from cand
  join inv on inv.organization_id = cand.organization_id
   and ((inv.host is not null and (cand.dom = inv.host or cand.dom like '%.' || inv.host))
     or (inv.edom is not null and (cand.dom = inv.edom or cand.dom like '%.' || inv.edom)))
  where cand.dom <> ''
    and cand.dom not in ('gmail.com', 'googlemail.com', 'yahoo.com', 'hotmail.com', 'outlook.com',
                         'live.com', 'msn.com', 'aol.com', 'icloud.com', 'me.com', 'proton.me',
                         'protonmail.com', 'naver.com', 'daum.net', 'kakao.com', 'qq.com', '163.com')
  group by cand.id, cand.dom
)
update app.communications c
set party_id = m.party_id,
    contact_id = case when exists (select 1 from app.contacts k
                                   where k.id = c.contact_id and k.party_id = m.party_id)
                      then c.contact_id end,
    external_data = coalesce(c.external_data, '{}'::jsonb)
      || jsonb_build_object('inferred_party_type', 'investor',
           'investor_intro',
             coalesce(c.external_data->'investor_intro', jsonb_build_object('reason', 'sender_domain'))
             || jsonb_build_object('relinked', true, 'backfilled', true, 'matched_domain', m.dom))
from m
where c.id = m.id and m.n = 1
returning c.from_name, c.from_address, left(c.subject, 60) as subj, m.dom,
  (select party_name from app.parties where id = m.party_id) as linked_party;
