-- ============================================================
-- ALL-IN-ONE: interest tags normalize v2 + JSONB legacy backfill (2026-07-04)
-- >>> RUN THIS SINGLE FILE. No prerequisites, no ordering. Idempotent. <<<
-- Combines:
--   [A] migration_interest_tags_normalize_v2.sql  (tables, aliases, RLS,
--       canonical 22 tags, synonym merge incl. deep_tech_seed -> deep_tech,
--       wave 2-6 researched assignments)
--   [B] fix_backfill_interest_tags_jsonb.sql      (legacy parties.interest_tags
--       JSONB column -> normalized tables; column kept for the UI)
--   [C] final diagnostics (distribution, unmapped, missing wave-4 firms)
-- Supersedes: migration_interest_tags_normalize.sql (v1),
--   migration_interest_tags_normalize_v2.sql, fix_backfill_interest_tags_jsonb.sql
--   (keep only this file in sql\ going forward).
-- ============================================================

-- (1) Tables ---------------------------------------------------------------
create table if not exists app.interest_tags (
  id         bigint generated always as identity primary key,
  code       text not null unique,
  label_en   text not null,
  label_ko   text not null,
  sort_order int  not null default 100,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists app.interest_tag_aliases (
  alias          text primary key,
  canonical_code text not null references app.interest_tags(code) on update cascade on delete cascade,
  created_at     timestamptz not null default now()
);

create table if not exists app.investor_interest_tags (
  investor_profile_id uuid   not null references app.investor_profile(id) on delete cascade,
  interest_tag_id     bigint not null references app.interest_tags(id) on delete cascade,
  organization_id     uuid   not null,
  created_at          timestamptz not null default now(),
  primary key (investor_profile_id, interest_tag_id)
);

create index if not exists idx_investor_interest_tags_tag
  on app.investor_interest_tags(interest_tag_id);
create index if not exists idx_investor_interest_tags_org
  on app.investor_interest_tags(organization_id);

-- If investor_profile.id is bigint, the uuid FK fails at CREATE; run manually:
-- alter table app.investor_interest_tags
--   alter column investor_profile_id type bigint using investor_profile_id::bigint;

-- (2) RLS ------------------------------------------------------------------
alter table app.interest_tags enable row level security;
alter table app.interest_tag_aliases enable row level security;
alter table app.investor_interest_tags enable row level security;

do $rls$
declare org_expr text;
begin
  if exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
             where n.nspname = 'app' and p.proname = 'current_org_id') then
    org_expr := 'app.current_org_id()';
  else
    org_expr := $$ (auth.jwt() ->> 'organization_id')::uuid $$;
  end if;

  if not exists (select 1 from pg_policies where schemaname='app'
                 and tablename='interest_tags' and policyname='interest_tags_read_all') then
    execute 'create policy interest_tags_read_all on app.interest_tags
             for select to authenticated using (true)';
  end if;
  if not exists (select 1 from pg_policies where schemaname='app'
                 and tablename='interest_tag_aliases' and policyname='interest_tag_aliases_read_all') then
    execute 'create policy interest_tag_aliases_read_all on app.interest_tag_aliases
             for select to authenticated using (true)';
  end if;
  if not exists (select 1 from pg_policies where schemaname='app'
                 and tablename='investor_interest_tags' and policyname='investor_interest_tags_org_all') then
    execute format(
      'create policy investor_interest_tags_org_all on app.investor_interest_tags
       for all to authenticated using (organization_id = %s) with check (organization_id = %s)',
      org_expr, org_expr);
  end if;
end
$rls$;

