-- ============================================================
-- 20260620030000_app_filler_profile_B2b_supply_model_residual.sql
-- (B2b) Residual supply_model backfill for the 52 rows left NULL by (B2).
--   - 40 SMI plant-site parties -> 'satellite (on-site)'
--        (link-evidenced satellites whose link_type was 'active'/'historical',
--         plus named city-site plants; SMI US OWN MINES are NOT in this set).
--   - 11 -> 'Merchant'  (SMI US own mines: Adams MA / Barretts MT / Canaan CT /
--        Cougar WA / Lucerne Valley CA / Ste. Genevieve MO; SMI Indonesia country
--        aggregate; Imerys Brazil+Artemyn; Omya Brazil; Petro Caspian; Trzuskawica CRH).
--   - 1 left NULL on purpose: Omya (HQ) - corporate HQ, no supply model.
--
-- >>> RUN IN THE SUPABASE SQL EDITOR. <<<
-- Idempotent: guarded by supply_model IS NULL + explicit party_id sets.
-- ============================================================

update app.filler_supplier_profile fp
set supply_model = 'satellite (on-site)', updated_at = now()
where fp.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and fp.deleted_at is null
  and fp.supply_model is null
  and fp.party_id in (
    'd9828323-dfb8-4518-9f64-101d5ac0fa90',
    '96f2e46e-4fde-40d7-aa53-d976df352f16',
    'e5bdc53e-f60f-4769-8b85-de58d9abe44c',
    '052d5520-d52a-4ea8-8f0c-54875b0aa723',
    '051c8f63-3f03-4baf-8ed8-35593e3ef618',
    'cec6804b-e716-4702-a43c-244b30b75fd6',
    '2ad24bf4-b9c5-4763-aa0f-018dbcc96116',
    'd7c75f06-8910-4304-97be-4c6dc252f4a5',
    '1e0439a9-1261-4635-b76e-64f30db7ec05',
    'ee500a51-16ab-425b-81b6-1d30b0cc495e',
    '357f7c13-3ff2-4671-8e16-925521035099',
    '116db4e9-e7af-4a0c-b01f-fb950b9cd326',
    'e7eb801b-4cdf-4955-98d9-d7cbf7c658ec',
    '992ce57b-edcc-411e-b396-1a6d5ff5bd17',
    '12332f5f-dce5-42ae-99b1-c559bbf1d6f6',
    '91e60359-f0e1-4127-8e78-a4557a937587',
    '3d08331e-2041-4c7f-b4a4-bcc0e4a09915',
    '53b4f1fe-7d61-4ea4-bfd9-70daf624cae0',
    'e6292004-1fb4-4680-ac6e-6ab7b2a61fcd',
    'c2fda98a-04cf-474f-9da8-54c41ca80bac',
    '25dce85a-bd2f-4929-95ca-4eb054bc2160',
    '45a93fab-a2c0-4726-9a0f-4062f2d06511',
    '03badee1-e551-46ba-96f2-adaa84fd6415',
    '0fa2ec21-379e-4a5c-b076-a01aaaf0accc',
    '026684e2-2d91-465d-a30e-403ab4c24707',
    '55d012e2-1c60-45a7-9046-5e841f1858d3',
    '52f22cbe-44bc-44c8-92f5-5c42f2a580a3',
    '4a418304-f0b3-45cd-9322-8687f150aa94',
    'c0d910dc-90fc-4778-90e1-7a60553a7ab7',
    '27dadd0f-94c5-4fcc-9030-a872c9719c58',
    '9f66ddf8-2322-41b3-9335-235c03215ed4',
    '914f659f-22c9-421d-8e0c-45ea9e39b5dc',
    '182d46db-6ffa-4c8e-a743-085632db6f1e',
    'aab05ecf-b32e-4720-a384-1b40b28db105',
    '7623d7fc-7bfd-4342-bcba-8460ed83b7bf',
    '81b5fd3d-cee0-4d35-b648-d541821cd3b9',
    'd080e4b2-58d4-44b0-afa6-b020d7a50401',
    'b3499eb5-46d9-4374-b7af-c4d906a04837',
    'b49cd54c-fa4d-41f0-89f4-f52f8bd59ccd',
    '25c1a913-dd52-4eb2-8d63-37d76b8a4e23'
  );

update app.filler_supplier_profile fp
set supply_model = 'Merchant', updated_at = now()
where fp.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and fp.deleted_at is null
  and fp.supply_model is null
  and fp.party_id in (
    '801a41d5-1da5-404a-9e2b-3a1560cdc23a',
    'd8445277-2fae-4a2a-abcf-f37410c6391c',
    '7c66afd3-8112-4339-aa2f-c66dc70935e1',
    'df33c002-a174-4539-a5f5-805eaf8c0cf4',
    '3583bb5f-2c79-4eff-a1ee-f2b2ed0706fe',
    'e46b80fa-6d71-48a3-ae3e-fa60877febdb',
    'ae7d3254-0e50-4c63-96f5-8caa382bf79f',
    '6292bb71-cf6e-4996-87a8-9e5ebc80c394',
    '63910bab-7ce7-4213-8e61-814c743d99c2',
    '2ec3cca2-fecc-477e-8820-b069f7a50cdc',
    '2c5f4cba-426a-46b5-8e9a-9ba27ee27639'
  );

-- verification: post-update, only Omya (HQ) should remain supply_model NULL.
select p.party_name, fp.supply_model
from app.filler_supplier_profile fp
join app.parties p on p.id = fp.party_id
where p.party_type_id = 3
  and p.deleted_at is null
  and fp.deleted_at is null
  and fp.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and fp.supply_model is null
order by p.party_name;
