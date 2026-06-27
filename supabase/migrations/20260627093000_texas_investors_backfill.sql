-- ============================================================
-- 20260627093000_texas_investors_backfill.sql
-- Backfill the Texas investors that ALREADY existed under a prior source
-- (dedup-skipped in 20260627090000; investor_profile@texas source came back 16 of 24).
-- Non-destructive: fills only NULL columns; tags all 24 in notes with a marker (idempotent).
-- Then ensures an investor_profile exists for any of these 24 that are investors and lack one.
-- Run as one txn in Supabase SQL Editor. Safe to re-run.
-- ============================================================

begin;

-- 1) enrich existing rows (coalesce = no clobber); append source marker to notes once
update app.parties p set
  region  = coalesce(p.region,  v.region),
  city    = coalesce(p.city,    v.city),
  website = coalesce(p.website, v.website),
  source  = coalesce(p.source,  'texas_startup_resources_2017'),
  notes   = case
              when p.notes is null then v.notes || ' [texas_startup_resources_2017]'
              when position('texas_startup_resources_2017' in p.notes) > 0 then p.notes
              else p.notes || ' [texas_startup_resources_2017]'
            end
from (values
  ('Alara Capital','Austin','TX','https://www.alaracap.com','VC; technology, semiconductors, software'),
  ('Aristos Ventures','Dallas','TX','https://www.aristosventures.com','VC; capital-efficient technology, SaaS, security'),
  ('Covera Ventures','Austin','TX','https://www.coveraventures.com','VC; early-stage software, mobile, infrastructure'),
  ('Dallas Venture Partners','Dallas','TX','https://www.dallasventurepartners.com','VC; enterprise SaaS, AgTech, healthcare IT'),
  ('Daylight Partners','Austin','TX','https://www.daylightpartners.com','VC; technology, revenue+product stage'),
  ('Live Oak Venture Partners','Austin','TX','https://www.liveoakvp.com','VC; IT & tech-enabled services'),
  ('Mercury Fund','Houston','TX','https://www.mercuryfund.com','VC; SaaS, cloud, data science (often lead)'),
  ('Naya Ventures','Irving','TX','https://www.nayaventures.com','VC; mobile, cloud, big data'),
  ('Next Step Capital Partners','Austin','TX','https://www.nextstepcapitalpartners.com','VC; revenue-share funding, technology'),
  ('S3 Ventures','Austin','TX','https://www.s3vc.com','VC; IT solutions, enterprise software, medical device'),
  ('Santé Ventures','Austin','TX','https://www.santeventures.com','VC; early-stage life science & healthcare'),
  ('Silverton Partners','Austin','TX','https://www.silvertonpartners.com','VC; seed-Series A technology'),
  ('Trailblazer Capital','Dallas','TX','https://www.trailblazercapital.com','VC; networking, telecom, enterprise software'),
  ('Texo Ventures','Austin','TX','https://www.texoventures.com','VC; early-stage healthcare, medical device/diagnostics'),
  ('Texas Women''s Ventures Capital Management','Dallas','TX','https://www.twvcapital.com','VC; women-owned & women-led, growth'),
  ('Emergent Technologies','Austin','TX','https://www.emergenttechnologies.com','Life-sciences venture firm (also incubator/accelerator)'),
  ('Aggie Angel Network','College Station','TX','https://www.aggieangelnetwork.com','Angel network; early-stage technology'),
  ('Central Texas Angel Network','Austin','TX','https://www.centraltexasangelnetwork.com','Angel network (ATAN/ACA member)'),
  ('Cowtown Angels','Fort Worth','TX','https://www.cowtownangels.org','Angel network; early-stage'),
  ('Dallas Angel Network','Dallas','TX','https://www.dallasangelnetwork.com','Angel network; early-stage'),
  ('Houston Angel Network','Houston','TX','https://www.houstonangelnetwork.org','Angel network; oldest in TX, most active in US'),
  ('North Texas Angel Network','Dallas','TX','https://www.northtexasangels.org','Angel network; early-stage, any industry'),
  ('Tyler Texas Angel Network','Tyler','TX','https://www.tylertexasangelnetwork.com','Angel network; early-stage'),
  ('Wilco Angel Network','Georgetown','TX','https://www.wilcoangelnetwork.org','Angel network (Texas Entrepreneur Networks)')
) as v(party_name, city, region, website, notes)
where p.party_name = v.party_name and p.deleted_at is null;

-- 2) ensure investor_profile for any of the 24 that are investors (party_type_id=1) and have none
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
where p.party_type_id=1 and p.deleted_at is null
  and not exists (select 1 from app.investor_profile ip where ip.party_id=p.id);

commit;

-- ===================== VERIFY =====================
-- investor_profile across all 24 Texas investor names (expect 24):
select count(*) from app.investor_profile ip join app.parties p on p.id=ip.party_id
where p.party_name in (
  'Alara Capital',
  'Aristos Ventures',
  'Covera Ventures',
  'Dallas Venture Partners',
  'Daylight Partners',
  'Live Oak Venture Partners',
  'Mercury Fund',
  'Naya Ventures',
  'Next Step Capital Partners',
  'S3 Ventures',
  'Santé Ventures',
  'Silverton Partners',
  'Trailblazer Capital',
  'Texo Ventures',
  'Texas Women''s Ventures Capital Management',
  'Emergent Technologies',
  'Aggie Angel Network',
  'Central Texas Angel Network',
  'Cowtown Angels',
  'Dallas Angel Network',
  'Houston Angel Network',
  'North Texas Angel Network',
  'Tyler Texas Angel Network',
  'Wilco Angel Network'
);

-- any of the 24 names that exist but are NOT party_type_id=1 (would explain a profile gap; inspect manually):
select p.party_name, p.party_type_id, p.source
from app.parties p where p.deleted_at is null and p.party_type_id<>1 and p.party_name in (
  'Alara Capital',
  'Aristos Ventures',
  'Covera Ventures',
  'Dallas Venture Partners',
  'Daylight Partners',
  'Live Oak Venture Partners',
  'Mercury Fund',
  'Naya Ventures',
  'Next Step Capital Partners',
  'S3 Ventures',
  'Santé Ventures',
  'Silverton Partners',
  'Trailblazer Capital',
  'Texo Ventures',
  'Texas Women''s Ventures Capital Management',
  'Emergent Technologies',
  'Aggie Angel Network',
  'Central Texas Angel Network',
  'Cowtown Angels',
  'Dallas Angel Network',
  'Houston Angel Network',
  'North Texas Angel Network',
  'Tyler Texas Angel Network',
  'Wilco Angel Network'
);

-- review the 24 rows (source + tag visible):
select p.party_name, p.party_type_id, p.city, p.region, p.source, left(p.notes,60) as notes
from app.parties p where p.deleted_at is null and p.party_name in (
  'Alara Capital',
  'Aristos Ventures',
  'Covera Ventures',
  'Dallas Venture Partners',
  'Daylight Partners',
  'Live Oak Venture Partners',
  'Mercury Fund',
  'Naya Ventures',
  'Next Step Capital Partners',
  'S3 Ventures',
  'Santé Ventures',
  'Silverton Partners',
  'Trailblazer Capital',
  'Texo Ventures',
  'Texas Women''s Ventures Capital Management',
  'Emergent Technologies',
  'Aggie Angel Network',
  'Central Texas Angel Network',
  'Cowtown Angels',
  'Dallas Angel Network',
  'Houston Angel Network',
  'North Texas Angel Network',
  'Tyler Texas Angel Network',
  'Wilco Angel Network'
) order by p.source, p.party_name;
