-- ===========================================================================
--  update_20260915c_party_websites_verified.sql
--  URM - website domains I can state with confidence
-- ---------------------------------------------------------------------------
--  !! SUPABASE SQL EDITOR: press Ctrl+A (SELECT ALL) BEFORE pressing Run. !!
-- ---------------------------------------------------------------------------
--  61 of 156 rows. Only firms whose domain is unambiguous are here; everything
--  I was not sure about was left out entirely rather than guessed, and is
--  listed in party_websites_to_research.csv for a lookup pass.
--
--  TWO RULES APPLIED
--    Corporate venture arms point at the PARENT domain, because that is where
--    their mail comes from. BASF VC was dropped at the gate precisely because
--    its site is basf-vc.com while its investment manager writes from
--    basf.com. TDK Ventures is the exception - it really does run its own.
--
--    University investment offices point at the university domain, since staff
--    write from there (yale.edu, stanford.edu, nd.edu).
--
--  These become whitelist rules when you re-run
--  migration_20260915k_whitelist_directory.sql.
--
--  IDEMPOTENT: safe to re-run.
-- ===========================================================================

update app.parties p
   set website = v.website,
       updated_at = now()
  from (values
    ('a16zcrypto.com', '0cf9f089-d7cc-41fb-937b-340eef4f79cc'::uuid),  -- [US] a16z crypto
    ('adia.ae', '7feff29e-fb3b-4ac0-bdfc-a8073a28b42f'::uuid),  -- [AE] Abu Dhabi Investment Authority (ADIA)
    ('baylor.edu', '9cbd1770-3e57-4691-9929-b981dc107777'::uuid),  -- [US] Baylor Angel Network
    ('bezosexpeditions.com', '81cf3c14-cd93-47e0-9752-baf1bf634689'::uuid),  -- [US] Bezos Expeditions
    ('bp.com', '524f4f86-9e6e-41cc-bf5f-bfcc243428dc'::uuid),  -- [US] BP Ventures
    ('cantor.com', 'b278cad1-4202-4ee7-9a99-e5fd39aab9a6'::uuid),  -- [null] Cantor Fitzgerald (Cantor Equity Partners)
    ('caterpillar.com', '71af30ff-97f4-4d4a-bf77-4908ecc85796'::uuid),  -- [US] Caterpillar Ventures
    ('chevron.com', '3c4ff2a8-106f-4cd6-98bc-25e46af8a733'::uuid),  -- [US] Chevron Technology Ventures
    ('citi.com', '7c23cd3f-8ec6-4180-87ee-e13229e13605'::uuid),  -- [US] Citi Ventures
    ('cppinvestments.com', '1c4f3b31-46a5-4084-ae5e-56bd6e024e45'::uuid),  -- [CA] CPP Investments
    ('dcvc.com', '9b7a4a3f-1b8a-4758-b630-c01721f0aa16'::uuid),  -- [US] DCVC (Data Collective)
    ('dcvc.com', '8201403b-ea64-4935-946a-a1f4bbf17b15'::uuid),  -- [US] DCVC Bio
    ('dumac.duke.edu', 'f4aad4df-1793-4b44-a114-e18de8b6c3fe'::uuid),  -- [US] DUMAC (Duke University)
    ('emersoncollective.com', 'dbd0b2e0-9898-4435-9c45-65a8841be205'::uuid),  -- [US] Emerson Collective
    ('encapinvestments.com', 'aced0be2-d6ca-441b-8769-75c817ceb44c'::uuid),  -- [US] EnCap Investments
    ('gic.com.sg', '35250171-c9ee-41bc-b4ac-7d132b4b078f'::uuid),  -- [SG] GIC
    ('hmc.harvard.edu', '0c0a0ac7-a9bd-4407-af46-9204823f8a44'::uuid),  -- [US] Harvard Management Company
    ('henkel.com', '0b428ec6-349e-468b-a8bd-b3bec5689d67'::uuid),  -- [null] Henkel Tech Ventures
    ('kkr.com', 'c09c2516-98a6-4a94-a202-604cef5e2d41'::uuid),  -- [US] KKR Global Impact Fund
    ('lcatterton.com', '889e68ef-941f-4ab6-9c9c-4bead2fdb314'::uuid),  -- [null] L Catterton
    ('loreal.com', '9bdfecc4-4847-407b-b7a2-b157c3795271'::uuid),  -- [null] L'Oréal BOLD
    ('lererhippeau.com', '11c05899-85c0-4e10-af56-b58ac959281f'::uuid),  -- [null] Lerer Hippeau
    ('marubeni.com', '07ac5aba-f59a-4fb1-935c-f084b417b5cd'::uuid),  -- [JP] Marubeni Ventures
    ('mitimco.org', '5f6ddd3d-4645-415f-97a6-2a7cc7419224'::uuid),  -- [US] MIT Investment Management Company (MITIMCo)
    ('mubadala.com', '5eb22d84-64c0-491d-b98f-d26a762c4c87'::uuid),  -- [AE] Mubadala Investment Company
    ('nbim.no', 'e23f6a72-338c-492b-ae87-419f9e763c5a'::uuid),  -- [NO] Norges Bank Investment Management
    ('nd.edu', 'd3ea5c36-a7e4-4d84-ab64-cb0b88a1790e'::uuid),  -- [US] Notre Dame Investment Office
    ('oxy.com', '7d709c24-5b4c-4c5b-8b8b-098154a47dfc'::uuid),  -- [US] Oxy
    ('princeton.edu', 'a46ec528-adad-484f-9da9-7ddc0a978499'::uuid),  -- [US] Princeton University Investment Company (PRINCO)
    ('pif.gov.sa', 'c1472276-9a05-4c5f-a9ac-12ba85946be5'::uuid),  -- [SA] Public Investment Fund (PIF)
    ('qia.qa', 'a24d277d-095a-4e8b-a4af-705e4ce1824f'::uuid),  -- [QA] Qatar Investment Authority (QIA)
    ('softeq.com', 'a430f0c9-b63d-48e0-81a0-41d629c071a3'::uuid),  -- [US] Softeq Venture Studio
    ('stanford.edu', '0b96892e-720f-41ac-85ec-c65e0abdc566'::uuid),  -- [US] Stanford Management Company
    ('sycamorepartners.com', '0dbbce54-60e6-4dae-bef1-a106013445c2'::uuid),  -- [null] Sycamore Partners
    ('tdk-ventures.com', 'ed077416-c4ab-4aa9-8705-3ec32c9c14b2'::uuid),  -- [US] TDK Ventures
    ('tmc.edu', '671cd69c-d52b-437f-8654-4a5855f73c6a'::uuid),  -- [US] Texas Medical Center Venture Fund
    ('tmc.edu', '7cbe6d33-570f-45b8-bc66-b09cf1e155a5'::uuid),  -- [US] TMC Innovation (TMCi)
    ('utimco.org', '81844c40-6c6f-4be8-9eac-6d3d21e3ebc8'::uuid),  -- [US] UTIMCO (Univ. of Texas / Texas A&M)
    ('gore.com', '4135faa4-5d0e-4989-a65f-4a2291f50172'::uuid),  -- [US] W. L. Gore & Associates Innovation Center
    ('woodside.com', 'b4f2c698-fbff-4005-961b-b8a3c04b2531'::uuid),  -- [US] Woodside Energy
    ('yale.edu', 'c0c855fb-d3b9-43dc-a486-eb2af450c9f7'::uuid),  -- [US] Yale Investments Office
    ('activate.org', 'b7fc6e1e-d70a-4675-a0f4-477209bf315c'::uuid),  -- [US] Activate Houston
    ('cleantechopen.org', '002e4f21-5a10-4787-a7da-290555ef9ad0'::uuid),  -- [null] Cleantech Open
    ('3ds.com', '8870e300-ffc3-449d-a5dc-effa44eeef03'::uuid),  -- [null] Dassault Systemes
    ('digitalwildcatters.com', '7c4eb4ff-491b-4a56-9b43-f75117071343'::uuid),  -- [US] Digital Wildcatters
    ('equinor.com', '489818cd-f2c7-40f2-a6c8-114babcd5b06'::uuid),  -- [null] Equinor
    ('gevernova.com', 'c4d5afb9-76c2-4500-bf7d-305107f4c248'::uuid),  -- [null] GE Vernova
    ('halliburtonlabs.com', 'd97dbe07-11b9-4c15-8ffa-98d04231425f'::uuid),  -- [US] Halliburton Labs
    ('kccworld.co.kr', 'cd155d23-c73f-4d30-b3df-1fb98f0c6a1b'::uuid),  -- [null] KCC Glass
    ('lxhausys.com', '4133c5ce-8c03-4e63-a1b3-0951b1c843e2'::uuid),  -- [null] LX Hausys
    ('masschallenge.org', 'defce8a3-81c9-4f5a-9432-0060cc6e5383'::uuid),  -- [US] MassChallenge Texas
    ('mitsubishielectric.com', 'a033393a-3d78-4fb6-b31f-d24c3f459017'::uuid),  -- [null] Mitsubishi Electric Automation
    ('nsf.gov', '8ecf7ba5-83dc-498b-be7f-c3d81014700b'::uuid),  -- [null] National Science Foundation (NSF)
    ('puffer.com', '3fbd072a-45f1-4a61-90f5-e2107cd973d4'::uuid),  -- [null] Puffer-Sweiven
    ('rice.edu', '3226328a-9798-49be-8865-e679fee4f4b8'::uuid),  -- [US] Rice Business Plan Competition
    ('sangetsu.co.jp', '245b1ef9-6536-4cf0-8011-e7aa0e8df5ba'::uuid),  -- [null] Sangetsu
    ('teknorapex.com', '9962e918-461e-49ad-8ed9-0be071ab4427'::uuid),  -- [null] Teknor Apex
    ('uh.edu', 'c4a66a89-1afd-4ee9-ace2-53977251b3ec'::uuid),  -- [US] UH Technology Bridge
    ('vescom.com', 'ccf52993-6f1a-44d9-b13b-0dbd7eb0783f'::uuid),  -- [null] Vescom
    ('withum.com', '15f644f7-2807-4592-8a3d-d3a75daf8517'::uuid),  -- [null] Withum/USI
    ('wolfgordon.com', '0fd938c0-feee-4b9f-b4d4-6aea060a0df4'::uuid)   -- [null] Wolf-Gordon
  ) as v(website, party_id)
 where p.id = v.party_id
   and p.deleted_at is null;

-- ---------------------------------------------------------------------------
-- VERIFY 1 - what is left
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

-- ---------------------------------------------------------------------------
-- VERIFY 2 - domains shared by more than one party. dcvc.com and tmc.edu are
-- expected; anything else is worth a second look.
-- ---------------------------------------------------------------------------
select lower(p.website) as domain, count(*) as parties, string_agg(p.party_name, ' | ')
from app.parties p
join app.party_types t on t.id = p.party_type_id
where p.deleted_at is null
  and t.code in ('investor', 'partner')
  and coalesce(p.website, '') <> ''
group by domain
having count(*) > 1
order by parties desc;
