-- ============================================================
-- Copy investor Introduction -> Notes (where Notes is empty)
-- Rule: if a party has Introduction content (intro_ko/intro_en), fill Notes
-- with that same content. Scope: investor parties.
-- SAFE: only fills Notes that are currently empty -> never overwrites notes.
-- No hardcoded text: copies straight from the existing intro columns.
-- Run in Supabase SQL Editor (UTF-8). Save WITHOUT BOM. 2026-06-15.
-- ============================================================

-- (1) Fill Notes from Introduction (KO then EN; skips a missing side via concat_ws)
update app.parties p
set notes = btrim(concat_ws(E'\n\n', nullif(btrim(p.intro_ko), ''), nullif(btrim(p.intro_en), '')), E'\n'),
    updated_at = now()
where p.party_type_id = coalesce((select id from app.party_types where code = 'investor'), 1)
  and p.deleted_at is null
  and (p.intro_ko is not null or p.intro_en is not null)
  and (p.notes is null or btrim(p.notes) = '');

-- (2) Verification: among investors that have an Introduction, how many now have Notes
select count(*) as investors_with_intro,
       count(*) filter (where notes is not null and btrim(notes) <> '') as with_notes
from app.parties p
where p.party_type_id = coalesce((select id from app.party_types where code = 'investor'), 1)
  and p.deleted_at is null
  and (p.intro_ko is not null or p.intro_en is not null);

-- (3) Spot check (10 firms from the latest document)
select coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') as party_name,
       (p.intro_ko is not null or p.intro_en is not null) as has_intro,
       (p.notes is not null and btrim(p.notes) <> '') as has_notes,
       left(p.notes, 60) as notes_preview
from app.parties p
where p.deleted_at is null and (
  coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike 'Capricorn%'
  or coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike 'Emerson Collective%'
  or coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike 'ICONIQ%'
  or coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike 'Eclipse Ventures%'
  or coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike 'G2 Venture Partners%'
  or coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike 'Generation Investment Management%'
  or coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike 'Temasek%'
  or coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike 'GIC'
  or coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike 'UC Investments%'
  or coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike 'Stanford Management Company%'
)
order by party_name;
