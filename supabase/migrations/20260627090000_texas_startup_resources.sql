-- ============================================================
-- 20260627090000_texas_startup_resources.sql
-- TEXAS startup resources -> app.parties. Source: texas_startup_resources_2017
-- 24 investors (party_type_id=1) + 81 partners (party_types.code='partner') = 105 rows.
-- Built from TX Startup Resources Directory (Gov. of TX, 2017) + handoff scope.
-- Scope = investors + investment-relevant partners (accelerators/universities/angel/funding).
-- Excluded: coworking, makerspaces, arts/culinary incubators, generic SBDC/chamber, event franchises.
-- investor_type_id via coalesce-by-code (vc / angel -> other fallback). sector/geo are text[].
-- investor_sector_focus & investor_stage_focus OMITTED (sector/stage id mapping unknown; in sector_focus array).
-- Mirrors 20260620370015_global_investors_batch7.sql shape. Run as one txn in Supabase SQL Editor.
-- ============================================================

begin;

-- 1a) investors -> app.parties (party_type_id=1)
insert into app.parties (party_type_id, entity_type_id, party_name, status, source, country_code, region, city, website, notes, organization_id)
select 1::smallint, 1::smallint, v.party_name, 'active', 'texas_startup_resources_2017', 'US', 'TX', v.city, v.website, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('Alara Capital','Austin','https://www.alaracap.com','VC; technology, semiconductors, software'),
  ('Aristos Ventures','Dallas','https://www.aristosventures.com','VC; capital-efficient technology, SaaS, security'),
  ('Covera Ventures','Austin','https://www.coveraventures.com','VC; early-stage software, mobile, infrastructure'),
  ('Dallas Venture Partners','Dallas','https://www.dallasventurepartners.com','VC; enterprise SaaS, AgTech, healthcare IT'),
  ('Daylight Partners','Austin','https://www.daylightpartners.com','VC; technology, revenue+product stage'),
  ('Live Oak Venture Partners','Austin','https://www.liveoakvp.com','VC; IT & tech-enabled services'),
  ('Mercury Fund','Houston','https://www.mercuryfund.com','VC; SaaS, cloud, data science (often lead)'),
  ('Naya Ventures','Irving','https://www.nayaventures.com','VC; mobile, cloud, big data'),
  ('Next Step Capital Partners','Austin','https://www.nextstepcapitalpartners.com','VC; revenue-share funding, technology'),
  ('S3 Ventures','Austin','https://www.s3vc.com','VC; IT solutions, enterprise software, medical device'),
  ('Santé Ventures','Austin','https://www.santeventures.com','VC; early-stage life science & healthcare'),
  ('Silverton Partners','Austin','https://www.silvertonpartners.com','VC; seed-Series A technology'),
  ('Trailblazer Capital','Dallas','https://www.trailblazercapital.com','VC; networking, telecom, enterprise software'),
  ('Texo Ventures','Austin','https://www.texoventures.com','VC; early-stage healthcare, medical device/diagnostics'),
  ('Texas Women''s Ventures Capital Management','Dallas','https://www.twvcapital.com','VC; women-owned & women-led, growth'),
  ('Emergent Technologies','Austin','https://www.emergenttechnologies.com','Life-sciences venture firm (also incubator/accelerator)'),
  ('Aggie Angel Network','College Station','https://www.aggieangelnetwork.com','Angel network; early-stage technology'),
  ('Central Texas Angel Network','Austin','https://www.centraltexasangelnetwork.com','Angel network (ATAN/ACA member)'),
  ('Cowtown Angels','Fort Worth','https://www.cowtownangels.org','Angel network; early-stage'),
  ('Dallas Angel Network','Dallas','https://www.dallasangelnetwork.com','Angel network; early-stage'),
  ('Houston Angel Network','Houston','https://www.houstonangelnetwork.org','Angel network; oldest in TX, most active in US'),
  ('North Texas Angel Network','Dallas','https://www.northtexasangels.org','Angel network; early-stage, any industry'),
  ('Tyler Texas Angel Network','Tyler','https://www.tylertexasangelnetwork.com','Angel network; early-stage'),
  ('Wilco Angel Network','Georgetown','https://www.wilcoangelnetwork.org','Angel network (Texas Entrepreneur Networks)')
) as v(party_name, city, website, notes)
where not exists (select 1 from app.parties p where p.party_name=v.party_name and p.deleted_at is null);

