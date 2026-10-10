-- ============================================================
-- enrich_20261010_mill_emails_b15.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Batch 15 - Europe / Japan mills, crawler run w10 (2026-10-10).
-- Part 1 websites (18 rows) - each site was reached by the crawler.
--   kotkamills.com now redirects to mm.group (Kotkamills is part of
--   Mayr-Melnhof); Kotkamills and MM Follacell get mm.group.
-- Part 2 e-mails (10 rows) - general or mill inboxes printed on the sites:
--   Perlen info@perlen.ch | Kotkamills kotka@mm.group | MM Follacell
--   follacell@mm.group | Jujo Thermal jujosales@ | Saica Paper France
--   us-comercial.paper@saica.com (paper division sales) | Gascogne
--   info@groupe-gascogne.com | Glomma Papp post@glommapapp.no |
--   SCA group + SCA Munksund info@sca.com | SCA Obbola obbola@sca.com
-- Part 3 SCA Ostrand is a market-pulp mill - tagged 'MBG Pulp Only'.
-- Not used: staff addresses, packaging-plant inboxes, compliance,
-- communication, security, recruitment, webmaster, other-company domains.
-- Crawl failed (bot block): Ranheim, Rengo, Marusumi, Daio - not filled.
-- Idempotent. Last statement is a verification select.
-- ============================================================
update app.parties p
set website = v.website,
    domain_normalized = coalesce(nullif(btrim(p.domain_normalized), ''), v.domain),
    updated_at = now()
from (values
  ('e8f64c26-4ccf-4ae4-99f4-88d21fb72bba'::uuid, 'https://www.perlen.ch',          'perlen.ch'),
  ('c860a1af-1440-4594-ab6e-fb530b21042a'::uuid, 'https://www.modelgroup.com',     'modelgroup.com'),
  ('e2df56b4-7cb8-491e-991b-9018bbe73b31'::uuid, 'https://mm.group',               'mm.group'),
  ('e54ba024-cac4-45bc-af64-22c42da135bf'::uuid, 'https://mm.group',               'mm.group'),
  ('142ca691-3f41-4848-89e3-80e61a00fe53'::uuid, 'https://www.pankaboard.com',     'pankaboard.com'),
  ('bc9b8c43-11af-48a6-bc6f-cd694cca2d1c'::uuid, 'https://www.jujothermal.com',    'jujothermal.com'),
  ('15235ab7-7fb9-44fb-86c2-fb0adb63a092'::uuid, 'https://www.lucartgroup.com',    'lucartgroup.com'),
  ('68f1d11f-2930-4201-80e9-fe62ef891b6d'::uuid, 'https://www.saica.com',          'saica.com'),
  ('db307cc4-c6d9-4f88-9e16-d50f52d2b153'::uuid, 'https://www.groupe-gascogne.com','groupe-gascogne.com'),
  ('9d016cbd-25e6-4be8-a162-f50fd0c2744d'::uuid, 'https://glommapapp.no',          'glommapapp.no'),
  ('99f9d6a3-f43e-4885-bcd6-94ab9282d691'::uuid, 'https://vpkgroup.com',           'vpkgroup.com'),
  ('0d9ccc9b-2b8d-4147-9663-36e16dd947b9'::uuid, 'https://www.sca.com',            'sca.com'),
  ('7c0395ba-88d9-4f92-b9b8-cd8acf30fd15'::uuid, 'https://www.sca.com',            'sca.com'),
  ('f7ac33a7-5ef6-46c9-b7e7-1c23c6fbe829'::uuid, 'https://www.sca.com',            'sca.com'),
  ('c7c661ea-b528-4210-91a6-a0c7c6ebf46c'::uuid, 'https://www.sca.com',            'sca.com'),
  ('65b8cb89-27bf-4e8b-ad7e-5dd90b5d3703'::uuid, 'https://www.cranecurrency.com',  'cranecurrency.com'),
  ('27ca7dd6-c13d-4d64-a016-b0a0a516f671'::uuid, 'https://www.chuetsu-pulp.co.jp', 'chuetsu-pulp.co.jp'),
  ('ffaade08-9cd1-40a1-a918-d0731586f678'::uuid, 'https://www.lintec.co.jp',       'lintec.co.jp')
) as v(party_id, website, domain)
where p.id = v.party_id
  and p.deleted_at is null
  and nullif(btrim(p.website), '') is null;

insert into app.contacts
  (organization_id, party_id, contact_type_id, email, title_text,
   is_primary, is_decision_maker, source, notes)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, v.party_id, 2, v.email, v.title_text,
       true, false, 'homepage', v.notes
