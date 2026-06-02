// src/app/(app)/pipelines/[code]/deals/[id]/log-activity-modal.tsx
//
// Client wrapper for the Activity tab. Encapsulates:
//   - "Log activity" button (top-right of the tab content)
//   - Modal dialog with 6 fields (type / title / when / direction / summary / notes)
//   - Activity list rendering (same shape as the previous server-rendered list)
//
// The server page passes engagements as a prop; we re-render them here so the
// button + modal + list can live together in one client component.

'use client';

import { useEffect, useState, useTransition } from 'react';
import { Plus, Mail, Phone, Calendar, FileText, MessageSquare, Activity as ActivityIcon } from 'lucide-react';
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { logEngagement } from './actions';

interface EngagementType {
  id: number;
  code: string;
  display_name_en: string;
}

interface Engagement {
  id: string;
  title: string;
  summary: string | null;
  content: string | null;
  occurred_at: string | null;
  direction: string | null;
  duration_min: number | null;
  status: string | null;
  next_steps: string | null;
  engagement_type: { id: number; code: string; display_name_en: string; name?: string } | null;
  channel?: string | null;
}

interface Props {
  pipelineCode: string;
  dealId: string;
  engagements: Engagement[];
  engagementTypes: EngagementType[];
  /** Open tasks on this deal, for the optional "Task" selector. */
  tasks?: Array<{ id: string; title: string }>;
}

// ============================================================
// Formatters (small subset, duplicated from page.tsx for client use)
// ============================================================

