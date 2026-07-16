-- ============================================================
-- fix_smi_regional_hq_keep_2026-07-16.sql
--
-- DECISION - fa423be1 Specialty Minerals (USA - Regional HQ) STAYS. Not merged.
--
-- I flagged it yesterday as undecided because I did not know the base roster's
-- model. Block 5 of scan_entity_enrollment settled it without anyone having to
-- answer. The 148 unreachable deals are drawn from exactly two families, and
-- their naming is perfectly regular:
--
--     Specialty Minerals (<Country>)            43 rows   country entity
--     Specialty Minerals (<Country> - <Site>)   65 rows   plant or site
--
-- 'Specialty Minerals (USA - Regional HQ)' matches the SECOND pattern exactly.
-- It is a SITE row - the Americas regional office - filed the same way as
-- 'Specialty Minerals (Japan)' and 'Specialty Minerals FMT (Japan - Shiraoi,
-- Hokkaido)' are filed. The roster is internally consistent and this row obeys
-- it. Merging it away would have broken a convention that holds across 108 rows
-- in order to fix a problem that was never there.
--
-- Keeping it is right. The caution was worth it - I nearly folded a well-formed
-- row into another because two names looked similar to me.
--
-- CONTRAST with cd3dbf9e 'Specialty Minerals Inc.', which was retired: that one
-- matches NEITHER pattern, came from filler_gap_2026Q3 rather than the base
-- roster, and duplicated an existing row. Naming convention was the tell.
--
-- IDEMPOTENT. Notes only - nothing structural changes.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

update app.filler_supplier_profile f
set notes = coalesce(f.notes, '') || E'\n[roster-model 2026-07-16] DECIDED - KEEP, do not merge. The base roster industry.v11_4.filler_supplier names Specialty Minerals rows in two regular shapes - "Specialty Minerals (Country)" for a country entity, 43 of them, and "Specialty Minerals (Country - Site)" for a plant or office, 65 of them. This row matches the second shape exactly and is the Americas regional office. The convention holds across 108 rows. Folding this row onto Specialty Minerals (HQ) would break a working model because two names looked alike. Its entity_enrollment phantom deal was retired on 2026-07-16 and that was the only thing wrong with it.',
    updated_at = now()
where f.party_id = 'fa423be1-6482-4147-beae-179d118f48d9'::uuid
  and f.deleted_at is null
  and coalesce(f.notes, '') not like '%[roster-model 2026-07-16]%';

-- Record the rule where the next person will hit it - on the keeper.
update app.filler_supplier_profile f
set notes = coalesce(f.notes, '') || E'\n[roster-model 2026-07-16] HOW TO TELL A DUPLICATE FROM A SIBLING in the Specialty Minerals and Omya families. The base roster industry.v11_4.filler_supplier uses two regular name shapes - "Specialty Minerals (Country)" and "Specialty Minerals (Country - Site)". A row obeying either shape is a legitimate sibling, however similar the name looks. A row obeying NEITHER, and carrying source = filler_gap_2026Q3 or filler_gap_kr_2026Q3, is a gap-file insert that landed on top of a base row the gap file could not see - that is a duplicate. "Specialty Minerals Inc." failed both tests and was retired. "Specialty Minerals (USA - Regional HQ)" passes and stays. The same test retires "Omya Korea Inc." against "Omya (Korea)".',
    updated_at = now()
where f.party_id = '9f161ff5-c369-4ca2-8a22-46a1ec40fd0d'::uuid
  and f.deleted_at is null
  and coalesce(f.notes, '') not like '%[roster-model 2026-07-16]%';

-- ---------- VERIFY ----------
-- select p.party_name, p.deleted_at is null as live,
--        (select count(*) from app.deals d where d.party_id = p.id and d.deleted_at is null) as live_deals
-- from app.parties p
-- where p.id in ('9f161ff5-c369-4ca2-8a22-46a1ec40fd0d'::uuid,
--                'fa423be1-6482-4147-beae-179d118f48d9'::uuid,
--                '5ba57cb3-a5bb-4fd1-8750-342eb2cc25f1'::uuid,
--                'cd3dbf9e-bb61-4fda-81aa-9d914a5a5658'::uuid)
-- order by p.party_name;
-- EXPECT - SMI (HQ) live 1 deal, Regional HQ live 0 deals, MTI live 0 deals,
--          Specialty Minerals Inc. live = false.
