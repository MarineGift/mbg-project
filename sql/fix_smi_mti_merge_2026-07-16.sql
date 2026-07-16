-- ============================================================
-- fix_smi_mti_merge_2026-07-16.sql
--
-- THE FOUR DEALS, and what they say. All four share pipeline fb74a367, campaign
-- e0000000-0000-4000-8000-00000000000e, creator 551fc4a0, and all four were made
-- on 2026-07-02 inside sixteen minutes:
--
--   19:56:23  4ed714c6  Specialty Minerals (HQ)          source = manual
--                       stage 42316f1f  <- moved along by a person
--   20:04:07  55a80846  Minerals Technologies Inc.       source = entity_enrollment
--   20:12:22  adb8de0d  Specialty Minerals (USA - Reg HQ) source = entity_enrollment
--   20:12:22  758ac7f3  Specialty Minerals Inc.          source = entity_enrollment
--
-- A person opened ONE deal deliberately at 19:56 and advanced it. Then an
-- entity_enrollment process stamped a deal onto every other party row that
-- looked like a filler target - including three rows that are the same company.
-- The duplicates did not sit inert. AUTOMATION ATE THEM AND MANUFACTURED DEALS.
--
-- Every deal has value_amount null, extra_data {}, and last_activity_at equal to
-- created_at. Nothing has happened on any of them since 2026-07-02, including
-- the manual one. So no work is destroyed by removing the three phantoms.
--
-- WHAT THIS FILE DOES
--   KEEP    9f161ff5  Specialty Minerals (HQ)  - 3 contacts incl. Sharad Mathur,
--                     36 communications, 27 engagements, the SEC 8-K supply link,
--                     and the one manual deal. This is the real relationship.
--   REMOVE  cd3dbf9e  Specialty Minerals Inc.  - a filler_gap_2026Q3 insert on
--                     top of the existing base row. Same mistake as my Omya Korea
--                     and Taekyung duplicates. Nothing attached but its phantom.
--   KEEP    5ba57cb3  Minerals Technologies Inc. - a REAL separate entity, the
--                     NYSE parent (MTX). The party stays. Its FCC deal does not -
--                     an FCC licence would be signed by SMI, not the holding
--                     company, and carrying both double-counts the pipeline.
--   FLAG    fa423be1  Specialty Minerals (USA - Regional HQ) - NOT touched beyond
--                     its phantom deal. It came from the BASE roster
--                     (industry.v11_4), same as the keeper, so the roster itself
--                     models HQ and Regional HQ separately. I do not know that
--                     model and will not guess. Decision left to you - see 5.
--
-- IDEMPOTENT. Everything is a SOFT delete - clear deleted_at to restore.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 0) PRE-FLIGHT (run separately) ----------
-- select id, party_id, deal_name, status, source, current_stage_id, deleted_at
-- from app.deals
-- where id in ('4ed714c6-96e0-4229-9274-0579ccdef811'::uuid,
--              '55a80846-bf2d-4104-8daf-9f46c44341e0'::uuid,
--              'adb8de0d-44e1-4589-bb27-85b3ca6b4ef7'::uuid,
--              '758ac7f3-082c-4c33-9799-919880bcbbad'::uuid);
-- EXPECT 4 rows, all deleted_at null. After this file, 3 have deleted_at set.


-- ---------- 1) Retire the three entity_enrollment phantoms ----------
update app.deals d
set deleted_at = now(),
    notes = coalesce(d.notes, '') || E'\n[smi-merge 2026-07-16] RETIRED as a duplicate. Created by entity_enrollment on 2026-07-02 against a party row that duplicates Specialty Minerals (HQ) 9f161ff5-c369-4ca2-8a22-46a1ec40fd0d, which already carries the deliberate manual deal 4ed714c6-96e0-4229-9274-0579ccdef811 plus 3 contacts, 36 communications and 27 engagements. This deal had value_amount null, extra_data empty and no activity after creation, so nothing is lost. The FCC pipeline was counting four Specialty Minerals deals where there is one relationship. Reversible - clear deleted_at.',
    updated_at = now()
where d.id in ('55a80846-bf2d-4104-8daf-9f46c44341e0'::uuid,
               'adb8de0d-44e1-4589-bb27-85b3ca6b4ef7'::uuid,
               '758ac7f3-082c-4c33-9799-919880bcbbad'::uuid)
  and d.deleted_at is null;


-- ---------- 2) Retire the duplicate party ----------
update app.parties p
set deleted_at = now(),
    notes = coalesce(p.notes, '') || E'\n[smi-merge 2026-07-16] RETIRED as a duplicate of Specialty Minerals (HQ) 9f161ff5-c369-4ca2-8a22-46a1ec40fd0d. Inserted by filler_gap_2026Q3 while the base roster row already existed - the NOT EXISTS guard matched exact party_name and "Specialty Minerals Inc." never collided with "Specialty Minerals (HQ)". That gap file header notes it checked against "Double A Specialty Minerals" - it checked the wrong neighbour. Identical to the Omya Korea and Taekyung duplicates in the KR seed. Nothing was attached except one entity_enrollment phantom deal, now retired. Reversible - clear deleted_at.',
    updated_at = now()