function fmtRelative(iso: string | null): string {
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

function iconFor(typeCode: string | null | undefined) {
  const t = (typeCode || '').toLowerCase();
  if (t.includes('email')) return Mail;
  if (t.includes('call') || t.includes('phone')) return Phone;
  if (t.includes('meeting')) return Calendar;
  if (t.includes('note')) return FileText;
  return MessageSquare;
}

// ============================================================
// Public component
// ============================================================

export function ActivityTabClient({
  pipelineCode,
  dealId,
  engagements,
  engagementTypes,
  tasks = [],
}: Props) {
  const [open, setOpen] = useState(false);

  return (
    <div>
      {/* Header bar: title + action button */}
      <div className="mb-3 flex items-center justify-between">
        <div className="text-xs font-medium uppercase tracking-wider text-muted-foreground">
          {engagements.length === 0
            ? 'Activity'
            : 'Recent activity (' + engagements.length + (engagements.length === 50 ? ', latest 50' : '') + ')'}
        </div>
        <Button size="sm" onClick={() => setOpen(true)} className="gap-1.5">
          <Plus className="h-3.5 w-3.5" />
          Log activity
        </Button>
      </div>

      {/* List or empty state */}
      {engagements.length === 0 ? (
        <div className="flex flex-col items-center justify-center rounded-lg border bg-card py-16">
          <ActivityIcon className="mb-3 h-8 w-8 text-muted-foreground/30" />
          <div className="text-sm font-medium text-foreground">No activity yet</div>
          <div className="mt-1 max-w-md text-center text-xs text-muted-foreground">
            Click <span className="font-medium">Log activity</span> to record an email, call, meeting, or note for this deal.
          </div>
        </div>
      ) : (
        <ol className="rounded-lg border bg-card">
          {engagements.map((e, idx) => (
            <ActivityRow key={e.id} engagement={e} isLast={idx === engagements.length - 1} />
          ))}
        </ol>
      )}

      <LogActivityModal
        open={open}
        onOpenChange={setOpen}
        pipelineCode={pipelineCode}
        dealId={dealId}
        engagementTypes={engagementTypes}
        tasks={tasks}
      />
    </div>
  );
}

// ============================================================
// Row (extracted for clarity)
// ============================================================

function ActivityRow({ engagement: e, isLast }: { engagement: Engagement; isLast: boolean }) {
  const typeCode = e.engagement_type?.code || e.channel || '';
  const Icon = iconFor(typeCode);
  const typeLabel = e.engagement_type?.display_name_en || e.engagement_type?.name || e.engagement_type?.code || e.channel || '';
  const body = e.summary || e.content || '';

  return (
    <li className={'flex gap-3 px-4 py-3 ' + (isLast ? '' : 'border-b')}>
      <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-muted">
        <Icon className="h-4 w-4 text-muted-foreground" />
      </div>
      <div className="min-w-0 flex-1">
        <div className="flex items-baseline justify-between gap-2">
          <div className="line-clamp-1 text-sm font-medium text-foreground">{e.title}</div>
          <div className="shrink-0 text-xs text-muted-foreground">{fmtRelative(e.occurred_at)}</div>
        </div>
        <div className="mt-0.5 flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
          {typeLabel && <span className="capitalize">{typeLabel}</span>}
          {e.direction && (
            <>
              {typeLabel && <span className="opacity-40">{'\u00b7'}</span>}
              <span className="capitalize">{e.direction}</span>
            </>
          )}
          {e.duration_min != null && (
            <>
              <span className="opacity-40">{'\u00b7'}</span>
              <span>{e.duration_min}m</span>
            </>
          )}
          {e.status && e.status !== 'completed' && (
            <>
              <span className="opacity-40">{'\u00b7'}</span>
              <span className="capitalize">{e.status}</span>
            </>
          )}
        </div>
        {body && (
          <p className="mt-1.5 line-clamp-2 text-xs text-muted-foreground">
            {String(body).slice(0, 240)}
          </p>
        )}
        {e.next_steps && (
          <p className="mt-1.5 line-clamp-1 text-xs text-foreground/80">
            <span className="font-medium">Next:</span> {e.next_steps}
          </p>
        )}
      </div>
    </li>
  );
}

// ============================================================
// Modal
// ============================================================

// Build a local datetime string in "YYYY-MM-DDTHH:mm" for <input type="datetime-local">
function toLocalDateTimeInputValue(d: Date): string {
  const pad = (n: number) => String(n).padStart(2, '0');
  return (
    d.getFullYear() + '-' +
    pad(d.getMonth() + 1) + '-' +
    pad(d.getDate()) + 'T' +
    pad(d.getHours()) + ':' +
    pad(d.getMinutes())
  );
}

function LogActivityModal({
  open,
  onOpenChange,
  pipelineCode,
  dealId,
  engagementTypes,
  tasks,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  pipelineCode: string;
  dealId: string;
  engagementTypes: EngagementType[];
  tasks: Array<{ id: string; title: string }>;
}) {
  // === All hooks first, before any conditional return ===
  // Prefer 'call' as default type, falling back to first available
  const defaultTypeId =
    engagementTypes.find((t) => t.code === 'call')?.id ?? engagementTypes[0]?.id ?? 0;

  const [typeId, setTypeId] = useState<number>(defaultTypeId);
  const [title, setTitle] = useState('');
  const [taskId, setTaskId] = useState<string>('');
  const [occurredAt, setOccurredAt] = useState<string>('');
  const [direction, setDirection] = useState<string>('outbound');
  const [summary, setSummary] = useState('');
  const [notes, setNotes] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  // Reset when opening
  useEffect(() => {
    if (open) {
      setTypeId(defaultTypeId);
      setTitle('');
      setTaskId('');
      setOccurredAt(toLocalDateTimeInputValue(new Date()));
      setDirection('outbound');
      setSummary('');
      setNotes('');
      setError(null);
    }
  }, [open, defaultTypeId]);

  const currentType = engagementTypes.find((t) => t.id === typeId);
  const typeCode = currentType?.code ?? '';
  // Direction is only meaningful for 2-way comms; show for call/email/message
  const showDirection = ['call', 'email', 'message'].includes(typeCode);

  const handleSubmit = () => {
    setError(null);
    const trimmedTitle = title.trim();
    if (!trimmedTitle) { setError('Title is required'); return; }
    if (!typeId) { setError('Activity type is required'); return; }
    if (!occurredAt) { setError('Time is required'); return; }

    // Convert local datetime to ISO. <input datetime-local> gives
    // "YYYY-MM-DDTHH:mm" without timezone; new Date() interprets it as local.
    const isoTime = new Date(occurredAt).toISOString();

    startTransition(async () => {
      const result = await logEngagement({
        pipelineCode,
        dealId,
        engagement_type_id: typeId,
        title: trimmedTitle,
        occurred_at: isoTime,
        direction: showDirection ? direction : null,
        summary: summary.trim() || null,
        notes: notes.trim() || null,
        task_id: taskId || null,
      });
      if (!result.ok) {
        setError(result.error);
        return;
      }
      onOpenChange(false);
      // No navigation needed -- revalidatePath refreshes the page below.
    });
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle>Log activity</DialogTitle>
        </DialogHeader>

        <div className="space-y-4 py-2">
          {/* Type */}
          <div>
            <label className="mb-1.5 block text-sm font-medium text-foreground">
              Type <span className="text-rose-600">*</span>
            </label>
            <div className="grid grid-cols-3 gap-1.5">
              {engagementTypes.map((t) => {
                const Icon = iconFor(t.code);
                const active = t.id === typeId;
                return (
                  <button
                    key={t.id}
                    type="button"
                    onClick={() => setTypeId(t.id)}
                    disabled={isPending}
                    className={
                      'flex items-center gap-1.5 rounded-md border px-2.5 py-1.5 text-xs transition ' +
                      (active
                        ? 'border-foreground bg-foreground text-background'
                        : 'border-border bg-background text-foreground hover:bg-muted')
                    }
                  >
                    <Icon className="h-3.5 w-3.5" />
                    <span className="truncate">{t.display_name_en}</span>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Title */}
          <div>
            <label
              htmlFor="act-title"
              className="mb-1 block text-sm font-medium text-foreground"
            >
              Title <span className="text-rose-600">*</span>
            </label>
            <input
              id="act-title"
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder={
                typeCode === 'meeting' ? 'Intro meeting with Lux team' :
                typeCode === 'call'    ? 'Followup call re: Series A terms' :
                typeCode === 'email'   ? 'Sent term sheet draft' :
                typeCode === 'note'    ? 'Internal note on valuation' :
                                         'Short summary of what happened'
              }
              className="w-full rounded-md border bg-background px-3 py-2 text-sm focus:border-foreground/30 focus:outline-none focus:ring-2 focus:ring-foreground/5"
              maxLength={200}
              disabled={isPending}
            />
          </div>

          {/* Task (only when the deal has tasks) */}
          {tasks.length > 0 && (
            <div>
              <label
                htmlFor="act-task"
                className="mb-1 block text-sm font-medium text-foreground"
              >
                Task
                <span className="ml-1 text-xs font-normal text-muted-foreground">optional</span>
              </label>
              <select
                id="act-task"
                value={taskId}
                onChange={(e) => setTaskId(e.target.value)}
                disabled={isPending}
                className="w-full rounded-md border bg-background px-3 py-2 text-sm focus:border-foreground/30 focus:outline-none focus:ring-2 focus:ring-foreground/5"
              >
                <option value="">No task (deal timeline)</option>
                {tasks.map((t) => (
                  <option key={t.id} value={t.id}>{t.title}</option>
                ))}
              </select>
            </div>
          )}
          <div>
            <label
              htmlFor="act-when"
              className="mb-1 block text-sm font-medium text-foreground"
            >
              When <span className="text-rose-600">*</span>
            </label>
            <input
              id="act-when"
              type="datetime-local"
              value={occurredAt}
              onChange={(e) => setOccurredAt(e.target.value)}
              className="w-full rounded-md border bg-background px-3 py-2 text-sm focus:border-foreground/30 focus:outline-none focus:ring-2 focus:ring-foreground/5"
              disabled={isPending}
            />
          </div>

          {/* Direction -- only for two-way comms */}
          {showDirection && (
            <div>
              <label className="mb-1.5 block text-sm font-medium text-foreground">
                Direction
              </label>
              <div className="flex gap-1.5">
                {(['inbound', 'outbound'] as const).map((d) => {
                  const active = direction === d;
                  return (
                    <button
                      key={d}
                      type="button"
                      onClick={() => setDirection(d)}
                      disabled={isPending}
                      className={
                        'flex-1 rounded-md border px-3 py-1.5 text-xs capitalize transition ' +
                        (active
                          ? 'border-foreground bg-foreground text-background'
                          : 'border-border bg-background text-foreground hover:bg-muted')
                      }
                    >
                      {d}
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          {/* Summary */}
          <div>
            <label
              htmlFor="act-summary"
              className="mb-1 block text-sm font-medium text-foreground"
            >
              Summary
              <span className="ml-1 text-xs font-normal text-muted-foreground">one-line, optional</span>
            </label>
            <input
              id="act-summary"
              type="text"
              value={summary}
              onChange={(e) => setSummary(e.target.value)}
              className="w-full rounded-md border bg-background px-3 py-2 text-sm focus:border-foreground/30 focus:outline-none focus:ring-2 focus:ring-foreground/5"
              maxLength={300}
              disabled={isPending}
            />
          </div>

          {/* Notes */}
          <div>
            <label
              htmlFor="act-notes"
              className="mb-1 block text-sm font-medium text-foreground"
            >
              Notes
              <span className="ml-1 text-xs font-normal text-muted-foreground">free-form, optional</span>
            </label>
            <textarea
              id="act-notes"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
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
            {isPending ? 'Logging...' : 'Log activity'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