-- 1b) partners -> app.parties (party_types.code='partner')
insert into app.parties (party_type_id, entity_type_id, party_name, status, source, country_code, region, city, website, notes, organization_id)
select (select id from app.party_types where code='partner')::smallint, 1::smallint, v.party_name, 'active', 'texas_startup_resources_2017', 'US', 'TX', v.city, v.website, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('3 Day Startup','Austin','https://www.3daystartup.org','Accelerator; multi-industry; founded at UT Austin'),
  ('Accelerated Ventures at Baylor University','Waco','https://www.baylor.edu/business/entrepreneurship','Accelerator; university (Baylor); high tech'),
  ('AccelerateH2O','San Antonio','https://www.imagineh20.org','Accelerator; water technology'),
  ('AccelerateNFC','Richardson','https://www.acceleratenfc.com','Accelerator; near-field communication / high tech'),
  ('Allied Affiliated Funding','Dallas','https://www.fundingbyallied.com','Funding; invoice factoring / asset-based lending'),
  ('The Alliance for Higher Education','Dallas','https://www.ntxrcic.org','Accelerator; high tech; North Texas'),
  ('ATI Clean Energy Incubator at UT Austin','Austin','https://www.ati.utexas.edu','Incubator; energy & clean tech; UT Austin'),
  ('Austin Technology Incubator at UT Austin','Austin','https://www.ati.utexas.edu','Incubator; high tech; UT Austin'),
  ('Big Austin','Austin','https://www.bigaustin.org','Accelerator; small-business financing & education'),
  ('BioHouston','Houston','https://www.biohouston.org','Incubator; biotech / life science'),
  ('Biotechnology Commercialization Center at UTHealth Houston','Houston','https://www.uth.edu/otm','Incubator; biotech / life science; UTHealth'),
  ('Build Sec Foundry','San Antonio','https://www.buildsecfoundry.com','Incubator; security products'),
  ('Business and Community Lenders of Texas','Austin','https://www.bcloftexas.org','Funding; CDFI lending & entrepreneurship services'),
  ('Business Technology Center at HBDI','Houston','https://www.hbdi.org','Incubator; Houston Business Development Inc.'),
  ('The Business Factory at CVCED','San Angelo','https://www.cvced.org','Incubator; Concho Valley'),
  ('Capital Factory','Austin','https://www.capitalfactory.com','Accelerator; seed funding for equity'),
  ('Cardwell Collaborative','El Paso','https://www.mcafound.org','Incubator; biomedical R&D / commercialization'),
  ('Center for Innovation Technology and Entrepreneurship at UTSA','San Antonio','https://www.business.utsa.edu/cite','Accelerator/incubator; UTSA'),
  ('Coastal Bend Business Innovation Center at TAMU-CC','Corpus Christi','https://cbbic.tamucc.edu','Accelerator; Texas A&M-Corpus Christi'),
  ('Collide Village Accelerator Program','Addison','https://www.collidevillage.com','Accelerator; seed + convertible note for equity'),
  ('The Dallas Entrepreneur Center','Dallas','https://www.thedec.co','Incubator; multi-industry'),
  ('Dallas Women''s Venture Fund','Dallas','https://womensventurefund.org','Funding; nonprofit lender (women-owned), CDFI'),
  ('DFW Excellerator','Dallas','https://www.dfwexcellerator.com','Accelerator; international (esp. China) markets'),
  ('Discovery Park Business Incubator at UNT','Denton','https://www.research.unt.edu','Incubator; University of North Texas'),
  ('DreamIt Ventures','Austin','https://www.dreamit.com','Accelerator; multi-industry (pre-seed)'),
  ('Economic Growth Business Incubator','Austin','https://www.egbi.org','Incubator; disadvantaged-community focus'),
  ('Entrepreneurship and Commercialization Center at UT Rio Grande Valley','Brownsville','https://www.utrgv.edu/ecc','Incubator; UTRGV'),
  ('Enventure','Houston','https://www.enventure.org','Accelerator; life science / medtech'),
  ('GeniusDen','Dallas','https://www.geniusden.com','Incubator'),
  ('Health Wildcatters','Dallas','https://www.healthwildcatters.com','Accelerator; healthcare; seed for equity'),
  ('Houston Technology Center','Houston','https://www.houstontech.org','Incubator & accelerator; multi-sector'),
  ('The Hub of Human Innovation','El Paso','https://www.hubep.org','Incubator; high tech & clean energy'),
  ('The Huntsville Area Technology and Business Complex','Huntsville','https://www.hatchbusiness.com','Incubator; high tech; SHSU affiliate'),
  ('IBM PartnerWorld','Austin','https://www.ibm.com/partnerworld','Accelerator; corporate (IBM); high tech'),
  ('IDEA Works Fort Worth','Fort Worth','https://www.ideaworksfw.org','Incubator; high tech'),
  ('InCube Labs','San Antonio','https://www.incubelabs.com','Incubator; biotech/medical (operates InCube Ventures)'),
  ('Innovation Greenhouse at UNT','Denton','https://innovation.unt.edu','Accelerator; University of North Texas'),
  ('Innovation Underground','Bryan','https://iu.adventgx.com','Incubator; operated by Advent GX'),
  ('Institute of Innovation and Entrepreneurship at UT Dallas','Dallas','https://innovation.utdallas.edu','University program; entrepreneurship education & commercialization'),
  ('International Accelerator','Austin','https://www.internationalaccelerator.com','Accelerator; non-US-citizen founders (invests)'),
  ('iStart Valley','Plano','https://www.istartvalley.org','Accelerator; technology'),
  ('Jon Brumley Texas Venture Labs at UT Austin','Austin','https://www.mccombs.utexas.edu','Accelerator; UT Austin (McCombs)'),
  ('LAUNCH Innovative Business at Baylor University','Waco','https://www.launchinnovator.com','Accelerator; university (Baylor)'),
  ('LiftFund','San Antonio','https://www.liftfund.com','Funding; CDFI microlender (statewide)'),
  ('Longhorn Startup Lab at UT Austin','Austin','https://www.longhornstartup.com','Accelerator; UT Austin'),
  ('MCR Capital Advisors','Dallas','https://www.mcrcapital.com','Funding; capital advisory (MCR Venture Partners)'),
  ('Microsoft Technology Center','Irving','https://www.microsoft.com/mtc','Incubator; corporate (Microsoft); high tech'),
  ('MileOne - International Business Assistance Center','Laredo','https://www.mileoneinc.com','Incubator / accelerator'),
  ('Munir Abdul Lalani Center for Entrepreneurship and Free Enterprise','Wichita Falls','https://www.mwsu.edu','University center; supports angel/VC development'),
  ('NextHIT','Houston','https://www.houstonhealthventures.com','Accelerator; health IT (Houston Health Ventures funding)'),
  ('NSBRI Industry Forum','Houston','https://www.nsbri.org','Accelerator; space biomedical; seed (SMARTCAP)'),
  ('OwlSpark at Rice University','Houston','https://www.owlspark.com','Accelerator; Rice University'),
  ('PeopleFund','Austin','https://www.peoplefund.org','Funding; CDFI (statewide)'),
  ('Rapid Response Manufacturing Center at UTRGV','Edinburg','https://www.utrgv.edu','Accelerator; manufacturing; UTRGV (FKA UTPA)'),
  ('RED Labs at the University of Houston','Houston','https://redlabs.bauer.uh.edu','Accelerator; University of Houston'),
  ('Research Valley Innovation Center','College Station','https://www.aminnovationcenter.com','Incubator; biotech / life science'),
  ('REVTECH','Dallas','https://www.revtechaccelerator.com','Accelerator; retail tech; seed for equity'),
  ('Rice Alliance for Technology and Entrepreneurship','Houston','https://www.alliance.rice.edu','Accelerator; Rice University'),
  ('Rice Launch at Rice University','Houston','https://www.rcelconnect.org','Accelerator; Rice University'),
  ('San Antonio Clean Energy Incubator','San Antonio','https://www.texasenergy.utsa.edu','Incubator; clean energy; UTSA'),
  ('Seed Sumo','College Station','https://www.seedsumo.com','Accelerator; seed for equity'),
  ('Shell GameChanger','Houston','https://www.shell.com','Accelerator; corporate (Shell); energy; project funding'),
  ('Silsbee EDC Business Incubator Program','Silsbee','https://www.silsbeeedc.com','Incubator'),
  ('SKU','Austin','https://www.sku.is','Accelerator; consumer packaged goods; seed for equity'),
  ('STAR Park at Texas State University','San Marcos','https://www.txstate.edu/starpark','Incubator; Texas State University'),
  ('Startup Aggieland at Texas A&M University','College Station','https://www.startupaggieland.com','Accelerator / incubator; Texas A&M'),
  ('TECH Fort Worth','Fort Worth','https://www.techfortworth.org','Incubator; high tech'),
  ('Tech Ranch Austin','Austin','https://www.techranchaustin.com','Incubator; high tech'),
  ('Tech Wildcatters','Dallas','https://techwildcatters.com','Accelerator; B2B; seed fund'),
  ('Technology Business Accelerator (TechBA)','Austin','https://www.techba.org','Accelerator; cross-border (Mexico-US)'),
  ('TechStars Austin','Austin','https://www.techstars.com','Accelerator; seed for equity (national network)'),
  ('Texas A&M Bioscience Business Accelerator','College Station','https://www.vpr.tamu.edu','Accelerator; biotech / life science; Texas A&M'),
  ('Texas Medical Center Accelerator (TMCx)','Houston','https://www.tmc.edu/innovation','Accelerator; life science / health (no equity)'),
  ('Texas Research and Technology Foundation',NULL,NULL,'Incubator / accelerator (in development); life science'),
  ('Thinktiv','Austin','https://www.thinktiv.com','Venture studio / accelerator; takes equity for services'),
  ('TTU Innovation Hub at Research Park','Lubbock','https://www.depts.ttu.edu/vpr','Incubator; Texas Tech University'),
  ('Tyler Area Business Incubator','Tyler','https://www.tjc.edu','Incubator; Tyler Junior College'),
  ('The UTSA New Venture Incubator','San Antonio','https://research.utsa.edu','Accelerator / incubator; UTSA'),
  ('The Venture Development Center at UT Dallas','Richardson','https://innovation.utdallas.edu','Incubator; UT Dallas'),
  ('Veterans Business Outreach Center at UTA','Arlington','https://www.uta.edu','Accelerator; veterans; UT Arlington'),
  ('West Texas A&M University Enterprise Center','Amarillo','https://wtenterprisecenter.com','Incubator; West Texas A&M University')
) as v(party_name, city, website, notes)
where not exists (select 1 from app.parties p where p.party_name=v.party_name and p.deleted_at is null);

