-- ============================================================
-- fix_supply_link_taekyung_enrich_2026-07-16.sql
--
-- MY ROW IS IMPOVERISHED. In fix_taekyung_dupes_2026-07-16.sql I inserted a
-- party_supply_links row with only (mill_party_id, filler_party_id,
-- organization_id) because I did not know the table's shape. It ran without
-- error, which is exactly why nobody would notice.
--
-- Block 5 revealed the real convention, set by omya_smi_batch1 on 2026-06-17:
--   link_type, confidence, active_since/until, volume_estimate, product_grade,
--   notes with a pipe-delimited source suffix, and an extra_data envelope
--   carrying batch / source / link_kind / evidence_url / researched_at /
--   supply_structure.
-- My Hansol Janghang link has NONE of that. Bringing it up to the convention.
--
-- SECOND ITEM - flagging the SMI to International Paper link (818ecd2b).
-- It reads link_type = active, confidence = high, "8 satellite plants (US & EU)".
-- Its evidence_url is an SEC 8-K at accession 0000891014-03-000027. The 03 marks
-- it as a 2003 filing. researched_at says 2026-06-17, but the SOURCE is 23 years
-- old, and International Paper has closed or divested a large share of its mill
-- base since - Ticonderoga, Jay and Androscoggin have all changed hands or shut.
-- This is the same shape as the MLC, Zantat and Shiraishi errors: a confident
-- claim resting on a document that has aged out. Not changing confidence without
-- checking - recording the concern.
--
-- IDEMPOTENT. NOTHING IS INSERTED. No BEGIN / no DO blocks / no semicolons or
-- bare 'into' in strings.
-- ============================================================

-- ---------- 0) PRE-FLIGHT (run first, separately) ----------
-- select id, filler_party_id, mill_party_id, link_type, confidence,
--        product_grade, volume_estimate, notes, extra_data
-- from app.party_supply_links
-- where filler_party_id = '3d121300-0eab-49b9-baf3-89f592baca78'::uuid;
-- EXPECT 1 row, almost every column null. That is the row this file fills in.


-- ---------- 1) Bring the Hansol Janghang link up to convention ----------
update app.party_supply_links s
set product_grade   = coalesce(s.product_grade, 'PCC filler-grade'),
    volume_estimate = coalesce(s.volume_estimate, '1 satellite plant (KR)'),
    notes = coalesce(s.notes, '') ||
            'Hansol Paper Janghang mill - on-site PCC (mill-level) | src: internal, batch15 mill intro',
    extra_data = coalesce(s.extra_data, '{}'::jsonb) || '{"batch": "kr_filler_2026-07-16", "source": "internal - 20260620210000_paper_mill_website_intro_batch15 Janghang intro", "link_kind": "pcc_satellite", "evidence_url": null, "researched_at": "2026-07-16", "supply_structure": "on-site satellite PCC (mill-level)", "source_type": "internal", "caveat": "Recorded from an internal note, NOT a primary source. Confirm with Hansol or Taekyung BK before treating as established."}'::jsonb,
    updated_at = now()
where s.mill_party_id   = '890ae7ee-12ae-4889-be24-c1f2155dbad0'::uuid
  and s.filler_party_id = '3d121300-0eab-49b9-baf3-89f592baca78'::uuid
  and coalesce(s.notes, '') not like '%Hansol Paper Janghang mill - on-site PCC%';


-- ---------- 2) link_type - separate statement on purpose ----------
-- If link_type is an enum and 'active' is not a member, this errors. Block 1 has
-- already committed by then, so nothing above is lost.
update app.party_supply_links s
set link_type = 'active', updated_at = now()
where s.mill_party_id   = '890ae7ee-12ae-4889-be24-c1f2155dbad0'::uuid
  and s.filler_party_id = '3d121300-0eab-49b9-baf3-89f592baca78'::uuid
  and s.link_type is null;


-- ---------- 3) confidence - also separate, and deliberately NOT high ----------
-- The existing SMI row uses 'high'. Mine does not deserve it. The Hansol
-- Janghang link comes from a note inside another party's intro, corroborated
-- only by Taekyung BK's own supply_model. Two internal records agreeing is not a
-- primary source. If 'medium' is not a valid enum member this errors and the
-- column simply stays null, which is a fair outcome.
update app.party_supply_links s
set confidence = 'medium', updated_at = now()
where s.mill_party_id   = '890ae7ee-12ae-4889-be24-c1f2155dbad0'::uuid
  and s.filler_party_id = '3d121300-0eab-49b9-baf3-89f592baca78'::uuid
  and s.confidence is null;


-- ---------- 4) FLAG the SMI to International Paper link as source-stale ----------
update app.party_supply_links s
set extra_data = coalesce(s.extra_data, '{}'::jsonb) || '{"staleness_flag": {"raised_at": "2026-07-16", "concern": "link_type is active and confidence is high, but the evidence_url is an SEC 8-K at accession 0000891014-03-000027, a 2003 filing. International Paper has closed or divested much of its mill base since then - Ticonderoga, Jay and Androscoggin among them. The 8 satellite plants figure is very likely no longer accurate. Same failure shape as the MLC, Zantat and Shiraishi paper-grade claims: a confident record resting on a document that aged out. Confidence NOT lowered pending a check against current MTI disclosure.", "suggested_check": "MTI 10-K segment disclosure and mineralstech.com satellite plant list"}}'::jsonb,
    updated_at = now()
where s.id = '818ecd2b-5a51-4343-8950-c5b47e3c7fd6'::uuid
  and not (coalesce(s.extra_data, '{}'::jsonb) ? 'staleness_flag');


-- ---------- 5) VERIFY ----------
-- select s.id, f.party_name as filler, m.party_name as mill,
--        s.link_type, s.confidence, s.product_grade, s.volume_estimate,
--        s.extra_data #>> '{source_type}' as src_type
-- from app.party_supply_links s
-- left join app.parties f on f.id = s.filler_party_id
-- left join app.parties m on m.id = s.mill_party_id
-- order by f.party_name;
-- Shows every supply link in the DB. Worth a look on its own - how many are
-- there in total, and how many rest on a source older than the MLC 8-K.


-- ---------- 6) STILL NEEDED - block 1 of scan_smi_deals ----------
-- This file came from block 5. Block 1 is the one that decides the merge:
--   select d.* from app.deals d
--   where d.party_id in ('5ba57cb3-a5bb-4fd1-8750-342eb2cc25f1'::uuid,
--                        'cd3dbf9e-bb61-4fda-81aa-9d914a5a5658'::uuid,
--                        '9f161ff5-c369-4ca2-8a22-46a1ec40fd0d'::uuid,
--                        'fa423be1-6482-4147-beae-179d118f48d9'::uuid);
-- Four deals sit across the four duplicate SMI/MTI rows, three of them on rows
-- with zero communications. Until those four rows are visible I will not write
-- the merge.
