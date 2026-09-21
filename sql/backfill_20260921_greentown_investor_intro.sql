-- ==========================================================================
-- backfill_20260921_greentown_investor_intro.sql
--
--   !!! Ctrl+A (SELECT ALL) then Run !!!
--   (the editor runs only highlighted text when something is selected)
--
-- Purpose
--   Tag inbound mail that came through Greentown Labs investor intros as
--   Investors (external_data.inferred_party_type = investor), and re-link a
--   reply to its investor firm when the warm-intro subject names the firm and
--   exactly one investor party carries that name.
--   Same rules as src/lib/email/investor-intro.ts (new mail is handled at
--   ingest from this deploy on). Rule-based, no AI.
--
-- Rules
--   A  sender is a Greentown intro sender (Will at greentownlabs.org / .com)
--   B  subject is the warm-intro template (Exploring a potential fit ...)
--   C  subject or NEW body text (quoted history cut) mentions Greentown plus
--      an intro or investment word, sender is not Greentown staff
--   B and C skip automated mail (List-Unsubscribe / Precedence header).
--   Only unlinked, mentor or investor messages are touched (rule A always).
--
-- Idempotent: rows already tagged are skipped. No org UUID needed.
-- Whole file = one transaction in the Supabase editor.
-- ==========================================================================

-- 1) tag
with c0 as (
  select c.id,
         lower(coalesce(c.from_address, '')) as sender,
         coalesce(c.subject, '') as subj,
         (regexp_split_to_array(
            coalesce(c.body_plain, ''),
            '\n\s*(On [^\n]{4,200}wrote:|-{2,}\s*(Original|Forwarded) [Mm]essage|_{10,}|[Ff]rom:\s)'
          ))[1] as new_text,
         c.external_data->'raw_selected_headers' as hdr,
         pt.code as linked_type
  from app.communications c
  left join app.parties p on p.id = c.party_id
  left join app.party_types pt on pt.id = p.party_type_id
  where c.direction = 'inbound'
    and c.deleted_at is null
    and coalesce(c.external_data->>'inferred_party_type', '') = ''
),
c1 as (
  select id, subj,
    case
      when sender in ('will@greentownlabs.org', 'will@greentownlabs.com')
        then 'greentown_sender'
      when coalesce(hdr->>'list-unsubscribe', '') <> ''
        or lower(coalesce(hdr->>'precedence', '')) in ('bulk', 'list', 'junk')
        then null
      when subj ~* 'exploring (a )?potential fit wit[h]'
        then 'intro_subject'
      when sender !~* '@([a-z0-9-]+\.)*greentownlabs\.(org|com)$'
        and (subj || ' ' || new_text) ~* 'green\s*town'
        and (subj || ' ' || new_text) ~* '(connect|introduc|intro|deck|pitch|invest|fund|portfolio|venture|capital|seed|diligence|cal[l]|meet)'
        then 'greentown_mention'
      else null
    end as reason,
    linked_type
  from c0
),
hit as (
  select id, reason,
         case when subj ~* 'potential fit wit[h]'
              then nullif(btrim(regexp_replace(
                     regexp_replace(subj, '^.*potential fit wit[h]\s+', '', 'i'),
                     '[\s.!?]+$', '')), '')
         end as firm_hint
  from c1
  where reason is not null
    and (reason = 'greentown_sender'
         or linked_type is null
         or linked_type in ('mentor', 'investor'))
)
update app.communications c
set external_data = coalesce(c.external_data, '{}'::jsonb)
  || jsonb_build_object(
       'inferred_party_type', 'investor',
       'investor_intro', jsonb_build_object(
         'reason', hit.reason,
         'firm_hint', hit.firm_hint,
         'relinked', false,
         'backfilled', true))
from hit
where c.id = hit.id;

-- 2) re-link to the named investor firm (unique name match only)
with cand as (
  select c.id as comm_id, c.party_id as old_party, c.contact_id,
         c.external_data->'investor_intro'->>'firm_hint' as firm,
         c.organization_id
  from app.communications c
  where c.external_data->>'inferred_party_type' = 'investor'
    and coalesce(c.external_data->'investor_intro'->>'firm_hint', '') <> ''
    and coalesce((c.external_data->'investor_intro'->>'relinked')::boolean, false) = false
),
firm as (
  select cand.comm_id, min(p.id::text)::uuid as party_id, count(*) as n
  from cand
  join app.parties p
    on p.organization_id = cand.organization_id
   and lower(btrim(p.party_name)) = lower(cand.firm)
   and p.deleted_at is null
  join app.party_types pt on pt.id = p.party_type_id and pt.code = 'investor'
  group by cand.comm_id
)
update app.communications c
set party_id = firm.party_id,
    contact_id = case
      when c.contact_id is null then null
      when exists (select 1 from app.contacts k
                   where k.id = c.contact_id and k.party_id = firm.party_id)
        then c.contact_id
      else null
    end,
    external_data = jsonb_set(c.external_data, '{investor_intro,relinked}', 'true'::jsonb)
from firm
where c.id = firm.comm_id
  and firm.n = 1
  and c.party_id is distinct from firm.party_id;

-- 3) result (the only grid the editor shows)
select c.occurred_at::date as day,
       c.from_name,
       c.from_address,
       left(c.subject, 90) as subject_text,
       c.external_data->'investor_intro'->>'reason' as reason,
       c.external_data->'investor_intro'->>'firm_hint' as firm_hint,
       c.external_data->'investor_intro'->>'relinked' as relinked,
       p.party_name as linked_party,
       pt.code as linked_type
from app.communications c
left join app.parties p on p.id = c.party_id
left join app.party_types pt on pt.id = p.party_type_id
where c.external_data->>'inferred_party_type' = 'investor'
order by c.occurred_at desc
limit 200;