-- 2) app.investor_profile for the 24 investor rows (scoped by source + party_type_id=1)
insert into app.investor_profile (party_id, investor_type_id, sector_focus, geographic_focus, is_lead_investor, organization_id)
select p.id,
       coalesce((select id from app.investor_types where code=v.itype_code),
                (select id from app.investor_types where code='other'))::smallint,
       v.sector_focus, v.geographic_focus, false, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p join (values
  ('Alara Capital', 'vc', array['technology','semiconductors','software','digital_media']::text[], array['Texas']::text[]),
  ('Aristos Ventures', 'vc', array['technology','saas','security','information_services']::text[], array['Texas']::text[]),
  ('Covera Ventures', 'vc', array['software','mobile','infrastructure','tech_enabled_services']::text[], array['Texas']::text[]),
  ('Dallas Venture Partners', 'vc', array['saas','agtech','healthcare_it','mobile']::text[], array['Texas','Midwest']::text[]),
  ('Daylight Partners', 'vc', array['technology']::text[], array['Texas']::text[]),
  ('Live Oak Venture Partners', 'vc', array['it','tech_enabled_services']::text[], array['Texas']::text[]),
  ('Mercury Fund', 'vc', array['saas','cloud','data_science','intelligent_manufacturing']::text[], array['US','Mid-America']::text[]),
  ('Naya Ventures', 'vc', array['mobile','cloud','big_data']::text[], array['US','India']::text[]),
  ('Next Step Capital Partners', 'vc', array['technology','revenue_based']::text[], array['Texas']::text[]),
  ('S3 Ventures', 'vc', array['it','software','medical_device']::text[], array['Texas']::text[]),
  ('Santé Ventures', 'vc', array['life_science','healthcare']::text[], array['Texas']::text[]),
  ('Silverton Partners', 'vc', array['technology','seed_seriesA']::text[], array['Texas']::text[]),
  ('Trailblazer Capital', 'vc', array['networking','telecom','enterprise_software','cloud']::text[], array['Texas','Oklahoma']::text[]),
  ('Texo Ventures', 'vc', array['healthcare','medical_device','diagnostics']::text[], array['Texas']::text[]),
  ('Texas Women''s Ventures Capital Management', 'vc', array['women_owned','growth']::text[], array['Texas','Southwest']::text[]),
  ('Emergent Technologies', 'vc', array['life_science','biotech']::text[], array['Texas']::text[]),
  ('Aggie Angel Network', 'angel', array['early_stage','technology']::text[], array['Texas']::text[]),
  ('Central Texas Angel Network', 'angel', array['early_stage']::text[], array['Texas']::text[]),
  ('Cowtown Angels', 'angel', array['early_stage']::text[], array['Texas']::text[]),
  ('Dallas Angel Network', 'angel', array['early_stage']::text[], array['Texas']::text[]),
  ('Houston Angel Network', 'angel', array['early_stage']::text[], array['Texas']::text[]),
  ('North Texas Angel Network', 'angel', array['early_stage']::text[], array['Texas']::text[]),
  ('Tyler Texas Angel Network', 'angel', array['early_stage']::text[], array['Texas']::text[]),
  ('Wilco Angel Network', 'angel', array['early_stage']::text[], array['Texas']::text[])
) as v(party_name, itype_code, sector_focus, geographic_focus) on v.party_name=p.party_name
where p.source='texas_startup_resources_2017' and p.party_type_id=1 and p.deleted_at is null
  and not exists (select 1 from app.investor_profile ip where ip.party_id=p.id);

