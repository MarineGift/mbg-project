-- ============================================================
-- fix_20261010_host_mill_cleanup.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Clean-up from the Omya / SMI host-mill review (doc "Omya - SMI host mill
-- list", 2026-10-10). Three changes:
-- 1) Remove one wrong link: the SMI historical satellite "USA - Sartell MN"
--    was attached to Clearwater Paper. Sartell was a Verso mill (closed 2012),
--    never a Clearwater mill. Only that one link row is deleted.
-- 2) Omya -> Billerud Escanaba: confidence set to high. Omya operates the
--    on-site PCC plant (started 2014, operating at the Michigan EGLE
--    inspection of March 2024).
-- 3) Tag four more non-paper producers 'MBG Pulp Only' (skipped by
--    /marketing): Montes del Plata, UPM Fray Bentos, UPM Paso de los Toros
--    (Uruguay pulp mills) and Lenzing Group (dissolving pulp and fibres).
-- Idempotent. Last statement is a verification select.
-- ============================================================

-- 1) wrong link
delete from app.party_supply_links l
using app.parties f
where f.id = l.filler_party_id
  and f.party_name = 'Specialty Minerals (USA - Sartell MN)'
  and l.mill_party_id = 'c014ea7a-e5da-4cc6-b11d-9aac2215f836'::uuid;

-- 2) confirmed Omya on-site PCC at Escanaba
update app.party_supply_links l
set confidence = 'high',
    notes = coalesce(nullif(btrim(l.notes), '') || ' | ', '')
            || 'Omya on-site PCC plant at Escanaba since 2014, operating per Michigan EGLE inspection March 2024 (checked 2026-10-10)'
from app.parties f
where f.id = l.filler_party_id
  and f.party_name = 'Omya (USA)'
  and l.mill_party_id = '2ed3ac31-de06-4608-9427-fa4789cc80ed'::uuid
  and l.confidence is distinct from 'high';

-- 3) pulp / fibre producers
update app.parties p
set interest_tags = coalesce(p.interest_tags, '[]'::jsonb) || '["MBG Pulp Only"]'::jsonb,
    updated_at = now()
where p.deleted_at is null
  and p.id in ('8d19cb27-3128-4796-96e1-499aab16415d'::uuid,
               '3c893407-beb5-492c-aa7f-384f16666bd2'::uuid,
               'd226ea8b-a601-4e92-8815-6ad3e6104a73'::uuid,
               'a8ff9f12-61fb-4481-8c3d-89c3c45efb26'::uuid)
  and jsonb_typeof(coalesce(p.interest_tags, '[]'::jsonb)) = 'array'
  and not (coalesce(p.interest_tags, '[]'::jsonb) ? 'MBG Pulp Only');

select 'sartell link left' as check_item,
       count(*)::text as value
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
where f.party_name = 'Specialty Minerals (USA - Sartell MN)'
  and l.mill_party_id = 'c014ea7a-e5da-4cc6-b11d-9aac2215f836'::uuid
union all
select 'escanaba omya confidence',
       max(l.confidence)
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
where f.party_name = 'Omya (USA)'
  and l.mill_party_id = '2ed3ac31-de06-4608-9427-fa4789cc80ed'::uuid
union all
select 'pulp only tagged total',
       count(*)::text
from app.parties p
join app.party_types t on t.id = p.party_type_id and t.code = 'paper_mill'
where p.deleted_at is null and p.interest_tags ? 'MBG Pulp Only';
