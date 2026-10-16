-- ============================================================
-- seed_20261015m_mexico_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Mexico update (reports 2026-10-15). Introduction -> intro_ko / intro_en
-- (only when empty), detail -> notes once with 'MX check 2026-10-15',
-- plant data -> Mill profile card. Many MX rows may exist already, so each
-- mill is matched by name regex OR (city + owner regex) before any insert.
--
-- 1) Fillers if missing (8): Omya México, SMI Anáhuac (status to confirm),
--    Terrazo, Reverté Durango, ICC, ATSA, ONIC, LEDSA.
-- 2) Mills if missing (20): Pondercel, Scribe, Cartones Ponderosa,
--    Papel San Francisco, KCM x6, Essity x3, Convertipap, Smurfit Westrock x6.
--    Context rows, match only: Greenpaper, Grupak, Softys, Corporativo
--    Papelera, Papeles Ultra, Papelera San Luis, Copamex Industrias,
--    Papelera Chihuahua.
-- 3) Supply link: SMI Anáhuac -> Pondercel (historical, medium).
-- 4) app.country_markets MX row (priority high).
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
       v.party_name, 'MX', v.region, v.city, v.website, 'active', 'mexico_update_20261015',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('omya.*m[eé]x', 'Omya México', 'Estado de México', 'Cuautitlán Izcalli', null, 'Omya(스위스)의 멕시코 법인. 멕시코 내 제조시설 4곳, Cuautitlán Izcalli 연구·응용 실험실. 제지·판지용 충전제·코팅 탄산칼슘 공급.', 'Omya México - four manufacturing sites in Mexico and an application lab at Cuautitlán Izcalli, filler and coating calcium carbonate for paper and board.', 'MX check 2026-10-15: which of the four sites make paper-grade GCC or PCC, capacities and paper customers not public. Royalty licensee at Omya HQ level - Omya Multifill (high filler with biopolymer, PCC flocculation, MFC) is the comparable in-house technology.'),
  ('(specialty minerals|minerals technologies).*(m[eé]x|an[aá]huac|chihuahua)', 'Specialty Minerals S.A. de C.V. - Anáhuac', 'Chihuahua', 'Anáhuac', null, 'Minerals Technologies(SMI)의 멕시코 법인. Chihuahua 주 Colonia Anáhuac(Cuauhtémoc 인근) 에 Pondercel 연계 제지용 PCC 위성공장 기록.', 'Specialty Minerals S.A. de C.V. (Minerals Technologies) - satellite PCC plant recorded at Colonia Anáhuac near Cuauhtémoc, Chihuahua, tied to the Copamex Pondercel mill.', 'MX check 2026-10-15: current operation, capacity and operator not confirmed - records are older industry reports and a directory listing (phone +52 625 585 0423). Royalty licensee at MTI HQ level.'),
  ('terrazo', 'Terrazo de México', 'Coahuila', 'Torreón', null, 'Torreón(Coahuila) 의 GCC 제조사. 석회석·백색 대리석 미분쇄, MICROFILLER 3·10·40·200·BLEND, 제지 산업 공급 명시.', 'Terrazo de México, Circuito Enrique de Lara 301, Ciudad Industrial, Torreón, Coahuila - ground limestone and white marble, MICROFILLER 3, 10, 40, 200 and BLEND, paper industry named as a market.', 'MX check 2026-10-15: ventas@terrazomexico.com, +52 871 750 6378. Wet grinding or slurry capacity not confirmed. Product numbers are not confirmed as D50.'),
  ('revert[eé].*(am[eé]rica|durango|m[eé]x)', 'Reverté Minerals América - Durango', 'Durango', 'Dinamita', null, '스페인 Reverté 그룹의 Durango(Dinamita) 미세·초미세 GCC 공장(2015년 가동, 2008년 백색 대리석 광상 확보). 2026년 공장 지분 과반 매각.', 'Reverté Minerals América - fine and ultrafine GCC plant at Dinamita, Durango (white marble deposit secured 2008, plant started 2015), part of Spain-based Reverté. Majority stake in the plant sold in 2026.', 'MX check 2026-10-15: new controlling owner to identify. sales@reverte-na.com, +52 871 751 6020 (2026 directory). Capacity not public.'),
  ('industria de carbonato', 'Industria de Carbonato de Calcio (ICC)', 'Querétaro', 'Ezequiel Montes', null, 'Querétaro Ezequiel Montes 의 40년 업력 탄산칼슘 채굴·분쇄 업체. A-200~A-1000 (평균 입경 약 6~14 μm), 제지·판지 공급 명시.', 'Industria de Carbonato de Calcio (ICC), San Juan del Río - Xilitla road km 45, Ezequiel Montes, Querétaro - over 40 years, quarry to grinding, A-200 to A-1000 (about 6-14 micron mean size), paper and board named.', 'MX check 2026-10-15: ventas@industriadecarbonato.com, +52 441 103 6895. Grades are coarse for printing paper - confirm the grade sold to mills.'),
  ('\matsa\M', 'ATSA Minerales', 'Estado de México', 'Tlalnepantla', null, 'ATSA Minerales(Corporación ATSA) — 탄산칼슘·카올린·돌로마이트·복합안료, 전 광물 합산 연 85만 t 이상. 제지용 초미세 카올린 슬러리 보유.', 'ATSA Minerales (Corporación ATSA), base Tlalnepantla - calcium carbonate, kaolin, dolomite and blended pigments, over 850,000 t/yr across all minerals, ultrafine kaolin slurry for paper.', 'MX check 2026-10-15: processing sites per mining directory - San Juan del Río and Ezequiel Montes (Querétaro), Huayacocotla (Veracruz), Mixquiahuala (Hidalgo). Paper-grade GCC share of the 850 kt not public. +52 55 9454 0100.'),
  ('^onic\M', 'ONIC', null, null, null, '제지용 탄산칼슘 슬러리와 AKD 사이즈제·PAM·지력증강제·스티키 제어제 공급사. 슬러리 자체 제조 여부 미확인.', 'ONIC - calcium carbonate slurry and paper chemicals (AKD sizing, PAM, wet and dry strength, stickies control, cationic agents) for paper and board mills.', 'MX check 2026-10-15: own slurry production, GCC or PCC base and mill customers not confirmed. info@onic.mx, +52 811 125 2626. Customer trial channel, not a producer yet.'),
  ('ledsa', 'LEDSA Industrial', 'Querétaro', 'Cadereyta de Montes', null, 'Querétaro Cadereyta de Montes 의 석회석 분쇄업체(100~325 mesh), 제지 용도 명시.', 'LEDSA Industrial, Cadereyta de Montes, Querétaro - ground limestone 100-325 mesh, paper named as a use.', 'MX check 2026-10-15: small grinder - raw-material source only. Not added: Carbonato de Calcio Sol, QR Minerales, HSL México (production unconfirmed), Grupo Calidra (lime, 16 plants), Infra Derivados Químicos (Cuautitlán PCC, 2005 data only).')
) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
);

-- existing filler rows: fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
    notes = case when coalesce(p.notes, '') ilike '%MX check 2026-10-15%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
    updated_at = now()
