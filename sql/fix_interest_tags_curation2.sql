-- ============================================================
-- CURATION PASS 2 (final): fold remaining long-tail + drop orphans (2026-07-04)
-- Input: post-curation 900-report 2026-07-05. Idempotent.
--   (1) promote 3 meaningful canonicals (generalist / diversity / non-dilutive)
--   (2) ~28 aliases for clear folds (oceans -> ocean_blue_economy, etc.)
--   (3) merge
--   (4) delete usage-0 orphan 900 tags (created from supplier/mill legacy
--       values that have no investor profile: gcc, pcc, limestone, ...)
--   (5) final report -- remaining 1-usage regional/meta tags (texas, midwest,
--       leadership, ...) are fine to leave as-is
-- ============================================================

-- (1) Promotions
insert into app.interest_tags (code, label_en, label_ko, sort_order) values
  ('generalist',      'Generalist Tech',        '제너럴리스트',   300),
  ('diversity_focus', 'Diversity-Focused',      '다양성 포커스',  310),
  ('non_dilutive',    'Non-Dilutive Funding',   '비희석 자금',    320)
on conflict (code) do update
  set label_en = excluded.label_en, label_ko = excluded.label_ko,
      sort_order = excluded.sort_order, updated_at = now();

-- (2) Aliases
insert into app.interest_tag_aliases (alias, canonical_code) values
  ('tech',                       'generalist'),
  ('technology',                 'generalist'),
  ('digital',                    'generalist'),
  ('oceans',                     'ocean_blue_economy'),
  ('sustainable_chemistry',      'specialty_chemicals'),
  ('ingredients',                'specialty_chemicals'),
  ('carbon_removal',             'climate_tech'),
  ('climate_software',           'climate_tech'),
  ('sustainable_infrastructure', 'climate_tech'),
  ('sustainable_industrial',     'industrial_decarbonization'),
  ('green_fuels',                'energy'),
  ('semiconductors',             'hardware'),
  ('devices',                    'hardware'),
  ('iot',                        'hardware'),
  ('wireless',                   'hardware'),
  ('computing',                  'ai'),
  ('ai_infra',                   'ai'),
  ('intelligence',               'ai'),
  ('health_tech',                'healthcare'),
  ('healthcare_it',              'healthcare'),
  ('healthcare_only',            'healthcare'),
  ('defense_tech',               'defense_space'),
  ('national_security',          'defense_space'),
  ('security',                   'cybersecurity'),
  ('marketplace',                'commerce'),
  ('women_led',                  'diversity_focus'),
  ('female_founders',            'diversity_focus'),
  ('diverse_founders',           'diversity_focus'),
  ('royalty_based',              'non_dilutive'),
  ('sbir_sttr',                  'non_dilutive'),
  ('angel_fund',                 'angel_network'),
  ('cvc_platform',               'cvc'),
  ('venture_studio',             'accelerator'),
  ('mobile',                     'software'),
  ('applications',               'software'),
  ('gaming',                     'consumer')
on conflict (alias) do update set canonical_code = excluded.canonical_code;

-- (3) Merge (same idempotent logic as prior passes)
insert into app.investor_interest_tags (investor_profile_id, interest_tag_id, organization_id)
select iit.investor_profile_id, canon.id, iit.organization_id
from app.investor_interest_tags iit
join app.interest_tags legacy on legacy.id = iit.interest_tag_id
join app.interest_tag_aliases a on a.alias = legacy.code
join app.interest_tags canon on canon.code = a.canonical_code and canon.id <> legacy.id
on conflict do nothing;

delete from app.investor_interest_tags iit
using app.interest_tags legacy, app.interest_tag_aliases a, app.interest_tags canon
where legacy.id = iit.interest_tag_id
  and a.alias = legacy.code
  and canon.code = a.canonical_code
  and canon.id <> legacy.id;

delete from app.interest_tags t
using app.interest_tag_aliases a, app.interest_tags canon
where a.alias = t.code and canon.code = a.canonical_code and canon.id <> t.id
  and not exists (select 1 from app.investor_interest_tags x where x.interest_tag_id = t.id);

-- (4) Drop usage-0 orphan auto-created tags (supplier/mill legacy vocabulary
-- with no investor link; regenerates automatically if ever needed)
delete from app.interest_tags t
where t.sort_order >= 900
  and not exists (select 1 from app.investor_interest_tags x where x.interest_tag_id = t.id)
  and not exists (select 1 from app.interest_tag_aliases a where a.canonical_code = t.code);

-- (5) Final report
select it.code, it.sort_order, count(iit.investor_profile_id) as usage
from app.interest_tags it
left join app.investor_interest_tags iit on iit.interest_tag_id = it.id
group by it.code, it.sort_order
order by (it.sort_order >= 900), usage desc, it.sort_order;
