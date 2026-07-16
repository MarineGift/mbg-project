-- ============================================================
-- scan_filler_name_dupes_2026-07-16.sql
--
-- WHY THIS EXISTS: the domain scan in
-- scan_filler_paper_grade_reverify_2026-07-16.sql (block 6) caught the Taekyung
-- BK dupe on the spot, but MISSED the Taekyung Industrial dupe - because the
-- stored domain is taekyungind.co.kr and the seed used taekyung.co.kr.
-- Different host, no group, no flag. And a row with a NULL website is invisible
-- to that scan entirely, which is why GMC could not be checked at all.
--
-- So host grouping is necessary but NOT sufficient. This adds the other two
-- nets - normalized name, and a coarse prefix cluster. Run all three before any
-- future INSERT into filler_supplier.
--
-- READ-ONLY. Run each block separately.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 1) NORMALIZED NAME COLLISION ----------
-- Strips bracketed text, then legal-form suffixes, then all non-alphanumerics.
--   'Taekyung BK Co. (태경비케이, ex-Baekkwang Materials)' -> taekyungbk
--   'Taekyung BK Co., Ltd.'                              -> taekyungbk   MATCH
-- This is the net that would have caught the dupe the host scan missed.
select
  coalesce(p.country_code,'??') as cc,
  regexp_replace(
    regexp_replace(
      regexp_replace(lower(p.party_name), '\(.*?\)', '', 'g'),
      '\y(co|ltd|inc|corp|corporation|company|kaisha|kogyo|sdn|bhd|gmbh|ag|sa|plc|llc|pte|bv|nv|oy|ab|as)\y', '', 'g'),
    '[^a-z0-9]', '', 'g') as norm_name,
  count(*) as rows,
  string_agg(p.party_name || ' [' || coalesce(p.source,'-') || ']', ' | ' order by p.party_name) as names,
  string_agg(p.id::text, ' | ' order by p.party_name) as ids
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null
group by 1, 2
having count(*) > 1
order by 1, 2;


-- ---------- 2) COARSE PREFIX CLUSTER - review by eye ----------
-- First 8 characters of the normalized name, per country. Deliberately loose.
-- It surfaces near-misses the exact-normalized net cannot see, e.g.
--   'Taekyung Industrial' -> taekyungindustrial
--   'Taekyung Industry Co., Ltd.' -> taekyungindustry
-- which differ, but share the prefix taekyung. Expect false positives - the
-- point is a short human review list, not an automated decision.
select
  coalesce(p.country_code,'??') as cc,
  left(regexp_replace(lower(p.party_name), '[^a-z0-9]', '', 'g'), 8) as prefix8,
  count(*) as rows,
  string_agg(p.party_name || ' [' || coalesce(p.website,'no-website') || ']', ' | ' order by p.party_name) as names
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null
group by 1, 2
having count(*) > 1
order by count(*) desc, 1, 2;


-- ---------- 3) INVISIBLE TO THE DOMAIN SCAN ----------
-- Rows with no website cannot be host-grouped at all. GMC sits here - it was
-- inserted with a NULL website, so nothing has ever checked it for a dupe.
select p.id, p.party_name, p.country_code, p.city, p.source,
       (p.intro_ko is not null) as has_ko,
       f.evidence_level, f.supply_model
from app.parties p
left join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
where p.party_type_id = 3 and p.deleted_at is null
  and coalesce(p.website,'') = ''
order by p.country_code nulls last, p.party_name;


-- ---------- 4) EVERYTHING FROM THE KR SEED - what actually survived ----------
select p.id, p.party_name, p.country_code, p.city, p.website, p.source,
       f.supply_model, f.evidence_level
from app.parties p
left join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
where p.party_type_id = 3 and p.deleted_at is null
  and p.source = 'filler_gap_kr_2026Q3'
order by p.party_name;
-- After fix_omya_korea_dupe and fix_taekyung_dupes have both run, this should
-- return exactly 1 row - GMC Co., Ltd. (Korea). Anything else is a leftover.


-- ---------- 5) FULL KR PICTURE - the audit I should have run on day one ----------
select p.id, p.party_name, p.country_code, p.city, p.website, p.source,
       f.mineral_class, f.supply_model, f.evidence_level, f.market_role,
       (p.intro_ko is not null) as has_ko,
       (select count(*) from app.contacts c where c.party_id = p.id and c.deleted_at is null) as contacts
from app.parties p
left join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
where p.party_type_id = 3 and p.deleted_at is null
  and (p.country_code = 'KR' or p.website like '%.kr%' or p.party_name ~ '[가-힣]')
order by p.party_name;
