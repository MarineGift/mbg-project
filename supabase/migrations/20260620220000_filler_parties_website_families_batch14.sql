-- 20260620220000_filler_parties_website_families_batch14.sql
-- filler_supplier (party_type_id = 3) website backfill - BATCH 14.
-- Families: Omya->omya.com, SMI/MTI->mineralstech.com, Carmeuse->carmeuse.com,
-- Sibelco->sibelco.com; plus verified independents. Evaluation notes that were
-- stuffed in the website column are first preserved into filler_supplier_profile.notes
-- (tag [ex-website-note 2026-06-20]) before the website column is overwritten/cleared.
-- UTF-8. RUN IN SUPABASE SQL EDITOR. Idempotent guards; org+type scoped.

-- A) preserve embedded website-column notes into filler_supplier_profile.notes
update app.filler_supplier_profile f
set notes = coalesce(f.notes,'') || E'\n[ex-website-note 2026-06-20] ' || d.note,
    updated_at = now()
from (values
  ('85249ecd-c58c-499c-b7df-3cd505c742e4'::uuid, '⭐⭐⭐ 터키 자국 calcite #1 by quarry scale'),  -- Anadolu Mikronize (ANDCARB)
  ('a29c3014-b274-475a-a0c0-3b04ea7f1aa8'::uuid, '⭐⭐ Mexican lime #1; PCC value chain'),  -- Calidra (Grupo Calidra)
  ('ff8b1fb0-6983-43c9-8dd8-1cd0599bdc0b'::uuid, 'Potential local supplier candidate only'),  -- Calrock Sdn Bhd
  ('fd4b2bcf-58ac-4993-a848-ba3b47cbcf55'::uuid, 'Lime + limestone supplier'),  -- Carmeuse Canada
  ('d08ba3a8-976f-4e95-83cc-3c45559ac2f4'::uuid, 'Carmeuse Mexican lime'),  -- Carmeuse Mexico
  ('d78bfd69-2187-429e-86a6-91ac591b9593'::uuid, 'Small domestic operator'),  -- EGM (Wierzbica)
  ('4bcca929-8061-4e62-ac82-7a17b7e92405'::uuid, 'Domestic WGCC supplier; verification needed'),  -- F.M.T. (Thailand) Co., Ltd.
  ('23bcb2d1-a78e-40e7-b1ac-c66cd7a4acff'::uuid, 'Domestic CaCO3 producer; needs paper-customer verification'),  -- Global Filler Corporation
  ('1406738e-b384-43d1-bf0f-0654ca1ab792'::uuid, '⭐⭐ Canadian lime #1; PCC value chain'),  -- Graymont
  ('e575dd34-d48e-4742-a44b-e5d24920dc2f'::uuid, '⭐ 미국 paper talc 시장의 specialty 사업자'),  -- IMI Fabi
  ('dae6be28-25cd-453b-98a5-86d239b0766c'::uuid, 'Specialty paper kaolin supplier; less paper-explicit than Omya/Zantat'),  -- Kaolin (Malaysia) Sdn Bhd / local kaolin suppliers
  ('7eacb25d-df07-4024-83b2-1ae4d8467310'::uuid, 'Building 위주, paper fit 제한적'),  -- KW Czatkowice (Czatkowice Limestone Mine)
  ('df5461f2-06e8-4156-b983-4a6ee76f6298'::uuid, 'Small specialty supplier'),  -- Labtar (Tarnów Opolski)
  ('55b9c376-49fd-4179-9277-1d4e1c7df03b'::uuid, '⭐⭐ 폴란드 자국 lime supplier #1; PCC value-chain enabler'),  -- Lhoist Polska
  ('64614082-d16d-432e-84a5-66fdee3d2b20'::uuid, 'Cement upstream'),  -- Mexalit / Cemex Minerals
  ('dc92d027-424c-4696-bffe-7f349c26c253'::uuid, 'Niğtaş affiliate'),  -- Mikrokal (Niğtaş affiliate)
  ('2a4a6b46-4a82-4cb7-b56e-b9846c4e104c'::uuid, 'TURKCARB brand multi-mineral specialist'),  -- Mikron-S Mikronize Mineral (TURKCARB)
  ('cbde4480-031d-4836-b7bb-a9b5a335b7cb'::uuid, '⭐ 미국 자국 PCC 시장의 두 번째 사업자 (MTI 다음)'),  -- Mississippi Lime Company (MLC)
  ('ec511809-95e8-43e8-a13a-d5744c2ea877'::uuid, 'Niğde cluster member'),  -- Nidaş AS
  ('38fa015e-204d-4cc9-83ea-b31091da6123'::uuid, '⭐⭐ 터키 자국 calcite #2; nano-grade specialist'),  -- Niğtaş Group
  ('33d5aa0b-2cf8-4b73-842f-873f2a85312d'::uuid, '⭐ Scandinavian-owned, 폴란드 4-site footprint'),  -- Nordkalk
  ('988b7f5c-40fb-487d-ac4e-1d432007f8e9'::uuid, 'Top-tier; only confirmed Australia paper-mineral entity'),  -- Omya (Australia)
  ('b252f5e1-c082-4772-ada2-0d56bd615ef0'::uuid, 'NA Omya footprint with Canadian operations'),  -- Omya (Canada)
  ('fac3df6e-875a-4cc3-97d4-fbb0ca10dd7f'::uuid, '⭐⭐⭐ Yeongwol 200k+ t/y high-grade GCC confirmed (Omya Final 2025); 5-plant claim verification needed'),  -- Omya (Korea)
  ('fbca4410-7bb9-4ec4-8d17-5adb39e1c38d'::uuid, 'Top-tier; Volza data: largest CaCO3 exporter from Malaysia (45%, 1,180 shipments)'),  -- Omya (Malaysia)
  ('19d167eb-84d0-4914-9af2-8ac5bf8dc708'::uuid, 'NA Omya footprint Mexican operations'),  -- Omya (Mexico)
  ('8f10519d-75ac-49f2-b4ce-587b47accdf6'::uuid, 'Top-tier; Mielnik 폴란드 plant + EU footprint'),  -- Omya (Poland)
  ('f2322eb8-9971-41b4-993d-35a7c05a6fbc'::uuid, 'Top-tier; 4-plant Turkish footprint, European Omya backbone'),  -- Omya (Turkey)
  ('3bccf3f8-8b1e-43af-9fdd-049b62af066b'::uuid, 'Top-tier; 2024 Domtar Nekoosa+Rothschild PCC plant landmark'),  -- Omya (USA)
  ('09ff62ad-8f2c-4e93-8174-48e99fc2c8b0'::uuid, 'Best foreign supplier presence in Vietnam paper market'),  -- Omya (Vietnam)
  ('3ed78f9d-1c53-46dc-bccf-c916c5f393ac'::uuid, 'Strongest domestic supplier for Thai paper market'),  -- Quality Minerals Public Co., Ltd. (Q-min)
  ('f55d50a2-461f-457e-98cd-bda773692e41'::uuid, 'Potential but unverified paper-market role in Malaysia'),  -- Shiraishi Calcium Malaysia Sdn Bhd
  ('0c151b95-c048-48c5-8b21-350048295904'::uuid, 'Secondary candidate'),  -- Sibelco
  ('5d2e3859-d191-48e5-b0a8-1dfde1783c53'::uuid, 'Specialty minerals'),  -- Sibelco Canada
  ('ffeb9cf5-83f0-4fa4-b91b-3add230b558c'::uuid, 'High technical fit but no local mill-level evidence'),  -- Specialty Minerals (Australia)
  ('1e85e8fa-4dba-40fa-ae0a-819b08bafdd4'::uuid, '⭐⭐ Canadian satellite/cross-border supply'),  -- Specialty Minerals (Canada)
  ('4986266c-fe4b-4c45-98f6-6ebf07f58c6c'::uuid, '⚠️ NO direct Korea operations - imports only via trading houses'),  -- Specialty Minerals (Korea)
  ('98daf450-5ee1-4ff8-9143-07b6928e147d'::uuid, 'Theoretical only; no Malaysia commercial entity'),  -- Specialty Minerals (Malaysia)
  ('939c9bcc-9f01-4394-b66e-886def63bde9'::uuid, '⭐⭐ Brazil + Mexican cross-border'),  -- Specialty Minerals (Mexico)
  ('f644544d-bced-4938-818d-f1d8026dce61'::uuid, '⭐ MM Kwidzyn (구 IP) historical 관계 verification critical'),  -- Specialty Minerals (Poland)
  ('b2cd5da3-ddca-45a1-ac91-9c577f46d8e6'::uuid, '⚠️ Historical A-grade announcements vs current C-grade public evidence'),  -- Specialty Minerals (Thailand)
  ('da2b4748-187f-4201-942b-cec65243388a'::uuid, 'EU-wide; Turkish satellite verification needed'),  -- Specialty Minerals (Turkey)
  ('fa423be1-6482-4147-beae-179d118f48d9'::uuid, 'PCC satellite의 발상지. 미국 paper-mineral 산업의 본거지'),  -- Specialty Minerals (USA - Regional HQ)
  ('4b369bdb-0695-427d-89bf-ffaf9da79186'::uuid, '❌ No Vietnam linkage — unique gap vs other Asian markets'),  -- Specialty Minerals (Vietnam)
  ('7683abf7-d054-4ca9-9125-fe4d768b54db'::uuid, 'Top-tier Asia-Pacific Omya JV; covers fine/specialty papers'),  -- Surint Omya Chemicals (Thailand) / Omya
  ('f1fa65ef-99de-461d-831f-717f517ba932'::uuid, 'Local mineral vendor; needs verification for paper sector'),  -- TH Materials
  ('45d93ac1-41a4-4207-acc1-896c1300a3b2'::uuid, '미국 paper kaolin leader (post-2022 Imerys 인수)'),  -- Thiele Kaolin Company
  ('a8fda5c6-4def-4200-bac0-83adb435bd63'::uuid, 'Domestic supplier with explicit paper-sector positioning'),  -- TLD Vietnam
  ('331739e4-87fa-4582-ab37-7665c45b912b'::uuid, 'Potential local GCC candidate; paper linkage needs verification'),  -- Uniko Calcium Carbonate Industry Sdn Bhd
  ('bf627e0b-186b-4597-b43f-bf6c434bba02'::uuid, 'Strong domestic fit for alkaline papermaking'),  -- VSV Group
  ('ea39bb0c-639e-44be-a84c-a586f88e3cb5'::uuid, 'Top domestic supplier with paper-explicit positioning')  -- Zantat Sdn Bhd
) as d(party_id, note)
where f.party_id = d.party_id
  and (f.notes is null or f.notes not like '%[ex-website-note 2026-06-20]%');

