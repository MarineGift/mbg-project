-- ============================================================
-- seed_20261014u_pakistan_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Pakistan update (reports "Pakistan PCC/GCC producers" + "Pakistan paper
-- companies", 2026-10). Introduction -> intro_ko / intro_en (only when
-- empty), extra detail -> notes once with 'PK check 2026-10-14', plant data
-- -> Mill profile card. Already in URM: Packages Limited, Bulleh Shah.
--
-- 1) Fillers if missing: OmyaPack (Omya 50 / Packages 50, Kasur 2018),
--    Asian Chemicals (PCC), Shaheen Grinding Mills (170 kt), Shaheen
--    Carbonates, Asian Polymer, Omar Group, Salamat. Crown Mining, Prime
--    Carbonate, Tycoon skipped (no paper link).
-- 2) Mills if missing: Premier, Flying Board, Packages Rose Petal tissue,
--    Fazal, Empire.
-- 3) Links: Shaheen Carbonates -> Empire and Fazal (active / medium -
--    customers named by Shaheen, grade not stated). OmyaPack -> Bulleh Shah
--    (POTENTIAL / medium - same group, supply not public).
-- 4) Plant blocks, priority 1-5: Bulleh Shah (360 kt installed, 266 kt
--    2025), Premier (25 kt), Century (280 kt board), Flying Board (18 kt),
--    Rose Petal tissue. context: Fazal, Empire.
--    FCC scenarios: Premier, Flying Board.
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
       v.party_name, 'PK', v.region, v.city, v.website, 'active', 'pakistan_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('OmyaPack', '%OmyaPack%', 'Punjab', 'Kasur', 'https://www.omya.com', 'Omya 와 Packages Limited 의 50:50 합작 OmyaPack. Kasur 에서 2018-06 상업생산, 제지·판지용 건식·습식 탄산칼슘.', 'OmyaPack - 50:50 joint venture of Omya and Packages Limited, commercial production at Kasur since 2018-06, dry and wet calcium carbonate for paper and board.', 'PK check 2026-10-14: 2025 revenue about PKR 2.6bn (+21 pct), pre-tax profit about PKR 601m (+24 pct), Packages Group results. Supply volume to Bulleh Shah not public. Royalty licensee is Omya at HQ level.'),
  ('Asian Chemicals', '%Asian Chemicals%', 'Punjab', 'Muridke', 'https://www.asianchemicals.com.pk', '1981년 설립, 파키스탄 최초 PCC 제조사라 밝히는 Asian Chemicals(Star Brand). Kala Shah Kaku, 제지용 충전·코팅 PCC, 생석회·소석회.', 'Asian Chemicals (founded 1981, says first PCC maker in Pakistan, Star Brand), 22 km G.T. Road, Kala Shah Kaku, Muridke - PCC for paper filling and coating, quick and hydrated lime.', 'PK check 2026-10-14: 2005 survey listed 90 t/day (about 32,400 t/yr) - historical. Dry powder versus slurry to confirm. Contact info@asianchemicals.com.pk, +92-42-37980003.'),
  ('Shaheen Grinding Mills', '%Shaheen Grinding%', 'Punjab', 'Lahore', 'https://www.shaheengrinding.com', '1966년 출발한 Shaheen Grinding Mills(라호르). GCC·코팅 GCC·액상 분산 GCC·활석·카올린, 연 17만 t, 제지·포장재·티슈용 제품.', 'Shaheen Grinding Mills (since 1966), Lahore - GCC, coated GCC, liquid dispersed GCC, talc, kaolin, 170,000 t/yr stated, products for paper, board and tissue.', 'PK check 2026-10-14: 9 km Bhoptian Chowk, off Raiwind Road, Lahore, sales@shaheengrinding.com, +92-328-9040494. Particle range about 1-100 um. Group plants also at Faisalabad, Mardan, Swabi.'),
  ('Shaheen Carbonates', '%Shaheen Carbonates%', 'Punjab', 'Faisalabad', 'https://www.shaheencarbonates.com', 'Shaheen 계열 Faisalabad 의 Shaheen Carbonates. 제지·포장재용 GCC, Empire Paper Mills·Fazal Paper Mills 를 주요 고객으로 공개.', 'Shaheen Carbonates (Shaheen group), Faisalabad - GCC for paper and packaging, names Empire Paper Mills and Fazal Paper Mills as main customers.', 'PK check 2026-10-14: grades supplied to Empire and Fazal not stated on the site.'),
  ('Asian Polymer Industries', '%Asian Polymer%', 'Punjab', 'Muridke', 'https://www.asianpolymer.com', 'Muridke 의 Asian Polymer Industries. 탄산칼슘 분말·액상·과립, 제지 적용, 수출.', 'Asian Polymer Industries, 34 km Khori Stop, G.T. Road, Muridke - calcium carbonate powder, liquid and granules, paper among uses, exporter.', 'PK check 2026-10-14: 100,000-120,000 t/yr in an outside company register - unverified. Check whether the liquid grade is paper slurry or plastics dispersion. info@asianpolymer.com.'),
  ('Omar Group (Omar Minerals)', '%Omar Group%', 'Sindh', 'Karachi', 'https://www.omargroup.com', '카라치 본사 Omar Group 의 GCC 사업. 원석부터 수직계열화, 볼밀·분급·코팅, 최대 20 t/h.', 'Omar Group (Omar Minerals), Karachi - vertically integrated GCC, ball mills, classifiers, coating, up to 20 t/h.', 'PK check 2026-10-14: CaCO3 up to 99.5 pct, brightness 93-95, D98 under 20 to under 3.5 um. 20 t/h x 24 h x 330 d = 158,400 t/yr theoretical. No paper customers or slurry found. info@omargroup.com.'),
  ('Salamat Enterprises', '%Salamat%', 'Punjab', 'Haji Kot', 'https://www.salamatenterprises.com', '1989년부터 산업광물 분쇄 Salamat Enterprises(Haji Kot). 제지 코팅·충전용 GCC, 연 10만 t 분쇄능력.', 'Salamat Enterprises (since 1989), Kala Khatie Narang Mandi Road, Haji Kot, Punjab - GCC for paper coating and filler, 100,000 t/yr grinding.', 'PK check 2026-10-14: CaCO3 98.5 pct+, whiteness 94+, moisture 0.3 pct, 5-44 um. Wet slurry process not confirmed.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
);

