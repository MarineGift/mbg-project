-- 20260620150000_filler_supplier_profile_enrich_batch9.sql
-- Filler-supplier ENRICHMENT - BATCH 9 (India, homepage-read). UTF-8.
-- Same non-destructive design as batch 7/8 (mineral_class COALESCE; notes APPEND
-- with idempotent guard; industry_source only if null; market_role etc. untouched).

-- 1) company intro (ko/en)
update app.parties p
set intro_ko = d.intro_ko, intro_en = d.intro_en, updated_at = now()
from (values
  ('feab20d4-08cb-423f-814f-7f29ed665244'::uuid,
   '인도의 대표 백색 산업광물·기능성 충전제 제조사(바도다라, BSE/NSE 상장). GCC·PCC·표면처리·초미세/나노 등급의 탄산칼슘과 카올린·탤크 등을 생산하며, 제지용 코팅안료·충전제(TiO2 일부 대체)로 공급. 베트남 법인·말레이시아 채석장 보유.',
   'A leading Indian producer of white industrial minerals and functional fillers (Vadodara; BSE/NSE listed). Makes GCC, PCC, surface-coated and ultrafine/nano CaCO3 plus kaolin and talc, supplying paper-grade coating pigments and fillers (partial TiO2 replacement). Has a Vietnam unit and Malaysian quarries.'),
  ('6ce2f30c-4c98-4886-8922-62ffd57f62b2'::uuid,
   '인도 최대 PCC 제조사(1981년 설립, BSE/NSE 상장). PCC·GCC·WGCC·ACC 등 19개 탄산칼슘 등급을 생산하며 전분·소르비톨·에탄올 사업도 영위. 인도 최초로 제지공장 현장(on-site/satellite) PCC를 도입해 Magnum Papers·Silvertone·Orient Paper Mills(Birla) 등에 공급.',
   'India''s leading PCC producer (founded 1981; BSE/NSE listed), making 19 grades of CaCO3 (PCC/GCC/WGCC/ACC) alongside starch, sorbitol and ethanol. It pioneered on-site/satellite PCC plants in India, supplying paper mills such as Magnum Papers, Silvertone and Orient Paper Mills (Birla).'),
  ('22f4f49d-91d8-488f-9165-fa55659b0763'::uuid,
   '1972년 설립된 우다이푸르 기반 산업광물 기업으로 세계 최대 규모의 규회석(wollastonite) 생산사이자 인도 최대 방해석(calcite)/GCC·최초 WGCC 슬러리 생산사(계열 Fimakem). 규회석·GCC·WGCC·탤크·돌로마이트 등 80여 등급을 제지 등 20여 산업에 공급.',
   'An Udaipur-based industrial-minerals firm founded 1972 -- the world''s largest wollastonite producer and India''s largest calcite/GCC and first WGCC-slurry producer (via affiliate Fimakem). Supplies 80+ grades of wollastonite, GCC, WGCC, talc and dolomite to 20+ industries including paper.'),
  ('53a7435e-5761-449d-a6ea-fe1628cc0b50'::uuid,
   '1960년 설립된 인도 최대의 다종광물 솔루션 기업(상장). 보크사이트·벤토나이트·카올린·GCC 등을 채굴·가공·수출하며, Kutch의 White Performance Minerals 단지에서 특수 카올린과 GCC를 생산. 제지용 카올린 코팅안료(Ashagloss/Topgloss)와 GCC를 공급.',
   'India''s largest multi-mineral solutions group, founded 1960 (listed), mining/processing/exporting bauxite, bentonite, kaolin and GCC. Its White Performance Minerals complex in Kutch makes specialty kaolin and GCC, supplying paper-grade kaolin coating pigments (Ashagloss/Topgloss) and GCC.'),
  ('34e3bab8-7ec7-4a9b-b0ca-43d65a57cf2d'::uuid,
   'Ashapura 그룹의 White Performance Minerals 부문(Kutch, 2016 가동). 코팅·비코팅 GCC와 특수 카올린을 PLC 자동공정으로 생산해 제지·도료·고무·화장품 등에 충전제/코팅안료로 공급하는 인도 유수의 가공 탄산칼슘·카올린 생산.',
   'The White Performance Minerals division of the Ashapura Group (Kutch, commissioned 2016). Produces coated/uncoated GCC and specialty kaolin via automated PLC processes for paper, paints, rubber and cosmetics as fillers/coating pigments; a leading Indian processed-CaCO3 and kaolin maker.'),
  ('b8abccc4-f5c0-4c77-b1de-cfe1d79797cf'::uuid,
   '인도의 침강성 탄산칼슘(PCC) 제조사(공개법인). 고순도 PCC를 여러 산업에 공급하며 제지용으로도 활용 가능.',
   'An Indian precipitated calcium carbonate (PCC) producer (public limited), supplying high-purity PCC to multiple industries, with paper-grade use plausible.'),
  ('aaf7bd3c-e640-4047-a8da-93cecaa7e48a'::uuid,
   '우다이푸르 기반의 방해석/중질탄산칼슘(GCC) 제조사. 제지를 포함한 다양한 산업용 GCC를 생산·공급.',
   'An Udaipur-based producer of calcite/ground calcium carbonate (GCC), supplying industrial GCC for uses including paper.'),
  ('f26ebc78-777d-4e59-aaa3-152532ac40a1'::uuid,
   '라자스탄 알와르 소재 중질탄산칼슘(GCC) 제조사. 98%+ 순도의 100~1500 mesh GCC를 제지·도료·플라스틱·건설용으로 생산.',
   'A ground calcium carbonate (GCC) maker in Alwar, Rajasthan, producing 98%+ purity GCC at 100-1500 mesh for paper, paints, plastics and construction.'),
  ('b6514b8d-e09d-47f2-b241-7183f27d806e'::uuid,
   '하리아나 야무나나가르 소재 탄산칼슘 제조사. 제지용 PCC와 GCC를 생산·공급.',
   'A calcium-carbonate maker in Yamunanagar, Haryana, producing PCC and GCC for paper applications.')
) as d(party_id, intro_ko, intro_en)
where p.id = d.party_id
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169';

