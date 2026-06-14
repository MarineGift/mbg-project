// src/app/(app)/pipelines/[code]/deals/[id]/add-task-modal.tsx
//
// Client wrapper for the Tasks tab:
//   - "Add task" button (top-right of the tab content)
//   - Modal dialog with 5 fields (title / due / priority / assignee / desc)
//   - Task list rendering (Ad hoc + by-checklist groups)
//
// The server page passes tasks + checklists as props. Assignee search is a
// separate server action (searchContacts) -- the 217 contacts are too many
// for client-side filtering, and most contacts only match by company anyway.

'use client';

import { useEffect, useRef, useState, useTransition } from 'react';
import {
  Plus,
  CheckSquare,
  Square,
  CircleDashed,
  Search,
  User,
  Activity,
  Paperclip,
  ChevronDown,
  ChevronRight,
  ListChecks,
  List,
  CalendarRange,
} from 'lucide-react';
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { addTask, searchContacts, toggleTaskInDeal } from './actions';
import AttachmentsPanel from '@/components/attachments/attachments-panel';

// ============================================================
// Types (duck-typed against server data)
// ============================================================

interface Task {
  id: string;
  title: string;
  description: string | null;
  status: string | null;
  priority: string | null;
  start_at?: string | null;
  due_at: string | null;
  checklist_id: string | null;
  stage_id?: string | null;
  assigned_to_contact_id: string | null;
  assigned_to_user_id: string | null;
  estimated_minutes: number | null;
  // Count of non-deleted engagements linked to this task (engagements.task_id).
  // Attached server-side in the Tasks-tab fetch; absent => 0.
  _activityCount?: number | null;
}

interface Checklist {
  id: string;
  title?: string | null;
  name?: string | null;
  description?: string | null;
  stage_id?: string | null;
}

interface ContactResult {
  id: string;
  full_name: string | null;
  given_name: string | null;
  family_name: string | null;
  email: string | null;
  title_text: string | null;
  firm: { party_name: string | null } | null;
}

interface Props {
  pipelineCode: string;
  dealId: string;
  tasks: Task[];
  checklists: Checklist[];
  stages?: Array<{ id: string; name: string; sort_order: number | null }>;
  currentStageId?: string | null;
}

// ============================================================
// Formatters
// ============================================================

function fmtDate(iso: string | null | undefined): string {
  if (!iso) return '\u2014';
  const d = new Date(iso);
  if (isNaN(d.getTime())) return '\u2014';
  return d.toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' });
}

function fmtRelative(iso: string | null | undefined): string {
  if (!iso) return '';
  const ms = Date.now() - new Date(iso).getTime();
  const future = ms < 0;
  const absDays = Math.floor(Math.abs(ms) / 86_400_000);
  if (absDays < 1) return future ? 'soon' : 'today';
  if (absDays < 30) return future ? 'in ' + absDays + 'd' : absDays + 'd ago';
  if (absDays < 365) {
    const mo = Math.floor(absDays / 30);
    return future ? 'in ' + mo + 'mo' : mo + 'mo ago';
  }
  const y = Math.floor(absDays / 365);
  return future ? 'in ' + y + 'y' : y + 'y ago';
}

function contactLabel(c: ContactResult): string {
  if (c.full_name) return c.full_name;
  if (c.given_name && c.family_name) return c.given_name + ' ' + c.family_name;
  if (c.given_name || c.family_name) return (c.given_name || c.family_name) as string;
  if (c.title_text && c.firm?.party_name) return c.title_text + ' at ' + c.firm.party_name;
  if (c.title_text) return c.title_text;
  if (c.email) return c.email;
  return '(unnamed)';
}

function contactSecondaryLine(c: ContactResult): string {
  const parts: string[] = [];
  if (c.email) parts.push(c.email);
  if (c.title_text && c.firm?.party_name) parts.push(c.title_text + ' @ ' + c.firm.party_name);
  else if (c.firm?.party_name) parts.push(c.firm.party_name);
  else if (c.title_text) parts.push(c.title_text);
  return parts.join(' \u00b7 ');
}

// ============================================================
// Public component
// ============================================================

