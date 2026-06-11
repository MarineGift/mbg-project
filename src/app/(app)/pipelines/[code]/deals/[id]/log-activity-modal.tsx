// src/app/(app)/pipelines/[code]/deals/[id]/log-activity-modal.tsx
//
// Activity tab = the main working surface (HubSpot-style).
//
//   Composer (top):
//     [Checklist v]  [+ New checklist]   [Task v]  [+ New task]
//     [ type chips ]  [ title ]  [ when ]  [ summary ]   [Log activity]
//
//   - Checklist select filters the Task select (tasks of that checklist).
//   - "+ New checklist" / "+ New task" navigate to the Checklist / Tasks tab
//     (those tabs own the full CRUD).
//   - Task select default = "Log directly to this deal" -> task_id null, which
//     is the quick deal-level path (an email that arrives before any task).
//   - Picking a task links the activity to it (engagements.task_id).
//
//   Timeline (below): the deal's recent activities, newest first.
//
// Reuses existing server actions only (logEngagement). No new server code.

'use client';

import { useEffect, useMemo, useRef, useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import {
  Plus,
  Mail,
  Phone,
  Calendar,
  FileText,
  MessageSquare,
  Users,
  X,
  Loader2,
  Activity as ActivityIcon,
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Send } from 'lucide-react';
import { ComposeEmailDialog } from '@/components/email/compose-email-dialog';
import { logEngagement, searchPartyContacts } from './actions';

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

interface TaskOption {
  id: string;
  title: string;
  checklist_id?: string | null;
}

interface ChecklistOption {
  id: string;
  title: string;
}

interface Props {
  pipelineCode: string;
  dealId: string;
  engagements: Engagement[];
  engagementTypes: EngagementType[];
  tasks?: TaskOption[];
  checklists?: ChecklistOption[];
  /** Compose ("Send Email") context for this deal */
  partyId?: string | null;
  contactId?: string | null;
  contactName?: string | null;
  contactEmail?: string | null;
  templates?: unknown[];
}

// ============================================================
// Helpers
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

// ============================================================
// Public component
// ============================================================

export function ActivityTabClient({
  pipelineCode,
  dealId,
  engagements,
  engagementTypes,
  tasks = [],
  checklists = [],
  partyId = null,
  contactId = null,
  contactName = null,
  contactEmail = null,
  templates = [],
}: Props) {
  const router = useRouter();
  const [composeOpen, setComposeOpen] = useState(false);
  return (
    <div className="space-y-4">
      {/* Send Email -> opens the real Compose dialog (Manual / Template / AI),
          pre-linked to this deal so the sent mail auto-logs as an engagement. */}
      <div className="flex items-center justify-between rounded-lg border bg-card p-3">
        <div className="text-sm text-muted-foreground">
          {contactEmail
            ? <>Send an email to <span className="font-medium text-foreground">{contactName || contactEmail}</span> and log it on this deal.</>
            : partyId
              ? 'Compose an email for this deal. Add a recipient in the dialog.'
              : 'No company linked to this deal yet.'}
        </div>
        <Button
          size="sm"
          onClick={() => setComposeOpen(true)}
          disabled={!partyId}
        >
          <Send className="mr-1 h-4 w-4" />
          Send Email
        </Button>
      </div>

      {partyId && (
        <ComposeEmailDialog
          open={composeOpen}
          onOpenChange={setComposeOpen}
          mode="new"
          partyId={partyId}
          dealId={dealId}
          contactId={contactId}
          contactName={contactName}
          defaultTo={contactEmail ?? ''}
          templates={templates}
          onSent={() => router.refresh()}
        />
      )}

      <ActivityComposer
        pipelineCode={pipelineCode}
        dealId={dealId}
        engagementTypes={engagementTypes}
        tasks={tasks}
        checklists={checklists}
        partyId={partyId}
      />

      {/* Timeline */}
      <div>
        <div className="mb-2 text-xs font-medium uppercase tracking-wider text-muted-foreground">
          {engagements.length === 0
            ? 'Activity'
            : 'Recent activity (' + engagements.length + (engagements.length === 50 ? ', latest 50' : '') + ')'}
        </div>
        {engagements.length === 0 ? (
          <div className="flex flex-col items-center justify-center rounded-lg border bg-card py-12">
            <ActivityIcon className="mb-3 h-8 w-8 text-muted-foreground/30" />
            <div className="text-sm font-medium text-foreground">No activity yet</div>
            <div className="mt-1 max-w-md text-center text-xs text-muted-foreground">
              Use the composer above to log an email, call, meeting, or note.
            </div>
          </div>
        ) : (
          <ol className="rounded-lg border bg-card">
            {engagements.map((e, idx) => (
              <ActivityRow key={e.id} engagement={e} isLast={idx === engagements.length - 1} />
            ))}
          </ol>
        )}
      </div>
    </div>
  );
}

// ============================================================
// Composer
// ============================================================

function ActivityComposer({
  pipelineCode,
  dealId,
  engagementTypes,
  tasks,
  checklists,
  partyId = null,
}: {
  pipelineCode: string;
  dealId: string;
  engagementTypes: EngagementType[];
  tasks: TaskOption[];
  checklists: ChecklistOption[];
  partyId?: string | null;
}) {
  const router = useRouter();
  const dealBase = '/pipelines/' + pipelineCode + '/deals/' + dealId;

  const [checklistId, setChecklistId] = useState('');
  const [taskId, setTaskId] = useState('');
  const [typeId, setTypeId] = useState<number>(engagementTypes[0]?.id ?? 0);
  const [title, setTitle] = useState('');
  const [when, setWhen] = useState(() => toLocalDateTimeInputValue(new Date()));
  const [summary, setSummary] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  // ----- participants (meeting/call/message/consultation only) -----
  type Participant = { contact_id?: string | null; name?: string | null; email?: string | null };
  const PARTICIPANT_TYPE_CODES = new Set(['meeting', 'call', 'message', 'consultation']);
  const selectedTypeCode = (engagementTypes.find((t) => t.id === typeId)?.code ?? '').toLowerCase();
  const showParticipants = partyId != null && PARTICIPANT_TYPE_CODES.has(selectedTypeCode);

  const [participants, setParticipants] = useState<Participant[]>([]);
  const [pQuery, setPQuery] = useState('');
  const [pResults, setPResults] = useState<
    Array<{ id: string; full_name: string | null; email: string | null; title_text: string | null }>
  >([]);
  const [pSearching, setPSearching] = useState(false);
  const [pOpen, setPOpen] = useState(false);
  const pDebounce = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    if (!showParticipants || !partyId) {
      setPResults([]);
      setPOpen(false);
      return;
    }
    if (pDebounce.current) clearTimeout(pDebounce.current);
    pDebounce.current = setTimeout(async () => {
      setPSearching(true);
      const rows = await searchPartyContacts(partyId, pQuery);
      setPSearching(false);
      setPResults(
        rows.map((r) => ({ id: r.id, full_name: r.full_name, email: r.email, title_text: r.title_text })),
      );
      setPOpen(true);
    }, 200);
    return () => {
      if (pDebounce.current) clearTimeout(pDebounce.current);
    };
  }, [pQuery, partyId, showParticipants]);

  function addContactParticipant(r: { id: string; full_name: string | null; email: string | null }) {
    setParticipants((prev) =>
      prev.some((p) => p.contact_id === r.id)
        ? prev
        : [...prev, { contact_id: r.id, name: r.full_name, email: r.email }],
    );
    setPQuery('');
    setPResults([]);
    setPOpen(false);
  }
  function addFreeParticipant() {
    const v = pQuery.trim();
    if (!v) return;
    const isEmail = v.includes('@');
    setParticipants((prev) => [
      ...prev,
      isEmail ? { email: v, name: null } : { name: v, email: null },
    ]);
    setPQuery('');
    setPResults([]);
    setPOpen(false);
  }
  function removeParticipant(idx: number) {
    setParticipants((prev) => prev.filter((_, i) => i !== idx));
  }

  // Tasks shown in the Task dropdown: filtered to the chosen checklist (if any).
  const visibleTasks = useMemo(() => {
    if (!checklistId) return tasks;
    return tasks.filter((t) => t.checklist_id === checklistId);
  }, [tasks, checklistId]);

  function onChecklistChange(id: string) {
    setChecklistId(id);
    // If the currently selected task isn't in the new checklist, clear it.
    if (id && taskId) {
      const stillValid = tasks.some((t) => t.id === taskId && t.checklist_id === id);
      if (!stillValid) setTaskId('');
    }
  }

  function submit() {
    setError(null);
    const t = title.trim();
    if (!t) { setError('Title is required'); return; }
    if (!typeId) { setError('Pick an activity type'); return; }
    const occurredIso = when ? new Date(when).toISOString() : new Date().toISOString();
    startTransition(async () => {
      const r = await logEngagement({
        pipelineCode,
        dealId,
        engagement_type_id: typeId,
        title: t,
        occurred_at: occurredIso,
        summary: summary.trim() || null,
        task_id: taskId || null, // empty = log directly to the deal
        participants: showParticipants ? participants : undefined,
      });
      if (!r.ok) { setError(r.error); return; }
      setTitle('');
      setSummary('');
      setParticipants([]);
      setPQuery('');
      router.refresh();
    });
  }

  return (
    <div className="space-y-3 rounded-lg border bg-card p-3">
      <div className="text-xs font-medium uppercase tracking-wider text-muted-foreground">
        Log activity
      </div>

      {/* Checklist + Task selectors with "go to tab" buttons */}
      <div className="grid gap-2 sm:grid-cols-2">
        <div className="flex items-center gap-1.5">
          <select
            value={checklistId}
            onChange={(e) => onChecklistChange(e.target.value)}
            disabled={isPending}
            className="min-w-0 flex-1 rounded-md border bg-background px-2 py-1.5 text-sm focus:border-foreground/30 focus:outline-none focus:ring-2 focus:ring-foreground/5"
          >
            <option value="">All checklists</option>
            {checklists.map((c) => (
              <option key={c.id} value={c.id}>{c.title}</option>
            ))}
          </select>
          <button
            type="button"
            onClick={() => router.push(dealBase + '?tab=checklist')}
            className="inline-flex shrink-0 items-center gap-1 rounded-md border px-2 py-1.5 text-xs font-medium text-blue-700 hover:bg-blue-50"
            title="Manage checklist items"
          >
            <Plus className="h-3.5 w-3.5" />
            Checklist
          </button>
        </div>

        <div className="flex items-center gap-1.5">
          <select
            value={taskId}
            onChange={(e) => setTaskId(e.target.value)}
            disabled={isPending}
            className="min-w-0 flex-1 rounded-md border bg-background px-2 py-1.5 text-sm focus:border-foreground/30 focus:outline-none focus:ring-2 focus:ring-foreground/5"
          >
            <option value="">Log directly to this deal (no task)</option>
            {visibleTasks.map((t) => (
              <option key={t.id} value={t.id}>{t.title}</option>
            ))}
          </select>
          <button
            type="button"
            onClick={() => router.push(dealBase + '?tab=tasks')}
            className="inline-flex shrink-0 items-center gap-1 rounded-md border px-2 py-1.5 text-xs font-medium text-blue-700 hover:bg-blue-50"
            title="Manage tasks"
          >
            <Plus className="h-3.5 w-3.5" />
            Task
          </button>
        </div>
      </div>

      {/* Activity type chips */}
      <div className="flex flex-wrap gap-1.5">
        {engagementTypes.length === 0 ? (
          <span className="text-xs text-muted-foreground">No activity types configured.</span>
        ) : (
          engagementTypes.map((t) => {
            const Icon = iconFor(t.code);
            const active = t.id === typeId;
            return (
              <button
                key={t.id}
                type="button"
                onClick={() => setTypeId(t.id)}
                disabled={isPending}
                className={
                  'inline-flex items-center gap-1 rounded-md border px-2 py-1 text-xs capitalize transition ' +
                  (active
                    ? 'border-foreground bg-foreground text-background'
                    : 'border-border bg-background text-foreground hover:bg-muted')
                }
              >
                <Icon className="h-3 w-3" />
                {t.display_name_en}
              </button>
            );
          })
        )}
      </div>

      {/* Title */}
      <input
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        placeholder="What happened? (e.g. Sent intro email to program officer)"
        disabled={isPending}
        className="w-full rounded-md border bg-background px-3 py-2 text-sm focus:border-foreground/30 focus:outline-none focus:ring-2 focus:ring-foreground/5"
      />

      {/* When + summary */}
      <div className="flex flex-wrap items-center gap-2">
        <input
          type="datetime-local"
          value={when}
          onChange={(e) => setWhen(e.target.value)}
          disabled={isPending}
          className="rounded-md border bg-background px-2 py-1.5 text-sm focus:border-foreground/30 focus:outline-none focus:ring-2 focus:ring-foreground/5"
        />
        <input
          value={summary}
          onChange={(e) => setSummary(e.target.value)}
          placeholder="Summary (optional)"
          disabled={isPending}
          className="min-w-0 flex-1 rounded-md border bg-background px-3 py-1.5 text-sm focus:border-foreground/30 focus:outline-none focus:ring-2 focus:ring-foreground/5"
        />
      </div>

      {/* Participants (meeting / call / message / consultation only) */}
      {showParticipants && (
        <div className="space-y-2 rounded-md border border-dashed bg-muted/30 p-2.5">
          <div className="flex items-center gap-1.5 text-xs font-medium text-muted-foreground">
            <Users className="h-3.5 w-3.5" />
            Participants (optional)
          </div>

          {participants.length > 0 && (
            <div className="flex flex-wrap gap-1.5">
              {participants.map((p, idx) => (
                <span
                  key={idx}
                  className="inline-flex items-center gap-1 rounded-full bg-background border px-2 py-0.5 text-xs"
                >
                  {p.name || p.email || 'Unknown'}
                  {!p.contact_id && (
                    <span className="text-muted-foreground">(unlinked)</span>
                  )}
                  <button
                    type="button"
                    onClick={() => removeParticipant(idx)}
                    disabled={isPending}
                    className="text-muted-foreground hover:text-foreground"
                    aria-label="Remove participant"
                  >
                    <X className="h-3 w-3" />
                  </button>
                </span>
              ))}
            </div>
          )}

          <div className="relative">
            <input
              value={pQuery}
              onChange={(e) => setPQuery(e.target.value)}
              onFocus={() => pResults.length > 0 && setPOpen(true)}
              onBlur={() => setTimeout(() => setPOpen(false), 150)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') {
                  e.preventDefault();
                  addFreeParticipant();
                }
              }}
              placeholder="Search this company's contacts, or type a name/email + Enter"
              disabled={isPending}
              className="w-full rounded-md border bg-background px-3 py-1.5 text-sm focus:border-foreground/30 focus:outline-none focus:ring-2 focus:ring-foreground/5"
            />
            {pSearching && (
              <Loader2 className="absolute right-2 top-2 h-3.5 w-3.5 animate-spin text-muted-foreground" />
            )}
            {pOpen && pResults.length > 0 && (
              <div className="absolute z-20 left-0 right-0 top-full mt-1 max-h-52 overflow-y-auto rounded-md border bg-popover shadow-md">
                {pResults.map((r) => (
                  <button
                    key={r.id}
                    type="button"
                    className="flex w-full flex-col px-3 py-1.5 text-left text-sm hover:bg-accent"
                    onMouseDown={(ev) => {
                      ev.preventDefault();
                      addContactParticipant(r);
                    }}
                  >
                    <span className="font-medium">
                      {r.full_name || r.email || '(no name)'}
                      {r.title_text ? (
                        <span className="font-normal text-muted-foreground"> &middot; {r.title_text}</span>
                      ) : null}
                    </span>
                    {r.email && <span className="text-xs text-muted-foreground">{r.email}</span>}
                  </button>
                ))}
              </div>
            )}
          </div>
          <p className="text-xs text-muted-foreground">
            Not sure who attended? Leave this empty and log it; attach contacts later.
          </p>
        </div>
      )}

      {error && (
        <div className="rounded-md bg-rose-50 px-3 py-2 text-sm text-rose-700 ring-1 ring-inset ring-rose-200">
          {error}
        </div>
      )}

      <div className="flex items-center justify-between gap-2">
        <span className="text-xs text-muted-foreground">
          {taskId
            ? 'Will be linked to the selected task.'
            : 'Will be logged directly to this deal.'}
        </span>
        <Button size="sm" onClick={submit} disabled={isPending || !title.trim()} className="gap-1.5">
          <Plus className="h-3.5 w-3.5" />
          {isPending ? 'Logging...' : 'Log activity'}
        </Button>
      </div>
    </div>
  );
}

// ============================================================
// Timeline row
// ============================================================

function ActivityRow({ engagement: e, isLast }: { engagement: Engagement; isLast: boolean }) {
  const typeCode = e.engagement_type?.code || e.channel || '';
  const Icon = iconFor(typeCode);
  const typeLabel =
    e.engagement_type?.display_name_en || e.engagement_type?.name || e.engagement_type?.code || e.channel || '';
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