from (values
  ('omya.*m[eé]x', 'Omya México', 'Estado de México', 'Cuautitlán Izcalli', null, 'Omya(스위스)의 멕시코 법인. 멕시코 내 제조시설 4곳, Cuautitlán Izcalli 연구·응용 실험실. 제지·판지용 충전제·코팅 탄산칼슘 공급.', 'Omya México - four manufacturing sites in Mexico and an application lab at Cuautitlán Izcalli, filler and coating calcium carbonate for paper and board.', 'MX check 2026-10-15: which of the four sites make paper-grade GCC or PCC, capacities and paper customers not public. Royalty licensee at Omya HQ level - Omya Multifill (high filler with biopolymer, PCC flocculation, MFC) is the comparable in-house technology.'),
  ('(specialty minerals|minerals technologies).*(m[eé]x|an[aá]huac|chihuahua)', 'Specialty Minerals S.A. de C.V. - Anáhuac', 'Chihuahua', 'Anáhuac', null, 'Minerals Technologies(SMI)의 멕시코 법인. Chihuahua 주 Colonia Anáhuac(Cuauhtémoc 인근) 에 Pondercel 연계 제지용 PCC 위성공장 기록.', 'Specialty Minerals S.A. de C.V. (Minerals Technologies) - satellite PCC plant recorded at Colonia Anáhuac near Cuauhtémoc, Chihuahua, tied to the Copamex Pondercel mill.', 'MX check 2026-10-15: current operation, capacity and operator not confirmed - records are older industry reports and a directory listing (phone +52 625 585 0423). Royalty licensee at MTI HQ level.'),
  ('terrazo', 'Terrazo de México', 'Coahuila', 'Torreón', null, 'Torreón(Coahuila) 의 GCC 제조사. 석회석·백색 대리석 미분쇄, MICROFILLER 3·10·40·200·BLEND, 제지 산업 공급 명시.', 'Terrazo de México, Circuito Enrique de Lara 301, Ciudad Industrial, Torreón, Coahuila - ground limestone and white marble, MICROFILLER 3, 10, 40, 200 and BLEND, paper industry named as a market.', 'MX check 2026-10-15: ventas@terrazomexico.com, +52 871 750 6378. Wet grinding or slurry capacity not confirmed. Product numbers are not confirmed as D50.'),
  ('revert[eé].*(am[eé]rica|durango|m[eé]x)', 'Reverté Minerals América - Durango', 'Durango', 'Dinamita', null, '스페인 Reverté 그룹의 Durango(Dinamita) 미세·초미세 GCC 공장(2015년 가동, 2008년 백색 대리석 광상 확보). 2026년 공장 지분 과반 매각.', 'Reverté Minerals América - fine and ultrafine GCC plant at Dinamita, Durango (white marble deposit secured 2008, plant started 2015), part of Spain-based Reverté. Majority stake in the plant sold in 2026.', 'MX check 2026-10-15: new controlling owner to identify. sales@reverte-na.com, +52 871 751 6020 (2026 directory). Capacity not public.'),
  ('industria de carbonato', 'Industria de Carbonato de Calcio (ICC)', 'Querétaro', 'Ezequiel Montes', null, 'Querétaro Ezequiel Montes 의 40년 업력 탄산칼슘 채굴·분쇄 업체. A-200~A-1000 (평균 입경 약 6~14 μm), 제지·판지 공급 명시.', 'Industria de Carbonato de Calcio (ICC), San Juan del Río - Xilitla road km 45, Ezequiel Montes, Querétaro - over 40 years, quarry to grinding, A-200 to A-1000 (about 6-14 micron mean size), paper and board named.', 'MX check 2026-10-15: ventas@industriadecarbonato.com, +52 441 103 6895. Grades are coarse for printing paper - confirm the grade sold to mills.'),
  ('\matsa\M', 'ATSA Minerales', 'Estado de México', 'Tlalnepantla', null, 'ATSA Minerales(Corporación ATSA) — 탄산칼슘·카올린·돌로마이트·복합안료, 전 광물 합산 연 85만 t 이상. 제지용 초미세 카올린 슬러리 보유.', 'ATSA Minerales (Corporación ATSA), base Tlalnepantla - calcium carbonate, kaolin, dolomite and blended pigments, over 850,000 t/yr across all minerals, ultrafine kaolin slurry for paper.', 'MX check 2026-10-15: processing sites per mining directory - San Juan del Río and Ezequiel Montes (Querétaro), Huayacocotla (Veracruz), Mixquiahuala (Hidalgo). Paper-grade GCC share of the 850 kt not public. +52 55 9454 0100.'),
  ('^onic\M', 'ONIC', null, null, null, '제지용 탄산칼슘 슬러리와 AKD 사이즈제·PAM·지력증강제·스티키 제어제 공급사. 슬러리 자체 제조 여부 미확인.', 'ONIC - calcium carbonate slurry and paper chemicals (AKD sizing, PAM, wet and dry strength, stickies control, cationic agents) for paper and board mills.', 'MX check 2026-10-15: own slurry production, GCC or PCC base and mill customers not confirmed. info@onic.mx, +52 811 125 2626. Customer trial channel, not a producer yet.'),
  ('ledsa', 'LEDSA Industrial', 'Querétaro', 'Cadereyta de Montes', null, 'Querétaro Cadereyta de Montes 의 석회석 분쇄업체(100~325 mesh), 제지 용도 명시.', 'LEDSA Industrial, Cadereyta de Montes, Querétaro - ground limestone 100-325 mesh, paper named as a use.', 'MX check 2026-10-15: small grinder - raw-material source only. Not added: Carbonato de Calcio Sol, QR Minerales, HSL México (production unconfirmed), Grupo Calidra (lime, 16 plants), Infra Derivados Químicos (Cuautitlán PCC, 2005 data only).')
) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
  and coalesce(p.source, '') <> 'mexico_update_20261015';

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
       d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
