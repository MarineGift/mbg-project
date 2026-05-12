/**
 * lib/stores/ui-store.ts
 *
 * 페이지 간 공유되는 UI 상태 (Zustand).
 *
 * 원칙:
 *   - 비즈니스 데이터는 절대 저장하지 않음 (TanStack Query가 담당)
 *   - 페이지를 거쳐 유지되어야 하는 UI 상태만 (사이드바, 선택 등)
 *   - cookie/localStorage 영속화는 명시적으로만 (PII 위험 회피)
 */

'use client';

import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';

export type DraftQueueViewMode = 'compact' | 'comfortable';
export type EngagementViewMode = 'kanban' | 'list';

interface UiState {
  // ── 사이드바 ────────────────────────────────────────────
  sidebarCollapsed: boolean;
  toggleSidebar: () => void;
  setSidebarCollapsed: (collapsed: boolean) => void;

  // ── 초안 큐 ────────────────────────────────────────────
  draftQueueViewMode: DraftQueueViewMode;
  setDraftQueueViewMode: (mode: DraftQueueViewMode) => void;

  /** 큐에서 다중 선택한 초안 ID들 (일괄 승인용). 페이지 이동 시 초기화. */
  selectedDraftIds: Set<string>;
  toggleDraftSelection: (id: string) => void;
  selectAllDrafts: (ids: string[]) => void;
  clearDraftSelection: () => void;

  // ── 인게이지먼트 ─────────────────────────────────────────
  engagementViewMode: EngagementViewMode;
  setEngagementViewMode: (mode: EngagementViewMode) => void;

  // ── 키보드 단축키 활성 여부 (포커스 충돌 방지) ─────────
  keyboardShortcutsEnabled: boolean;
  setKeyboardShortcutsEnabled: (enabled: boolean) => void;

  // ── Browser Notification opt-in (Q9 기본 off) ────────
  notificationsEnabled: boolean;
  setNotificationsEnabled: (enabled: boolean) => void;

  // ── Realtime 카운트 (사이드바 뱃지) ─────────────────
  pendingDraftCount: number;
  setPendingDraftCount: (n: number) => void;
  incrementPendingDraftCount: () => void;
  decrementPendingDraftCount: () => void;
}

export const useUiStore = create<UiState>()(
  persist(
    (set) => ({
      // 사이드바 (영속)
      sidebarCollapsed: false,
      toggleSidebar: () =>
        set((s) => ({ sidebarCollapsed: !s.sidebarCollapsed })),
      setSidebarCollapsed: (collapsed) => set({ sidebarCollapsed: collapsed }),

      // 큐 뷰 모드 (영속)
      draftQueueViewMode: 'comfortable',
      setDraftQueueViewMode: (mode) => set({ draftQueueViewMode: mode }),

      // 큐 선택 (휘발성 — partialize에서 제외)
      selectedDraftIds: new Set<string>(),
      toggleDraftSelection: (id) =>
        set((s) => {
          const next = new Set(s.selectedDraftIds);
          if (next.has(id)) {
            next.delete(id);
          } else {
            next.add(id);
          }
          return { selectedDraftIds: next };
        }),
      selectAllDrafts: (ids) =>
        set({ selectedDraftIds: new Set(ids) }),
      clearDraftSelection: () =>
        set({ selectedDraftIds: new Set<string>() }),

      // 인게이지먼트 뷰 (영속)
      engagementViewMode: 'kanban',
      setEngagementViewMode: (mode) => set({ engagementViewMode: mode }),

      // 키보드 단축키 (휘발성)
      keyboardShortcutsEnabled: true,
      setKeyboardShortcutsEnabled: (enabled) =>
        set({ keyboardShortcutsEnabled: enabled }),

      // Browser Notification (영속)
      notificationsEnabled: false,
      setNotificationsEnabled: (enabled) =>
        set({ notificationsEnabled: enabled }),

      // Pending draft count (휘발성 — Realtime이 갱신, 새로고침 시 서버에서 다시 fetch)
      pendingDraftCount: 0,
      setPendingDraftCount: (n) => set({ pendingDraftCount: Math.max(0, n) }),
      incrementPendingDraftCount: () =>
        set((s) => ({ pendingDraftCount: s.pendingDraftCount + 1 })),
      decrementPendingDraftCount: () =>
        set((s) => ({ pendingDraftCount: Math.max(0, s.pendingDraftCount - 1) })),
    }),
    {
      name: 'urm-ui-state',
      storage: createJSONStorage(() => localStorage),
      // 영속화 필드만 선택 — Set은 JSON.stringify에서 빈 객체가 되므로 제외 필수
      partialize: (state) => ({
        sidebarCollapsed: state.sidebarCollapsed,
        draftQueueViewMode: state.draftQueueViewMode,
        engagementViewMode: state.engagementViewMode,
        notificationsEnabled: state.notificationsEnabled,
      }),
    },
  ),
);