-- existing filler rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
    notes = case when coalesce(p.notes, '') ilike '%PK check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
    updated_at = now()
from (values
  ('OmyaPack', '%OmyaPack%', 'Punjab', 'Kasur', 'https://www.omya.com', 'Omya 와 Packages Limited 의 50:50 합작 OmyaPack. Kasur 에서 2018-06 상업생산, 제지·판지용 건식·습식 탄산칼슘.', 'OmyaPack - 50:50 joint venture of Omya and Packages Limited, commercial production at Kasur since 2018-06, dry and wet calcium carbonate for paper and board.', 'PK check 2026-10-14: 2025 revenue about PKR 2.6bn (+21 pct), pre-tax profit about PKR 601m (+24 pct), Packages Group results. Supply volume to Bulleh Shah not public. Royalty licensee is Omya at HQ level.'),
  ('Asian Chemicals', '%Asian Chemicals%', 'Punjab', 'Muridke', 'https://www.asianchemicals.com.pk', '1981년 설립, 파키스탄 최초 PCC 제조사라 밝히는 Asian Chemicals(Star Brand). Kala Shah Kaku, 제지용 충전·코팅 PCC, 생석회·소석회.', 'Asian Chemicals (founded 1981, says first PCC maker in Pakistan, Star Brand), 22 km G.T. Road, Kala Shah Kaku, Muridke - PCC for paper filling and coating, quick and hydrated lime.', 'PK check 2026-10-14: 2005 survey listed 90 t/day (about 32,400 t/yr) - historical. Dry powder versus slurry to confirm. Contact info@asianchemicals.com.pk, +92-42-37980003.'),
  ('Shaheen Grinding Mills', '%Shaheen Grinding%', 'Punjab', 'Lahore', 'https://www.shaheengrinding.com', '1966년 출발한 Shaheen Grinding Mills(라호르). GCC·코팅 GCC·액상 분산 GCC·활석·카올린, 연 17만 t, 제지·포장재·티슈용 제품.', 'Shaheen Grinding Mills (since 1966), Lahore - GCC, coated GCC, liquid dispersed GCC, talc, kaolin, 170,000 t/yr stated, products for paper, board and tissue.', 'PK check 2026-10-14: 9 km Bhoptian Chowk, off Raiwind Road, Lahore, sales@shaheengrinding.com, +92-328-9040494. Particle range about 1-100 um. Group plants also at Faisalabad, Mardan, Swabi.'),
  ('Shaheen Carbonates', '%Shaheen Carbonates%', 'Punjab', 'Faisalabad', 'https://www.shaheencarbonates.com', 'Shaheen 계열 Faisalabad 의 Shaheen Carbonates. 제지·포장재용 GCC, Empire Paper Mills·Fazal Paper Mills 를 주요 고객으로 공개.', 'Shaheen Carbonates (Shaheen group), Faisalabad - GCC for paper and packaging, names Empire Paper Mills and Fazal Paper Mills as main customers.', 'PK check 2026-10-14: grades supplied to Empire and Fazal not stated on the site.'),
  ('Asian Polymer Industries', '%Asian Polymer%', 'Punjab', 'Muridke', 'https://www.asianpolymer.com', 'Muridke 의 Asian Polymer Industries. 탄산칼슘 분말·액상·과립, 제지 적용, 수출.', 'Asian Polymer Industries, 34 km Khori Stop, G.T. Road, Muridke - calcium carbonate powder, liquid and granules, paper among uses, exporter.', 'PK check 2026-10-14: 100,000-120,000 t/yr in an outside company register - unverified. Check whether the liquid grade is paper slurry or plastics dispersion. info@asianpolymer.com.'),
  ('Omar Group (Omar Minerals)', '%Omar Group%', 'Sindh', 'Karachi', 'https://www.omargroup.com', '카라치 본사 Omar Group 의 GCC 사업. 원석부터 수직계열화, 볼밀·분급·코팅, 최대 20 t/h.', 'Omar Group (Omar Minerals), Karachi - vertically integrated GCC, ball mills, classifiers, coating, up to 20 t/h.', 'PK check 2026-10-14: CaCO3 up to 99.5 pct, brightness 93-95, D98 under 20 to under 3.5 um. 20 t/h x 24 h x 330 d = 158,400 t/yr theoretical. No paper customers or slurry found. info@omargroup.com.'),
  ('Salamat Enterprises', '%Salamat%', 'Punjab', 'Haji Kot', 'https://www.salamatenterprises.com', '1989년부터 산업광물 분쇄 Salamat Enterprises(Haji Kot). 제지 코팅·충전용 GCC, 연 10만 t 분쇄능력.', 'Salamat Enterprises (since 1989), Kala Khatie Narang Mandi Road, Haji Kot, Punjab - GCC for paper coating and filler, 100,000 t/yr grinding.', 'PK check 2026-10-14: CaCO3 98.5 pct+, whiteness 94+, moisture 0.3 pct, 5-44 um. Wet slurry process not confirmed.')
) as v(party_name, guard_like, region, city, website, intro_ko, intro_en, notes)
where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
  and coalesce(p.source, '') <> 'pakistan_update_20261014';

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
       d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
