-- ============================================================
-- 20260620040000_app_filler_profile_B1_evidence_level_backfill.sql
-- (B1) Backfill filler_supplier_profile.evidence_level where it is NULL, using
--      the SAME convention already used in batch 10b:
--        supply_model contains 'satellite' -> 'B'  (satellite-derived, link/10-K verified)
--        supply_model contains 'merchant'  -> 'C'  (merchant / market-inferred)
--        otherwise (e.g. 'None (no local presence)', NULL) -> leave NULL
--
-- >>> RUN IN THE SUPABASE SQL EDITOR, AFTER (B2) and (B2b). <<<
-- Needs the final supply_model values, so run this last among the backfills.
-- Idempotent: only evidence_level IS NULL rows with a non-null derivation update.
-- Existing evidence_level values (64 rows) are left untouched.
-- evidence_level CHECK set is A/B/C/D (B/C used here).
-- ============================================================

update app.filler_supplier_profile fp
set evidence_level = d.lvl,
    updated_at     = now()
from (
  select
    fp.id as prof_id,
    case
      when fp.supply_model ilike '%satellite%' then 'B'
      when fp.supply_model ilike '%merchant%'  then 'C'
      else null
    end as lvl
  from app.filler_supplier_profile fp
  join app.parties p on p.id = fp.party_id
  where p.party_type_id = 3
    and p.deleted_at is null
    and fp.deleted_at is null
    and fp.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
    and fp.evidence_level is null
) d
where fp.id = d.prof_id
  and d.lvl is not null;

-- verification: evidence_level distribution after backfill.
select coalesce(fp.evidence_level, '(still null)') as evidence_level,
       count(*) as n
from app.filler_supplier_profile fp
join app.parties p on p.id = fp.party_id
where p.party_type_id = 3
  and p.deleted_at is null
  and fp.deleted_at is null
  and fp.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
group by 1
order by n desc;
