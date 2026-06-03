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
} from 'lucide-react';
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { addTask, searchContacts } from './actions';

// ============================================================
// Types (duck-typed against server data)
// ============================================================

interface Task {
  id: string;
  title: string;
  description: string | null;
  status: string | null;
  priority: string | null;
  due_at: string | null;
  checklist_id: string | null;
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

export function TasksTabClient({ pipelineCode, dealId, tasks, checklists }: Props) {
  const [open, setOpen] = useState(false);

  const adHoc = tasks.filter((t) => !t.checklist_id);
  const byChecklist = new Map<string, Task[]>();
  for (const c of checklists) byChecklist.set(c.id, []);
  for (const t of tasks) {
    if (t.checklist_id && byChecklist.has(t.checklist_id)) {
      byChecklist.get(t.checklist_id)!.push(t);
    }
  }

  return (
    <div>
      {/* Header bar */}
      <div className="mb-3 flex items-center justify-between">
        <div className="text-xs font-medium uppercase tracking-wider text-muted-foreground">
          {tasks.length === 0 ? 'Tasks' : 'Tasks (' + tasks.length + ')'}
        </div>
        <Button size="sm" onClick={() => setOpen(true)} className="gap-1.5">
          <Plus className="h-3.5 w-3.5" />
          Add task
        </Button>
      </div>

      {/* List or empty state */}
      {tasks.length === 0 ? (
        <div className="flex flex-col items-center justify-center rounded-lg border bg-card py-16">
          <CheckSquare className="mb-3 h-8 w-8 text-muted-foreground/30" />
          <div className="text-sm font-medium text-foreground">No tasks yet</div>
          <div className="mt-1 max-w-md text-center text-xs text-muted-foreground">
            Click <span className="font-medium">Add task</span> to track what needs to happen next for this deal.
          </div>
        </div>
      ) : (
        <div className="space-y-4">
          {adHoc.length > 0 && (
            checklists.length > 0 ? (
              // Mixed: standalone tasks get an "Other tasks" header so they
              // don't visually merge with named checklists.
              <TaskGroup title="Other tasks" tasks={adHoc} />
            ) : (
              // Only standalone tasks: skip the group header entirely.
              <div className="rounded-lg border bg-card">
                <ul className="divide-y">
                  {adHoc.map((t) => (
                    <TaskRow key={t.id} task={t} />
                  ))}
                </ul>
              </div>
            )
          )}
          {checklists.map((c) => (
            <TaskGroup
              key={c.id}
              title={c.title || c.name || 'Checklist'}
              description={c.description ?? null}
              tasks={byChecklist.get(c.id) ?? []}
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
      />
    </div>
  );
}

// ============================================================
// Task list rendering
// ============================================================

function TaskGroup({
  title,
  description,
  tasks,
}: {
  title: string;
  description?: string | null;
  tasks: Task[];
}) {
  const done = tasks.filter((t) => t.status === 'completed' || t.status === 'done').length;
  return (
    <div className="rounded-lg border bg-card">
      <div className="flex items-center justify-between border-b px-4 py-3">
        <div className="min-w-0">
          <div className="text-sm font-medium text-foreground">{title}</div>
          {description && (
            <div className="mt-0.5 text-xs text-muted-foreground">{description}</div>
          )}
        </div>
        <div className="shrink-0 text-xs text-muted-foreground tabular-nums">
          {done}/{tasks.length}
        </div>
      </div>
      {tasks.length === 0 ? (
        <div className="px-4 py-6 text-center text-xs text-muted-foreground/70">No tasks</div>
      ) : (
        <ul className="divide-y">
          {tasks.map((t) => (
            <TaskRow key={t.id} task={t} />
          ))}
        </ul>
      )}
    </div>
  );
}

function TaskRow({ task: t }: { task: Task }) {
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
  const isOverdue = !!(due && !isDone && new Date(due).getTime() < Date.now());
  const dueRelative = due && !isDone ? fmtRelative(due) : '';

  const activityCount = t._activityCount ?? 0;
  const showPriority = !!(priority && priority !== 'medium');
  const hasMeta = !!(
    showPriority ||
    due ||
    t.assigned_to_contact_id ||
    t.assigned_to_user_id ||
    t.estimated_minutes != null
  );

  return (
    <li className="flex items-start gap-3 px-4 py-2.5">
      <div className="mt-0.5">
        <StatusIcon className={'h-4 w-4 ' + statusIconCls} />
      </div>
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
          {due && (
            <>
              {priority && priority !== 'medium' && (
                <span className="opacity-40">{'\u00b7'}</span>
              )}
              <span className={isOverdue ? 'font-medium text-rose-700' : ''}>
                Due {fmtDate(due)}
                {dueRelative ? ' (' + dueRelative + ')' : ''}
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
        </div>
        {t.description && (
          <p className="mt-1.5 line-clamp-2 text-xs text-muted-foreground">{t.description}</p>
        )}
      </div>
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
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  pipelineCode: string;
  dealId: string;
  checklists: Checklist[];
}) {
  const [title, setTitle] = useState('');
  const [checklistId, setChecklistId] = useState('');
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
      setDueDate('');
      setPriority('medium');
      setContactId('');
      setContactDisplay('');
      setDescription('');
      setError(null);
    }
  }, [open]);

  const handleSubmit = () => {
    setError(null);
    const trimmedTitle = title.trim();
    if (!trimmedTitle) {
      setError('Title is required');
      return;
    }

    // Store as UTC noon of the picked date -- timezone-safe across the
    // entire UTC-10 to UTC+12 range (everywhere people live).
    const dueIso = dueDate ? dueDate + 'T12:00:00.000Z' : null;

    startTransition(async () => {
      const result = await addTask({
        pipelineCode,
        dealId,
        title: trimmedTitle,
        checklist_id: checklistId || null,
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

          {/* Checklist item (only when the deal has checklist items) */}
          {checklists.length > 0 && (
            <div>
              <label
                htmlFor="task-checklist"
                className="mb-1 block text-sm font-medium text-foreground"
              >
                Checklist item
                <span className="ml-1 text-xs font-normal text-muted-foreground">optional</span>
              </label>
              <select
                id="task-checklist"
                value={checklistId}
                onChange={(e) => setChecklistId(e.target.value)}
                disabled={isPending}
                className="w-full rounded-md border bg-background px-3 py-2 text-sm focus:border-foreground/30 focus:outline-none focus:ring-2 focus:ring-foreground/5"
              >
                <option value="">No checklist item (standalone)</option>
                {checklists.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.title || c.name || 'Checklist item'}
                  </option>
                ))}
              </select>
            </div>
          )}

          {/* Due date */}
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
