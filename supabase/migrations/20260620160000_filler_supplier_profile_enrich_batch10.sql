-- 20260620160000_filler_supplier_profile_enrich_batch10.sql
-- Filler-supplier ENRICHMENT - BATCH 10 (China, homepage-read). UTF-8.
-- Same non-destructive design as batch 7/8/9.

-- 1) company intro (ko/en)
update app.parties p
set intro_ko = d.intro_ko, intro_en = d.intro_en, updated_at = now()
from (values
  ('7d7a6790-086c-472f-8675-5a35a8bdefbd'::uuid,
   '1967년 설립된 후베이 징먼 소재 상장사(SZSE 002783). 민수용 폭약·질산암모늄·합성암모니아·비료가 주력이며, 나노 탄산칼슘(나노-PCC)을 부수 제품군으로 생산. 나노-PCC는 제지·플라스틱·고무·도료 등에 사용 가능.',
   'A listed company in Jingmen, Hubei (SZSE 002783, founded 1967). Its core business is civil explosives, ammonium nitrate, synthetic ammonia and fertilizers; nano calcium carbonate (nano-PCC) is a secondary product line usable in paper, plastics, rubber and coatings.'),
  ('256947a4-9f3b-42ee-96be-743ad72cbd2a'::uuid,
   '푸젠 소재 나노 탄산칼슘(PCC) 전문 제조사. 제지용을 포함한 나노-PCC를 생산·공급.',
   'A Fujian-based nano calcium carbonate (PCC) specialist, producing nano-PCC including paper-grade applications.'),
  ('2c7759a6-3b7a-4312-af03-5d498e2f4544'::uuid,
   '광시 소재 신소재 기업으로 나노-PCC·미세 PCC 및 GCC를 제지용 등으로 생산·공급.',
   'A Guangxi-based new-materials maker producing nano-PCC, micro-PCC and GCC for uses including papermaking.'),
  ('7be68e77-1c7c-4dc3-afd7-c92df46b3481'::uuid,
   '1997년 설립된 장쑤(양저우) 소재 분체기술 기업(신삼판 834008). 초미세 중질탄산칼슘(GCC)을 제지·도료 등에 공급.',
   'A powder-technology firm in Yangzhou, Jiangsu, founded 1997 (NEEQ 834008), supplying ultrafine ground calcium carbonate (GCC) for paper and coatings.'),
  ('6e2eddb4-511a-454f-8f6b-d2e2533f933a'::uuid,
   '1993년 설립된 광둥 롄저우 기반 탄산칼슘 제조사(연산 약 60만t). GCC·PCC·나노 탄산칼슘·마스터배치를 생산하며 다양한 산업에 충전제를 공급.',
   'A Guangdong (Lianzhou) calcium-carbonate maker founded 1993 (~600k t/y), producing GCC, PCC, nano CaCO3 and masterbatch as fillers for various industries.')
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
  ('7d7a6790-086c-472f-8675-5a35a8bdefbd'::uuid, 'pcc',
   'Paper-grade: plausible (nano CaCO3 = nano-PCC, secondary line). Primarily explosives/ammonium nitrate/fertilizer maker. SZSE 002783, Jingmen, 1967.', 'http://www.hbklgroup.cn'),
  ('256947a4-9f3b-42ee-96be-743ad72cbd2a'::uuid, 'pcc',
   'Paper-grade: YES (nano CaCO3 / nano-PCC for paper). Fujian nano-CaCO3 specialist.', 'http://www.nanocaco3.com'),
  ('2c7759a6-3b7a-4312-af03-5d498e2f4544'::uuid, 'both',
   'Paper-grade: YES (nano-PCC + micro-PCC + GCC for papermaking). Guangxi new-materials maker.', 'https://www.huananm.com'),
  ('7be68e77-1c7c-4dc3-afd7-c92df46b3481'::uuid, 'gcc',
   'Paper-grade: YES (ultrafine GCC for paper/coatings). Yangzhou, Jiangsu; founded 1997; NEEQ 834008.', 'http://www.yzqunxin.com'),
  ('6e2eddb4-511a-454f-8f6b-d2e2533f933a'::uuid, 'both',
   'Paper-grade: among uses. GCC+PCC+nano CaCO3+masterbatch; ~600k t/y; Lianzhou, Guangdong; founded 1993.', 'https://www.gdcaco3.com')
) as d(party_id, mc, note, src)
where f.party_id = d.party_id
  and f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and (f.notes is null or f.notes not like '%[homepage 2026-06-20]%');

-- 3) INSERT fallback (only if profile missing)
insert into app.filler_supplier_profile (id, party_id, organization_id, mineral_class, notes, industry_source, created_at, updated_at)
select gen_random_uuid(), d.party_id, 'b25de8f2-1020-482f-9012-183f63883169', d.mc,
       '[homepage 2026-06-20] ' || d.note, d.src, now(), now()
from (values
  ('7d7a6790-086c-472f-8675-5a35a8bdefbd'::uuid, 'pcc',  'Paper-grade: plausible. Nano-PCC secondary; explosives/fertilizer maker (SZSE 002783).', 'http://www.hbklgroup.cn'),
  ('256947a4-9f3b-42ee-96be-743ad72cbd2a'::uuid, 'pcc',  'Paper-grade: YES. Nano-PCC for paper (Fujian).', 'http://www.nanocaco3.com'),
  ('2c7759a6-3b7a-4312-af03-5d498e2f4544'::uuid, 'both', 'Paper-grade: YES. nano/micro-PCC + GCC for papermaking.', 'https://www.huananm.com'),
  ('7be68e77-1c7c-4dc3-afd7-c92df46b3481'::uuid, 'gcc',  'Paper-grade: YES. Ultrafine GCC; 1997; NEEQ 834008.', 'http://www.yzqunxin.com'),
  ('6e2eddb4-511a-454f-8f6b-d2e2533f933a'::uuid, 'both', 'Paper-grade: among uses. GCC+PCC+nano+masterbatch ~600k t/y.', 'https://www.gdcaco3.com')
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
  '7d7a6790-086c-472f-8675-5a35a8bdefbd','256947a4-9f3b-42ee-96be-743ad72cbd2a',
  '2c7759a6-3b7a-4312-af03-5d498e2f4544','7be68e77-1c7c-4dc3-afd7-c92df46b3481',
  '6e2eddb4-511a-454f-8f6b-d2e2533f933a'
)
order by p.party_name;
