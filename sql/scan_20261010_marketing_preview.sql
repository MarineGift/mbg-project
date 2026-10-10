-- ============================================================
-- scan_20261010_marketing_preview.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- READ-ONLY. One statement - export the result as CSV.
-- Paper-mill funnel for a first FCC introduction campaign: how many mills
-- (and distinct addresses) are left after each exclusion, in this order:
--   1 paper mills in URM            2 not archived
--   3 not do_not_contact            4 not tagged 'MBG Pulp Only'
--   5 country not DE / AT / KR      6 has at least one e-mail
--   7 not an active Omya/SMI host   8 no Omya/SMI link at all
-- Then the stage-8 count by country (top destinations).
-- The /marketing page also checks its own do-not-send list and send history,
-- so the real send count can be a little lower than stage 8.
-- ============================================================
with mill as (
  select p.id, p.country_code,
         coalesce(p.status, 'active') = 'archived'                          as is_archived,
         coalesce(p.do_not_contact, false)                                  as is_dnc,
         (jsonb_typeof(coalesce(p.interest_tags, '[]'::jsonb)) = 'array'
          and p.interest_tags ? 'MBG Pulp Only')                            as is_pulp,
         upper(coalesce(p.country_code, '')) in ('DE', 'AT', 'KR')          as is_excl_country
  from app.parties p
  join app.party_types t on t.id = p.party_type_id and t.code = 'paper_mill'
  where p.deleted_at is null
),
mail as (
  select c.party_id, lower(btrim(c.email)) as email
  from app.contacts c
  where c.deleted_at is null and nullif(btrim(c.email), '') is not null
),
lic as (
  select l.mill_party_id,
         bool_or(l.link_type in ('active', 'filler_supply')) as active_host,
         true as any_link
  from app.party_supply_links l
  join app.parties f on f.id = l.filler_party_id and f.deleted_at is null
  where f.party_name ilike '%omya%'
     or f.party_name ilike '%specialty minerals%'
     or f.party_name ilike 'minerals technologies%'
  group by l.mill_party_id
),
flag as (
  select m.*,
         exists (select 1 from mail x where x.party_id = m.id)  as has_email,
         coalesce(lic.active_host, false)                       as is_active_host,
         coalesce(lic.any_link, false)                          as is_any_link
  from mill m
  left join lic on lic.mill_party_id = m.id
),
stage as (
  select f.*,
         not f.is_archived                                         as s2,
         not f.is_archived and not f.is_dnc                        as s3,
         not f.is_archived and not f.is_dnc and not f.is_pulp      as s4,
         not f.is_archived and not f.is_dnc and not f.is_pulp
           and not f.is_excl_country                               as s5
  from flag f
),
s as (
  select st.*,
         st.s5 and st.has_email                                    as s6,
         st.s5 and st.has_email and not st.is_active_host          as s7,
         st.s5 and st.has_email and not st.is_any_link             as s8
  from stage st
)
select 1 as ord, '1 paper mills in URM'           as step, count(*) as mills, null::bigint as addresses from s
union all select 2, '2 not archived',               count(*) filter (where s2), null from s
union all select 3, '3 not do_not_contact',         count(*) filter (where s3), null from s
union all select 4, '4 not Pulp Only',              count(*) filter (where s4), null from s
union all select 5, '5 country not DE / AT / KR',   count(*) filter (where s5), null from s
union all select 6, '6 has e-mail',                 count(*) filter (where s6),
  (select count(distinct x.email) from mail x join s on s.id = x.party_id where s.s6) from s
union all select 7, '7 not active Omya/SMI host',   count(*) filter (where s7),
  (select count(distinct x.email) from mail x join s on s.id = x.party_id where s.s7) from s
union all select 8, '8 no Omya/SMI link at all',    count(*) filter (where s8),
  (select count(distinct x.email) from mail x join s on s.id = x.party_id where s.s8) from s
union all
select 100 + row_number() over (order by count(*) desc, upper(s.country_code))::int,
       '   country ' || coalesce(upper(s.country_code), '??'),
       count(*), null
from s where s.s8
group by upper(s.country_code)
order by 1;
