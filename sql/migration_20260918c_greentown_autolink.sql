-- ============================================================
-- migration_20260918c_greentown_autolink.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Problem this fixes
--   The "Curated by Greentown Labs" chip and badges read
--   app.v_greentown_parties, which is built from app.party_relationships
--   FROM the "Greentown Labs Houston" party -- NOT from parties.source.
--   Rows created by hand in the UI carry the right source but no
--   relationship, so they stay invisible to that filter until someone
--   inserts the link by hand.
--
-- What this does
--   Adds an AFTER INSERT OR UPDATE OF source trigger on app.parties that
--   creates the missing relationship automatically whenever source starts
--   with "greentown". Relationship type is chosen from the party type:
--     investor -> sources_investor
--     partner  -> has_partner
--     mentor   -> has_mentor
--   Any other party type is left alone.
--
--   Singular and plural party_types codes are both accepted, so this keeps
--   working whichever form the row uses.
--
-- Safety
--   - Guarded by NOT EXISTS: never creates a duplicate link.
--   - SECURITY DEFINER with a pinned search_path, so bulk imports and UI
--     inserts behave the same under RLS.
--   - Never removes a link. If a source is later changed away from
--     greentown, the existing relationship stays and must be deleted by hand.
--
-- Idempotent: safe to run more than once.
-- ============================================================


-- ------------------------------------------------------------
-- 1) the function
-- ------------------------------------------------------------
create or replace function app.fn_link_greentown_party()
returns trigger
language plpgsql
security definer
set search_path = app, public
as $fn$
declare
  v_rel text;
  v_gt  uuid;
begin
  -- only rows that declare a greentown origin
  if new.source is null or new.source not ilike 'greentown%' then
    return new;
  end if;

  -- party type decides the relationship type
  select case
           when pt.code in ('investor', 'investors') then 'sources_investor'
           when pt.code in ('partner', 'partners')   then 'has_partner'
           when pt.code in ('mentor', 'mentors')     then 'has_mentor'
           else null
         end
    into v_rel
  from app.party_types pt
  where pt.id = new.party_type_id;

  if v_rel is null then
    return new;
  end if;

  -- the hub party, scoped to the same organization
  select p.id
    into v_gt
  from app.parties p
  where p.party_name = 'Greentown Labs Houston'
    and p.organization_id = new.organization_id
    and p.deleted_at is null
  limit 1;

  if v_gt is null or v_gt = new.id then
    return new;
  end if;

  insert into app.party_relationships
    (from_party_id, to_party_id, relationship_type, organization_id, source)
  select v_gt, new.id, v_rel, new.organization_id, new.source
  where not exists (
    select 1
    from app.party_relationships r
    where r.to_party_id = new.id
      and r.relationship_type = v_rel
  );

  return new;
end;
$fn$;


-- ------------------------------------------------------------
-- 2) the trigger
-- ------------------------------------------------------------
drop trigger if exists trg_link_greentown_party on app.parties;

create trigger trg_link_greentown_party
  after insert or update of source on app.parties
  for each row
  execute function app.fn_link_greentown_party();


-- ------------------------------------------------------------
-- 3) one-time catch-up for rows that already missed the link
--    (partners and mentors too, not just investors)
-- ------------------------------------------------------------
insert into app.party_relationships
  (from_party_id, to_party_id, relationship_type, organization_id, source)
select gt.id,
       p.id,
       case
         when pt.code in ('investor', 'investors') then 'sources_investor'
         when pt.code in ('partner', 'partners')   then 'has_partner'
         when pt.code in ('mentor', 'mentors')     then 'has_mentor'
       end,
       p.organization_id,
       p.source
from app.parties p
join app.party_types pt on pt.id = p.party_type_id
join app.parties gt
  on gt.party_name = 'Greentown Labs Houston'
 and gt.organization_id = p.organization_id
 and gt.deleted_at is null
where p.deleted_at is null
  and p.source ilike 'greentown%'
  and pt.code in ('investor', 'investors', 'partner', 'partners', 'mentor', 'mentors')
  and gt.id <> p.id
  and not exists (
    select 1
    from app.party_relationships r
    where r.to_party_id = p.id
      and r.relationship_type = case
            when pt.code in ('investor', 'investors') then 'sources_investor'
            when pt.code in ('partner', 'partners')   then 'has_partner'
            when pt.code in ('mentor', 'mentors')     then 'has_mentor'
          end
  );


-- ------------------------------------------------------------
-- 4) Verification
-- ------------------------------------------------------------
select r.relationship_type,
       count(*) as links
from app.party_relationships r
where r.relationship_type in ('sources_investor', 'has_partner', 'has_mentor')
group by r.relationship_type
order by r.relationship_type;
