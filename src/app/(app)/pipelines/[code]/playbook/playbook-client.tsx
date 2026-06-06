'use client';

// Stage Playbook editor UI. Per stage, manage checklist templates and task
// templates (create / edit / delete). All mutations go through the server
// actions in lib/actions/stage-playbooks.ts; on success we router.refresh() to
// re-read the server component.

import { useState, useTransition, type ReactNode } from 'react';
import { useRouter } from 'next/navigation';
import { Plus, Pencil, Trash2, Check, X, ListTodo, CheckSquare } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import {
  createChecklistTemplate, updateChecklistTemplate, deleteChecklistTemplate,
  createTaskTemplate, updateTaskTemplate, deleteTaskTemplate,
} from '@/lib/actions/stage-playbooks';
import type { PlaybookStage, ChecklistTemplate, TaskTemplate, TemplatePriority } from '@/lib/queries/stage-playbooks';

type ActionResult = { ok: boolean; errorMessage?: string };
type Run = (fn: () => Promise<ActionResult>) => void;

const INPUT =
  'h-9 w-full rounded-md border border-input bg-background px-2 text-sm focus:outline-none focus:ring-1 focus:ring-ring';
const PRIORITY_STYLE: Record<TemplatePriority, string> = {
  high:   'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300',
  medium: 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300',
  low:    'bg-slate-100 text-slate-600 dark:bg-slate-800/60 dark:text-slate-300',
};

export function PlaybookClient({
  stages,
}: {
  stages: PlaybookStage[];
}) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  const run: Run = (fn) => {
    setError(null);
    startTransition(async () => {
      const res = await fn();
      if (!res.ok) {
        setError(res.errorMessage ?? 'Something went wrong');
        return;
      }
      router.refresh();
    });
  };

  if (stages.length === 0) {
    return (
      <Card>
        <CardContent className="py-10 text-center text-sm text-muted-foreground">
          This pipeline has no stages, so there is nothing to configure yet.
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-4">
      {error && (
        <div className="rounded-md border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700 dark:border-red-900 dark:bg-red-950/30 dark:text-red-300">
          {error}
        </div>
      )}

      {stages.map((stage) => (
        <Card key={stage.id}>
          <CardContent className="p-4 space-y-4">
            <div className="flex items-center gap-2">
              <span className="inline-flex h-6 min-w-6 items-center justify-center rounded-full bg-muted px-2 text-xs font-medium text-muted-foreground">
                {stage.sortOrder}
              </span>
              <h2 className="text-base font-semibold">{stage.name}</h2>
            </div>

            {/* Checklist templates */}
            <section className="space-y-2">
              <div className="flex items-center gap-1.5 text-xs font-medium uppercase tracking-wide text-muted-foreground">
                <CheckSquare className="h-3.5 w-3.5" /> Checklist items
              </div>
              <div className="space-y-1.5">
                {stage.checklists.length === 0 && (
                  <p className="text-sm text-muted-foreground/70">No checklist items.</p>
                )}
                {stage.checklists.map((cl) => (
                  <ChecklistRow key={cl.id} item={cl} run={run} pending={pending} />
                ))}
              </div>
              <AddChecklist stageId={stage.id} run={run} pending={pending} />
            </section>

            {/* Task templates */}
            <section className="space-y-2 border-t pt-3">
              <div className="flex items-center gap-1.5 text-xs font-medium uppercase tracking-wide text-muted-foreground">
                <ListTodo className="h-3.5 w-3.5" /> Tasks
              </div>
              <div className="space-y-1.5">
                {stage.tasks.length === 0 && (
                  <p className="text-sm text-muted-foreground/70">No tasks.</p>
                )}
                {stage.tasks.map((tk) => (
                  <TaskRow key={tk.id} item={tk} checklists={stage.checklists} run={run} pending={pending} />
                ))}
              </div>
              <AddTask stageId={stage.id} checklists={stage.checklists} run={run} pending={pending} />
            </section>
          </CardContent>
        </Card>
      ))}
    </div>
  );
}

/* ---------------- Checklist row ---------------- */

