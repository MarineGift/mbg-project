-- ============================================================
-- RPC: sync_party_interest_tags -- real-time form-save sync (2026-07-04)
-- Called by createParty/updateParty server actions right after a successful
-- write. Mirrors the party's legacy interest_tags jsonb into the normalized
-- layer with REPLACE semantics:
--   - slugs each value, resolves via interest_tag_aliases to canonical codes
--   - creates unknown codes in the catalogue (sort_order 900, curate later)
--   - investor_interest_tags becomes EXACTLY the saved set (insert missing,
--     delete removed) -- safe because the edit form now LOADS the normalized
--     set first (party-detail patch), so the round-trip preserves research
--     tags unless the user deliberately removes a chip.
-- Non-investors (no investor_profile) are a no-op. Idempotent.
-- ============================================================

create or replace function app.sync_party_interest_tags(p_party_id uuid)
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
    return 0;  -- not an investor / deleted: nothing to sync
  end if;

  -- legacy jsonb -> canonical code array (alias-aware; array-guarded)
  select coalesce(array_agg(distinct code), '{}') into v_codes
  from (
    select coalesce(a.canonical_code, s.slug) as code
    from (
      select regexp_replace(lower(btrim(t)), '[^a-z0-9]+', '_', 'g') as slug
      from app.parties p
      cross join lateral jsonb_array_elements_text(
        case when jsonb_typeof(coalesce(p.interest_tags, '[]'::jsonb)) = 'array'
             then p.interest_tags else '[]'::jsonb end
      ) as t
      where p.id = p_party_id and btrim(t) <> ''
    ) s
    left join app.interest_tag_aliases a on a.alias = s.slug
    where s.slug <> ''
  ) r;

  -- unknown codes -> catalogue (auto-created zone, curate via aliases later)
  insert into app.interest_tags (code, label_en, label_ko, sort_order)
  select c, c, c, 900 from unnest(v_codes) as c
  on conflict (code) do nothing;

  -- REPLACE: drop links no longer present in the saved set
  delete from app.investor_interest_tags iit
  using app.interest_tags it
  where iit.investor_profile_id = v_profile
    and it.id = iit.interest_tag_id
    and it.code <> all (v_codes);

  -- insert missing links
  insert into app.investor_interest_tags (investor_profile_id, interest_tag_id, organization_id)
  select v_profile, it.id, v_org
  from unnest(v_codes) as c
  join app.interest_tags it on it.code = c
  on conflict do nothing;
  get diagnostics v_cnt = row_count;

  return v_cnt;
end;
$fn$;

revoke all on function app.sync_party_interest_tags(uuid) from public;
grant execute on function app.sync_party_interest_tags(uuid) to authenticated;

-- smoke test (replace with a real party id):
-- select app.sync_party_interest_tags('<party-uuid>');
