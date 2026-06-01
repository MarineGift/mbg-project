'use server';
/**
 * lib/actions/email-tracking.ts
 *
 * Create an email tracking record + inject the HTML pixel.
 *
 * Used by:
 *   - communications.ts -> sendOutboundManual (manual send)
 *   - (future) drafts.ts -> sendApprovedDraft (AI auto-send)
 */

import { createSupabaseServerClient } from '@/lib/supabase/server';
import { rpc } from '@/lib/rpc/typed-rpc';
import { extractLinks, injectTracking } from '@/lib/utils/email-tracking';
import type { TrackingPayload } from '@/types/phase21';

/* ──────────────────────────────────────────────────────────
 * Input type
 * ────────────────────────────────────────────────────────── */
export interface CreateTrackingInput {
  orgId: string;

  /** the communications.id of a manual send */
  communicationId?: string;

  /** the id of a template-based draft (future) */
  draftId?: string;

  partyId?: string;
  contactId?: string;
  subject?: string;
  sentTo: string;

  /** The HTML body to inject the pixel + links into.
   *  Convert plain text via plainToHtml() before calling. */
  htmlBody: string;
}

export interface CreateTrackingResult {
  payload: TrackingPayload;
  /** HTML with the pixel/tracking links injected - pass to sendOne(bodyHtml: ...) */
  injectedHtml: string;
}

/* ──────────────────────────────────────────────────────────
 * Main function
 * ────────────────────────────────────────────────────────── */

/**
 * 1. extract external links from htmlBody
 * 2. create email_tracking + email_tracking_links rows (RPC)
 * 3. inject the pixel + tracking links into the HTML
 * 4. return injectedHtml -> pass this to sendOne(bodyHtml)
 */
export async function createEmailTracking(
  input: CreateTrackingInput,
): Promise<CreateTrackingResult> {
  const supabase = await createSupabaseServerClient();

  const links = extractLinks(input.htmlBody).map((url) => ({ url }));

  const { data, error } = await rpc(supabase, 'create_email_tracking', {
    p_org_id:           input.orgId,
    p_communication_id: input.communicationId ?? undefined,
    p_draft_id:         input.draftId         ?? undefined,
    p_party_id:         input.partyId         ?? undefined,
    p_contact_id:       input.contactId       ?? undefined,
    p_subject:          input.subject         ?? undefined,
    p_sent_to:          input.sentTo,
    p_links:            links,
  });

  if (error) {
    throw new Error(`createEmailTracking RPC failed: ${error.message}`);
  }

  const payload = data as unknown as TrackingPayload;
  const injectedHtml = injectTracking(input.htmlBody, payload);

  return { payload, injectedHtml };
}
