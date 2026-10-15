-- ============================================================
-- seed_20261014ab_kuwait_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Kuwait update (reports 2026-10). Introduction -> intro_ko / intro_en
-- (only when empty), detail -> notes once with 'KW check 2026-10-14',
-- plant data -> Mill profile card.
--
-- 1) Fillers if missing: KDF (drilling-grade GCC, 250 kt combined
--    minerals), NICBM lime (500 t/day). No PCC maker in Kuwait.
-- 2) Mills if missing + plant blocks, priority 1-2: Gulf Paper
--    Manufacturing (50 kt packaging + 15 kt tissue), United Paper
--    Industries (deinked pulp - machine to confirm). context, match only:
--    Al Wataniya, Al Jothoor (likely converters).
--    Packaging converters (Al Khat, Kuwait Box, Caesar Pack) not added.
--    No FCC scenarios, no supply links.
--
-- Idempotent. Last statement is a verification select.
-- ============================================================

-- ---------- 1) FILLER ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, intro_ko, intro_en, notes, organization_id)
select 3::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 3 and x.deleted_at is null
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'KW', v.region, v.city, v.website, 'active', 'kuwait_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('Kuwait Drilling Fluids & Oil Services (KDF)', '%Kuwait Drilling Fluids%', 'Ahmadi', 'Shuaiba', null, 'Shuaiba 항 보안구역의 KDF. 롤러밀 3기로 바라이트·벤토나이트·탄산칼슘·대리석 분쇄, 합산 연 최대 25만 t, 시추용 중심.', 'Kuwait Drilling Fluids and Oil Services (KDF), Shuaiba Port secure area (about 70,000 m2) - three roller mills grinding barite, bentonite, calcium carbonate and marble, up to 250,000 t/yr combined, mainly drilling fluids.', 'KW check 2026-10-14: calcium carbonate share, paper grade and wet milling not confirmed. No PCC maker found in Kuwait. Kuwait imported 23,645 t HS 283650 in 2024 (about 70 pct Saudi origin).'),
  ('National Industries Company for Building Materials (NICBM) - Lime', '%NICBM%', 'Ahmadi', null, 'https://www.nicbm.com', '쿠웨이트 NICBM 석회공장. 생석회·소석회 약 500 t/일, 건축자재(AAC·석회벽돌)용.', 'National Industries Company for Building Materials lime factory, Kuwait - quick and hydrated lime about 500 t/day, for AAC blocks and lime bricks.', 'KW check 2026-10-14: possible lime source for PCC-based FCC - no PCC production. Tel +965 24642000.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
);

-- existing filler rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
    notes = case when coalesce(p.notes, '') ilike '%KW check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
    updated_at = now()
