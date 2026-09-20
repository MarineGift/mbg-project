-- ############################################################
-- HOW TO RUN: Ctrl+A (SELECT ALL), then Run the WHOLE file.
-- URM Batch 06 — Greentown Labs Investor Address & Information
-- Targets were confirmed present in the 256-row Greentown master export.
--
-- Safe/idempotent:
--   * NO new parties
--   * NO deletes
--   * blank fields only, except the explicitly documented Alliance rebrand
-- ############################################################

begin;

do $$
begin
  if not exists (select 1 from app.party_types where code='investor') then
    raise exception 'Required party_type investor is missing';
  end if;
end $$;

-- 1. Address/location + official information
with v(
  party_name, country_code, region, city,
  website, domain_normalized, intro_en
) as (
 values
 (
  '369 Funds','US','Texas','Houston',
  'https://369funds.com','369funds.com',
  $i$369 Funds is a Houston-based private-markets investment platform providing investors access to tax-efficient opportunities across energy, technology, infrastructure, manufacturing, housing and agriculture. The firm targets institutional-quality projects in fast-growing U.S. industries and combines sector experience with tax-advantaged investment strategies.$i$
 ),
 (
  'Actia Capital Partners','GB','England','London',
  'https://actiapartners.com','actiapartners.com',
  $i$Actia Capital Partners is a specialist venture investor backing entrepreneurs building innovative infrastructure solutions from the early stages of commercialization. The firm positions itself at the intersection of venture capital and infrastructure and works with InfraTech founders developing technologies for critical physical systems.$i$
 ),
 (
  'AmFam Institute','US','Wisconsin','Madison',
  'https://www.amfaminstitute.com','amfaminstitute.com',
  $i$The American Family Insurance Institute for Corporate and Social Impact is an impact-oriented venture investor that backs scalable social enterprises. It invests primarily at Seed and Series A in areas including home resilience, access to housing and AI for social good, combining venture capital with a mission to strengthen communities and close equity gaps.$i$
 ),
 (
  'Angel Investor Forum','US','Connecticut',null,
  'https://www.angelinvestorforum.com','angelinvestorforum.com',
  $i$Angel Investor Forum is a Connecticut angel-investor network founded in 2004. Its members invest in early-stage U.S. companies across sectors, generally at pre-seed and seed, with a preference for Connecticut companies. The group provides smart capital, diligence and investor expertise, with aggregate investments commonly in the hundreds of thousands of dollars.$i$
 ),
 (
  'Arosa Capital Management','US','Florida','Miami Beach',
  'https://arosacapital.com','arosacapital.com',
  $i$Arosa Capital Management is an investment-management firm with a principal business address in Miami Beach, Florida. The firm manages investment portfolios and has participated in energy and related investment strategies; its current SEC filings identify Arosa Capital Management LP as an institutional investment manager.$i$
 ),
 (
  'Avila VC','US','Florida','Miami',
  'https://www.avila.vc','avila.vc',
  $i$Avila VC is a venture-capital firm investing at the intersection of digital technology and the physical economy. Its thesis centers on rebuilding foundational industries for abundance, sustainability and human flourishing, with portfolio exposure to advanced manufacturing, energy and other technology-enabled physical systems.$i$
 ),
 (
  'Bantam Group','US',null,null,
  'https://bantamgroup.com','bantamgroup.com',
  $i$Bantam Group is an investor and entrepreneurial advisor that invests directly in emerging companies and works actively as a mentor, coach and advocate for founders. Its investments span technology and other sectors, and it also participates alongside angel groups and early-stage venture firms and as a limited partner in venture funds.$i$
 ),
 (
  'BasisTech','US','Massachusetts','Somerville',
  'https://www.basistech.com','basistech.com',
  $i$BasisTech is a Somerville, Massachusetts-based technology company and startup platform that works with entrepreneurs to refine ideas, attract talent, access capital and accelerate growth. It focuses on early-stage technology ventures with global potential and operates an accelerator environment supporting portfolio companies and founders.$i$
 ),
 (
  'BetterWay','US','South Carolina','Charleston',
  'https://www.betterway.vc','betterway.vc',
  $i$BetterWay is an early-stage green-technology venture firm backing U.S.-based pre-seed and seed hard-tech companies. It focuses on non-software technologies that improve the economics and environmental performance of legacy industries, combining capital with operating, manufacturing and venture support.$i$
 ),
 (
  'Alliance Partners','US','New York','New York',
  'https://www.allianceimpactpartners.com','allianceimpactpartners.com',
  $i$Alliance Partners is a collaborative strategic investment platform focused on industries that move the physical economy. Formerly Mobility Impact Partners, it brings together industrial and service companies, startups and investors to identify consequential technology shifts, make high-conviction investments and accelerate deployment of emerging technologies across industrial sectors.$i$
 )
)
update app.parties p
set
 country_code      = coalesce(nullif(p.country_code,''), v.country_code),
 region            = coalesce(nullif(p.region,''), v.region),
 city              = coalesce(nullif(p.city,''), v.city),
 website           = coalesce(nullif(p.website,''), v.website),
 domain_normalized = coalesce(nullif(p.domain_normalized,''), v.domain_normalized),
 intro_en          = coalesce(nullif(p.intro_en,''), v.intro_en),
 updated_at        = now()