where p.id = 'cd3dbf9e-bb61-4fda-81aa-9d914a5a5658'::uuid
  and p.deleted_at is null
  and not exists (select 1 from app.contacts c where c.party_id = p.id and c.deleted_at is null)
  and not exists (select 1 from app.communications m where m.party_id = p.id)
  and not exists (select 1 from app.engagements e where e.party_id = p.id)
  and not exists (select 1 from app.party_supply_links s where s.filler_party_id = p.id)
  and not exists (select 1 from app.deals d where d.party_id = p.id and d.deleted_at is null);


-- ---------- 3) MTI stays, but say plainly what it is ----------
update app.filler_supplier_profile f
set market_role = 'NYSE parent (MTX) - holding company, NOT the licensing counterparty',
    notes = coalesce(f.notes, '') || E'\n[smi-merge 2026-07-16] Party KEPT - Minerals Technologies Inc. is a real, distinct entity, the NYSE-listed parent. Its FCC Licensing deal was RETIRED because a licence would be signed by Specialty Minerals, the operating subsidiary, and holding both deals double-counted the pipeline. Direct all FCC work at Specialty Minerals (HQ) 9f161ff5-c369-4ca2-8a22-46a1ec40fd0d, which holds the contacts and the history. Keep this row for corporate structure and for 10-K segment disclosure, which is a good source of current satellite-plant facts.',
    updated_at = now()
where f.party_id = '5ba57cb3-a5bb-4fd1-8750-342eb2cc25f1'::uuid
  and f.deleted_at is null
  and coalesce(f.notes, '') not like '%[smi-merge 2026-07-16]%';


-- ---------- 4) Protect the keeper - record why it wins ----------
update app.filler_supplier_profile f
set notes = coalesce(f.notes, '') || E'\n[smi-merge 2026-07-16] CANONICAL Specialty Minerals row. Three other rows carried competing evidence levels for this same company - A here, B on Regional HQ, C on both gap-file rows - so any ranking query returned whichever it happened to hit. This row wins on substance - 3 contacts including Sharad Mathur who runs new product and business development for paper and packaging at MTI, 36 communications, 27 engagements, a supply link to International Paper sourced from an SEC 8-K, and the one manual deal 4ed714c6. Route all SMI work here.',
    updated_at = now()
where f.party_id = '9f161ff5-c369-4ca2-8a22-46a1ec40fd0d'::uuid
  and f.deleted_at is null
  and coalesce(f.notes, '') not like '%[smi-merge 2026-07-16]%';


-- ---------- 5) Regional HQ - flagged for YOUR decision, not merged ----------
update app.filler_supplier_profile f
set notes = coalesce(f.notes, '') || E'\n[smi-merge 2026-07-16] DECISION NEEDED - not merged. Its phantom deal was retired, but the party stands. This row and the keeper BOTH come from the base roster industry.v11_4.filler_supplier, so the roster deliberately models a global HQ and a regional HQ as separate rows - the same way it separates Specialty Minerals (Japan) from Specialty Minerals FMT (Japan - Shiraoi). I do not know that model and would rather not guess at it. Against merging - the roster split may be intentional and other countries follow the same shape. For merging - the keeper is already at Bethlehem PA, which IS the SMI Americas HQ, so the two rows describe one office. If the roster shape is arbitrary here, say so and I will fold this row onto 9f161ff5.',
    updated_at = now()
where f.party_id = 'fa423be1-6482-4147-beae-179d118f48d9'::uuid
  and f.deleted_at is null
  and coalesce(f.notes, '') not like '%[smi-merge 2026-07-16]%';


-- ---------- 6) VERIFY ----------
-- select p.party_name, p.deleted_at is null as party_live,
--        f.evidence_level, f.market_role,
--        (select count(*) from app.deals d where d.party_id = p.id and d.deleted_at is null) as live_deals
-- from app.parties p
-- left join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
-- where p.id in ('5ba57cb3-a5bb-4fd1-8750-342eb2cc25f1'::uuid,
--                'cd3dbf9e-bb61-4fda-81aa-9d914a5a5658'::uuid,
--                '9f161ff5-c369-4ca2-8a22-46a1ec40fd0d'::uuid,
--                'fa423be1-6482-4147-beae-179d118f48d9'::uuid)
-- order by p.party_name;
-- EXPECT - Specialty Minerals (HQ) live with 1 deal. MTI live with 0 deals.
-- Regional HQ live with 0 deals. Specialty Minerals Inc. party_live = false.
