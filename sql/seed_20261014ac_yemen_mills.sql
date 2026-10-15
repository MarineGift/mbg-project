-- ============================================================
-- seed_20261014ac_yemen_mills.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Yemen update (reports 2026-10). LOW PRIORITY, record only.
-- No paper-grade PCC or GCC maker found - no filler rows added (Jordanian
-- suppliers to Yemen belong to Jordan). Introduction -> intro_ko / intro_en
-- (only when empty), detail -> notes once with 'YE check 2026-10-14'.
--
-- SANCTIONS: Ansar Allah (Houthis), who control Sana'a and parts of Taiz,
-- are US-designated. Every plant block says to screen against the OFAC SDN
-- list before any contact.
--
-- Mills if missing + plant blocks: 1 NCSPI (HSA, Taiz)  2 Al-Ganad (Taiz)
-- context: National Company for Paper Products (Sana'a), National Carton
-- (HSA). All likely converters - own paper machines not confirmed.
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
       v.party_name, 'YE', v.region, v.city, v.website, 'active', 'yemen_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('%Sponge%Plastic%', '%NCSPI%', 'National Company for Sponge & Plastic Industry - HSA (Taiz)', 'Taiz', 'Al-Hawban', null, 'HSA Group 계열 National Company for Sponge & Plastic Industry(1974년 설립, 타이즈 Al-Hawban). 스펀지·플라스틱·티슈 제품, 1994년 자료상 티슈 가공.', 'National Company for Sponge and Plastic Industry (HSA Group, founded 1974), Al-Hawban Airport Street, Taiz - sponge, plastics and tissue products, tissue converting per 1994 profile.', 'YE check 2026-10-14: own tissue machine and capacity not confirmed. Contact per HSA directory +967 4 218999, ncspi@hsa.com.ye.'),
  ('%Ganad%', '%Al-Ganad%', 'Al-Ganad Light Industries (Taiz)', 'Taiz', 'Al-Janad', 'https://www.gan-light.com', '1990년 설립 Al-Ganad Light Industries(타이즈 Al-Janad). 학교 노트·인쇄물로 시작, 2006-07 티슈 공장 가동(Style·Yasmin·Royal Golden).', 'Al-Ganad Light Industries (founded 1990, producing since 1993), Al-Janad, Taiz - school notebooks and printing, tissue plant since 2006-07 (Style, Yasmin, Royal Golden brands).', 'YE check 2026-10-14: notebooks use bought paper rolls - no own printing-paper machine. Tissue base-paper making not confirmed.'),
  ('%National Company for Paper Products%', '%Yemen Paper%', 'National Company for Paper Products (Sana''a)', 'Sana''a', 'Sana''a', 'https://www.yemenpaper.com', '사나의 National Company for Paper Products. Fel 브랜드 위생용 종이제품.', 'National Company for Paper Products Ltd., Sana''a - Fel-brand hygiene paper products.', 'YE check 2026-10-14: base-paper making not confirmed - ask jumbo-roll origin. Tel +967 1 526954, yemenpaper@gmail.com.'),
  ('%National Carton Industries%', '%NCIC%Yemen%', 'National Carton Industries Company - HSA (Taiz)', 'Taiz', null, null, 'HSA Group 계열 National Carton Industries(1974년 설립, 타이즈). 산업·농수산물용 골판지 상자.', 'National Carton Industries Company (HSA Group, founded 1974), Taiz - corrugated boxes for industry, produce and fish.', null)
) as v(name_like, alt_like, party_name, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'YE'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
);

-- existing mill rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
    notes = case when m.notes is null or coalesce(p.notes, '') ilike '%YE check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
    updated_at = now()
