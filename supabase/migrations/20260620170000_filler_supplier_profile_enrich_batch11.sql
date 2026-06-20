-- 20260620170000_filler_supplier_profile_enrich_batch11.sql
-- Filler-supplier ENRICHMENT - BATCH 11 (global major families). UTF-8.
-- Fills parties.intro_ko / intro_en for the multinational CaCO3 families by name
-- pattern (parent-company summary applied to every country unit). Idempotent:
-- only rows where intro_ko IS NULL are touched. mineral_class already correct
-- for these families (both/pcc) and is NOT modified. Rich per-unit notes preserved.

-- Omya (Switzerland; world's #1 GCC)
update app.parties set intro_ko =
  '1884년 스위스에서 설립된 세계 최대 중질탄산칼슘(GCC) 생산사이자 특수광물 글로벌 기업. GCC·PCC를 제지(충전제·코팅안료)·플라스틱·도료·식품 등에 공급하며 50여 개국에 거점을 둔 제지용 탄산칼슘 글로벌 1위급.',
  intro_en =
  'Founded 1884 in Switzerland, the world''s leading producer of ground calcium carbonate (GCC) and a global industrial-minerals company. Supplies GCC and PCC for paper (filler and coating pigment), plastics, paints and food across 50+ countries; a top global paper-CaCO3 supplier.',
  updated_at = now()
where party_name ilike 'Omya%' and party_type_id = 3
  and organization_id = 'b25de8f2-1020-482f-9012-183f63883169' and intro_ko is null;

-- Specialty Minerals / Minerals Technologies (USA; world's #1 PCC, on-site satellite pioneer)
update app.parties set intro_ko =
  '미국 Minerals Technologies(NYSE: MTX) 산하 Specialty Minerals(SMI). 1986년 제지공장 현장(on-site/satellite) PCC를 세계 최초로 상용화한 PCC 글로벌 리더로, 장기계약 기반 위성 PCC 플랜트를 다수 운영하는 제지용 PCC 세계 1위.',
  intro_en =
  'Specialty Minerals (SMI), a unit of Minerals Technologies Inc. (NYSE: MTX, HQ New York). The world leader in PCC, which pioneered on-site/satellite PCC plants at paper mills in 1986 and operates many under long-term contracts; the #1 global paper-PCC supplier.',
  updated_at = now()
where party_name ilike 'Specialty Minerals%' and party_type_id = 3
  and organization_id = 'b25de8f2-1020-482f-9012-183f63883169' and intro_ko is null;

-- Imerys (France; mineral-based specialty solutions)
update app.parties set intro_ko =
  '프랑스에 본사를 둔 광물 기반 특수솔루션 글로벌 리더(상장). 제지용으로 GCC·PCC·카올린(코팅안료·충전제)을 공급하며 전 세계에 생산거점을 보유.',
  intro_en =
  'A France-headquartered global leader in mineral-based specialty solutions (listed). For paper it supplies GCC, PCC and kaolin (coating pigments and fillers), with production sites worldwide.',
  updated_at = now()
where party_name ilike 'Imerys%' and party_type_id = 3
  and organization_id = 'b25de8f2-1020-482f-9012-183f63883169' and intro_ko is null;

-- Carmeuse (Belgium; global lime & limestone, family-owned)
update app.parties set intro_ko =
  '벨기에에 본사를 둔 세계적 석회·석회석 생산 기업(가족경영). 생석회·소석회·석회석과 PCC 가치사슬을 보유하며 유럽·북미 등에서 제지용 PCC/충전제를 공급.',
  intro_en =
  'A Belgium-headquartered, family-owned global lime and limestone producer with operations across Europe and North America and a PCC value chain serving paper.',
  updated_at = now()
where party_name ilike 'Carmeuse%' and party_type_id = 3
  and organization_id = 'b25de8f2-1020-482f-9012-183f63883169' and intro_ko is null;

-- Sibelco (Belgium; global material solutions)
update app.parties set intro_ko =
  '벨기에에 본사를 둔 글로벌 소재솔루션 기업. 실리카·점토·장석·탄산칼슘 등 산업광물을 채굴·가공해 제지를 포함한 다양한 산업에 공급.',
  intro_en =
  'A Belgium-headquartered global material-solutions company mining and processing industrial minerals -- silica, clays, feldspar and calcium carbonate -- for many industries including paper.',
  updated_at = now()
where party_name ilike 'Sibelco%' and party_type_id = 3
  and organization_id = 'b25de8f2-1020-482f-9012-183f63883169' and intro_ko is null;

-- verify (rows per family + how many now have intro)
select case
         when party_name ilike 'Omya%' then 'Omya'
         when party_name ilike 'Specialty Minerals%' then 'SMI/MTI'
         when party_name ilike 'Imerys%' then 'Imerys'
         when party_name ilike 'Carmeuse%' then 'Carmeuse'
         when party_name ilike 'Sibelco%' then 'Sibelco'
       end as family,
       count(*) as total_rows,
       count(intro_ko) as with_intro
from app.parties
where party_type_id = 3
  and organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and (party_name ilike 'Omya%' or party_name ilike 'Specialty Minerals%'
       or party_name ilike 'Imerys%' or party_name ilike 'Carmeuse%'
       or party_name ilike 'Sibelco%')
group by 1
order by 1;
