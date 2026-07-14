-- =====================================================================
-- 20260714230000_fix_material_impact_contact.sql
-- Purpose: Seed 7/20 preflight Part 1 flagged one active enrollment
--          (Material Impact) with NO linked contact. All 5 existing
--          Material Impact contacts had NULL email and the party had
--          no contact_form_url. Public general inbox found on the
--          firm's official site: info@materialimpact.com.
-- Action:  (1) set email on the generic party-level contact,
--          (2) relink the enrollment to that contact and reinstate it
--              (it was cancelled mid-triage before the address was found).
-- Status:  APPLIED 2026-07-14. Idempotent guards included; safe to
--          re-run (both statements no-op after first application).
-- Result:  Seed sequence active 67 / cancelled 10, bad_email 0
--          -> clean 67/67 for the 7/20 send.
-- =====================================================================

-- Statement 1: general inbox on the unnamed Material Impact contact.
-- Guard: only fills if email is still NULL/empty (never overwrites).
UPDATE app.contacts
SET email = 'info@materialimpact.com'
WHERE id = '0831477d-6b4e-4067-abfd-a5ff47c9fd5f'
  AND (email IS NULL OR btrim(email) = '');

-- Statement 2: relink + reinstate the Seed enrollment.
-- Guard: only flips back if still cancelled (no-op once active).
UPDATE app.email_sequence_enrollments
SET contact_id = '0831477d-6b4e-4067-abfd-a5ff47c9fd5f',
    status = 'active'::app.enrollment_status
WHERE id = 'ad244413-d0cd-4df7-b3fa-94827cc7cd39'
  AND status = 'cancelled'::app.enrollment_status;

-- Verification (run separately, single SELECT):
-- expect active_cnt = 67, cancelled_cnt = 10
-- SELECT COUNT(*) FILTER (WHERE e.status = 'active'::app.enrollment_status) AS active_cnt,
--        COUNT(*) FILTER (WHERE e.status = 'cancelled'::app.enrollment_status) AS cancelled_cnt
-- FROM app.email_sequences s
-- JOIN app.email_sequence_enrollments e ON e.sequence_id = s.id
-- WHERE s.name = 'Investor Cold Outreach - FCC Seed';

-- Follow-up (backlog, low priority): partner-level emails for
-- Carmichael Roberts / Adam Sharkawy are not public. Add Material
-- Impact to the warm-intro discovery list (alongside Planet A /
-- Eclipse) for a LinkedIn-path upgrade later.
