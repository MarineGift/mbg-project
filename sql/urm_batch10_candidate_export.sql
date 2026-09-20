-- ############################################################
-- HOW TO RUN: Ctrl+A (SELECT ALL), then Run the WHOLE file.
-- URM Batch 10 Candidate Export — Greentown Labs Investors
-- READ ONLY. No INSERT / UPDATE / DELETE.
--
-- Purpose:
--   Continue address/information completion for ALL investors carrying
--   normalized tag code = greentown_labs.
--   Excludes companies already processed in Batches 01-09.
-- ############################################################

with gt as (
 select distinct
   p.id party_id, p.party_name, p.country_code, p.region, p.city,
   p.website, p.domain_normalized, p.intro_en, p.source,
   ip.id investor_profile_id, ip.priority,
   it.code investor_type, ip.sector_focus, ip.investment_types
 from app.parties p
 join app.investor_profile ip on ip.party_id=p.id
 left join app.investor_types it on it.id=ip.investor_type_id
 where p.deleted_at is null
   and p.party_type_id=(select id from app.party_types where code='investor')
   and exists (
     select 1
     from app.investor_interest_tags iit
     join app.interest_tags tag on tag.id=iit.interest_tag_id
     where iit.investor_profile_id=ip.id and tag.code='greentown_labs'
   )
   and lower(trim(p.party_name)) not in (
     -- Batch 01
     'congruent ventures','clean energy ventures','material impact','prelude ventures',
     'pangaea ventures','sosv',
     -- Batch 02
     'at one ventures','massventures','clean energy venture group',
     'breakthrough energy ventures','ara partners',
     -- Batch 03
     'basf venture capital','baukunst','cybernetix ventures','diamond edge ventures',
     'houston angel network','piva capital','dcvc','new climate ventures','ap ventures',
     'fine structure ventures',
     -- Batch 04
     'asahi kasei corporation','cemex ventures','henkel','imerys',
     'nova by saint-gobain','amrize','avery dennison ventures','julian capital',
     'shell ventures','elemental impact','activate capital','anthropocene ventures',
     -- Batch 05
     'powerhouse ventures','accelr8 ventures','active impact investments','aera vc',
     'agfunder','blackhorn ventures','born global ventures','burnt island ventures',
     'calvert impact',
     -- Batch 06
     '369 funds','actia capital partners','amfam institute',
     'angel investor forum','arosa capital management','avila vc','bantam group',
     'basistech','betterway','alliance partners',
     -- Batch 07
     'boston angel club','boston impact initiative','calibrant energy','camber road',
     'carnrite ventures','caterpillar','caymont ventures','cei',
     'cerity partners ventures',
     -- Batch 08
     '11 tribes','audacy','blue dome capital','building ventures',
     'camber creek','chestnut run capital','clearsky','climate investment',
     -- Batch 09
     'avesta fund','clai ventures','climate tech partners','convergent ventures',
     'counteract','chemical angels','cerulean ventures'
   )
),
x as (
 select *,
   (case when nullif(trim(country_code),'') is null then 1 else 0 end +
    case when nullif(trim(region),'') is null then 1 else 0 end +
    case when nullif(trim(city),'') is null then 1 else 0 end +
    case when nullif(trim(website),'') is null then 1 else 0 end +
    case when nullif(trim(domain_normalized),'') is null then 1 else 0 end +
    case when nullif(trim(intro_en),'') is null then 1 else 0 end +
    case when investor_type is null then 1 else 0 end) missing_fields
 from gt
)
select
 party_name, investor_type, priority,
 country_code, region, city, website, domain_normalized,
 intro_en, sector_focus, investment_types, missing_fields, source
from x
where missing_fields>0
order by missing_fields desc, priority='high' desc, party_name
limit 30;
