import type { SupabaseClient } from '@supabase/supabase-js';
import type { TimelineItem } from '@/components/timeline/timeline-types'; // adjust alias

// Reads from the app.deal_forecast view (extended with name/dates), so one
// query gives dates + effective_probability (= progress) + won/lost flags.
export type DealTimelineRow = {
  id: string;
  name: string | null;
  start_date: string | null;
  end_date: string | null;
  stage_id: string | null;
  campaign_id: string | null;
  amount: number | null;
  effective_probability: number | null;
  is_won: boolean;
  is_lost: boolean;
};

export async function getDealsTimeline(
  supabase: SupabaseClient,
  organizationId: string,
  opts?: { campaignId?: string },
): Promise<DealTimelineRow[]> {
  let q = supabase
    .schema('app')
    .from('deal_forecast' as never)
    .select('id, name, start_date, end_date, stage_id, campaign_id, amount, effective_probability, is_won, is_lost')
    .eq('organization_id', organizationId)
    .not('start_date', 'is', null);
  if (opts?.campaignId) q = q.eq('campaign_id', opts.campaignId);
  const { data, error } = await q.order('start_date', { ascending: true });
  if (error) throw error;
  return (data ?? []) as unknown as DealTimelineRow[];
}

// Writes go to the base table (views are read-only).
export async function setDealDates(
  supabase: SupabaseClient,
  organizationId: string,
  dealId: string,
  startDate: string | null,
  endDate: string | null,
): Promise<void> {
  const { error } = await supabase
    .schema('app')
    .from('deals' as never)
    .update({ start_date: startDate, end_date: endDate } as never)
    .eq('organization_id', organizationId)
    .eq('id', dealId);
  if (error) throw error;
}

// Map deal rows -> shared TimelineItem.
//   progress: won => 100, lost => 0, else effective_probability
//   lost deals default to a muted grey unless you pass a color.
export function dealRowsToItems(
  rows: DealTimelineRow[],
  opts?: { color?: (r: DealTimelineRow) => string | undefined; href?: (r: DealTimelineRow) => string },
): TimelineItem[] {
  return rows
    .filter((r) => r.start_date && r.end_date)
    .map((r) => ({
      id: r.id,
      label: r.name ?? '(untitled)',
      start: r.start_date as string,
      end: r.end_date as string,
      progress: r.is_won ? 100 : r.is_lost ? 0 : Number(r.effective_probability ?? 0),
      color: opts?.color?.(r) ?? (r.is_lost ? '#94a3b8' : undefined),
      href: opts?.href?.(r),
    }));
}
