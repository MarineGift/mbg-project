'use client';

// src/components/tasks/task-board-view.tsx
// Unified board view for the Todo task engine: Kanban / Calendar / Gantt tabs.
// All three views share one `items` state, so a change in any view (create,
// edit, delete, drag-move) reflects across the others without a refresh.
//
// - No external DnD lib: native HTML5 drag-and-drop only.
// - Tailwind for layout/cards; inline style only for DB-driven status colors.
// - Full CRUD via a single TaskModal (create + edit + delete), opened from
//   every view. organization_id / created_by are set by DB defaults (SaaS:
//   tenant + author un-spoofable from the client), so writes never send them.
// - Calendar shows BOTH start and due dates (chip on each).
// - Gantt shows only items that have BOTH start AND due dates.
//
// Server actions: createItem / updateItem / deleteItem / moveItem.

import { useEffect, useMemo, useRef, useState, useTransition } from 'react';
import type {
  BoardData,
  TaskItem,
  TaskStatusOption,
  TaskPriority,
} from '@/lib/tasks/types';
import {
  moveItem,
  createItem,
  updateItem,
  deleteItem,
  resolvePartyIdByName,
} from '@/lib/tasks/actions';
import { parseQuickAdd } from '@/lib/tasks/quick-add-parser';
import { createSupabaseBrowserClient } from '@/lib/supabase/client';

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

const PRI: Record<string, { cls: string; label: string }> = {
  urgent: { cls: 'bg-red-50 text-red-700', label: 'urgent' },
  high:   { cls: 'bg-amber-50 text-amber-700', label: 'high' },
  med:    { cls: 'bg-blue-50 text-blue-700', label: 'med' },
  low:    { cls: 'bg-slate-100 text-slate-500', label: 'low' },
};
const PRIORITIES: TaskPriority[] = ['low', 'med', 'high', 'urgent'];

function priMeta(key: string | null | undefined): { cls: string; label: string } {
  return PRI[key ?? 'med'] ?? { cls: 'bg-blue-50 text-blue-700', label: 'med' };
}

const WEEKDAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

const pad = (n: number) => (n < 10 ? `0${n}` : `${n}`);

function todayStr(): string {
  const d = new Date();
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}
function toDays(s: string): number {
  const [y = 0, m = 1, d = 1] = s.split('-').map(Number);
  return Math.floor(Date.UTC(y, m - 1, d) / 86_400_000);
}
function fromDays(n: number): string {
  const dt = new Date(n * 86_400_000);
  return `${dt.getUTCFullYear()}-${pad(dt.getUTCMonth() + 1)}-${pad(dt.getUTCDate())}`;
}
function weekdayOf(s: string): number {
  const [y = 0, m = 1, d = 1] = s.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d)).getUTCDay();
}

type View = 'kanban' | 'calendar' | 'gantt';

interface TaskFormValues {
  title: string;
  status: string;
  priority: TaskPriority | null;
  startDate: string | null;
  dueDate: string | null;
  description: string | null;
  recurrence: string | null;
  recurrenceEnds: string | null;
}

// Repeat dropdown options (maps label -> RRULE subset understood by the DB trigger).
const RECUR_OPTIONS: Array<{ key: string; label: string; rule: string | null }> = [
  { key: 'none',    label: 'Does not repeat', rule: null },
  { key: 'daily',   label: 'Daily',           rule: 'FREQ=DAILY' },
  { key: 'weekly',  label: 'Weekly',          rule: 'FREQ=WEEKLY' },
  { key: 'biweekly',label: 'Every 2 weeks',   rule: 'FREQ=WEEKLY;INTERVAL=2' },
  { key: 'monthly', label: 'Monthly',         rule: 'FREQ=MONTHLY' },
  { key: 'yearly',  label: 'Yearly',          rule: 'FREQ=YEARLY' },
];
function ruleToKey(rule: string | null): string {
  if (!rule) return 'none';
  return RECUR_OPTIONS.find((o) => o.rule === rule)?.key ?? 'none';
}

type ModalState =
  | { mode: 'create'; presetStatus?: string; presetStart?: string | null; presetDue?: string | null }
  | { mode: 'edit'; item: TaskItem };

// ---------------------------------------------------------------------------
// Root: tabs + shared state + CRUD handlers
// ---------------------------------------------------------------------------

