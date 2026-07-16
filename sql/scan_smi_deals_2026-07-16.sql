-- ============================================================
-- scan_smi_deals_2026-07-16.sql
--
-- WHY THIS IS NOT THE MERGE FILE YET.
--
-- Blocks 1 and 2 of scan_us_smi_mti_structure came back and the picture is worse
-- than a tidiness problem:
--
--   party                            source                  ev  cont deal comm engag
--   Specialty Minerals (HQ)          industry.v11_4          A     3    1   36    27
--   Minerals Technologies Inc.       filler_gap_2026Q3       C     0    1    0     0
--   Specialty Minerals (USA - Reg HQ) industry.v11_4         B     0    1    0     0
--   Specialty Minerals Inc.          filler_gap_2026Q3       C     0    1    0     0
--
-- FOUR DEALS. Two legal entities. And three of those deals hang off rows with
-- ZERO communications and ZERO engagements - no history, no contacts, nothing.
-- Only 9f161ff5 has a real relationship behind it: 36 communications and 27
-- engagements.
--
-- So this is not cosmetic. Any pipeline report counting SMI deals is counting
-- FOUR where there is one relationship. The duplicates did not merely clutter
-- the roster, they SPLIT THE PIPELINE.
--
-- Note also the provenance split - the base roster (industry.v11_4) already had
-- HQ and Regional HQ. filler_gap_2026Q3 then added Minerals Technologies Inc.
-- and Specialty Minerals Inc. on top. Same shape as the Omya Korea and Taekyung
-- duplicates: a gap file inserting over a base roster it could not see.
--
-- I am NOT writing the merge until these four deals are visible. Re-pointing or
-- deleting a deal blind is how a pipeline number silently changes and nobody
-- can say why.
--
-- READ-ONLY. Run each block SEPARATELY.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 1) THE FOUR DEALS, FULL ROWS ----------
-- select * deliberately - I do not know the app.deals schema and guessing column
-- names is exactly what produced the 42703 error on app.contacts earlier today.
select d.*
from app.deals d
where d.party_id in ('5ba57cb3-a5bb-4fd1-8750-342eb2cc25f1'::uuid,
                     'cd3dbf9e-bb61-4fda-81aa-9d914a5a5658'::uuid,
                     '9f161ff5-c369-4ca2-8a22-46a1ec40fd0d'::uuid,
                     'fa423be1-6482-4147-beae-179d118f48d9'::uuid);


-- ---------- 2) IS THIS AN SMI-ONLY PROBLEM, OR EVERYWHERE ----------
-- Parties that carry a deal but have no communications and no contacts. A deal
-- against a party nobody has ever spoken to is either a placeholder or an
-- artefact of a duplicate row.
select p.id, p.party_name, p.party_type_id, p.source,
       (select count(*) from app.deals dd          where dd.party_id = p.id) as deals,
       (select count(*) from app.communications cc where cc.party_id = p.id) as comms,
       (select count(*) from app.contacts ct       where ct.party_id = p.id and ct.deleted_at is null) as contacts
from app.parties p
where p.deleted_at is null
  and exists (select 1 from app.deals dd where dd.party_id = p.id)
  and not exists (select 1 from app.communications cc where cc.party_id = p.id)
  and not exists (select 1 from app.contacts ct where ct.party_id = p.id and ct.deleted_at is null)
order by p.party_type_id, p.party_name;


-- ---------- 3) EVERY filler_gap_2026Q3 ROW SITTING ON A BASE-ROSTER DOMAIN ----------
-- The general shape of the bug. filler_gap_2026Q3 added Specialty Minerals Inc.
-- next to the existing Specialty Minerals (HQ) because the NOT EXISTS guard
-- matched exact party_name. Omya Korea and both Taekyung rows were the same
-- mistake from my own seed. This finds the rest of the family.
select lower(regexp_replace(regexp_replace(coalesce(p.website,''), '^https?://', ''), '/.*$', '')) as host,
       coalesce(p.country_code,'??') as cc,
       count(*) as rows,
       string_agg(p.party_name || ' <' || coalesce(p.source,'null') || '>', E'\n   ' order by p.source nulls first) as rows_by_source
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and coalesce(p.website,'') <> ''
group by 1, 2
having count(*) > 1
   and count(*) filter (where p.source like 'filler_gap%') > 0
   and count(*) filter (where p.source is null or p.source not like 'filler_gap%') > 0
order by 1, 2;


-- ---------- 4) WHAT 9f161ff5 ACTUALLY HAS - the relationship worth protecting ----------
select 'communications' as kind, count(*) as n,
       min(created_at)::date as first, max(created_at)::date as last
from app.communications where party_id = '9f161ff5-c369-4ca2-8a22-46a1ec40fd0d'::uuid
union all
select 'engagements', count(*), min(created_at)::date, max(created_at)::date
from app.engagements where party_id = '9f161ff5-c369-4ca2-8a22-46a1ec40fd0d'::uuid;
-- 36 communications and 27 engagements is a live relationship with the exact
-- company FCC has to displace. Whatever the merge does, this row survives.


-- ---------- 5) THE SUPPLY LINK ON 9f161ff5 ----------
-- SMI HQ has 1 party_supply_links row. Which mill is SMI supplying in this DB
-- and is it one of the 13 satellite plants already recorded?
select s.*, m.party_name as mill_name, m.country_code as mill_country
from app.party_supply_links s
left join app.parties m on m.id = s.mill_party_id
where s.filler_party_id = '9f161ff5-c369-4ca2-8a22-46a1ec40fd0d'::uuid;
