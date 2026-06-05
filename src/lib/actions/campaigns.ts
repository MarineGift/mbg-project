/**
 * lib/actions/campaigns.ts
 *
 * Server Actions for campaigns (app.campaigns). organization_id is filled by
 * the column default app.current_organization_id() (see 03 migration), so it is
 * intentionally NOT set on INSERT -- matching lib/actions/rounds.ts.
 */

'use server';

import { revalidatePath } from 'next/cache';
import { z } from 'zod';
import { requireAuth } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';

export interface CampaignActionResult {
  ok: boolean;
  errorCode?: 'unauthorized' | 'validation' | 'not_found' | 'database' | 'unknown';
  errorMessage?: string;
}

const createSchema = z.object({
  name: z.string().min(1, 'Required').max(120),
  campaignType: z.string().max(60).optional().nullable(),
  description: z.string().max(5000).optional().nullable(),
  status: z.enum(['active', 'closed', 'archived']).default('active'),
  startDate: z.string().optional().nullable(),
  endDate: z.string().optional().nullable(),
  color: z.string().max(20).optional().nullable(),
});

export async function createCampaign(
  input: z.input<typeof createSchema>,
): Promise<CampaignActionResult & { campaignId?: string }> {
  try { await requireAuth(); } catch { return { ok: false, errorCode: 'unauthorized' }; }

  const parsed = createSchema.safeParse(input);
  if (!parsed.success) {
    return { ok: false, errorCode: 'validation', errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input' };
  }

  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('campaigns' as never)
    .insert({
      name: parsed.data.name.trim(),
      campaign_type: parsed.data.campaignType?.trim() || null,
      description: parsed.data.description?.trim() || null,
      status: parsed.data.status,
      start_date: parsed.data.startDate || null,
      end_date: parsed.data.endDate || null,
      color: parsed.data.color || null,
    } as never)
    .select('id')
    .single();

  if (error || !data) {
    return { ok: false, errorCode: 'database', errorMessage: error?.message ?? 'Insert failed' };
  }
  revalidatePath('/campaigns');
  return { ok: true, campaignId: (data as { id: string }).id };
}

export async function deleteCampaign(input: { campaignId: string }): Promise<CampaignActionResult> {
  try { await requireAuth(); } catch { return { ok: false, errorCode: 'unauthorized' }; }

  const parsed = z.object({ campaignId: z.string().uuid() }).safeParse(input);
  if (!parsed.success) return { ok: false, errorCode: 'validation' };

  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('campaigns' as never)
    .delete()
    .eq('id', parsed.data.campaignId)
    .select('id')
    .maybeSingle();

  if (error) return { ok: false, errorCode: 'database', errorMessage: error.message };
  if (!data) return { ok: false, errorCode: 'not_found' };
  revalidatePath('/campaigns');
  return { ok: true };
}
