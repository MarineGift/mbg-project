-- ===========================================================================
--  update_20260915_party_websites.sql
--  URM - fill in the missing investor / partner website domains
-- ---------------------------------------------------------------------------
--  !! SUPABASE SQL EDITOR: press Ctrl+A (SELECT ALL) BEFORE pressing Run. !!
-- ---------------------------------------------------------------------------
--  HOW TO USE
--    Type the domain between the quotes on each line - bare domain, no
--    https:// and no www (the whitelist migration strips those anyway, but a
--    clean value keeps the directory readable):
--
--        ('a16zcrypto.com',  '0cf9f089-...'),   -- a16z crypto
--
--    Leave a line as '' if you cannot find the site. Rows with an empty value
--    are skipped by the WHERE clause, so you can run this repeatedly as you
--    work through the list.
--
--    Then re-run sql/migration_20260915k_whitelist_directory.sql to turn the
--    new domains into whitelist rules.
--
--  CAVEAT worth remembering
--    A corporate VC often sends mail from the PARENT domain while its site is
--    a separate brand - BASF Venture Capital writes from basf.com but its site
--    is basf-vc.com. Filling the website does NOT cover that case; add the
--    sending domain to app.email_whitelist separately when you hit one.
--
--  IDEMPOTENT: safe to re-run.
-- ===========================================================================

