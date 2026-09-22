'use server';
/**
 * lib/actions/email-blocklist.ts
 *
 * Do-not-send (suppression / unsubscribe) list CRUD. Reuses the email_whitelist
 * shape (pattern + kind + is_active) on a SEPARATE table app.email_blocklist so
 * the deny semantics stay airtight (a missing list_type filter on a shared table
 * could let an unsubscribed address through).
 *
 * Direct table access (no RPC) under RLS: pol_email_blocklist_* scope every row
 * to organization_id = app.current_organization_id(). Workers use the service
 * role and bypass RLS. Mirrors the direct-access style of registerAddressEntry.
 */
import { requireAuth } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { revalidatePath } from 'next/cache';

export type BlocklistKind = 'address' | 'domain' | 'regex';

export type BlocklistEntry = {
  id: string;
  pattern: string;
  kind: string;
  reason: string | null;
  notes: string | null;
  is_active: boolean;
  created_at: string;
};

const PATH = '/settings/email-blocklist';

export async function listBlocklist(): Promise<BlocklistEntry[]> {
  let auth;
  try {
    auth = await requireAuth();
  } catch {
    return [];
  }
  const sb = await createSupabaseServerClient();
  const { data, error } = await sb
    .schema('app')
    .from('email_blocklist' as never)
    .select('id, pattern, kind, reason, notes, is_active, created_at')
    .eq('organization_id', auth.organizationId)
    .order('created_at', { ascending: false });
  if (error) return [];
  return (data ?? []) as unknown as BlocklistEntry[];
}

export async function addBlocklistEntry(
  pattern: string,
  kind: BlocklistKind,
  reason?: string,
  notes?: string,
): Promise<{ ok: boolean; error?: string }> {
  let auth;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, error: 'Unauthorized' };
  }
  const p = (pattern ?? '').trim().toLowerCase();
  if (!p) return { ok: false, error: 'empty' };
  if (kind === 'domain' && p.includes('@')) return { ok: false, error: 'Enter the domain without @' };
  if (kind === 'address' && !p.includes('@')) return { ok: false, error: 'Enter the address including @' };
  if (kind === 'regex') {
    try {
      new RegExp(pattern);
    } catch {
      return { ok: false, error: 'Invalid regular expression' };
    }
  }

  const sb = await createSupabaseServerClient();
  const { error } = await sb
    .schema('app')
    .from('email_blocklist' as never)
    .insert({
      organization_id: auth.organizationId,
      pattern: p,
      kind,
      reason: reason?.trim() || null,
      notes: notes?.trim() || null,
      is_active: true,
      created_by: auth.userId,
    } as never);
  if (error) {
    if (/duplicate|unique|already|exists/i.test(error.message)) {
      return { ok: false, error: 'That pattern is already on the list.' };
    }
    return { ok: false, error: error.message };
  }
  revalidatePath(PATH);
  return { ok: true };
}

export async function toggleBlocklistEntry(
  id: string,
  active: boolean,
): Promise<{ ok: boolean; error?: string }> {
  let auth;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, error: 'Unauthorized' };
  }
  const sb = await createSupabaseServerClient();
  const { error } = await sb
    .schema('app')
    .from('email_blocklist' as never)
    .update({ is_active: active } as never)
    .eq('id', id)
    .eq('organization_id', auth.organizationId);
  if (error) return { ok: false, error: error.message };
  revalidatePath(PATH);
  return { ok: true };
}

export async function deleteBlocklistEntry(id: string): Promise<{ ok: boolean; error?: string }> {
  let auth;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, error: 'Unauthorized' };
  }
  const sb = await createSupabaseServerClient();
  const { error } = await sb
    .schema('app')
    .from('email_blocklist' as never)
    .delete()
    .eq('id', id)
    .eq('organization_id', auth.organizationId);
  if (error) return { ok: false, error: error.message };
  revalidatePath(PATH);
  return { ok: true };
}

/* ============================================================
 * 2026-09-21: compose-time release (reply to an auto-suppressed address)
 * ============================================================ */

export type BlocklistMatch = {
  id: string;
  pattern: string;
  kind: string;
  reason: string | null;
  notes: string | null;
};

/** Active blocklist rows that match this address (address / domain / regex). */
export async function findBlocklistMatches(
  email: string,
): Promise<{ ok: true; matches: BlocklistMatch[] } | { ok: false; error: string }> {
  let auth;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, error: 'Unauthorized' };
  }
  const e = (email ?? '').trim().toLowerCase();
  const domain = e.split('@')[1] ?? '';
  const sb = await createSupabaseServerClient();
  const { data, error } = await sb
    .schema('app')
    .from('email_blocklist' as never)
    .select('id, pattern, kind, reason, notes')
    .eq('organization_id', auth.organizationId)
    .eq('is_active', true);
  if (error) return { ok: false, error: error.message };
  const matches = ((data ?? []) as unknown as BlocklistMatch[]).filter((r) => {
    const p = (r.pattern ?? '').trim().toLowerCase();
    if (r.kind === 'address') return p === e;
    if (r.kind === 'domain') return p === domain;
    if (r.kind === 'regex') {
      try { return new RegExp(r.pattern, 'i').test(e); } catch { return false; }
    }
    return false;
  });
  return { ok: true, matches };
}

/**
 * Deactivate (not delete - history kept) the ADDRESS-kind rows for this email.
 * Domain / regex rules are left alone on purpose: they cover more than one
 * person and must be changed in Settings > Email blocklist.
 */
export async function releaseBlocklistAddress(
  email: string,
): Promise<{ ok: boolean; released: number; remaining: number; error?: string }> {
  const found = await findBlocklistMatches(email);
  if (!found.ok) return { ok: false, released: 0, remaining: 0, error: found.error };
  const addressIds = found.matches.filter((m) => m.kind === 'address').map((m) => m.id);
  const remaining = found.matches.length - addressIds.length;
  if (addressIds.length === 0) return { ok: true, released: 0, remaining };

  const auth = await requireAuth();
  const sb = await createSupabaseServerClient();
  const stamp = new Date().toISOString().slice(0, 10);
  for (const m of found.matches.filter((x) => x.kind === 'address')) {
    const { error } = await sb
      .schema('app')
      .from('email_blocklist' as never)
      .update({
        is_active: false,
        notes: `${m.notes ? m.notes + ' | ' : ''}released from reply ${stamp}`.slice(0, 500),
      } as never)
      .eq('id', m.id)
      .eq('organization_id', auth.organizationId);
    if (error) return { ok: false, released: 0, remaining, error: error.message };
  }
  revalidatePath(PATH);
  return { ok: true, released: addressIds.length, remaining };
}
