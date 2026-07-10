-- ============================================================
-- backfill_market_size_verified_2026-07-10.sql
-- Updates market-size answers to the figures verified by web
-- search on 2026-07-10 (see docs/handoff market verification).
--
-- Key corrections vs the old deck:
--   * TAM is the royalty-bearing filler tonnage, NOT finished
--     paper/tissue product markets (the old $200B was product
--     markets misused as filler TAM)
--   * PCC volume 10-25M tons/yr (old deck said 51-63M)
--   * GCC 2030 ~$51B (GVR), PCC 2024 ~$5.4B (Precedence)
--   * Royalty pool = paper CaCO3 filler 30-48M tons x $350/ton
--                  = $10.5-16.8B/yr
--
-- Supabase SQL Editor safe: no do-blocks, no temp tables,
-- no semicolons or SQL keywords inside string literals.
-- ============================================================

-- ------------------------------------------------------------
-- 1. market_size_musd: reframe as the royalty pool with basis.
--    Old value "15000" had no stated basis - replace with the
--    verified royalty-pool figure and its derivation.
-- ------------------------------------------------------------
update app.answer_library al
set body_en    = 'Our royalty-bearing market is the calcium-carbonate filler consumed by paper - roughly 30 to 48 million tons per year - which at 350 USD per ton of royalty is a 10.5 to 16.8B USD annual pool. Reference markets - GCC about 51B USD by 2030, PCC about 5.4B USD in 2024 - size the broader material industry we plug into.',
    body_ko    = '당사의 로열티 대상 시장은 제지 산업이 소비하는 탄산칼슘 필러로, 연 약 3,000만~4,800만 톤 규모이며 톤당 350달러 로열티 기준 연 105억~168억 달러의 로열티 풀에 해당합니다. 참고로 GCC 시장은 2030년 약 510억 달러, PCC는 2024년 약 54억 달러 규모로, 당사가 결합하는 소재 산업의 전체 크기를 보여줍니다.',
    updated_at = now()
where al.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and al.answer_key = 'market_size_musd';


-- ------------------------------------------------------------
-- 2. Seed reusable market_context key (verified figures block
--    for deck notes, form long-answers, diligence Q&A)
-- ------------------------------------------------------------
insert into app.answer_library
  (organization_id, answer_key, title, body_en, body_ko,
   disclosure_level, variant, tags, created_by)
select
  'b25de8f2-1020-482f-9012-183f63883169'::uuid,
  'market_context',
  'Verified market figures (2026-07-10)',
  'Global paper production is about 400 million tons per year (FAO 2023, packaging 55 pct). Paper consumes roughly 30 to 48 million tons per year of calcium-carbonate filler and coating. At 350 USD per ton of royalty that is a 10.5 to 16.8B USD annual royalty pool. GCC is the larger material by volume - roughly 5x PCC - and is projected near 51B USD by 2030 (Grand View Research), while PCC was about 5.4B USD in 2024 (Precedence Research). Our confirmed track of 9,000 tons plus roughly 10,000 in progress is about 0.05 pct penetration - at 1 pct that is 105 to 168M USD per year in royalty.',
  '세계 제지 생산은 연 약 4억 톤이며(FAO 2023, 패키징 55퍼센트), 제지 산업은 연 약 3,000만~4,800만 톤의 탄산칼슘 필러·코팅을 소비합니다. 톤당 350달러 로열티 기준 연 105억~168억 달러의 로열티 풀입니다. GCC는 볼륨 기준 더 큰 소재로 PCC의 약 5배이며 2030년 약 510억 달러로 전망되고(Grand View Research), PCC는 2024년 약 54억 달러였습니다(Precedence Research). 당사의 확정 9,000톤 및 약 10,000톤 진행은 약 0.05퍼센트 침투이며, 1퍼센트면 연 1억 5백만~1억 6,800만 달러의 로열티에 해당합니다.',
  'public',
  'medium',
  array['market','tam','verified','royalty'],
  (select created_by from app.answer_library
    where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    order by created_at limit 1)
where not exists (
  select 1 from app.answer_library
  where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    and answer_key = 'market_context'
    and variant = 'medium'
);

update app.answer_library
set body_en    = 'Global paper production is about 400 million tons per year (FAO 2023, packaging 55 pct). Paper consumes roughly 30 to 48 million tons per year of calcium-carbonate filler and coating. At 350 USD per ton of royalty that is a 10.5 to 16.8B USD annual royalty pool. GCC is the larger material by volume - roughly 5x PCC - and is projected near 51B USD by 2030 (Grand View Research), while PCC was about 5.4B USD in 2024 (Precedence Research). Our confirmed track of 9,000 tons plus roughly 10,000 in progress is about 0.05 pct penetration - at 1 pct that is 105 to 168M USD per year in royalty.',
    body_ko    = '세계 제지 생산은 연 약 4억 톤이며(FAO 2023, 패키징 55퍼센트), 제지 산업은 연 약 3,000만~4,800만 톤의 탄산칼슘 필러·코팅을 소비합니다. 톤당 350달러 로열티 기준 연 105억~168억 달러의 로열티 풀입니다. GCC는 볼륨 기준 PCC의 약 5배이며 2030년 약 510억 달러로 전망되고(Grand View Research), PCC는 2024년 약 54억 달러였습니다(Precedence Research). 당사의 확정 9,000톤 및 약 10,000톤 진행은 약 0.05퍼센트 침투이며, 1퍼센트면 연 1억 5백만~1억 6,800만 달러의 로열티에 해당합니다.',
    updated_at = now()
where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and answer_key = 'market_context'
  and variant = 'medium';


-- ------------------------------------------------------------
-- 3. Resync any form answers bound to market_size_musd
-- ------------------------------------------------------------
update app.application_field_answers fa
set final_text = al.body_en,
    updated_at = now()
from app.application_form_fields ff,
     app.answer_library al
where ff.id = fa.field_id
  and al.id = fa.answer_id
  and al.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and al.answer_key = 'market_size_musd'
  and al.body_en is not null
  and fa.final_text is distinct from al.body_en;


-- ------------------------------------------------------------
-- VERIFY: the two market keys with heads
-- ------------------------------------------------------------
select answer_key, variant,
       length(body_en) as en_chars,
       left(body_en, 55) as en_head
from app.answer_library
where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and answer_key in ('market_size_musd','market_context')
order by answer_key, variant;