from (
  select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'YE'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Sponge%Plastic%', '%NCSPI%', '%Sponge%', 'HSA Group 계열 National Company for Sponge & Plastic Industry(1974년 설립, 타이즈 Al-Hawban). 스펀지·플라스틱·티슈 제품, 1994년 자료상 티슈 가공.', 'National Company for Sponge and Plastic Industry (HSA Group, founded 1974), Al-Hawban Airport Street, Taiz - sponge, plastics and tissue products, tissue converting per 1994 profile.', 'YE check 2026-10-14: own tissue machine and capacity not confirmed. Contact per HSA directory +967 4 218999, ncspi@hsa.com.ye.'),
  ('%Ganad%', '%Al-Ganad%', '%Ganad%', '1990년 설립 Al-Ganad Light Industries(타이즈 Al-Janad). 학교 노트·인쇄물로 시작, 2006-07 티슈 공장 가동(Style·Yasmin·Royal Golden).', 'Al-Ganad Light Industries (founded 1990, producing since 1993), Al-Janad, Taiz - school notebooks and printing, tissue plant since 2006-07 (Style, Yasmin, Royal Golden brands).', 'YE check 2026-10-14: notebooks use bought paper rolls - no own printing-paper machine. Tissue base-paper making not confirmed.'),
  ('%National Company for Paper Products%', '%Yemen Paper%', '%Paper Products%', '사나의 National Company for Paper Products. Fel 브랜드 위생용 종이제품.', 'National Company for Paper Products Ltd., Sana''a - Fel-brand hygiene paper products.', 'YE check 2026-10-14: base-paper making not confirmed - ask jumbo-roll origin. Tel +967 1 526954, yemenpaper@gmail.com.'),
  ('%National Carton Industries%', '%NCIC%Yemen%', '%National Carton%', 'HSA Group 계열 National Carton Industries(1974년 설립, 타이즈). 산업·농수산물용 골판지 상자.', 'National Carton Industries Company (HSA Group, founded 1974), Taiz - corrugated boxes for industry, produce and fish.', null)
  ) as v(name_like, alt_like, owner_like, intro_ko, intro_en, notes)
) m
where p.id = m.id and coalesce(p.source, '') <> 'yemen_update_20261014';

-- ---------- 4) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (
  select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'YE'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Sponge%Plastic%', '%NCSPI%', '%Sponge%'),
  ('%Ganad%', '%Al-Ganad%', '%Ganad%'),
  ('%National Company for Paper Products%', '%Yemen Paper%', '%Paper Products%'),
  ('%National Carton Industries%', '%NCIC%Yemen%', '%National Carton%')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'YE'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Sponge%Plastic%', '%NCSPI%', '%Sponge%',
   $pj${"owner": "HSA Group", "priority": 1, "products": "Tissue products (converting, base-paper making to confirm)", "grades": ["Tissue"], "approach": "Screen every party against the OFAC SDN list first - Ansar Allah (Houthis), who control Sana'a and parts of Taiz, are US-designated. Then confirm whether it makes tissue base paper or converts imported jumbo rolls.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Ganad%', '%Al-Ganad%', '%Ganad%',
   $pj${"owner": "Al-Ganad Light Industries", "priority": 2, "products": "Tissue, school notebooks, printed products", "grades": ["Tissue"], "approach": "Screen every party against the OFAC SDN list first - Ansar Allah (Houthis), who control Sana'a and parts of Taiz, are US-designated. Then ask who makes its tissue base paper.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%National Company for Paper Products%', '%Yemen Paper%', '%Paper Products%',
   $pj${"owner": "National Company for Paper Products", "products": "Hygiene tissue products", "approach": "Screen every party against the OFAC SDN list first - Ansar Allah (Houthis), who control Sana'a and parts of Taiz, are US-designated. Use only to trace base-paper suppliers.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%National Carton Industries%', '%NCIC%Yemen%', '%National Carton%',
   $pj${"owner": "HSA Group", "products": "Corrugated boxes", "approach": "Converter unless own base-paper machine found - not an FCC user.", "checked_at": "2026-10-14"}$pj$::jsonb)
  ) as v(name_like, alt_like, owner_like, plant)
) m
where mp.party_id = m.id;

-- ---------- 5) VERIFY ----------
with v(name_like, alt_like, owner_like) as (values
  ('%Sponge%Plastic%', '%NCSPI%', '%Sponge%'),
  ('%Ganad%', '%Al-Ganad%', '%Ganad%'),
  ('%National Company for Paper Products%', '%Yemen Paper%', '%Paper Products%'),
  ('%National Carton Industries%', '%NCIC%Yemen%', '%National Carton%')
)
select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_like) as name,
       case when p.source = 'yemen_update_20261014' then 'added now' when p.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from v
left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'YE'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1)
left join app.paper_mill_profile mp on mp.party_id = p.id
union all
select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', '-'
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and l.extra_data ->> 'batch' = 'yemen_update_20261014'
order by 1, 4, 2;
