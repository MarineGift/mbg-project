-- ============================================================
-- CURATION: promote & merge auto-created legacy tags (2026-07-04)
-- Input: C1 distribution 2026-07-05 (~70 auto-created sort_order-900 tags).
-- Idempotent; safe to re-run. Run any time after fix_interest_tags_all_in_one.
--   (1) promote high-usage legacy tags to canonical (ko/en labels, sort<900)
--   (2) add aliases folding synonym sprawl into canonicals
--   (3) re-run the canonical merge (same logic as all-in-one [B3])
--   (4) verify: remaining 900s should be low-usage long tail only
-- ============================================================

-- (1) Promotions (upsert labels + sort_order)
insert into app.interest_tags (code, label_en, label_ko, sort_order) values
  ('life_science',  'Life Science',      '라이프사이언스', 165),
  ('fintech',       'Fintech',           '핀테크',         200),
  ('consumer',      'Consumer',          '컨슈머',         210),
  ('enterprise',    'Enterprise',        '엔터프라이즈',   220),
  ('ai',            'AI',                'AI',             230),
  ('software',      'Software & SaaS',   '소프트웨어·SaaS', 240),
  ('web3_crypto',   'Web3 & Crypto',     '웹3·크립토',     250),
  ('defense_space', 'Defense & Space',   '방산·우주',      260),
  ('accelerator',   'Accelerator',       '액셀러레이터',   270),
  ('angel_network', 'Angel Network',     '엔젤 네트워크',  275),
  ('commerce',      'Commerce & Retail', '커머스·리테일',  280),
  ('mobility',      'Mobility',          '모빌리티',       285),
  ('media',         'Media',             '미디어',         290),
  ('cybersecurity', 'Cybersecurity',     '사이버보안',     295)
on conflict (code) do update
  set label_en = excluded.label_en, label_ko = excluded.label_ko,
      sort_order = excluded.sort_order, updated_at = now();

-- (2) Alias additions (synonym -> canonical)
insert into app.interest_tag_aliases (alias, canonical_code) values
  -- software sprawl
  ('saas',                  'software'),
  ('b2b_saas',              'software'),
  ('b2b_software',          'software'),
  ('enterprise_saas',       'software'),
  ('enterprise_software',   'software'),
  ('industrial_software',   'software'),
  ('b2b',                   'enterprise'),
  ('internet',              'consumer'),
  ('consumer_tech',         'consumer'),
  ('cpg',                   'consumer'),
  ('retail_tech',           'commerce'),
  ('marketplaces',          'commerce'),
  -- life science / health
  ('life_sciences',         'life_science'),
  ('biotech',               'life_science'),
  ('bio',                   'life_science'),
  ('biology',               'life_science'),
  ('healthtech',            'healthcare'),
  -- materials / deep tech
  ('sustainable_materials', 'advanced_materials'),
  ('bio_based_materials',   'advanced_materials'),
  ('materials_science',     'advanced_materials'),
  ('hard_tech',             'deep_tech'),
  ('frontier',              'deep_tech'),
  ('biomanufacturing',      'biomaterials'),
  ('industrial_bio',        'biomaterials'),
  ('synthetic_biology',     'biomaterials'),
  ('bioeconomy',            'biomaterials'),
  ('plastics',              'specialty_chemicals'),
  -- climate / energy / food
  ('water',                 'climate_tech'),
  ('nature_positive',       'climate_tech'),
  ('energy_tech',           'energy'),
  ('upstream',              'energy'),
  ('midstream',             'energy'),
  ('food',                  'food_agriculture'),
  ('beverage',              'food_agriculture'),
  ('sustainable_food',      'food_agriculture'),
  -- industrial
  ('construction',          'industrial'),
  ('manufacturing',         'industrial'),
  -- web3 / defense
  ('crypto',                'web3_crypto'),
  ('web3',                  'web3_crypto'),
  ('blockchain',            'web3_crypto'),
  ('defense',               'defense_space'),
  ('aerospace',             'defense_space'),
  ('space',                 'defense_space'),
  -- investor-type / misc
  ('angel_network_alliance','angel_network'),
  ('cyber',                 'cybersecurity')
on conflict (alias) do update set canonical_code = excluded.canonical_code;

-- (3) Merge non-canonical rows into canonicals (idempotent)
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

-- (4) Verification: remaining auto-created long tail (curate later or ignore)
select it.code, count(iit.investor_profile_id) as usage
from app.interest_tags it
left join app.investor_interest_tags iit on iit.interest_tag_id = it.id
where it.sort_order >= 900
group by it.code order by usage desc;
