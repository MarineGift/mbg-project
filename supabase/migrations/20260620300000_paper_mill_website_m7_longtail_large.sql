-- 20260620300000_paper_mill_website_m7_longtail_large.sql
-- NON-CONNECTED paper_mill (party_type_id = 2) website backfill - m7 (long-tail, large cos across countries).
-- Verified this pass: TIPCO(tipco.com.ph), Fine Hygienic(finehh.com), Packages(packages.com.pk),
--   Roshan(roshanpackages.com.pk), Thal(thallimited.com), Bio Pappel(biopappel.com), Copamex(copamex.com),
--   Carvajal/Propal(propal.com.co), ENCE(ence.es), Ilim(ilimgroup.com), Bohui(bohui.com).
-- Reused verified domains: APP(asiapulppaper.com), Chenming(chenmingpaper.com), Saica(saica.com),
--   Lecta(lecta.com), Miquel y Costas(miquelycostas.com), IP(internationalpaper.com), DS Smith/CMCP(dssmith.com),
--   Century PK(centurypaper.com.pk).
-- NOT included (unverified/sanctioned/defunct -> stay NULL): Shanying, Vinda, C&S, Huatai, Yueyang (CN);
--   Segezha, Arkhangelsk, Kama, Solikamsk (RU); Faderco, General Emballage, GIPEC (DZ); Med Paper, GPC (MA);
--   UPPC, PICOP (PH); Familia, Cartones America, Empacor (CO); Goma-Camps, Sniace (ES); Cherat, Security Papers (PK);
--   Egypt state mills; all composite/Multi-mill rows.
-- website-only. UTF-8. RUN IN SUPABASE SQL EDITOR. Idempotent. Org+type scoped.

