-- ============================================================
-- seed_20261015b_brunei_mill.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Brunei update (reports 2026-10). LOW PRIORITY. Introduction -> intro_ko /
-- intro_en (only when empty), detail -> notes once with
-- 'BN check 2026-10-15', plant data -> Mill profile card.
--
-- No paper-grade PCC or GCC maker in Brunei - no filler rows. Heidelberg
-- Materials Butra makes cement (its "PCC 52.5N" is Portland Composite
-- Cement, not precipitated calcium carbonate).
-- Mill if missing + plant block: EnEvo (recycled tissue, own machine).
-- Paper importers and converters (Muji Paper, AFIA, Sagaria, Wan Sing,
-- Brunei Press) not added.
-- No FCC scenarios, no supply links.
--
-- Idempotent. Last statement is a verification select.
-- ============================================================

-- ---------- 2) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, intro_ko, intro_en, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'BN', v.region, v.city, v.website, 'active', 'brunei_update_20261015',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('%EnEvo%', '%Environmental Evolution%', 'EnEvo Sdn Bhd - Recycled Tissue Mill (Tutong)', 'Tutong', 'Serambangun', null, '2016년 설립 투퉁 Serambangun 의 EnEvo(Environmental Evolution). 회수 사무용지로 재생펄프를 만들어 화장지 직접 초조 — 브루나이 최초 상업 재생 화장지(2020-01).', 'EnEvo Sdn Bhd (Environmental Evolution, founded 2016), Serambangun Industrial Site, Tutong - pulps recovered office paper and makes toilet tissue on its own machine (Wangda equipment), Brunei''s first commercial recycled tissue (2020-01).', 'BN check 2026-10-15: about 2 t/day paper, up to 3 t/day waste-paper input (2020 press) - about 600-900 t/yr at 300 days, calculated. Over 100 t waste paper recycled by 2023 (national SDG report). Still collecting in 2025. GM Tan Kheng Tong. +673 422 0838, info.enevo@gmail.com. Nearby Malaysian supplier worth checking: Hai Ming Paper Mills (Kota Samarahan, Sarawak).')
) as v(name_like, alt_like, party_name, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BN'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
);

-- existing mill rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
    notes = case when m.notes is null or coalesce(p.notes, '') ilike '%BN check 2026-10-15%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
    updated_at = now()
from (
  select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BN'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%EnEvo%', '%Environmental Evolution%', '%EnEvo%', '2016년 설립 투퉁 Serambangun 의 EnEvo(Environmental Evolution). 회수 사무용지로 재생펄프를 만들어 화장지 직접 초조 — 브루나이 최초 상업 재생 화장지(2020-01).', 'EnEvo Sdn Bhd (Environmental Evolution, founded 2016), Serambangun Industrial Site, Tutong - pulps recovered office paper and makes toilet tissue on its own machine (Wangda equipment), Brunei''s first commercial recycled tissue (2020-01).', 'BN check 2026-10-15: about 2 t/day paper, up to 3 t/day waste-paper input (2020 press) - about 600-900 t/yr at 300 days, calculated. Over 100 t waste paper recycled by 2023 (national SDG report). Still collecting in 2025. GM Tan Kheng Tong. +673 422 0838, info.enevo@gmail.com. Nearby Malaysian supplier worth checking: Hai Ming Paper Mills (Kota Samarahan, Sarawak).')
  ) as v(name_like, alt_like, owner_like, intro_ko, intro_en, notes)
) m
where p.id = m.id and coalesce(p.source, '') <> 'brunei_update_20261015';

-- ---------- 4) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (
  select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BN'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%EnEvo%', '%Environmental Evolution%', '%EnEvo%')
  ) as v(name_like, alt_like, owner_like)
) m
where m.id is not null
  and not exists (select 1 from app.paper_mill_profile mp where mp.party_id = m.id);

update app.paper_mill_profile mp
set extra_data = coalesce(mp.extra_data, '{}'::jsonb) || jsonb_build_object('plant', m.plant),
    main_products = coalesce(nullif(btrim(mp.main_products), ''), m.plant ->> 'products'),
    updated_at = now()
from (
  select v.plant, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BN'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%EnEvo%', '%Environmental Evolution%', '%EnEvo%',
   $pj${"owner": "EnEvo Sdn Bhd", "priority": 1, "products": "100 pct recycled toilet tissue", "grades": ["Tissue"], "machines": 1, "capacity_split": [{"label": "About 2 t/day x 300 (calculated, 2020)", "value_t": 600}], "pitch": "Recycled-fibre tissue trial - a data set apart to the virgin-pulp tissue trial", "approach": "Technical proof only - royalty tiny (under USD 2,100/yr even at 15 pct). Real Brunei volume comes via Malaysian and Chinese paper exporters.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb)
  ) as v(name_like, alt_like, owner_like, plant)
) m
where mp.party_id = m.id;

-- ---------- 5) VERIFY ----------
with v(name_like, alt_like, owner_like) as (values
  ('%EnEvo%', '%Environmental Evolution%', '%EnEvo%')
)
select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_like) as name,
       case when p.source = 'brunei_update_20261015' then 'added now' when p.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from v
left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BN'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1)
left join app.paper_mill_profile mp on mp.party_id = p.id
union all
select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', '-'
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and l.extra_data ->> 'batch' = 'brunei_update_20261015'
order by 1, 4, 2;
