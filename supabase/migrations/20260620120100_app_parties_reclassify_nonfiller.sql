-- 20260620120100_app_parties_reclassify_nonfiller.sql
-- Reclassify two NON-filler chemical producers out of filler_supplier(3).
--   Tangshan Sanyou Chemical  (soda ash / PVC, SSE 600409) -- not a CaCO3 filler
--   Petro Caspian Sepehr      (caustic soda, Iran)         -- not a CaCO3 filler
--
-- OPTION A (recommended): introduce a catch-all 'other_supplier' party_type and
-- move both rows there. Non-destructive; reusable for future mis-classified rows.
--
-- RUN IN SUPABASE SQL EDITOR to apply.

-- 1) add the new party_type if it does not already exist (id = max+1; idempotent)
insert into app.party_types (id, code, display_name_en, display_name_ko, display_name_ja, sort_order, is_active)
select (select coalesce(max(id),0)+1 from app.party_types),
       'other_supplier', 'Other Supplier', '기타 공급사', 'その他サプライヤー',
       (select coalesce(max(sort_order),0)+1 from app.party_types), true
where not exists (select 1 from app.party_types where code = 'other_supplier');

-- 2) move the two rows to other_supplier (referenced by code, no hard-coded id)
update app.parties
set party_type_id = (select id from app.party_types where code = 'other_supplier'),
    updated_at = now()
where id in (
  '85c4c2b8-1d33-451e-937a-765ebfc52383',  -- Tangshan Sanyou
  '7c66afd3-8112-4339-aa2f-c66dc70935e1'   -- Petro Caspian Sepehr
)
  and party_type_id = 3
  and organization_id = 'b25de8f2-1020-482f-9012-183f63883169';

-- verify (both rows should now show the new other_supplier id)
select p.id, p.party_name, p.party_type_id, t.code
from app.parties p
join app.party_types t on t.id = p.party_type_id
where p.id in (
  '85c4c2b8-1d33-451e-937a-765ebfc52383',
  '7c66afd3-8112-4339-aa2f-c66dc70935e1'
);