from (values
  ('Kuwait Drilling Fluids & Oil Services (KDF)', '%Kuwait Drilling Fluids%', 'Ahmadi', 'Shuaiba', null, 'Shuaiba 항 보안구역의 KDF. 롤러밀 3기로 바라이트·벤토나이트·탄산칼슘·대리석 분쇄, 합산 연 최대 25만 t, 시추용 중심.', 'Kuwait Drilling Fluids and Oil Services (KDF), Shuaiba Port secure area (about 70,000 m2) - three roller mills grinding barite, bentonite, calcium carbonate and marble, up to 250,000 t/yr combined, mainly drilling fluids.', 'KW check 2026-10-14: calcium carbonate share, paper grade and wet milling not confirmed. No PCC maker found in Kuwait. Kuwait imported 23,645 t HS 283650 in 2024 (about 70 pct Saudi origin).'),
  ('National Industries Company for Building Materials (NICBM) - Lime', '%NICBM%', 'Ahmadi', null, 'https://www.nicbm.com', '쿠웨이트 NICBM 석회공장. 생석회·소석회 약 500 t/일, 건축자재(AAC·석회벽돌)용.', 'National Industries Company for Building Materials lime factory, Kuwait - quick and hydrated lime about 500 t/day, for AAC blocks and lime bricks.', 'KW check 2026-10-14: possible lime source for PCC-based FCC - no PCC production. Tel +965 24642000.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
  and coalesce(p.source, '') <> 'kuwait_update_20261014';

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
       d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
from app.parties p
join (values
  ('Kuwait Drilling Fluids & Oil Services (KDF)', 'GCC producer', 'Kuwait drilling-grade GCC - paper fit to confirm', 'merchant', 'C', 'gcc'),
  ('National Industries Company for Building Materials (NICBM) - Lime', 'Lime producer', 'Kuwait lime - PCC raw material option', 'merchant', 'C', 'pcc')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'kuwait_update_20261014'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 2) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, intro_ko, intro_en, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'KW', v.region, v.city, v.website, 'active', 'kuwait_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('%Gulf Paper%', '%GPMC%', 'Gulf Paper Manufacturing Company (Shuaiba)', 'Ahmadi', 'Shuaiba', 'https://www.gpmckw.com', '1979년 설립(1982년 생산) 쿠웨이트 Shuaiba 의 Gulf Paper Manufacturing. 플루팅·브라운/화이트탑 라이너·코어지·티슈 원지, 연 약 6.5만~7만 t.', 'Gulf Paper Manufacturing Company (founded 1979, producing since 1982), Shuaiba Industrial Area, Kuwait - fluting, brown and white top liner, core paper and tissue, about 65,000-70,000 t/yr.', 'KW check 2026-10-14: line 1 packaging 50,000 t, line 2 tissue 15,000 t (production page) versus 70,000 t total (about page). Tissue 16.5-38 gsm, jumbo rolls up to 220 cm. Chairman Khalid Mohammed Saqer Al Moasherji. Shuaiba West, Block 3, +965 22393550, management@gpmckw.com, purchase@gpmckw.com. Also runs a Dubai Jebel Ali mill.'),
  ('%United Paper Industries%', '%UPI%Kuwait%', 'United Paper Industries (Shuaiba)', 'Ahmadi', 'Shuaiba', 'https://www.upi.com.kw', '1998년 설립 Shuaiba 의 United Paper Industries. 쿠웨이트 산업연합 등록 사업은 폐지 탈묵 제지용 펄프 제조.', 'United Paper Industries (founded 1998), Western Industrial Shuaiba, Block 2, Plot 75 - registered with the Kuwait Industries Union for deinked recycled pulp for papermaking.', 'KW check 2026-10-14: own paper machine and output not confirmed (some directories say recycled kraft and packaging). Chairman and CEO Abdulrahman Abdullah Dakhil Al Dakhi, GM Ali Abdulrahman Ahmed Al-Hajri, +965 23260501, legaladmin@upi.com.kw.')
) as v(name_like, alt_like, party_name, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'KW'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
);

-- existing mill rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
    notes = case when m.notes is null or coalesce(p.notes, '') ilike '%KW check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
    updated_at = now()
from (
  select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'KW'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Gulf Paper%', '%GPMC%', '%Gulf Paper%', '1979년 설립(1982년 생산) 쿠웨이트 Shuaiba 의 Gulf Paper Manufacturing. 플루팅·브라운/화이트탑 라이너·코어지·티슈 원지, 연 약 6.5만~7만 t.', 'Gulf Paper Manufacturing Company (founded 1979, producing since 1982), Shuaiba Industrial Area, Kuwait - fluting, brown and white top liner, core paper and tissue, about 65,000-70,000 t/yr.', 'KW check 2026-10-14: line 1 packaging 50,000 t, line 2 tissue 15,000 t (production page) versus 70,000 t total (about page). Tissue 16.5-38 gsm, jumbo rolls up to 220 cm. Chairman Khalid Mohammed Saqer Al Moasherji. Shuaiba West, Block 3, +965 22393550, management@gpmckw.com, purchase@gpmckw.com. Also runs a Dubai Jebel Ali mill.'),
  ('%United Paper Industries%', '%UPI%Kuwait%', '%United Paper%', '1998년 설립 Shuaiba 의 United Paper Industries. 쿠웨이트 산업연합 등록 사업은 폐지 탈묵 제지용 펄프 제조.', 'United Paper Industries (founded 1998), Western Industrial Shuaiba, Block 2, Plot 75 - registered with the Kuwait Industries Union for deinked recycled pulp for papermaking.', 'KW check 2026-10-14: own paper machine and output not confirmed (some directories say recycled kraft and packaging). Chairman and CEO Abdulrahman Abdullah Dakhil Al Dakhi, GM Ali Abdulrahman Ahmed Al-Hajri, +965 23260501, legaladmin@upi.com.kw.'),
  ('%Wataniya Paper%', '%Al Wataniya%Paper%', '%Wataniya%', 'National Consumer Holding 의 Al Wataniya Paper Products(Subhan). 화장지·미용티슈·키친타월·냅킨(Watani Classic 등).', 'Al Wataniya Paper Products (National Consumer Holding since 2008), Subhan Industrial Area - toilet, facial, kitchen towel and napkins (Watani Classic, Breeze, Lamar).', 'KW check 2026-10-14: own tissue machine not confirmed - may convert bought jumbo rolls. Chairman Abdulwahab Asaad Al-Sanad, CEO Hazem Al-Bakri.'),
  ('%Jothoor%', '%Jothor%', '%Jothoor%', '1986년 설립 Subhan 의 Al Jothoor 티슈 공장. 화장지·미용티슈·핸드타월.', 'Al Jothoor Factory for Manufacturing Tissue Papers (founded 1986), Subhan - consumer tissue.', null)
  ) as v(name_like, alt_like, owner_like, intro_ko, intro_en, notes)
) m
where p.id = m.id and coalesce(p.source, '') <> 'kuwait_update_20261014';