function ChecklistRow({ item, run, pending }: { item: ChecklistTemplate; run: Run; pending: boolean }) {
  const [editing, setEditing] = useState(false);
  const [title, setTitle] = useState(item.title);

  if (editing) {
    return (
      <div className="flex items-center gap-1.5">
        <input className={INPUT} value={title} onChange={(e) => setTitle(e.target.value)} autoFocus
          onKeyDown={(e) => { if (e.key === 'Enter') save(); if (e.key === 'Escape') cancel(); }} />
        <IconBtn title="Save" onClick={save} disabled={pending}><Check className="h-4 w-4" /></IconBtn>
        <IconBtn title="Cancel" onClick={cancel} disabled={pending}><X className="h-4 w-4" /></IconBtn>
      </div>
    );
  }
  return (
    <div className="group flex items-center gap-2 rounded-md border px-2.5 py-1.5">
      <span className="flex-1 text-sm">{item.title}</span>
      <IconBtn title="Edit" onClick={() => setEditing(true)} disabled={pending}><Pencil className="h-3.5 w-3.5" /></IconBtn>
      <IconBtn title="Delete" onClick={del} disabled={pending} danger><Trash2 className="h-3.5 w-3.5" /></IconBtn>
    </div>
  );

  function save() {
    const t = title.trim();
    if (!t) return;
    run(() => updateChecklistTemplate({ id: item.id, title: t }));
    setEditing(false);
  }
  function cancel() { setTitle(item.title); setEditing(false); }
  function del() {
    if (!confirm(`Delete checklist item "${item.title}"?`)) return;
    run(() => deleteChecklistTemplate(item.id));
  }
}

function AddChecklist({ stageId, run, pending }: { stageId: string; run: Run; pending: boolean }) {
  const [open, setOpen] = useState(false);
  const [title, setTitle] = useState('');

  if (!open) {
    return (
      <button type="button" onClick={() => setOpen(true)} disabled={pending}
        className="inline-flex items-center gap-1 text-sm text-primary hover:underline disabled:opacity-50">
        <Plus className="h-3.5 w-3.5" /> Add checklist item
      </button>
    );
  }
  return (
    <div className="flex items-center gap-1.5">
      <input className={INPUT} placeholder="Checklist item title" value={title} autoFocus
        onChange={(e) => setTitle(e.target.value)}
        onKeyDown={(e) => { if (e.key === 'Enter') add(); if (e.key === 'Escape') close(); }} />
      <IconBtn title="Add" onClick={add} disabled={pending}><Check className="h-4 w-4" /></IconBtn>
      <IconBtn title="Cancel" onClick={close} disabled={pending}><X className="h-4 w-4" /></IconBtn>
    </div>
  );

  function add() {
    const t = title.trim();
    if (!t) return;
    run(() => createChecklistTemplate({ stageId, title: t }));
    setTitle(''); setOpen(false);
  }
  function close() { setTitle(''); setOpen(false); }
}

/* ---------------- Task row ---------------- */

interface TaskDraft {
  title: string;
  description: string;
  priority: TemplatePriority;
  dueInDays: string;
  checklistTemplateId: string;
}

function TaskRow({
  item, checklists, run, pending,
}: { item: TaskTemplate; checklists: ChecklistTemplate[]; run: Run; pending: boolean }) {
  const [editing, setEditing] = useState(false);
  const [d, setD] = useState<TaskDraft>(toDraft(item));

  if (editing) {
    return (
      <div className="rounded-md border p-2.5">
        <TaskForm d={d} setD={setD} checklists={checklists} />
        <div className="mt-2 flex items-center gap-1.5">
          <Button size="sm" onClick={save} disabled={pending}>Save</Button>
          <Button size="sm" variant="outline" onClick={() => { setD(toDraft(item)); setEditing(false); }} disabled={pending}>Cancel</Button>
        </div>
      </div>
    );
  }
  const linked = checklists.find((c) => c.id === item.checklistTemplateId);
  return (
    <div className="flex items-start gap-2 rounded-md border px-2.5 py-1.5">
      <div className="flex-1 space-y-0.5">
        <div className="flex items-center gap-2">
          <span className="text-sm font-medium">{item.title}</span>
          <span className={`inline-flex rounded-full px-1.5 py-0.5 text-[10px] font-medium uppercase ${PRIORITY_STYLE[item.defaultPriority]}`}>
            {item.defaultPriority}
          </span>
          <span className="text-xs text-muted-foreground">due in {item.dueInDays}d</span>
          {linked && (
            <span className="inline-flex items-center gap-0.5 text-xs text-muted-foreground">
              <CheckSquare className="h-3 w-3" /> {linked.title}
            </span>
          )}
        </div>
        {item.description && <p className="text-xs text-muted-foreground">{item.description}</p>}
      </div>
      <IconBtn title="Edit" onClick={() => setEditing(true)} disabled={pending}><Pencil className="h-3.5 w-3.5" /></IconBtn>
      <IconBtn title="Delete" onClick={del} disabled={pending} danger><Trash2 className="h-3.5 w-3.5" /></IconBtn>
    </div>
  );

  function save() {
    const t = d.title.trim();
    if (!t) return;
    run(() => updateTaskTemplate({
      id: item.id,
      title: t,
      description: d.description.trim() || null,
      defaultPriority: d.priority,
      dueInDays: clampDays(d.dueInDays),
      checklistTemplateId: d.checklistTemplateId || null,
    }));
    setEditing(false);
  }
  function del() {
    if (!confirm(`Delete task "${item.title}"?`)) return;
    run(() => deleteTaskTemplate(item.id));
  }
}