commit;

-- ===================== VERIFY =====================
-- total rows this batch (expect 105):
select count(*) from app.parties where source='texas_startup_resources_2017';
-- investors (expect 24):
select count(*) from app.parties where source='texas_startup_resources_2017' and party_type_id=1;
-- partners (expect 81):
select count(*) from app.parties p where p.source='texas_startup_resources_2017' and p.party_type_id=(select id from app.party_types where code='partner');
-- investor_profile rows (expect 24):
select count(*) from app.investor_profile ip join app.parties p on p.id=ip.party_id where p.source='texas_startup_resources_2017';
-- any investor names skipped by dedup (already existed under another source):
select v.name from (values
  ('Alara Capital'),
  ('Aristos Ventures'),
  ('Covera Ventures'),
  ('Dallas Venture Partners'),
  ('Daylight Partners'),
  ('Live Oak Venture Partners'),
  ('Mercury Fund'),
  ('Naya Ventures'),
  ('Next Step Capital Partners'),
  ('S3 Ventures'),
  ('Santé Ventures'),
  ('Silverton Partners'),
  ('Trailblazer Capital'),
  ('Texo Ventures'),
  ('Texas Women''s Ventures Capital Management'),
  ('Emergent Technologies'),
  ('Aggie Angel Network'),
  ('Central Texas Angel Network'),
  ('Cowtown Angels'),
  ('Dallas Angel Network'),
  ('Houston Angel Network'),
  ('North Texas Angel Network'),
  ('Tyler Texas Angel Network'),
  ('Wilco Angel Network')
) v(name) where not exists (select 1 from app.parties p where p.party_name=v.name and p.deleted_at is null);
