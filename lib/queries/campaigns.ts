import type { SupabaseClient } from '@supabase/supabase-js';

// --- types ---------------------------------------------------
export type CampaignStatus = 'active' | 'closed' | 'archived';

export type Campaign = {
  id: string;
  organization_id: string;
  name: string;
  campaign_type: string | null; // 'filler_sales' | 'fundraising' | ... (free text)
  description: string | null;
  status: CampaignStatus;
  start_date: string | null;
  end_date: string | null;
  color: string | null;
  created_at: string;
  updated_at: string;
};

export type NewCampaignInput = {
  name: string;
  campaign_type?: string | null;
  description?: string | null;
  status?: CampaignStatus;
  start_date?: string | null;
  end_date?: string | null;
  color?: string | null;
};

// `as never` on the table name is the documented app-schema cast,
// needed until database.ts is regenerated to include app.campaigns.
const TABLE = 'campaigns' as never;

// --- reads ---------------------------------------------------
export async function listCampaigns(
  supabase: SupabaseClient,
  organizationId: string,
  opts?: { activeOnly?: boolean },
): Promise<Campaign[]> {
  let q = supabase
    .schema('app')
    .from(TABLE)
    .select('*')
    .eq('organization_id', organizationId);

  if (opts?.activeOnly) q = q.eq('status', 'active');

  const { data, error } = await q.order('created_at', { ascending: false });
  if (error) throw error;
  return (data ?? []) as unknown as Campaign[];
}

export async function getCampaign(
  supabase: SupabaseClient,
  organizationId: string,
  id: string,
): Promise<Campaign | null> {
  const { data, error } = await supabase
    .schema('app')
    .from(TABLE)
    .select('*')
    .eq('organization_id', organizationId)
    .eq('id', id)
    .maybeSingle();
  if (error) throw error;
  return (data ?? null) as unknown as Campaign | null;
}

// --- writes --------------------------------------------------
export async function createCampaign(
  supabase: SupabaseClient,
  organizationId: string,
  input: NewCampaignInput,
): Promise<Campaign> {
  const row = {
    organization_id: organizationId,
    name: input.name,
    campaign_type: input.campaign_type ?? null,
    description: input.description ?? null,
    status: input.status ?? 'active',
    start_date: input.start_date ?? null,
    end_date: input.end_date ?? null,
    color: input.color ?? null,
  };

  const { data, error } = await supabase
    .schema('app')
    .from(TABLE)
    .insert(row as never)
    .select('*')
    .single();
  if (error) throw error;
  return data as unknown as Campaign;
}

export async function updateCampaign(
  supabase: SupabaseClient,
  organizationId: string,
  id: string,
  patch: Partial<NewCampaignInput>,
): Promise<Campaign> {
  const { data, error } = await supabase
    .schema('app')
    .from(TABLE)
    .update(patch as never)
    .eq('organization_id', organizationId)
    .eq('id', id)
    .select('*')
    .single();
  if (error) throw error;
  return data as unknown as Campaign;
}

// --- deal linking helpers -----------------------------------
// NOTE: swap 'deals' to 'engagements' if that is your canonical table.
const DEALS_TABLE = 'deals' as never;

export async function setDealCampaign(
  supabase: SupabaseClient,
  organizationId: string,
  dealId: string,
  campaignId: string | null,
): Promise<void> {
  const { error } = await supabase
    .schema('app')
    .from(DEALS_TABLE)
    .update({ campaign_id: campaignId } as never)
    .eq('organization_id', organizationId)
    .eq('id', dealId);
  if (error) throw error;
}
