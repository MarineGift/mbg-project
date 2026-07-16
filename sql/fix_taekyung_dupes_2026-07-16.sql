-- ============================================================
-- fix_taekyung_dupes_2026-07-16.sql
--
-- MY SECOND AND THIRD DUPE. The domain scan caught one immediately.
--
--   KEEP  3d121300-0eab-49b9-baf3-89f592baca78  Taekyung BK (ex-Baekkwang Materials)
--   DROP  'Taekyung BK Co., Ltd.'               source = filler_gap_kr_2026Q3   (mine)
--
--   KEEP  313a4d86-0055-49a1-aca0-6a760ee0b7e2  Taekyung Industrial
--   DROP  'Taekyung Industry Co., Ltd.'         source = filler_gap_kr_2026Q3   (mine)
--
-- Both keepers were already in the repo, in
-- 20260620060000_app_parties_website_backfill_batch1.sql lines 21-22. The KR
-- audit that produced seed_filler_suppliers_kr_2026-07-16.sql grepped only for
-- the literal ,'KR' value-tuple pattern and never looked at .co.kr domains, so
-- it missed both. The claim "KR filler suppliers = 0" was wrong three times over
-- - Omya (Korea), Taekyung BK and Taekyung Industrial all existed.
--
-- WHY THE DOMAIN SCAN ONLY CAUGHT ONE: Taekyung BK collided on
-- www.taekyungbk.co.kr. Taekyung Industrial did not, because the stored domain
-- is taekyungind.co.kr while the seed used taekyung.co.kr. Different host, no
-- group, no flag. Host grouping is necessary but not sufficient.
--
-- The Taekyung Industry merge is SELF-GUARDING - if 313a4d86 turns out not to be
-- a filler_supplier row, every statement touching it is a no-op.
--
-- IDEMPOTENT. Safe to run twice. Safe if the seed was never run.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 0) PRE-FLIGHT (run first, separately) ----------
-- select id, party_name, party_type_id, country_code, city, website, source,
--        (intro_ko is not null) as has_ko
-- from app.parties
-- where party_type_id = 3 and deleted_at is null and party_name ilike '%taekyung%'
-- order by party_name;
-- EXPECT 4 rows before this file runs, 2 rows after.
-- If 313a4d86 is NOT party_type_id = 3, tell me before running block 3.


-- ---------- 1) TAEKYUNG BK - carry the research onto the keeper ----------
update app.parties k
set country_code = coalesce(k.country_code, d.country_code),
    region       = coalesce(k.region, d.region),
    city         = coalesce(k.city, d.city),
    intro_ko     = coalesce(k.intro_ko, d.intro_ko),
    intro_en     = coalesce(k.intro_en, d.intro_en),
    notes        = coalesce(k.notes, d.notes),
    updated_at   = now()
from app.parties d
where k.id = '3d121300-0eab-49b9-baf3-89f592baca78'::uuid
  and k.party_type_id = 3 and k.deleted_at is null
  and d.party_name = 'Taekyung BK Co., Ltd.'
  and d.party_type_id = 3 and d.source = 'filler_gap_kr_2026Q3' and d.deleted_at is null;

-- 1b) keeper has no profile row -> create one carrying the satellite evidence
insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   onsite_pcc_evidence, mineral_class, industry_source, notes, extra_data, created_at, updated_at)
select '3d121300-0eab-49b9-baf3-89f592baca78'::uuid,
       'b25de8f2-1020-482f-9012-183f63883169'::uuid,
       'PCC/GCC producer', 'KR lime leader running an on-site PCC satellite',
       'satellite', 'B',
       'On-site PCC plant at the Hansol Paper Janghang mill. NOTE - this was ALREADY recorded on the mill side in 20260620210000_paper_mill_website_intro_batch15.sql, in the Janghang plant intro. It was not a new finding.',
       'CaCO3 (PCC/GCC)', 'industry-research',
       '[kr-dupe-merge 2026-07-16] Profile created during the Taekyung BK dupe merge. Formerly Baekkwang Mineral Products. Danyang plants 1 and 2, about 1.28M t/yr quicklime, Korea largest lime producer. Absorbed Korea Fimatec (Sumitomo Osaka Cement and Fimatec JV) 2000-07-01 for ultrafine GCC. Danyang PCC plant since 2002 at 50 kt/yr.',
       '{"paper_grade": {"claim": "yes", "source_url": "http://www.taekyungbk.co.kr/pc/business/intro", "source_type": "marketing", "checked_at": "2026-07-16"}}'::jsonb,
       now(), now()
