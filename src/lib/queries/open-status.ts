// src/lib/queries/open-status.ts
// Server-only: fetch open/read tracking (email_tracking) for outbound messages.
// Source of truth for "Read time" display. Populated by the open-pixel route
// (api/track/open/[token]) today; later also importable from TABS Mailer DB.

import 'server-only';
import { createClient } from '@supabase/supabase-js';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { env } from '@/lib/env';

export interface OpenStatus {
  firstOpenedAt: string | null;
  openCount: number;
}

async function getSessionOrgId(): Promise<string | null> {
  const supabase = await createSupabaseServerClient();
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) return null;
  try {
    const payload = JSON.parse(
      Buffer.from(session.access_token.split('.')[1] ?? '', 'base64').toString(),
    );
    return (
      payload.organization_id ??
      payload.app_metadata?.organization_id ??
      null
    );
  } catch {
    return null;
  }
}

function makeAdminAppClient() {
  return createClient(
    env.NEXT_PUBLIC_SUPABASE_URL,
    env.SUPABASE_SERVICE_ROLE_KEY,
    { auth: { autoRefreshToken: false, persistSession: false }, db: { schema: 'app' } },
  );
}

function earliest(a: string | null, b: string | null): string | null {
  if (!a) return b;
  if (!b) return a;
  return a <= b ? a : b;
}

/**
 * Returns a map keyed by communication_id -> { firstOpenedAt, openCount }.
 * Aggregates across recipient rows (sum opens, earliest first-open).
 * Communications with no tracking row are simply absent from the map.
 */
export async function fetchOpenStatuses(
  communicationIds: string[],
): Promise<Record<string, OpenStatus>> {
  const out: Record<string, OpenStatus> = {};
  if (!communicationIds || communicationIds.length === 0) return out;

  const orgId = await getSessionOrgId();
  if (!orgId) return out;

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const client = makeAdminAppClient().from('email_tracking') as any;
  const { data, error } = await client
    .select('communication_id, first_opened_at, open_count')
    .eq('organization_id', orgId)
    .in('communication_id', communicationIds);

  if (error || !data) return out;

  for (const row of data as Array<{
    communication_id: string | null;
    first_opened_at: string | null;
    open_count: number | null;
  }>) {
    const cid = row.communication_id;
    if (!cid) continue;
    const oc = row.open_count ?? 0;
    const prev = out[cid];
    if (!prev) {
      out[cid] = { firstOpenedAt: row.first_opened_at, openCount: oc };
    } else {
      out[cid] = {
        firstOpenedAt: earliest(prev.firstOpenedAt, row.first_opened_at),
        openCount: prev.openCount + oc,
      };
    }
  }
  return out;
}