-- (3) Canonical tag catalogue (22) -------------------------------------------
insert into app.interest_tags (code, label_en, label_ko, sort_order)
values
  ('pulp_paper',                 'Pulp & Paper',                '펄프·제지',            10),
  ('sustainable_packaging',      'Sustainable Packaging',       '지속가능 포장',        20),
  ('biomaterials',               'Biomaterials',                '바이오소재',           30),
  ('advanced_materials',         'Advanced Materials',          '첨단소재',             35),
  ('ocean_blue_economy',         'Ocean & Blue Economy',        '해양·블루이코노미',    40),
  ('specialty_chemicals',        'Specialty Chemicals',         '특수화학',             50),
  ('circular_economy',           'Circular Economy',            '순환경제',             60),
  ('industrial_decarbonization', 'Industrial Decarbonization',  '산업 탈탄소',          70),
  ('industrial',                 'Industrial',                  '산업 일반',            75),
  ('climate_tech',               'Climate Tech',                '기후 기술',            80),
  ('energy',                     'Energy',                      '에너지',               85),
  ('deep_tech',                  'Deep Tech',                   '딥테크',               90),
  ('hardware',                   'Hardware & Robotics',         '하드웨어·로보틱스',    95),
  ('cvc',                        'Corporate VC',                '기업형 VC',           100),
  ('catalytic_capital',          'Catalytic / Philanthropic',   '촉매·자선 자본',      110),
  ('grant_funding',              'Grant Funding',               '그랜트 자금',         120),
  ('femtech_womens_health',      'Femtech & Womens Health',     '펨테크·여성건강',     130),
  ('korea_cross_border',         'Korea Cross-Border',          '한국 크로스보더',     140),
  ('university_spinout',         'University Spinouts',         '대학 스핀아웃',       150),
  ('healthcare',                 'Healthcare',                  '헬스케어',            160),
  ('logistics_supply_chain',     'Logistics & Supply Chain',    '물류·공급망',         170),
  ('food_agriculture',           'Food & Agriculture',          '식품·농업',           180)
on conflict (code) do update
  set label_en = excluded.label_en, label_ko = excluded.label_ko,
      sort_order = excluded.sort_order, updated_at = now();

