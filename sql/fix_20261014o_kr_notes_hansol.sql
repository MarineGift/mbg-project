-- ============================================================
-- fix_20261014o_kr_notes_hansol.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Follow-up to 20261014n:
-- 1) Notes did not land on Omya Korea (row is not tagged country KR) and
--    Taekyung Industrial (name reads Industrial, not Industry). Re-applied
--    with matching patterns, guarded.
-- 2) The Hansol Daejeon pattern also matched 'Shintanjin Mill (Daejeon)'.
--    Shintanjin block is re-written on the Shintanjin row only, and the
--    Daejeon industrial-paper block goes only on a Hansol Daejeon row that
--    is not Shintanjin (none is written if that row does not exist).
-- Jeonju Paper, Shindaeyang and Taerim (context rows) are not in URM -
-- left out on purpose.
-- Idempotent. Last statement verifies.
-- ============================================================

update app.parties p
set notes = coalesce(nullif(btrim(p.notes), '') || ' | ', '') || 'KR check 2026-10-14: five Korean plants (Gunsan, Andong, Jeongseon, Jecheon, Onsan) and five quarries, over 1.2 Mt/yr calcium carbonate in total (dry plus slurry, not paper-only). Onsan hosts the Omya Hankook Chemical PCC JV with Hankuk Paper (2004). 2001 press named Hansol, Hankuk and Shin Moorim as main paper customers, paper about 70 pct of output then. KFTC 2017: paper GCC market about KRW 112.1bn, three suppliers Omya Korea, Taekyung Industry, GMC.', updated_at = now()
where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike 'Omya Korea%'
  and coalesce(p.notes, '') not ilike '%KR check 2026-10-14%';

update app.parties p
set notes = coalesce(nullif(btrim(p.notes), '') || ' | ', '') || 'KR check 2026-10-14: GCC capacity 545,220 t/yr per 2025 business report (filed 2026-03-23) - Gwangyang 144,000, Goesan 179,220, Onsan 222,000. Paper share not disclosed. One of three Korean paper GCC slurry suppliers (KFTC).', updated_at = now()
where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike 'Taekyung Industr%'
  and coalesce(p.notes, '') not ilike '%KR check 2026-10-14%';

update app.paper_mill_profile mp
set extra_data = coalesce(mp.extra_data, '{}'::jsonb) || jsonb_build_object('plant', $pj${"owner": "Hansol Paper", "priority": 5, "products": "Printing and specialty papers", "approach": "After Janghang. 2025 utilization 95.5 pct.", "to_collect": ["Current PCC / GCC supplier per machine and contract term", "Actual filler use (t/yr) and slurry solids", "Filler loading per grade and target increase", "Quality gates - opacity, brightness, tensile, stiffness, retention, drainage", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
    updated_at = now()
where mp.party_id in (select p.id from app.parties p
                      where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'KR'
                        and p.party_name ilike '%Shintanjin%');

insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from app.parties p
where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'KR'
  and p.party_name ilike '%Hansol%Daejeon%' and p.party_name not ilike '%Shintanjin%'
  and not exists (select 1 from app.paper_mill_profile mp where mp.party_id = p.id);

update app.paper_mill_profile mp
set extra_data = coalesce(mp.extra_data, '{}'::jsonb) || jsonb_build_object('plant', $pj${"owner": "Hansol Paper", "products": "Industrial paper", "approach": "Depends on grade. 2025 utilization 98.2 pct.", "checked_at": "2026-10-14"}$pj$::jsonb),
    updated_at = now()
where mp.party_id in (select p.id from app.parties p
                      where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'KR'
                        and p.party_name ilike '%Hansol%Daejeon%' and p.party_name not ilike '%Shintanjin%');

select 'filler' as kind, p.party_name as name,
       case when p.notes ilike '%KR check 2026-10-14%' then 'note added' else 'no note' end as status
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null
  and (p.party_name ilike 'Omya Korea%' or p.party_name ilike 'Taekyung Industr%')
union all
select 'hansol mill', p.party_name,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') || ' / ' || coalesce(mp.extra_data #>> '{plant,products}', '-')
from app.parties p
left join app.paper_mill_profile mp on mp.party_id = p.id
where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'KR'
  and p.party_name ilike '%Hansol%'
order by 1, 2;