from app.parties p
join (values
  ('Omya México', 'GCC and PCC producer', 'Omya México - royalty licensee (Omya HQ)', 'merchant', 'B', 'gcc'),
  ('Specialty Minerals S.A. de C.V. - Anáhuac', 'PCC producer', 'Satellite PCC at Pondercel - status to confirm', 'satellite (on-site)', 'C', 'pcc'),
  ('Terrazo de México', 'GCC producer', 'Local GCC - FCC producer candidate', 'merchant', 'B', 'gcc'),
  ('Reverté Minerals América - Durango', 'GCC producer', 'Fine GCC - co-production candidate', 'merchant', 'B', 'gcc'),
  ('Industria de Carbonato de Calcio (ICC)', 'GCC producer', 'Local GCC near Cartones Ponderosa', 'merchant', 'C', 'gcc'),
  ('ATSA Minerales', 'GCC and kaolin producer', 'Mineral processor with paper slurry experience', 'merchant', 'C', 'gcc'),
  ('ONIC', 'Slurry and chemicals supplier', 'CaCO3 slurry and paper chemicals - mill trial channel', 'merchant', 'C', 'gcc'),
  ('LEDSA Industrial', 'GCC producer', 'Small grinder - raw material', 'merchant', 'C', 'gcc')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'mexico_update_20261015'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 2) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, intro_ko, intro_en, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'MX', v.region, v.city, v.website, 'active', 'mexico_update_20261015',
       v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('pondercel', 'cuauht[eé]moc', 'copamex|pondercel', 'Copamex - Pondercel (Cuauhtémoc)', 'Chihuahua', 'Cuauhtémoc', null, 'Copamex(1928년 창업, Nuevo León)가 1995년 인수한 Pondercel 공장. 필기·인쇄용 Bond paper 주요 생산공장.', 'Copamex (founded 1928, Nuevo León) - Pondercel mill at Cuauhtémoc, Chihuahua, acquired 1995, one of the main Mexican bond (writing and printing) paper mills.', 'MX check 2026-10-15: older industry reports place a Specialty Minerals satellite PCC plant at Colonia Anáhuac next to this mill - current operation and supplier not confirmed. Mill phone +52 625 581 9700. Capacity not public.'),
  ('scribe|bio ?pappel.*orizaba', 'orizaba', 'pappel|scribe', 'Bio Pappel - Scribe (Orizaba)', 'Veracruz', 'Orizaba', null, 'Bio Pappel 그룹(Scribe·Titán·McKinley)의 백색 인쇄·필기용지 사업부 Scribe. 제지산업협회 명부상 Orizaba 공장이 Scribe 관련 시설.', 'Bio Pappel group (Scribe, Titán, McKinley) - Scribe is the white printing, writing paper and notebook division. The chamber directory links the Orizaba, Veracruz site to Scribe.', 'MX check 2026-10-15: which Bio Pappel site runs the white-paper machines (Orizaba, Tizayuca, Durango, Nuevo León, Oaxaca, Mexicali, Apaxco) is not confirmed. Capacity not public.'),
  ('cartones ponderosa', 'san juan del r', 'ponderosa', 'Cartones Ponderosa (San Juan del Río)', 'Querétaro', 'San Juan del Río', null, '1979년 가동한 San Juan del Río 의 코팅·비코팅 재생 백판지 제조사. 3층 섬유 + 4회 코팅, 평량 235~490 g/m².', 'Cartones Ponderosa, San Juan del Río, Querétaro (since 1979) - coated and uncoated recycled folding boxboard, three fibre plies plus four coating passes, 235-490 g/m2, food, pharma and consumer packaging.', 'MX check 2026-10-15: capacity 240,000 t/yr per company history (2012 upgrade), Valmet case cites about 270,000 t - current figure to confirm.'),
  ('papel san francisco', 'mexicali', 'san francisco', 'Papel San Francisco (Mexicali)', 'Baja California', 'Mexicali', null, '1980년 설립 Mexicali 의 독립 티슈 제조사. TM9(2024) 가동, TM10 2026년 1분기 목표, 목표 생산능력 연 27만 t.', 'Papel San Francisco, Mexicali, Baja California (founded 1980) - independent tissue maker serving Mexico and the US West, TM9 started 2024, TM10 targeted 2026 Q1, target capacity 270,000 t/yr.', 'MX check 2026-10-15: TM10 start-up and the 270 kt total not confirmed as of 2026-10.'),
  ('kimberly.*orizaba|orizaba.*kimberly', 'orizaba', 'kimberly', 'Kimberly-Clark de México - Orizaba', 'Veracruz', 'Orizaba', null, 'Kimberly-Clark de México(KCM, Pétalo·Kleenex·Suavel·Sanitas, 연 매출 약 540억 페소, 약 9천 명)의 위생용지 생산시설. Orizaba 공장.', 'Kimberly-Clark de México (Pétalo, Kleenex, Suavel, Sanitas - about MXN 54 bn sales, about 9,000 staff) - Orizaba site, household and institutional tissue.', 'MX check 2026-10-15: machine-level capacity not public. KCM is a separate listed company, not part of Arbex.'),
  ('kimberly.*san juan del r|san juan del r.*kimberly', 'san juan del r', 'kimberly', 'Kimberly-Clark de México - San Juan del Río', 'Querétaro', 'San Juan del Río', null, 'Kimberly-Clark de México(KCM, Pétalo·Kleenex·Suavel·Sanitas, 연 매출 약 540억 페소, 약 9천 명)의 위생용지 생산시설. San Juan del Río 공장.', 'Kimberly-Clark de México (Pétalo, Kleenex, Suavel, Sanitas - about MXN 54 bn sales, about 9,000 staff) - San Juan del Río site, household and institutional tissue.', 'MX check 2026-10-15: machine-level capacity not public. KCM is a separate listed company, not part of Arbex.'),
  ('kimberly.*morelia|morelia.*kimberly', 'morelia', 'kimberly', 'Kimberly-Clark de México - Morelia', 'Michoacán', 'Morelia', null, 'Kimberly-Clark de México(KCM, Pétalo·Kleenex·Suavel·Sanitas, 연 매출 약 540억 페소, 약 9천 명)의 위생용지 생산시설. Morelia 공장.', 'Kimberly-Clark de México (Pétalo, Kleenex, Suavel, Sanitas - about MXN 54 bn sales, about 9,000 staff) - Morelia site, household tissue.', 'MX check 2026-10-15: machine-level capacity not public. KCM is a separate listed company, not part of Arbex.'),
  ('kimberly.*ramos arizpe|ramos arizpe.*kimberly', 'ramos arizpe', 'kimberly', 'Kimberly-Clark de México - Ramos Arizpe', 'Coahuila', 'Ramos Arizpe', null, 'Kimberly-Clark de México(KCM, Pétalo·Kleenex·Suavel·Sanitas, 연 매출 약 540억 페소, 약 9천 명)의 위생용지 생산시설. Ramos Arizpe 공장.', 'Kimberly-Clark de México (Pétalo, Kleenex, Suavel, Sanitas - about MXN 54 bn sales, about 9,000 staff) - Ramos Arizpe site, household tissue.', 'MX check 2026-10-15: machine-level capacity not public. KCM is a separate listed company, not part of Arbex.'),
  ('kimberly.*ecatepec|ecatepec.*kimberly', 'ecatepec', 'kimberly', 'Kimberly-Clark de México - Ecatepec', 'Estado de México', 'Ecatepec', null, 'Kimberly-Clark de México(KCM, Pétalo·Kleenex·Suavel·Sanitas, 연 매출 약 540억 페소, 약 9천 명)의 위생용지 생산시설. Ecatepec 공장.', 'Kimberly-Clark de México (Pétalo, Kleenex, Suavel, Sanitas - about MXN 54 bn sales, about 9,000 staff) - Ecatepec site, household and institutional tissue.', 'MX check 2026-10-15: machine-level capacity not public. KCM is a separate listed company, not part of Arbex.'),
  ('kimberly.*texmelucan|texmelucan.*kimberly', 'texmelucan', 'kimberly', 'Kimberly-Clark de México - Texmelucan', 'Puebla', 'Texmelucan', null, 'Kimberly-Clark de México(KCM, Pétalo·Kleenex·Suavel·Sanitas, 연 매출 약 540억 페소, 약 9천 명)의 위생용지 생산시설. Texmelucan 공장.', 'Kimberly-Clark de México (Pétalo, Kleenex, Suavel, Sanitas - about MXN 54 bn sales, about 9,000 staff) - Texmelucan site, institutional tissue.', 'MX check 2026-10-15: machine-level capacity not public. KCM is a separate listed company, not part of Arbex.'),
  ('essity.*monterrey|monterrey.*essity', 'monterrey', 'essity|\msca\M', 'Essity - Monterrey', 'Nuevo León', 'Monterrey', 'https://www.essity.com', 'Essity(스웨덴) 멕시코 티슈 공장 Monterrey. 연 80천 t (2024 연차보고서).', 'Essity Mexico tissue mill at Monterrey, Nuevo León - 80,000 t/yr tissue (Essity Annual Report 2024).', null),
  ('essity.*sahag|sahag.*essity', 'sahag', 'essity|\msca\M', 'Essity - Sahagún', 'Hidalgo', 'Sahagún', 'https://www.essity.com', 'Essity(스웨덴) 멕시코 티슈 공장 Sahagún. 연 95천 t (2024 연차보고서).', 'Essity Mexico tissue mill at Sahagún, Hidalgo - 95,000 t/yr tissue (Essity Annual Report 2024). TAD tissue experience.', null),
  ('essity.*uruapan|uruapan.*essity', 'uruapan', 'essity|\msca\M', 'Essity - Uruapan', 'Michoacán', 'Uruapan', 'https://www.essity.com', 'Essity(스웨덴) 멕시코 티슈 공장 Uruapan. 연 40천 t (2024 연차보고서).', 'Essity Mexico tissue mill at Uruapan, Michoacán - 40,000 t/yr tissue (Essity Annual Report 2024).', null),
  ('convertipap', 'tlaxcala', 'convertipap', 'Convertipap (Tlaxcala)', 'Tlaxcala', 'Tlaxcala', null, '중부 멕시코(Tlaxcala·Ixtapaluca) 독립 티슈 제조사. 연 12.5만 t 목표, 2027년경 TM8 로 15만 t 계획.', 'Convertipap - independent tissue maker in central Mexico (Tlaxcala, Ixtapaluca), toilet, towel, napkin and jumbo rolls - 125,000 t/yr target, TM8 around 2027 for 150,000 t (plan).', 'MX check 2026-10-15: 125 kt is a stated target, not confirmed running capacity.'),
  ('(smurfit|westrock|gondi).*monterrey|monterrey.*(smurfit|westrock|gondi)', 'monterrey', '(smurfit|westrock|gondi)', 'Smurfit Westrock - Monterrey', 'Nuevo León', 'Monterrey', 'https://www.smurfitwestrock.com', 'Smurfit Westrock(구 Smurfit Kappa·WestRock·Grupo Gondi) 멕시코 Monterrey 제지공장. 연 402,000 t (Smurfit Westrock 2025 Annual Report).', 'Smurfit Westrock (ex Smurfit Kappa, WestRock and Grupo Gondi) - Monterrey mill, Mexico: 402,000 t containerboard per year (Smurfit Westrock 2025 Annual Report, end 2025).', 'MX check 2026-10-15: Mexico total 1.49 Mt/yr across six mills (1,293 kt containerboard, 198 kt boxboard). Ex-Gondi sites are the same group - do not count twice.'),
  ('(smurfit|westrock|gondi).*cerro gordo|cerro gordo.*(smurfit|westrock|gondi)', null, '(smurfit|westrock|gondi)', 'Smurfit Westrock - Cerro Gordo', 'Estado de México', null, 'https://www.smurfitwestrock.com', 'Smurfit Westrock(구 Smurfit Kappa·WestRock·Grupo Gondi) 멕시코 Cerro Gordo 제지공장. 연 347,000 t (Smurfit Westrock 2025 Annual Report).', 'Smurfit Westrock (ex Smurfit Kappa, WestRock and Grupo Gondi) - Cerro Gordo mill, Mexico: 259,000 t containerboard + 88,000 t boxboard per year (Smurfit Westrock 2025 Annual Report, end 2025).', 'MX check 2026-10-15: Mexico total 1.49 Mt/yr across six mills (1,293 kt containerboard, 198 kt boxboard). Ex-Gondi sites are the same group - do not count twice.'),
  ('(smurfit|westrock|gondi).*guadalajara|guadalajara.*(smurfit|westrock|gondi)', 'guadalajara', '(smurfit|westrock|gondi)', 'Smurfit Westrock - Guadalajara', 'Jalisco', 'Guadalajara', 'https://www.smurfitwestrock.com', 'Smurfit Westrock(구 Smurfit Kappa·WestRock·Grupo Gondi) 멕시코 Guadalajara 제지공장. 연 270,000 t (Smurfit Westrock 2025 Annual Report).', 'Smurfit Westrock (ex Smurfit Kappa, WestRock and Grupo Gondi) - Guadalajara mill, Mexico: 160,000 t containerboard + 110,000 t boxboard per year (Smurfit Westrock 2025 Annual Report, end 2025).', 'MX check 2026-10-15: Mexico total 1.49 Mt/yr across six mills (1,293 kt containerboard, 198 kt boxboard). Ex-Gondi sites are the same group - do not count twice.'),
  ('(smurfit|westrock|gondi).*san pablo|san pablo.*(smurfit|westrock|gondi)', null, '(smurfit|westrock|gondi)', 'Smurfit Westrock - San Pablo', null, null, 'https://www.smurfitwestrock.com', 'Smurfit Westrock(구 Smurfit Kappa·WestRock·Grupo Gondi) 멕시코 San Pablo 제지공장. 연 243,000 t (Smurfit Westrock 2025 Annual Report).', 'Smurfit Westrock (ex Smurfit Kappa, WestRock and Grupo Gondi) - San Pablo mill, Mexico: 243,000 t containerboard per year (Smurfit Westrock 2025 Annual Report, end 2025).', 'MX check 2026-10-15: Mexico total 1.49 Mt/yr across six mills (1,293 kt containerboard, 198 kt boxboard). Ex-Gondi sites are the same group - do not count twice.'),
  ('(smurfit|westrock|gondi).*los reyes|los reyes.*(smurfit|westrock|gondi)', null, '(smurfit|westrock|gondi)', 'Smurfit Westrock - Los Reyes', 'Estado de México', null, 'https://www.smurfitwestrock.com', 'Smurfit Westrock(구 Smurfit Kappa·WestRock·Grupo Gondi) 멕시코 Los Reyes 제지공장. 연 158,000 t (Smurfit Westrock 2025 Annual Report).', 'Smurfit Westrock (ex Smurfit Kappa, WestRock and Grupo Gondi) - Los Reyes mill, Mexico: 158,000 t containerboard per year (Smurfit Westrock 2025 Annual Report, end 2025).', 'MX check 2026-10-15: Mexico total 1.49 Mt/yr across six mills (1,293 kt containerboard, 198 kt boxboard). Ex-Gondi sites are the same group - do not count twice.'),
  ('(smurfit|westrock|gondi).*san luis potos|san luis potos.*(smurfit|westrock|gondi)', 'san luis potos', '(smurfit|westrock|gondi)', 'Smurfit Westrock - San Luis Potosí', 'San Luis Potosí', 'San Luis Potosí', 'https://www.smurfitwestrock.com', 'Smurfit Westrock(구 Smurfit Kappa·WestRock·Grupo Gondi) 멕시코 San Luis Potosí 제지공장. 연 71,000 t (Smurfit Westrock 2025 Annual Report).', 'Smurfit Westrock (ex Smurfit Kappa, WestRock and Grupo Gondi) - San Luis Potosí mill, Mexico: 71,000 t containerboard per year (Smurfit Westrock 2025 Annual Report, end 2025).', 'MX check 2026-10-15: Mexico total 1.49 Mt/yr across six mills (1,293 kt containerboard, 198 kt boxboard). Ex-Gondi sites are the same group - do not count twice.')
) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MX'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;

