/**
 * types/email-outcome.ts
 *
 * Shared constants + types for the send-outcome log
 * (app.email_send_outcomes, migration_20260714090000).
 *
 * Lives outside lib/actions because 'use server' modules may only export
 * async functions; the client component and the server actions both import
 * these from here.
 */

export const OUTCOME_CODES = [
  'bounce_hard',
  'bounce_soft',
  'send_failure',
  'rejected_sector',
  'rejected_stage',
  'rejected_other',
  'unsubscribe_request',
  'auto_reply',
  'reply_positive',
  'reply_neutral',
] as const;
export type OutcomeCode = (typeof OUTCOME_CODES)[number];

export const NEXT_ACTIONS = [
  'suppress',
  'resend_later',
  'switch_deck',
  'switch_contact',
  'follow_up',
  'none',
] as const;
export type NextAction = (typeof NEXT_ACTIONS)[number];

export type OutcomeRow = {
  id: string;
  recipient_email: string;
  outcome: OutcomeCode;
  reason: string | null;
  next_action: NextAction | null;
  resend_not_before: string | null;
  source: string | null;
  evidence_ref: string | null;
  created_at: string;
  party_id: string | null;
  party_name: string | null;
  party_type: string | null;
};

export interface AddOutcomeInput {
  recipientEmail: string;
  outcome: OutcomeCode;
  reason?: string;
  nextAction: NextAction;
  /** ISO date (yyyy-mm-dd); only used with nextAction='resend_later' */
  resendNotBefore?: string;
}
