'use server';

/**
 * lib/actions/marketing-segment.ts
 *
 * buildMarketingSegment -- analyze a directory segment and return the next
 * send batch (party ids). The batch is then previewed / queued through the
 * existing bulk-mail actions with source { mode: 'parties', partyIds }.
 */

import { z } from 'zod';
import { requireAuth } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { resolveMarketingSegment, MAX_BATCH, type SegmentResult } from '@/lib/queries/marketing-segment';

const schema = z.object({
  partyTypeCode: z.string().min(1).max(64),
  templateId: z.string().uuid(),
  includeCountries: z.array(z.string().max(8)).max(300).optional(),
  excludeCountries: z.array(z.string().max(8)).max(300).optional(),
  keyword: z.string().max(200).optional(),
  supplierQuery: z.string().max(200).optional(),
  receivedTemplateId: z.string().uuid().nullable().optional(),
  receivedMinDays: z.number().int().min(0).max(365).optional(),
  batchSize: z.number().int().min(1).max(MAX_BATCH),
});

export async function buildMarketingSegment(
  input: z.input<typeof schema>,
): Promise<{ ok: boolean; errorMessage?: string; result?: SegmentResult }> {
  let auth;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorMessage: 'Not signed in.' };
  }
  const parsed = schema.safeParse(input);
  if (!parsed.success) {
    return { ok: false, errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input' };
  }
  const supabase = await createSupabaseServerClient();
  try {
    const result = await resolveMarketingSegment(supabase, auth.organizationId, parsed.data);
    return { ok: true, result };
  } catch (err) {
    return { ok: false, errorMessage: err instanceof Error ? err.message : 'Segment failed' };
  }
}