from app.parties p
join (values
  ('OmyaPack', 'GCC producer', 'Omya-Packages carbonate JV, Kasur', 'satellite (on-site) + merchant', 'B', 'gcc'),
  ('Asian Chemicals', 'PCC producer', 'Pakistan PCC - FCC co-production candidate 1', 'merchant', 'B', 'pcc'),
  ('Shaheen Grinding Mills', 'GCC producer', 'Pakistan paper GCC incl. liquid dispersed', 'merchant', 'B', 'gcc'),
  ('Shaheen Carbonates', 'GCC producer', 'Pakistan paper GCC with named mill customers', 'merchant', 'B', 'gcc'),
  ('Asian Polymer Industries', 'GCC producer', 'Pakistan GCC with liquid products', 'merchant', 'C', 'gcc'),
  ('Omar Group (Omar Minerals)', 'GCC producer', 'Fine GCC - raw material option', 'merchant', 'C', 'gcc'),
  ('Salamat Enterprises', 'GCC producer', 'Punjab GCC', 'merchant', 'C', 'gcc')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'pakistan_update_20261014'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 2) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, intro_ko, intro_en, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'PK', v.region, v.city, v.website, 'active', 'pakistan_update_20261014',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('%Premier Paper%', '%Premier Paper Mills%', 'Premier Paper Mills (Sheikhupura)', 'Punjab', 'Sheikhupura', 'https://www.premiergroup.pk', '1985년 설립 Premier Paper Mills. Sheikhupura-Lahore Road 9 km, 오프셋 인쇄용지·고급 필기용지·사무용지, 연 2.5만 t.', 'Premier Paper Mills (founded 1985), 9 km Sheikhupura-Lahore Road - offset, fine writing and office paper, 25,000 t/yr.', 'PK check 2026-10-14: contact admin@premiergroup.pk, +92-56-3543833 (company site).'),
  ('%Flying Board%', '%Flying Paper%', 'Flying Board & Paper Products (Punjab)', 'Punjab', null, 'https://www.flyinggroup.com.pk', 'Flying Group 계열 Flying Board & Paper Products(1989년 설립). 오프셋 인쇄용지 연 1.8만 t, 밀짚펄프 연 1.2만 t.', 'Flying Board and Paper Products (Flying Group, founded 1989) - offset printing paper about 18,000 t/yr and wheat-straw pulp about 12,000 t/yr.', null),
  ('%Packages%Tissue%', '%Rose Petal%', 'Packages - Rose Petal Tissue (Lahore)', 'Punjab', 'Lahore', 'https://www.rosepetal.com.pk', 'Packages Group 의 티슈 사업 Rose Petal(1980년대 초 출시). 2008년 연 3.3만 t 고속 티슈기 PM-9 도입, 화장지·미용티슈·타월·냅킨.', 'Packages Group tissue business, Rose Petal brand (early 1980s) - high-speed PM-9 tissue machine of 33,000 t/yr design installed 2008, toilet, facial, towel, napkin.', null),
  ('%Fazal Paper%', '%Fazal Paper Mills%', 'Fazal Paper Mills (Okara)', 'Punjab', 'Okara', null, '펀자브 Okara 의 제지사 Fazal Paper Mills. Shaheen Carbonates 의 주요 고객으로 공개.', 'Fazal Paper Mills, Okara, Punjab - named by Shaheen Carbonates as a main customer.', null),
  ('%Empire Paper%', '%Empire Paper Mills%', 'Empire Paper Mills (Pakistan)', null, null, null, 'Shaheen Carbonates 의 주요 고객으로 공개된 파키스탄 제지사 Empire Paper Mills. 공장 위치 확인 필요.', 'Empire Paper Mills, Pakistan - named by Shaheen Carbonates as a main customer, mill location to confirm.', null)
) as v(name_like, alt_like, party_name, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PK'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
);

