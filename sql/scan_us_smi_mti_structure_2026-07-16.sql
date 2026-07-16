-- ============================================================
-- scan_us_smi_mti_structure_2026-07-16.sql
--
-- THE PROBLEM, straight off the 2026-07-16 US pipeline export:
-- four company-level rows exist for what is really TWO legal entities.
--
--   5ba57cb3-a5bb-4fd1-8750-342eb2cc25f1  Minerals Technologies Inc.
--        New York  | C | merchant | "Global minerals parent (PCC/GCC)"        | 0 contacts
--   cd3dbf9e-bb61-4fda-81aa-9d914a5a5658  Specialty Minerals Inc.
--        New York  | C | merchant | "Global PCC/GCC merchant supplier"        | 0 contacts
--   9f161ff5-c369-4ca2-8a22-46a1ec40fd0d  Specialty Minerals (HQ)
--        Bethlehem PA | A | On-site satellite PCC plants
--                     | "Leading global satellite PCC operator"               | 3 contacts
--   fa423be1-6482-4147-beae-179d118f48d9  Specialty Minerals (USA - Regional HQ)
--        null      | B | Satellite (long-term 10-year contracts) + merchant
--                     | "Regional HQ (SMI Americas)"                          | 0 contacts
--
-- Minerals Technologies Inc. is the NYSE parent (MTX). Specialty Minerals Inc.
-- is its subsidiary. So a parent row plus an SMI row is legitimate. But
-- 'Specialty Minerals Inc.', 'Specialty Minerals (HQ)' and 'Specialty Minerals
-- (USA - Regional HQ)' are all plausibly the SAME company - carrying THREE
-- different evidence levels (A, B, C) and THREE contradictory supply_models.
--
-- HOW IT HAPPENED - the same failure I made with Omya Korea. A gap file inserted
-- 'Specialty Minerals Inc.' while 'Specialty Minerals (HQ)' already existed,
-- because the NOT EXISTS guard matched on exact party_name and the two strings
-- differ. That file's own header even notes it checked against 'Double A
-- Specialty Minerals' - it checked the wrong neighbour.
--
-- WHY IT MATTERS: SMI is the single most important company in this pipeline -
-- it is the global satellite PCC operator and the direct incumbent FCC has to
-- displace. Its evidence level is currently A, B and C simultaneously, and any
-- ranking query returns whichever row it happens to hit.
--
-- READ-ONLY. Run each block separately. Send block 2 and 3 back.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 1) THE FOUR ROWS SIDE BY SIDE ----------
select p.id, p.party_name, p.city, p.region, p.website, p.source,
       f.evidence_level, f.supply_model, f.market_role, f.mineral_class,
       (p.intro_ko is not null) as has_ko,
       length(coalesce(f.notes,'')) as notes_len
from app.parties p
left join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
where p.id in ('5ba57cb3-a5bb-4fd1-8750-342eb2cc25f1'::uuid,
               'cd3dbf9e-bb61-4fda-81aa-9d914a5a5658'::uuid,
               '9f161ff5-c369-4ca2-8a22-46a1ec40fd0d'::uuid,
               'fa423be1-6482-4147-beae-179d118f48d9'::uuid)
order by p.party_name;


-- ---------- 2) WHAT IS ATTACHED - decides which row can be deleted ----------
-- A row with contacts, deals or supply links cannot simply be dropped.
-- Specialty Minerals (HQ) has 3 contacts, so it is the natural keeper.
select p.id, p.party_name,
       (select count(*) from app.contacts c            where c.party_id = p.id and c.deleted_at is null) as contacts,
       (select count(*) from app.deals d               where d.party_id = p.id) as deals,
       (select count(*) from app.communications m      where m.party_id = p.id) as comms,
       (select count(*) from app.deal_parties dp       where dp.party_id = p.id) as deal_parties,
       (select count(*) from app.party_supply_links s  where s.filler_party_id = p.id) as supply_links,
       (select count(*) from app.engagements e         where e.party_id = p.id) as engagements
from app.parties p
where p.id in ('5ba57cb3-a5bb-4fd1-8750-342eb2cc25f1'::uuid,
               'cd3dbf9e-bb61-4fda-81aa-9d914a5a5658'::uuid,
               '9f161ff5-c369-4ca2-8a22-46a1ec40fd0d'::uuid,
               'fa423be1-6482-4147-beae-179d118f48d9'::uuid)
order by p.party_name;


-- ---------- 3) THE 3 CONTACTS ON Specialty Minerals (HQ) ----------
-- Whoever these are, they are the reason 9f161ff5 should be the keeper.
select c.id, c.full_name, c.title_text, c.department, c.email,
       c.phone_e164, c.is_primary, c.is_decision_maker, c.source
from app.contacts c
where c.party_id = '9f161ff5-c369-4ca2-8a22-46a1ec40fd0d'::uuid
  and c.deleted_at is null
order by c.full_name;


-- ---------- 4) EVERY mineralstech.com ROW, ALL COUNTRIES ----------
-- 86 parties share this domain across 17 country groups. Most are plant rows
-- and legitimate. This separates the company-level rows - the ones that can be
-- duplicates - from the plant rows, which cannot.
select coalesce(p.country_code,'??') as cc,
       count(*) filter (where p.party_name !~ ' - ')  as company_level_rows,
       count(*) filter (where p.party_name ~ ' - ')   as plant_rows,
       string_agg(p.party_name, ' | ' order by p.party_name)
         filter (where p.party_name !~ ' - ') as company_names
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null
  and p.website like '%mineralstech.com%'
group by 1
having count(*) filter (where p.party_name !~ ' - ') > 1
order by 1;
-- Any country with more than one company-level row is a candidate for the same
-- problem the US has. Check CN, IN and the rest.


-- ---------- 5) THE GENERAL VERSION - which gap file inserted over what ----------
-- Rows whose source marks them as gap-file inserts, sitting on a domain that
-- already had a row from an older source. This is the Omya Korea shape, and
-- the Specialty Minerals Inc. shape, expressed as a query.
select lower(regexp_replace(regexp_replace(coalesce(p.website,''), '^https?://', ''), '/.*$', '')) as host,
       coalesce(p.country_code,'??') as cc,
       string_agg(p.party_name || ' <' || coalesce(p.source,'null') || '>', ' | ' order by p.source nulls first) as rows_by_source
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and coalesce(p.website,'') <> ''
group by 1, 2
having count(*) > 1
   and count(*) filter (where p.source like 'filler_gap%') > 0
   and count(*) filter (where p.source is null or p.source not like 'filler_gap%') > 0
order by 1, 2;