export function TasksTabClient({ pipelineCode, dealId, tasks, checklists, stages, currentStageId }: Props) {
  const [open, setOpen] = useState(false);
  const [local, setLocal] = useState<Task[]>(tasks);
  const [view, setView] = useState<'list' | 'timeline'>('list');
  const [, startTransition] = useTransition();
  const [collapsedStages, setCollapsedStages] = useState<Set<string>>(() => {
    const s = new Set<string>();
    for (const st of stages ?? []) if (st.id !== currentStageId) s.add(st.id);
    s.add('__other__');
    return s;
  });

  // Resync when the server refreshes (after revalidatePath).
  useEffect(() => {
    setLocal(tasks);
  }, [tasks]);

  const isTaskDone = (t: Task) => t.status === 'completed' || t.status === 'done';
  const doneCount = local.filter(isTaskDone).length;

  // Checklist item titles (for the 2nd-level sub-group labels).
  const checklistTitle = new Map<string, string>();
  for (const c of checklists) checklistTitle.set(c.id, c.title || c.name || 'Checklist');

  // Two-level grouping: Stage (level 1, every pipeline stage in order) ->
  // Checklist item (level 2) -> tasks. Tasks not linked to a checklist item
  // land in a "General" sub-group. Tasks with no/unknown stage land in a
  // trailing "Other" stage group.
  const GENERAL = '__general__';
  const tasksByStage = new Map<string, Task[]>();
  for (const t of local) {
    const key = t.stage_id ?? '__other__';
    if (!tasksByStage.has(key)) tasksByStage.set(key, []);
    tasksByStage.get(key)!.push(t);
  }

  function buildSubgroups(stageId: string | null, stageTasks: Task[]) {
    const byCl = new Map<string, Task[]>();
    for (const t of stageTasks) {
      const k =
        t.checklist_id && checklistTitle.has(t.checklist_id) ? t.checklist_id : GENERAL;
      if (!byCl.has(k)) byCl.set(k, []);
      byCl.get(k)!.push(t);
    }
    // Seed a sub-group for EVERY checklist item of this stage -- even with 0
    // tasks -- so the full Stage > Checklist structure is always visible.
    if (stageId) {
      for (const c of checklists) {
        if (c.stage_id === stageId && !byCl.has(c.id)) byCl.set(c.id, []);
      }
    }
    const keys = Array.from(byCl.keys()).sort((a, b) => {
      if (a === GENERAL) return 1;
      if (b === GENERAL) return -1;
      return (checklistTitle.get(a) ?? '').localeCompare(checklistTitle.get(b) ?? '');
    });
    return keys
      .filter((k) => k !== GENERAL || (byCl.get(k)?.length ?? 0) > 0) // hide empty General
      .map((k) => {
        const list = byCl.get(k) ?? [];
        return {
          key: k,
          label: k === GENERAL ? null : checklistTitle.get(k) ?? 'Checklist',
          tasks: list,
          done: list.filter(isTaskDone).length,
        };
      });
  }

  const stageGroups: Array<{
    key: string;
    label: string;
    isCurrent: boolean;
    tasks: Task[];
    done: number;
    subgroups: ReturnType<typeof buildSubgroups>;
  }> = [];
  for (const st of stages ?? []) {
    const list = tasksByStage.get(st.id) ?? [];
    tasksByStage.delete(st.id);
    stageGroups.push({
      key: st.id,
      label: st.name,
      isCurrent: st.id === currentStageId,
      tasks: list,
      done: list.filter(isTaskDone).length,
      subgroups: buildSubgroups(st.id, list),
    });
  }
  const otherTasks: Task[] = [];
  for (const [, list] of tasksByStage) otherTasks.push(...list);
  if (otherTasks.length > 0) {
    stageGroups.push({
      key: '__other__',
      label: 'Other',
      isCurrent: false,
      tasks: otherTasks,
      done: otherTasks.filter(isTaskDone).length,
      subgroups: buildSubgroups(null, otherTasks),
    });
  }

  function toggleStage(key: string) {
    setCollapsedStages((prev) => {
      const n = new Set(prev);
      if (n.has(key)) n.delete(key);
      else n.add(key);
      return n;
    });
  }

  function toggle(task: Task) {
    const next = !isTaskDone(task);
    setLocal((prev) =>
      prev.map((t) =>
        t.id === task.id ? { ...t, status: next ? 'completed' : 'pending' } : t,
      ),
    );
    startTransition(async () => {
      const r = await toggleTaskInDeal({ pipelineCode, dealId, taskId: task.id, completed: next });
      if (!r.ok) {
        // revert on failure
        setLocal((prev) =>
          prev.map((t) =>
            t.id === task.id ? { ...t, status: next ? 'pending' : 'completed' } : t,
          ),
        );
      }
    });
  }

  return (
    <div>
      {/* Header bar */}
      <div className="mb-3 flex items-center justify-between">
        <div className="text-xs font-medium uppercase tracking-wider text-muted-foreground">
          {local.length === 0 ? 'Tasks' : 'Tasks (' + doneCount + '/' + local.length + ')'}
        </div>
        <div className="flex items-center gap-2">
          {local.length > 0 && (
            <div className="flex items-center rounded-md border p-0.5">
              <button
                type="button"
                onClick={() => setView('list')}
                className={
                  'flex items-center gap-1 rounded px-2 py-1 text-xs ' +
                  (view === 'list'
                    ? 'bg-muted font-medium text-foreground'
                    : 'text-muted-foreground hover:text-foreground')
                }
              >
                <List className="h-3.5 w-3.5" />
                List
              </button>
              <button
                type="button"
                onClick={() => setView('timeline')}
                className={
                  'flex items-center gap-1 rounded px-2 py-1 text-xs ' +
                  (view === 'timeline'
                    ? 'bg-muted font-medium text-foreground'
                    : 'text-muted-foreground hover:text-foreground')
                }
              >
                <CalendarRange className="h-3.5 w-3.5" />
                Timeline
              </button>
            </div>
          )}
          <Button size="sm" onClick={() => setOpen(true)} className="gap-1.5">
            <Plus className="h-3.5 w-3.5" />
            Add task
          </Button>
        </div>
      </div>

      {/* Overall progress */}
      {local.length > 0 && (
        <ProgressBar done={doneCount} total={local.length} className="mb-4" />
      )}

      {/* List or empty state */}
      {local.length === 0 ? (
        <div className="flex flex-col items-center justify-center rounded-lg border bg-card py-16">
          <CheckSquare className="mb-3 h-8 w-8 text-muted-foreground/30" />
          <div className="text-sm font-medium text-foreground">No tasks yet</div>
          <div className="mt-1 max-w-md text-center text-xs text-muted-foreground">
            Click <span className="font-medium">Add task</span> to track what needs to happen next for this deal.
          </div>
        </div>
      ) : view === 'timeline' ? (
        <TaskGantt stageGroups={stageGroups} onToggleTask={toggle} />
      ) : (
        <div className="space-y-3">
          {stageGroups.map((g) => (
            <StageGroup
              key={g.key}
              label={g.label}
              isCurrent={g.isCurrent}
              done={g.done}
              total={g.tasks.length}
              subgroups={g.subgroups}
              collapsed={collapsedStages.has(g.key)}
              onToggleCollapse={() => toggleStage(g.key)}
              onToggleTask={toggle}
            />
          ))}
        </div>
      )}

      <AddTaskModal
        open={open}
        onOpenChange={setOpen}
        pipelineCode={pipelineCode}
        dealId={dealId}
        checklists={checklists}
        stages={stages}
        currentStageId={currentStageId}
      />
    </div>
  );
}

