-- ============================================================
-- seed_20261015u_belize_mills.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Belize update (reports 2026-10-15). No paper-grade PCC / GCC maker, so no
-- filler rows (Limbe agricultural lime and village lime kilns excluded).
-- 1) Mill if missing + plant block, priority 1: Caribbean Paper Mill Company
--    (Orange Walk) - Caribbean Paper Company treated as the same mill.
--    Context, match only: Roses Paper Products (converter).
-- 2) app.country_markets BZ row (priority low).
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
       v.party_name, 'BZ', v.region, v.city, v.website, 'active', 'belize_update_20261015',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('caribbean paper', 'orange walk', 'caribbean', 'Caribbean Paper Mill Company (Orange Walk)', 'Orange Walk', 'Orange Walk', null, '벨리즈 티슈 제조사(1997년 Caribbean Paper Company 로 가공 시작, 2014년부터 폐지·버진 펄프로 원지 제조). 화장지·냅킨·키친타월·기관용 핸드타월, 카리브해 수출(2026년 선적 확인).', 'Caribbean Paper Mill Company, 5 Miles San Estevan Road, Orange Walk District (linked to Caribbean Paper Company, Mile 13 George Price Highway - converting since 1997, papermaking on waste paper and virgin pulp since 2014). Toilet tissue, napkins, kitchen towel, institutional hand towel (brands Softy, Class, Tender), exports to Caribbean islands - shipments seen 2026-06 to 2026-10.', 'BZ check 2026-10-15: historical record of 5.5 t/day waste paper (about 2,002 t/yr, input not output). Environment Department compliance plan posted 2024-02-19. Current paper machine, capacity and filler use not confirmed. +501 225-6080, +501 615-2995, commercialcaribbeanpaper@gmail.com (2019 contact). Company and Mill Company treated as one mill.')
) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;

-- existing mill rows (incl. context rows): fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
    notes = case when m.notes is null or coalesce(p.notes, '') ilike '%BZ check 2026-10-15%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
    updated_at = now()
from (
  select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
  from (values
  ('caribbean paper', 'orange walk', 'caribbean', '벨리즈 티슈 제조사(1997년 Caribbean Paper Company 로 가공 시작, 2014년부터 폐지·버진 펄프로 원지 제조). 화장지·냅킨·키친타월·기관용 핸드타월, 카리브해 수출(2026년 선적 확인).', 'Caribbean Paper Mill Company, 5 Miles San Estevan Road, Orange Walk District (linked to Caribbean Paper Company, Mile 13 George Price Highway - converting since 1997, papermaking on waste paper and virgin pulp since 2014). Toilet tissue, napkins, kitchen towel, institutional hand towel (brands Softy, Class, Tender), exports to Caribbean islands - shipments seen 2026-06 to 2026-10.', 'BZ check 2026-10-15: historical record of 5.5 t/day waste paper (about 2,002 t/yr, input not output). Environment Department compliance plan posted 2024-02-19. Current paper machine, capacity and filler use not confirmed. +501 225-6080, +501 615-2995, commercialcaribbeanpaper@gmail.com (2019 contact). Company and Mill Company treated as one mill.'),
  ('roses paper', null, 'roses paper', null, null, 'BZ check 2026-10-15: Roses Paper Products, 2.5 Miles Northern Highway, Belize City - tissue products, own paper machine not confirmed (US shipments until 2014). Not the US firm Roses Southwest Papers.')
  ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
) m
where p.id = m.id and coalesce(p.source, '') <> 'belize_update_20261015';

-- ---------- 3) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (
  select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
  from (values
  ('caribbean paper', 'orange walk', 'caribbean'),
  ('roses paper', null, 'roses paper')
  ) as v(name_rx, city_rx, owner_rx)
) m
where m.id is not null
  and not exists (select 1 from app.paper_mill_profile mp where mp.party_id = m.id);

update app.paper_mill_profile mp
set extra_data = coalesce(mp.extra_data, '{}'::jsonb) || jsonb_build_object('plant', m.plant),
    main_products = coalesce(nullif(btrim(mp.main_products), ''), m.plant ->> 'products'),
    updated_at = now()
