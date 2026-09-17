/**
 * lib/email/processor.ts
 *
 * Inbound mail post-processing. NO AI.
 *
 * Called by the mailcarrier worker for every stored inbound message:
 *   [1] load the communications row
 *   [2] classify with keyword/header rules (rule-classifier.ts) - $0, no API call
 *   [3] save communications.ai_classification (+ language_detected if empty)
 *       and merge a small marker into external_data (never overwrite it)
 *
 * No reply drafts are created here. AI is used ONLY when the user presses
 * "Generate AI reply" in the compose dialog (lib/actions/email-compose.ts).
 */

import type { SupabaseClient } from '@supabase/supabase-js';
import { classifyByRules } from './rule-classifier';
import type { ClassificationOutput } from '../../types/classification';

export class ProcessorError extends Error {
  public override readonly cause?: unknown;
  constructor(message: string, cause?: unknown) {
    super(message);
    this.name = 'ProcessorError';
    this.cause = cause;
  }
}

export class ProcessorCommunicationNotFoundError extends ProcessorError {
  constructor(communicationId: string) {
    super(`Communication not found or already deleted: ${communicationId}`);
    this.name = 'ProcessorCommunicationNotFoundError';
  }
}

export interface InboundClassificationResult {
  communicationId: string;
  classification: ClassificationOutput;
  isAutomated: boolean;
  automatedReason?: string;
}

export async function processInbound(
  supabase: SupabaseClient,
  organizationId: string,
  communicationId: string,
): Promise<InboundClassificationResult> {
  // [1] load
  const { data, error } = await supabase
    .schema('app')
    .from('communications')
    .select('id, subject, body_plain, from_address, language_detected, external_data')
    .eq('id', communicationId)
    .eq('organization_id', organizationId)
    .is('deleted_at', null)
    .maybeSingle();

  if (error) {
    throw new ProcessorError(`Communication lookup failed: ${error.message}`, error);
  }
  if (!data) {
    throw new ProcessorCommunicationNotFoundError(communicationId);
  }

  const externalData: Record<string, unknown> =
    data.external_data && typeof data.external_data === 'object' && !Array.isArray(data.external_data)
      ? { ...(data.external_data as Record<string, unknown>) }
      : {};
  const headers: Record<string, string> = {};
  const rsh = externalData.raw_selected_headers;
  if (rsh && typeof rsh === 'object') {
    for (const [k, v] of Object.entries(rsh as Record<string, unknown>)) {
      if (typeof v === 'string') headers[k.toLowerCase()] = v;
    }
  }

  // [2] classify (rules only)
  const rules = classifyByRules({
    subject: (data.subject as string | null) ?? '',
    bodyPlain: (data.body_plain as string | null) ?? '',
    fromAddress: (data.from_address as string | null) ?? undefined,
    headers,
  });
  const c = rules.classification;

  // [3] save
  const update: Record<string, unknown> = {
    ai_classification: c,
    external_data: {
      ...externalData,
      classified_by: 'rules',
      classified_at: new Date().toISOString(),
      automated_mail: rules.isAutomated ? (rules.automatedReason ?? true) : null,
    },
  };
  if (!data.language_detected && c.detectedLanguage !== 'other') {
    update.language_detected = c.detectedLanguage;
  }

  const { error: updateError } = await supabase
    .schema('app')
    .from('communications')
    .update(update)
    .eq('id', communicationId);
  if (updateError) {
    throw new ProcessorError(`Classification save failed: ${updateError.message}`, updateError);
  }

  return {
    communicationId,
    classification: c,
    isAutomated: rules.isAutomated,
    automatedReason: rules.automatedReason,
  };
}
