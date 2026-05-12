/**
 * components/providers/realtime-provider.tsx
 *
 * Supabase Realtime 구독 — 전역 App shell에서 1회 mount.
 *
 * 구독:
 *   - ai.drafts (organization_id 필터) — INSERT/UPDATE/DELETE 감지하여 큐 카운트 갱신
 *
 * 변경 시 router.refresh()를 호출하지 않음 (페이지마다 너무 자주 일어남).
 * 대신 Zustand의 pendingDraftCount만 갱신하고 사이드바 배지로 노출.
 * 새 초안 도착 시 notificationsEnabled이면 Browser Notification.
 */

'use client';

import { useEffect, useRef } from 'react';
import { toast } from 'sonner';
import { useTranslations } from 'next-intl';
import { createSupabaseBrowserClient } from '@/lib/supabase/client';
import { useUiStore } from '@/lib/stores/ui-store';

interface Props {
  organizationId: string;
  /** SSR fetch 직후의 pending_review draft 카운트 — 초기값 */
  initialPendingCount: number;
}

interface DraftRow {
  id: string;
  status: string;
  organization_id: string;
  classification_category?: string | null;
  confidence_score?: number | null;
}

export function RealtimeProvider({ organizationId, initialPendingCount }: Props) {
  const setCount = useUiStore((s) => s.setPendingDraftCount);
  const increment = useUiStore((s) => s.incrementPendingDraftCount);
  const decrement = useUiStore((s) => s.decrementPendingDraftCount);
  const notificationsEnabled = useUiStore((s) => s.notificationsEnabled);
  const t = useTranslations('realtime');

  // 초기 카운트 SSR에서 받아 store에 반영
  const setRef = useRef(setCount);
  setRef.current = setCount;
  useEffect(() => {
    setRef.current(initialPendingCount);
  }, [initialPendingCount]);

  useEffect(() => {
    const supabase = createSupabaseBrowserClient();
    const channel = supabase
      .channel(`drafts:org-${organizationId}`)
      .on(
        'postgres_changes' as never,
        {
          event: 'INSERT',
          schema: 'ai',
          table: 'drafts',
          filter: `organization_id=eq.${organizationId}`,
        },
        (payload: { new: DraftRow }) => {
          const next = payload.new;
          if (next.status === 'pending_review') {
            increment();
            toast.info(t('newDraft'), { duration: 4000 });
            // Browser Notification (opt-in)
            if (
              notificationsEnabled &&
              typeof window !== 'undefined' &&
              'Notification' in window &&
              Notification.permission === 'granted'
            ) {
              try {
                new Notification(t('newDraftTitle'), {
                  body: t('newDraftBody'),
                  tag: `draft-${next.id}`,
                });
              } catch {
                // permission revoked between checks — ignore
              }
            }
          }
        },
      )
      .on(
        'postgres_changes' as never,
        {
          event: 'UPDATE',
          schema: 'ai',
          table: 'drafts',
          filter: `organization_id=eq.${organizationId}`,
        },
        (payload: { new: DraftRow; old: DraftRow }) => {
          const before = payload.old?.status;
          const after = payload.new?.status;
          // pending_review → 다른 상태 (승인·거부·만료·자동발송): 카운트 감소
          if (before === 'pending_review' && after !== 'pending_review') {
            decrement();
          }
          // 다른 상태 → pending_review (드물지만 가능): 증가
          if (before !== 'pending_review' && after === 'pending_review') {
            increment();
          }
        },
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
    // organizationId가 바뀌면 (조직 전환 — Phase 1 미지원이지만 안전망) 재구독
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [organizationId]);

  return null;
}
