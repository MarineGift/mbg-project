'use client';

// src/components/schedule/schedule-editor.tsx
// Add/edit/delete time blocks.
//   date set    → edit that date only (routine_day_blocks); no weekday/active
//   date absent → edit the default template (routine_blocks); weekday/active shown

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { Plus, Trash2, Pencil, Loader2, X, Check } from 'lucide-react';
import { cn } from '@/lib/utils';
import {
  upsertBlock, deleteBlock,
  upsertDayBlock, deleteDayBlock,
} from '@/app/actions/schedule';
import {
  CATEGORY_META, CATEGORY_ORDER, catMeta, hhmm,
} from './constants';

export type EditorBlock = {
  id: string;
  title: string;
  category: string;
  start_time: string;   // "HH:MM:SS" or "HH:MM"
  end_time: string;
  weekday_mask?: number; // template mode only
  active?: boolean;      // template mode only
};

const DOW_LABELS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

function maskToDays(mask: number): boolean[] {
  return Array.from({ length: 7 }, (_, i) => (mask & (1 << i)) !== 0);
}
function daysToMask(days: boolean[]): number {
  return days.reduce((acc, on, i) => (on ? acc | (1 << i) : acc), 0);
}
function maskLabel(mask: number): string {
  if (mask === 127) return 'Every day';
  const days = maskToDays(mask);
  if (mask === 0b0111110) return 'Weekdays';
  if (mask === 0b1000001) return 'Weekend';
  return DOW_LABELS.filter((_, i) => days[i]).join('·') || 'None';
}

type Draft = {
  id?: string;
  title: string;
  category: string;
  start_time: string;
  end_time: string;
  weekday_mask: number;
  active: boolean;
};

const BLANK: Draft = {
  title: '', category: 'work', start_time: '09:00', end_time: '10:00', weekday_mask: 127, active: true,
};

export function ScheduleEditor({ blocks, date }: { blocks: EditorBlock[]; date?: string }) {
  const router = useRouter();
  const dayMode = !!date;
  const [isPending, startTransition] = useTransition();
  const [editing, setEditing] = useState<Draft | null>(null);

  function save(draft: Draft) {
    startTransition(async () => {
      const res = dayMode
        ? await upsertDayBlock(date!, {
            id: draft.id,
            title: draft.title,
            category: draft.category,
            start_time: draft.start_time,
            end_time: draft.end_time,
          })
        : await upsertBlock({
            id: draft.id,
            title: draft.title,
            category: draft.category,
            start_time: draft.start_time,
            end_time: draft.end_time,
            weekday_mask: draft.weekday_mask,
            active: draft.active,
          });
      if (!res.success) { alert(`Save failed: ${res.error}`); return; }
      setEditing(null);
      router.refresh();
    });
  }

  function remove(id: string, title: string) {
    const msg = dayMode
      ? `Delete "${title}" from this day?`
      : `Delete "${title}"? Related logs will also be removed.`;
    if (!confirm(msg)) return;
    startTransition(async () => {
      const res = dayMode ? await deleteDayBlock(id) : await deleteBlock(id);
      if (!res.success) { alert(`Delete failed: ${res.error}`); return; }
      router.refresh();
    });
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-end">
        <button
          onClick={() => setEditing({ ...BLANK })}
          className="inline-flex items-center gap-1.5 rounded-md bg-primary px-3 py-1.5 text-sm font-medium text-primary-foreground hover:opacity-90"
        >
          <Plus className="h-4 w-4" /> Add block
        </button>
      </div>

      {editing && (
        <BlockForm
          draft={editing}
          dayMode={dayMode}
          busy={isPending}
          onChange={setEditing}
          onCancel={() => setEditing(null)}
          onSave={() => save(editing)}
        />
      )}

      <ul className="divide-y rounded-lg border">
        {blocks.length === 0 && (
          <li className="px-4 py-6 text-center text-sm text-muted-foreground">
            No blocks. Start with “Add block”.
          </li>
        )}
        {blocks.map((b) => {
          const meta = catMeta(b.category);
          const inactive = b.active === false;
          return (
            <li key={b.id} className={cn('flex items-center gap-3 px-4 py-2.5', inactive && 'opacity-50')}>
              <div className="w-[92px] shrink-0 text-sm tabular-nums text-muted-foreground">
                {hhmm(b.start_time)}–{hhmm(b.end_time)}
              </div>
              <span className={cn('h-2 w-2 shrink-0 rounded-full', meta.dot)} />
              <div className="min-w-0 flex-1">
                <div className="truncate text-sm font-medium">{b.title}</div>
                <div className="text-xs text-muted-foreground">
                  {meta.label}
                  {!dayMode && b.weekday_mask !== undefined && ` · ${maskLabel(b.weekday_mask)}`}
                  {inactive && ' · inactive'}
                </div>
              </div>
              <button
                onClick={() => setEditing({
                  id: b.id, title: b.title, category: b.category,
                  start_time: hhmm(b.start_time), end_time: hhmm(b.end_time),
                  weekday_mask: b.weekday_mask ?? 127, active: b.active ?? true,
                })}
                className="inline-flex h-8 w-8 items-center justify-center rounded-md border hover:bg-accent"
                title="Edit"
              >
                <Pencil className="h-4 w-4" />
              </button>
              <button
                onClick={() => remove(b.id, b.title)}
                className="inline-flex h-8 w-8 items-center justify-center rounded-md border text-rose-600 hover:bg-rose-50"
                title="Delete"
              >
                <Trash2 className="h-4 w-4" />
              </button>
            </li>
          );
        })}
      </ul>
    </div>
  );
}