from v
where lower(trim(p.party_name))=lower(trim(v.party_name))
  and p.party_type_id=(select id from app.party_types where code='investor')
  and p.deleted_at is null;

-- 2. Alliance Partners is the current name/brand of the record whose
-- old stored URL pointed to Mobility Impact Partners. Update ONLY if the
-- legacy URL/domain is still present, so later manual edits are preserved.
update app.parties p
set website='https://www.allianceimpactpartners.com',
    domain_normalized='allianceimpactpartners.com',
    updated_at=now()
where lower(trim(p.party_name))='alliance partners'
  and p.party_type_id=(select id from app.party_types where code='investor')
  and p.deleted_at is null
  and (
    lower(coalesce(p.website,'')) like '%mobilityimpact.partners%'
    or lower(coalesce(p.domain_normalized,''))='mobilityimpact.partners'
  );

commit;

-- VERIFY A — final address/information
select
 p.party_name,
 p.country_code,
 p.region,
 p.city,
 p.website,
 p.domain_normalized,
 left(p.intro_en,160) as intro_preview
from app.parties p
where p.deleted_at is null
 and p.party_type_id=(select id from app.party_types where code='investor')
 and lower(trim(p.party_name)) in (
  '369 funds','actia capital partners','amfam institute',
  'angel investor forum','arosa capital management','avila vc',
  'bantam group','basistech','betterway','alliance partners'
 )
order by p.party_name;

-- VERIFY B — remaining location/info gaps
select
 p.party_name,
 concat_ws(', ',
   case when nullif(trim(p.country_code),'') is null then 'country' end,
   case when nullif(trim(p.region),'') is null then 'region' end,
   case when nullif(trim(p.city),'') is null then 'city' end,
   case when nullif(trim(p.website),'') is null then 'website' end,
   case when nullif(trim(p.domain_normalized),'') is null then 'domain' end,
   case when nullif(trim(p.intro_en),'') is null then 'intro' end
 ) as still_missing
from app.parties p
where p.deleted_at is null
 and p.party_type_id=(select id from app.party_types where code='investor')
 and lower(trim(p.party_name)) in (
  '369 funds','actia capital partners','amfam institute',
  'angel investor forum','arosa capital management','avila vc',
  'bantam group','basistech','betterway','alliance partners'
 )
order by p.party_name;

-- VERIFY C — ensure all 10 expected names existed
with t(party_name) as (
 values
 ('369 Funds'),('Actia Capital Partners'),('AmFam Institute'),
 ('Angel Investor Forum'),('Arosa Capital Management'),('Avila VC'),
 ('Bantam Group'),('BasisTech'),('BetterWay'),('Alliance Partners')
)
select t.party_name as not_found
from t
where not exists (
 select 1 from app.parties p
 where p.deleted_at is null
   and p.party_type_id=(select id from app.party_types where code='investor')
   and lower(trim(p.party_name))=lower(trim(t.party_name))
)
order by t.party_name;

notify pgrst, 'reload schema';