update app.parties p
set website = d.url, updated_at = now()
from (values
  ('2cf72ce8-f1f2-4dc6-b486-00ff4df68aac'::uuid, 'https://www.asiapulppaper.com'),  -- [CN] APP China
  ('1eec3bdc-a16b-4846-9edb-18e4247e1431'::uuid, 'https://www.biopappel.com'),  -- [MX] Bio Pappel — Atenquique
  ('0da21f57-e4cb-4360-af23-22f1d1690623'::uuid, 'https://www.biopappel.com'),  -- [MX] Bio Pappel — Durango
  ('9a619bd5-7a76-4d81-8e26-08c9b36cf80c'::uuid, 'https://www.biopappel.com'),  -- [MX] Bio Pappel — McKinley
  ('3c7d129f-5e27-48a2-a6b8-65ee11c33e21'::uuid, 'https://www.biopappel.com'),  -- [MX] Bio Pappel — Scribe
  ('0a3dde65-502b-4a0c-a647-1a020e0c712b'::uuid, 'https://www.biopappel.com'),  -- [MX] Bio Pappel — Scribe / Atenquique pulp
  ('b7582406-58c5-415a-8c24-fce6fea97365'::uuid, 'https://www.biopappel.com'),  -- [MX] Bio Pappel — Titán
  ('bfa5cab3-be4a-48f1-b37e-1d46d5caf20e'::uuid, 'https://www.packages.com.pk'),  -- [PK] Bulleh Shah
  ('b627aba9-bd72-4254-b2de-ad77afdbeed0'::uuid, 'https://www.packages.com.pk'),  -- [PK] Bulleh Shah Packaging
  ('8eab1187-d1a4-4f5c-9203-eb3a2bfa2d95'::uuid, 'https://www.packages.com.pk'),  -- [PK] Bulleh Shah Paper Mill (BSPM) — Kasur
  ('d7b6026f-d0f1-461b-bfed-feeaa5eb56d4'::uuid, 'https://www.lecta.com'),  -- [ES] Cartiera Pirinex (Lecta)
  ('ea0cca33-7090-4c0a-8188-7046ce71798a'::uuid, 'https://www.propal.com.co'),  -- [CO] Carvajal Propal
  ('995669bc-7bc0-40ca-bab5-7864ff5d4988'::uuid, 'https://www.propal.com.co'),  -- [CO] Carvajal Pulpa y Papel (Propal)
  ('01683841-b0b7-46ab-9fc8-cdb9120c3aae'::uuid, 'https://www.ence.es'),  -- [ES] Celulosas de Asturias (CEASA)
  ('51a714fa-bb1a-4a08-9b5b-71729c6da251'::uuid, 'https://www.ence.es'),  -- [ES] Celulosas de Asturias S.A. (CEASA)
  ('66a08d13-3f3a-46c6-ad5f-e15c33aee70f'::uuid, 'https://www.centurypaper.com.pk'),  -- [PK] Century
  ('7a83a45c-8259-42e5-88a4-2f3e97352654'::uuid, 'https://www.centurypaper.com.pk'),  -- [PK] Century Paper & Board
  ('9952de05-98fa-4254-a373-8e83d60fed0c'::uuid, 'https://www.dssmith.com'),  -- [MA] CMCP
  ('25a5f74f-8ef6-4126-b75a-15bfa0216f5b'::uuid, 'https://www.dssmith.com'),  -- [MA] CMCP Agadir packaging
  ('1aece75b-13a2-43aa-bbb3-42b2c4b44391'::uuid, 'https://www.dssmith.com'),  -- [MA] CMCP Casablanca packaging
  ('b7089b22-3931-4b12-b016-f54a71e250b6'::uuid, 'https://www.internationalpaper.com'),  -- [MA] CMCP-International Paper
  ('94338fdf-557c-4656-a497-77baa2cd2e7d'::uuid, 'https://www.copamex.com'),  -- [MX] Corporativo Copamex
  ('b1b6b1fb-1cf1-4950-b245-bea4708aca1c'::uuid, 'https://www.ence.es'),  -- [ES] ENCE + CEASA
  ('a51186c9-869d-4a3e-9092-f0d2c11dcb6a'::uuid, 'https://www.ence.es'),  -- [ES] ENCE Energía y Celulosa
  ('2e660dfd-afe2-493b-ad94-052904749ff4'::uuid, 'https://www.ence.es'),  -- [ES] ENCE Navia
  ('908ab07c-2f28-4528-90d6-38079c86f98e'::uuid, 'https://www.ence.es'),  -- [ES] ENCE Pontevedra
  ('7d81c3f4-5e8e-4e82-a20f-a068fc232fab'::uuid, 'https://www.finehh.com'),  -- [EG] Fine Hygienic Holding Egypt
  ('06f2fb2d-e7a0-4e93-8fd8-4f054ea58937'::uuid, 'https://www.finehh.com'),  -- [EG] Fine Hygienic Holdings Egypt
  ('868f1e30-8771-42f5-ae2b-eeb053db917e'::uuid, 'https://www.asiapulppaper.com'),  -- [CN] Gold Hongye Paper (APP)
  ('c7ab5582-c45b-430a-9e9b-e833553932c6'::uuid, 'https://www.biopappel.com'),  -- [MX] Grupo Bio Pappel (Pappel)
  ('168684f0-bb08-4892-a31f-7accedd08acd'::uuid, 'https://www.asiapulppaper.com'),  -- [CN] Guangxi Jingui Pulp & Paper (APP)
  ('806744ad-62fa-49b6-a439-a9dbc656af1e'::uuid, 'https://www.asiapulppaper.com'),  -- [CN] Hainan Jinhai Pulp & Paper (APP)
  ('a178a47d-afab-49b8-ab28-7891e7da5ba9'::uuid, 'https://www.ilimgroup.com'),  -- [RU] Ilim Bratsk
  ('28641f03-5a9f-408d-9027-954dc74a4b8e'::uuid, 'https://www.ilimgroup.com'),  -- [RU] Ilim Bratsk + Koryazhma
  ('fa774855-9c79-4aaf-a26f-0354e18241ea'::uuid, 'https://www.ilimgroup.com'),  -- [RU] Ilim Gofra Kommunar
  ('a4344dca-17ae-49ac-9b4a-2b653dfb6ab9'::uuid, 'https://www.ilimgroup.com'),  -- [RU] Ilim Group
  ('1267e201-ee81-43ae-b9e5-a51b2240e22d'::uuid, 'https://www.ilimgroup.com'),  -- [RU] Ilim Koryazhma
  ('30aa0824-dfbd-4603-bd7e-19e8ef4c3614'::uuid, 'https://www.ilimgroup.com'),  -- [RU] Ilim Ust-Ilimsk
  ('8014b103-a0ec-40a3-b1d8-74c4f269116e'::uuid, 'https://www.internationalpaper.com'),  -- [ES] IP Madrid (former Holmen)
  ('5ae92908-ae1c-48ec-bf8d-376f5700038a'::uuid, 'https://www.bohui.com'),  -- [CN] Jiangsu Bohui Paper (APP) (Dafeng)
  ('88ca497f-c47c-403d-81db-136286e77e8c'::uuid, 'https://www.miquelycostas.com'),  -- [ES] Miquel y Costas & Miquel S.A.
  ('1c84b541-7c03-43ae-bb5f-1f2568e4a6ff'::uuid, 'https://www.miquelycostas.com'),  -- [ES] Miquel y Costas mills
  ('833a8342-4132-4278-bd7b-895758054885'::uuid, 'https://www.asiapulppaper.com'),  -- [CN] Ningbo Asia Pulp & Paper (APP)
  ('4c1b6e95-5ca0-451b-940f-8a5d05969b88'::uuid, 'https://www.asiapulppaper.com'),  -- [CN] Ningbo Zhonghua Paper (APP)
  ('a4893b54-d00f-4747-aac0-eac37e844593'::uuid, 'https://www.packages.com.pk'),  -- [PK] Packages Karachi corrugating
  ('d4ce7829-0a21-4f97-a1bb-95187ed4595a'::uuid, 'https://www.packages.com.pk'),  -- [PK] Packages Lahore
  ('23cbd0da-f2cf-4c61-ada6-e6ad5a595dba'::uuid, 'https://www.roshanpackages.com.pk'),  -- [PK] Roshan Packages
  ('4ef838b2-0cc1-4811-8a11-f35ffb704755'::uuid, 'https://www.roshanpackages.com.pk'),  -- [PK] Roshan Packages Ltd (RPL)
  ('86b571f4-420b-48de-a714-30026ee4c4d1'::uuid, 'https://www.saica.com'),  -- [ES] Saica Group (HQ)
  ('3361bb7d-baf3-4ebe-9ad8-b9a4240bfdeb'::uuid, 'https://www.saica.com'),  -- [ES] Saica Pack + Flex
  ('ef79725f-9f75-4d9d-af96-eb9628693edf'::uuid, 'https://www.saica.com'),  -- [ES] Saica Pack + Flex plants
  ('335a80bc-648d-4e78-908e-0a4487a7b287'::uuid, 'https://www.saica.com'),  -- [ES] Saica Paper El Burgo de Ebro Zaragoza
  ('6a6d1429-874f-411c-8856-5699c38e1178'::uuid, 'https://www.saica.com'),  -- [ES] Saica Paper Partington UK
  ('fb87d668-4de6-4ff3-8138-7dd5ba0500b4'::uuid, 'https://www.bohui.com'),  -- [CN] Shandong Bohui Paper Industrial Co.
  ('3d0b6229-0281-49b3-b081-afec99ac6d0a'::uuid, 'https://www.chenmingpaper.com'),  -- [CN] Shandong Chenming Paper Holdings Ltd.
  ('6d7d4d0a-166e-4941-bb53-0388d1e2d8b3'::uuid, 'https://www.chenmingpaper.com'),  -- [CN] Shouguang Meilun Paper
  ('4c43d397-607c-4fe4-84ec-74206d740345'::uuid, 'https://www.thallimited.com'),  -- [PK] Thal Limited (THALL)
  ('e19b0291-97d5-40ad-874a-d564e663f09c'::uuid, 'https://www.thallimited.com'),  -- [PK] Thal Limited paper
  ('3a948eb3-d59b-42b6-ad14-c5433bfefcd1'::uuid, 'https://www.thallimited.com'),  -- [PK] Thal Limited paper unit
  ('c2f1ad31-2229-48d2-84dc-f68c477acc10'::uuid, 'https://www.tipco.com.ph'),  -- [PH] TIPCO
  ('f635091d-e2b3-4e3b-92bb-95516623bd48'::uuid, 'https://www.tipco.com.ph'),  -- [PH] TIPCO Mabalacat PM1
  ('e66a1cac-0cc2-4467-aef1-a809f242a74b'::uuid, 'https://www.tipco.com.ph'),  -- [PH] TIPCO Mabalacat PM2
  ('00e1b664-8014-4525-8ce6-9a39779cd1de'::uuid, 'https://www.tipco.com.ph'),  -- [PH] TIPCO Mabalacat PM3
  ('029b3cc9-ffa2-46c8-a7aa-df1266206a0c'::uuid, 'https://www.tipco.com.ph')  -- [PH] Trust International Paper Corp (TIPCO)
) as d(party_id, url)
where p.id = d.party_id
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and p.party_type_id = 2
  and (p.website is null or p.website not ilike 'http%');