-- existing mill rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
    notes = case when m.notes is null or coalesce(p.notes, '') ilike '%PK check 2026-10-14%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
    updated_at = now()
from (
  select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PK'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Bulleh Shah%', '%Bulleh Shah Packaging%', '%Bulleh Shah%', 'Packages Limited 완전자회사 Bulleh Shah Packaging(2005년 설립, Kasur). 복사용지(Copymate Plus)·인쇄용지·백판지·액체포장판지·골판지원지, 설치능력 연 36만 t.', 'Bulleh Shah Packaging (Packages Limited, 100 pct, founded 2005), Kasur - copy paper (Copymate Plus), printing and writing, folding box board, liquid packaging board, WLC and containerboard, 360,000 t/yr installed.', 'PK check 2026-10-14: PACRA rating 2026-09 - output 266,076 t in 2025 (237,870 t in 2024), utilization 73.9 pct. Copy and printing grades on 100 pct wood pulp. Stora Enso JV 2012-2017. Sister company OmyaPack (Omya 50 pct) makes calcium carbonate in Kasur.'),
  ('%Premier Paper%', '%Premier Paper Mills%', '%Premier%', '1985년 설립 Premier Paper Mills. Sheikhupura-Lahore Road 9 km, 오프셋 인쇄용지·고급 필기용지·사무용지, 연 2.5만 t.', 'Premier Paper Mills (founded 1985), 9 km Sheikhupura-Lahore Road - offset, fine writing and office paper, 25,000 t/yr.', 'PK check 2026-10-14: contact admin@premiergroup.pk, +92-56-3543833 (company site).'),
  ('%Century Paper%', '%Century Paper & Board%', '%Century%', 'Lakson Group 의 Century Paper & Board Mills(1984년 설립, Kasur). 162에이커 통합공장, 코팅 백판지·비도공 판지·MF/MG 지·골판지 포장, 연 28만 t(2025 증설).', 'Century Paper and Board Mills (Lakson Group, founded 1984), Kasur - 162-acre integrated mill, coated and uncoated board, MF and MG paper, corrugated packaging, 280,000 t/yr after 2025 expansion.', 'PK check 2026-10-14: FY2025 filing - 265,000 t capacity, 157,285 t produced. PM-7 coated duplex line since 2009. Capacity history 110 kt (2006), 240 kt (2009), 265 kt (2021), 280 kt (2025).'),
  ('%Flying Board%', '%Flying Paper%', '%Flying%', 'Flying Group 계열 Flying Board & Paper Products(1989년 설립). 오프셋 인쇄용지 연 1.8만 t, 밀짚펄프 연 1.2만 t.', 'Flying Board and Paper Products (Flying Group, founded 1989) - offset printing paper about 18,000 t/yr and wheat-straw pulp about 12,000 t/yr.', null),
  ('%Packages%Tissue%', '%Rose Petal%', '%Packages%', 'Packages Group 의 티슈 사업 Rose Petal(1980년대 초 출시). 2008년 연 3.3만 t 고속 티슈기 PM-9 도입, 화장지·미용티슈·타월·냅킨.', 'Packages Group tissue business, Rose Petal brand (early 1980s) - high-speed PM-9 tissue machine of 33,000 t/yr design installed 2008, toilet, facial, towel, napkin.', null),
  ('%Fazal Paper%', '%Fazal Paper Mills%', '%Fazal%', '펀자브 Okara 의 제지사 Fazal Paper Mills. Shaheen Carbonates 의 주요 고객으로 공개.', 'Fazal Paper Mills, Okara, Punjab - named by Shaheen Carbonates as a main customer.', null),
  ('%Empire Paper%', '%Empire Paper Mills%', '%Empire%', 'Shaheen Carbonates 의 주요 고객으로 공개된 파키스탄 제지사 Empire Paper Mills. 공장 위치 확인 필요.', 'Empire Paper Mills, Pakistan - named by Shaheen Carbonates as a main customer, mill location to confirm.', null)
  ) as v(name_like, alt_like, owner_like, intro_ko, intro_en, notes)
) m
where p.id = m.id and coalesce(p.source, '') <> 'pakistan_update_20261014';

