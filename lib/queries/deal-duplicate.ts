import type { SupabaseClient } from '@supabase/supabase-js';

// Columns that must never be carried into a duplicate.
const SKIP = ['id', 'created_at', 'updated_at'];

function stripRow(row: Record<string, unknown>): Record<string, unknown> {
  const out: Record<string, unknown> = { ...row };
  for (const k of SKIP) delete out[k];
  return out;
}

async function readDeal(
  supabase: SupabaseClient,
  organizationId: string,
  dealId: string,
): Promise<Record<string, unknown>> {
  const { data, error } = await supabase
    .schema('app')
    .from('deals' as never)
    .select('*')
    .eq('organization_id', organizationId)
    .eq('id', dealId)
    .single();
  if (error) throw error;
  return data as unknown as Record<string, unknown>;
}

// Single copy. Appends " (copy)" to the name unless you override it.
export async function duplicateDeal(
  supabase: SupabaseClient,
  organizationId: string,
  dealId: string,
  overrides: Record<string, unknown> = {},
) {
  const src = await readDeal(supabase, organizationId, dealId);
  const row = { ...stripRow(src), ...overrides };
  if (overrides.name === undefined && typeof row.name === 'string') {
    row.name = `${row.name} (copy)`;
  }

  const { data, error } = await supabase
    .schema('app')
    .from('deals' as never)
    .insert(row as never)
    .select('*')
    .single();
  if (error) throw error;
  return data;
}

// Clone one deal across many parties at once
// (e.g. same offer to 10 companies in a campaign).
// NOTE: confirm the FK column on deals -> 'party_id' below.
export async function duplicateDealForParties(
  supabase: SupabaseClient,
  organizationId: string,
  dealId: string,
  partyIds: string[],
  overrides: Record<string, unknown> = {},
) {
  if (partyIds.length === 0) return [];
  const src = await readDeal(supabase, organizationId, dealId);
  const base = stripRow(src);

  const rows = partyIds.map((pid) => ({
    ...base,
    ...overrides,
    party_id: pid,
  }));

  const { data, error } = await supabase
    .schema('app')
    .from('deals' as never)
    .insert(rows as never)
    .select('*');
  if (error) throw error;
  return data;
}
