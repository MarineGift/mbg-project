-- ============================================================
-- 20260620020000_app_filler_profile_B2_supply_model_backfill.sql
-- (B2) Backfill filler_supplier_profile.supply_model for ALL rows where it is
--      currently NULL, using link-aware + keyword derivation.
--
-- Derivation order (first match wins):
--   1. satellite (on-site)      <- party has a non-deleted party_supply_links row
--                                  whose link_type contains 'satellite'
--                                  (this catches real satellite sites and AUTO-
--                                   EXCLUDES SMI own mines/HQ, which have no such link)
--   2. None (no local presence) <- market_role = 'No direct presence' (from (D))
--   3. satellite (on-site)      <- market_role/supplier_type mentions satellite/on-site
--   4. Merchant                 <- merchant/distribution/lime/limestone/cement/kaolin/
--                                  mineral/PCC #1/MTI/Swiss global/GCC/process supply/
--                                  presence/global  (and NOT an "(HQ)" corporate row)
--   5. (leave NULL)             <- no defensible signal -> reported, not guessed
--
-- >>> RUN IN THE SUPABASE SQL EDITOR. <<<
-- Idempotent : only rows with supply_model IS NULL and a non-null derivation update.
-- Safe       : SMI mines/HQ get no satellite link -> never mislabeled as satellite.
-- ============================================================

update app.filler_supplier_profile fp
set supply_model = d.derived,
    updated_at   = now()
from (
  select
    fp.id as prof_id,
    case
      when exists (
             select 1 from app.party_supply_links sl
             where sl.filler_party_id = fp.party_id
               and sl.deleted_at is null
               and coalesce(sl.link_type, '') ilike '%satellite%'
           )
        then 'satellite (on-site)'
      when lower(coalesce(fp.market_role, '')) = 'no direct presence'
        then 'None (no local presence)'
      when lower(coalesce(fp.market_role, '') || ' ' || coalesce(fp.supplier_type, ''))
           ~ '(satellite|on-site|on site)'
        then 'satellite (on-site)'
      when p.party_name not ilike '%(HQ)%'
           and lower(coalesce(fp.market_role, '') || ' ' || coalesce(fp.supplier_type, ''))
               ~ '(merchant|distribution|lime|limestone|cement|kaolin|mineral|pcc #1|swiss global|mti|subsidiary|process supply|gcc|presence|global)'
        then 'Merchant'
      else null
    end as derived
  from app.filler_supplier_profile fp
  join app.parties p on p.id = fp.party_id
  where p.party_type_id = 3
    and p.deleted_at is null
    and fp.deleted_at is null
    and fp.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
    and fp.supply_model is null
) d
where fp.id = d.prof_id
  and d.derived is not null;

-- verification + residual report: post-update supply_model distribution
-- (any '(still null)' rows are the safe residual to review in a follow-up).
select coalesce(fp.supply_model, '(still null)') as supply_model,
       count(*) as n
from app.filler_supplier_profile fp
join app.parties p on p.id = fp.party_id
where p.party_type_id = 3
  and p.deleted_at is null
  and fp.deleted_at is null
  and fp.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
group by 1
order by n desc;