-- ---------- 3) LINKS ----------
insert into app.party_supply_links
  (id, organization_id, mill_party_id, filler_party_id, link_type,
   product_grade, volume_estimate, confidence, active_since, active_until,
   notes, extra_data, created_at, updated_at)
select gen_random_uuid(), 'b25de8f2-1020-482f-9012-183f63883169'::uuid, m.id, f.id, r.link_type, r.grade, null, 'medium', null, null, r.label,
       jsonb_build_object('supply_structure', r.structure, 'source', r.src, 'batch', 'pakistan_update_20261014', 'researched_at', '2026-10-14'),
       now(), now()
from (values
  ('%Empire Paper%', '%Empire Paper Mills%', '%Empire%', 'Shaheen Carbonates%', 'active', 'GCC filler-grade', 'merchant GCC', 'shaheencarbonates.com customer list', 'Shaheen Carbonates names Empire Paper Mills as a main customer'),
  ('%Fazal Paper%', '%Fazal Paper Mills%', '%Fazal%', 'Shaheen Carbonates%', 'active', 'GCC filler-grade', 'merchant GCC', 'shaheencarbonates.com customer list', 'Shaheen Carbonates names Fazal Paper Mills as a main customer'),
  ('%Bulleh Shah%', '%Bulleh Shah Packaging%', '%Bulleh Shah%', 'OmyaPack%', 'potential', 'GCC filler-grade', 'same-group carbonate JV (Kasur)', 'Packages Group reports', 'OmyaPack (Omya 50 / Packages 50) and Bulleh Shah are in the same group - supply volume not public')
) as v(name_like, alt_like, owner_like, filler_like, link_type, grade, structure, src, label)
cross join lateral (select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PK'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id) m
cross join lateral (
  select x.id from app.parties x
  where x.party_type_id = 3 and x.deleted_at is null and x.party_name ilike v.filler_like
  order by x.created_at limit 1
) f
cross join lateral (select v.link_type, v.grade, v.structure, v.src, v.label) r
where m.id is not null
  and not exists (select 1 from app.party_supply_links l
                  where l.mill_party_id = m.id and l.filler_party_id = f.id and l.deleted_at is null);

-- ---------- 4) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (
  select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PK'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Bulleh Shah%', '%Bulleh Shah Packaging%', '%Bulleh Shah%'),
  ('%Premier Paper%', '%Premier Paper Mills%', '%Premier%'),
  ('%Century Paper%', '%Century Paper & Board%', '%Century%'),
  ('%Flying Board%', '%Flying Paper%', '%Flying%'),
  ('%Packages%Tissue%', '%Rose Petal%', '%Packages%'),
  ('%Fazal Paper%', '%Fazal Paper Mills%', '%Fazal%'),
  ('%Empire Paper%', '%Empire Paper Mills%', '%Empire%')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PK'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Bulleh Shah%', '%Bulleh Shah Packaging%', '%Bulleh Shah%',
   $pj${"owner": "Packages Limited", "priority": 1, "products": "Copy paper, printing and writing, folding box board, liquid packaging board, WLC, testliner and fluting", "grades": ["Copy paper", "Writing and printing", "Folding box board"], "capacity_split": [{"label": "Installed (PACRA 2026-09)", "value_t": 360000}, {"label": "2025 output", "value_t": 266076}], "filler": [{"supplier": "OmyaPack (Omya 50 / Packages 50)", "type": "Same-group carbonate supplier, Kasur", "status": "Supply volume and grades not public", "basis": "Packages Group reports"}], "pitch": "Wood-pulp copy and printing grades - pulp saving with opacity and strength held", "approach": "Top Pakistan account - mill and Omya JV in one group. Go through Packages Group technical and business development, aligned with Omya HQ (licensee). Set the FCC IP boundary clearly with Omya.", "to_collect": ["Current PCC / GCC supplier and grade, and loading per grade", "Imported pulp volume and landed cost", "Ash, opacity, tensile, retention baseline", "Who approves a machine trial"], "sources": [{"label": "PACRA 2026-09"}, {"label": "bullehshah.com.pk"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Premier Paper%', '%Premier Paper Mills%', '%Premier%',
   $pj${"owner": "Premier Group", "priority": 2, "products": "Offset printing, fine writing and office paper", "grades": ["Offset", "Writing", "Office paper"], "capacity": {"value": 25000, "unit": "metric_t", "year": "Company site", "source": "premiergroup.pk"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.75, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 0.85, "fcc_share": 0.25, "fcc_loading": 0.2}, {"label": "Expanded", "utilization": 0.9, "fcc_share": 0.5, "fcc_loading": 0.25}], "note": "Planning scenarios on nameplate paper capacity, not orders. FCC in sheet is not the same as pulp replaced."}, "pitch": "Small mill - pilot and cost-saving proof on copy and printing grades", "approach": "Compare FCC with the current PCC / GCC sheet on ash, brightness, opacity, tensile, basis weight, drainage and retention.", "to_collect": ["Current PCC / GCC supplier and grade, and loading per grade", "Imported pulp volume and landed cost", "Ash, opacity, tensile, retention baseline", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Century Paper%', '%Century Paper & Board%', '%Century%',
   $pj${"owner": "Lakson Group", "priority": 3, "products": "Coated board, uncoated board, MF and MG paper", "grades": ["Coated board", "Uncoated board"], "capacity_split": [{"label": "After 2025 expansion", "value_t": 280000}, {"label": "FY2025 output", "value_t": 157285}], "pitch": "Base-ply pulp saving in coated board", "approach": "Ply trials - bond, stiffness, Z-strength and surface. Board data needed first.", "to_collect": ["Current PCC / GCC supplier and grade, and loading per grade", "Imported pulp volume and landed cost", "Ash, opacity, tensile, retention baseline", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Flying Board%', '%Flying Paper%', '%Flying%',
   $pj${"owner": "Flying Group", "priority": 4, "products": "Offset printing paper, wheat-straw pulp", "grades": ["Offset"], "capacity": {"value": 18000, "unit": "metric_t", "year": "Group figure", "source": "flyinggroup.com.pk"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.75, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 0.85, "fcc_share": 0.25, "fcc_loading": 0.2}, {"label": "Expanded", "utilization": 0.9, "fcc_share": 0.5, "fcc_loading": 0.25}], "note": "Planning scenarios on nameplate paper capacity, not orders. FCC in sheet is not the same as pulp replaced."}, "pitch": "Compare FCC in straw-pulp versus wood-pulp sheets", "approach": "Group also has mineral and chemical units - check carbonate grades in-house.", "to_collect": ["Current PCC / GCC supplier and grade, and loading per grade", "Imported pulp volume and landed cost", "Ash, opacity, tensile, retention baseline", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Packages%Tissue%', '%Rose Petal%', '%Packages%',
   $pj${"owner": "Packages Group", "priority": 5, "products": "Facial and toilet tissue, kitchen towel, napkins", "grades": ["Tissue"], "capacity_split": [{"label": "PM-9 design (2008)", "value_t": 33000}], "approach": "Confirm PM-9 status and ownership first. Separate tissue trial.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Fazal Paper%', '%Fazal Paper Mills%', '%Fazal%',
   $pj${"owner": "Fazal Paper Mills", "products": "Paper and board", "filler": [{"supplier": "Shaheen Carbonates", "type": "GCC", "status": "Named customer", "basis": "shaheencarbonates.com - grade not stated"}], "approach": "Check grades and GCC use - route in via Shaheen.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Empire Paper%', '%Empire Paper Mills%', '%Empire%',
   $pj${"owner": "Empire Paper Mills", "products": "Paper products", "filler": [{"supplier": "Shaheen Carbonates", "type": "GCC", "status": "Named customer", "basis": "shaheencarbonates.com - grade not stated"}], "approach": "Verify location, grades and GCC supply.", "checked_at": "2026-10-14"}$pj$::jsonb)
  ) as v(name_like, alt_like, owner_like, plant)
) m
where mp.party_id = m.id;

-- ---------- 5) VERIFY ----------
with v(name_like, alt_like, owner_like) as (values
  ('%Bulleh Shah%', '%Bulleh Shah Packaging%', '%Bulleh Shah%'),
  ('%Premier Paper%', '%Premier Paper Mills%', '%Premier%'),
  ('%Century Paper%', '%Century Paper & Board%', '%Century%'),
  ('%Flying Board%', '%Flying Paper%', '%Flying%'),
  ('%Packages%Tissue%', '%Rose Petal%', '%Packages%'),
  ('%Fazal Paper%', '%Fazal Paper Mills%', '%Fazal%'),
  ('%Empire Paper%', '%Empire Paper Mills%', '%Empire%')
)
select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_like) as name,
       case when p.source = 'pakistan_update_20261014' then 'added now' when p.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from v
left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'PK'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1)
left join app.paper_mill_profile mp on mp.party_id = p.id
union all
select 'filler', p.party_name,
       case when p.source = 'pakistan_update_20261014' then 'added now' else 'already there' end, '-',
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ilike '%OmyaPack%' or p.party_name ilike '%Asian Chemicals%' or p.party_name ilike '%Shaheen Grinding%' or p.party_name ilike '%Shaheen Carbonates%' or p.party_name ilike '%Asian Polymer%' or p.party_name ilike '%Omar Group%' or p.party_name ilike '%Salamat%')
union all
select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', '-'
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and l.extra_data ->> 'batch' = 'pakistan_update_20261014'
order by 1, 4, 2;
