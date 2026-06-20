-- 20260620180000_filler_supplier_profile_enrich_batch12.sql
-- Filler-supplier ENRICHMENT - BATCH 12 (Japan independents + Turkey Nigde calcite cluster). UTF-8.
-- Same non-destructive design (mineral_class COALESCE; notes APPEND w/ guard;
-- industry_source only if null; market_role etc. untouched).

-- 1) company intro (ko/en)
update app.parties p
set intro_ko = d.intro_ko, intro_en = d.intro_en, updated_at = now()
from (values
  ('21d35d02-debe-4575-8018-dcef7468c02c'::uuid,
   '日鉄鉱業(Nittetsu Mining) 그룹의 탄산칼슘 분체 제조사. 그룹 석회석을 원료로 중질탄산칼슘(GCC) 등 무기 분체를 생산해 제지·수지·도료 등에 공급.',
   'A ground calcium carbonate (GCC) powder maker in the Nittetsu Mining group, producing GCC and inorganic powders from group limestone for paper, resins and coatings.'),
  ('92f57c52-4570-4464-b212-fbc52240e34a'::uuid,
   '1939년 신일본제철 광업부문이 독립해 설립된 일본 최상급 석회석 생산사(상장, 연 약 1,800만t). 석회석을 철강·시멘트·골재·제지·유리·탈황용으로 공급하고 탄산칼슘 등 무기 분체와 무기질지(난연지)도 생산. 탄산칼슘 분체는 자회사 Fimatec가 담당.',
   'Japan''s top-class limestone producer (listed; ~18M t/y), spun off from Nippon Steel''s mining division in 1939. Supplies limestone for steel, cement, aggregate, paper, glass and flue-gas desulfurization, and makes CaCO3 inorganic powders and inorganic (flame-retardant) paper; CaCO3 powders are handled by its subsidiary Fimatec.'),
  ('f24bb73a-2cc9-4727-a54d-1f6e0ee318c9'::uuid,
   '1953년 설립된 탄산칼슘 종합 제조사. 순백색 결정질 석회석 자가광산(히로시마 東城·미에 鈴鹿·후쿠시마)을 보유하고 중질(GCC)·초미립 NS·표면처리(노벨라이트/NCC)·서브미크론(니트렉스) 등 다양한 등급을 생산해 제지·수지·식품 등에 공급.',
   'A comprehensive calcium-carbonate maker founded 1953 with its own pure-white crystalline limestone mines (Tojo/Hiroshima, Suzuka/Mie, Fukushima). Produces GCC, ultrafine "NS", surface-treated (Noverite/NCC) and submicron ("Nitrex") grades for paper, resins and food.'),
  ('85249ecd-c58c-499c-b7df-3cd505c742e4'::uuid,
   '터키 Niğde 기반 방해석(calcite) 미분쇄 기업으로 채석 규모 기준 터키 최대급. 약 4,500데카르 광산과 연 120만t 미분쇄 설비로 GCC를 생산해 제지·도료·플라스틱 등에 공급(ANDCARB 브랜드).',
   'A Niğde-based calcite micronizer in Turkey, among the country''s largest by quarry scale (~4,500 decares of mines; 1.2M t/y micronization), producing GCC (ANDCARB brand) for paper, paints and plastics.'),
  ('38fa015e-204d-4cc9-83ea-b31091da6123'::uuid,
   '터키 Niğde 기반 방해석 미분쇄 기업으로 자국 calcite 2위급이며 나노 등급 전문. GCC(나노 등급 포함)를 제지·도료·플라스틱 등에 공급.',
   'A Niğde-based calcite micronizer in Turkey, the country''s #2 by scale and a nano-grade specialist, supplying GCC (including nano grades) for paper, paints and plastics.'),
  ('2a4a6b46-4a82-4cb7-b56e-b9846c4e104c'::uuid,
   '터키의 미분쇄 광물 전문기업(TURKCARB 브랜드). 방해석 기반 GCC 등 다종 광물을 제지·도료·플라스틱 등에 공급.',
   'A Turkish micronized-minerals specialist (TURKCARB brand), supplying calcite-based GCC and multi-mineral products for paper, paints and plastics.'),
  ('ec511809-95e8-43e8-a13a-d5744c2ea877'::uuid,
   '터키 Niğde calcite 클러스터의 미분쇄 기업. GCC를 제지·도료·플라스틱 등 산업용으로 생산·공급.',
   'A micronizing firm in Turkey''s Niğde calcite cluster, producing GCC for paper, paints and plastics.'),
  ('dc92d027-424c-4696-bffe-7f349c26c253'::uuid,
   'Niğtaş 계열의 터키 Niğde 방해석 미분쇄 기업. GCC를 제지·도료·플라스틱 등에 공급.',
   'A Niğde calcite micronizer in Turkey, an affiliate of the Niğtaş group, supplying GCC for paper, paints and plastics.')
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
  ('21d35d02-debe-4575-8018-dcef7468c02c'::uuid, 'gcc',
   'Paper-grade: YES (GCC for paper among uses). Nittetsu Mining group CaCO3 powder maker.', 'http://www.fmt.co.jp'),
  ('92f57c52-4570-4464-b212-fbc52240e34a'::uuid, 'gcc',
   'Paper-grade: YES (limestone for paper + inorganic paper). Japan top limestone ~18M t/y; listed (ex-Nippon Steel mining). CaCO3 powders via Fimatec.', 'https://www.nittetsukou.co.jp'),
  ('f24bb73a-2cc9-4727-a54d-1f6e0ee318c9'::uuid, 'gcc',
   'Paper-grade: plausible (GCC incl. ultrafine NS / submicron Nitrex + surface-treated). Own white-crystalline limestone mines; since 1953.', 'https://www.nittofunka.co.jp'),
  ('85249ecd-c58c-499c-b7df-3cd505c742e4'::uuid, 'gcc',
   'Paper-grade: YES (GCC). Turkey #1 calcite by quarry scale; Nigde ~4,500 decares + 1.2M t/y micronization. ANDCARB brand.', NULL),
  ('38fa015e-204d-4cc9-83ea-b31091da6123'::uuid, 'gcc',
   'Paper-grade: YES (GCC incl. nano grades). Turkey #2 calcite; nano-grade specialist (Nigde).', NULL),
  ('2a4a6b46-4a82-4cb7-b56e-b9846c4e104c'::uuid, 'gcc',
   'Paper-grade: YES (GCC). TURKCARB brand; Turkish micronized-minerals specialist.', NULL),
  ('ec511809-95e8-43e8-a13a-d5744c2ea877'::uuid, 'gcc',
   'Paper-grade: YES (GCC). Nigde calcite cluster member (Turkey).', NULL),
  ('dc92d027-424c-4696-bffe-7f349c26c253'::uuid, 'gcc',
   'Paper-grade: YES (GCC). Nigtas affiliate; Nigde calcite micronizer (Turkey).', NULL)
) as d(party_id, mc, note, src)
where f.party_id = d.party_id
  and f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and (f.notes is null or f.notes not like '%[homepage 2026-06-20]%');

