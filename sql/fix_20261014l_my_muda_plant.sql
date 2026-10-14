-- ============================================================
-- fix_20261014l_my_muda_plant.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- 20261014k could not find Muda Kajang / Tasek - URM holds Muda as ONE
-- mill row (Muda Paper Mills, both mills). Writes the priority-4 plant block
-- to that row. Pascorp (ceased 2025-08) is not in URM and is left out.
-- Idempotent. Last statement verifies.
-- ============================================================

insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from app.parties p
where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'MY'
  and p.party_name ilike '%Muda%'
  and not exists (select 1 from app.paper_mill_profile mp where mp.party_id = p.id);

update app.paper_mill_profile mp
set extra_data = coalesce(mp.extra_data, '{}'::jsonb) || jsonb_build_object('plant', $pj${"owner": "Muda Holdings Berhad - Muda Paper Mills", "priority": 4, "products": "Testliner, corrugating medium, chip board, core board, wrapping paper", "grades": ["Testliner", "Chip board", "Core board"], "capacity_split": [{"label": "Kajang plus Tasek mills, older company figure", "value_t": 400000}], "pitch": "Cost-down on a specific grade - Muda is looking for savings", "approach": "One URM row covers both mills (Kajang, Selangor and Tasek, Penang). Local decision-making - pilot one grade at Kajang, then Tasek. 2025: revenue RM1.43bn, EBITDA RM58.1m, pre-tax loss RM62.1m.", "to_collect": ["Current filler use per machine (t/yr) and supplier", "Ash and strength specs per grade - compression, burst, ply bond", "Drainage and drying energy baseline", "Who approves a machine trial"], "sources": [{"label": "Muda 2025 annual report"}], "checked_at": "2026-10-14"}$pj$::jsonb),
    main_products = coalesce(nullif(btrim(mp.main_products), ''), 'Testliner, corrugating medium, chip board, core board, wrapping paper'),
    updated_at = now()
where mp.party_id in (select p.id from app.parties p
                      where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'MY'
                        and p.party_name ilike '%Muda%');

select p.party_name, p.city,
       mp.extra_data #>> '{plant,priority}' as priority,
       case when mp.extra_data #>> '{plant,checked_at}' = '2026-10-14' then 'written' else '-' end as plant_block
from app.parties p
left join app.paper_mill_profile mp on mp.party_id = p.id
where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'MY'
  and p.party_name ilike '%Muda%';
