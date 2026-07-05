-- ============================================================
-- RPC: sync_party_sector_focus -- real-time form-save sync (2026-07-04)
-- Mirrors sync_party_interest_tags but for the SECTOR focus normalized layer:
--   parties.investor_profile -> investor_sector_focus -> sectors.
-- The party form now stores sector focus as a comma-separated list of sector
-- CODES (same shape as interest tags). On save the server action calls this to
-- REPLACE the investor_sector_focus set:
--   - slugs each value; unknown codes are created in app.sectors (sort 900)
--   - investor_sector_focus becomes EXACTLY the saved set (insert + delete)
-- Also keeps the legacy investor_profile.sector_focus text[] in sync (the
-- directory + card still read it) by writing the resolved code array back.
-- Non-investors are a no-op. Idempotent. security definer.
-- ============================================================

create or replace function app.sync_party_sector_focus(p_party_id uuid, p_codes text[])
returns int
language plpgsql
security definer
set search_path = app, public
as $fn$
declare
  v_profile uuid;
  v_org     uuid;
  v_codes   text[];
  v_cnt     int := 0;
begin
  select ip.id, p.organization_id
    into v_profile, v_org
  from app.parties p
  join app.investor_profile ip on ip.party_id = p.id
  where p.id = p_party_id and p.deleted_at is null;

  if v_profile is null then
    return 0;  -- not an investor / deleted
  end if;

  -- normalize incoming values to slugs (drop blanks/dupes)
  select coalesce(array_agg(distinct slug), '{}') into v_codes
  from (
    select regexp_replace(lower(btrim(c)), '[^a-z0-9]+', '_', 'g') as slug
    from unnest(coalesce(p_codes, '{}')) as c
    where btrim(c) <> ''
  ) s
  where s.slug <> '';

  -- unknown sector codes -> catalogue (auto-created zone, curate later)
  insert into app.sectors (code, label_en, sort_order)
  select c, initcap(replace(c,'_',' ')), 900 from unnest(v_codes) as c
  on conflict (code) do nothing;

  -- REPLACE normalized links: delete links no longer in the saved set
  delete from app.investor_sector_focus isf
  using app.sectors s
  where isf.investor_profile_id = v_profile
    and s.id = isf.sector_id
    and s.code <> all (v_codes);

  -- insert missing links
  insert into app.investor_sector_focus (investor_profile_id, sector_id, organization_id)
  select v_profile, s.id, v_org
  from unnest(v_codes) as c
  join app.sectors s on s.code = c
  on conflict do nothing;
  get diagnostics v_cnt = row_count;

  -- keep legacy text[] column in sync (directory/card still read it)
  update app.investor_profile
     set sector_focus = v_codes, updated_at = now()
   where id = v_profile;

  return v_cnt;
end;
$fn$;

revoke all on function app.sync_party_sector_focus(uuid, text[]) from public;
grant execute on function app.sync_party_sector_focus(uuid, text[]) to authenticated;

-- Backfill note: to normalize EXISTING free-text sector_focus values into the
-- catalogue + links in one pass, run this once:
--   select app.sync_party_sector_focus(p.id, ip.sector_focus)
--   from app.parties p join app.investor_profile ip on ip.party_id=p.id
--   where p.deleted_at is null and coalesce(array_length(ip.sector_focus,1),0) > 0;