-- 3) INSERT fallback (only if profile missing)
insert into app.filler_supplier_profile (id, party_id, organization_id, mineral_class, notes, industry_source, created_at, updated_at)
select gen_random_uuid(), d.party_id, 'b25de8f2-1020-482f-9012-183f63883169', d.mc,
       '[homepage 2026-06-20] ' || d.note, d.src, now(), now()
from (values
  ('21d35d02-debe-4575-8018-dcef7468c02c'::uuid, 'gcc', 'Paper-grade: YES. Nittetsu Mining group CaCO3 powder.', 'http://www.fmt.co.jp'),
  ('92f57c52-4570-4464-b212-fbc52240e34a'::uuid, 'gcc', 'Paper-grade: YES. Japan top limestone; CaCO3 via Fimatec.', 'https://www.nittetsukou.co.jp'),
  ('f24bb73a-2cc9-4727-a54d-1f6e0ee318c9'::uuid, 'gcc', 'Paper-grade: plausible. GCC maker since 1953; own mines.', 'https://www.nittofunka.co.jp'),
  ('85249ecd-c58c-499c-b7df-3cd505c742e4'::uuid, 'gcc', 'Paper-grade: YES. Turkey #1 calcite (ANDCARB), Nigde.', NULL),
  ('38fa015e-204d-4cc9-83ea-b31091da6123'::uuid, 'gcc', 'Paper-grade: YES. Turkey #2 calcite; nano-grade (Nigtas).', NULL),
  ('2a4a6b46-4a82-4cb7-b56e-b9846c4e104c'::uuid, 'gcc', 'Paper-grade: YES. TURKCARB micronized minerals.', NULL),
  ('ec511809-95e8-43e8-a13a-d5744c2ea877'::uuid, 'gcc', 'Paper-grade: YES. Nigde calcite cluster (Nidas).', NULL),
  ('dc92d027-424c-4696-bffe-7f349c26c253'::uuid, 'gcc', 'Paper-grade: YES. Nigde calcite (Mikrokal, Nigtas affiliate).', NULL)
) as d(party_id, mc, note, src)
where not exists (
  select 1 from app.filler_supplier_profile f
  where f.party_id = d.party_id
    and f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
);

-- 4) verify
select p.party_name, (p.intro_ko is not null) as has_intro_ko, f.mineral_class, left(f.notes,110) notes_tail
from app.parties p
left join app.filler_supplier_profile f
  on f.party_id = p.id and f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
where p.id in (
  '21d35d02-debe-4575-8018-dcef7468c02c','92f57c52-4570-4464-b212-fbc52240e34a',
  'f24bb73a-2cc9-4727-a54d-1f6e0ee318c9','85249ecd-c58c-499c-b7df-3cd505c742e4',
  '38fa015e-204d-4cc9-83ea-b31091da6123','2a4a6b46-4a82-4cb7-b56e-b9846c4e104c',
  'ec511809-95e8-43e8-a13a-d5744c2ea877','dc92d027-424c-4696-bffe-7f349c26c253'
)
order by p.party_name;
