/**
 * components/providers/realtime-provider.tsx
 * Phase 22b: inbox unread + open tasks count
 */

'use client';

import { useEffect, useRef } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import { toast } from 'sonner';
import { useTranslations } from 'next-intl';
import { createSupabaseBrowserClient } from '@/lib/supabase/client';
import { useUiStore } from '@/lib/stores/ui-store';

interface Props {
  organizationId: string;
  initialPendingCount: number;
  initialInboxUnreadCount?: number;
  initialOpenTaskCount?: number;
}

interface DraftRow {
  id: string;
  status: string;
  organization_id: string;
  classification_category?: string | null;
  confidence_score?: number | null;
}

export function RealtimeProvider({
  organizationId,
  initialPendingCount,
  initialInboxUnreadCount = 0,
  initialOpenTaskCount = 0,
}: Props) {
  const setCount = useUiStore((s) => s.setPendingDraftCount);
  const increment = useUiStore((s) => s.incrementPendingDraftCount);
  const decrement = useUiStore((s) => s.decrementPendingDraftCount);
  const notificationsEnabled = useUiStore((s) => s.notificationsEnabled);
  const setInboxUnreadCount = useUiStore((s) => s.setInboxUnreadCount);
  const inboxUnreadCount = useUiStore((s) => s.inboxUnreadCount);
  const setOpenTaskCount = useUiStore((s) => s.setOpenTaskCount);
  const t = useTranslations('realtime');
  const router = useRouter();
  const pathname = usePathname();
  const pathnameRef = useRef(pathname);
  pathnameRef.current = pathname;

  // Server-component refresh helper - only refresh on relevant routes
  // inbox events: /inbox, /sent, /inbox/[id]
  // drafts events: /drafts, /drafts/[id], or inbox-detail (which embeds drafts)
  const refreshIfRelevant = (target: 'inbox' | 'drafts') => {
    const p = pathnameRef.current;
    const onInbox = p === '/inbox' || p === '/sent' || p.startsWith('/inbox/');
    const onDrafts = p === '/drafts' || p.startsWith('/drafts/');
    if (target === 'inbox' && onInbox) router.refresh();
    if (target === 'drafts' && (onDrafts || onInbox)) router.refresh();
  };

  const setRef = useRef(setCount);
  setRef.current = setCount;
  useEffect(() => { setRef.current(initialPendingCount); }, [initialPendingCount]);

  const setInboxRef = useRef(setInboxUnreadCount);
  setInboxRef.current = setInboxUnreadCount;
  useEffect(() => { setInboxRef.current(initialInboxUnreadCount); }, [initialInboxUnreadCount]);

  const setTaskRef = useRef(setOpenTaskCount);
  setTaskRef.current = setOpenTaskCount;
  useEffect(() => { setTaskRef.current(initialOpenTaskCount); }, [initialOpenTaskCount]);

  // ── communications 변경 구독 (soft-delete 시 inbox 카운트 감소) ──────────
  const inboxCountRef = useRef(inboxUnreadCount);
  inboxCountRef.current = inboxUnreadCount;

  useEffect(() => {
    const supabase = createSupabaseBrowserClient();
    const channel = supabase
      .channel(`communications:org-${organizationId}`)
      .on('postgres_changes' as never,
        {
          event: 'UPDATE',
          schema: 'app',
          table: 'communications',
          filter: `organization_id=eq.${organizationId}`,
        },
        (payload: { new: Record<string, unknown>; old: Record<string, unknown> }) => {
          const n = payload.new ?? {};
          const o = payload.old ?? {};
          const isInbound = n.direction === 'inbound';
          const newDeleted = !!n.deleted_at;
          const oldDeleted = !!o.deleted_at;
          const newUnread = !n.read_at; // read_at is always present on the new row

          if (isInbound) {
            // an UNREAD inbound message was soft-deleted -> leaves the unread set
            if (!oldDeleted && newDeleted && newUnread) {
              setInboxUnreadCount(Math.max(0, inboxCountRef.current - 1));
            // an UNREAD inbound message was restored -> re-enters the unread set
            } else if (oldDeleted && !newDeleted && newUnread) {
              setInboxUnreadCount(inboxCountRef.current + 1);
            }
          }
          // read/unread toggles change list emphasis AND the exact count; rather than
          // do fragile optimistic math, let the (app) layout recompute the authoritative
          // count on router.refresh() -> it re-runs and pushes initialInboxUnreadCount.
          refreshIfRelevant('inbox');
        },
      )
      .on('postgres_changes' as never,
        {
          event: 'INSERT',
          schema: 'app',
          table: 'communications',
          filter: `organization_id=eq.${organizationId}`,
        },
        (payload: { new: Record<string, unknown> }) => {
          const n = payload.new ?? {};
          // Only inbound + unread bumps the badge. (Previously every insert did,
          // which wrongly counted outbound/sent mail as unread.)
          if (n.direction === 'inbound' && !n.read_at) {
            setInboxUnreadCount(inboxCountRef.current + 1);
          }
          refreshIfRelevant('inbox');
        },
      )
      .subscribe();
    return () => { supabase.removeChannel(channel); };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [organizationId]);

  // ── drafts 변경 구독 ────────────────────────────────────────────────────
  useEffect(() => {
    const supabase = createSupabaseBrowserClient();
    const channel = supabase
      .channel(`drafts:org-${organizationId}`)
      .on('postgres_changes' as never,
        { event: 'INSERT', schema: 'ai', table: 'drafts', filter: `organization_id=eq.${organizationId}` },
        (payload: { new: DraftRow }) => {
          const next = payload.new;
          if (next.status === 'pending_review') {
            increment();
            toast.info(t('newDraft'), { duration: 4000 });
            if (notificationsEnabled && typeof window !== 'undefined' && 'Notification' in window && Notification.permission === 'granted') {
              try { new Notification(t('newDraftTitle'), { body: t('newDraftBody'), tag: `draft-${next.id}` }); } catch { /* ignore */ }
            }
          }
          refreshIfRelevant('drafts');
        },
      )
      .on('postgres_changes' as never,
        { event: 'UPDATE', schema: 'ai', table: 'drafts', filter: `organization_id=eq.${organizationId}` },
        (payload: { new: DraftRow; old: DraftRow }) => {
          const before = payload.old?.status;
          const after = payload.new?.status;
          if (before === 'pending_review' && after !== 'pending_review') decrement();
          if (before !== 'pending_review' && after === 'pending_review') increment();
          refreshIfRelevant('drafts');
        },
      )
      .subscribe();
    return () => { supabase.removeChannel(channel); };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [organizationId]);

  return null;
}