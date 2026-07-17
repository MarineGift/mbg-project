-- ============================================================
-- migration_028_do_not_contact_2026-07-17.sql
--
-- Adds a party-level do-not-contact flag, because there is currently nowhere to
-- record that a party must never be approached.
--
-- WHY THIS IS NEEDED, concretely.
-- Taekyung Industrial co-filed the competing patent family EP4579034 with
-- Kleannara Co., Ltd. on flexible calcium carbonate. Both are adverse parties in
-- a live dispute. On 2026-07-16 I flagged the two Taekyung rows by writing into
-- app.filler_supplier_profile.extra_data. Then block 6 of
-- scan_form_system_state returned this:
--
--   Kleannara (깨끗한나라)   party_type_id = 2   adverse = null   form_rows = 0
--
-- Kleannara is a PAPER MILL. It has no filler_supplier_profile, so the flag I
-- invented has nowhere to live. And block 4 shows why that matters: of 888 paper
-- mill parties, 868 already have a contact - 97.7 percent. The mill roster is
-- the one part of this database that is actually reachable, and the other side
-- of a patent dispute is sitting inside it, unmarked.
--
-- THE PRECEDENT IS ALREADY SET. migration_027 put contact_form_url and
-- preferred_contact_method on app.parties with exactly this reasoning:
--   "common attribute of any party -> lives on parties itself,
--    NOT on investor_profile / paper_mill_profile"
-- Whether a party must not be approached is true of any party regardless of
-- type. Same argument, same home.
--
-- WHAT THIS DOES NOT DO. A flag nobody reads changes nothing. Two things must
-- consume it, and each gets its own file with its own care:
--   1. app.v_email_do_not_send - the suppression view. Adverse parties DO belong
--      there. Yesterday I argued generic inboxes do not, and that still holds:
--      a generic inbox is a HYGIENE problem and a duplicate party is a DEDUP
--      problem, both of which belong at enrolment. But "never contact this
--      party" is not hygiene - it is suppression, which is exactly what the view
--      is for. The only difference from its existing inputs is that the source
--      is a decision rather than an event.
--   2. the enrolment step - so no deal, no sequence and no contact_inquiry form
--      is ever created against a flagged party in the first place.
-- Neither is in this file. This file only creates the place to put the fact.
--
-- Supabase SQL Editor safe:
--   * no do-blocks, no temp tables
--   * ADD COLUMN IF NOT EXISTS and CREATE INDEX IF NOT EXISTS - idempotent
--   * constraint is DROP IF EXISTS then ADD, matching the 026/027 pattern
--
-- SaaS rules:
--   * app.parties is an entity table and already carries created_by - nothing to
--     add there
--   * RLS from 013 already covers every row. RLS is row level, so new columns
--     need no new policy.
--
-- Depends on: migration_027_contact_method_variants.sql
-- ============================================================


-- ------------------------------------------------------------
-- 1. parties: must this party never be approached
--    Default false. The overwhelming majority of 1800+ rows are
--    ordinary targets - the flag marks the exceptions.
-- ------------------------------------------------------------
ALTER TABLE app.parties
  ADD COLUMN IF NOT EXISTS do_not_contact boolean NOT NULL DEFAULT false;

-- A bare boolean invites someone to unset it without knowing why. The reason is
-- not optional in practice, so the constraint below makes it structural.
ALTER TABLE app.parties
  ADD COLUMN IF NOT EXISTS do_not_contact_reason text;

ALTER TABLE app.parties
  ADD COLUMN IF NOT EXISTS do_not_contact_set_at timestamptz;


-- ------------------------------------------------------------
-- 2. A flag without a reason is a landmine for whoever finds it
--    next. If the flag is true the reason is mandatory.
-- ------------------------------------------------------------
ALTER TABLE app.parties
  DROP CONSTRAINT IF EXISTS parties_do_not_contact_reason_chk;

ALTER TABLE app.parties
  ADD CONSTRAINT parties_do_not_contact_reason_chk
  CHECK (
    do_not_contact IS FALSE
    OR (do_not_contact_reason IS NOT NULL AND length(btrim(do_not_contact_reason)) > 0)
  );


-- ------------------------------------------------------------
-- 3. Partial index - the guard asks "is this one flagged" on
--    every enrolment, and the true set is tiny. Same shape as
--    the contact_form_url partial index in 027.
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_parties_do_not_contact
  ON app.parties (id)
  WHERE do_not_contact IS TRUE;


-- ------------------------------------------------------------
-- 4. Column comments - this flag will be read by someone who was
--    not here for the dispute.
-- ------------------------------------------------------------
COMMENT ON COLUMN app.parties.do_not_contact IS
  'TRUE means this party must never receive outreach of any kind - no cold email, no sequence enrolment, no deal, no contact_inquiry form submission. Reasons include being an adverse party in litigation, a counterparty under an agreement that restricts contact, or an explicit request. This is NOT the same as app.v_email_do_not_send, which suppresses people who have already responded, bounced or applied. That view answers "stop asking". This column answers "never ask". Set it through a reviewed migration or fix file, never ad hoc.';

COMMENT ON COLUMN app.parties.do_not_contact_reason IS
  'Mandatory whenever do_not_contact is TRUE - enforced by parties_do_not_contact_reason_chk. State the reason plainly enough that someone with no context can tell whether it still applies. An unexplained block gets cleared by the next person who finds it in the way.';


-- ------------------------------------------------------------
-- 5. VERIFY
-- ------------------------------------------------------------
-- select column_name, data_type, column_default, is_nullable
-- from information_schema.columns
-- where table_schema = 'app' and table_name = 'parties'
--   and column_name like 'do_not_contact%'
-- order by ordinal_position;
--
-- select count(*) filter (where do_not_contact) as blocked,
--        count(*) as total
-- from app.parties where deleted_at is null;
-- Expect blocked = 0 until fix_adverse_parties_dnc runs.
