// src/app/(app)/meetings/[id]/page.tsx
// Meeting detail page.
//
// Fixes the /meetings/[id] 404: the calendar dialog ("View details" on a
// meeting-type item, calendar/page.tsx) links to /meetings/{id}, but no route
// existed. The DB rows are fine (app.meetings + app.meeting_attendees); this is
// purely the missing Next.js route file.
//
// Pattern matches contacts/[id]/page.tsx: server component, direct supabase
// queries (schema('app')), notFound() on miss, semantic Tailwind tokens,
// lucide-react icons. Next 14 -> params is a plain object (not a Promise).
//
// Columns mirror BASE_SELECT / MeetingAttendeeRow in lib/queries/meetings.ts.
// Party link needs the [partyType] segment, so we fetch parties.party_type.

import Link from 'next/link';
import { notFound } from 'next/navigation';
import {
  ChevronLeft,
  Calendar,
  Clock,
  MapPin,
  Video,
  Building2,
  ExternalLink,
  Users,
  Star,
} from 'lucide-react';
import { createSupabaseServerClient } from '@/lib/supabase/server';

interface Props {
  params: { id: string };
}

// ---------------------------------------------------------------------------
// Formatting helpers
// ---------------------------------------------------------------------------

function fmtDateTime(iso: string | null | undefined): string {
  if (!iso) return '\u2014';
  const d = new Date(iso);
  if (isNaN(d.getTime())) return '\u2014';
  return d.toLocaleString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
    timeZoneName: 'short',
  });
}

function fmtDuration(min: number | null | undefined): string {
  if (!min || min <= 0) return '';
  if (min < 60) return `${min} min`;
  const h = Math.floor(min / 60);
  const m = min % 60;
  return m ? `${h}h ${m}m` : `${h}h`;
}

function titleCase(s: string | null | undefined): string {
  if (!s) return '';
  return s.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());
}

const STATUS_STYLES: Record<string, string> = {
  scheduled: 'bg-violet-50 text-violet-700 ring-violet-200',
  completed: 'bg-emerald-50 text-emerald-700 ring-emerald-200',
  cancelled: 'bg-zinc-100 text-zinc-600 ring-zinc-200',
  no_show: 'bg-rose-50 text-rose-700 ring-rose-200',
  rescheduled: 'bg-amber-50 text-amber-700 ring-amber-200',
};

const RESPONSE_STYLES: Record<string, string> = {
  accepted: 'bg-emerald-50 text-emerald-700 ring-emerald-200',
  declined: 'bg-rose-50 text-rose-700 ring-rose-200',
  tentative: 'bg-amber-50 text-amber-700 ring-amber-200',
  no_response: 'bg-zinc-50 text-zinc-600 ring-zinc-200',
};

const CHANNEL_ICON: Record<string, typeof Video> = {
  video_call: Video,
  video_conference: Video,
  phone_call: Clock,
  in_person: MapPin,
  hybrid: Users,
  other: Calendar,
};