-- B) set verified websites (fills nulls / overwrites preserved notes)
update app.parties p
set website = d.url, updated_at = now()
from (values
  ('85249ecd-c58c-499c-b7df-3cd505c742e4'::uuid, 'https://www.anadolumikronize.com.tr'),  -- Anadolu Mikronize (ANDCARB)
  ('a29c3014-b274-475a-a0c0-3b04ea7f1aa8'::uuid, 'https://www.calidra.com'),  -- Calidra (Grupo Calidra)
  ('fd4b2bcf-58ac-4993-a848-ba3b47cbcf55'::uuid, 'https://www.carmeuse.com'),  -- Carmeuse Canada
  ('d08ba3a8-976f-4e95-83cc-3c45559ac2f4'::uuid, 'https://www.carmeuse.com'),  -- Carmeuse Mexico
  ('1406738e-b384-43d1-bf0f-0654ca1ab792'::uuid, 'https://www.graymont.com'),  -- Graymont
  ('e575dd34-d48e-4742-a44b-e5d24920dc2f'::uuid, 'https://www.imifabi.com'),  -- IMI Fabi
  ('55b9c376-49fd-4179-9277-1d4e1c7df03b'::uuid, 'https://www.lhoist.com'),  -- Lhoist Polska
  ('2a4a6b46-4a82-4cb7-b56e-b9846c4e104c'::uuid, 'https://www.mikrons.com.tr'),  -- Mikron-S Mikronize Mineral (TURKCARB)
  ('cbde4480-031d-4836-b7bb-a9b5a335b7cb'::uuid, 'https://www.mississippilime.com'),  -- Mississippi Lime Company (MLC)
  ('38fa015e-204d-4cc9-83ea-b31091da6123'::uuid, 'https://www.nigtas.com'),  -- Niğtaş Group
  ('33d5aa0b-2cf8-4b73-842f-873f2a85312d'::uuid, 'https://www.nordkalk.com'),  -- Nordkalk
  ('988b7f5c-40fb-487d-ac4e-1d432007f8e9'::uuid, 'https://www.omya.com'),  -- Omya (Australia)
  ('d8445277-2fae-4a2a-abcf-f37410c6391c'::uuid, 'https://www.omya.com'),  -- Omya (Brazil)
  ('b252f5e1-c082-4772-ada2-0d56bd615ef0'::uuid, 'https://www.omya.com'),  -- Omya (Canada)
  ('a1da894d-e839-4a65-8522-fba822320c12'::uuid, 'https://www.omya.com'),  -- Omya (China)
  ('c2771490-e54e-4468-b3be-82a101903a29'::uuid, 'https://www.omya.com'),  -- Omya (India)
  ('fac3df6e-875a-4cc3-97d4-fbb0ca10dd7f'::uuid, 'https://www.omya.com'),  -- Omya (Korea)
  ('fbca4410-7bb9-4ec4-8d17-5adb39e1c38d'::uuid, 'https://www.omya.com'),  -- Omya (Malaysia)
  ('19d167eb-84d0-4914-9af2-8ac5bf8dc708'::uuid, 'https://www.omya.com'),  -- Omya (Mexico)
  ('8f10519d-75ac-49f2-b4ce-587b47accdf6'::uuid, 'https://www.omya.com'),  -- Omya (Poland)
  ('8743619a-7370-4dfe-b39c-545d6069020a'::uuid, 'https://www.omya.com'),  -- Omya (Thailand)
  ('f2322eb8-9971-41b4-993d-35a7c05a6fbc'::uuid, 'https://www.omya.com'),  -- Omya (Turkey)
  ('3bccf3f8-8b1e-43af-9fdd-049b62af066b'::uuid, 'https://www.omya.com'),  -- Omya (USA)
  ('09ff62ad-8f2c-4e93-8174-48e99fc2c8b0'::uuid, 'https://www.omya.com'),  -- Omya (Vietnam)
  ('3ed78f9d-1c53-46dc-bccf-c916c5f393ac'::uuid, 'https://www.qmin.co.th'),  -- Quality Minerals Public Co., Ltd. (Q-min)
  ('0c151b95-c048-48c5-8b21-350048295904'::uuid, 'https://www.sibelco.com'),  -- Sibelco
  ('5d2e3859-d191-48e5-b0a8-1dfde1783c53'::uuid, 'https://www.sibelco.com'),  -- Sibelco Canada
  ('ffeb9cf5-83f0-4fa4-b91b-3add230b558c'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (Australia)
  ('d9828323-dfb8-4518-9f64-101d5ac0fa90'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (Brazil - São Paulo)
  ('96f2e46e-4fde-40d7-aa53-d976df352f16'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (Brazil)
  ('5ca2d961-2228-481c-a7bd-2744f674e25a'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (Canada - Cornwall)
  ('1e85e8fa-4dba-40fa-ae0a-819b08bafdd4'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (Canada)
  ('e5bdc53e-f60f-4769-8b85-de58d9abe44c'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (China - Beihai)
  ('052d5520-d52a-4ea8-8f0c-54875b0aa723'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (China - Dagang/Tianjin)
  ('14cd2b8e-e805-4c2e-a31f-5568172de4d6'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (China - Dongguan)
  ('ac486a6d-2905-4684-9191-f42a7fa7b0a7'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (China - Henan)
  ('051c8f63-3f03-4baf-8ed8-35593e3ef618'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (China - Nanjing)
  ('b3d13820-813a-4a6c-ab0c-e6fd7035c118'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (China - Nanning)
  ('7afab3d5-07a8-4bf7-bc17-cc0d798025a1'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (China - Quzhou)
  ('1634a616-31c0-4db6-ade9-af470c898fe3'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (China - Rugao)
  ('cec6804b-e716-4702-a43c-244b30b75fd6'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (China - Shouguang)
  ('2ad24bf4-b9c5-4763-aa0f-018dbcc96116'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (China - Suzhou)
  ('d7c75f06-8910-4304-97be-4c6dc252f4a5'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (China - Wuhu)
  ('0d7fddd8-32b5-4f08-bacb-9dbdf816b019'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (China - Yanzhou)
  ('10a63afb-d1cf-4076-9d84-dcc44b7752b3'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (China - Zhejiang)
  ('1e0439a9-1261-4635-b76e-64f30db7ec05'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (China - Zhenjiang)
  ('0bb0e5c1-2b0f-4bf9-9fbb-d01851290024'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (China)
  ('ee500a51-16ab-425b-81b6-1d30b0cc495e'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (Finland - Äänekoski)
  ('357f7c13-3ff2-4671-8e16-925521035099'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (Finland - Oulu/Kajaani)
  ('116db4e9-e7af-4a0c-b01f-fb950b9cd326'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (Finland - Tervakoski)
  ('e7eb801b-4cdf-4955-98d9-d7cbf7c658ec'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (France - Arches)
  ('992ce57b-edcc-411e-b396-1a6d5ff5bd17'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (France - Saillat-sur-Vienne)
  ('a164b6e8-e8ee-422c-892d-5b7a3622bf8f'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (France - Saillat)
  ('12332f5f-dce5-42ae-99b1-c559bbf1d6f6'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (Germany - Stockstadt)
  ('91e60359-f0e1-4127-8e78-a4557a937587'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (India - Ballarshah)
  ('3d08331e-2041-4c7f-b4a4-bcc0e4a09915'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (India - Bhiwadi)
  ('53b4f1fe-7d61-4ea4-bfd9-70daf624cae0'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (India - Dandeli)
  ('7ed2a5a7-f4c8-46f4-a409-1a4e2b8874d2'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (India - Erode)
  ('e6292004-1fb4-4680-ac6e-6ab7b2a61fcd'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (India - Gaganapur)
  ('c2fda98a-04cf-474f-9da8-54c41ca80bac'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (India - Lalkuan)
  ('25dce85a-bd2f-4929-95ca-4eb054bc2160'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (India - Rajahmundry)
  ('45a93fab-a2c0-4726-9a0f-4062f2d06511'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (India - Rayagada)
  ('03badee1-e551-46ba-96f2-adaa84fd6415'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (India - Saila Khurd)
  ('e93bfc9c-ce4e-4d5c-a848-da2946c5bed9'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (India - Songadh)
  ('c62365b8-c3b6-43e7-a87a-3d37d8a2ee92'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (India - Sri Muktsar Sahib)
  ('4334c367-3c77-4765-b0ba-5d9612922225'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (India - Sri Muktsar)
  ('0fa2ec21-379e-4a5c-b076-a01aaaf0accc'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (India - Vapi)
  ('dbc630fc-1d8a-4ab4-b5e9-401bf904779a'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (India)
  ('026684e2-2d91-465d-a30e-403ab4c24707'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (Indonesia - Perawang 1)
  ('55d012e2-1c60-45a7-9046-5e841f1858d3'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (Indonesia - Perawang 2)
  ('df33c002-a174-4539-a5f5-805eaf8c0cf4'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (Indonesia)
  ('48c2bca8-6a49-4f14-82e3-0ca06c75699d'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (Japan)
  ('4986266c-fe4b-4c45-98f6-6ebf07f58c6c'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (Korea)
  ('52f22cbe-44bc-44c8-92f5-5c42f2a580a3'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (Malaysia - Sipitang)
  ('98daf450-5ee1-4ff8-9143-07b6928e147d'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (Malaysia)
  ('939c9bcc-9f01-4394-b66e-886def63bde9'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (Mexico)
  ('f644544d-bced-4938-818d-f1d8026dce61'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (Poland)
  ('4a418304-f0b3-45cd-9322-8687f150aa94'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (Portugal - Figueira da Foz)
  ('e14e5b00-8b6f-4a6d-a22f-acf8486d4a02'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (South Africa - Durban)
  ('c0d910dc-90fc-4778-90e1-7a60553a7ab7'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (Sweden - Hallstavik)
  ('27dadd0f-94c5-4fcc-9030-a872c9719c58'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (Thailand - Prachinburi)
  ('b2cd5da3-ddca-45a1-ac91-9c577f46d8e6'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (Thailand)
  ('da2b4748-187f-4201-942b-cec65243388a'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (Turkey)
  ('9f66ddf8-2322-41b3-9335-235c03215ed4'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (UK - Kemsley Kent)
  ('914f659f-22c9-421d-8e0c-45ea9e39b5dc'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (UK - Lifford Birmingham)
  ('3583bb5f-2c79-4eff-a1ee-f2b2ed0706fe'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (USA - Adams MA)
  ('60fc6697-8991-42f8-8800-6d09a8543d3a'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (USA - Androscoggin ME)
  ('e46b80fa-6d71-48a3-ae3e-fa60877febdb'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (USA - Barretts MT)
  ('182d46db-6ffa-4c8e-a743-085632db6f1e'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (USA - Biron WI)
  ('96b61bfa-a5c2-466a-8951-8c6cf3a6e3bb'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (USA - Bucksport ME)
  ('ae7d3254-0e50-4c63-96f5-8caa382bf79f'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (USA - Canaan CT)
  ('5455bfb0-51d1-4eb6-94a8-b76b86facb9b'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (USA - Chillicothe OH)
  ('6292bb71-cf6e-4996-87a8-9e5ebc80c394'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (USA - Cougar WA)
  ('aab05ecf-b32e-4720-a384-1b40b28db105'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (USA - Escanaba MI)
  ('6a793f2f-a07e-4923-a99f-2f98e072d136'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (USA - Jay ME)
  ('c329a89c-52c5-453b-b365-588d51fb9e46'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (USA - Lifford AL)
  ('63910bab-7ce7-4213-8e61-814c743d99c2'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (USA - Lucerne Valley CA)
  ('7623d7fc-7bfd-4342-bcba-8460ed83b7bf'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (USA - Mobile AL)
  ('fa423be1-6482-4147-beae-179d118f48d9'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (USA - Regional HQ)
  ('81b5fd3d-cee0-4d35-b648-d541821cd3b9'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (USA - Rumford ME)
  ('3333b457-a223-4f42-b0bc-961e902201df'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (USA - Sartell MN)
  ('d080e4b2-58d4-44b0-afa6-b020d7a50401'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (USA - Spring Grove PA)
  ('2ec3cca2-fecc-477e-8820-b069f7a50cdc'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (USA - Ste. Genevieve MO)
  ('b3499eb5-46d9-4374-b7af-c4d906a04837'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (USA - Ticonderoga NY)
  ('b49cd54c-fa4d-41f0-89f4-f52f8bd59ccd'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (USA - Wickliffe KY)
  ('7a7d2a03-a727-4a5d-afd4-ec227fe6faec'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (USA - Wisconsin Rapids WI)
  ('4b369bdb-0695-427d-89bf-ffaf9da79186'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals (Vietnam)
  ('25c1a913-dd52-4eb2-8d63-37d76b8a4e23'::uuid, 'https://www.mineralstech.com'),  -- Specialty Minerals FMT (Japan - Shiraoi, Hokkaido)
  ('7683abf7-d054-4ca9-9125-fe4d768b54db'::uuid, 'https://www.omya.com'),  -- Surint Omya Chemicals (Thailand) / Omya
  ('45d93ac1-41a4-4207-acc1-896c1300a3b2'::uuid, 'https://www.thielekaolin.com'),  -- Thiele Kaolin Company
  ('ea39bb0c-639e-44be-a84c-a586f88e3cb5'::uuid, 'https://www.zantat.com.my')  -- Zantat Sdn Bhd
) as d(party_id, url)
where p.id = d.party_id
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and p.party_type_id = 3
  and (p.website is null or p.website not ilike 'http%');

-- C) clear leftover embedded notes from website col for rows with no verified URL
--    (note already preserved in step A; only fires when the tag is present)
update app.parties p
set website = null, updated_at = now()
from app.filler_supplier_profile f
where p.id = f.party_id
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and p.party_type_id = 3
  and (p.website is not null and p.website not ilike 'http%')
  and f.notes like '%[ex-website-note 2026-06-20]%';

-- verify
select
  count(*) filter (where website ilike 'http%') as with_url,
  count(*) filter (where website is not null and website not ilike 'http%') as still_noteish,
  count(*) filter (where website is null) as null_url,
  count(*) as total
from app.parties
where party_type_id = 3
  and organization_id = 'b25de8f2-1020-482f-9012-183f63883169';
