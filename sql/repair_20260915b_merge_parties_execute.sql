-- ===========================================================================
--  repair_20260915b_merge_parties_execute.sql
--  URM - actually perform the duplicate party merges
-- ---------------------------------------------------------------------------
--  !! SUPABASE SQL EDITOR: press Ctrl+A (SELECT ALL) BEFORE pressing Run. !!
-- ---------------------------------------------------------------------------
--  This is the executing half of repair_20260915_merge_duplicate_parties.sql,
--  which only generated statements. The evidence report showed all eight pairs
--  carry almost nothing - Clean Energy Ventures has 4 messages on the survivor
--  and every other record is 0 messages / 0 contacts - so running them in one
--  pass is safe. The survivor is still chosen by evidence, not by luck.
--
--  WHAT IT DOES, per duplicate name:
--    1. ranks the records: most mail, then contacts, then meetings, then the
--       oldest record wins
--    2. repoints every app table with a party_id column at the survivor -
--       discovered from information_schema, so a table added later is included
--       automatically
--    3. soft-deletes the loser
--
--  Names are compared with punctuation, spacing and case removed, which is how
--  'Texas Halo Fund' and 'Texas HALO Fund' come together.
--
--  (v2: handles the UNIQUE(party_id) on the 1:1 profile tables - 23505 on
--   the first run.)
--
--  IDEMPOTENT: once merged, the losers are deleted_at and no longer ranked, so
--  a second run finds nothing to do.
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- STEP 1 - the merge
-- ---------------------------------------------------------------------------
do $do$
declare
  pair   record;
  tbl    record;
  moved  integer := 0;
  merged integer := 0;
begin
  for pair in
    with ranked as (
      select p.id,
             p.party_name,
             lower(regexp_replace(p.party_name, '[^a-zA-Z0-9]', '', 'g')) as key,
             row_number() over (
               partition by lower(regexp_replace(p.party_name, '[^a-zA-Z0-9]', '', 'g'))
               order by
                 (select count(*) from app.communications c
                   where c.party_id = p.id and c.deleted_at is null) desc,
                 (select count(*) from app.contacts ct
                   where ct.party_id = p.id and ct.deleted_at is null) desc,
                 (select count(*) from app.meetings m
                   where m.party_id = p.id and m.deleted_at is null) desc,
                 p.created_at
             ) as rn
      from app.parties p
      where p.deleted_at is null
    )
    select d.id as drop_id, k.id as keep_id, d.party_name
    from ranked d
    join ranked k on k.key = d.key and k.rn = 1
    where d.rn > 1
  loop
    for tbl in
      select c.table_name
      from information_schema.columns c
      join information_schema.tables t
        on t.table_schema = c.table_schema
       and t.table_name = c.table_name
       and t.table_type = 'BASE TABLE'
      where c.table_schema = 'app'
        and c.column_name = 'party_id'
        and c.table_name <> 'parties'
    loop
      -- 1:1 profile tables (investor_profile, paper_mill_profile, lead_scores,
      -- party_profiles ...) carry a UNIQUE on party_id. When BOTH records have
      -- a row, repointing hits 23505. The loser's row is the one to discard:
      -- the survivor was chosen because it holds the history, and the loser's
      -- profile is a stub created by whatever import made the duplicate.
      begin
        execute format(
          'update app.%I set party_id = $1 where party_id = $2',
          tbl.table_name
        ) using pair.keep_id, pair.drop_id;
        get diagnostics moved = row_count;
        if moved > 0 then
          raise notice 'moved % row(s) in app.% for %', moved, tbl.table_name, pair.party_name;
        end if;
      exception when unique_violation then
        execute format(
          'delete from app.%I where party_id = $1',
          tbl.table_name
        ) using pair.drop_id;
        get diagnostics moved = row_count;
        raise notice 'app.% already had a row for the survivor - dropped % duplicate row(s) from %',
          tbl.table_name, moved, pair.party_name;
      end;
    end loop;

    update app.parties
       set deleted_at = now(),
           updated_at = now()
     where id = pair.drop_id;

    merged := merged + 1;
    raise notice 'merged % : % retired into %', pair.party_name, pair.drop_id, pair.keep_id;
  end loop;

  raise notice 'pairs merged: %', merged;
end
$do$;

-- ---------------------------------------------------------------------------
-- VERIFY 1 - no duplicate names left
-- ---------------------------------------------------------------------------
select lower(regexp_replace(party_name, '[^a-zA-Z0-9]', '', 'g')) as key,
       count(*) as records,
       string_agg(party_name, ' | ') as names
from app.parties
where deleted_at is null
group by key
having count(*) > 1
order by records desc;

-- ---------------------------------------------------------------------------
-- VERIFY 2 - no duplicate website domains left either
-- ---------------------------------------------------------------------------
select lower(website) as domain,
       count(*) as parties,
       string_agg(party_name, ' | ') as names
from app.parties
where deleted_at is null
  and coalesce(website, '') <> ''
group by domain
having count(*) > 1
order by parties desc;

-- ---------------------------------------------------------------------------
-- STEP 2 - the two pairs whose halves had DIFFERENT domains. Neither had any
-- mail, so the ranking picked by age, not by evidence. Check what survived and
-- set the domain their mail will actually come from.
-- ---------------------------------------------------------------------------
select id, party_name, website
from app.parties
where deleted_at is null
  and (party_name ilike '%goose%' or party_name ilike '%LMNT%')
order by party_name;

-- To change one, uncomment and fill in:
-- update app.parties set website = 'goosecapital.com', updated_at = now()
--  where id = 'PASTE-ID' ;

-- ---------------------------------------------------------------------------
-- STEP 3 - now re-run sql/migration_20260915m_link_by_website.sql. The domains
-- it skipped as ambiguous - activate.org with its 12 messages and the rest -
-- resolve to a single party now and will link on this pass.
-- ---------------------------------------------------------------------------