interface ActionItem {
  text: string;
  assignee_user_id?: string;
  due_at?: string;
  done?: boolean;
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

export default async function MeetingDetailPage({ params }: Props) {
  const supabase = await createSupabaseServerClient();

  // 1) Meeting row (columns mirror BASE_SELECT in lib/queries/meetings.ts)
  const { data: meetingRow } = await supabase
    .schema('app')
    .from('meetings' as never)
    .select(
      'id, organization_id, user_id, party_id, engagement_id, stage_id, ' +
      'meeting_type, channel, status, title, agenda, notes, ai_summary, ' +
      'outcome, next_steps, action_items, occurred_at, scheduled_at, ' +
      'actual_started_at, actual_ended_at, duration_min, location, ' +
      'meeting_url, calendar_event_id, created_at, updated_at'
    )
    .eq('id', params.id)
    .is('deleted_at', null)
    .maybeSingle();

  if (!meetingRow) notFound();
  const m = meetingRow as any;

  // 2) Attendees (single source of truth: app.meeting_attendees)
  const { data: attendeeRows } = await supabase
    .schema('app')
    .from('meeting_attendees' as never)
    .select(
      'id, contact_id, email, name, role, response, ' +
      'is_internal, user_id, person_party_id, notes'
    )
    .eq('meeting_id', params.id);

  const attendees = (attendeeRows ?? []) as any[];

  // 3) Party (for the header link -> needs party_type for the [partyType] segment)
  let party: { party_name: string; party_type: string | null } | null = null;
  if (m.party_id) {
    const { data: partyRow } = await supabase
      .schema('app')
      .from('parties' as never)
      .select('party_name, party_type')
      .eq('id', m.party_id)
      .maybeSingle();
    if (partyRow) party = partyRow as any;
  }

  // 4) Stage label (best-effort; app.stages is the known table used by deals)
  let stage: { name: string; code: string | null } | null = null;
  if (m.stage_id) {
    const { data: stageRow } = await supabase
      .schema('app')
      .from('stages' as never)
      .select('name, code')
      .eq('id', m.stage_id)
      .maybeSingle();
    if (stageRow) stage = stageRow as any;
  }

  const actionItems: ActionItem[] = Array.isArray(m.action_items) ? m.action_items : [];
  const when = m.scheduled_at ?? m.occurred_at;
  const ChannelIcon = (m.channel && CHANNEL_ICON[m.channel]) || Calendar;

  const partyHref =
    party && m.party_id && party.party_type
      ? `/${party.party_type}/parties/${m.party_id}`
      : null;

  return (
    <div className="flex h-full flex-col">
      {/* ===== Header ===== */}
      <div className="border-b bg-background px-6 py-4">
        <div className="flex items-center gap-2 text-xs text-muted-foreground">
          <Link
            href="/calendar"
            className="inline-flex items-center gap-1 hover:text-foreground"
          >
            <ChevronLeft className="h-3 w-3" />
            Calendar
          </Link>
        </div>

        <div className="mt-1 flex flex-wrap items-center gap-3">
          <h1 className="text-xl font-semibold text-foreground">{m.title}</h1>
          <span
            className={
              'inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-medium capitalize ring-1 ring-inset ' +
              (STATUS_STYLES[m.status] || 'bg-zinc-50 text-zinc-600 ring-zinc-200')
            }
          >
            {titleCase(m.status)}
          </span>
          {m.meeting_type && m.meeting_type !== 'other' && (
            <span className="rounded-full bg-zinc-100 px-2 py-0.5 text-[10px] font-medium text-zinc-600">
              {titleCase(m.meeting_type)}
            </span>
          )}
        </div>

        {/* When / duration / channel */}
        <div className="mt-2 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-muted-foreground">
          <span className="inline-flex items-center gap-1">
            <Calendar className="h-3 w-3" />
            {fmtDateTime(when)}
          </span>
          {fmtDuration(m.duration_min) && (
            <span className="inline-flex items-center gap-1">
              <Clock className="h-3 w-3" />
              {fmtDuration(m.duration_min)}
            </span>
          )}
          {m.channel && (
            <span className="inline-flex items-center gap-1">
              <ChannelIcon className="h-3 w-3" />
              {titleCase(m.channel)}
            </span>
          )}
          {m.location && (
            <span className="inline-flex items-center gap-1">
              <MapPin className="h-3 w-3" />
              {m.location}
            </span>
          )}
          {m.meeting_url && (
            <a
              href={m.meeting_url}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-1 text-blue-600 hover:underline"
            >
              <Video className="h-3 w-3" />
              Join
              <ExternalLink className="h-2.5 w-2.5 opacity-60" />
            </a>
          )}
        </div>

        {/* Party + stage line */}
        {(party || stage) && (
          <div className="mt-1 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-muted-foreground">
            {party && (
              <span className="inline-flex items-center gap-1">
                <Building2 className="h-3 w-3" />
                {partyHref ? (
                  <Link href={partyHref} className="font-medium text-foreground hover:underline">
                    {party.party_name}
                  </Link>
                ) : (
                  <span className="font-medium text-foreground">{party.party_name}</span>
                )}
              </span>
            )}
            {stage && (
              <span className="opacity-80">
                {stage.name}
                {stage.code && <span className="ml-1 opacity-50">({stage.code})</span>}
              </span>
            )}
          </div>
        )}
      </div>

      {/* ===== Body ===== */}
      <div className="flex-1 overflow-y-auto p-6 space-y-6">
        {/* Agenda */}
        {m.agenda && (
          <section className="rounded-lg border bg-card p-4 text-sm">
            <div className="mb-1.5 text-[10px] font-medium uppercase tracking-wider text-muted-foreground">
              Agenda
            </div>
            <div className="whitespace-pre-wrap text-foreground">{m.agenda}</div>
          </section>
        )}

        {/* Attendees */}
        <section className="space-y-3">
          <div className="text-xs font-medium uppercase tracking-wider text-muted-foreground">
            Attendees ({attendees.length})
          </div>
          {attendees.length === 0 ? (
            <div className="rounded-lg border bg-card px-4 py-8 text-center text-sm text-muted-foreground">
              No attendees recorded.
            </div>
          ) : (
            <div className="rounded-lg border bg-card overflow-hidden">
              <table className="w-full text-sm">
                <thead className="bg-muted/30 text-xs text-muted-foreground">
                  <tr>
                    <th className="px-4 py-2 text-left font-medium">Name</th>
                    <th className="px-4 py-2 text-left font-medium">Role</th>
                    <th className="px-4 py-2 text-left font-medium">Response</th>
                    <th className="px-4 py-2 text-left font-medium">Side</th>
                  </tr>
                </thead>
                <tbody className="divide-y">
                  {attendees.map((a: any) => (
                    <tr key={a.id}>
                      <td className="px-4 py-2">
                        <div className="flex items-center gap-1.5">
                          {a.role === 'organizer' && (
                            <Star className="h-3 w-3 text-amber-500" />
                          )}
                          <span className="font-medium text-foreground">
                            {a.name || a.email}
                          </span>
                        </div>
                        {a.name && a.email && (
                          <a
                            href={'mailto:' + a.email}
                            className="text-[11px] text-muted-foreground hover:underline"
                          >
                            {a.email}
                          </a>
                        )}
                      </td>
                      <td className="px-4 py-2 text-xs text-muted-foreground capitalize">
                        {titleCase(a.role)}
                      </td>
                      <td className="px-4 py-2">
                        <span
                          className={
                            'inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-medium capitalize ring-1 ring-inset ' +
                            (RESPONSE_STYLES[a.response] || 'bg-zinc-50 text-zinc-600 ring-zinc-200')
                          }
                        >
                          {titleCase(a.response)}
                        </span>
                      </td>
                      <td className="px-4 py-2 text-xs text-muted-foreground">
                        {a.is_internal ? 'Internal' : 'External'}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </section>

        {/* Outcome / next steps (completed meetings) */}
        {(m.outcome || m.next_steps) && (
          <section className="grid gap-4 md:grid-cols-2">
            {m.outcome && (
              <div className="rounded-lg border bg-card p-4 text-sm">
                <div className="mb-1.5 text-[10px] font-medium uppercase tracking-wider text-muted-foreground">
                  Outcome
                </div>
                <div className="whitespace-pre-wrap text-foreground">{m.outcome}</div>
              </div>
            )}
            {m.next_steps && (
              <div className="rounded-lg border bg-card p-4 text-sm">
                <div className="mb-1.5 text-[10px] font-medium uppercase tracking-wider text-muted-foreground">
                  Next steps
                </div>
                <div className="whitespace-pre-wrap text-foreground">{m.next_steps}</div>
              </div>
            )}
          </section>
        )}

        {/* Action items */}
        {actionItems.length > 0 && (
          <section className="space-y-2">
            <div className="text-xs font-medium uppercase tracking-wider text-muted-foreground">
              Action items ({actionItems.length})
            </div>
            <ul className="rounded-lg border bg-card divide-y">
              {actionItems.map((it, i) => (
                <li key={i} className="flex items-start gap-2 px-4 py-2 text-sm">
                  <span
                    className={
                      'mt-0.5 inline-block h-3.5 w-3.5 shrink-0 rounded border ' +
                      (it.done ? 'bg-emerald-500 border-emerald-500' : 'border-zinc-300')
                    }
                  />
                  <span className={it.done ? 'text-muted-foreground line-through' : 'text-foreground'}>
                    {it.text}
                  </span>
                </li>
              ))}
            </ul>
          </section>
        )}

        {/* AI summary */}
        {m.ai_summary && (
          <section className="rounded-lg border bg-card p-4 text-sm">
            <div className="mb-1.5 text-[10px] font-medium uppercase tracking-wider text-muted-foreground">
              AI summary
            </div>
            <div className="whitespace-pre-wrap text-foreground">{m.ai_summary}</div>
          </section>
        )}

        {/* Notes */}
        {m.notes && (
          <section className="rounded-lg border bg-card p-4 text-sm">
            <div className="mb-1.5 text-[10px] font-medium uppercase tracking-wider text-muted-foreground">
              Notes
            </div>
            <div className="whitespace-pre-wrap text-foreground">{m.notes}</div>
          </section>
        )}
      </div>
    </div>
  );
}