-- 2) profile enrich
update app.filler_supplier_profile f
set mineral_class    = coalesce(d.mc, f.mineral_class),
    notes            = coalesce(f.notes,'') || E'\n[homepage 2026-06-20] ' || d.note,
    industry_source  = coalesce(f.industry_source, d.src),
    updated_at       = now()
from (values
  ('feab20d4-08cb-423f-814f-7f29ed665244'::uuid, 'both',
   'Paper-grade: YES (coating pigment + filler; partial TiO2 replacement). GCC+PCC+surface-coated+ultrafine. Leading India white-minerals maker; Vadodara; BSE/NSE.', 'https://www.20microns.com'),
  ('6ce2f30c-4c98-4886-8922-62ffd57f62b2'::uuid, 'both',
   'Paper-grade: YES. India PCC leader (19 CaCO3 grades: PCC/GCC/WGCC/ACC). FIRST on-site/satellite PCC operator in India. On-site PCC at paper mills: Magnum Papers (2009, 1st), Silvertone Pulp&Paper (Muzaffarnagar 2013), Orient Paper Mills (Birla, Amlai 2015). BSE/NSE.', 'https://www.gulshanindia.com'),
  ('22f4f49d-91d8-488f-9165-fa55659b0763'::uuid, 'gcc',
   'Paper-grade: YES (fillers/extenders for paper among 20+ industries). World #1 wollastonite + India #1 calcite/GCC + India-first WGCC slurry (via Fimakem). Udaipur, 1972; 80+ grades.', 'https://www.wolkem.com'),
  ('53a7435e-5761-449d-a6ea-fe1628cc0b50'::uuid, 'gcc',
   'Paper-grade: YES (kaolin coating pigments Ashagloss/Topgloss + GCC). India largest multi-mineral group (1960, listed): bauxite/bentonite/kaolin/GCC. White Performance Minerals complex, Kutch.', 'https://www.ashapura.com'),
  ('34e3bab8-7ec7-4a9b-b0ca-43d65a57cf2d'::uuid, 'gcc',
   'Paper-grade: YES (specialty kaolin + coated/uncoated GCC for paper). White Performance Minerals (Kutch 2016). Leading India processed-CaCO3 + kaolin.', 'https://www.ashapura.com'),
  ('b8abccc4-f5c0-4c77-b1de-cfe1d79797cf'::uuid, 'pcc',
   'Paper-grade: plausible (PCC maker; public Ltd). PCC for multiple industries.', 'https://www.kunalcalcium.com'),
  ('aaf7bd3c-e640-4047-a8da-93cecaa7e48a'::uuid, 'gcc',
   'Paper-grade: YES (GCC/calcite for paper among uses). Udaipur calcite/GCC maker.', 'https://www.mumalmicrons.in'),
  ('f26ebc78-777d-4e59-aaa3-152532ac40a1'::uuid, 'gcc',
   'Paper-grade: YES (GCC 100-1500 mesh for paper/paints/plastics/construction; 98%+ CaCO3). Alwar, Rajasthan.', 'https://www.shikharmicrons.com'),
  ('b6514b8d-e09d-47f2-b241-7183f27d806e'::uuid, 'both',
   'Paper-grade: YES (PCC/GCC for paper). Yamunanagar, Haryana.', 'https://www.yamunacalcium.com')
) as d(party_id, mc, note, src)
where f.party_id = d.party_id
  and f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and (f.notes is null or f.notes not like '%[homepage 2026-06-20]%');

