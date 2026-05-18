/**
 * lib/stores/ui-store.ts
 * Phase 22b: inboxUnreadCount + openTaskCount 추가
 */

'use client';

import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';

export type DraftQueueViewMode = 'compact' | 'comfortable';
export type EngagementViewMode = 'kanban' | 'list';

interface UiState {
  sidebarCollapsed: boolean;
  toggleSidebar: () => void;
  setSidebarCollapsed: (collapsed: boolean) => void;

  draftQueueViewMode: DraftQueueViewMode;
  setDraftQueueViewMode: (mode: DraftQueueViewMode) => void;

  selectedDraftIds: Set<string>;
  toggleDraftSelection: (id: string) => void;
  selectAllDrafts: (ids: string[]) => void;
  clearDraftSelection: () => void;

  engagementViewMode: EngagementViewMode;
  setEngagementViewMode: (mode: EngagementViewMode) => void;

  keyboardShortcutsEnabled: boolean;
  setKeyboardShortcutsEnabled: (enabled: boolean) => void;

  notificationsEnabled: boolean;
  setNotificationsEnabled: (enabled: boolean) => void;

  // Realtime badges
  pendingDraftCount: number;
  setPendingDraftCount: (n: number) => void;
  incrementPendingDraftCount: () => void;
  decrementPendingDraftCount: () => void;

  inboxUnreadCount: number;
  setInboxUnreadCount: (n: number) => void;

  openTaskCount: number;
  setOpenTaskCount: (n: number) => void;
}

export const useUiStore = create<UiState>()(
  persist(
    (set) => ({
      sidebarCollapsed: false,
      toggleSidebar: () => set((s) => ({ sidebarCollapsed: !s.sidebarCollapsed })),
      setSidebarCollapsed: (collapsed) => set({ sidebarCollapsed: collapsed }),

      draftQueueViewMode: 'comfortable',
      setDraftQueueViewMode: (mode) => set({ draftQueueViewMode: mode }),

      selectedDraftIds: new Set<string>(),
      toggleDraftSelection: (id) =>
        set((s) => {
          const next = new Set(s.selectedDraftIds);
          if (next.has(id)) { next.delete(id); } else { next.add(id); }
          return { selectedDraftIds: next };
        }),
      selectAllDrafts: (ids) => set({ selectedDraftIds: new Set(ids) }),
      clearDraftSelection: () => set({ selectedDraftIds: new Set<string>() }),

      engagementViewMode: 'kanban',
      setEngagementViewMode: (mode) => set({ engagementViewMode: mode }),

      keyboardShortcutsEnabled: true,
      setKeyboardShortcutsEnabled: (enabled) => set({ keyboardShortcutsEnabled: enabled }),

      notificationsEnabled: false,
      setNotificationsEnabled: (enabled) => set({ notificationsEnabled: enabled }),

      pendingDraftCount: 0,
      setPendingDraftCount: (n) => set({ pendingDraftCount: Math.max(0, n) }),
      incrementPendingDraftCount: () =>
        set((s) => ({ pendingDraftCount: s.pendingDraftCount + 1 })),
      decrementPendingDraftCount: () =>
        set((s) => ({ pendingDraftCount: Math.max(0, s.pendingDraftCount - 1) })),

      inboxUnreadCount: 0,
      setInboxUnreadCount: (n) => set({ inboxUnreadCount: Math.max(0, n) }),

      openTaskCount: 0,
      setOpenTaskCount: (n) => set({ openTaskCount: Math.max(0, n) }),
    }),
    {
      name: 'urm-ui-state',
      storage: createJSONStorage(() => localStorage),
      partialize: (state) => ({
        sidebarCollapsed: state.sidebarCollapsed,
        draftQueueViewMode: state.draftQueueViewMode,
        engagementViewMode: state.engagementViewMode,
        notificationsEnabled: state.notificationsEnabled,
      }),
    },
  ),
);