-- existing mill rows (incl. context rows): fill empty introduction, append memo once
update app.parties p
set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
    intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
    notes = case when m.notes is null or coalesce(p.notes, '') ilike '%MX check 2026-10-15%' then p.notes
                 else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
    updated_at = now()
from (
  select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MX'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
  from (values
  ('pondercel', 'cuauht[eé]moc', 'copamex|pondercel', 'Copamex(1928년 창업, Nuevo León)가 1995년 인수한 Pondercel 공장. 필기·인쇄용 Bond paper 주요 생산공장.', 'Copamex (founded 1928, Nuevo León) - Pondercel mill at Cuauhtémoc, Chihuahua, acquired 1995, one of the main Mexican bond (writing and printing) paper mills.', 'MX check 2026-10-15: older industry reports place a Specialty Minerals satellite PCC plant at Colonia Anáhuac next to this mill - current operation and supplier not confirmed. Mill phone +52 625 581 9700. Capacity not public.'),
  ('scribe|bio ?pappel.*orizaba', 'orizaba', 'pappel|scribe', 'Bio Pappel 그룹(Scribe·Titán·McKinley)의 백색 인쇄·필기용지 사업부 Scribe. 제지산업협회 명부상 Orizaba 공장이 Scribe 관련 시설.', 'Bio Pappel group (Scribe, Titán, McKinley) - Scribe is the white printing, writing paper and notebook division. The chamber directory links the Orizaba, Veracruz site to Scribe.', 'MX check 2026-10-15: which Bio Pappel site runs the white-paper machines (Orizaba, Tizayuca, Durango, Nuevo León, Oaxaca, Mexicali, Apaxco) is not confirmed. Capacity not public.'),
  ('cartones ponderosa', 'san juan del r', 'ponderosa', '1979년 가동한 San Juan del Río 의 코팅·비코팅 재생 백판지 제조사. 3층 섬유 + 4회 코팅, 평량 235~490 g/m².', 'Cartones Ponderosa, San Juan del Río, Querétaro (since 1979) - coated and uncoated recycled folding boxboard, three fibre plies plus four coating passes, 235-490 g/m2, food, pharma and consumer packaging.', 'MX check 2026-10-15: capacity 240,000 t/yr per company history (2012 upgrade), Valmet case cites about 270,000 t - current figure to confirm.'),
  ('papel san francisco', 'mexicali', 'san francisco', '1980년 설립 Mexicali 의 독립 티슈 제조사. TM9(2024) 가동, TM10 2026년 1분기 목표, 목표 생산능력 연 27만 t.', 'Papel San Francisco, Mexicali, Baja California (founded 1980) - independent tissue maker serving Mexico and the US West, TM9 started 2024, TM10 targeted 2026 Q1, target capacity 270,000 t/yr.', 'MX check 2026-10-15: TM10 start-up and the 270 kt total not confirmed as of 2026-10.'),
  ('kimberly.*orizaba|orizaba.*kimberly', 'orizaba', 'kimberly', 'Kimberly-Clark de México(KCM, Pétalo·Kleenex·Suavel·Sanitas, 연 매출 약 540억 페소, 약 9천 명)의 위생용지 생산시설. Orizaba 공장.', 'Kimberly-Clark de México (Pétalo, Kleenex, Suavel, Sanitas - about MXN 54 bn sales, about 9,000 staff) - Orizaba site, household and institutional tissue.', 'MX check 2026-10-15: machine-level capacity not public. KCM is a separate listed company, not part of Arbex.'),
  ('kimberly.*san juan del r|san juan del r.*kimberly', 'san juan del r', 'kimberly', 'Kimberly-Clark de México(KCM, Pétalo·Kleenex·Suavel·Sanitas, 연 매출 약 540억 페소, 약 9천 명)의 위생용지 생산시설. San Juan del Río 공장.', 'Kimberly-Clark de México (Pétalo, Kleenex, Suavel, Sanitas - about MXN 54 bn sales, about 9,000 staff) - San Juan del Río site, household and institutional tissue.', 'MX check 2026-10-15: machine-level capacity not public. KCM is a separate listed company, not part of Arbex.'),
  ('kimberly.*morelia|morelia.*kimberly', 'morelia', 'kimberly', 'Kimberly-Clark de México(KCM, Pétalo·Kleenex·Suavel·Sanitas, 연 매출 약 540억 페소, 약 9천 명)의 위생용지 생산시설. Morelia 공장.', 'Kimberly-Clark de México (Pétalo, Kleenex, Suavel, Sanitas - about MXN 54 bn sales, about 9,000 staff) - Morelia site, household tissue.', 'MX check 2026-10-15: machine-level capacity not public. KCM is a separate listed company, not part of Arbex.'),
  ('kimberly.*ramos arizpe|ramos arizpe.*kimberly', 'ramos arizpe', 'kimberly', 'Kimberly-Clark de México(KCM, Pétalo·Kleenex·Suavel·Sanitas, 연 매출 약 540억 페소, 약 9천 명)의 위생용지 생산시설. Ramos Arizpe 공장.', 'Kimberly-Clark de México (Pétalo, Kleenex, Suavel, Sanitas - about MXN 54 bn sales, about 9,000 staff) - Ramos Arizpe site, household tissue.', 'MX check 2026-10-15: machine-level capacity not public. KCM is a separate listed company, not part of Arbex.'),
  ('kimberly.*ecatepec|ecatepec.*kimberly', 'ecatepec', 'kimberly', 'Kimberly-Clark de México(KCM, Pétalo·Kleenex·Suavel·Sanitas, 연 매출 약 540억 페소, 약 9천 명)의 위생용지 생산시설. Ecatepec 공장.', 'Kimberly-Clark de México (Pétalo, Kleenex, Suavel, Sanitas - about MXN 54 bn sales, about 9,000 staff) - Ecatepec site, household and institutional tissue.', 'MX check 2026-10-15: machine-level capacity not public. KCM is a separate listed company, not part of Arbex.'),
  ('kimberly.*texmelucan|texmelucan.*kimberly', 'texmelucan', 'kimberly', 'Kimberly-Clark de México(KCM, Pétalo·Kleenex·Suavel·Sanitas, 연 매출 약 540억 페소, 약 9천 명)의 위생용지 생산시설. Texmelucan 공장.', 'Kimberly-Clark de México (Pétalo, Kleenex, Suavel, Sanitas - about MXN 54 bn sales, about 9,000 staff) - Texmelucan site, institutional tissue.', 'MX check 2026-10-15: machine-level capacity not public. KCM is a separate listed company, not part of Arbex.'),
  ('essity.*monterrey|monterrey.*essity', 'monterrey', 'essity|\msca\M', 'Essity(스웨덴) 멕시코 티슈 공장 Monterrey. 연 80천 t (2024 연차보고서).', 'Essity Mexico tissue mill at Monterrey, Nuevo León - 80,000 t/yr tissue (Essity Annual Report 2024).', null),
  ('essity.*sahag|sahag.*essity', 'sahag', 'essity|\msca\M', 'Essity(스웨덴) 멕시코 티슈 공장 Sahagún. 연 95천 t (2024 연차보고서).', 'Essity Mexico tissue mill at Sahagún, Hidalgo - 95,000 t/yr tissue (Essity Annual Report 2024). TAD tissue experience.', null),
  ('essity.*uruapan|uruapan.*essity', 'uruapan', 'essity|\msca\M', 'Essity(스웨덴) 멕시코 티슈 공장 Uruapan. 연 40천 t (2024 연차보고서).', 'Essity Mexico tissue mill at Uruapan, Michoacán - 40,000 t/yr tissue (Essity Annual Report 2024).', null),
  ('convertipap', 'tlaxcala', 'convertipap', '중부 멕시코(Tlaxcala·Ixtapaluca) 독립 티슈 제조사. 연 12.5만 t 목표, 2027년경 TM8 로 15만 t 계획.', 'Convertipap - independent tissue maker in central Mexico (Tlaxcala, Ixtapaluca), toilet, towel, napkin and jumbo rolls - 125,000 t/yr target, TM8 around 2027 for 150,000 t (plan).', 'MX check 2026-10-15: 125 kt is a stated target, not confirmed running capacity.'),
  ('(smurfit|westrock|gondi).*monterrey|monterrey.*(smurfit|westrock|gondi)', 'monterrey', '(smurfit|westrock|gondi)', 'Smurfit Westrock(구 Smurfit Kappa·WestRock·Grupo Gondi) 멕시코 Monterrey 제지공장. 연 402,000 t (Smurfit Westrock 2025 Annual Report).', 'Smurfit Westrock (ex Smurfit Kappa, WestRock and Grupo Gondi) - Monterrey mill, Mexico: 402,000 t containerboard per year (Smurfit Westrock 2025 Annual Report, end 2025).', 'MX check 2026-10-15: Mexico total 1.49 Mt/yr across six mills (1,293 kt containerboard, 198 kt boxboard). Ex-Gondi sites are the same group - do not count twice.'),
  ('(smurfit|westrock|gondi).*cerro gordo|cerro gordo.*(smurfit|westrock|gondi)', null, '(smurfit|westrock|gondi)', 'Smurfit Westrock(구 Smurfit Kappa·WestRock·Grupo Gondi) 멕시코 Cerro Gordo 제지공장. 연 347,000 t (Smurfit Westrock 2025 Annual Report).', 'Smurfit Westrock (ex Smurfit Kappa, WestRock and Grupo Gondi) - Cerro Gordo mill, Mexico: 259,000 t containerboard + 88,000 t boxboard per year (Smurfit Westrock 2025 Annual Report, end 2025).', 'MX check 2026-10-15: Mexico total 1.49 Mt/yr across six mills (1,293 kt containerboard, 198 kt boxboard). Ex-Gondi sites are the same group - do not count twice.'),
  ('(smurfit|westrock|gondi).*guadalajara|guadalajara.*(smurfit|westrock|gondi)', 'guadalajara', '(smurfit|westrock|gondi)', 'Smurfit Westrock(구 Smurfit Kappa·WestRock·Grupo Gondi) 멕시코 Guadalajara 제지공장. 연 270,000 t (Smurfit Westrock 2025 Annual Report).', 'Smurfit Westrock (ex Smurfit Kappa, WestRock and Grupo Gondi) - Guadalajara mill, Mexico: 160,000 t containerboard + 110,000 t boxboard per year (Smurfit Westrock 2025 Annual Report, end 2025).', 'MX check 2026-10-15: Mexico total 1.49 Mt/yr across six mills (1,293 kt containerboard, 198 kt boxboard). Ex-Gondi sites are the same group - do not count twice.'),
  ('(smurfit|westrock|gondi).*san pablo|san pablo.*(smurfit|westrock|gondi)', null, '(smurfit|westrock|gondi)', 'Smurfit Westrock(구 Smurfit Kappa·WestRock·Grupo Gondi) 멕시코 San Pablo 제지공장. 연 243,000 t (Smurfit Westrock 2025 Annual Report).', 'Smurfit Westrock (ex Smurfit Kappa, WestRock and Grupo Gondi) - San Pablo mill, Mexico: 243,000 t containerboard per year (Smurfit Westrock 2025 Annual Report, end 2025).', 'MX check 2026-10-15: Mexico total 1.49 Mt/yr across six mills (1,293 kt containerboard, 198 kt boxboard). Ex-Gondi sites are the same group - do not count twice.'),
  ('(smurfit|westrock|gondi).*los reyes|los reyes.*(smurfit|westrock|gondi)', null, '(smurfit|westrock|gondi)', 'Smurfit Westrock(구 Smurfit Kappa·WestRock·Grupo Gondi) 멕시코 Los Reyes 제지공장. 연 158,000 t (Smurfit Westrock 2025 Annual Report).', 'Smurfit Westrock (ex Smurfit Kappa, WestRock and Grupo Gondi) - Los Reyes mill, Mexico: 158,000 t containerboard per year (Smurfit Westrock 2025 Annual Report, end 2025).', 'MX check 2026-10-15: Mexico total 1.49 Mt/yr across six mills (1,293 kt containerboard, 198 kt boxboard). Ex-Gondi sites are the same group - do not count twice.'),
  ('(smurfit|westrock|gondi).*san luis potos|san luis potos.*(smurfit|westrock|gondi)', 'san luis potos', '(smurfit|westrock|gondi)', 'Smurfit Westrock(구 Smurfit Kappa·WestRock·Grupo Gondi) 멕시코 San Luis Potosí 제지공장. 연 71,000 t (Smurfit Westrock 2025 Annual Report).', 'Smurfit Westrock (ex Smurfit Kappa, WestRock and Grupo Gondi) - San Luis Potosí mill, Mexico: 71,000 t containerboard per year (Smurfit Westrock 2025 Annual Report, end 2025).', 'MX check 2026-10-15: Mexico total 1.49 Mt/yr across six mills (1,293 kt containerboard, 198 kt boxboard). Ex-Gondi sites are the same group - do not count twice.'),
  ('green ?paper', null, 'green ?paper', null, null, 'MX check 2026-10-15: Industrial packaging and containerboard (Nuevo León) - no capacity data, context only.'),
  ('grupak', null, 'grupak', null, null, 'MX check 2026-10-15: Containerboard and packaging (Morelos, Hidalgo) - no capacity data, context only.'),
  ('softys', null, 'softys', null, null, 'MX check 2026-10-15: Tissue - Altamira tissue machine project announced - no capacity data, context only.'),
  ('corporativo papelera', null, 'corporativo papelera', null, null, 'MX check 2026-10-15: Tissue - machine upgrade and expansion reported - no capacity data, context only.'),
  ('papeles ultra', null, 'papeles ultra', null, null, 'MX check 2026-10-15: Paper and board - products to confirm - no capacity data, context only.'),
  ('industrial papelera san luis', null, 'industrial papelera san luis', null, null, 'MX check 2026-10-15: Industrial papers (San Luis Potosí) - no capacity data, context only.'),
  ('copamex.*(industrias|san nicol)', null, 'copamex.*(industrias|san nicol)', null, null, 'MX check 2026-10-15: Kraft and specialty papers - no capacity data, context only.'),
  ('papelera chihuahua', null, 'papelera chihuahua', null, null, 'MX check 2026-10-15: Kraft and specialty papers - no capacity data, context only.')
  ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
) m
where p.id = m.id and coalesce(p.source, '') <> 'mexico_update_20261015';

-- ---------- 3) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (
  select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MX'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
  from (values
  ('pondercel', 'cuauht[eé]moc', 'copamex|pondercel'),
  ('scribe|bio ?pappel.*orizaba', 'orizaba', 'pappel|scribe'),
  ('cartones ponderosa', 'san juan del r', 'ponderosa'),
  ('papel san francisco', 'mexicali', 'san francisco'),
  ('kimberly.*orizaba|orizaba.*kimberly', 'orizaba', 'kimberly'),
  ('kimberly.*san juan del r|san juan del r.*kimberly', 'san juan del r', 'kimberly'),
  ('kimberly.*morelia|morelia.*kimberly', 'morelia', 'kimberly'),
  ('kimberly.*ramos arizpe|ramos arizpe.*kimberly', 'ramos arizpe', 'kimberly'),
  ('kimberly.*ecatepec|ecatepec.*kimberly', 'ecatepec', 'kimberly'),
  ('kimberly.*texmelucan|texmelucan.*kimberly', 'texmelucan', 'kimberly'),
  ('essity.*monterrey|monterrey.*essity', 'monterrey', 'essity|\msca\M'),
  ('essity.*sahag|sahag.*essity', 'sahag', 'essity|\msca\M'),
  ('essity.*uruapan|uruapan.*essity', 'uruapan', 'essity|\msca\M'),
  ('convertipap', 'tlaxcala', 'convertipap'),
  ('(smurfit|westrock|gondi).*monterrey|monterrey.*(smurfit|westrock|gondi)', 'monterrey', '(smurfit|westrock|gondi)'),
  ('(smurfit|westrock|gondi).*cerro gordo|cerro gordo.*(smurfit|westrock|gondi)', null, '(smurfit|westrock|gondi)'),
  ('(smurfit|westrock|gondi).*guadalajara|guadalajara.*(smurfit|westrock|gondi)', 'guadalajara', '(smurfit|westrock|gondi)'),
  ('(smurfit|westrock|gondi).*san pablo|san pablo.*(smurfit|westrock|gondi)', null, '(smurfit|westrock|gondi)'),
  ('(smurfit|westrock|gondi).*los reyes|los reyes.*(smurfit|westrock|gondi)', null, '(smurfit|westrock|gondi)'),
  ('(smurfit|westrock|gondi).*san luis potos|san luis potos.*(smurfit|westrock|gondi)', 'san luis potos', '(smurfit|westrock|gondi)'),
  ('green ?paper', null, 'green ?paper'),
  ('grupak', null, 'grupak'),
  ('softys', null, 'softys'),
  ('corporativo papelera', null, 'corporativo papelera'),
  ('papeles ultra', null, 'papeles ultra'),
  ('industrial papelera san luis', null, 'industrial papelera san luis'),
  ('copamex.*(industrias|san nicol)', null, 'copamex.*(industrias|san nicol)'),
  ('papelera chihuahua', null, 'papelera chihuahua')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MX'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
  from (values
  ('pondercel', 'cuauht[eé]moc', 'copamex|pondercel',
   $pj${"owner": "Copamex", "priority": 1, "products": "Bond writing and printing paper", "grades": ["Bond paper", "Printing and writing"], "pitch": "Clear PCC baseline - FCC partial PCC replacement and fibre saving on bond paper", "approach": "Lead Mexican account. Confirm whether the Anáhuac satellite PCC (SMI) still supplies - SMI is an MBG licensee, so a trial can run through SMI.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "recent": "SMI satellite PCC history at Anáhuac (status to confirm)", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('scribe|bio ?pappel.*orizaba', 'orizaba', 'pappel|scribe',
   $pj${"owner": "Bio Pappel", "priority": 2, "products": "Copy, printing and writing paper, notebooks", "grades": ["Copy paper", "Printing and writing"], "pitch": "High-ash trial - keep tensile, opacity and drainage while cutting pulp", "approach": "Find the machine and its filler supplier first, then a scale-up account after Pondercel.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('cartones ponderosa', 'san juan del r', 'ponderosa',
   $pj${"owner": "Cartones Ponderosa", "priority": 3, "products": "Coated recycled folding boxboard", "grades": ["Coated board", "Folding boxboard"], "capacity": {"value": 240000, "unit": "metric_t", "year": "Company history, 2012 upgrade (Valmet cites 270 kt)", "source": "cartonesponderosa.com"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.85, "fcc_share": 0.5, "fcc_loading": 0.03}, {"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.05}], "note": "Report example 5 pct of 240 kt at full output - planning scenario, not an order. Filler in the white top ply or middle ply, not a coating pigment."}, "pitch": "Ply-level FCC (top white or middle ply) for fibre saving at equal stiffness", "approach": "Propose a joint pilot - in-house furnish and coating development team. Querétaro GCC producers (ICC, ATSA) are nearby.", "to_collect": ["Filler use per ply", "Stiffness, compression, caliper, brightness, printability baseline", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('papel san francisco', 'mexicali', 'san francisco',
   $pj${"owner": "Papel San Francisco", "priority": 4, "products": "Toilet tissue, kitchen towel, napkins", "grades": ["Tissue"], "capacity_split": [{"label": "Target with TM10 (2025 report)", "value_t": 270000}], "pitch": "Low-dose FCC fibre replacement (1-5 pct) on a new machine", "approach": "Independent - shorter decisions.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('kimberly.*orizaba|orizaba.*kimberly', 'orizaba', 'kimberly',
   $pj${"owner": "Kimberly-Clark de México", "priority": 5, "products": "Toilet tissue, facial, napkins, towels", "grades": ["Tissue"], "pitch": "Strength and softness co-trial at 1-5 pct FCC", "approach": "Approach KCM centrally - one technical approval can cover every site.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('kimberly.*san juan del r|san juan del r.*kimberly', 'san juan del r', 'kimberly',
   $pj${"owner": "Kimberly-Clark de México", "priority": 5, "products": "Toilet tissue, facial, napkins, towels", "grades": ["Tissue"], "pitch": "Strength and softness co-trial at 1-5 pct FCC", "approach": "Approach KCM centrally - one technical approval can cover every site.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('kimberly.*morelia|morelia.*kimberly', 'morelia', 'kimberly',
   $pj${"owner": "Kimberly-Clark de México", "priority": 5, "products": "Toilet tissue, facial, napkins, towels", "grades": ["Tissue"], "pitch": "Strength and softness co-trial at 1-5 pct FCC", "approach": "Approach KCM centrally - one technical approval can cover every site.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('kimberly.*ramos arizpe|ramos arizpe.*kimberly', 'ramos arizpe', 'kimberly',
   $pj${"owner": "Kimberly-Clark de México", "priority": 5, "products": "Toilet tissue, facial, napkins, towels", "grades": ["Tissue"], "pitch": "Strength and softness co-trial at 1-5 pct FCC", "approach": "Approach KCM centrally - one technical approval can cover every site.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('kimberly.*ecatepec|ecatepec.*kimberly', 'ecatepec', 'kimberly',
   $pj${"owner": "Kimberly-Clark de México", "priority": 5, "products": "Toilet tissue, facial, napkins, towels", "grades": ["Tissue"], "pitch": "Strength and softness co-trial at 1-5 pct FCC", "approach": "Approach KCM centrally - one technical approval can cover every site.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('kimberly.*texmelucan|texmelucan.*kimberly', 'texmelucan', 'kimberly',
   $pj${"owner": "Kimberly-Clark de México", "priority": 5, "products": "Toilet tissue, facial, napkins, towels", "grades": ["Tissue"], "pitch": "Strength and softness co-trial at 1-5 pct FCC", "approach": "Approach KCM centrally - one technical approval can cover every site.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('essity.*monterrey|monterrey.*essity', 'monterrey', 'essity|\msca\M',
   $pj${"owner": "Essity", "priority": 6, "products": "Toilet tissue, facial, institutional tissue", "grades": ["Tissue"], "capacity": {"value": 80000, "unit": "metric_t", "year": "Essity Annual Report 2024", "source": "essity.com"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}], "note": "Report example 3 pct at full output - planning scenario, not an order."}, "approach": "Global technical approval at Essity first, then a Mexican pilot.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('essity.*sahag|sahag.*essity', 'sahag', 'essity|\msca\M',
   $pj${"owner": "Essity", "priority": 6, "products": "Toilet tissue, facial, institutional tissue", "grades": ["Tissue", "TAD tissue"], "capacity": {"value": 95000, "unit": "metric_t", "year": "Essity Annual Report 2024", "source": "essity.com"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}], "note": "Report example 3 pct at full output - planning scenario, not an order."}, "approach": "Global technical approval at Essity first, then a Mexican pilot.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('essity.*uruapan|uruapan.*essity', 'uruapan', 'essity|\msca\M',
   $pj${"owner": "Essity", "priority": 6, "products": "Toilet tissue, facial, institutional tissue", "grades": ["Tissue"], "capacity": {"value": 40000, "unit": "metric_t", "year": "Essity Annual Report 2024", "source": "essity.com"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}], "note": "Report example 3 pct at full output - planning scenario, not an order."}, "approach": "Global technical approval at Essity first, then a Mexican pilot.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('convertipap', 'tlaxcala', 'convertipap',
   $pj${"owner": "Convertipap", "priority": 7, "products": "Toilet tissue, towels, napkins, industrial rolls", "grades": ["Tissue"], "capacity_split": [{"label": "Target (2025 interview)", "value_t": 125000}], "approach": "Cost-saving pitch ahead of the TM8 expansion.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('(smurfit|westrock|gondi).*monterrey|monterrey.*(smurfit|westrock|gondi)', 'monterrey', '(smurfit|westrock|gondi)',
   $pj${"owner": "Smurfit Westrock", "products": "Containerboard", "grades": ["Containerboard"], "capacity": {"value": 402000, "unit": "metric_t", "year": "Smurfit Westrock 2025 Annual Report (end 2025)", "source": "smurfitwestrock.com"}, "capacity_split": [{"label": "Containerboard", "value_t": 402000}], "checked_at": "2026-10-15", "approach": "Strength-critical containerboard - later, after a packaging-grade FCC is proven."}$pj$::jsonb),
  ('(smurfit|westrock|gondi).*cerro gordo|cerro gordo.*(smurfit|westrock|gondi)', null, '(smurfit|westrock|gondi)',
   $pj${"owner": "Smurfit Westrock", "products": "Containerboard and boxboard", "grades": ["Containerboard", "Boxboard"], "capacity": {"value": 347000, "unit": "metric_t", "year": "Smurfit Westrock 2025 Annual Report (end 2025)", "source": "smurfitwestrock.com"}, "capacity_split": [{"label": "Containerboard", "value_t": 259000}, {"label": "Boxboard", "value_t": 88000}], "checked_at": "2026-10-15", "priority": 8, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Base", "utilization": 1, "fcc_share": 0.2536, "fcc_loading": 0.05}], "note": "Report example 5 pct on the boxboard line only at full output - planning scenario."}, "pitch": "Ply-level fibre saving on the boxboard line", "approach": "Boxboard line first - containerboard only after a packaging-grade FCC is proven.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"]}$pj$::jsonb),
  ('(smurfit|westrock|gondi).*guadalajara|guadalajara.*(smurfit|westrock|gondi)', 'guadalajara', '(smurfit|westrock|gondi)',
   $pj${"owner": "Smurfit Westrock", "products": "Containerboard and boxboard", "grades": ["Containerboard", "Boxboard"], "capacity": {"value": 270000, "unit": "metric_t", "year": "Smurfit Westrock 2025 Annual Report (end 2025)", "source": "smurfitwestrock.com"}, "capacity_split": [{"label": "Containerboard", "value_t": 160000}, {"label": "Boxboard", "value_t": 110000}], "checked_at": "2026-10-15", "priority": 8, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Base", "utilization": 1, "fcc_share": 0.4074, "fcc_loading": 0.05}], "note": "Report example 5 pct on the boxboard line only at full output - planning scenario."}, "pitch": "Ply-level fibre saving on the boxboard line", "approach": "Boxboard line first - containerboard only after a packaging-grade FCC is proven.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"]}$pj$::jsonb),
  ('(smurfit|westrock|gondi).*san pablo|san pablo.*(smurfit|westrock|gondi)', null, '(smurfit|westrock|gondi)',
   $pj${"owner": "Smurfit Westrock", "products": "Containerboard", "grades": ["Containerboard"], "capacity": {"value": 243000, "unit": "metric_t", "year": "Smurfit Westrock 2025 Annual Report (end 2025)", "source": "smurfitwestrock.com"}, "capacity_split": [{"label": "Containerboard", "value_t": 243000}], "checked_at": "2026-10-15", "approach": "Strength-critical containerboard - later, after a packaging-grade FCC is proven."}$pj$::jsonb),
  ('(smurfit|westrock|gondi).*los reyes|los reyes.*(smurfit|westrock|gondi)', null, '(smurfit|westrock|gondi)',
   $pj${"owner": "Smurfit Westrock", "products": "Containerboard", "grades": ["Containerboard"], "capacity": {"value": 158000, "unit": "metric_t", "year": "Smurfit Westrock 2025 Annual Report (end 2025)", "source": "smurfitwestrock.com"}, "capacity_split": [{"label": "Containerboard", "value_t": 158000}], "checked_at": "2026-10-15", "approach": "Strength-critical containerboard - later, after a packaging-grade FCC is proven."}$pj$::jsonb),
  ('(smurfit|westrock|gondi).*san luis potos|san luis potos.*(smurfit|westrock|gondi)', 'san luis potos', '(smurfit|westrock|gondi)',
   $pj${"owner": "Smurfit Westrock", "products": "Containerboard", "grades": ["Containerboard"], "capacity": {"value": 71000, "unit": "metric_t", "year": "Smurfit Westrock 2025 Annual Report (end 2025)", "source": "smurfitwestrock.com"}, "capacity_split": [{"label": "Containerboard", "value_t": 71000}], "checked_at": "2026-10-15", "approach": "Strength-critical containerboard - later, after a packaging-grade FCC is proven."}$pj$::jsonb),
  ('green ?paper', null, 'green ?paper',
   $pj${"owner": "Greenpaper", "products": "Industrial packaging and containerboard (Nuevo León)", "approach": "Confirm running machines and grades before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('grupak', null, 'grupak',
   $pj${"owner": "Grupak", "products": "Containerboard and packaging (Morelos, Hidalgo)", "approach": "Confirm running machines and grades before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('softys', null, 'softys',
   $pj${"owner": "Softys México", "products": "Tissue - Altamira tissue machine project announced", "approach": "Confirm running machines and grades before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('corporativo papelera', null, 'corporativo papelera',
   $pj${"owner": "Grupo Corporativo Papelera", "products": "Tissue - machine upgrade and expansion reported", "approach": "Confirm running machines and grades before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('papeles ultra', null, 'papeles ultra',
   $pj${"owner": "Papeles Ultra", "products": "Paper and board - products to confirm", "approach": "Confirm running machines and grades before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('industrial papelera san luis', null, 'industrial papelera san luis',
   $pj${"owner": "Industrial Papelera San Luis", "products": "Industrial papers (San Luis Potosí)", "approach": "Confirm running machines and grades before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('copamex.*(industrias|san nicol)', null, 'copamex.*(industrias|san nicol)',
   $pj${"owner": "Copamex Industrias (San Nicolás de los Garza)", "products": "Kraft and specialty papers", "approach": "Confirm running machines and grades before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('papelera chihuahua', null, 'papelera chihuahua',
   $pj${"owner": "Papelera Chihuahua (Copamex)", "products": "Kraft and specialty papers", "approach": "Confirm running machines and grades before outreach.", "checked_at": "2026-10-15"}$pj$::jsonb)
  ) as v(name_rx, city_rx, owner_rx, plant)
) m
where mp.party_id = m.id;

-- ---------- 4) SUPPLY LINK (historical) ----------
insert into app.party_supply_links
  (id, organization_id, mill_party_id, filler_party_id, link_type,
   product_grade, volume_estimate, confidence, active_since, active_until,
   notes, extra_data, created_at, updated_at)
select gen_random_uuid(), 'b25de8f2-1020-482f-9012-183f63883169'::uuid, m.id, f.id, 'historical', 'PCC filler-grade', null, 'medium', null, null,
       'SMI satellite PCC at Colonia Anahuac for the Pondercel mill - older industry reports, current operation not confirmed',
       jsonb_build_object('supply_structure', 'satellite PCC next to the mill', 'source', 'industry reports + Mexican company directory',
                          'batch', 'mexico_update_20261015', 'researched_at', '2026-10-15'),
       now(), now()
from (values ('pondercel', 'cuauht[eé]moc', 'copamex|pondercel')) as v(name_rx, city_rx, owner_rx)
cross join lateral (select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MX'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id) m
cross join lateral (
  select x.id from app.parties x
  where x.party_type_id = 3 and x.deleted_at is null
    and x.party_name ~* '(specialty minerals|minerals technologies).*(m[eé]x|an[aá]huac|chihuahua)'
  order by x.created_at limit 1
) f
where m.id is not null
  and not exists (select 1 from app.party_supply_links l
                  where l.mill_party_id = m.id and l.filler_party_id = f.id and l.deleted_at is null);

-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'MX', 'Mexico', 'high',
   $cm$Pondercel bond paper with SMI PCC history, Scribe, Cartones Ponderosa board and a large tissue base$cm$,
   $cm$Omya and SMI (both MBG licensees) are present - Omya with four plants, SMI with a satellite PCC record at Anáhuac for Copamex Pondercel. White paper: Pondercel and Bio Pappel Scribe. Coated recycled board: Cartones Ponderosa (240 kt). Tissue: KCM, Essity (215 kt), Papel San Francisco, Convertipap. Smurfit Westrock runs 1.49 Mt of mostly containerboard.$cm$,
   $cm${"fillers": "Omya México (4 plants, lab at Cuautitlán Izcalli), SMI satellite PCC at Anáhuac for Pondercel (status to confirm), local GCC: Terrazo (Torreón), Reverté (Durango, majority stake sold 2026), ICC and ATSA (Querétaro), LEDSA. ONIC sells CaCO3 slurry and paper chemicals. Calidra is lime only. Infra Derivados Químicos PCC (Cuautitlán) is 2005 history.", "mills": "Printing and writing: Copamex Pondercel (bond), Bio Pappel Scribe. Coated recycled board: Cartones Ponderosa 240 kt. Tissue: Kimberly-Clark de México (6 sites), Essity 215 kt (Monterrey, Sahagún, Uruapan), Papel San Francisco 270 kt target, Convertipap 125 kt target. Packaging: Smurfit Westrock 1.49 Mt in six mills (198 kt boxboard).", "strategy": "Pondercel first (clear PCC baseline, SMI history), then Scribe, then ply-level FCC at Cartones Ponderosa. Tissue pilots at 1-5 pct with independents (Papel San Francisco, Convertipap). Production runs through licensees Omya and SMI - local GCC producers (Terrazo, Reverté, ICC) only as additional licensees.", "risks": "Strong recycled-fibre base and 43.6 pct import share in pulp, paper and board. Omya Multifill is a comparable in-house technology. Mill-level filler use and supplier contracts are not public.", "next_steps": ["Confirm whether SMI Anáhuac still supplies Pondercel", "Identify the Bio Pappel white-paper machine and its filler supplier", "Propose a ply-level pilot to Cartones Ponderosa"], "key_numbers": [{"label": "Pulp, paper and board output 2025", "value": "USD 2.0 bn (Euromonitor)"}, {"label": "Domestic market 2025", "value": "USD 2.7 bn, imports about 43.6 pct"}, {"label": "Smurfit Westrock Mexico", "value": "1.49 Mt in six mills"}, {"label": "Essity Mexico tissue", "value": "215 kt"}, {"label": "Report scenario", "value": "28,350 t FCC, USD 425,250 royalty"}], "files": ["seed_20261015m_mexico_mills_fillers"]}$cm$::jsonb,
   $cm$Pondercel 인쇄용지(SMI PCC 이력)·Scribe·Ponderosa 백판지 + 대형 티슈 시장$cm$,
   $cm$라이선시 Omya(멕시코 공장 4곳)·SMI(Anáhuac 위성 PCC 기록) 모두 진출. 1순위 Copamex Pondercel, 2순위 Bio Pappel Scribe, 3순위 Cartones Ponderosa 층별 적용. 티슈는 KCM·Essity·Papel San Francisco·Convertipap 에 1~5% 시험.$cm$,
   28350, 28350,
   $cm$Ponderosa 24만 t·Smurfit 백판지 19.8만 t 5% + Essity 21.5만 t 3% (가동 100% 가정, 보고서 예시)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
with v(name_rx, city_rx, owner_rx) as (values
  ('pondercel', 'cuauht[eé]moc', 'copamex|pondercel'),
  ('scribe|bio ?pappel.*orizaba', 'orizaba', 'pappel|scribe'),
  ('cartones ponderosa', 'san juan del r', 'ponderosa'),
  ('papel san francisco', 'mexicali', 'san francisco'),
  ('kimberly.*orizaba|orizaba.*kimberly', 'orizaba', 'kimberly'),
  ('kimberly.*san juan del r|san juan del r.*kimberly', 'san juan del r', 'kimberly'),
  ('kimberly.*morelia|morelia.*kimberly', 'morelia', 'kimberly'),
  ('kimberly.*ramos arizpe|ramos arizpe.*kimberly', 'ramos arizpe', 'kimberly'),
  ('kimberly.*ecatepec|ecatepec.*kimberly', 'ecatepec', 'kimberly'),
  ('kimberly.*texmelucan|texmelucan.*kimberly', 'texmelucan', 'kimberly'),
  ('essity.*monterrey|monterrey.*essity', 'monterrey', 'essity|\msca\M'),
  ('essity.*sahag|sahag.*essity', 'sahag', 'essity|\msca\M'),
  ('essity.*uruapan|uruapan.*essity', 'uruapan', 'essity|\msca\M'),
  ('convertipap', 'tlaxcala', 'convertipap'),
  ('(smurfit|westrock|gondi).*monterrey|monterrey.*(smurfit|westrock|gondi)', 'monterrey', '(smurfit|westrock|gondi)'),
  ('(smurfit|westrock|gondi).*cerro gordo|cerro gordo.*(smurfit|westrock|gondi)', null, '(smurfit|westrock|gondi)'),
  ('(smurfit|westrock|gondi).*guadalajara|guadalajara.*(smurfit|westrock|gondi)', 'guadalajara', '(smurfit|westrock|gondi)'),
  ('(smurfit|westrock|gondi).*san pablo|san pablo.*(smurfit|westrock|gondi)', null, '(smurfit|westrock|gondi)'),
  ('(smurfit|westrock|gondi).*los reyes|los reyes.*(smurfit|westrock|gondi)', null, '(smurfit|westrock|gondi)'),
  ('(smurfit|westrock|gondi).*san luis potos|san luis potos.*(smurfit|westrock|gondi)', 'san luis potos', '(smurfit|westrock|gondi)'),
  ('green ?paper', null, 'green ?paper'),
  ('grupak', null, 'grupak'),
  ('softys', null, 'softys'),
  ('corporativo papelera', null, 'corporativo papelera'),
  ('papeles ultra', null, 'papeles ultra'),
  ('industrial papelera san luis', null, 'industrial papelera san luis'),
  ('copamex.*(industrias|san nicol)', null, 'copamex.*(industrias|san nicol)'),
  ('papelera chihuahua', null, 'papelera chihuahua')
)
select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
       case when p.source = 'mexico_update_20261015' then 'added now' when p.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from v
left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MX'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
left join app.paper_mill_profile mp on mp.party_id = p.id
union all
select 'filler', p.party_name,
       case when p.source = 'mexico_update_20261015' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'omya.*m[eé]x' or p.party_name ~* '(specialty minerals|minerals technologies).*(m[eé]x|an[aá]huac|chihuahua)' or p.party_name ~* 'terrazo' or p.party_name ~* 'revert[eé].*(am[eé]rica|durango|m[eé]x)' or p.party_name ~* 'industria de carbonato' or p.party_name ~* '\matsa\M' or p.party_name ~* '^onic\M' or p.party_name ~* 'ledsa')
union all
select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', '-'
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and l.extra_data ->> 'batch' = 'mexico_update_20261015'
union all
select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
       coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
from app.country_markets cm
where cm.country_code = 'MX'
order by 1, 4, 2;