// ============================================================
// TaskGantt -- Timeline view of the deal's tasks.
// Reuses the same Stage -> Checklist-item -> Task grouping as the list, but
// only shows populated stages / checklist items. Bars span start_at..due_at;
// a due-only task gets a short bar ending on its due date; a task with no
// dates shows a muted note. A single "now" line spans the rows.
// ============================================================

const DAY_MS = 86_400_000;

function ganttBounds(t: Task): { s: number | null; e: number | null } {
  const start = t.start_at ? new Date(t.start_at).getTime() : NaN;
  const due = t.due_at ? new Date(t.due_at).getTime() : NaN;
  return {
    s: isNaN(start) ? null : start,
    e: isNaN(due) ? null : due,
  };
}

type GanttStageGroup = {
  key: string;
  label: string;
  isCurrent: boolean;
  subgroups: Array<{ key: string; label: string | null; tasks: Task[] }>;
};

function TaskGantt({
  stageGroups,
  onToggleTask,
}: {
  stageGroups: GanttStageGroup[];
  onToggleTask: (t: Task) => void;
}) {
  type Row =
    | { kind: 'stage'; label: string; current: boolean }
    | { kind: 'checklist'; label: string }
    | { kind: 'task'; task: Task };

  const rows: Row[] = [];
  const dated: Task[] = [];
  for (const g of stageGroups) {
    const populated = g.subgroups.filter((sg) => sg.tasks.length > 0);
    if (populated.length === 0) continue;
    rows.push({ kind: 'stage', label: g.label, current: g.isCurrent });
    for (const sg of populated) {
      if (sg.label != null) rows.push({ kind: 'checklist', label: sg.label });
      for (const t of sg.tasks) {
        rows.push({ kind: 'task', task: t });
        dated.push(t);
      }
    }
  }

  const now = Date.now();
  const stamps: number[] = [now];
  let hasDated = false;
  for (const t of dated) {
    const { s, e } = ganttBounds(t);
    if (s != null) {
      stamps.push(s);
      hasDated = true;
    }
    if (e != null) {
      stamps.push(e);
      hasDated = true;
    }
  }

  if (rows.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center rounded-lg border bg-card py-12">
        <CalendarRange className="mb-3 h-8 w-8 text-muted-foreground/30" />
        <div className="text-sm font-medium text-foreground">Nothing to schedule</div>
        <div className="mt-1 text-xs text-muted-foreground">Add a task to see it on the timeline.</div>
      </div>
    );
  }
  if (!hasDated) {
    return (
      <div className="flex flex-col items-center justify-center rounded-lg border bg-card py-12">
        <CalendarRange className="mb-3 h-8 w-8 text-muted-foreground/30" />
        <div className="text-sm font-medium text-foreground">No dates yet</div>
        <div className="mt-1 max-w-sm text-center text-xs text-muted-foreground">
          Give tasks a start and/or due date (in <span className="font-medium">Add task</span>) to place them on the
          timeline.
        </div>
      </div>
    );
  }

  let t0 = Math.min(...stamps);
  let t1 = Math.max(...stamps);
  if (t1 - t0 < DAY_MS) {
    t0 -= DAY_MS * 2;
    t1 += DAY_MS * 2;
  } else {
    t0 -= DAY_MS;
    t1 += DAY_MS;
  }
  const span = t1 - t0 || 1;
  const pct = (ms: number) => ((ms - t0) / span) * 100;
  const todayPct = pct(now);

  return (
    <div className="overflow-x-auto rounded-lg border bg-card">
      <div className="min-w-[640px]">
        <div className="flex">
          {/* Left: grouped labels */}
          <div className="w-52 shrink-0 border-r">
            <div className="h-7 border-b bg-muted/30" />
            {rows.map((r, i) => {
              if (r.kind === 'stage')
                return (
                  <div
                    key={'l' + i}
                    className={
                      'flex h-7 items-center gap-1.5 px-3 text-xs font-semibold ' +
                      (r.current ? 'text-emerald-700' : 'text-foreground')
                    }
                  >
                    <span className="truncate">{r.label}</span>
                    {r.current && (
                      <span className="shrink-0 rounded bg-emerald-100 px-1 text-[10px] font-medium text-emerald-700">
                        current
                      </span>
                    )}
                  </div>
                );
              if (r.kind === 'checklist')
                return (
                  <div
                    key={'l' + i}
                    className="flex h-7 items-center gap-1.5 pl-5 pr-3 text-xs text-muted-foreground"
                  >
                    <ListChecks className="h-3 w-3 shrink-0 text-emerald-500" />
                    <span className="truncate">{r.label}</span>
                  </div>
                );
              const isDone = r.task.status === 'completed' || r.task.status === 'done';
              return (
                <button
                  key={'l' + i}
                  type="button"
                  onClick={() => onToggleTask(r.task)}
                  className="flex h-7 w-full items-center pl-8 pr-3 text-left text-xs hover:bg-muted/40"
                  title="Toggle complete"
                >
                  <span className={'truncate ' + (isDone ? 'text-muted-foreground line-through' : 'text-foreground')}>
                    {r.task.title}
                  </span>
                </button>
              );
            })}
          </div>

          {/* Right: timeline */}
          <div className="relative flex-1">
            <div className="relative h-7 border-b bg-muted/30 text-[10px] text-muted-foreground">
              <span className="absolute left-2 top-1/2 -translate-y-1/2">
                {fmtDate(new Date(t0).toISOString())}
              </span>
              <span className="absolute right-2 top-1/2 -translate-y-1/2">
                {fmtDate(new Date(t1).toISOString())}
              </span>
            </div>
            {todayPct >= 0 && todayPct <= 100 && (
              <div
                className="pointer-events-none absolute z-10 w-px bg-rose-400/70"
                style={{ left: todayPct + '%', top: '1.75rem', bottom: 0 }}
              >
                <span className="absolute -top-0 left-1 text-[9px] font-medium text-rose-500">now</span>
              </div>
            )}
            {rows.map((r, i) => {
              if (r.kind !== 'task') return <div key={'t' + i} className="h-7" />;
              const { s, e } = ganttBounds(r.task);
              const isDone = r.task.status === 'completed' || r.task.status === 'done';
              if (s == null && e == null)
                return (
                  <div key={'t' + i} className="flex h-7 items-center px-2">
                    <span className="text-[10px] italic text-muted-foreground/60">no dates</span>
                  </div>
                );
              const end = e ?? (s as number);
              const startMs = s ?? end - DAY_MS;
              const overdue = e != null && e < now && !isDone;
              const left = pct(startMs);
              const width = Math.max(1.5, pct(end) - left);
              const barCls = isDone
                ? 'bg-muted-foreground/30'
                : overdue
                  ? 'bg-rose-400'
                  : 'bg-sky-500';
              const range =
                (s != null ? fmtDate(r.task.start_at) + ' \u2192 ' : 'due ') +
                fmtDate(r.task.due_at ?? r.task.start_at);
              return (
                <div key={'t' + i} className="relative h-7">
                  <div
                    className={'absolute top-1.5 h-4 rounded ' + barCls}
                    style={{ left: left + '%', width: width + '%' }}
                    title={r.task.title + '  (' + range + ')'}
                  />
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}

// ============================================================
// Task list rendering
// ============================================================

function ProgressBar({
  done,
  total,
  className,
}: {
  done: number;
  total: number;
  className?: string;
}) {
  const pct = total > 0 ? Math.round((done / total) * 100) : 0;
  return (
    <div
      className={'h-1.5 w-full overflow-hidden rounded-full bg-muted ' + (className ?? '')}
      role="progressbar"
      aria-valuenow={pct}
      aria-valuemin={0}
      aria-valuemax={100}
    >
      <div
        className="h-full rounded-full bg-emerald-500 transition-all"
        style={{ width: pct + '%' }}
      />
    </div>
  );
}

function StageGroup({
  label,
  isCurrent,
  done,
  total,
  subgroups,
  collapsed,
  onToggleCollapse,
  onToggleTask,
}: {
  label: string;
  isCurrent: boolean;
  done: number;
  total: number;
  subgroups: Array<{ key: string; label: string | null; tasks: Task[]; done: number }>;
  collapsed: boolean;
  onToggleCollapse: () => void;
  onToggleTask: (t: Task) => void;
}) {
  const isOpen = !collapsed;
  // Show 2nd-level sub-headers only when meaningful (more than one sub-group,
  // or a single checklist-linked sub-group). All-"General" stays flat.
  const showSubHeaders =
    subgroups.length > 1 || (subgroups.length === 1 && subgroups[0]?.label != null);
  return (
    <div className="rounded-lg border bg-card">
      <div
        role="button"
        tabIndex={0}
        onClick={onToggleCollapse}
        onKeyDown={(e) => {
          if (e.key === 'Enter' || e.key === ' ') {
            e.preventDefault();
            onToggleCollapse();
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
            <span className="truncate text-sm font-medium text-foreground">{label}</span>
            {isCurrent && (
              <span className="shrink-0 rounded bg-emerald-100 px-1.5 py-0.5 text-[10px] font-medium text-emerald-700">
                Current
              </span>
            )}
          </div>
          <span className="shrink-0 text-xs text-muted-foreground tabular-nums">
            {done}/{total}
          </span>
        </div>
        {total > 0 && <ProgressBar done={done} total={total} className="mt-2" />}
      </div>

      {isOpen &&
        (subgroups.length === 0 ? (
          <div className="px-4 py-4 text-center text-xs text-muted-foreground/70">
            No tasks yet{isCurrent ? '' : ' — added when the deal reaches this stage'}
          </div>
        ) : (
          <div>
            {subgroups.map((sg) => {
              const isChecklist = sg.label != null;
              const rail =
                showSubHeaders
                  ? isChecklist
                    ? ' ml-[1.6rem] border-l-2 border-emerald-200'
                    : ' ml-[1.6rem] border-l-2 border-muted'
                  : '';
              return (
                <div key={sg.key}>
                  {showSubHeaders && (
                    <div className="flex items-center gap-2 border-b bg-muted/40 px-4 py-2">
                      {isChecklist ? (
                        <ListChecks className="h-4 w-4 shrink-0 text-emerald-600" />
                      ) : (
                        <CircleDashed className="h-4 w-4 shrink-0 text-muted-foreground" />
                      )}
                      <span
                        className={
                          'flex-1 truncate text-xs ' +
                          (isChecklist
                            ? 'font-semibold text-foreground'
                            : 'font-medium text-muted-foreground')
                        }
                      >
                        {sg.label ?? 'General (not under a checklist item)'}
                      </span>
                      <span className="shrink-0 text-[11px] text-muted-foreground tabular-nums">
                        {sg.done}/{sg.tasks.length}
                      </span>
                    </div>
                  )}
                  {sg.tasks.length === 0 ? (
                    <div className={'px-4 py-2 text-[11px] text-muted-foreground/60' + rail}>
                      No tasks yet — add one and link it to this item
                    </div>
                  ) : (
                    <ul className={'divide-y' + rail}>
                      {sg.tasks.map((t) => (
                        <TaskRow key={t.id} task={t} onToggle={onToggleTask} />
                      ))}
                    </ul>
                  )}
                </div>
              );
            })}
          </div>
        ))}
    </div>
  );
}

function TaskRow({ task: t, onToggle }: { task: Task; onToggle: (t: Task) => void }) {
  const [filesOpen, setFilesOpen] = useState(false);
  const status = String(t.status || 'pending').toLowerCase();
  const isDone = status === 'completed' || status === 'done';
  const isInProgress = status === 'in_progress' || status === 'in-progress';
  const StatusIcon = isDone ? CheckSquare : isInProgress ? CircleDashed : Square;
  const statusIconCls = isDone
    ? 'text-foreground/70'
    : isInProgress
    ? 'text-amber-600'
    : 'text-muted-foreground';

  const priority = String(t.priority || '').toLowerCase();
  const priorityCls =
    priority === 'high'
      ? 'text-rose-700'
      : priority === 'low'
      ? 'text-zinc-500'
      : 'text-amber-700';

  const due = t.due_at;
  const start = t.start_at;
  const isOverdue = !!(due && !isDone && new Date(due).getTime() < Date.now());
  const dueRelative = due && !isDone ? fmtRelative(due) : '';
  const durationDays =
    start && due
      ? Math.max(
          0,
          Math.round(
            (new Date(due).getTime() - new Date(start).getTime()) / 86400000,
          ),
        )
      : null;

  const activityCount = t._activityCount ?? 0;
  const showPriority = !!(priority && priority !== 'medium');
  const hasMeta = !!(
    showPriority ||
    start ||
    due ||
    t.assigned_to_contact_id ||
    t.assigned_to_user_id ||
    t.estimated_minutes != null
  );

  return (
    <li className="px-4 py-2.5">
      <div className="flex items-start gap-3">
        <button
          type="button"
          onClick={() => onToggle(t)}
          aria-label={isDone ? 'mark incomplete' : 'mark complete'}
          className="mt-0.5 shrink-0"
        >
          <StatusIcon className={'h-4 w-4 ' + statusIconCls} />
        </button>
        <div className="min-w-0 flex-1">
          <div
            className={
              'text-sm ' + (isDone ? 'text-muted-foreground line-through' : 'text-foreground')
            }
          >
            {t.title}
          </div>
          <div className="mt-0.5 flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
            {priority && priority !== 'medium' && (
              <span className={'font-medium capitalize ' + priorityCls}>{priority}</span>
            )}
            {start && (
              <>
                {showPriority && <span className="opacity-40">{'\u00b7'}</span>}
                <span>Start {fmtDate(start)}</span>
              </>
            )}
            {due && (
              <>
                {(showPriority || start) && (
                  <span className="opacity-40">{'\u00b7'}</span>
                )}
                <span className={isOverdue ? 'font-medium text-rose-700' : ''}>
                  Due {fmtDate(due)}
                  {dueRelative ? ' (' + dueRelative + ')' : ''}
                </span>
              </>
            )}
            {durationDays != null && (
              <>
                <span className="opacity-40">{'\u00b7'}</span>
                <span className="tabular-nums" title="planned duration">
                  {durationDays}d
                </span>
              </>
            )}
            {(t.assigned_to_contact_id || t.assigned_to_user_id) && (
              <>
                <span className="opacity-40">{'\u00b7'}</span>
                <span>Assigned</span>
              </>
            )}
            {t.estimated_minutes != null && (
              <>
                <span className="opacity-40">{'\u00b7'}</span>
                <span>{t.estimated_minutes}m est</span>
              </>
            )}
            {activityCount > 0 && (
              <>
                {hasMeta && <span className="opacity-40">{'\u00b7'}</span>}
                <span className="inline-flex items-center gap-1 text-foreground/70">
                  <Activity className="h-3 w-3" />
                  {activityCount} {activityCount === 1 ? 'activity' : 'activities'}
                </span>
              </>
            )}
            {(hasMeta || activityCount > 0) && (
              <span className="opacity-40">{'\u00b7'}</span>
            )}
            <button
              type="button"
              onClick={() => setFilesOpen((v) => !v)}
              className="inline-flex items-center gap-1 hover:text-foreground"
            >
              <Paperclip className="h-3 w-3" />
              {filesOpen ? 'Hide files' : 'Files'}
            </button>
          </div>
          {t.description && (
            <p className="mt-1.5 line-clamp-2 text-xs text-muted-foreground">{t.description}</p>
          )}
        </div>
      </div>
      {filesOpen && (
        <div className="mt-2 pl-7">
          <AttachmentsPanel entityType="task" entityId={t.id} title="Attachments" />
        </div>
      )}
    </li>
  );
}

// ============================================================
// Modal
// ============================================================

function AddTaskModal({
  open,
  onOpenChange,
  pipelineCode,
  dealId,
  checklists,
  stages,
  currentStageId,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  pipelineCode: string;
  dealId: string;
  checklists: Checklist[];
  stages?: Array<{ id: string; name: string; sort_order: number | null }>;
  currentStageId?: string | null;
}) {
  const [title, setTitle] = useState('');
  const [checklistId, setChecklistId] = useState('');
  const [startDate, setStartDate] = useState('');
  const [dueDate, setDueDate] = useState('');
  const [priority, setPriority] = useState<'low' | 'medium' | 'high'>('medium');
  const [contactId, setContactId] = useState('');
  const [contactDisplay, setContactDisplay] = useState('');
  const [description, setDescription] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  useEffect(() => {
    if (open) {
      setTitle('');
      setChecklistId('');
      setStartDate('');
      setDueDate('');
      setPriority('medium');
      setContactId('');
      setContactDisplay('');
      setDescription('');
      setError(null);
    }
  }, [open]);

  const modalStageName = new Map<string, string>();
  const modalStageOrder = new Map<string, number>();
  (stages ?? []).forEach((s, i) => {
    modalStageName.set(s.id, s.name);
    modalStageOrder.set(s.id, s.sort_order ?? i);
  });
  const orderedModalChecklists = [...checklists].sort((a, b) => {
    const ra =
      (a.stage_id === currentStageId ? 0 : 1_000_000) +
      (a.stage_id ? modalStageOrder.get(a.stage_id) ?? 9999 : 9999);
    const rb =
      (b.stage_id === currentStageId ? 0 : 1_000_000) +
      (b.stage_id ? modalStageOrder.get(b.stage_id) ?? 9999 : 9999);
    return ra - rb;
  });

  const handleSubmit = () => {
    setError(null);
    const trimmedTitle = title.trim();
    if (!trimmedTitle) {
      setError('Title is required');
      return;
    }
    if (!checklistId) {
      setError('Pick the checklist item this task belongs to');
      return;
    }

    // Store as UTC noon of the picked date -- timezone-safe across the
    // entire UTC-10 to UTC+12 range (everywhere people live).
    const startIso = startDate ? startDate + 'T12:00:00.000Z' : null;
    const dueIso = dueDate ? dueDate + 'T12:00:00.000Z' : null;

    if (startIso && dueIso && startIso > dueIso) {
      setError('Start date must be on or before the due date');
      return;
    }

    startTransition(async () => {
      const result = await addTask({
        pipelineCode,
        dealId,
        title: trimmedTitle,
        checklist_id: checklistId || null,
        start_at: startIso,
        due_at: dueIso,
        priority,
        assigned_to_contact_id: contactId || null,
        description: description.trim() || null,
      });
      if (!result.ok) {
        setError(result.error);
        return;
      }
      onOpenChange(false);
      // No navigation -- revalidatePath refreshes the page below.
    });
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle>Add task</DialogTitle>
        </DialogHeader>

        <div className="space-y-4 py-2">
          {/* Title */}
          <div>
            <label
              htmlFor="task-title"
              className="mb-1 block text-sm font-medium text-foreground"
            >
              Title <span className="text-rose-600">*</span>
            </label>
            <input
              id="task-title"
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Send Series A term sheet draft"
              className="w-full rounded-md border bg-background px-3 py-2 text-sm focus:border-foreground/30 focus:outline-none focus:ring-2 focus:ring-foreground/5"
              maxLength={200}
              autoFocus
              disabled={isPending}
            />
          </div>

          {/* Checklist item (REQUIRED -- tasks always live under a checklist item) */}
          <div>
            <label
              htmlFor="task-checklist"
              className="mb-1 block text-sm font-medium text-foreground"
            >
              Checklist item <span className="text-rose-600">*</span>
            </label>
            {checklists.length === 0 ? (
              <div className="rounded-md border bg-muted/30 px-3 py-2 text-xs text-muted-foreground">
                This deal has no checklist items yet. Add one in the Checklist tab first,
                then come back to attach a task to it.
              </div>
            ) : (
              <select
                id="task-checklist"
                value={checklistId}
                onChange={(e) => setChecklistId(e.target.value)}
                disabled={isPending}
                className="w-full rounded-md border bg-background px-3 py-2 text-sm focus:border-foreground/30 focus:outline-none focus:ring-2 focus:ring-foreground/5"
              >
                <option value="">Select a checklist item…</option>
                {orderedModalChecklists.map((c) => {
                  const sn = c.stage_id ? modalStageName.get(c.stage_id) : null;
                  return (
                    <option key={c.id} value={c.id}>
                      {sn ? sn + ' \u00b7 ' : ''}
                      {c.title || c.name || 'Checklist item'}
                    </option>
                  );
                })}
              </select>
            )}
          </div>

          {/* Start + Due dates (range -> enables duration analysis) */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label
                htmlFor="task-start"
                className="mb-1 block text-sm font-medium text-foreground"
              >
                Start date
                <span className="ml-1 text-xs font-normal text-muted-foreground">optional</span>
              </label>
              <input
                id="task-start"
                type="date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
                className="w-full rounded-md border bg-background px-3 py-2 text-sm focus:border-foreground/30 focus:outline-none focus:ring-2 focus:ring-foreground/5"
                disabled={isPending}
              />
            </div>
            <div>
              <label
                htmlFor="task-due"
                className="mb-1 block text-sm font-medium text-foreground"
              >
                Due date
                <span className="ml-1 text-xs font-normal text-muted-foreground">optional</span>
              </label>
              <input
                id="task-due"
                type="date"
                value={dueDate}
                onChange={(e) => setDueDate(e.target.value)}
                className="w-full rounded-md border bg-background px-3 py-2 text-sm focus:border-foreground/30 focus:outline-none focus:ring-2 focus:ring-foreground/5"
                disabled={isPending}
              />
            </div>
          </div>

          {/* Priority */}
          <div>
            <label className="mb-1.5 block text-sm font-medium text-foreground">
              Priority
            </label>
            <div className="grid grid-cols-3 gap-1.5">
              {(['low', 'medium', 'high'] as const).map((p) => {
                const active = priority === p;
                const activeCls =
                  p === 'high'
                    ? 'border-rose-600 bg-rose-600 text-white'
                    : p === 'low'
                    ? 'border-zinc-500 bg-zinc-500 text-white'
                    : 'border-amber-600 bg-amber-600 text-white';
                return (
                  <button
                    key={p}
                    type="button"
                    onClick={() => setPriority(p)}
                    disabled={isPending}
                    className={
                      'rounded-md border px-3 py-1.5 text-xs capitalize transition ' +
                      (active
                        ? activeCls
                        : 'border-border bg-background text-foreground hover:bg-muted')
                    }
                  >
                    {p}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Assignee */}
          <div>
            <label className="mb-1 block text-sm font-medium text-foreground">
              Assignee
              <span className="ml-1 text-xs font-normal text-muted-foreground">optional</span>
            </label>
            <ContactSearchInput
              contactId={contactId}
              displayName={contactDisplay}
              onSelect={({ id, label }) => {
                setContactId(id);
                setContactDisplay(label);
              }}
              onClear={() => {
                setContactId('');
                setContactDisplay('');
              }}
              disabled={isPending}
            />
          </div>

          {/* Description */}
          <div>
            <label
              htmlFor="task-desc"
              className="mb-1 block text-sm font-medium text-foreground"
            >
              Description
              <span className="ml-1 text-xs font-normal text-muted-foreground">optional</span>
            </label>
            <textarea
              id="task-desc"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              rows={3}
              className="w-full resize-none rounded-md border bg-background px-3 py-2 text-sm focus:border-foreground/30 focus:outline-none focus:ring-2 focus:ring-foreground/5"
              disabled={isPending}
            />
          </div>

          {error && (
            <div className="rounded-md bg-rose-50 px-3 py-2 text-sm text-rose-700 ring-1 ring-inset ring-rose-200">
              {error}
            </div>
          )}
        </div>

        <DialogFooter>
          <Button
            variant="outline"
            onClick={() => onOpenChange(false)}
            disabled={isPending}
          >
            Cancel
          </Button>
          <Button onClick={handleSubmit} disabled={isPending}>
            {isPending ? 'Adding...' : 'Add task'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

// ============================================================
// Contact search (debounced, server-side)
// ============================================================

function ContactSearchInput({
  contactId,
  displayName,
  onSelect,
  onClear,
  disabled,
}: {
  contactId: string;
  displayName: string;
  onSelect: (sel: { id: string; label: string }) => void;
  onClear: () => void;
  disabled?: boolean;
}) {
  // === ALL HOOKS FIRST -- before any conditional return ===
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<ContactResult[]>([]);
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    const handler = (e: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, [open]);

  // Now branch on selected vs unselected
  if (contactId) {
    return (
      <div className="flex items-center gap-2 rounded-md border bg-muted/30 px-3 py-2 text-sm">
        <User className="h-4 w-4 shrink-0 text-muted-foreground" />
        <span className="flex-1 truncate font-medium text-foreground">{displayName}</span>
        <button
          type="button"
          onClick={onClear}
          disabled={disabled}
          className="text-xs text-muted-foreground hover:text-foreground disabled:opacity-50"
        >
          Change
        </button>
      </div>
    );
  }

  const runSearch = (q: string) => {
    if (debounceRef.current) clearTimeout(debounceRef.current);
    if (!q.trim()) {
      setResults([]);
      setOpen(false);
      return;
    }
    debounceRef.current = setTimeout(async () => {
      setLoading(true);
      try {
        const r = await searchContacts(q);
        setResults(r);
        setOpen(true);
      } finally {
        setLoading(false);
      }
    }, 250);
  };

  return (
    <div ref={containerRef} className="relative">
      <div className="relative">
        <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <input
          type="text"
          value={query}
          onChange={(e) => {
            setQuery(e.target.value);
            runSearch(e.target.value);
          }}
          onFocus={() => {
            if (query.trim() && results.length > 0) setOpen(true);
          }}
          placeholder="Search contacts by name or email..."
          disabled={disabled}
          className="w-full rounded-md border bg-background py-2 pl-9 pr-3 text-sm focus:border-foreground/30 focus:outline-none focus:ring-2 focus:ring-foreground/5"
        />
      </div>

      {open && (
        <div className="absolute z-50 mt-1 w-full overflow-hidden rounded-md border bg-popover shadow-md">
          {loading ? (
            <div className="px-3 py-2 text-xs text-muted-foreground">Searching...</div>
          ) : results.length === 0 ? (
            <div className="px-3 py-3 text-xs text-muted-foreground">No contacts found</div>
          ) : (
            <ul className="max-h-60 overflow-y-auto py-1">
              {results.map((c) => {
                const label = contactLabel(c);
                const sub = contactSecondaryLine(c);
                return (
                  <li key={c.id}>
                    <button
                      type="button"
                      onClick={() => {
                        onSelect({ id: c.id, label });
                        setOpen(false);
                        setQuery('');
                        setResults([]);
                      }}
                      className="block w-full px-3 py-1.5 text-left text-sm hover:bg-muted"
                    >
                      <div className="font-medium text-foreground">{label}</div>
                      {sub && (
                        <div className="mt-0.5 line-clamp-1 text-xs text-muted-foreground">
                          {sub}
                        </div>
                      )}
                    </button>
                  </li>
                );
              })}
            </ul>
          )}
        </div>
      )}
    </div>
  );
}
