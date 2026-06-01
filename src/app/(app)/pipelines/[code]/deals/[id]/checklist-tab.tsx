// src/app/(app)/pipelines/[code]/deals/[id]/checklist-tab.tsx
//
// Checklist tab for the deal detail page. Lists app.deal_checklists rows for
// this deal as checkable items, with inline add and per-row delete.
// Mirrors the Tasks tab look (header + count + bordered card list).
//
// Optimistic UI + useTransition; server actions call revalidatePath, which
// refreshes the server-rendered `items` prop (resynced via useEffect).

'use client';

import { useEffect, useState, useTransition } from 'react';
import { CheckSquare, Square, Plus, X, ListChecks } from 'lucide-react';
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
}

interface Props {
  pipelineCode: string;
  dealId: string;
  items: ChecklistItem[];
}

export function ChecklistTabClient({ pipelineCode, dealId, items }: Props) {
  const [local, setLocal] = useState<ChecklistItem[]>(items);
  const [draft, setDraft] = useState('');
  const [, startTransition] = useTransition();

  // Resync when the server refreshes (after revalidatePath).
  useEffect(() => {
    setLocal(items);
  }, [items]);

  const total = local.length;
  const done = local.filter((i) => i.is_complete).length;

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
    // Optimistic temp row; replaced by the real row after revalidate resync.
    const tempId = 'temp-' + Date.now();
    setLocal((prev) => [
      ...prev,
      { id: tempId, title, is_complete: false, sort_order: null, completed_at: null },
    ]);
    startTransition(async () => {
      const r = await addChecklistItem({ pipelineCode, dealId, title });
      if (!r.ok) {
        console.error('addChecklistItem failed', r.error);
        setLocal((prev) => prev.filter((i) => i.id !== tempId));
      }
    });
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
          onKeyDown={(e) => { if (e.key === 'Enter') add(); }}
          placeholder="Add a checklist item..."
          className="flex-1 rounded-md border bg-background px-3 py-2 text-sm focus:border-foreground/30 focus:outline-none focus:ring-2 focus:ring-foreground/5"
        />
        <Button size="sm" onClick={add} disabled={!draft.trim()} className="gap-1.5">
          <Plus className="h-3.5 w-3.5" />
          Add
        </Button>
      </div>

      {/* List or empty state */}
      {total === 0 ? (
        <div className="flex flex-col items-center justify-center rounded-lg border bg-card py-16">
          <ListChecks className="mb-3 h-8 w-8 text-muted-foreground/30" />
          <div className="text-sm font-medium text-foreground">No checklist items yet</div>
          <div className="mt-1 max-w-md text-center text-xs text-muted-foreground">
            Add items above to track the steps for closing this deal.
          </div>
        </div>
      ) : (
        <div className="rounded-lg border bg-card">
          <ul className="divide-y">
            {local.map((item) => {
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
            })}
          </ul>
        </div>
      )}
    </div>
  );
}