function BlockForm({
  draft, dayMode, busy, onChange, onCancel, onSave,
}: {
  draft: Draft;
  dayMode: boolean;
  busy: boolean;
  onChange: (d: Draft) => void;
  onCancel: () => void;
  onSave: () => void;
}) {
  const days = maskToDays(draft.weekday_mask);
  return (
    <div className="rounded-lg border bg-muted/30 p-4">
      <div className="grid gap-3 sm:grid-cols-2">
        <label className="sm:col-span-2 text-sm">
          <span className="mb-1 block font-medium">Title</span>
          <input
            value={draft.title}
            onChange={(e) => onChange({ ...draft, title: e.target.value })}
            placeholder="e.g., Work 1 (deep work)"
            className="w-full rounded-md border bg-background px-3 py-2 text-sm"
          />
        </label>

        <label className="text-sm">
          <span className="mb-1 block font-medium">Category</span>
          <select
            value={draft.category}
            onChange={(e) => onChange({ ...draft, category: e.target.value })}
            className="w-full rounded-md border bg-background px-3 py-2 text-sm"
          >
            {CATEGORY_ORDER.map((c) => (
              <option key={c} value={c}>{CATEGORY_META[c].label}</option>
            ))}
          </select>
        </label>

        <div className="grid grid-cols-2 gap-2 text-sm">
          <label>
            <span className="mb-1 block font-medium">Start</span>
            <input type="time" value={draft.start_time}
              onChange={(e) => onChange({ ...draft, start_time: e.target.value })}
              className="w-full rounded-md border bg-background px-2 py-2 text-sm" />
          </label>
          <label>
            <span className="mb-1 block font-medium">End</span>
            <input type="time" value={draft.end_time}
              onChange={(e) => onChange({ ...draft, end_time: e.target.value })}
              className="w-full rounded-md border bg-background px-2 py-2 text-sm" />
          </label>
        </div>

        {!dayMode && (
          <>
            <div className="sm:col-span-2">
              <span className="mb-1 block text-sm font-medium">Days</span>
              <div className="flex flex-wrap gap-1.5">
                {DOW_LABELS.map((lbl, i) => (
                  <button
                    key={i}
                    type="button"
                    onClick={() => {
                      const next = [...days]; next[i] = !next[i];
                      onChange({ ...draft, weekday_mask: daysToMask(next) });
                    }}
                    className={cn(
                      'h-8 min-w-[2.25rem] rounded-md border px-1 text-xs',
                      days[i] ? 'bg-primary text-primary-foreground border-primary' : 'hover:bg-accent',
                    )}
                  >
                    {lbl}
                  </button>
                ))}
                <div className="ml-2 flex gap-1">
                  <button type="button" onClick={() => onChange({ ...draft, weekday_mask: 127 })}
                    className="rounded-md border px-2 text-xs hover:bg-accent">Every day</button>
                  <button type="button" onClick={() => onChange({ ...draft, weekday_mask: 0b0111110 })}
                    className="rounded-md border px-2 text-xs hover:bg-accent">Weekdays</button>
                  <button type="button" onClick={() => onChange({ ...draft, weekday_mask: 0b1000001 })}
                    className="rounded-md border px-2 text-xs hover:bg-accent">Weekend</button>
                </div>
              </div>
            </div>

            <label className="sm:col-span-2 flex items-center gap-2 text-sm">
              <input type="checkbox" checked={draft.active}
                onChange={(e) => onChange({ ...draft, active: e.target.checked })} />
              Active (unchecked = excluded from schedule/reports)
            </label>
          </>
        )}
      </div>

      <div className="mt-3 flex justify-end gap-2">
        <button onClick={onCancel}
          className="inline-flex items-center gap-1.5 rounded-md border px-3 py-1.5 text-sm hover:bg-accent">
          <X className="h-4 w-4" /> Cancel
        </button>
        <button onClick={onSave} disabled={busy}
          className="inline-flex items-center gap-1.5 rounded-md bg-primary px-3 py-1.5 text-sm font-medium text-primary-foreground hover:opacity-90 disabled:opacity-50">
          {busy ? <Loader2 className="h-4 w-4 animate-spin" /> : <Check className="h-4 w-4" />} Save
        </button>
      </div>
    </div>
  );
}
