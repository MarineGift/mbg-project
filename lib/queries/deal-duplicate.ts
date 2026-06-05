import type { SupabaseClient } from '@supabase/supabase-js';

// Never carried into a duplicate.
const SKIP = ['id', 'created_at', 'updated_at', 'deleted_at'];

function stripRow(row: Record<string, unknown>): Record<string, unknown> {
  const out: Record<string, unknown> = { ...row };
  for (const k of SKIP) delete out[k];
  return out;
}

async function readDeal(
  supabase: SupabaseClient, organizationId: string, dealId: string,
): Promise<Record<string, unknown>> {
  const { data, error } = await supabase.schema('app').from('deals' as never)
    .select('*').eq('organization_id', organizationId).eq('id', dealId).single();
  if (error) throw error;
  return data as unknown as Record<string, unknown>;
}

// Single copy. Appends " (copy)" to deal_name unless overridden.
export async function duplicateDeal(
  supabase: SupabaseClient, organizationId: string, dealId: string,
  overrides: Record<string, unknown> = {},
) {
  const src = await readDeal(supabase, organizationId, dealId);
  const row = { ...stripRow(src), ...overrides };
  if (overrides.deal_name === undefined && typeof row.deal_name === 'string') {
    row.deal_name = `${row.deal_name} (copy)`;
  }
  const { data, error } = await supabase.schema('app').from('deals' as never)
    .insert(row as never).select('*').single();
  if (error) throw error;
  return data;
}

// Clone one deal across many parties (same offer to N companies in a campaign).
export async function duplicateDealForParties(
  supabase: SupabaseClient, organizationId: string, dealId: string,
  partyIds: string[], overrides: Record<string, unknown> = {},
) {
  if (partyIds.length === 0) return [];
  const src = await readDeal(supabase, organizationId, dealId);
  const base = stripRow(src);
  const rows = partyIds.map((pid) => ({ ...base, ...overrides, party_id: pid }));
  const { data, error } = await supabase.schema('app').from('deals' as never)
    .insert(rows as never).select('*');
  if (error) throw error;
  return data;
}