where exists (select 1 from app.parties p where p.id = '3d121300-0eab-49b9-baf3-89f592baca78'::uuid
                and p.party_type_id = 3 and p.deleted_at is null)
  and not exists (select 1 from app.filler_supplier_profile f
                  where f.party_id = '3d121300-0eab-49b9-baf3-89f592baca78'::uuid);

-- 1c) keeper already had a profile -> append, never overwrite
update app.filler_supplier_profile f
set notes = coalesce(f.notes, '') || E'\n[kr-dupe-merge 2026-07-16] Merged from the duplicate row Taekyung BK Co., Ltd. Formerly Baekkwang Mineral Products. Danyang plants 1 and 2, about 1.28M t/yr quicklime, Korea largest lime producer, plus PCC. Absorbed Korea Fimatec 2000-07-01 for ultrafine GCC. SATELLITE - on-site PCC plant at the Hansol Paper Janghang mill, which was already recorded on the mill side in batch15. Consider supply_model satellite / evidence_level B if not already set.',
    updated_at = now()
where f.party_id = '3d121300-0eab-49b9-baf3-89f592baca78'::uuid
  and f.deleted_at is null
  and coalesce(f.notes, '') not like '%[kr-dupe-merge 2026-07-16]%';


-- ---------- 2) TAEKYUNG BK - remove the duplicate ----------
delete from app.filler_supplier_profile f
using app.parties p
where f.party_id = p.id
  and p.party_name = 'Taekyung BK Co., Ltd.'
  and p.party_type_id = 3 and p.source = 'filler_gap_kr_2026Q3';

delete from app.parties p
where p.party_name = 'Taekyung BK Co., Ltd.'
  and p.party_type_id = 3 and p.source = 'filler_gap_kr_2026Q3'
  and not exists (select 1 from app.contacts       c where c.party_id = p.id)
  and not exists (select 1 from app.deals          d where d.party_id = p.id)
  and not exists (select 1 from app.communications m where m.party_id = p.id)
  and not exists (select 1 from app.deal_parties  dp where dp.party_id = p.id)
  and not exists (select 1 from app.party_supply_links s where s.filler_party_id = p.id);


-- ---------- 3) TAEKYUNG INDUSTRIAL - same merge, self-guarding ----------
update app.parties k
set country_code = coalesce(k.country_code, d.country_code),
    region       = coalesce(k.region, d.region),
    city         = coalesce(k.city, d.city),
    intro_ko     = coalesce(k.intro_ko, d.intro_ko),
    intro_en     = coalesce(k.intro_en, d.intro_en),
    notes        = coalesce(k.notes, d.notes),
    updated_at   = now()
from app.parties d
where k.id = '313a4d86-0055-49a1-aca0-6a760ee0b7e2'::uuid
  and k.party_type_id = 3 and k.deleted_at is null
  and d.party_name = 'Taekyung Industry Co., Ltd.'
  and d.party_type_id = 3 and d.source = 'filler_gap_kr_2026Q3' and d.deleted_at is null;

update app.filler_supplier_profile f
set notes = coalesce(f.notes, '') || E'\n[kr-dupe-merge 2026-07-16] Merged from the duplicate row Taekyung Industry Co., Ltd. KOSPI-listed Taekyung Group flagship, founded 1982-02-15. Ferroalloy plus a paper-materials division making GCC and PCC. Ultrafine wet GCC slurries TK-45F/50F60, TK-65F/75F60 and OTM-55C sold as filler and coating pigment to art paper, white board, newsprint and containerboard mills. It already markets high-fill slurries positioned on pulp reduction, which overlaps the FCC pitch. DOMAIN CHECK - the stored website is taekyungind.co.kr but the live site is taekyung.co.kr. Verify and update.',
    updated_at = now()
