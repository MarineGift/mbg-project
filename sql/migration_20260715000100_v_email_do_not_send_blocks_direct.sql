-- =====================================================================
-- migration_20260715000100_v_email_do_not_send_blocks_direct.sql
--
-- Adds a trailing column: blocks_direct boolean
--
-- Why
--   app.v_email_do_not_send is a COLD-OUTREACH suppression list, not a
--   global one. Its rows include form_submitted, rejected_*, reply_* and
--   resend_later cooldowns -- none of which should stop a human writing a
--   direct reply. A firm that submits our form and then mails us MUST be
--   answerable.
--
--   But two of its inputs are genuinely global and must win on every path,
--   including a hand-written reply:
--       outcome     = unsubscribe_request
--       next_action = suppress
--   blocks_direct marks exactly those rows.
--
-- Consumer
--   src/lib/email/send-outbound.ts reads this column when
--   sendClass = direct. When sendClass = cold, every row blocks and this
--   column is ignored.
--
-- is_follow_up is NOT this. It means reply_positive OR next_action=follow_up
--   -- a hint that a human should reach out. It is left untouched.
--
-- Safety
--   CREATE OR REPLACE VIEW may only APPEND columns, which is what this does.
--   Existing consumers are unaffected because they select a subset:
--     app.v_enrollment_send_health        -> party_id, email_lower
--     public.get_due_enrollments()        -> party_id, email_lower
--     src/lib/queries/bulk-mail.ts        -> email_lower, party_id
--   The body below is byte-for-byte pg_get_viewdef output with the new
--   column threaded through the three CTEs and the final GROUP BY.
--
-- The view still has NO organization_id. Do not add an org filter downstream
--   -- 42703. Org safety is carried by the candidate set, as documented in
--   docs/schema/app_schema_reference.md.
--
-- Read-only view. Safe to re-run.
-- =====================================================================

CREATE OR REPLACE VIEW app.v_email_do_not_send AS
WITH outcome_block AS (
  SELECT lower(o.recipient_email) AS email_lower,
         o.party_id,
         max(o.occurred_at) AS last_event_at,
         string_agg(DISTINCT o.outcome, ', '::text) AS reasons,
         bool_or(o.outcome = 'reply_positive'::text OR o.next_action = 'follow_up'::text) AS is_follow_up,
         bool_or(o.outcome = 'unsubscribe_request'::text OR o.next_action = 'suppress'::text) AS blocks_direct
    FROM app.email_send_outcomes o
   WHERE (o.outcome = ANY (ARRAY['bounce_hard'::text, 'unsubscribe_request'::text, 'reply_positive'::text, 'reply_neutral'::text, 'rejected_sector'::text, 'rejected_stage'::text, 'rejected_other'::text]))
      OR o.next_action = 'suppress'::text
      OR o.next_action = 'resend_later'::text AND o.resend_not_before > CURRENT_DATE
   GROUP BY (lower(o.recipient_email)), o.party_id
), form_block AS (
  SELECT lower(c.email) AS email_lower,
         af.party_id,
         max(COALESCE(af.submitted_at, af.updated_at)) AS last_event_at,
         'form_'::text || min(af.status) AS reasons,
         false AS is_follow_up,
         false AS blocks_direct
    FROM app.application_forms af
    JOIN app.contacts c ON c.party_id = af.party_id
   WHERE (af.status = ANY (ARRAY['submitted'::text, 'decided'::text]))
     AND c.email IS NOT NULL
     AND btrim(c.email) <> ''::text
   GROUP BY (lower(c.email)), af.party_id
), form_block_partyonly AS (
  SELECT NULL::text AS email_lower,
         af.party_id,
         max(COALESCE(af.submitted_at, af.updated_at)) AS last_event_at,
         'form_'::text || min(af.status) AS reasons,
         false AS is_follow_up,
         false AS blocks_direct
    FROM app.application_forms af
   WHERE (af.status = ANY (ARRAY['submitted'::text, 'decided'::text]))
     AND NOT (EXISTS (
       SELECT 1
         FROM app.contacts c
        WHERE c.party_id = af.party_id
          AND c.email IS NOT NULL
          AND btrim(c.email) <> ''::text))
   GROUP BY af.party_id
), unioned AS (
  SELECT outcome_block.email_lower,
         outcome_block.party_id,
         outcome_block.last_event_at,
         outcome_block.reasons,
         outcome_block.is_follow_up,
         outcome_block.blocks_direct
    FROM outcome_block
  UNION ALL
  SELECT form_block.email_lower,
         form_block.party_id,
         form_block.last_event_at,
         form_block.reasons,
         form_block.is_follow_up,
         form_block.blocks_direct
    FROM form_block
  UNION ALL
  SELECT form_block_partyonly.email_lower,
         form_block_partyonly.party_id,
         form_block_partyonly.last_event_at,
         form_block_partyonly.reasons,
         form_block_partyonly.is_follow_up,
         form_block_partyonly.blocks_direct
    FROM form_block_partyonly
)
SELECT email_lower,
       party_id,
       max(last_event_at) AS last_event_at,
       string_agg(DISTINCT reasons, ', '::text) AS outcomes,
       bool_or(is_follow_up) AS is_follow_up,
       bool_or(blocks_direct) AS blocks_direct
  FROM unioned
 GROUP BY email_lower, party_id;
