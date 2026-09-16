-- ===========================================================================
--  update_20260915d_party_websites_final.sql
--  URM - website domains for the investors / partners that had none
-- ---------------------------------------------------------------------------
--  !! SUPABASE SQL EDITOR: press Ctrl+A (SELECT ALL) BEFORE pressing Run. !!
-- ---------------------------------------------------------------------------
--  68 rows. Values come from the researched list; https:// and www. are
--  stripped and the format is validated, so every value here is a bare domain.
--
--  Rows left blank in the source file are simply absent from this statement -
--  nothing is written for them, so re-running is safe and you can append more
--  later.
--
--  NEXT: re-run sql/migration_20260915k_whitelist_directory.sql to turn these
--  domains into mail whitelist rules.
--
--  IDEMPOTENT: safe to re-run.
-- ===========================================================================

update app.parties p
   set website = v.website,
       updated_at = now()
  from (values
    ('11tribes.vc', '9162e68b-27d9-4527-b564-496101c9b3dc'::uuid),  -- [US] 11 Tribes Ventures
    ('ajuib.co.kr', '71cb01d9-a567-4be3-9060-ecd0a2f5bd69'::uuid),  -- [KR] Aju IB Investment
    ('amplovc.com', '1e2d0b88-5be4-4341-a68e-54e0ef50aad7'::uuid),  -- [US] Amplo Ventures
    ('antares.ventures', 'f527182c-6707-4f0c-b6f4-a65b0f3f7e02'::uuid),  -- [US] Antares Ventures
    ('artemisenergypartners.com', '799dec6a-9c74-463d-b590-d4a86773887b'::uuid),  -- [US] Artemis Energy Partners
    ('barshopventures.com', '57f82c4a-a809-437a-b60b-7733981526e3'::uuid),  -- [US] Barshop Ventures
    ('bigbasincapital.com', 'b409c2b6-2129-4713-b044-ef234f9f6c7a'::uuid),  -- [US] Big Basin Capital
    ('collateralgood.eu', '826d7930-52a2-475c-92d7-a8c598453f98'::uuid),  -- [CH] Collateral Good
    ('cottonwood.vc', 'd18b17c8-d001-4e36-941c-458219c462a3'::uuid),  -- [US] Cottonwood Venture Partners
    ('bauer.uh.edu', '4cb0f4fc-da35-4fc6-b301-2eda15ec606c'::uuid),  -- [US] Cougar Fund
    ('decarbpartners.com', '5e3c3189-17d0-40a1-8505-a6dcc07a7774'::uuid),  -- [US] Decarbonization Partners
    ('eclipticcapital.com', '1e335003-368e-4537-b5ed-7e53cb45a4b8'::uuid),  -- [US] Ecliptic Capital
    ('energyinnovationcapital.com', 'd61df9fe-8549-4ed5-a7c4-32211881d0ad'::uuid),  -- [US] Energy Innovation Capital
    ('fiftyyears.com', '94b7d115-2874-4947-87b8-eaa5731b93e1'::uuid),  -- [--] Fifty Years
    ('firebrandvc.com', 'de9f6ecc-e8b1-463a-acc3-b56aea5713ba'::uuid),  -- [US] Firebrand Ventures
    ('fitzgate.com', '8c724efc-1d52-439b-80b9-3ee3da1b0e36'::uuid),  -- [US] Fitz Gate Ventures
    ('geekdomfund.com', 'ca52f2d7-81b4-4701-a7c5-3e119cdf9e7d'::uuid),  -- [US] Geekdom Fund
    ('genesis-park.com', '347f1245-62bd-4784-83e2-d0cbb5f0fe9d'::uuid),  -- [US] Genesis Park
    ('glventures.com', 'a7734597-19ac-4fe7-9b33-3fbc461cadf7'::uuid),  -- [CN] GL Ventures
    ('goldcrest.com', '6c5e6595-9619-4a90-ab9c-7cc2c6b177a2'::uuid),  -- [US] Goldcrest Capital
    ('gpgventures.com', '3fb67384-00cf-4982-ab2b-47bf5303b583'::uuid),  -- [US] Green Park & Golf Ventures
    ('hennessycapitalgroup.com', 'deaa81b6-2cc2-4b0b-8e42-31f8ac738c8f'::uuid),  -- [--] Hennessy Capital Group
    ('techv.co.jp', '3f135f04-e0fc-4b31-bfce-8a9fc1d718e5'::uuid),  -- [JP] Itochu Technology Ventures
    ('kaleo.vc', '4a68712c-aca5-43a6-98a5-13a1d60d0f6a'::uuid),  -- [US] Kaleo Ventures
    ('knightsgateventures.com', '9a671779-0e22-4bf8-9734-7e3aca6c0db4'::uuid),  -- [US] Knightsgate Ventures
    ('koloninvest.com', 'e6efdf11-11c0-49c4-a438-438824bcdf83'::uuid),  -- [KR] Kolon Investment
    ('lmntventures.com', '2e7048a4-f460-45cb-bbf7-b4a438df14b4'::uuid),  -- [US] LMNT Ventures
    ('mccombsenterprises.com', '337377c4-0e06-4600-a15a-3264083c37db'::uuid),  -- [US] McCombs Enterprises
    ('mitsui-global.com', 'be50c733-c8cf-4dfa-92fa-46be8b16e47a'::uuid),  -- [US] Mitsui & Co. Global Investment
    ('montroselane.com', '655a4ef2-4acc-4c11-a384-f4575652116e'::uuid),  -- [US] Montrose Lane
    ('oup.vc', '6d431bda-9529-4855-a2a0-2aa5ad8df4a3'::uuid),  -- [US] Osage University Partners
    ('overlaycapital.com', 'e99df0a8-fab0-495e-bedd-0cc7cc881158'::uuid),  -- [US] Overlay Capital
    ('overture.vc', 'd3367475-c36c-458b-9727-e8cbb71f4579'::uuid),  -- [US] Overture VC
    ('ponderosavc.com', '27154c63-4df3-4bb6-9de9-2d260aefb302'::uuid),  -- [US] Ponderosa Ventures
    ('primersazze.com', '86208524-e7a4-4596-91a3-f633527695fb'::uuid),  -- [US] Primer Sazze Partners
    ('redhouseassociates.com', 'e9340759-8a77-4e57-89fa-5e8677d1203e'::uuid),  -- [US] RedHouse Associates
    ('revtechventures.com', '492d5db7-bc24-44bd-abe9-c1fb9415affc'::uuid),  -- [US] RevTech Ventures
    ('rhapsodyvp.com', '856c9254-945f-4e42-9655-93722d64897d'::uuid),  -- [US] Rhapsody Venture Partners
    ('sbvacorp.com', 'be460b09-820b-410d-be29-f31a9abc7f4e'::uuid),  -- [KR] SBVA
    ('seedroundcapital.com', '472659f4-c4f6-46b6-99ea-e269ce05cf00'::uuid),  -- [US] Seed Round Capital
    ('sentiero.vc', 'fdf8ea2c-0510-4720-8e42-4782068290e1'::uuid),  -- [US] Sentiero Ventures
    ('silascapital.com', 'd70bd3cc-37bd-488a-b685-c4a634bdd60e'::uuid),  -- [--] Silas Capital
    ('silentvc.com', '2780ef67-08cf-4b99-8dbb-c7302fbf18b3'::uuid),  -- [US] Silent Ventures
    ('pearl-energy.com', 'e861958b-ebc5-4255-b0c8-45a3e45efd41'::uuid),  -- [--] Spring Valley Acquisition (Pearl Energy)
    ('strongvc.com', '0adf0feb-e284-49ef-829a-2641cb33883c'::uuid),  -- [US] Strong Ventures
    ('supplychange.fund', 'b0ab4508-6555-4ce0-9cbd-4712cb9a32fa'::uuid),  -- [US] Supply Change Capital
    ('tengelmann-ventures.com', '93b97e33-b53a-4f9b-ba51-3f0e1fc28519'::uuid),  -- [DE] Tengelmann Ventures
    ('texashalofund.com', 'f8c4b3c7-4cc3-49fd-b7a1-b2d5a547f227'::uuid),  -- [US] Texas HALO Fund
    ('houston.tie.org', '4441b9a5-a6ce-4864-9bce-3295f3dfdbf7'::uuid),  -- [US] TiE Houston
    ('tvp.vc', '77178b81-e52a-48f5-bf61-ea4694ab627f'::uuid),  -- [US] Trammell Venture Partners
    ('truewealthvc.com', '817477ae-3521-4afc-9f3f-f586e7d2605a'::uuid),  -- [US] True Wealth Ventures
    ('tupperlakepartners.com', '324e271a-b4af-4374-9435-d70ac349f0e2'::uuid),  -- [US] Tupper Lake Partners
    ('ucop.edu', '7e6f7bdf-8424-48a5-a785-c2eedc8c9a1c'::uuid),  -- [US] UC Investments
    ('vcfuel.com', '9613a6a3-e18f-4b8e-a71a-6b2058e13378'::uuid),  -- [US] VC Fuel
    ('ventioneers.com', '7e71c100-423d-414d-9878-6df6d8f4b288'::uuid),  -- [US] Ventioneers
    ('willoughbycapital.com', 'de6cb14f-8466-4c5a-ac86-108026b1a04f'::uuid),  -- [US] Willoughby Capital
    ('workamericacapital.com', '6f41959a-9f7e-4824-87c5-462ba6c6a7ce'::uuid),  -- [US] Work America Capital
    ('biowell.ai', '9b428bb7-b818-4abe-92ab-6bc2c23a2001'::uuid),  -- [US] BioWell
    ('austintexas.gov', '0d86a209-6008-4a92-94fc-9db7d9e4739d'::uuid),  -- [--] Circular Austin Showcase
    ('energytechnexus.com', '4cb5f7bf-200c-4d84-8d5f-7efd90f3217b'::uuid),  -- [US] Energy Tech Nexus
    ('htxenergytransition.org', 'fff38d6a-7e46-46c9-90c4-179804435bdd'::uuid),  -- [US] Houston Energy Transition Initiative
    ('houstonexponential.com', 'b98a8bed-1a71-495e-a328-9b97d7ce1f34'::uuid),  -- [US] Houston Exponential
    ('houston.org', '6aa94c9f-5a29-43f6-8d1b-1064808315b4'::uuid),  -- [US] Houston Next: Advancing Opportunity
    ('lentexwallcoverings.com', '66fda9ba-fe9a-4b75-9142-3605e62544a7'::uuid),  -- [--] Len-Tex
    ('mdcwall.com', '1f96bcf6-03eb-4d29-8805-88f4e68944d4'::uuid),  -- [--] MDC Wallcoverings
    ('momentumco.com', '450bbd3b-4499-42a7-85fd-43b5a3e0c46d'::uuid),  -- [--] Momentum Textiles & Wallcovering
    ('tex-e.org', '250be62d-03db-42ee-924a-2e4c9b23fffc'::uuid),  -- [--] TEX-E
    ('trtf.com', 'a4182dd0-1368-4589-a889-4fd34d21d093'::uuid)   -- [US] Texas Research and Technology Foundation
  ) as v(website, party_id)
 where p.id = v.party_id
   and p.deleted_at is null;

-- ---------------------------------------------------------------------------
-- VERIFY 1 - what is still missing
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
-- VERIFY 2 - domains now shared by more than one party. dcvc.com and tmc.edu
-- are expected. An unexpected pair means one of the values is wrong.
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