-- (4) Alias map (synonyms -> canonical) ---------------------------------------
insert into app.interest_tag_aliases (alias, canonical_code)
values
  -- deep tech variants (incl. v1's deep_tech_seed)
  ('deeptech',            'deep_tech'),
  ('deep_tech_seed',      'deep_tech'),
  ('hardtech',            'deep_tech'),
  ('frontier_tech',       'deep_tech'),
  -- materials / chemicals
  ('materials',           'advanced_materials'),
  ('advanced_material',   'advanced_materials'),
  ('new_materials',       'advanced_materials'),
  ('chemicals_materials', 'specialty_chemicals'),
  ('chemicals',           'specialty_chemicals'),
  ('chemistry',           'specialty_chemicals'),
  -- climate variants
  ('climate',             'climate_tech'),
  ('climatetech',         'climate_tech'),
  ('cleantech',           'climate_tech'),
  ('sustainability',      'climate_tech'),
  ('decarbonization',     'industrial_decarbonization'),
  -- packaging / circular / paper
  ('packaging',           'sustainable_packaging'),
  ('circular',            'circular_economy'),
  ('recycling',           'circular_economy'),
  ('paper',               'pulp_paper'),
  ('pulp',                'pulp_paper'),
  ('forestry',            'pulp_paper'),
  ('forest_industry',     'pulp_paper'),
  -- bio / ocean
  ('biomaterial',         'biomaterials'),
  ('bio_materials',       'biomaterials'),
  ('biotech_materials',   'biomaterials'),
  ('ocean',               'ocean_blue_economy'),
  ('marine',              'ocean_blue_economy'),
  ('blue_economy',        'ocean_blue_economy'),
  ('oceantech',           'ocean_blue_economy'),
  -- health
  ('health',              'healthcare'),
  ('medtech',             'healthcare'),
  ('digital_health',      'healthcare'),
  -- logistics / food / energy / hardware
  ('logistics',           'logistics_supply_chain'),
  ('supply_chain',        'logistics_supply_chain'),
  ('food_ag',             'food_agriculture'),
  ('agtech',              'food_agriculture'),
  ('agriculture',         'food_agriculture'),
  ('foodtech',            'food_agriculture'),
  ('energy_transition',   'energy'),
  ('clean_energy',        'energy'),
  ('robotics',            'hardware'),
  -- capital types / other
  ('corporate_vc',        'cvc'),
  ('corporate_venture',   'cvc'),
  ('foundation',          'catalytic_capital'),
  ('philanthropy',        'catalytic_capital'),
  ('impact',              'catalytic_capital'),
  ('grants',              'grant_funding'),
  ('femtech',             'femtech_womens_health'),
  ('womens_health',       'femtech_womens_health'),
  ('korea',               'korea_cross_border'),
  ('university',          'university_spinout'),
  ('spinout',             'university_spinout')
on conflict (alias) do update set canonical_code = excluded.canonical_code;

-- (5) MERGE: collapse any existing non-canonical tag rows ----------------------
-- (covers v1 leftovers like deep_tech_seed and any auto-created variants)
-- 5a. remap links to canonical
insert into app.investor_interest_tags (investor_profile_id, interest_tag_id, organization_id)
select iit.investor_profile_id, canon.id, iit.organization_id
from app.investor_interest_tags iit
join app.interest_tags legacy on legacy.id = iit.interest_tag_id
join app.interest_tag_aliases a on a.alias = legacy.code
join app.interest_tags canon on canon.code = a.canonical_code and canon.id <> legacy.id
on conflict do nothing;

-- 5b. drop old links
delete from app.investor_interest_tags iit
using app.interest_tags legacy, app.interest_tag_aliases a, app.interest_tags canon
where legacy.id = iit.interest_tag_id
  and a.alias = legacy.code
  and canon.code = a.canonical_code
  and canon.id <> legacy.id;

-- 5c. drop orphaned non-canonical tag rows
delete from app.interest_tags t
using app.interest_tag_aliases a, app.interest_tags canon
where a.alias = t.code and canon.code = a.canonical_code and canon.id <> t.id
  and not exists (select 1 from app.investor_interest_tags x where x.interest_tag_id = t.id);

-- (6) Backfill from legacy tags column (alias-aware; column is KEPT) ----------
do $legacy$
declare
  rec record;
begin
  for rec in
    select c.table_name, c.data_type
    from information_schema.columns c
    where c.table_schema = 'app'
      and c.table_name in ('investor_profile', 'parties')
      and c.column_name = 'tags'
  loop
    -- 6a. auto-create canonical-or-new tags from distinct legacy values
    execute format($q$
      with raw as (
        select %s as ref_id, %s as org_id,
               regexp_replace(lower(btrim(t)), '[^a-z0-9]+', '_', 'g') as slug
        from app.%I src
        cross join lateral %s as t
        where btrim(t) <> ''
      ),
      resolved as (
        select r.*, coalesce(a.canonical_code, r.slug) as code
        from raw r
        left join app.interest_tag_aliases a on a.alias = r.slug
      )
      insert into app.interest_tags (code, label_en, label_ko, sort_order)
      select distinct code, code, code, 900 from resolved
      on conflict (code) do nothing
    $q$,
      case when rec.table_name = 'investor_profile' then 'src.id' else 'src.id' end,
      'src.organization_id',
      rec.table_name,
      case when rec.data_type = 'ARRAY'
           then 'unnest(src.tags)'
           else $$regexp_split_to_table(coalesce(src.tags,''), '\s*,\s*')$$ end
    );

    -- 6b. link to investor_profile (parties route through their profile)
    if rec.table_name = 'investor_profile' then
      execute format($q$
        insert into app.investor_interest_tags (investor_profile_id, interest_tag_id, organization_id)
        select ip.id, it.id, ip.organization_id
        from app.investor_profile ip
        cross join lateral %s as t
        join app.interest_tags it on it.code = coalesce(
          (select a.canonical_code from app.interest_tag_aliases a
            where a.alias = regexp_replace(lower(btrim(t)), '[^a-z0-9]+', '_', 'g')),
          regexp_replace(lower(btrim(t)), '[^a-z0-9]+', '_', 'g'))
        where btrim(t) <> ''
        on conflict do nothing
      $q$, case when rec.data_type = 'ARRAY'
                then 'unnest(ip.tags)'
                else $$regexp_split_to_table(coalesce(ip.tags,''), '\s*,\s*')$$ end);
      raise notice 'Backfilled from app.investor_profile.tags (column kept for UI)';
    else
      execute format($q$
        insert into app.investor_interest_tags (investor_profile_id, interest_tag_id, organization_id)
        select ip.id, it.id, p.organization_id
        from app.parties p
        join app.investor_profile ip on ip.party_id = p.id
        cross join lateral %s as t
        join app.interest_tags it on it.code = coalesce(
          (select a.canonical_code from app.interest_tag_aliases a
            where a.alias = regexp_replace(lower(btrim(t)), '[^a-z0-9]+', '_', 'g')),
          regexp_replace(lower(btrim(t)), '[^a-z0-9]+', '_', 'g'))
        where btrim(t) <> '' and p.deleted_at is null
        on conflict do nothing
      $q$, case when rec.data_type = 'ARRAY'
                then 'unnest(p.tags)'
                else $$regexp_split_to_table(coalesce(p.tags,''), '\s*,\s*')$$ end);
      raise notice 'Backfilled from app.parties.tags (column kept for UI)';
    end if;
  end loop;
end
$legacy$;

-- (7) Researched assignments for waves 2-6 (deep_tech canonical) --------------
insert into app.investor_interest_tags (investor_profile_id, interest_tag_id, organization_id)
select ip.id, it.id, ip.organization_id
from (values
  ('UB Forest Industry%','pulp_paper'),('UB Forest Industry%','biomaterials'),
  ('UB Forest Industry%','sustainable_packaging'),('UB Forest Industry%','circular_economy'),
  ('Mets%Spring%','pulp_paper'),('Mets%Spring%','sustainable_packaging'),('Mets%Spring%','cvc'),
  ('Sofinnova Partners%','biomaterials'),('Sofinnova Partners%','specialty_chemicals'),
  ('Voima Ventures%','deep_tech'),('Voima Ventures%','biomaterials'),('Voima Ventures%','university_spinout'),
  ('HG Ventures%','specialty_chemicals'),('HG Ventures%','industrial_decarbonization'),
  ('HG Ventures%','circular_economy'),('HG Ventures%','cvc'),
  ('%Syensqo%','specialty_chemicals'),('%Syensqo%','biomaterials'),('%Syensqo%','cvc'),
  ('Evonik%','specialty_chemicals'),('Evonik%','circular_economy'),('Evonik%','cvc'),
  ('Collateral Good%','climate_tech'),('Collateral Good%','sustainable_packaging'),
  ('Propeller VC%','ocean_blue_economy'),('Propeller VC%','climate_tech'),
  ('SWEN%','ocean_blue_economy'),('Katapult%','ocean_blue_economy'),
  ('Planet A%','climate_tech'),('Planet A%','biomaterials'),
  ('Icos Capital%','industrial_decarbonization'),('Icos Capital%','specialty_chemicals'),
  ('Capricorn Partners%','specialty_chemicals'),('Capricorn Partners%','climate_tech'),
  ('DCVC%','deep_tech'),('DCVC%','climate_tech'),
  ('Fifty Years%','deep_tech'),('Fifty Years%','biomaterials'),
  ('Congruent%','climate_tech'),('Congruent%','industrial_decarbonization'),
  ('Khosla%','deep_tech'),('Khosla%','climate_tech'),('Rhapsody%','deep_tech'),
  ('Koch Disruptive%','cvc'),('Koch Disruptive%','pulp_paper'),('Koch Disruptive%','specialty_chemicals'),
  ('Breakthrough Energy%','climate_tech'),('Breakthrough Energy%','industrial_decarbonization'),
  ('ADM Ventures%','cvc'),('ADM Ventures%','biomaterials'),
  ('1955 Capital%','climate_tech'),('1955 Capital%','industrial_decarbonization'),('1955 Capital%','korea_cross_border'),
  ('Seabird%','ocean_blue_economy'),
  ('Energy Impact Partners%','climate_tech'),('Energy Impact Partners%','energy'),
  ('Osage University%','university_spinout'),('Osage University%','deep_tech'),
  ('Elemental Impact%','climate_tech'),('Elemental Impact%','grant_funding'),
  ('Cantos%','deep_tech'),('Humba%','deep_tech'),
  ('Refactor Capital%','biomaterials'),('Refactor Capital%','deep_tech'),
  ('Compound VC%','deep_tech'),('Compound VC%','university_spinout'),
  ('Overlay Capital%','sustainable_packaging'),('Overlay Capital%','circular_economy'),
  ('Ponderosa Ventures%','ocean_blue_economy'),('Ponderosa Ventures%','biomaterials'),
  ('Schmidt Marine%','ocean_blue_economy'),('Schmidt Marine%','catalytic_capital'),('Schmidt Marine%','grant_funding'),
  ('Pivotal Ventures%','femtech_womens_health'),
  ('Grantham Foundation%','climate_tech'),('Grantham Foundation%','catalytic_capital'),
  ('Gates Foundation%','catalytic_capital'),('Gates Foundation%','femtech_womens_health'),
  ('Emerson Collective%','catalytic_capital'),('Emerson Collective%','climate_tech'),
  ('Autodesk Foundation%','catalytic_capital'),('Autodesk Foundation%','grant_funding'),
  ('Autodesk Foundation%','industrial_decarbonization'),
  ('Prime Coalition%','catalytic_capital'),('Prime Coalition%','climate_tech'),
  ('Bezos Earth Fund%','grant_funding'),('Bezos Earth Fund%','ocean_blue_economy'),
  ('LyondellBasell%','cvc'),('LyondellBasell%','circular_economy'),('LyondellBasell%','specialty_chemicals'),
  ('8090 Industries%','industrial_decarbonization'),
  ('Innovation Endeavors%','deep_tech'),('Innovation Endeavors%','biomaterials'),
  ('Obvious Ventures%','climate_tech'),('MetaVC%','deep_tech'),('MetaVC%','advanced_materials'),
  ('Fine Structure%','deep_tech'),('Fine Structure%','advanced_materials'),
  ('Third Sphere%','climate_tech'),('Third Sphere%','hardware'),
  ('Clean Energy Ventures%','climate_tech'),('Clean Energy Ventures%','energy'),
  ('Good Growth Capital%','deep_tech'),('Good Growth Capital%','university_spinout'),
  ('Overture VC%','climate_tech'),
  ('Altos Ventures%','korea_cross_border'),
  ('Primer Sazze%','korea_cross_border'),('Primer Sazze%','deep_tech'),
  ('LG Technology Ventures%','korea_cross_border'),('LG Technology Ventures%','cvc'),
  ('LG Technology Ventures%','specialty_chemicals'),
  ('Bluepoint Partners%','korea_cross_border'),('Bluepoint Partners%','deep_tech'),
  ('Bluepoint Partners%','university_spinout'),
  ('Kolon Investment%','korea_cross_border'),('Kolon Investment%','cvc'),('Kolon Investment%','specialty_chemicals'),
  ('Goodwater Capital%','korea_cross_border'),('Strong Ventures%','korea_cross_border'),
  ('SBVA%','korea_cross_border'),
  ('Samsung Venture Investment%','korea_cross_border'),('Samsung Venture Investment%','cvc'),
  ('Big Basin Capital%','korea_cross_border'),
  ('FuturePlay%','korea_cross_border'),('FuturePlay%','deep_tech'),
  ('Aju IB%','korea_cross_border'),('Aju IB%','biomaterials')
) as m(match_pat, tag_code)
join app.parties p
  on coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike m.match_pat
 and p.deleted_at is null
 and p.source in ('web_research_2026Q3','web_research_2026Q3_us','web_research_2026Q3_phil',
                  'web_research_2026Q3_us2','web_research_2026Q3_kr')
join app.investor_profile ip on ip.party_id = p.id
join app.interest_tags it on it.code = m.tag_code
on conflict do nothing;

-- (8) Verification -------------------------------------------------------------
-- 8a. catalogue (canonical first; sort_order 900 = auto-created, needs curation)
select code, label_ko, label_en, sort_order,
       (sort_order >= 900) as needs_curation
from app.interest_tags order by sort_order, code;

-- 8b. UNMAPPED report: auto-created tags to review -> add alias or promote
select it.code, count(iit.investor_profile_id) as usage
from app.interest_tags it
left join app.investor_interest_tags iit on iit.interest_tag_id = it.id
where it.sort_order >= 900
group by it.code order by usage desc;

-- 8c. tag distribution
select it.code, it.label_ko, count(*) as investors
from app.investor_interest_tags iit
join app.interest_tags it on it.id = iit.interest_tag_id
group by it.code, it.label_ko order by investors desc;

-- 8d. per-investor tags (Advanced Materials sector view parity check vs UI)
select p.party_name, array_agg(it.code order by it.sort_order) as interest_tags
from app.parties p
join app.investor_profile ip on ip.party_id = p.id
join app.investor_interest_tags iit on iit.investor_profile_id = ip.id
join app.interest_tags it on it.id = iit.interest_tag_id
where p.deleted_at is null
group by p.party_name order by p.party_name;

-- ============================================================
-- (9) CLEANUP -- run ONLY AFTER the directory/detail UI reads the normalized
--     tables (do not run now; the TAGS column still reads the legacy field):
-- do $$ begin
--   if exists (select 1 from information_schema.columns where table_schema='app'
--              and table_name='investor_profile' and column_name='tags') then
--     execute 'alter table app.investor_profile rename column tags to tags_legacy';
--   end if;
--   if exists (select 1 from information_schema.columns where table_schema='app'
--              and table_name='parties' and column_name='tags') then
--     execute 'alter table app.parties rename column tags to tags_legacy';
--   end if;
-- end $$;
-- ============================================================

-- ============================================================
-- [B] LEGACY BACKFILL: app.parties.interest_tags (JSONB) -> normalized
-- ============================================================

-- B1. create canonical-or-new tags from distinct legacy values (alias-aware)
with raw as (
  select regexp_replace(lower(btrim(t)), '[^a-z0-9]+', '_', 'g') as slug
  from app.parties p
  cross join lateral jsonb_array_elements_text(
    case when jsonb_typeof(coalesce(p.interest_tags, '[]'::jsonb)) = 'array'
         then p.interest_tags else '[]'::jsonb end
  ) as t
  where p.deleted_at is null and btrim(t) <> ''
),
resolved as (
  select distinct coalesce(a.canonical_code, r.slug) as code
  from raw r
  left join app.interest_tag_aliases a on a.alias = r.slug
)
insert into app.interest_tags (code, label_en, label_ko, sort_order)
select code, code, code, 900 from resolved
on conflict (code) do nothing;

-- B2. link to investor profiles (parties without a profile are skipped)
insert into app.investor_interest_tags (investor_profile_id, interest_tag_id, organization_id)
select ip.id, it.id, p.organization_id
from app.parties p
join app.investor_profile ip on ip.party_id = p.id
cross join lateral jsonb_array_elements_text(
  case when jsonb_typeof(coalesce(p.interest_tags, '[]'::jsonb)) = 'array'
       then p.interest_tags else '[]'::jsonb end
) as t
join app.interest_tags it on it.code = coalesce(
  (select a.canonical_code from app.interest_tag_aliases a
    where a.alias = regexp_replace(lower(btrim(t)), '[^a-z0-9]+', '_', 'g')),
  regexp_replace(lower(btrim(t)), '[^a-z0-9]+', '_', 'g'))
where p.deleted_at is null and btrim(t) <> ''
on conflict do nothing;

-- B3. legacy values may include synonyms just auto-created in B1/B2 as
-- non-canonical rows if an alias was missing; re-run the canonical merge so
-- anything alias-mapped collapses (same logic as [A] step 5, idempotent).
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

-- ============================================================
-- [C] FINAL DIAGNOSTICS
-- ============================================================

-- C1. distribution (deep_tech_seed must NOT appear; deep_tech should be >= 18)
select it.code, it.label_ko, count(*) as investors
from app.investor_interest_tags iit
join app.interest_tags it on it.id = iit.interest_tag_id
group by it.code, it.label_ko order by investors desc;

-- C2. unmapped auto-created tags (sort_order 900) -> curate via aliases
select it.code, count(iit.investor_profile_id) as usage
from app.interest_tags it
left join app.investor_interest_tags iit on iit.interest_tag_id = it.id
where it.sort_order >= 900
group by it.code order by usage desc;

-- C3. wave-4 presence check (run seed_investor_philanthropic_wave4_us.sql for
-- any row where found = false)
with w4(firm, pat) as (values
  ('Schmidt Marine','Schmidt Marine%'),('Pivotal Ventures','Pivotal Ventures%'),
  ('Grantham Foundation','Grantham Foundation%'),('Gates SIF','Gates Foundation%'),
  ('Emerson Collective','Emerson Collective%'),('Autodesk Foundation','Autodesk Foundation%'),
  ('Prime Coalition','Prime Coalition%'),('Bezos Earth Fund','Bezos Earth Fund%')
)
select w4.firm, (p.id is not null) as found
from w4
left join app.parties p
  on coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') ilike w4.pat
 and p.deleted_at is null
order by found, w4.firm;