update app.parties p
   set website = v.website,
       updated_at = now()
  from (values
    ('', '9162e68b-27d9-4527-b564-496101c9b3dc'::uuid),  -- [US] 11 Tribes Ventures
    ('', '0cf9f089-d7cc-41fb-937b-340eef4f79cc'::uuid),  -- [US] a16z crypto
    ('', '7feff29e-fb3b-4ac0-bdfc-a8073a28b42f'::uuid),  -- [AE] Abu Dhabi Investment Authority (ADIA)
    ('', '71cb01d9-a567-4be3-9060-ecd0a2f5bd69'::uuid),  -- [KR] Aju IB Investment
    ('', 'ce20dbfa-615e-4a50-816e-3fd30a67169b'::uuid),  -- [US] Alliance of Texas Angel Networks
    ('', '1e2d0b88-5be4-4341-a68e-54e0ef50aad7'::uuid),  -- [US] Amplo Ventures
    ('', 'f527182c-6707-4f0c-b6f4-a65b0f3f7e02'::uuid),  -- [US] Antares Ventures
    ('', '799dec6a-9c74-463d-b590-d4a86773887b'::uuid),  -- [US] Artemis Energy Partners
    ('', '57f82c4a-a809-437a-b60b-7733981526e3'::uuid),  -- [US] Barshop Ventures
    ('', '9cbd1770-3e57-4691-9929-b981dc107777'::uuid),  -- [US] Baylor Angel Network
    ('', '81cf3c14-cd93-47e0-9752-baf1bf634689'::uuid),  -- [US] Bezos Expeditions
    ('', 'b409c2b6-2129-4713-b044-ef234f9f6c7a'::uuid),  -- [US] Big Basin Capital
    ('', '524f4f86-9e6e-41cc-bf5f-bfcc243428dc'::uuid),  -- [US] BP Ventures
    ('', 'bb187b5d-8333-4ee7-9acc-10e4f54c7443'::uuid),  -- [null] Brock Adler
    ('', '4106f761-b189-4822-9a77-8aee1187526c'::uuid),  -- [null] C3 Geoscience Consulting
    ('', 'b278cad1-4202-4ee7-9a99-e5fd39aab9a6'::uuid),  -- [null] Cantor Fitzgerald (Cantor Equity Partners)
    ('', 'ad5e0008-6ca2-4c0b-b558-1579d2a048ca'::uuid),  -- [US] Cascade Investment
    ('', '71af30ff-97f4-4d4a-bf77-4908ecc85796'::uuid),  -- [US] Caterpillar Ventures
    ('', '81cbe4b7-a187-4645-86d1-360204638c26'::uuid),  -- [null] CCE Advisory
    ('', '3c4ff2a8-106f-4cd6-98bc-25e46af8a733'::uuid),  -- [US] Chevron Technology Ventures
    ('', '7c23cd3f-8ec6-4180-87ee-e13229e13605'::uuid),  -- [US] Citi Ventures
    ('', '826d7930-52a2-475c-92d7-a8c598453f98'::uuid),  -- [CH] Collateral Good
    ('', 'd18b17c8-d001-4e36-941c-458219c462a3'::uuid),  -- [US] Cottonwood Venture Partners
    ('', '4cb0f4fc-da35-4fc6-b301-2eda15ec606c'::uuid),  -- [US] Cougar Fund
    ('', '1c4f3b31-46a5-4084-ae5e-56bd6e024e45'::uuid),  -- [CA] CPP Investments
    ('', '9b7a4a3f-1b8a-4758-b630-c01721f0aa16'::uuid),  -- [US] DCVC (Data Collective)
    ('', '8201403b-ea64-4935-946a-a1f4bbf17b15'::uuid),  -- [US] DCVC Bio
    ('', '5e3c3189-17d0-40a1-8505-a6dcc07a7774'::uuid),  -- [US] Decarbonization Partners
    ('', 'c6a32f22-e8de-441b-8989-54da84f52c85'::uuid),  -- [US] Deep Space Ventures
    ('', 'f4aad4df-1793-4b44-a114-e18de8b6c3fe'::uuid),  -- [US] DUMAC (Duke University)
    ('', '1e335003-368e-4537-b5ed-7e53cb45a4b8'::uuid),  -- [US] Ecliptic Capital
    ('', 'dbd0b2e0-9898-4435-9c45-65a8841be205'::uuid),  -- [US] Emerson Collective
    ('', 'aced0be2-d6ca-441b-8769-75c817ceb44c'::uuid),  -- [US] EnCap Investments
    ('', 'd61df9fe-8549-4ed5-a7c4-32211881d0ad'::uuid),  -- [US] Energy Innovation Capital
    ('', '94b7d115-2874-4947-87b8-eaa5731b93e1'::uuid),  -- [null] Fifty Years
    ('', 'de9f6ecc-e8b1-463a-acc3-b56aea5713ba'::uuid),  -- [US] Firebrand Ventures
    ('', '8c724efc-1d52-439b-80b9-3ee3da1b0e36'::uuid),  -- [US] Fitz Gate Ventures
    ('', 'ca52f2d7-81b4-4701-a7c5-3e119cdf9e7d'::uuid),  -- [US] Geekdom Fund
    ('', '347f1245-62bd-4784-83e2-d0cbb5f0fe9d'::uuid),  -- [US] Genesis Park
    ('', '35250171-c9ee-41bc-b4ac-7d132b4b078f'::uuid),  -- [SG] GIC
    ('', 'a7734597-19ac-4fe7-9b33-3fbc461cadf7'::uuid),  -- [CN] GL Ventures
    ('', '6c5e6595-9619-4a90-ab9c-7cc2c6b177a2'::uuid),  -- [US] Goldcrest Capital
    ('', '3fb67384-00cf-4982-ab2b-47bf5303b583'::uuid),  -- [US] Green Park & Golf Ventures
    ('', '0c0a0ac7-a9bd-4407-af46-9204823f8a44'::uuid),  -- [US] Harvard Management Company
    ('', '0b428ec6-349e-468b-a8bd-b3bec5689d67'::uuid),  -- [null] Henkel Tech Ventures
    ('', 'deaa81b6-2cc2-4b0b-8e42-31f8ac738c8f'::uuid),  -- [null] Hennessy Capital Group
    ('', '3b81958e-603b-4091-a74c-0063d0d47ac5'::uuid),  -- [US] Hillspire
    ('', '53219170-f6c8-40de-8434-3171491aaf7e'::uuid),  -- [US] Humba Ventures
    ('', 'b6aa6bf3-09db-48d6-9217-6a717403bc59'::uuid),  -- [US] Hunt Holdings
    ('', '5db46a86-a45a-412d-b7c5-c98c0657f6fe'::uuid),  -- [US] Integr8d Capital
    ('', '3f135f04-e0fc-4b31-bfce-8a9fc1d718e5'::uuid),  -- [JP] Itochu Technology Ventures
    ('', '4f5158be-54c8-46c6-a0a8-07df1d49fc47'::uuid),  -- [US] Jones Capital
    ('', '4a68712c-aca5-43a6-98a5-13a1d60d0f6a'::uuid),  -- [US] Kaleo Ventures
    ('', 'c09c2516-98a6-4a94-a202-604cef5e2d41'::uuid),  -- [US] KKR Global Impact Fund
    ('', '9a671779-0e22-4bf8-9734-7e3aca6c0db4'::uuid),  -- [US] Knightsgate Ventures
    ('', 'e6efdf11-11c0-49c4-a438-438824bcdf83'::uuid),  -- [KR] Kolon Investment
    ('', '889e68ef-941f-4ab6-9c9c-4bead2fdb314'::uuid),  -- [null] L Catterton
    ('', '9bdfecc4-4847-407b-b7a2-b157c3795271'::uuid),  -- [null] L'Oréal BOLD
    ('', '11c05899-85c0-4e10-af56-b58ac959281f'::uuid),  -- [null] Lerer Hippeau
    ('', '2e7048a4-f460-45cb-bbf7-b4a438df14b4'::uuid),  -- [US] LMNT Ventures
    ('', '92fb50cf-c74b-4d74-a71c-677374db3b90'::uuid),  -- [US] LP Capital
    ('', '07ac5aba-f59a-4fb1-935c-f084b417b5cd'::uuid),  -- [JP] Marubeni Ventures
    ('', '8fd7b4ae-73b7-4d33-8fb5-f7876109eef7'::uuid),  -- [null] MBG Mailing Test
    ('', '337377c4-0e06-4600-a15a-3264083c37db'::uuid),  -- [US] McCombs Enterprises
    ('', '5f6ddd3d-4645-415f-97a6-2a7cc7419224'::uuid),  -- [US] MIT Investment Management Company (MITIMCo)
    ('', 'be50c733-c8cf-4dfa-92fa-46be8b16e47a'::uuid),  -- [US] Mitsui & Co. Global Investment
    ('', '655a4ef2-4acc-4c11-a384-f4575652116e'::uuid),  -- [US] Montrose Lane
    ('', '5eb22d84-64c0-491d-b98f-d26a762c4c87'::uuid),  -- [AE] Mubadala Investment Company
    ('', '8b6f6723-2271-46de-9a06-12016821c9ab'::uuid),  -- [US] NextWave Partners
    ('', 'e23f6a72-338c-492b-ae87-419f9e763c5a'::uuid),  -- [NO] Norges Bank Investment Management
    ('', 'd3ea5c36-a7e4-4d84-ab64-cb0b88a1790e'::uuid),  -- [US] Notre Dame Investment Office
    ('', '6d431bda-9529-4855-a2a0-2aa5ad8df4a3'::uuid),  -- [US] Osage University Partners
    ('', 'e99df0a8-fab0-495e-bedd-0cc7cc881158'::uuid),  -- [US] Overlay Capital
    ('', 'd3367475-c36c-458b-9727-e8cbb71f4579'::uuid),  -- [US] Overture VC
    ('', '7d709c24-5b4c-4c5b-8b8b-098154a47dfc'::uuid),  -- [US] Oxy
    ('', 'af2a872d-a1a9-4849-aa75-2e1987e98317'::uuid),  -- [US] Petrus Group (Perot Family Office)
    ('', '27154c63-4df3-4bb6-9de9-2d260aefb302'::uuid),  -- [US] Ponderosa Ventures
    ('', '1aebebda-2a09-4b74-aaab-8b9483daa084'::uuid),  -- [KR] POSCO Venture Capital
    ('', '86208524-e7a4-4596-91a3-f633527695fb'::uuid),  -- [US] Primer Sazze Partners
    ('', 'a46ec528-adad-484f-9da9-7ddc0a978499'::uuid),  -- [US] Princeton University Investment Company (PRINCO)
    ('', 'c1472276-9a05-4c5f-a9ac-12ba85946be5'::uuid),  -- [SA] Public Investment Fund (PIF)
    ('', 'a24d277d-095a-4e8b-a4af-705e4ce1824f'::uuid),  -- [QA] Qatar Investment Authority (QIA)
    ('', 'f0c2b8aa-2562-4377-bdac-d8f74bb6bc89'::uuid),  -- [US] Quake Capital
    ('', 'e9340759-8a77-4e57-89fa-5e8677d1203e'::uuid),  -- [US] RedHouse Associates
    ('', '492d5db7-bc24-44bd-abe9-c1fb9415affc'::uuid),  -- [US] RevTech Ventures
    ('', '856c9254-945f-4e42-9655-93722d64897d'::uuid),  -- [US] Rhapsody Venture Partners
    ('', 'be460b09-820b-410d-be29-f31a9abc7f4e'::uuid),  -- [KR] SBVA
    ('', '50d34512-48ff-4704-bb7c-efef4635b7cb'::uuid),  -- [null] Scott Nyquist
    ('', '47cb0fe4-66ea-4e35-9b2f-69cd1380a15f'::uuid),  -- [US] Seabird Ventures
    ('', '472659f4-c4f6-46b6-99ea-e269ce05cf00'::uuid),  -- [US] Seed Round Capital
    ('', 'fdf8ea2c-0510-4720-8e42-4782068290e1'::uuid),  -- [US] Sentiero Ventures
    ('', 'd70bd3cc-37bd-488a-b685-c4a634bdd60e'::uuid),  -- [null] Silas Capital
    ('', '2780ef67-08cf-4b99-8dbb-c7302fbf18b3'::uuid),  -- [US] Silent Ventures
    ('', '6ebfff98-1d56-4cb0-92fa-8eeaacfb9ee6'::uuid),  -- [null] Sisukas Consulting, LLC
    ('', 'a430f0c9-b63d-48e0-81a0-41d629c071a3'::uuid),  -- [US] Softeq Venture Studio
    ('', 'e861958b-ebc5-4255-b0c8-45a3e45efd41'::uuid),  -- [null] Spring Valley Acquisition (Pearl Energy)
    ('', '0b96892e-720f-41ac-85ec-c65e0abdc566'::uuid),  -- [US] Stanford Management Company
    ('', '3112d7da-adee-4492-acf9-fde61500d83c'::uuid),  -- [null] Stealth VC Fund
    ('', '0adf0feb-e284-49ef-829a-2641cb33883c'::uuid),  -- [US] Strong Ventures
    ('', 'b0ab4508-6555-4ce0-9cbd-4712cb9a32fa'::uuid),  -- [US] Supply Change Capital
    ('', '0dbbce54-60e6-4dae-bef1-a106013445c2'::uuid),  -- [null] Sycamore Partners
    ('', 'ed077416-c4ab-4aa9-8705-3ec32c9c14b2'::uuid),  -- [US] TDK Ventures
    ('', '93b97e33-b53a-4f9b-ba51-3f0e1fc28519'::uuid),  -- [DE] Tengelmann Ventures
    ('', 'f8c4b3c7-4cc3-49fd-b7a1-b2d5a547f227'::uuid),  -- [US] Texas HALO Fund
    ('', '671cd69c-d52b-437f-8654-4a5855f73c6a'::uuid),  -- [US] Texas Medical Center Venture Fund
    ('', '4441b9a5-a6ce-4864-9bce-3295f3dfdbf7'::uuid),  -- [US] TiE Houston
    ('', '7cbe6d33-570f-45b8-bc66-b09cf1e155a5'::uuid),  -- [US] TMC Innovation (TMCi)
    ('', '77178b81-e52a-48f5-bf61-ea4694ab627f'::uuid),  -- [US] Trammell Venture Partners
    ('', '817477ae-3521-4afc-9f3f-f586e7d2605a'::uuid),  -- [US] True Wealth Ventures
    ('', '324e271a-b4af-4374-9435-d70ac349f0e2'::uuid),  -- [US] Tupper Lake Partners
    ('', '7e6f7bdf-8424-48a5-a785-c2eedc8c9a1c'::uuid),  -- [US] UC Investments
    ('', '81844c40-6c6f-4be8-9eac-6d3d21e3ebc8'::uuid),  -- [US] UTIMCO (Univ. of Texas / Texas A&M)
    ('', '29107c16-2a13-444f-8a8b-584f610822a9'::uuid),  -- [US] Valhalla Investment Group
    ('', '9613a6a3-e18f-4b8e-a71a-6b2058e13378'::uuid),  -- [US] VC Fuel
    ('', '7e71c100-423d-414d-9878-6df6d8f4b288'::uuid),  -- [US] Ventioneers
    ('', '8851ac5c-5a12-442a-b013-8b12c7d58016'::uuid),  -- [US] Veritec Ventures
    ('', '4135faa4-5d0e-4989-a65f-4a2291f50172'::uuid),  -- [US] W. L. Gore & Associates Innovation Center
    ('', '37b6063b-77a1-469b-8f40-857978b213bf'::uuid),  -- [US] Wild Basin Investments
    ('', 'de6cb14f-8466-4c5a-ac86-108026b1a04f'::uuid),  -- [US] Willoughby Capital
    ('', 'b4f2c698-fbff-4005-961b-b8a3c04b2531'::uuid),  -- [US] Woodside Energy
    ('', '6f41959a-9f7e-4824-87c5-462ba6c6a7ce'::uuid),  -- [US] Work America Capital
    ('', 'e36d2d40-7c74-4777-b906-b1f3b225e9b3'::uuid),  -- [null] Yael DeCapo
    ('', 'c0c855fb-d3b9-43dc-a486-eb2af450c9f7'::uuid),  -- [US] Yale Investments Office
    ('', 'b7fc6e1e-d70a-4675-a0f4-477209bf315c'::uuid),  -- [US] Activate Houston
    ('', '9b428bb7-b818-4abe-92ab-6bc2c23a2001'::uuid),  -- [US] BioWell
    ('', '0d86a209-6008-4a92-94fc-9db7d9e4739d'::uuid),  -- [null] Circular Austin Showcase
    ('', '002e4f21-5a10-4787-a7da-290555ef9ad0'::uuid),  -- [null] Cleantech Open
    ('', '8870e300-ffc3-449d-a5dc-effa44eeef03'::uuid),  -- [null] Dassault Systemes
    ('', '7c4eb4ff-491b-4a56-9b43-f75117071343'::uuid),  -- [US] Digital Wildcatters
    ('', '4cb5f7bf-200c-4d84-8d5f-7efd90f3217b'::uuid),  -- [US] Energy Tech Nexus
    ('', '489818cd-f2c7-40f2-a6c8-114babcd5b06'::uuid),  -- [null] Equinor
    ('', 'b24ca6a2-2ef0-4d50-8105-175fbc7e06de'::uuid),  -- [null] FCC
    ('', 'c4d5afb9-76c2-4500-bf7d-305107f4c248'::uuid),  -- [null] GE Vernova
    ('', 'd97dbe07-11b9-4c15-8ffa-98d04231425f'::uuid),  -- [US] Halliburton Labs
    ('', 'fff38d6a-7e46-46c9-90c4-179804435bdd'::uuid),  -- [US] Houston Energy Transition Initiative
    ('', 'b98a8bed-1a71-495e-a328-9b97d7ce1f34'::uuid),  -- [US] Houston Exponential
    ('', '6aa94c9f-5a29-43f6-8d1b-1064808315b4'::uuid),  -- [US] Houston Next: Advancing Opportunity
    ('', '418a6a20-73e3-482e-ad60-c8d9d408a8b1'::uuid),  -- [null] Inbound (Slack)
    ('', 'cd155d23-c73f-4d30-b3df-1fb98f0c6a1b'::uuid),  -- [null] KCC Glass
    ('', '66fda9ba-fe9a-4b75-9142-3605e62544a7'::uuid),  -- [null] Len-Tex
    ('', '4133c5ce-8c03-4e63-a1b3-0951b1c843e2'::uuid),  -- [null] LX Hausys
    ('', 'defce8a3-81c9-4f5a-9432-0060cc6e5383'::uuid),  -- [US] MassChallenge Texas
    ('', '1f96bcf6-03eb-4d29-8805-88f4e68944d4'::uuid),  -- [null] MDC Wallcoverings
    ('', 'a033393a-3d78-4fb6-b31f-d24c3f459017'::uuid),  -- [null] Mitsubishi Electric Automation
    ('', '450bbd3b-4499-42a7-85fd-43b5a3e0c46d'::uuid),  -- [null] Momentum Textiles & Wallcovering
    ('', '8ecf7ba5-83dc-498b-be7f-c3d81014700b'::uuid),  -- [null] National Science Foundation (NSF)
    ('', '3fbd072a-45f1-4a61-90f5-e2107cd973d4'::uuid),  -- [null] Puffer-Sweiven
    ('', '3226328a-9798-49be-8865-e679fee4f4b8'::uuid),  -- [US] Rice Business Plan Competition
    ('', '245b1ef9-6536-4cf0-8011-e7aa0e8df5ba'::uuid),  -- [null] Sangetsu
    ('', '9962e918-461e-49ad-8ed9-0be071ab4427'::uuid),  -- [null] Teknor Apex
    ('', '250be62d-03db-42ee-924a-2e4c9b23fffc'::uuid),  -- [null] TEX-E
    ('', 'a4182dd0-1368-4589-a889-4fd34d21d093'::uuid),  -- [US] Texas Research and Technology Foundation
    ('', 'c4a66a89-1afd-4ee9-ace2-53977251b3ec'::uuid),  -- [US] UH Technology Bridge
    ('', 'ccf52993-6f1a-44d9-b13b-0dbd7eb0783f'::uuid),  -- [null] Vescom
    ('', '15f644f7-2807-4592-8a3d-d3a75daf8517'::uuid),  -- [null] Withum/USI
    ('', '0fd938c0-feee-4b9f-b4d4-6aea060a0df4'::uuid)   -- [null] Wolf-Gordon
  ) as v(website, party_id)
 where p.id = v.party_id
   and p.deleted_at is null
   and nullif(trim(v.website), '') is not null;

-- ---------------------------------------------------------------------------
-- VERIFY - how many are still missing after the run
-- ---------------------------------------------------------------------------
select t.code as party_type,
       count(*) filter (where coalesce(nullif(trim(p.website), ''), null) is null) as no_website,
       count(*) as total
from app.parties p
join app.party_types t on t.id = p.party_type_id
where p.deleted_at is null
  and t.code in ('investor', 'partner')
group by t.code
order by no_website desc;