-- ---------- 4) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (
  select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'KW'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Gulf Paper%', '%GPMC%', '%Gulf Paper%'),
  ('%United Paper Industries%', '%UPI%Kuwait%', '%United Paper%'),
  ('%Wataniya Paper%', '%Al Wataniya%Paper%', '%Wataniya%'),
  ('%Jothoor%', '%Jothor%', '%Jothoor%')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'KW'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Gulf Paper%', '%GPMC%', '%Gulf Paper%',
   $pj${"owner": "Gulf Paper Manufacturing Company", "priority": 1, "products": "Fluting, brown top and white top liner, core paper, tissue jumbo rolls", "grades": ["Tissue", "White top liner", "Fluting"], "capacity_split": [{"label": "Line 1 packaging", "value_t": 50000}, {"label": "Line 2 tissue", "value_t": 15000}], "pitch": "Low-grammage tissue (16.5-20 gsm) close to the MBG 15 gsm trial, then white top liner", "approach": "Lead Kuwait account - reach management and production, not only purchasing. Supply could come via Saudi or UAE filler bases. Group link to the Dubai Jebel Ali mill.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "sources": [{"label": "gpmckw.com"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%United Paper Industries%', '%UPI%Kuwait%', '%United Paper%',
   $pj${"owner": "United Paper Industries", "priority": 2, "products": "Deinked recycled pulp (paper machine to confirm)", "approach": "Confirm a paper machine first - pulp only makes it a raw-material partner, not an FCC user.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Wataniya Paper%', '%Al Wataniya%Paper%', '%Wataniya%',
   $pj${"owner": "National Consumer Holding", "products": "Converted tissue", "approach": "Ask who supplies its base paper.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Jothoor%', '%Jothor%', '%Jothoor%',
   $pj${"owner": "Al Jothoor", "products": "Consumer tissue", "approach": "Confirm own paper machine.", "checked_at": "2026-10-14"}$pj$::jsonb)
  ) as v(name_like, alt_like, owner_like, plant)
) m
where mp.party_id = m.id;

-- ---------- 5) VERIFY ----------
with v(name_like, alt_like, owner_like) as (values
  ('%Gulf Paper%', '%GPMC%', '%Gulf Paper%'),
  ('%United Paper Industries%', '%UPI%Kuwait%', '%United Paper%'),
  ('%Wataniya Paper%', '%Al Wataniya%Paper%', '%Wataniya%'),
  ('%Jothoor%', '%Jothor%', '%Jothoor%')
)
select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_like) as name,
       case when p.source = 'kuwait_update_20261014' then 'added now' when p.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from v
left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'KW'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1)
left join app.paper_mill_profile mp on mp.party_id = p.id
union all
select 'filler', p.party_name,
       case when p.source = 'kuwait_update_20261014' then 'added now' else 'already there' end, '-',
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ilike '%Kuwait Drilling Fluids%' or p.party_name ilike '%NICBM%')
union all
select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', '-'
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and l.extra_data ->> 'batch' = 'kuwait_update_20261014'
order by 1, 4, 2;