function AddTask({
  stageId, checklists, run, pending,
}: { stageId: string; checklists: ChecklistTemplate[]; run: Run; pending: boolean }) {
  const [open, setOpen] = useState(false);
  const [d, setD] = useState<TaskDraft>(emptyDraft());

  if (!open) {
    return (
      <button type="button" onClick={() => setOpen(true)} disabled={pending}
        className="inline-flex items-center gap-1 text-sm text-primary hover:underline disabled:opacity-50">
        <Plus className="h-3.5 w-3.5" /> Add task
      </button>
    );
  }
  return (
    <div className="rounded-md border p-2.5">
      <TaskForm d={d} setD={setD} checklists={checklists} />
      <div className="mt-2 flex items-center gap-1.5">
        <Button size="sm" onClick={add} disabled={pending}>Add task</Button>
        <Button size="sm" variant="outline" onClick={close} disabled={pending}>Cancel</Button>
      </div>
    </div>
  );

  function add() {
    const t = d.title.trim();
    if (!t) return;
    run(() => createTaskTemplate({
      stageId,
      title: t,
      description: d.description.trim() || null,
      defaultPriority: d.priority,
      dueInDays: clampDays(d.dueInDays),
      checklistTemplateId: d.checklistTemplateId || null,
    }));
    close();
  }
  function close() { setD(emptyDraft()); setOpen(false); }
}

/* ---------------- shared task form ---------------- */

function TaskForm({
  d, setD, checklists,
}: { d: TaskDraft; setD: (d: TaskDraft) => void; checklists: ChecklistTemplate[] }) {
  return (
    <div className="space-y-2">
      <input className={INPUT} placeholder="Task title" value={d.title} autoFocus
        onChange={(e) => setD({ ...d, title: e.target.value })} />
      <textarea
        className="w-full rounded-md border border-input bg-background px-2 py-1.5 text-sm focus:outline-none focus:ring-1 focus:ring-ring"
        placeholder="Description (optional)" rows={2} value={d.description}
        onChange={(e) => setD({ ...d, description: e.target.value })} />
      <div className="flex flex-wrap items-center gap-2">
        <label className="flex items-center gap-1 text-xs text-muted-foreground">
          Priority
          <select className="h-9 rounded-md border border-input bg-background px-2 text-sm"
            value={d.priority} onChange={(e) => setD({ ...d, priority: e.target.value as TemplatePriority })}>
            <option value="low">low</option>
            <option value="medium">medium</option>
            <option value="high">high</option>
          </select>
        </label>
        <label className="flex items-center gap-1 text-xs text-muted-foreground">
          Due in
          <input type="number" min={0} max={365} className="h-9 w-16 rounded-md border border-input bg-background px-2 text-sm"
            value={d.dueInDays} onChange={(e) => setD({ ...d, dueInDays: e.target.value })} />
          days
        </label>
        <label className="flex items-center gap-1 text-xs text-muted-foreground">
          Linked checklist
          <select className="h-9 rounded-md border border-input bg-background px-2 text-sm"
            value={d.checklistTemplateId} onChange={(e) => setD({ ...d, checklistTemplateId: e.target.value })}>
            <option value="">None</option>
            {checklists.map((c) => <option key={c.id} value={c.id}>{c.title}</option>)}
          </select>
        </label>
      </div>
    </div>
  );
}

/* ---------------- helpers ---------------- */

function IconBtn({
  children, onClick, disabled, title, danger,
}: {
  children: ReactNode; onClick: () => void; disabled?: boolean; title: string; danger?: boolean;
}) {
  return (
    <button type="button" title={title} onClick={onClick} disabled={disabled}
      className={`inline-flex h-7 w-7 items-center justify-center rounded-md hover:bg-muted disabled:opacity-40 ${danger ? 'text-red-600 hover:bg-red-50 dark:hover:bg-red-950/30' : 'text-muted-foreground'}`}>
      {children}
    </button>
  );
}

function toDraft(t: TaskTemplate): TaskDraft {
  return {
    title: t.title,
    description: t.description ?? '',
    priority: t.defaultPriority,
    dueInDays: String(t.dueInDays),
    checklistTemplateId: t.checklistTemplateId ?? '',
  };
}
function emptyDraft(): TaskDraft {
  return { title: '', description: '', priority: 'medium', dueInDays: '3', checklistTemplateId: '' };
}
function clampDays(v: string): number {
  const n = parseInt(v, 10);
  if (!Number.isFinite(n) || n < 0) return 0;
  return n > 365 ? 365 : n;
}
