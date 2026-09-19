'use client'
// src/components/meetings/add-to-calendar-modal.tsx
//
// 2026-09-19 - "Add to Calendar" from an email.
//
// Opened from an email row (party Communications tab, or the inbox thread view).
// Everything is pre-filled from parse-meeting-invite and everything stays
// editable - the parser is a shortcut, never the final word.
//
// Timezone model: the ISO instant is the truth. The date/time box holds a WALL
// CLOCK read in the selected timezone, so an email that says "9:00 AM CDT"
// shows 09:00 with America/Chicago selected, whatever the browser's own zone is.

import { useState, useMemo, useEffect, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { CalendarPlus, Video, ExternalLink, AlertTriangle, Check } from 'lucide-react'
import {
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Checkbox } from '@/components/ui/checkbox'
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from '@/components/ui/select'
import { SUPPORTED_TIMEZONES, DEFAULT_TIMEZONE } from '@/lib/constants/timezones'
import {
  parseMeetingInvite,
  titleFromSubject,
  instantToWallClockInput,
  wallClockInputToInstant,
  zoneAbbreviation,
  type ParsedTimeCandidate,
} from '@/lib/meetings/parse-meeting-invite'
import { addEmailToCalendarAction } from '@/app/actions/add-email-to-calendar'

/** Everything the modal needs from an email, in one shape both call sites can build. */
export interface CalendarSourceEmail {
  communicationId: string
  subject: string | null
  bodyPlain: string | null
  bodyHtml: string | null
  occurredAt: string
  direction: string
  partyId: string | null
  partyName: string | null
  fromAddress: string | null
  fromName?: string | null
  toAddresses: string[]
  ccAddresses?: string[]
}

interface Props {
  open: boolean
  onClose: () => void
  source: CalendarSourceEmail | null
  /** Viewer's display timezone (IANA); used when the email states none. */
  timeZone?: string
}

const MEETING_TYPES = [
  'discovery', 'demo', 'proposal', 'negotiation',
  'follow_up', 'check_in', 'kickoff', 'review', 'other',
] as const

const DURATIONS = [15, 20, 30, 45, 60, 90, 120]

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

export function AddToCalendarModal({ open, onClose, source, timeZone }: Props) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()

  const fallbackZone = timeZone || DEFAULT_TIMEZONE

  const parsed = useMemo(() => {
    if (!source) return null
    return parseMeetingInvite({
      subject: source.subject,
      bodyPlain: source.bodyPlain,
      bodyHtml: source.bodyHtml,
      referenceDate: source.occurredAt,
      fallbackTimeZone: fallbackZone,
    })
  }, [source, fallbackZone])

  // Candidate addresses: everyone on the email except nobody - the user ticks.
  const addressBook = useMemo(() => {
    if (!source) return [] as Array<{ email: string; name?: string | null }>
    const out: Array<{ email: string; name?: string | null }> = []
    const push = (e: string | null | undefined, n?: string | null) => {
      const v = (e ?? '').trim().toLowerCase()
      if (v && EMAIL_RE.test(v) && !out.some((x) => x.email === v)) {
        out.push({ email: v, name: n ?? null })
      }
    }
    push(source.fromAddress, source.fromName)
    for (const a of source.toAddresses ?? []) push(a)
    for (const a of source.ccAddresses ?? []) push(a)
    return out
  }, [source])

  const [candidateIdx, setCandidateIdx] = useState(0)
  const [title, setTitle] = useState('')
  const [zone, setZone] = useState(fallbackZone)
  const [wallClock, setWallClock] = useState('')
  const [duration, setDuration] = useState(30)
  const [meetingUrl, setMeetingUrl] = useState('')
  const [meetingType, setMeetingType] = useState<string>('discovery')
  const [location, setLocation] = useState('')
  const [agenda, setAgenda] = useState('')
  const [picked, setPicked] = useState<string[]>([])
  const [error, setError] = useState<string | null>(null)
  const [duplicate, setDuplicate] = useState(false)
  const [done, setDone] = useState<{ kind: 'meeting' | 'event'; id: string } | null>(null)

  const applyCandidate = (c: ParsedTimeCandidate | null | undefined, tzFallback: string) => {
    const tz = c?.displayTimeZone || tzFallback
    setZone(tz)
    const iso = c?.startIso ?? new Date(Date.now() + 24 * 3600 * 1000).toISOString()
    setWallClock(instantToWallClockInput(iso, tz).slice(0, 16))
    if (c?.durationMin) setDuration(c.durationMin)
  }

  // Re-seed the form each time the modal opens on a new email.
  useEffect(() => {
    if (!open || !source) return
    const p = parsed
    setCandidateIdx(0)
    setTitle(
      titleFromSubject(source.subject)
      || (source.partyName ? `Meeting - ${source.partyName}` : 'Meeting'),
    )
    applyCandidate(p?.best ?? null, fallbackZone)
    if (!p?.best?.durationMin) setDuration(30)
    setMeetingUrl(p?.meetingUrl ?? '')
    setMeetingType('discovery')
    setLocation(p?.provider === 'google_meet' ? 'Google Meet' : '')
    setAgenda(p?.dialIn ? `Dial-in: ${p.dialIn}` : '')
    setPicked(addressBook.map((a) => a.email))
    setError(null)
    setDuplicate(false)
    setDone(null)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, source?.communicationId])

  if (!source) return null

  const startIso = wallClockInputToInstant(wallClock, zone)
  const zoneOptions = SUPPORTED_TIMEZONES.some((t) => t.value === zone)
    ? SUPPORTED_TIMEZONES
    : [...SUPPORTED_TIMEZONES, { value: zone, label: zone }]

  const submit = (force: boolean) => {
    if (!startIso) { setError('Enter a valid date and time.'); return }
    setError(null)
    startTransition(async () => {
      const res = await addEmailToCalendarAction({
        communicationId: source.communicationId,
        partyId: source.partyId,
        title,
        startIso,
        durationMin: duration,
        meetingUrl: meetingUrl || null,
        location: location || null,
        agenda: agenda || null,
        meetingType,
        attendees: addressBook.filter((a) => picked.includes(a.email)),
        allowDuplicate: force,
      })
      if (res.ok) {
        setDone({ kind: res.kind, id: res.id })
        router.refresh()
      } else {
        setError(res.error)
        setDuplicate(!!res.duplicate)
      }
    })
  }

  const candidates = parsed?.times ?? []

  return (
    <Dialog open={open} onOpenChange={(o) => { if (!o) onClose() }}>
      <DialogContent className="max-w-lg max-h-[88vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2 text-base">
            <CalendarPlus className="w-4 h-4" />
            Add to Calendar
          </DialogTitle>
        </DialogHeader>

        {done ? (
          <div className="space-y-4 py-2">
            <div className="flex items-start gap-2 rounded-md border border-emerald-200 bg-emerald-50 p-3 text-sm text-emerald-800">
              <Check className="w-4 h-4 mt-0.5 shrink-0" />
              <div>
                {done.kind === 'meeting'
                  ? 'Meeting created. It now appears on the calendar and in Today.'
                  : 'Event created on the calendar.'}
              </div>
            </div>
            <div className="flex gap-2">
              <Button asChild variant="outline" size="sm">
                <Link href="/calendar">Open calendar</Link>
              </Button>
              {done.kind === 'meeting' && done.id && (
                <Button asChild variant="outline" size="sm">
                  <Link href={`/meetings/${done.id}`}>Open meeting</Link>
                </Button>
              )}
              <Button size="sm" className="ml-auto" onClick={onClose}>Close</Button>
            </div>
          </div>
        ) : (
          <>
            {/* What the parser found */}
            {parsed?.meetingUrl ? (
              <div className="flex items-center gap-2 rounded-md border bg-blue-50 border-blue-200 px-3 py-2 text-xs text-blue-800">
                <Video className="w-3.5 h-3.5 shrink-0" />
                <span className="font-medium">
                  {parsed.provider === 'google_meet' ? 'Google Meet' : 'Meeting link'}
                </span>
                <a
                  href={parsed.meetingUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="truncate underline inline-flex items-center gap-1"
                >
                  {parsed.meetingUrl.replace(/^https?:\/\//, '')}
                  <ExternalLink className="w-3 h-3 shrink-0" />
                </a>
              </div>
            ) : (
              <div className="rounded-md border bg-amber-50 border-amber-200 px-3 py-2 text-xs text-amber-800">
                No meeting link found in this email - fill one in below if there is one.
              </div>
            )}

            {/* Alternative times the parser saw */}
            {candidates.length > 1 && (
              <div className="space-y-1">
                <Label className="text-xs">Times found in the email</Label>
                <div className="flex flex-wrap gap-1">
                  {candidates.map((c, i) => (
                    <button
                      key={c.startIso}
                      type="button"
                      onClick={() => { setCandidateIdx(i); applyCandidate(c, fallbackZone) }}
                      className={
                        'rounded border px-2 py-1 text-xs transition ' +
                        (i === candidateIdx
                          ? 'border-blue-400 bg-blue-50 text-blue-800'
                          : 'border-gray-200 hover:bg-gray-50 text-gray-600')
                      }
                      title={c.snippet}
                    >
                      {instantToWallClockInput(c.startIso, c.displayTimeZone).replace('T', ' ')}
                      {' '}
                      {zoneAbbreviation(c.startIso, c.displayTimeZone)}
                      {c.timeAssumed && ' (time guessed)'}
                    </button>
                  ))}
                </div>
              </div>
            )}

            <div className="space-y-3 py-1">
              <div className="space-y-1">
                <Label htmlFor="atc-title" className="text-xs">Title</Label>
                <Input
                  id="atc-title"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="Intro call"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div className="space-y-1">
                  <Label htmlFor="atc-when" className="text-xs">Date & time</Label>
                  <Input
                    id="atc-when"
                    type="datetime-local"
                    value={wallClock}
                    onChange={(e) => setWallClock(e.target.value)}
                  />
                </div>
                <div className="space-y-1">
                  <Label className="text-xs">Timezone</Label>
                  <Select
                    value={zone}
                    onValueChange={(next) => {
                      // Keep the wall clock the user is looking at; the instant moves.
                      setZone(next)
                    }}
                  >
                    <SelectTrigger><SelectValue /></SelectTrigger>
                    <SelectContent>
                      {zoneOptions.map((t) => (
                        <SelectItem key={t.value} value={t.value}>{t.label}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>

              {parsed?.best?.timeZoneLabel && (
                <p className="text-[11px] text-gray-500 -mt-1">
                  The email said &ldquo;{parsed.best.timeZoneLabel}&rdquo;.
                  {startIso && (
                    <> Stored as {new Date(startIso).toUTCString().replace(' GMT', ' UTC')}.</>
                  )}
                </p>
              )}

              <div className="grid grid-cols-2 gap-3">
                <div className="space-y-1">
                  <Label className="text-xs">Duration</Label>
                  <Select
                    value={String(duration)}
                    onValueChange={(v) => setDuration(Number(v))}
                  >
                    <SelectTrigger><SelectValue /></SelectTrigger>
                    <SelectContent>
                      {DURATIONS.map((d) => (
                        <SelectItem key={d} value={String(d)}>{d} min</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-1">
                  <Label className="text-xs">Type</Label>
                  <Select value={meetingType} onValueChange={setMeetingType}>
                    <SelectTrigger><SelectValue /></SelectTrigger>
                    <SelectContent>
                      {MEETING_TYPES.map((t) => (
                        <SelectItem key={t} value={t}>{t.replace('_', ' ')}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>

              <div className="space-y-1">
                <Label htmlFor="atc-url" className="text-xs">Meeting URL</Label>
                <Input
                  id="atc-url"
                  value={meetingUrl}
                  onChange={(e) => setMeetingUrl(e.target.value)}
                  placeholder="https://meet.google.com/..."
                />
              </div>

              <div className="space-y-1">
                <Label htmlFor="atc-loc" className="text-xs">Location</Label>
                <Input
                  id="atc-loc"
                  value={location}
                  onChange={(e) => setLocation(e.target.value)}
                  placeholder="Google Meet"
                />
              </div>

              {addressBook.length > 0 && (
                <div className="space-y-1">
                  <Label className="text-xs">Attendees</Label>
                  <div className="space-y-1 rounded border p-2 max-h-28 overflow-y-auto">
                    {addressBook.map((a) => (
                      <label key={a.email} className="flex items-center gap-2 text-xs cursor-pointer">
                        <Checkbox
                          checked={picked.includes(a.email)}
                          onCheckedChange={(c) =>
                            setPicked((prev) =>
                              c ? [...new Set([...prev, a.email])] : prev.filter((x) => x !== a.email),
                            )
                          }
                        />
                        <span className="font-mono truncate">{a.email}</span>
                      </label>
                    ))}
                  </div>
                </div>
              )}

              <div className="space-y-1">
                <Label htmlFor="atc-agenda" className="text-xs">Agenda / notes</Label>
                <Textarea
                  id="atc-agenda"
                  rows={2}
                  value={agenda}
                  onChange={(e) => setAgenda(e.target.value)}
                  placeholder="Dial-in, agenda, anything worth keeping"
                />
              </div>

              {!source.partyId && (
                <p className="text-[11px] text-amber-700">
                  This email is not linked to a party, so it is saved as a plain
                  calendar event rather than a meeting.
                </p>
              )}
            </div>

            {error && (
              <div className="flex items-start gap-2 rounded-md border border-red-200 bg-red-50 p-2 text-xs text-red-700">
                <AlertTriangle className="w-3.5 h-3.5 mt-0.5 shrink-0" />
                <div className="flex-1">
                  <div>{error}</div>
                  {duplicate && (
                    <button
                      type="button"
                      className="mt-1 underline font-medium"
                      onClick={() => submit(true)}
                    >
                      Add it anyway
                    </button>
                  )}
                </div>
              </div>
            )}

            <DialogFooter>
              <Button variant="ghost" onClick={onClose} disabled={isPending}>Cancel</Button>
              <Button onClick={() => submit(false)} disabled={isPending || !startIso}>
                <CalendarPlus className="w-4 h-4 mr-1" />
                {isPending ? 'Adding...' : 'Add to calendar'}
              </Button>
            </DialogFooter>
          </>
        )}
      </DialogContent>
    </Dialog>
  )
}

/** True when an email is worth showing the "Add to Calendar" button for. */
export function emailHasMeetingSignal(args: {
  subject?: string | null
  bodyPlain?: string | null
  bodyHtml?: string | null
  occurredAt?: string | null
  timeZone?: string | null
}): boolean {
  return parseMeetingInvite({
    subject: args.subject,
    bodyPlain: args.bodyPlain,
    bodyHtml: args.bodyHtml,
    referenceDate: args.occurredAt ?? null,
    fallbackTimeZone: args.timeZone ?? DEFAULT_TIMEZONE,
  }).hasSignal
}