export function TaskBoardView({ initial }: { initial: BoardData }) {
  const board = initial.board;
  const cols = useMemo(
    () => [...initial.statusOptions].sort((a, b) => a.position - b.position),
    [initial.statusOptions],
  );

  const [items, setItems] = useState<TaskItem[]>(initial.items);
  const [view, setView] = useState<View>('kanban');
  const [modal, setModal] = useState<ModalState | null>(null);
  const [currentUserId, setCurrentUserId] = useState<string | null>(null);
  const [, startTransition] = useTransition();

  useEffect(() => {
    let alive = true;
    (async () => {
      try {
        const sb = createSupabaseBrowserClient();
        const { data } = await sb.auth.getUser();
        if (alive) setCurrentUserId(data.user?.id ?? null);
      } catch {
        /* ignore */
      }
    })();
    return () => { alive = false; };
  }, []);

  // Realtime: subscribe to app.todo_items for THIS board and merge changes into
  // local state (no router.refresh, since the board lives in client state).
  // Same channel/postgres_changes pattern as RealtimeProvider; one .on per event.
  // Idempotent vs. our own optimistic writes: upsert-by-id replaces in place.
  // NOTE (DB, one-time): the table must be in the realtime publication and have
  // REPLICA IDENTITY FULL so UPDATE/DELETE carry enough row data + pass RLS:
  //   alter publication supabase_realtime add table app.todo_items;
  //   alter table app.todo_items replica identity full;
  useEffect(() => {
    const supabase = createSupabaseBrowserClient();

    const upsert = (raw: Record<string, unknown> | undefined) => {
      const row = raw as unknown as TaskItem | undefined;
      if (!row || row.board_id !== board.id) return;
      if (row.archived_at) {
        setItems((prev) => prev.filter((i) => i.id !== row.id));
        return;
      }
      setItems((prev) =>
        prev.some((i) => i.id === row.id)
          ? prev.map((i) => (i.id === row.id ? row : i))
          : [...prev, row],
      );
    };
    const removeById = (raw: Record<string, unknown> | undefined) => {
      const id = raw?.id as string | undefined;
      if (id) setItems((prev) => prev.filter((i) => i.id !== id));
    };

    const filter = `board_id=eq.${board.id}`;
    const channel = supabase
      .channel(`todo_items:board-${board.id}`)
      .on('postgres_changes' as never,
        { event: 'INSERT', schema: 'app', table: 'todo_items', filter },
        (payload: { new: Record<string, unknown> }) => upsert(payload.new),
      )
      .on('postgres_changes' as never,
        { event: 'UPDATE', schema: 'app', table: 'todo_items', filter },
        (payload: { new: Record<string, unknown> }) => upsert(payload.new),
      )
      .on('postgres_changes' as never,
        { event: 'DELETE', schema: 'app', table: 'todo_items', filter },
        (payload: { old: Record<string, unknown> }) => removeById(payload.old),
      )
      .subscribe();

    return () => { supabase.removeChannel(channel); };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [board.id]);

  const firstColKey = cols[0]?.key ?? 'todo';
  const statusColor = (key: string) =>
    cols.find((c) => c.key === key)?.color ?? '#94a3b8';
  const statusLabel = (key: string) =>
    cols.find((c) => c.key === key)?.label ?? key;

  const nextPos = (key: string) => {
    const l = items.filter((i) => i.status === key);
    return l.length ? Math.max(...l.map((i) => i.position)) + 1000 : 1000;
  };

  function moveTask(id: string, status: string, position: number) {
    setItems((prev) =>
      prev.map((i) => (i.id === id ? { ...i, status, position } : i)),
    );
    startTransition(async () => {
      try {
        await moveItem(id, status, position);
      } catch (e) {
        console.error('moveItem failed', e);
      }
    });
  }

  // Quick add from a kanban column header, with natural-language parsing.
  // "Pangaea follow-up next thu p1 @pangaea" -> due_date / priority / party_id
  // are extracted; unrecognized text stays in the title. Parsing runs on the
  // CLIENT so relative dates resolve in the user's local timezone; only the
  // @party lookup goes to the server (RLS-scoped).
  async function quickCreate(title: string, status: string) {
    try {
      const parsed = parseQuickAdd(title);
      let partyId: string | null = null;
      if (parsed.partyQuery) {
        try {
          const p = await resolvePartyIdByName(parsed.partyQuery);
          partyId = p?.id ?? null;
        } catch (e) {
          console.error('resolvePartyIdByName failed', e);
        }
      }
      const created = await createItem({
        boardId: board.id,
        title: parsed.title,
        status,
        priority: parsed.priority,
        startDate: parsed.startDate,
        dueDate: parsed.dueDate,
        recurrence: parsed.recurrence,
        partyId,
        position: nextPos(status),
      });
      setItems((prev) => [...prev, created]);
    } catch (e) {
      console.error('createItem failed', e);
    }
  }

  // Full create from the modal.
  async function createTask(v: TaskFormValues) {
    try {
      const created = await createItem({
        boardId: board.id,
        title: v.title,
        status: v.status,
        priority: v.priority,
        startDate: v.startDate,
        dueDate: v.dueDate,
        description: v.description,
        recurrence: v.recurrence,
        recurrenceEnds: v.recurrenceEnds,
        position: nextPos(v.status),
      });
      setItems((prev) => [...prev, created]);
    } catch (e) {
      console.error('createItem failed', e);
    }
  }

  async function updateTask(id: string, v: TaskFormValues) {
    setItems((prev) =>
      prev.map((i) =>
        i.id === id
          ? {
              ...i,
              title: v.title,
              status: v.status,
              priority: v.priority,
              start_date: v.startDate,
              due_date: v.dueDate,
              description: v.description,
              recurrence: v.recurrence,
              recurrence_ends: v.recurrenceEnds,
            }
          : i,
      ),
    );
    startTransition(async () => {
      try {
        await updateItem(id, {
          title: v.title,
          status: v.status,
          priority: v.priority,
          startDate: v.startDate,
          dueDate: v.dueDate,
          description: v.description,
          recurrence: v.recurrence,
          recurrenceEnds: v.recurrenceEnds,
        });
      } catch (e) {
        console.error('updateItem failed', e);
      }
    });
  }

  async function deleteTask(id: string) {
    const snapshot = items;
    setItems((prev) => prev.filter((i) => i.id !== id));
    try {
      await deleteItem(id);
    } catch (e) {
      console.error('deleteItem failed', e);
      setItems(snapshot); // rollback
    }
  }

  const openEdit = (item: TaskItem) => setModal({ mode: 'edit', item });
  const openCreate = (presetStatus?: string, presetStart?: string | null, presetDue?: string | null) =>
    setModal({ mode: 'create', presetStatus, presetStart, presetDue });

  const TABS: { key: View; label: string }[] = [
    { key: 'kanban', label: 'Kanban' },
    { key: 'calendar', label: 'Calendar' },
    { key: 'gantt', label: 'Gantt' },
  ];

  return (
    <div className="flex h-full flex-col p-5">
      <header className="mb-3 flex items-baseline gap-2.5">
        <h1 className="m-0 text-xl font-semibold tracking-tight text-foreground">{board.name}</h1>
        <span className="text-sm text-muted-foreground">{items.length} tasks</span>
        <button
          type="button"
          onClick={() => openCreate(firstColKey)}
          className="ml-auto inline-flex items-center gap-1.5 rounded-md bg-foreground px-3 py-1.5 text-sm font-semibold text-background hover:bg-foreground/90"
        >
          + New
        </button>
      </header>

      <div className="mb-4 flex gap-1 border-b">
        {TABS.map((t) => {
          const active = view === t.key;
          return (
            <button
              key={t.key}
              type="button"
              onClick={() => setView(t.key)}
              className={
                'relative -mb-px px-3.5 py-2 text-sm font-semibold transition-colors ' +
                (active ? 'text-foreground' : 'text-muted-foreground hover:text-foreground')
              }
            >
              {t.label}
              {active && (
                <span className="absolute inset-x-0 -bottom-px h-0.5 rounded-full bg-foreground" />
              )}
            </button>
          );
        })}
      </div>

      <div className="min-h-0 flex-1">
      {view === 'kanban' && (
        <KanbanView
          cols={cols}
          items={items}
          nextPos={nextPos}
          onMove={moveTask}
          onQuickCreate={quickCreate}
          onEdit={openEdit}
        />
      )}
      {view === 'calendar' && (
        <CalendarView
          items={items}
          statusColor={statusColor}
          onEdit={openEdit}
          onCreateAt={(day) => openCreate(firstColKey, day, day)}
        />
      )}
      {view === 'gantt' && (
        <GanttView
          items={items}
          statusColor={statusColor}
          statusLabel={statusLabel}
          onEdit={openEdit}
        />
      )}
      </div>

      {modal && (
        <TaskModal
          key={modal.mode === 'edit' ? modal.item.id : 'create'}
          mode={modal.mode}
          cols={cols}
          item={modal.mode === 'edit' ? modal.item : undefined}
          presetStatus={modal.mode === 'create' ? modal.presetStatus : undefined}
          presetStart={modal.mode === 'create' ? modal.presetStart ?? null : null}
          presetDue={modal.mode === 'create' ? modal.presetDue ?? null : null}
          currentUserId={currentUserId}
          onCreate={createTask}
          onUpdate={updateTask}
          onDelete={deleteTask}
          onClose={() => setModal(null)}
        />
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Kanban
// ---------------------------------------------------------------------------

function KanbanView(props: {
  cols: TaskStatusOption[];
  items: TaskItem[];
  nextPos: (key: string) => number;
  onMove: (id: string, status: string, position: number) => void;
  onQuickCreate: (title: string, status: string) => Promise<void>;
  onEdit: (item: TaskItem) => void;
}) {
  const { cols, items, nextPos, onMove, onQuickCreate, onEdit } = props;

  const [dragId, setDragId] = useState<string | null>(null);
  const [justDragged, setJustDragged] = useState(false);
  const [overCol, setOverCol] = useState<string | null>(null);
  const [composing, setComposing] = useState<string | null>(null);
  const [draft, setDraft] = useState('');

  const inCol = (k: string) =>
    items.filter((i) => i.status === k).sort((a, b) => a.position - b.position);

  function onDrop(colKey: string) {
    const id = dragId;
    setDragId(null);
    setOverCol(null);
    if (!id) return;
    const it = items.find((i) => i.id === id);
    if (!it || it.status === colKey) return;
    onMove(id, colKey, nextPos(colKey));
  }

  async function commitAdd(colKey: string) {
    const title = draft.trim();
    setComposing(null);
    setDraft('');
    if (!title) return;
    await onQuickCreate(title, colKey);
  }

  return (
    <div className="flex h-full min-w-full items-stretch gap-3 overflow-x-auto pb-2">
      {cols.map((col) => {
        const list = inCol(col.key);
        const isOver = overCol === col.key;
        return (
          <div
            key={col.key}
            onDragOver={(e) => {
              e.preventDefault();
              setOverCol(col.key);
            }}
            onDragLeave={() => setOverCol((c) => (c === col.key ? null : c))}
            onDrop={() => onDrop(col.key)}
            className={
              'flex min-w-[18rem] flex-1 flex-col rounded-lg border bg-card transition-colors ' +
              (isOver ? 'border-foreground/40 bg-card/80 ring-2 ring-foreground/10' : '')
            }
          >
            <div className="flex items-center gap-2 border-b px-3 py-2">
              <span
                className="h-2.5 w-2.5 shrink-0 rounded-full"
                style={{ background: col.color ?? '#94a3b8' }}
              />
              <span className="truncate text-sm font-medium text-foreground">{col.label}</span>
              <span className="ml-1 tabular-nums text-xs text-muted-foreground">
                {list.length}
              </span>
              <button
                type="button"
                onClick={() => { setComposing(col.key); setDraft(''); }}
                aria-label="add task"
                className="ml-auto text-lg leading-none text-muted-foreground hover:text-foreground"
              >
                +
              </button>
            </div>

            <div className="scrollbar-thin flex min-h-12 flex-1 flex-col gap-2 overflow-y-auto p-2">
              {list.map((it) => {
                const p = priMeta(it.priority);
                return (
                  <div
                    key={it.id}
                    draggable
                    onDragStart={() => { setDragId(it.id); setJustDragged(true); }}
                    onDragEnd={() => {
                      setDragId(null);
                      // suppress the click that some browsers fire after a drag
                      setTimeout(() => setJustDragged(false), 0);
                    }}
                    onClick={() => { if (!justDragged) onEdit(it); }}
                    className="cursor-pointer rounded-md border bg-background p-3 text-sm shadow-sm transition hover:border-foreground/20 hover:shadow active:cursor-grabbing"
                  >
                    <div className="mb-1.5 flex items-center gap-1.5">
                      <span
                        className={
                          'rounded px-1.5 py-0.5 text-[9.5px] font-semibold uppercase tracking-wide ' +
                          p.cls
                        }
                      >
                        {p.label}
                      </span>
                      {it.recurrence && (
                        <span className={it.due_date ? 'ml-auto text-[11px] text-muted-foreground' : 'ml-auto'} title={it.recurrence} aria-label="repeats">
                          &#8635;
                        </span>
                      )}
                      {it.due_date && (
                        <span className={(it.recurrence ? 'ml-1' : 'ml-auto') + ' text-[10.5px] text-muted-foreground'}>
                          {it.due_date}
                        </span>
                      )}
                    </div>
                    <div className="line-clamp-2 break-keep text-sm font-medium leading-tight text-foreground">
                      {it.title}
                    </div>
                  </div>
                );
              })}

              {composing === col.key && (
                <input
                  autoFocus
                  value={draft}
                  placeholder="Task (e.g. follow up thu p1 @party)"
                  onChange={(e) => setDraft(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') commitAdd(col.key);
                    if (e.key === 'Escape') { setComposing(null); setDraft(''); }
                  }}
                  onBlur={() => commitAdd(col.key)}
                  className="w-full rounded-md border bg-background px-2.5 py-2 text-sm outline-none focus:border-foreground/30 focus:ring-2 focus:ring-foreground/5"
                />
              )}
            </div>
          </div>
        );
      })}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Calendar (month grid; shows BOTH start and due dates)
// ---------------------------------------------------------------------------

type DayKind = 'start' | 'due' | 'both';

function CalendarView(props: {
  items: TaskItem[];
  statusColor: (key: string) => string;
  onEdit: (item: TaskItem) => void;
  onCreateAt: (day: string) => void;
}) {
  const { items, statusColor, onEdit, onCreateAt } = props;

  const now = new Date();
  const [calY, setCalY] = useState(now.getFullYear());
  const [calM, setCalM] = useState(now.getMonth()); // 0-based
  const today = todayStr();

  // For each day, list items that START or are DUE on it (both dates shown).
  const byDay = useMemo(() => {
    const m: Record<string, Array<{ item: TaskItem; kind: DayKind }>> = {};
    const push = (day: string, item: TaskItem, kind: DayKind) => {
      (m[day] ||= []).push({ item, kind });
    };
    for (const it of items) {
      const s = it.start_date;
      const d = it.due_date;
      if (s && d) {
        if (s === d) push(s, it, 'both');
        else { push(s, it, 'start'); push(d, it, 'due'); }
      } else if (s) {
        push(s, it, 'start');
      } else if (d) {
        push(d, it, 'due');
      }
    }
    return m;
  }, [items]);

  const firstDow = new Date(Date.UTC(calY, calM, 1)).getUTCDay();
  const daysInMonth = new Date(Date.UTC(calY, calM + 1, 0)).getUTCDate();

  const cells: (string | null)[] = [];
  for (let i = 0; i < firstDow; i++) cells.push(null);
  for (let d = 1; d <= daysInMonth; d++) cells.push(`${calY}-${pad(calM + 1)}-${pad(d)}`);
  while (cells.length % 7 !== 0) cells.push(null);

  function shiftMonth(delta: number) {
    let m = calM + delta;
    let y = calY;
    while (m < 0) { m += 12; y -= 1; }
    while (m > 11) { m -= 12; y += 1; }
    setCalM(m);
    setCalY(y);
  }

  const KIND_MARK: Record<DayKind, string> = {
    start: '▸ Start',
    due: '⚑ Due',
    both: '● Same day',
  };

  return (
    <div className="w-full">
      <div className="mb-3 flex items-center gap-2">
        <button type="button" onClick={() => shiftMonth(-1)}
          className="rounded-lg border border-slate-200 px-2.5 py-1 text-sm text-slate-500 hover:bg-slate-50">‹</button>
        <div className="min-w-[140px] text-center text-base font-bold">{MONTHS[calM]} {calY}</div>
        <button type="button" onClick={() => shiftMonth(1)}
          className="rounded-lg border border-slate-200 px-2.5 py-1 text-sm text-slate-500 hover:bg-slate-50">›</button>
        <button type="button" onClick={() => { setCalY(now.getFullYear()); setCalM(now.getMonth()); }}
          className="ml-1 rounded-lg border border-slate-200 px-2.5 py-1 text-sm text-slate-500 hover:bg-slate-50">Today</button>
        <div className="ml-auto flex items-center gap-3 text-[11px] text-slate-400">
          <span>▸ Start</span><span>⚑ Due</span>
        </div>
      </div>

      <div className="-mx-1 overflow-x-auto sm:mx-0">
      <div className="grid grid-cols-7 overflow-hidden rounded-xl border border-slate-200 min-w-[680px]">
        {WEEKDAYS.map((w) => (
          <div key={w}
            className="border-b border-slate-200 bg-slate-50 px-2 py-1.5 text-center text-[11px] font-semibold uppercase tracking-wide text-slate-400">
            {w}
          </div>
        ))}

        {cells.map((day, idx) => {
          if (!day) {
            return <div key={`e${idx}`} className="min-h-[110px] border-b border-r border-slate-100 bg-slate-50/40" />;
          }
          const list = byDay[day] ?? [];
          const isToday = day === today;
          const dnum = Number(day.slice(8, 10));
          return (
            <div
              key={day}
              onClick={() => onCreateAt(day)}
              className="min-h-[110px] cursor-pointer border-b border-r border-slate-100 p-1.5 align-top hover:bg-emerald-50/30"
            >
              <div className="mb-1 flex items-center">
                <span className={
                  'inline-flex h-5 w-5 items-center justify-center rounded-full text-[11px] ' +
                  (isToday ? 'bg-emerald-600 font-bold text-white' : 'text-slate-500')
                }>
                  {dnum}
                </span>
              </div>

              <div className="flex flex-col gap-1">
                {list.map(({ item, kind }) => (
                  <div
                    key={`${item.id}-${kind}`}
                    onClick={(e) => { e.stopPropagation(); onEdit(item); }}
                    className="flex cursor-pointer items-center gap-1 rounded-md border border-slate-200 bg-white px-1.5 py-1 text-[11px] leading-tight hover:border-emerald-400"
                    title={`${item.title}  (${item.start_date ?? '—'} → ${item.due_date ?? '—'})`}
                  >
                    <span className="h-2 w-2 shrink-0 rounded-full" style={{ background: statusColor(item.status) }} />
                    <span className="shrink-0 text-[8.5px] font-semibold text-slate-400">{KIND_MARK[kind]}</span>
                    <span className="truncate">{item.title}</span>
                  </div>
                ))}
              </div>
            </div>
          );
        })}
      </div>
      </div>

      <p className="mt-2 text-[11px] text-slate-400">
        Click an empty cell to add a task on that date (start = due) · click a chip to edit. Tasks appear on both their start and due dates.
      </p>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Gantt (requires BOTH start_date AND due_date)
// ---------------------------------------------------------------------------

const DAY_W = 34;   // px per day column
const LABEL_W = 220; // px for the left task-name column

function GanttView(props: {
  items: TaskItem[];
  statusColor: (key: string) => string;
  statusLabel: (key: string) => string;
  onEdit: (item: TaskItem) => void;
}) {
  const { items, statusColor, statusLabel, onEdit } = props;

  // Only items that have BOTH a start and a due date appear on the gantt.
  const rows = useMemo(() => {
    return items
      .filter((i) => i.start_date && i.due_date)
      .map((i) => {
        let ds = toDays(i.start_date as string);
        let de = toDays(i.due_date as string);
        if (de < ds) [ds, de] = [de, ds];
        return { item: i, ds, de };
      })
      .sort((a, b) => a.ds - b.ds || a.item.title.localeCompare(b.item.title));
  }, [items]);

  const missing = useMemo(
    () => items.filter((i) => !(i.start_date && i.due_date)),
    [items],
  );

  // Responsive scale: stretch day columns to fill the container on wide screens,
  // with a DAY_W floor so narrow screens keep a readable scale + horizontal scroll.
  const trackRef = useRef<HTMLDivElement | null>(null);
  const [containerW, setContainerW] = useState(0);
  useEffect(() => {
    const el = trackRef.current;
    if (!el) return;
    const measure = () => setContainerW(el.clientWidth);
    measure();
    const ro = new ResizeObserver(measure);
    ro.observe(el);
    return () => ro.disconnect();
  }, [rows.length]);

  if (rows.length === 0) {
    return (
      <div className="rounded-xl border border-dashed border-slate-200 p-8 text-center text-sm text-slate-400">
        No tasks to show on the Gantt. Enter <b>both a start and a due date</b> on a task to display it as a bar.
        {missing.length > 0 && (
          <div className="mt-2 text-[11px]">Incomplete dates {missing.length} items: {missing.map((i) => i.title).join(', ')}</div>
        )}
      </div>
    );
  }

  const minDay = Math.min(...rows.map((r) => r.ds)) - 2;
  const maxDay = Math.max(...rows.map((r) => r.de)) + 4;
  const days: number[] = [];
  for (let d = minDay; d <= maxDay; d++) days.push(d);

  const today = toDays(todayStr());
  const dayW = containerW > 0
    ? Math.max(DAY_W, Math.floor((containerW - LABEL_W) / days.length))
    : DAY_W;
  const trackW = days.length * dayW;

  return (
    <div ref={trackRef} className="overflow-x-auto rounded-xl border border-slate-200">
      <div style={{ width: LABEL_W + trackW }}>
        <div className="flex border-b border-slate-200 bg-slate-50">
          <div className="shrink-0 border-r border-slate-200 px-3 py-2 text-[11px] font-semibold uppercase tracking-wide text-slate-400"
            style={{ width: LABEL_W }}>
            Task
          </div>
          <div className="relative flex" style={{ width: trackW }}>
            {days.map((d) => {
              const s = fromDays(d);
              const dow = weekdayOf(s);
              const weekend = dow === 0 || dow === 6;
              const dom = Number(s.slice(8, 10));
              return (
                <div key={d}
                  className={'relative shrink-0 border-r border-slate-100 py-2 text-center text-[10px] ' +
                    (weekend ? 'bg-slate-100/60 text-slate-400' : 'text-slate-400')}
                  style={{ width: dayW }}>
                  {dom === 1 && (
                    <span className="absolute left-1 top-0.5 text-[9px] font-bold text-emerald-600">
                      {MONTHS[Number(s.slice(5, 7)) - 1]}
                    </span>
                  )}
                  {dom}
                </div>
              );
            })}
          </div>
        </div>

        {rows.map(({ item, ds, de }) => {
          const left = (ds - minDay) * dayW;
          const width = (de - ds + 1) * dayW;
          const p = priMeta(item.priority);
          return (
            <div key={item.id} className="flex border-b border-slate-100 last:border-b-0">
              <div className="flex shrink-0 items-center gap-1.5 border-r border-slate-200 px-3 py-2"
                style={{ width: LABEL_W }}>
                <span className={'rounded px-1 py-0.5 text-[8.5px] font-semibold uppercase ' + p.cls}>{p.label}</span>
                <span className="truncate text-[12px] font-medium" title={item.title}>{item.title}</span>
              </div>

              <div className="relative" style={{ width: trackW, height: 38 }}>
                {days.map((d) => {
                  const dow = weekdayOf(fromDays(d));
                  if (dow !== 0 && dow !== 6) return null;
                  return (
                    <div key={`w${d}`} className="absolute top-0 h-full bg-slate-50"
                      style={{ left: (d - minDay) * dayW, width: dayW }} />
                  );
                })}
                {today >= minDay && today <= maxDay && (
                  <div className="absolute top-0 z-10 h-full w-px bg-emerald-500/70"
                    style={{ left: (today - minDay) * dayW + dayW / 2 }} />
                )}
                <div
                  onClick={() => onEdit(item)}
                  className="absolute top-1/2 z-20 flex -translate-y-1/2 cursor-pointer items-center overflow-hidden rounded-md px-2 text-[10.5px] font-medium text-white shadow-sm hover:brightness-95"
                  style={{
                    left: left + 2,
                    width: Math.max(width - 4, dayW - 4),
                    height: 22,
                    background: statusColor(item.status),
                  }}
                  title={`${statusLabel(item.status)} · ${item.start_date} → ${item.due_date}`}
                >
                  <span className="truncate">{item.title}</span>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {missing.length > 0 && (
        <div className="border-t border-slate-200 px-3 py-2 text-[11px] text-slate-400">
          Missing start/due dates {missing.length} items (not on Gantt): {missing.map((i) => i.title).join(', ')}
        </div>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
// TaskModal (create / edit / delete)
// ---------------------------------------------------------------------------

function TaskModal(props: {
  mode: 'create' | 'edit';
  cols: TaskStatusOption[];
  item?: TaskItem;
  presetStatus?: string;
  presetStart?: string | null;
  presetDue?: string | null;
  currentUserId: string | null;
  onCreate: (v: TaskFormValues) => Promise<void>;
  onUpdate: (id: string, v: TaskFormValues) => Promise<void>;
  onDelete: (id: string) => Promise<void>;
  onClose: () => void;
}) {
  const {
    mode, cols, item, presetStatus, presetStart, presetDue,
    currentUserId, onCreate, onUpdate, onDelete, onClose,
  } = props;

  const [title, setTitle] = useState(item?.title ?? '');
  const [status, setStatus] = useState(item?.status ?? presetStatus ?? cols[0]?.key ?? '');
  const [priority, setPriority] = useState<TaskPriority | ''>(
    (item?.priority ?? '') as TaskPriority | '',
  );
  const [startDate, setStartDate] = useState(item?.start_date ?? presetStart ?? '');
  const [dueDate, setDueDate] = useState(item?.due_date ?? presetDue ?? '');
  const [description, setDescription] = useState(item?.description ?? '');
  const [recurKey, setRecurKey] = useState<string>(ruleToKey(item?.recurrence ?? null));
  const [recurEnds, setRecurEnds] = useState(item?.recurrence_ends ?? '');
  const [busy, setBusy] = useState(false);
  const recurRule = RECUR_OPTIONS.find((o) => o.key === recurKey)?.rule ?? null;

  const dateWarn = !!startDate && !!dueDate && toDays(dueDate) < toDays(startDate);
  const canSave = title.trim().length > 0 && !dateWarn && !busy;

  async function save() {
    if (!canSave) return;
    const v: TaskFormValues = {
      title: title.trim(),
      status,
      priority: priority === '' ? null : priority,
      startDate: startDate || null,
      dueDate: dueDate || null,
      description: description.trim() ? description.trim() : null,
      recurrence: recurRule,
      recurrenceEnds: recurRule ? (recurEnds || null) : null,
    };
    setBusy(true);
    try {
      if (mode === 'create') await onCreate(v);
      else if (item) await onUpdate(item.id, v);
      onClose();
    } finally {
      setBusy(false);
    }
  }

  async function remove() {
    if (!item) return;
    if (!window.confirm('Delete this task? This cannot be undone.')) return;
    setBusy(true);
    try {
      await onDelete(item.id);
      onClose();
    } finally {
      setBusy(false);
    }
  }

  const fieldCls =
    'w-full rounded-lg border border-slate-200 px-2.5 py-2 text-sm outline-none focus:border-emerald-500';
  const labelCls = 'mb-1 block text-[11px] font-semibold uppercase tracking-wide text-slate-400';

  const creatorText = !item?.created_by
    ? '—'
    : item.created_by === currentUserId
      ? 'Me (You)'
      : `${item.created_by.slice(0, 8)}…`;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/30 p-4"
      onClick={onClose}
    >
      <div
        className="w-full max-w-md rounded-2xl border border-slate-200 bg-white p-5 shadow-xl"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="mb-3 flex items-center justify-between">
          <h2 className="text-base font-bold">{mode === 'create' ? 'New task' : 'Edit task'}</h2>
          <button type="button" onClick={onClose}
            className="text-slate-400 hover:text-slate-600" aria-label="close">✕</button>
        </div>

        <div className="mb-3">
          <label className={labelCls}>Title</label>
          <input
            autoFocus value={title} onChange={(e) => setTitle(e.target.value)}
            onKeyDown={(e) => { if (e.key === 'Enter' && (e.metaKey || e.ctrlKey)) save(); }}
            placeholder="Task title" className={fieldCls}
          />
        </div>

        <div className="mb-3 grid grid-cols-2 gap-3">
          <div>
            <label className={labelCls}>Status</label>
            <select value={status} onChange={(e) => setStatus(e.target.value)} className={fieldCls}>
              {cols.map((c) => <option key={c.key} value={c.key}>{c.label}</option>)}
            </select>
          </div>
          <div>
            <label className={labelCls}>Priority</label>
            <select value={priority} onChange={(e) => setPriority(e.target.value as TaskPriority | '')} className={fieldCls}>
              <option value="">—</option>
              {PRIORITIES.map((p) => <option key={p} value={p}>{p}</option>)}
            </select>
          </div>
        </div>

        <div className="mb-1 grid grid-cols-2 gap-3">
          <div>
            <label className={labelCls}>Start date</label>
            <input type="date" value={startDate} onChange={(e) => setStartDate(e.target.value)} className={fieldCls} />
          </div>
          <div>
            <label className={labelCls}>Due date</label>
            <input type="date" value={dueDate} onChange={(e) => setDueDate(e.target.value)} className={fieldCls} />
          </div>
        </div>
        {dateWarn && <p className="mb-1 text-[11px] text-red-500">The due date is earlier than the start date.</p>}
        <p className="mb-3 text-[10.5px] text-slate-400">Both a start and a due date are required to appear on the Gantt.</p>

        <div className="mb-3 grid grid-cols-2 gap-3">
          <div>
            <label className={labelCls}>Repeat</label>
            <select value={recurKey} onChange={(e) => setRecurKey(e.target.value)} className={fieldCls}>
              {RECUR_OPTIONS.map((o) => <option key={o.key} value={o.key}>{o.label}</option>)}
            </select>
          </div>
          <div>
            <label className={labelCls}>Repeat until</label>
            <input
              type="date"
              value={recurEnds}
              onChange={(e) => setRecurEnds(e.target.value)}
              disabled={recurKey === 'none'}
              className={fieldCls + (recurKey === 'none' ? ' opacity-40' : '')}
            />
          </div>
        </div>
        {recurKey !== 'none' && !dueDate && (
          <p className="mb-3 text-[11px] text-amber-600">A due date is required for a repeating task to schedule its next occurrence.</p>
        )}

        <div className="mb-3">
          <label className={labelCls}>Description</label>
          <textarea
            value={description} onChange={(e) => setDescription(e.target.value)}
            rows={3} placeholder="(optional)" className={fieldCls + ' resize-none'}
          />
        </div>

        {mode === 'edit' && item && (
          <p className="mb-3 text-[11px] text-slate-400">
            Created by: {creatorText}
            {item.created_at ? ` · created ${item.created_at.slice(0, 10)}` : ''}
          </p>
        )}

        <div className="mt-2 flex items-center gap-2">
          {mode === 'edit' && (
            <button type="button" onClick={remove} disabled={busy}
              className="rounded-lg border border-red-200 px-3 py-2 text-sm font-semibold text-red-600 hover:bg-red-50 disabled:opacity-50">
              Delete
            </button>
          )}
          <div className="ml-auto flex gap-2">
            <button type="button" onClick={onClose}
              className="rounded-lg border border-slate-200 px-3 py-2 text-sm text-slate-500 hover:bg-slate-50">
              Cancel
            </button>
            <button type="button" onClick={save} disabled={!canSave}
              className="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-semibold text-white hover:bg-emerald-700 disabled:opacity-50">
              {busy ? 'Saving…' : 'Save'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
