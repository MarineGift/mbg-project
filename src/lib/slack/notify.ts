// src/lib/slack/notify.ts
//
// Outbound: push a URM event into the org's Slack channel via its configured
// Incoming Webhook. Safe to call from server code (server actions, workers).
// Never throws - returns false on any failure so callers don't break.
//
// Usage:
//   import { notifySlack } from '@/lib/slack/notify';
//   await notifySlack(orgId, `New deal created: ${deal.name}`);
//
// NOTE: new tables (slack_integrations) aren't in the generated Database types
// yet, so the admin client is used loosely here. Regenerate types when convenient.

import { createSupabaseAdminClient } from '@/lib/supabase/admin';

export async function notifySlack(organizationId: string, text: string): Promise<boolean> {
  if (!organizationId || !text) return false;

  const db = createSupabaseAdminClient() as any;

  const { data, error } = await db
    .schema('app')
    .from('slack_integrations')
    .select('webhook_url, enabled')
    .eq('organization_id', organizationId)
    .eq('enabled', true)
    .not('webhook_url', 'is', null)
    .limit(1)
    .maybeSingle();

  if (error || !data?.webhook_url) return false;

  try {
    const res = await fetch(data.webhook_url as string, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text }),
    });
    return res.ok;
  } catch {
    return false;
  }
}
