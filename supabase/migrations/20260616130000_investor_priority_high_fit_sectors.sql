-- ============================================================
-- 20260616130000_investor_priority_high_fit_sectors.sql
-- Set priority = 'high' on investors whose tagged sector focus
-- matches our business: advanced_materials + deep_tech.
-- (Our FCC paper-filler tech = advanced materials; chitin /
--  marine biomaterials platform = deep tech.)
--
-- Data-driven, not name-guessed: uses app.investor_sector_focus.
-- Any investor with a sector focus already has an investor_profile
-- row (FK), so a plain UPDATE is sufficient (no insert needed).
--
-- Idempotent: re-running just re-asserts 'high'. Safe.
--
-- HOW TO APPLY (live): run in the Supabase SQL Editor.
--   Run STEP 1 alone first to preview WHO will change.
--   Then run STEP 2 to apply.
-- (Pushing this file to the repo version-controls it but does NOT apply.)
--
-- Optional: to also include life_science (chitin / femtech angle),
-- add 'life_science' to the sec.code IN (...) lists in both steps.
-- ============================================================

-- ----- STEP 1: PREVIEW (read-only) -----
select sec.code            as fit_sector,
       p.party_name,
       ip.priority         as current_priority
from app.investor_profile ip
join app.parties p
  on p.id = ip.party_id and p.deleted_at is null
join app.party_types pt
  on pt.id = p.party_type_id and pt.code = 'investor'
join app.investor_sector_focus isf
  on isf.investor_profile_id = ip.id
join app.sectors sec
  on sec.id = isf.sector_id
where ip.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and sec.code in ('advanced_materials', 'deep_tech')
order by sec.code, p.party_name;

-- ----- STEP 2: APPLY (set High) -----
begin;

update app.investor_profile ip
set priority = 'high'
where ip.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and ip.id in (
    select isf.investor_profile_id
    from app.investor_sector_focus isf
    join app.sectors sec on sec.id = isf.sector_id
    where sec.code in ('advanced_materials', 'deep_tech')
  );

commit;

-- ----- VERIFY (read-only) -----
-- select ip.priority, count(*) as investors
-- from app.investor_profile ip
-- where ip.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
-- group by ip.priority
-- order by ip.priority;