-- 3) INSERT fallback (only if profile missing)
insert into app.filler_supplier_profile (id, party_id, organization_id, mineral_class, notes, industry_source, created_at, updated_at)
select gen_random_uuid(), d.party_id, 'b25de8f2-1020-482f-9012-183f63883169', d.mc,
       '[homepage 2026-06-20] ' || d.note, d.src, now(), now()
from (values
  ('feab20d4-08cb-423f-814f-7f29ed665244'::uuid, 'both', 'Paper-grade: YES. GCC+PCC; India white-minerals leader.', 'https://www.20microns.com'),
  ('6ce2f30c-4c98-4886-8922-62ffd57f62b2'::uuid, 'both', 'Paper-grade: YES. India PCC leader; on-site PCC (Magnum/Silvertone/Orient-Birla).', 'https://www.gulshanindia.com'),
  ('22f4f49d-91d8-488f-9165-fa55659b0763'::uuid, 'gcc',  'Paper-grade: YES. World #1 wollastonite + India #1 GCC/WGCC.', 'https://www.wolkem.com'),
  ('53a7435e-5761-449d-a6ea-fe1628cc0b50'::uuid, 'gcc',  'Paper-grade: YES. Multi-mineral group; kaolin+GCC for paper.', 'https://www.ashapura.com'),
  ('34e3bab8-7ec7-4a9b-b0ca-43d65a57cf2d'::uuid, 'gcc',  'Paper-grade: YES. White Performance Minerals: GCC+kaolin.', 'https://www.ashapura.com'),
  ('b8abccc4-f5c0-4c77-b1de-cfe1d79797cf'::uuid, 'pcc',  'Paper-grade: plausible. PCC maker.', 'https://www.kunalcalcium.com'),
  ('aaf7bd3c-e640-4047-a8da-93cecaa7e48a'::uuid, 'gcc',  'Paper-grade: YES. Udaipur GCC/calcite.', 'https://www.mumalmicrons.in'),
  ('f26ebc78-777d-4e59-aaa3-152532ac40a1'::uuid, 'gcc',  'Paper-grade: YES. Alwar GCC 98%+.', 'https://www.shikharmicrons.com'),
  ('b6514b8d-e09d-47f2-b241-7183f27d806e'::uuid, 'both', 'Paper-grade: YES. PCC/GCC for paper.', 'https://www.yamunacalcium.com')
) as d(party_id, mc, note, src)
where not exists (
  select 1 from app.filler_supplier_profile f
  where f.party_id = d.party_id
    and f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
);

-- 4) verify
select p.party_name, (p.intro_ko is not null) as has_intro_ko, f.mineral_class, left(f.notes,120) notes_tail
from app.parties p
left join app.filler_supplier_profile f
  on f.party_id = p.id and f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
where p.id in (
  'feab20d4-08cb-423f-814f-7f29ed665244','6ce2f30c-4c98-4886-8922-62ffd57f62b2',
  '22f4f49d-91d8-488f-9165-fa55659b0763','53a7435e-5761-449d-a6ea-fe1628cc0b50',
  '34e3bab8-7ec7-4a9b-b0ca-43d65a57cf2d','b8abccc4-f5c0-4c77-b1de-cfe1d79797cf',
  'aaf7bd3c-e640-4047-a8da-93cecaa7e48a','f26ebc78-777d-4e59-aaa3-152532ac40a1',
  'b6514b8d-e09d-47f2-b241-7183f27d806e'
)
order by p.party_name;
