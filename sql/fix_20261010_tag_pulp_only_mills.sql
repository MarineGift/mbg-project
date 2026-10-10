-- ============================================================
-- fix_20261010_tag_pulp_only_mills.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Tags 23 market-pulp / dissolving-pulp producers in the paper_mill directory
-- with the interest tag 'MBG Pulp Only'. They make no paper and use no
-- filler, so they are not FCC targets.
-- Effect:
--   * the directory shows a "Pulp Only" chip (MBG category row) - click to list them
--   * /marketing segments skip them (patch_20261010_marketing_skip_pulp_only.ps1)
--   * nothing else: no do_not_contact, contacts and e-mails stay, a person can
--     still write to them by hand (pulp supply-chain talks)
-- Chosen from scan_20261010_pulp_only_mills (85 rows reviewed by hand).
-- Integrated pulp + paper mills (Suzano, Klabin, Double A, Navigator Setubal,
-- Mondi Steti, Ilim, Segezha, SCA ...) are NOT tagged - they stay targets.
-- Only rows whose interest_tags is a jsonb array (or empty) are changed.
-- Idempotent. Last statement is a verification select.
-- ============================================================
update app.parties p
set interest_tags = coalesce(p.interest_tags, '[]'::jsonb) || '["MBG Pulp Only"]'::jsonb,
    updated_at = now()
where p.deleted_at is null
  and p.id in (select v.party_id from (values
  ('24051f10-e9df-4420-94ef-65a352e52da6'::uuid),  -- CMPC Celulose Riograndense
  ('37040d42-b0a4-4d3f-90e5-c3415d3c9cbb'::uuid),  -- Eldorado Brasil
  ('9e2412ad-91a8-400b-8ef6-692ff19c6bf4'::uuid),  -- Veracel
  ('20542502-5c71-406c-993f-3b357bf0c672'::uuid),  -- Canfor Pulp Products
  ('51a714fa-bb1a-4a08-9b5b-71729c6da251'::uuid),  -- Celulosas de Asturias S.A. (CEASA)
  ('a51186c9-869d-4a3e-9092-f0d2c11dcb6a'::uuid),  -- ENCE Energía y Celulosa
  ('2a57ca24-6d68-43b3-ac83-1a551c80d916'::uuid),  -- Metsä Fibre Äänekoski
  ('9a2ada85-364e-49ab-ae57-0beebd6fb766'::uuid),  -- Metsä Fibre Kemi bioproduct mill
  ('5f63ed6c-edc6-4467-a053-b4b9f8c7f2cd'::uuid),  -- UPM Kaukas Lappeenranta
  ('b3d9f9dc-7660-4cd1-a73e-9aa703565323'::uuid),  -- Fibre Excellence
  ('03025de7-b7a2-44cb-9f75-babe2b461fae'::uuid),  -- Fibre Excellence Saint Gaudens
  ('851d0d07-9ada-43e5-89db-26640a5868f2'::uuid),  -- Cellulose du Maroc
  ('1634770c-644b-4940-8ff7-123e40056caa'::uuid),  -- Altri Group
  ('cf0a253f-c4aa-4014-83fa-b5fe10cbf2f3'::uuid),  -- Södra Cell
  ('74171724-bada-49d6-9881-4019eb7e5fca'::uuid),  -- Sappi Saiccor
  ('c1b2134a-e3af-4ad4-b5bc-512f5b8578b6'::uuid),  -- Lenzing Biocel Paskov
  ('cf3991a9-7c75-4002-b7d8-1bbd532b2df0'::uuid),  -- Kanbe Pulp Mill
  ('d3292081-5845-4374-ae93-8b8e06999809'::uuid),  -- Nilar Pulp and Paper
  ('b19b0d0f-479e-47e8-9f55-98a31758bd91'::uuid),  -- Oji Fibre Solutions Kinleith Mill
  ('1619ef3e-3664-4989-9053-6c017ca4b1ae'::uuid),  -- Oji Fibre Solutions Tasman Mill
  ('29babd90-c42b-4814-aff7-4b8c6fcd9040'::uuid),  -- Pan Pac Forest Products
  ('49f234b1-f442-479c-92a0-edadf3c36964'::uuid),  -- Phoenix Pulp & Paper
  ('7e4dde04-533d-4130-be3e-4cfdc1019ba8'::uuid)  -- Mercer International
  ) as v(party_id))
  and jsonb_typeof(coalesce(p.interest_tags, '[]'::jsonb)) = 'array'
  and not (coalesce(p.interest_tags, '[]'::jsonb) ? 'MBG Pulp Only');

select count(*) filter (where p.interest_tags ? 'MBG Pulp Only') as tagged_pulp_only,
       count(*) filter (where jsonb_typeof(coalesce(p.interest_tags, '[]'::jsonb)) <> 'array') as skipped_not_array
from app.parties p
join app.party_types t on t.id = p.party_type_id and t.code = 'paper_mill'
where p.deleted_at is null;
