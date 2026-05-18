// src/lib/queries/communications.ts
// ============================================================
// Phase 22a — Communications data access
// ============================================================
import { createSupabaseServerClient } from "@/lib/supabase/server";
import type {
  CommunicationTimelineItem,
  PartyCommunicationStats,
  ThreadContext,
  TemplateForCompose,
} from "@/types/phase22a";

export async function getPartyCommunicationsTimeline(
  partyId: string,
  limit = 100
): Promise<CommunicationTimelineItem[]> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.rpc(
    "get_party_communications_timeline",
    { p_party_id: partyId, p_limit: limit }
  );
  if (error) {
    console.error("[getPartyCommunicationsTimeline]", error);
    return [];
  }
  return (data || []) as CommunicationTimelineItem[];
}

export async function getContactCommunicationsTimeline(
  contactId: string,
  limit = 100
): Promise<CommunicationTimelineItem[]> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.rpc(
    "get_contact_communications_timeline",
    { p_contact_id: contactId, p_limit: limit }
  );
  if (error) {
    console.error("[getContactCommunicationsTimeline]", error);
    return [];
  }
  return (data || []) as CommunicationTimelineItem[];
}

export async function getPartyCommunicationStats(
  partyId: string
): Promise<PartyCommunicationStats> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.rpc(
    "get_communications_stats_per_party",
    { p_party_id: partyId }
  );
  if (error) {
    console.error("[getPartyCommunicationStats]", error);
    return { total: 0, sent: 0, received: 0, opened: 0, replied: 0, threads: 0 };
  }
  const row = (data?.[0] || {}) as Partial<PartyCommunicationStats>;
  return {
    total: row.total ?? 0,
    sent: row.sent ?? 0,
    received: row.received ?? 0,
    opened: row.opened ?? 0,
    replied: row.replied ?? 0,
    threads: row.threads ?? 0,
  };
}

export async function getThreadContext(
  communicationId: string
): Promise<ThreadContext | null> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.rpc("get_thread_context", {
    p_communication_id: communicationId,
  });
  if (error) {
    console.error("[getThreadContext]", error);
    return null;
  }
  return data as ThreadContext;
}

export async function listTemplatesForCompose(
  orgId: string,
  module?: string
): Promise<TemplateForCompose[]> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.rpc("list_templates_for_compose", {
    p_org_id: orgId,
    p_module: module ?? null,
  });
  if (error) {
    console.error("[listTemplatesForCompose]", error);
    return [];
  }
  return (data || []) as TemplateForCompose[];
}

// ── Inbox detail page ──────────────────────────────────────────────────────
export async function fetchCommunicationDetail(id: string) {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema("app")
    .from("communications")
    .select(`
      *,
      party:parties(id, name, module),
      contact:contacts(id, given_name, family_name, email, role_title)
    `)
    .eq("id", id)
    .is("deleted_at", null)
    .single();
  if (error || !data) return null;
  return data;
}

// ── Thread grouping utilities ──────────────────────────────────────────────
export function groupByThread(
  items: CommunicationTimelineItem[]
): Map<string, CommunicationTimelineItem[]> {
  const map = new Map<string, CommunicationTimelineItem[]>();
  for (const item of items) {
    const key = item.thread_id || item.message_id || item.id;
    const existing = map.get(key) || [];
    existing.push(item);
    map.set(key, existing);
  }
  for (const [key, arr] of map) {
    arr.sort((a, b) => a.occurred_at.localeCompare(b.occurred_at));
    map.set(key, arr);
  }
  return map;
}

export function sortThreadsByRecency(
  threads: Map<string, CommunicationTimelineItem[]>
): Array<[string, CommunicationTimelineItem[]]> {
  const entries = Array.from(threads.entries());
  entries.sort(([, a], [, b]) => {
    const aLatest = a[a.length - 1]?.occurred_at || "";
    const bLatest = b[b.length - 1]?.occurred_at || "";
    return bLatest.localeCompare(aLatest);
  });
  return entries;
}

// ── Phase 22b: markCommunicationRead ─────────────────────────────────
// Safe no-op if read_at column does not exist yet
export async function markCommunicationRead(id: string): Promise<void> {
  try {
    const supabase = await createSupabaseServerClient();
    await supabase
      .schema('app')
      .from('communications')
      .update({ read_at: new Date().toISOString() } as any)
      .eq('id', id);
  } catch (_) {
    // Silently ignore — read_at column may not exist until SQL migration runs
  }
}

// ── Phase 22b: getUnreadCount ─────────────────────────────────────────
export async function getUnreadCount(): Promise<number> {
  try {
    const supabase = await createSupabaseServerClient();
    const { count } = await supabase
      .schema('app')
      .from('communications')
      .select('id', { count: 'exact', head: true })
      .is('read_at' as any, null)
      .eq('direction', 'inbound');
    return count ?? 0;
  } catch (_) {
    return 0;
  }
}
