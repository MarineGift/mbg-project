-- ============================================================
-- scan_20261010_pulp_only_mills.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- READ-ONLY. One statement - export the result as CSV.
-- Candidate market-pulp-only producers sitting in the paper_mill directory.
-- A pure pulp mill makes no paper, uses no filler, and is a weak FCC target.
-- A row is listed when either signal fires:
--   name_signal      party name contains pulp / celulose / celulosa / fibre / fiber
--   profile_signal   paper_mill_profile category or products mention pulp
-- Extra column (not a filter):
--   no_paper_type    the mill has no paper-type tag in v_paper_mill_types -
--                    the strongest hint that it is pulp only
-- paper_types shows the tags it does have, so a mill that is pulp AND paper
-- (an integrated mill, still a target) can be told apart by eye.
-- Archived and deleted rows are left out. Nothing is changed.
-- ============================================================
with mill as (
  select p.id, p.party_name, p.country_code, p.city, p.website
  from app.parties p
  join app.party_types t on t.id = p.party_type_id and t.code = 'paper_mill'
  where p.deleted_at is null
    and coalesce(p.status, 'active') <> 'archived'
),
types as (
  select v.mill_id, string_agg(distinct v.type_code, ' | ') as paper_types
  from app.v_paper_mill_types v
  group by v.mill_id
),
prof as (
  select pr.party_id,
         concat_ws(' / ', pr.main_product_category, pr.main_products) as profile_text
  from app.paper_mill_profile pr
  where pr.deleted_at is null
)
select m.party_name,
       m.country_code,
       m.city,
       m.website,
       (m.party_name ~* '(pulp|celulose|celulosa|cellulose|fibre|fiber)') as name_signal,
       (coalesce(prof.profile_text, '') ~* 'pulp') as profile_signal,
       (types.mill_id is null) as no_paper_type,
       types.paper_types,
       left(prof.profile_text, 200) as profile_text,
       m.id as party_id
from mill m
left join types on types.mill_id = m.id
left join prof  on prof.party_id = m.id
where m.party_name ~* '(pulp|celulose|celulosa|cellulose|fibre|fiber)'
   or coalesce(prof.profile_text, '') ~* 'pulp'
order by (types.mill_id is null) desc, m.country_code, m.party_name;