-- verify
select count(*) filter (where website ilike 'http%') as with_url, count(*) as total
from app.parties where id in (
  '2cf72ce8-f1f2-4dc6-b486-00ff4df68aac','1eec3bdc-a16b-4846-9edb-18e4247e1431','0da21f57-e4cb-4360-af23-22f1d1690623','9a619bd5-7a76-4d81-8e26-08c9b36cf80c','3c7d129f-5e27-48a2-a6b8-65ee11c33e21','0a3dde65-502b-4a0c-a647-1a020e0c712b','b7582406-58c5-415a-8c24-fce6fea97365','bfa5cab3-be4a-48f1-b37e-1d46d5caf20e','b627aba9-bd72-4254-b2de-ad77afdbeed0','8eab1187-d1a4-4f5c-9203-eb3a2bfa2d95','d7b6026f-d0f1-461b-bfed-feeaa5eb56d4','ea0cca33-7090-4c0a-8188-7046ce71798a','995669bc-7bc0-40ca-bab5-7864ff5d4988','01683841-b0b7-46ab-9fc8-cdb9120c3aae','51a714fa-bb1a-4a08-9b5b-71729c6da251','66a08d13-3f3a-46c6-ad5f-e15c33aee70f','7a83a45c-8259-42e5-88a4-2f3e97352654','9952de05-98fa-4254-a373-8e83d60fed0c','25a5f74f-8ef6-4126-b75a-15bfa0216f5b','1aece75b-13a2-43aa-bbb3-42b2c4b44391','b7089b22-3931-4b12-b016-f54a71e250b6','94338fdf-557c-4656-a497-77baa2cd2e7d','b1b6b1fb-1cf1-4950-b245-bea4708aca1c','a51186c9-869d-4a3e-9092-f0d2c11dcb6a','2e660dfd-afe2-493b-ad94-052904749ff4','908ab07c-2f28-4528-90d6-38079c86f98e','7d81c3f4-5e8e-4e82-a20f-a068fc232fab','06f2fb2d-e7a0-4e93-8fd8-4f054ea58937','868f1e30-8771-42f5-ae2b-eeb053db917e','c7ab5582-c45b-430a-9e9b-e833553932c6','168684f0-bb08-4892-a31f-7accedd08acd','806744ad-62fa-49b6-a439-a9dbc656af1e','a178a47d-afab-49b8-ab28-7891e7da5ba9','28641f03-5a9f-408d-9027-954dc74a4b8e','fa774855-9c79-4aaf-a26f-0354e18241ea','a4344dca-17ae-49ac-9b4a-2b653dfb6ab9','1267e201-ee81-43ae-b9e5-a51b2240e22d','30aa0824-dfbd-4603-bd7e-19e8ef4c3614','8014b103-a0ec-40a3-b1d8-74c4f269116e','5ae92908-ae1c-48ec-bf8d-376f5700038a','88ca497f-c47c-403d-81db-136286e77e8c','1c84b541-7c03-43ae-bb5f-1f2568e4a6ff','833a8342-4132-4278-bd7b-895758054885','4c1b6e95-5ca0-451b-940f-8a5d05969b88','a4893b54-d00f-4747-aac0-eac37e844593','d4ce7829-0a21-4f97-a1bb-95187ed4595a','23cbd0da-f2cf-4c61-ada6-e6ad5a595dba','4ef838b2-0cc1-4811-8a11-f35ffb704755','86b571f4-420b-48de-a714-30026ee4c4d1','3361bb7d-baf3-4ebe-9ad8-b9a4240bfdeb','ef79725f-9f75-4d9d-af96-eb9628693edf','335a80bc-648d-4e78-908e-0a4487a7b287','6a6d1429-874f-411c-8856-5699c38e1178','fb87d668-4de6-4ff3-8138-7dd5ba0500b4','3d0b6229-0281-49b3-b081-afec99ac6d0a','6d7d4d0a-166e-4941-bb53-0388d1e2d8b3','4c43d397-607c-4fe4-84ec-74206d740345','e19b0291-97d5-40ad-874a-d564e663f09c','3a948eb3-d59b-42b6-ad14-c5433bfefcd1','c2f1ad31-2229-48d2-84dc-f68c477acc10','f635091d-e2b3-4e3b-92bb-95516623bd48','e66a1cac-0cc2-4467-aef1-a809f242a74b','00e1b664-8014-4525-8ce6-9a39779cd1de','029b3cc9-ffa2-46c8-a7aa-df1266206a0c'
);