from (
  select v.plant, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
  from (values
  ('caribbean paper', 'orange walk', 'caribbean',
   $pj${"owner": "Caribbean Paper", "priority": 1, "products": "Toilet tissue, napkins, kitchen towel, hand towel", "grades": ["Tissue"], "pitch": "Small tissue FCC proof for the Caribbean export market", "approach": "Confirm the running paper machine and output first. FCC supply would come by Guatemala or Mexico producers.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('roses paper', null, 'roses paper',
   $pj${"owner": "Roses Paper Products", "products": "Tissue products - converter", "approach": "Confirm own base-paper making.", "checked_at": "2026-10-15"}$pj$::jsonb)
  ) as v(name_rx, city_rx, owner_rx, plant)
) m
where mp.party_id = m.id;

-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'BZ', 'Belize', 'low',
   $cm$One small tissue mill (Caribbean Paper, Orange Walk) - no paper PCC or GCC, carbonate imports mostly Guatemalan$cm$,
   $cm$No paper-grade PCC or GCC plant. Limbe (Spanish Lookout) crushes limestone for agricultural lime (2 mm) and five small lime kilns produce about 283 t/yr. Calcium carbonate imports were 2,499 t in 2024, 85.6 pct of it Guatemalan. The only papermaker is Caribbean Paper Mill Company (Orange Walk) - tissue for Belize and Caribbean islands. Others are converters or distributors.$cm$,
   $cm${"fillers": "None for paper. Limbe (agricultural lime, road aggregate, 2 mm) and five lime kilns at St. Margaret Village (about 283 t/yr) - not added. HS 283650 imports 2024: 2,499 t, Guatemala 2,139 t, Mexico 333 t.", "mills": "Caribbean Paper Mill Company, Orange Walk - tissue, papermaking since 2014 (Caribbean Paper Company is the same business). Converters and distributors, not added: Roses Paper Products, GraceKennedy Belize, Paper Box Belize, Gitz, Angelus Press, Norman's Printing.", "strategy": "Treat as an export market of Guatemala and Mexico FCC producers. Small tissue proof at Caribbean Paper once the running machine is confirmed.", "risks": "Very small volumes, machine output not public.", "next_steps": ["Confirm Caribbean Paper machine count and tissue output"], "key_numbers": [{"label": "HS 48 imports 2024", "value": "USD 24.32 m (Guatemala, US, Mexico lead)"}, {"label": "HS 48 exports 2024", "value": "USD 2.23 m (Jamaica, Guyana, Antigua)"}, {"label": "Calcium carbonate imports 2024", "value": "2,499 t, 85.6 pct Guatemala"}], "files": ["seed_20261015u_belize_mills"]}$cm$::jsonb,
   $cm$소형 티슈 공장 1곳(Caribbean Paper, Orange Walk) — 제지용 PCC·GCC 없음, 탄산칼슘은 과테말라 수입$cm$,
   $cm$제지용 PCC·GCC 공장 없음(Limbe 는 농업용 석회 2 mm, 석회 가마 5곳 연 283 t). 2024 탄산칼슘 수입 2,499 t 중 과테말라 85.6%. 원지 제조사는 Caribbean Paper Mill Company(Orange Walk) 티슈뿐 — 카리브해 수출. 과테말라·멕시코 FCC 생산거점의 수출시장으로 분류.$cm$,
   null, null,
   $cm$원지 생산량 미공개 — 산정 보류 (5,000 t × 5% 예시 시 250 t)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
with v(name_rx, city_rx, owner_rx) as (values
  ('caribbean paper', 'orange walk', 'caribbean'),
  ('roses paper', null, 'roses paper')
)
select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
       case when p.source = 'belize_update_20261015' then 'added now' when p.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from v
left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
left join app.paper_mill_profile mp on mp.party_id = p.id
union all
select 'filler', p.party_name,
       case when p.source = 'belize_update_20261015' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (false)
union all
select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and m.country_code = 'BZ'
union all
select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
       coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
from app.country_markets cm
where cm.country_code = 'BZ'
union all
select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
       coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
from app.parties p
left join app.paper_mill_profile mp on mp.party_id = p.id
where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'BZ'
  and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'BZ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
order by 1, 4, 2;
