/**
 * lib/actions/rounds.ts
 *
 * Server Actions for fundraising rounds (app.rounds).
 *
 * organization_id is filled by the column default app.current_organization_id()
 * (set in the rounds migration), so it is intentionally NOT set on INSERT here
 * -- matching the "actions never set org" pattern. RLS enforces org isolation
 * on every mutation.
 *
 * Follows the lib/actions/engagements.ts shape (zod + requireAuth + a typed
 * result object).
 */

'use server';

import { revalidatePath } from 'next/cache';
import { z } from 'zod';
import { requireAuth } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';

export interface RoundActionResult {
  ok: boolean;
  errorCode?:
    | 'unauthorized'
    | 'validation'
    | 'not_found'
    | 'database'
    | 'unknown';
  errorMessage?: string;
}

// Rounds only surface on the Investor board for now.
const INVESTOR_PIPELINE_PATH = '/pipelines/investor';

/* ============================================================
 * createRound
 * ============================================================ */

const roundCreateSchema = z.object({
  name: z.string().min(1, 'Required').max(120),
  roundType: z.string().max(60).optional().nullable(),
  targetAmount: z.number().min(0).max(1e15).optional().nullable(),
  preMoneyValuation: z.number().min(0).max(1e15).optional().nullable(),
  currency: z.string().length(3).default('USD'),
  status: z.enum(['open', 'closed', 'cancelled']).default('open'),
  openedAt: z.string().optional().nullable(),
  closedAt: z.string().optional().nullable(),
  notes: z.string().max(5000).optional().nullable(),
});

export async function createRound(
  input: z.input<typeof roundCreateSchema>,
): Promise<RoundActionResult & { roundId?: string }> {
  try {
    await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }

  const parsed = roundCreateSchema.safeParse(input);
  if (!parsed.success) {
    return {
      ok: false,
      errorCode: 'validation',
      errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input',
    };
  }

  const supabase = await createSupabaseServerClient();

  // organization_id omitted on purpose -> DB default app.current_organization_id()
  const { data, error } = await supabase
    .schema('app')
    .from('rounds' as never)
    .insert({
      name: parsed.data.name.trim(),
      round_type: parsed.data.roundType?.trim() || null,
      target_amount: parsed.data.targetAmount ?? null,
      pre_money_valuation: parsed.data.preMoneyValuation ?? null,
      currency: parsed.data.currency.toUpperCase(),
      status: parsed.data.status,
      opened_at: parsed.data.openedAt || null,
      closed_at: parsed.data.closedAt || null,
      notes: parsed.data.notes?.trim() || null,
    } as never)
    .select('id')
    .single();

  if (error || !data) {
    return {
      ok: false,
      errorCode: 'database',
      errorMessage: error?.message ?? 'Insert failed',
    };
  }

  revalidatePath(INVESTOR_PIPELINE_PATH);
  return { ok: true, roundId: (data as { id: string }).id };
}

/* ============================================================
 * updateRound  (partial; no zod defaults so omitted fields are untouched)
 * ============================================================ */

const roundUpdateSchema = z.object({
  roundId: z.string().uuid(),
  name: z.string().min(1).max(120).optional(),
  roundType: z.string().max(60).optional().nullable(),
  targetAmount: z.number().min(0).max(1e15).optional().nullable(),
  preMoneyValuation: z.number().min(0).max(1e15).optional().nullable(),
  currency: z.string().length(3).optional(),
  status: z.enum(['open', 'closed', 'cancelled']).optional(),
  openedAt: z.string().optional().nullable(),
  closedAt: z.string().optional().nullable(),
  notes: z.string().max(5000).optional().nullable(),
});

export async function updateRound(
  input: z.input<typeof roundUpdateSchema>,
): Promise<RoundActionResult> {
  try {
    await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }

  const parsed = roundUpdateSchema.safeParse(input);
  if (!parsed.success) {
    return {
      ok: false,
      errorCode: 'validation',
      errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input',
    };
  }

  const d = parsed.data;
  const updates: Record<string, unknown> = {
    updated_at: new Date().toISOString(),
  };
  if (d.name !== undefined) updates.name = d.name.trim();
  if (d.roundType !== undefined) updates.round_type = d.roundType?.trim() || null;
  if (d.targetAmount !== undefined) updates.target_amount = d.targetAmount ?? null;
  if (d.preMoneyValuation !== undefined)
    updates.pre_money_valuation = d.preMoneyValuation ?? null;
  if (d.currency !== undefined) updates.currency = d.currency.toUpperCase();
  if (d.status !== undefined) updates.status = d.status;
  if (d.openedAt !== undefined) updates.opened_at = d.openedAt || null;
  if (d.closedAt !== undefined) updates.closed_at = d.closedAt || null;
  if (d.notes !== undefined) updates.notes = d.notes?.trim() || null;

  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('rounds' as never)
    .update(updates as never)
    .eq('id', parsed.data.roundId)
    .select('id')
    .maybeSingle();

  if (error)
    return { ok: false, errorCode: 'database', errorMessage: error.message };
  if (!data) return { ok: false, errorCode: 'not_found' };

  revalidatePath(INVESTOR_PIPELINE_PATH);
  return { ok: true };
}

/* ============================================================
 * deleteRound
 *   deals.round_id FK is ON DELETE SET NULL -> deleting a round detaches its
 *   deals (they revert to "no round") instead of cascading the deals.
 * ============================================================ */

export async function deleteRound(input: {
  roundId: string;
}): Promise<RoundActionResult> {
  try {
    await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }

  const parsed = z.object({ roundId: z.string().uuid() }).safeParse(input);
  if (!parsed.success) return { ok: false, errorCode: 'validation' };

  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('rounds' as never)
    .delete()
    .eq('id', parsed.data.roundId)
    .select('id')
    .maybeSingle();

  if (error)
    return { ok: false, errorCode: 'database', errorMessage: error.message };
  if (!data) return { ok: false, errorCode: 'not_found' };

  revalidatePath(INVESTOR_PIPELINE_PATH);
  return { ok: true };
}
