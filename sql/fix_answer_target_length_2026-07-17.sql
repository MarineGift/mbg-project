-- ============================================================
-- fix_answer_target_length_2026-07-17.sql
--
-- The six filler answers landed, but three of them BREAK THEIR OWN CONTRACT:
--
--   answer_key            variant  target_length  actual en
--   fcc_inquiry_intro     short          200         226   over by 26
--   fcc_inquiry_intro     medium         900        1056   over by 156
--   fcc_inquiry_intro     long          1900        1978   over by 78
--   nda_request_close     short          180         188   over by 8
--
-- target_length is the whole point of migration 027 - the selector picks a
-- variant against the field's max_length. If a form field caps at 200 chars it
-- picks the short variant, and then 26 characters fall off the end. The short
-- variant exists precisely to fit that field. I wrote the targets as an
-- aspiration and then wrote past them.
--
-- Trimming the bodies rather than raising the targets. Raising target_length to
-- the real length would mean a 200-char field matches NOTHING, which is worse
-- than a body that fits.
--
-- Meaning is unchanged. Nothing new is disclosed. Every trim removes words, not
-- claims.
--
-- IDEMPOTENT - guarded on length so a rerun is a no-op.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 1) short - 226 -> under 200 ----------
update app.answer_library
set body_en = 'Marinebio Group licenses FCC, a filler grown in situ on pulp fiber, letting mills swap pulp for filler without losing strength. Runs on existing PCC and GCC assets. Open to a short call under NDA.',
    updated_at = now()
where answer_key = 'fcc_inquiry_intro' and variant = 'short' and length(body_en) > 200;

-- ---------- 2) nda_request_close - 188 -> under 180 ----------
update app.answer_library
set body_en = 'We welcome a short technical conversation under NDA. We do not discuss process detail, formulations or operating parameters outside an agreement, and we expect the same of you.',
    updated_at = now()
where answer_key = 'nda_request_close' and variant = 'short' and length(body_en) > 180;

-- ---------- 3) medium - 1056 -> under 900 ----------
update app.answer_library
set body_en = 'Marinebio Group is a technology licensor in paper fillers. We have developed FCC, a filler in which calcium carbonate is grown in situ on pulp fiber, so mineral and fiber form a single composite particle rather than a physical blend. For the mill the effect is direct - costly pulp is replaced by low-cost filler without losing sheet strength.

We are contacting you because FCC is produced on existing PCC and GCC plant assets. It is not a greenfield proposition. For a filler producer it is an upgrade to a line you already run and to mill customers you already hold, sold as a specialty grade rather than a commodity. We license - you produce and you sell.

The work is patented and published in the peer-reviewed literature, including two ACS journal articles, and is certified under Korea''s NET New Excellent Technology programme.

We welcome a short technical conversation under NDA.',
    updated_at = now()
where answer_key = 'fcc_inquiry_intro' and variant = 'medium' and length(body_en) > 900;

-- ---------- 4) long - 1978 -> under 1900 ----------
update app.answer_library
set body_en = 'Marinebio Group is a technology licensor in paper fillers, writing about a licensing opportunity that sits on plant assets you already operate.

WHAT FCC IS. FCC is a filler in which calcium carbonate is grown in situ on pulp fiber. Mineral and fiber form a single composite particle rather than a physical blend of two materials. The distinction matters because the strength penalty that normally caps filler loading comes from mineral displacing fiber-to-fiber bonding. When the mineral is grown on the fiber instead of mixed alongside it, that trade-off changes.

WHAT IT DOES FOR THE MILL. Pulp is the largest cost line in most paper grades and filler is among the smallest. FCC lets a mill move volume from the first to the second without giving up sheet strength. The mill needs no capital expenditure - it buys a filler grade instead of buying pulp.

WHY A FILLER PRODUCER RATHER THAN A MILL. FCC is produced on existing PCC and GCC plant assets. It is not a greenfield proposition and does not ask you to enter a new business. It is an upgrade to a line you already run, sold to mill customers you already hold, at a specialty price rather than a commodity one. Our model is licensing - we license, you produce and you sell.

WHAT IS ESTABLISHED. The work is patented and published in the peer-reviewed literature, including two ACS journal articles, so the science is on the public record and can be assessed independently before any commercial discussion. It is certified under Korea''s NET New Excellent Technology programme.

WHAT WE ASK. A short technical conversation under NDA - fifteen minutes to establish whether this is worth either side''s time. We do not discuss process detail, formulations or operating parameters outside an agreement, and we expect the same discipline from you. If the fit is not there we would rather find out quickly.',
    updated_at = now()
where answer_key = 'fcc_inquiry_intro' and variant = 'long' and length(body_en) > 1900;

-- ---------- 5) VERIFY ----------
-- select answer_key, variant, target_length, length(body_en) as en,
--        length(body_en) <= target_length as fits
-- from app.answer_library
-- where tags @> ARRAY['filler_safe']
-- order by target_length;
-- All six must read fits = true. body_ko is well under every target already.
