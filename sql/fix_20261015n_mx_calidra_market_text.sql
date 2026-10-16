-- ============================================================
-- fix_20261015n_mx_calidra_market_text.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Mexico seed (20261015m) follow-up. The probe showed existing MX filler
-- rows the seed text did not account for:
--   Calidra (Grupo Calidra) - profile PCC + GCC + lime (not lime only)
--   Imerys Mexico, Carmeuse Mexico - existing rows
-- 1) app.country_markets MX: rewrite sections.fillers
-- 2) LEDSA Industrial memo: drop the wrong 'Calidra (lime)' clause
-- 3) Calidra: append MX memo once (16 plants, paper PCC lines to confirm)
-- Idempotent. Last statement is a verification select.
-- ============================================================

update app.country_markets cm
set sections = jsonb_set(coalesce(cm.sections, '{}'::jsonb), '{fillers}',
      to_jsonb($cm$Licensees: Omya (Mexico) (4 plants, lab at Cuautitlán Izcalli) and Specialty Minerals (Mexico) (satellite PCC record at Anáhuac for Pondercel, status to confirm). Also in URM: Imerys Mexico, Calidra (PCC, GCC and lime - 16 plants, 24 depots), Carmeuse Mexico, Mexalit / Cemex Minerals. Local GCC: Terrazo (Torreón), Reverté (Durango, majority stake sold 2026), ICC and ATSA (Querétaro), LEDSA. ONIC sells CaCO3 slurry and paper chemicals. Infra Derivados Químicos PCC (Cuautitlán) is 2005 history only.$cm$::text)),
    updated_at = now()
where cm.country_code = 'MX'
  and cm.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid;

update app.parties p
set notes = replace(p.notes, ' Grupo Calidra (lime, 16 plants),', ''),
    updated_at = now()
where p.party_type_id = 3 and p.deleted_at is null
  and p.party_name = 'LEDSA Industrial'
  and p.notes like '%Grupo Calidra (lime, 16 plants),%';

update app.parties p
set notes = coalesce(nullif(btrim(p.notes), '') || ' | ', '')
            || 'MX check 2026-10-15: company lists 16 plants and 24 depots in Mexico (Monterrey, Torreón, San Luis Potosí, Apaxco, Bernal and others) - which plant makes paper-grade PCC and for which mill is not public. Lime and CO2 source role for PCC.',
    updated_at = now()
where p.party_type_id = 3 and p.deleted_at is null
  and p.id = 'a29c3014-b274-475a-a0c0-3b04ea7f1aa8'::uuid
  and coalesce(p.notes, '') not ilike '%MX check 2026-10-15%';

select 'market' as kind, cm.country_code as name, left(cm.sections ->> 'fillers', 160) as detail
from app.country_markets cm
where cm.country_code = 'MX'
union all
select 'filler memo', p.party_name,
       case when p.notes ilike '%Calidra (lime%' then 'STILL WRONG' else 'ok' end
       || ' / ' || case when p.notes ilike '%MX check 2026-10-15%' then 'MX memo' else 'no MX memo' end
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null
  and p.id in ('a29c3014-b274-475a-a0c0-3b04ea7f1aa8'::uuid, '8f8ae1a3-d471-4255-b8fd-ba65d37eb115'::uuid)
order by 1, 2;