where f.party_id = '313a4d86-0055-49a1-aca0-6a760ee0b7e2'::uuid
  and f.deleted_at is null
  and coalesce(f.notes, '') not like '%[kr-dupe-merge 2026-07-16]%';

delete from app.filler_supplier_profile f
using app.parties p
where f.party_id = p.id
  and p.party_name = 'Taekyung Industry Co., Ltd.'
  and p.party_type_id = 3 and p.source = 'filler_gap_kr_2026Q3'
  and exists (select 1 from app.parties k where k.id = '313a4d86-0055-49a1-aca0-6a760ee0b7e2'::uuid
                and k.party_type_id = 3 and k.deleted_at is null);

delete from app.parties p
where p.party_name = 'Taekyung Industry Co., Ltd.'
  and p.party_type_id = 3 and p.source = 'filler_gap_kr_2026Q3'
  and exists (select 1 from app.parties k where k.id = '313a4d86-0055-49a1-aca0-6a760ee0b7e2'::uuid
                and k.party_type_id = 3 and k.deleted_at is null)
  and not exists (select 1 from app.contacts       c where c.party_id = p.id)
  and not exists (select 1 from app.deals          d where d.party_id = p.id)
  and not exists (select 1 from app.communications m where m.party_id = p.id)
  and not exists (select 1 from app.deal_parties  dp where dp.party_id = p.id)
  and not exists (select 1 from app.party_supply_links s where s.filler_party_id = p.id);


-- ---------- 4) THE ONE GOOD THING - link Hansol Janghang to Taekyung BK ----------
-- batch15 recorded the on-site PCC relationship as prose inside the mill intro.
-- It was never a row. Now both uuids are known, so it can be a real edge.
--   mill   890ae7ee-12ae-4889-be24-c1f2155dbad0  Hansol Paper - Janghang mill
--   filler 3d121300-0eab-49b9-baf3-89f592baca78  Taekyung BK
insert into app.party_supply_links (mill_party_id, filler_party_id, organization_id)
select '890ae7ee-12ae-4889-be24-c1f2155dbad0'::uuid,
       '3d121300-0eab-49b9-baf3-89f592baca78'::uuid,
       'b25de8f2-1020-482f-9012-183f63883169'::uuid
where exists (select 1 from app.parties m where m.id = '890ae7ee-12ae-4889-be24-c1f2155dbad0'::uuid
                and m.party_type_id = 2 and m.deleted_at is null)
  and exists (select 1 from app.parties f where f.id = '3d121300-0eab-49b9-baf3-89f592baca78'::uuid
                and f.party_type_id = 3 and f.deleted_at is null)
  and not exists (select 1 from app.party_supply_links s
                  where s.mill_party_id = '890ae7ee-12ae-4889-be24-c1f2155dbad0'::uuid
                    and s.filler_party_id = '3d121300-0eab-49b9-baf3-89f592baca78'::uuid);
-- If app.party_supply_links has extra NOT NULL columns this will error. That is
-- fine - it is the last statement, everything above has already committed.


-- ---------- 5) VERIFY (run separately) ----------
-- select id, party_name, country_code, city, website, source, (intro_ko is not null) as has_ko
-- from app.parties
-- where party_type_id = 3 and deleted_at is null and party_name ilike '%taekyung%';
-- EXPECT 2 rows - 3d121300 Taekyung BK, 313a4d86 Taekyung Industrial. Both has_ko = true.

-- select count(*) from app.parties
-- where party_type_id = 3 and deleted_at is null and source = 'filler_gap_kr_2026Q3';
-- EXPECT 1 - only GMC Co., Ltd. (Korea) should remain from that seed.
