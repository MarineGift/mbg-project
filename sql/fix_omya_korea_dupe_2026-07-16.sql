-- ============================================================
-- fix_omya_korea_dupe_2026-07-16.sql
--
-- WHY: seed_filler_suppliers_kr_2026-07-16.sql claimed "KR filler suppliers = 0"
-- and inserted 'Omya Korea Inc.'. That claim was WRONG. A KR Omya row already
-- existed as 'Omya (Korea)' (id fac3df6e-875a-4cc3-97d4-fbb0ca10dd7f, see
-- 20260620220000_filler_parties_website_families_batch14.sql). The earlier audit
-- grepped the repo for the literal ,'KR' pattern, but the base filler roster was
-- never in the repo, so the grep could not see it. The NOT EXISTS guard matched
-- on exact party_name, so 'Omya Korea Inc.' did not collide with 'Omya (Korea)'.
--
-- RESULT: a duplicate Omya row (only if the seed was actually run in Supabase).
-- The other 3 rows (Taekyung Industry / Taekyung BK / GMC) are genuinely new
-- and are NOT touched here.
--
-- THIS FILE:
--   1. Moves the verified research onto the pre-existing 'Omya (Korea)' row
--      (country_code, region, city, intros) - this also answers the open
--      "5-plant claim verification needed" flag left in batch14.
--   2. Deletes the duplicate 'Omya Korea Inc.' row and its profile.
--
-- SAFE IF THE SEED WAS NEVER RUN: every statement is a no-op in that case.
-- IDEMPOTENT. No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 1) Enrich the REAL row: Omya (Korea) ----------
update app.parties p
set country_code = 'KR',
    region       = coalesce(p.region, '서울특별시'),
    city         = coalesce(p.city, '서울'),
    updated_at   = now()
where p.id = 'fac3df6e-875a-4cc3-97d4-fbb0ca10dd7f'::uuid
  and p.party_type_id = 3
  and p.deleted_at is null
  and (p.country_code is distinct from 'KR' or p.city is null);

update app.parties p
set intro_ko = '스위스 Omya의 한국 법인으로 1990년부터 가동 중이다. 서울 마포에 본사를 두고 군산·안동·함백·온산·제천 5개 공장(건식 3, 슬러리 2)에서 연 120만 톤 이상의 탄산칼슘을 생산하며 자체 광산 5곳을 보유한다. 국내 최대 제지용 필러 공급사로 FCC 로열티 라이선싱의 한국 시장 1순위 타깃이다.',
    intro_en = 'The Korean arm of Omya of Switzerland, running since 1990. HQ in Mapo, Seoul, with five plants at Gunsan, Andong, Hambaek, Onsan and Jecheon - three dry and two slurry lines above 1.2 million tons of calcium carbonate a year, backed by five owned mines. The largest paper-filler supplier in Korea and the top FCC royalty licensing target in this market.',
    updated_at = now()
where p.id = 'fac3df6e-875a-4cc3-97d4-fbb0ca10dd7f'::uuid
  and p.party_type_id = 3
  and p.deleted_at is null
  and p.intro_ko is null;

-- 1b) Resolve the open verification flag on the profile notes.
update app.filler_supplier_profile f
set notes = coalesce(f.notes, '') || E'\n[kr-verify 2026-07-16] 5-plant claim CONFIRMED from omya.com KR pages - Gunsan, Andong, Hambaek, Onsan, Jecheon (3 dry + 2 slurry), combined capacity above 1.2M t/yr, 5 owned mines, operating since 1990. NOTE the discrepancy - the earlier Yeongwol 200k t/yr GCC line is not named on the current plant list, so Yeongwol may be a mine or a renamed/closed site. Needs one more check.',
    updated_at = now()
where f.party_id = 'fac3df6e-875a-4cc3-97d4-fbb0ca10dd7f'::uuid
  and f.deleted_at is null
  and coalesce(f.notes, '') not like '%[kr-verify 2026-07-16]%';

-- ---------- 2) Remove the duplicate row ----------
-- 2a) profile first (FK child)
delete from app.filler_supplier_profile f
using app.parties p
where f.party_id = p.id
  and p.party_name = 'Omya Korea Inc.'
  and p.party_type_id = 3
  and p.source = 'filler_gap_kr_2026Q3';

-- 2b) the party itself - guarded so nothing with real activity is ever removed
delete from app.parties p
where p.party_name = 'Omya Korea Inc.'
  and p.party_type_id = 3
  and p.source = 'filler_gap_kr_2026Q3'
  and not exists (select 1 from app.contacts       c where c.party_id = p.id)
  and not exists (select 1 from app.deals          d where d.party_id = p.id)
  and not exists (select 1 from app.communications m where m.party_id = p.id)
  and not exists (select 1 from app.deal_parties  dp where dp.party_id = p.id);

-- ---------- 3) VERIFY (run separately) ----------
-- select id, party_name, country_code, city, source, (intro_ko is not null) as has_ko
-- from app.parties
-- where party_type_id = 3 and country_code = 'KR' and deleted_at is null
-- order by party_name;
-- EXPECT exactly 4 rows:
--   GMC Co., Ltd. (Korea)        source = filler_gap_kr_2026Q3
--   Omya (Korea)                 source = (original)            <- enriched, NOT duplicated
--   Taekyung BK Co., Ltd.        source = filler_gap_kr_2026Q3
--   Taekyung Industry Co., Ltd.  source = filler_gap_kr_2026Q3
-- If 'Omya Korea Inc.' still appears, the delete was blocked by a guard - check
-- for attached contacts/deals before removing by hand.

-- select party_name from app.parties
-- where party_type_id = 3 and deleted_at is null and party_name ilike '%omya%korea%';
-- EXPECT 1 row.
