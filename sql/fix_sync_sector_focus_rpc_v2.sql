-- ============================================================
-- RPC v2: sync_party_sector_focus -- fix 23502 (sectors.id null) (2026-07-04)
-- app.sectors.id has no auto-default (unlike interest_tags), so the auto-create
-- INSERT failed with a null id. v2 assigns id explicitly as max(id)+row_number
-- when creating unknown sectors. Everything else identical. Idempotent.
-- Replaces the earlier fix_sync_sector_focus_rpc.sql (create-or-replace).
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
  v_maxid   bigint;
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

  -- unknown sector codes -> catalogue, assigning id explicitly (max+row_number)
  select coalesce(max(id), 0) into v_maxid from app.sectors;
  insert into app.sectors (id, code, label_en, sort_order)
  select v_maxid + row_number() over (order by c),
         c, initcap(replace(c,'_',' ')), 900
  from (
    select distinct c
    from unnest(v_codes) as c
    where not exists (select 1 from app.sectors s where s.code = c)
  ) missing
  on conflict (code) do nothing;

  -- REPLACE normalized links
  delete from app.investor_sector_focus isf
  using app.sectors s
  where isf.investor_profile_id = v_profile
    and s.id = isf.sector_id
    and s.code <> all (v_codes);

  insert into app.investor_sector_focus (investor_profile_id, sector_id, organization_id)
  select v_profile, s.id, v_org
  from unnest(v_codes) as c
  join app.sectors s on s.code = c
  on conflict do nothing;
  get diagnostics v_cnt = row_count;

  -- keep legacy text[] column in sync
  update app.investor_profile
     set sector_focus = v_codes, updated_at = now()
   where id = v_profile;

  return v_cnt;
end;
$fn$;

revoke all on function app.sync_party_sector_focus(uuid, text[]) from public;
grant execute on function app.sync_party_sector_focus(uuid, text[]) to authenticated;