from (values
  ('e8f64c26-4ccf-4ae4-99f4-88d21fb72bba'::uuid, 'info@perlen.ch', 'General inbox',
   'Shown on https://www.perlen.ch/ (crawler 2026-10-10)'),
  ('e2df56b4-7cb8-491e-991b-9018bbe73b31'::uuid, 'kotka@mm.group', 'Mill inbox (MM Kotkamills)',
   'Listed for Kotka on https://mm.group/locations/ (crawler 2026-10-10)'),
  ('e54ba024-cac4-45bc-af64-22c42da135bf'::uuid, 'follacell@mm.group', 'Mill inbox (MM Follacell)',
   'Listed for Follacell on https://mm.group/locations/ (crawler 2026-10-10)'),
  ('bc9b8c43-11af-48a6-bc6f-cd694cca2d1c'::uuid, 'jujosales@jujothermal.com', 'Sales inbox',
   'Shown on https://www.jujothermal.com/ (crawler 2026-10-10)'),
  ('68f1d11f-2930-4201-80e9-fe62ef891b6d'::uuid, 'us-comercial.paper@saica.com', 'Saica Paper sales inbox',
   'Paper division commercial contact on https://www.saica.com/en/contact/ (crawler 2026-10-10)'),
  ('db307cc4-c6d9-4f88-9e16-d50f52d2b153'::uuid, 'info@groupe-gascogne.com', 'General inbox',
   'Shown on https://www.groupe-gascogne.com/fr/mentions-legales-2/ (crawler 2026-10-10)'),
  ('9d016cbd-25e6-4be8-a162-f50fd0c2744d'::uuid, 'post@glommapapp.no', 'General inbox',
   'Shown on https://glommapapp.no/ (crawler 2026-10-10)'),
  ('0d9ccc9b-2b8d-4147-9663-36e16dd947b9'::uuid, 'info@sca.com', 'Group general inbox (SCA)',
   'Shown on https://www.sca.com/sv/ (crawler 2026-10-10)'),
  ('7c0395ba-88d9-4f92-b9b8-cd8acf30fd15'::uuid, 'info@sca.com', 'Group general inbox (SCA)',
   'Shown on https://www.sca.com/sv/ (crawler 2026-10-10) - no Munksund sales inbox published'),
  ('f7ac33a7-5ef6-46c9-b7e7-1c23c6fbe829'::uuid, 'obbola@sca.com', 'Mill inbox (Obbola)',
   'Shown on https://www.sca.com/sv/kontakta-oss/ (crawler 2026-10-10)')
) as v(party_id, email, title_text, notes)
where exists (select 1 from app.parties p where p.id = v.party_id and p.deleted_at is null)
  and not exists (
    select 1 from app.contacts c
    where c.party_id = v.party_id
      and lower(c.email) = lower(v.email)
      and c.deleted_at is null
  );

update app.parties p
set interest_tags = coalesce(p.interest_tags, '[]'::jsonb) || '["MBG Pulp Only"]'::jsonb,
    updated_at = now()
where p.deleted_at is null
  and p.id = 'c7c661ea-b528-4210-91a6-a0c7c6ebf46c'::uuid
  and jsonb_typeof(coalesce(p.interest_tags, '[]'::jsonb)) = 'array'
  and not (coalesce(p.interest_tags, '[]'::jsonb) ? 'MBG Pulp Only');

select p.party_name, p.website,
       (select string_agg(c.email, ', ') from app.contacts c
         where c.party_id = p.id and c.deleted_at is null and nullif(btrim(c.email), '') is not null) as emails,
       (p.interest_tags ? 'MBG Pulp Only') as pulp_only
from app.parties p
where p.id in ('e8f64c26-4ccf-4ae4-99f4-88d21fb72bba'::uuid, 'c860a1af-1440-4594-ab6e-fb530b21042a'::uuid,
               'e2df56b4-7cb8-491e-991b-9018bbe73b31'::uuid, 'e54ba024-cac4-45bc-af64-22c42da135bf'::uuid,
               '142ca691-3f41-4848-89e3-80e61a00fe53'::uuid, 'bc9b8c43-11af-48a6-bc6f-cd694cca2d1c'::uuid,
               '15235ab7-7fb9-44fb-86c2-fb0adb63a092'::uuid, '68f1d11f-2930-4201-80e9-fe62ef891b6d'::uuid,
               'db307cc4-c6d9-4f88-9e16-d50f52d2b153'::uuid, '9d016cbd-25e6-4be8-a162-f50fd0c2744d'::uuid,
               '99f9d6a3-f43e-4885-bcd6-94ab9282d691'::uuid, '0d9ccc9b-2b8d-4147-9663-36e16dd947b9'::uuid,
               '7c0395ba-88d9-4f92-b9b8-cd8acf30fd15'::uuid, 'f7ac33a7-5ef6-46c9-b7e7-1c23c6fbe829'::uuid,
               'c7c661ea-b528-4210-91a6-a0c7c6ebf46c'::uuid, '65b8cb89-27bf-4e8b-ad7e-5dd90b5d3703'::uuid,
               '27ca7dd6-c13d-4d64-a016-b0a0a516f671'::uuid, 'ffaade08-9cd1-40a1-a918-d0731586f678'::uuid)
order by p.party_name;
