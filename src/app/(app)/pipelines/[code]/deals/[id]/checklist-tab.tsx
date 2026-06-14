// src/app/(app)/pipelines/[code]/deals/[id]/checklist-tab.tsx
//
// Checklist tab for the deal detail page. Lists app.deal_checklists rows for
// this deal, grouped by the stage they belong to (stage_id). The deal's
// current stage is shown first and expanded; other stages collapse. Items with
// no stage (manual / deal-level) fall into a "Deal-wide" group.
//
// Optimistic UI + useTransition; server actions call revalidatePath, which
// refreshes the server-rendered `items` prop (resynced via useEffect).
// Degrades to a single group when no stage data is supplied.

'use client';

import { useEffect, useMemo, useState, useTransition } from 'react';
import {
  CheckSquare,
  Square,
  Plus,
  X,
  ListChecks,
  ChevronDown,
  ChevronRight,
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import {
  addChecklistItem,
  toggleChecklistItem,
  deleteChecklistItem,
} from './checklist-actions';

interface ChecklistItem {
  id: string;
  title: string;
  is_complete: boolean | null;
  sort_order: number | null;
  completed_at: string | null;
  stage_id?: string | null;
}

interface Props {
  pipelineCode: string;
  dealId: string;
  items: ChecklistItem[];
  stages?: Array<{ id: string; name: string; sort_order: number | null }>;
  currentStageId?: string | null;
}

const NO_STAGE = '__deal_wide__';

function ProgressBar({ done, total }: { done: number; total: number }) {
  const pct = total > 0 ? Math.round((done / total) * 100) : 0;
  return (
    <div className="mt-2 h-1.5 w-full overflow-hidden rounded-full bg-muted">
      <div
        className="h-full rounded-full bg-emerald-500 transition-all"
        style={{ width: pct + '%' }}
      />
    </div>
  );
}

export function ChecklistTabClient({
  pipelineCode,
  dealId,
  items,
  stages,
  currentStageId,
}: Props) {
  const [local, setLocal] = useState<ChecklistItem[]>(items);
  const [draft, setDraft] = useState('');
  const [, startTransition] = useTransition();
  const [collapsed, setCollapsed] = useState<Set<string>>(() => {
    // Collapse every group except the current stage by default.
    const s = new Set<string>();
    for (const it of items) {
      const key = it.stage_id ?? NO_STAGE;
      if (key !== currentStageId) s.add(key);
    }
    return s;
  });

  // Resync when the server refreshes (after revalidatePath).
  useEffect(() => {
    setLocal(items);
  }, [items]);

  const total = local.length;
  const done = local.filter((i) => i.is_complete).length;

  const stageName = new Map<string, string>();
  const stageOrder = new Map<string, number>();
  (stages ?? []).forEach((s, idx) => {
    stageName.set(s.id, s.name);
    stageOrder.set(s.id, s.sort_order ?? idx);
  });

  // Group by stage_id; order: current stage first, then by stage sort_order,
  // then the deal-wide (no stage) group last.
  const groups = useMemo(() => {
    const byKey = new Map<string, ChecklistItem[]>();
    for (const it of local) {
      const key = it.stage_id ?? NO_STAGE;
      if (!byKey.has(key)) byKey.set(key, []);
      byKey.get(key)!.push(it);
    }
    const rank = (key: string) => {
      if (key === NO_STAGE) return 2_000_000;
      if (key === currentStageId) return 0;
      return 1_000_000 + (stageOrder.get(key) ?? 9999);
    };
    return Array.from(byKey.entries())
      .sort((a, b) => rank(a[0]) - rank(b[0]))
      .map(([key, list]) => ({
        key,
        label: key === NO_STAGE ? 'Deal-wide' : stageName.get(key) ?? 'Stage',
        isCurrent: key === currentStageId,
        items: list,
        done: list.filter((i) => i.is_complete).length,
      }));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [local, currentStageId, stages]);

  function toggleCollapse(key: string) {
    setCollapsed((prev) => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });
  }

  function toggle(item: ChecklistItem) {
    const next = !item.is_complete;
    setLocal((prev) =>
      prev.map((i) => (i.id === item.id ? { ...i, is_complete: next } : i)),
    );
    startTransition(async () => {
      const r = await toggleChecklistItem({
        pipelineCode,
        dealId,
        itemId: item.id,
        isComplete: next,
      });
      if (!r.ok) {
        console.error('toggleChecklistItem failed', r.error);
        setLocal((prev) =>
          prev.map((i) => (i.id === item.id ? { ...i, is_complete: !next } : i)),
        );
      }
    });
  }

  function remove(item: ChecklistItem) {
    const snapshot = local;
    setLocal((prev) => prev.filter((i) => i.id !== item.id));
    startTransition(async () => {
      const r = await deleteChecklistItem({ pipelineCode, dealId, itemId: item.id });
      if (!r.ok) {
        console.error('deleteChecklistItem failed', r.error);
        setLocal(snapshot);
      }
    });
  }

  function add() {
    const title = draft.trim();
    if (!title) return;
    setDraft('');
    const tempId = 'temp-' + Date.now();
    setLocal((prev) => [
      ...prev,
      {
        id: tempId,
        title,
        is_complete: false,
        sort_order: null,
        completed_at: null,
        stage_id: null,
      },
    ]);
    // Reveal the deal-wide group so the new item is visible.
    setCollapsed((prev) => {
      const next = new Set(prev);
      next.delete(NO_STAGE);
      return next;
    });
    startTransition(async () => {
      const r = await addChecklistItem({ pipelineCode, dealId, title });
      if (!r.ok) {
        console.error('addChecklistItem failed', r.error);
        setLocal((prev) => prev.filter((i) => i.id !== tempId));
      }
    });
  }

  function renderItem(item: ChecklistItem) {
    const isDone = !!item.is_complete;
    return (
      <li key={item.id} className="group flex items-center gap-3 px-4 py-2.5">
        <button
          type="button"
          onClick={() => toggle(item)}
          aria-label={isDone ? 'mark incomplete' : 'mark complete'}
          className="shrink-0"
        >
          {isDone ? (
            <CheckSquare className="h-4 w-4 text-foreground/70" />
          ) : (
            <Square className="h-4 w-4 text-muted-foreground hover:text-foreground" />
          )}
        </button>
        <span
          className={
            'flex-1 text-sm ' +
            (isDone ? 'text-muted-foreground line-through' : 'text-foreground')
          }
        >
          {item.title}
        </span>
        <button
          type="button"
          onClick={() => remove(item)}
          aria-label="delete item"
          className="shrink-0 text-muted-foreground opacity-0 transition hover:text-rose-600 group-hover:opacity-100"
        >
          <X className="h-3.5 w-3.5" />
        </button>
      </li>
    );
  }

  return (
    <div>
      {/* Header bar */}
      <div className="mb-3 flex items-center justify-between">
        <div className="text-xs font-medium uppercase tracking-wider text-muted-foreground">
          {total === 0 ? 'Checklist' : 'Checklist (' + done + '/' + total + ')'}
        </div>
      </div>

      {/* Add row */}
      <div className="mb-3 flex items-center gap-2">
        <input
          value={draft}
          onChange={(e) => setDraft(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === 'Enter') add();
          }}
          placeholder="Add a checklist item..."
          className="flex-1 rounded-md border bg-background px-3 py-2 text-sm focus:border-foreground/30 focus:outline-none focus:ring-2 focus:ring-foreground/5"
        />
        <Button size="sm" onClick={add} disabled={!draft.trim()} className="gap-1.5">
          <Plus className="h-3.5 w-3.5" />
          Add
        </Button>
      </div>

      {/* Grouped list or empty state */}
      {total === 0 ? (
        <div className="flex flex-col items-center justify-center rounded-lg border bg-card py-16">
          <ListChecks className="mb-3 h-8 w-8 text-muted-foreground/30" />
          <div className="text-sm font-medium text-foreground">No checklist items yet</div>
          <div className="mt-1 max-w-md text-center text-xs text-muted-foreground">
            Add items above to track the steps for closing this deal.
          </div>
        </div>
      ) : (
        <div className="space-y-3">
          {groups.map((g) => {
            const isOpen = !collapsed.has(g.key);
            return (
              <div key={g.key} className="rounded-lg border bg-card">
                <div
                  role="button"
                  tabIndex={0}
                  onClick={() => toggleCollapse(g.key)}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' || e.key === ' ') {
                      e.preventDefault();
                      toggleCollapse(g.key);
                    }
                  }}
                  className="cursor-pointer border-b px-4 py-3"
                >
                  <div className="flex items-center justify-between gap-2">
                    <div className="flex min-w-0 items-center gap-2">
                      {isOpen ? (
                        <ChevronDown className="h-3.5 w-3.5 shrink-0 text-muted-foreground" />
                      ) : (
                        <ChevronRight className="h-3.5 w-3.5 shrink-0 text-muted-foreground" />
                      )}
                      <span className="truncate text-sm font-medium text-foreground">
                        {g.label}
                      </span>
                      {g.isCurrent && (
                        <span className="shrink-0 rounded bg-emerald-100 px-1.5 py-0.5 text-[10px] font-medium text-emerald-700">
                          Current
                        </span>
                      )}
                    </div>
                    <span className="shrink-0 text-xs text-muted-foreground tabular-nums">
                      {g.done}/{g.items.length}
                    </span>
                  </div>
                  <ProgressBar done={g.done} total={g.items.length} />
                </div>
                {isOpen && <ul className="divide-y">{g.items.map(renderItem)}</ul>}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
