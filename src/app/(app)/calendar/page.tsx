// src/app/(app)/calendar/page.tsx
'use client'
import { useState, useEffect, useCallback } from 'react'
import { CalendarView } from '@/components/calendar/calendar-view'
import { MeetingCreateModal } from '@/components/meetings/meeting-create-modal'
import type { CalendarItem, CalendarFeedSource } from '@/lib/queries/calendar-meta'
import { CALENDAR_FEED_META, CALENDAR_FEED_SOURCES } from '@/lib/queries/calendar-meta'
import { cn } from '@/lib/utils'
import {
  getCalendarFeedAction as getCalendarFeed,
  createCalendarEventAction as createCalendarEvent,
  deleteCalendarEventAction as deleteCalendarEvent,
} from '@/app/actions/calendar'
import { EditEventModal } from '@/components/calendar/edit-event-modal'
import { EmailAttendeesModal } from '@/components/calendar/email-attendees-modal'
import {
  Dialog, DialogContent, DialogHeader, DialogTitle,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input }  from '@/components/ui/input'
import { Label }  from '@/components/ui/label'
import { Switch } from '@/components/ui/switch'
import { ExternalLink, Pencil, Trash2, Mail } from 'lucide-react'
import { useRouter } from 'next/navigation'

// --------------------------------------------------
// Quick Event Create (non-meeting)
// --------------------------------------------------

// JS getDay() index (0=Sun..6=Sat) -> RRULE BYDAY code / short label
const WEEKDAY_CODES  = ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA']
const WEEKDAY_LABELS = ['S', 'M', 'T', 'W', 'T', 'F', 'S']

// Assemble an RRULE body (no 'RRULE:' prefix) from the custom builder state.
function buildCustomRRule(s: {
  cFreq: 'DAILY' | 'WEEKLY' | 'MONTHLY' | 'YEARLY'
  cInterval: number
  cByday: Set<string>
  cEndMode: 'never' | 'until' | 'count'
  cUntil: string
  cCount: number
}): string {
  const parts = [`FREQ=${s.cFreq}`]
  if (s.cInterval > 1) parts.push(`INTERVAL=${s.cInterval}`)
  if (s.cFreq === 'WEEKLY' && s.cByday.size) {
    const ordered = WEEKDAY_CODES.filter((d) => s.cByday.has(d))
    parts.push(`BYDAY=${ordered.join(',')}`)
  }
  if (s.cEndMode === 'until' && s.cUntil) {
    parts.push(`UNTIL=${s.cUntil.replace(/-/g, '')}`)
  } else if (s.cEndMode === 'count' && s.cCount > 0) {
    parts.push(`COUNT=${s.cCount}`)
  }
  return parts.join(';')
}

function QuickEventModal({
  open, defaultDate, onClose,
}: {
  open: boolean; defaultDate: Date; onClose: () => void
}) {
  const router = useRouter()
  const [title,    setTitle]   = useState('')
  const [startAt,  setStartAt] = useState('')
  const [endAt,    setEndAt]   = useState('')
  const [allDay,   setAllDay]  = useState(false)
  const [saving,   setSaving]  = useState(false)
  const [recurrence, setRecurrence] = useState('')

  // 3-1 More options
  const [showMore,    setShowMore]    = useState(false)
  const [description, setDescription] = useState('')
  const [location,    setLocation]    = useState('')
  const [meetingUrl,  setMeetingUrl]  = useState('')

  // 3-2 Custom recurrence builder (only used when recurrence === 'CUSTOM')
  const [cFreq,     setCFreq]     = useState<'DAILY' | 'WEEKLY' | 'MONTHLY' | 'YEARLY'>('WEEKLY')
  const [cInterval, setCInterval] = useState(1)
  const [cByday,    setCByday]    = useState<Set<string>>(new Set())
  const [cEndMode,  setCEndMode]  = useState<'never' | 'until' | 'count'>('never')
  const [cUntil,    setCUntil]    = useState('')
  const [cCount,    setCCount]    = useState(10)

  useEffect(() => {
    if (open) {
      const d = defaultDate
      const base = `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`
      setTitle('')
      setAllDay(false)
      setRecurrence('')
      setStartAt(`${base}T09:00`)
      setEndAt(`${base}T10:00`)
      setShowMore(false)
      setDescription('')
      setLocation('')
      setMeetingUrl('')
      setCFreq('WEEKLY')
      setCInterval(1)
      setCByday(new Set([WEEKDAY_CODES[d.getDay()]]))
      setCEndMode('never')
      setCUntil('')
      setCCount(10)
    }
  }, [open, defaultDate])

  const toggleByday = (code: string) =>
    setCByday((prev) => {
      const next = new Set(prev)
      if (next.has(code)) next.delete(code); else next.add(code)
      return next
    })

  // The rule actually saved: a preset value, or the assembled custom rule.
  const effectiveRecurrence =
    recurrence === 'CUSTOM'
      ? buildCustomRRule({ cFreq, cInterval, cByday, cEndMode, cUntil, cCount })
      : recurrence

  async function handleSave() {
    if (!title.trim()) return
    setSaving(true)
    try {
      await createCalendarEvent({
        title:    title.trim(),
        start_at: new Date(allDay ? `${startAt}T00:00:00` : startAt).toISOString(),
        end_at:   new Date(allDay ? `${endAt}T23:59:59`   : endAt).toISOString(),
        is_all_day: allDay,
        recurrence_rule: effectiveRecurrence || null,
        ...(description.trim() ? { description: description.trim() } : {}),
        ...(location.trim()    ? { location:    location.trim() }    : {}),
        ...(meetingUrl.trim()  ? { meeting_url: meetingUrl.trim() }  : {}),
      })
      router.refresh()
      onClose()
    } finally {
      setSaving(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={v => !v && onClose()}>
      <DialogContent className="max-w-lg">
        <DialogHeader>
          <DialogTitle>Quick add event</DialogTitle>
        </DialogHeader>
        <div className="space-y-3 py-2">
          <div className="space-y-1">
            <Label>Title</Label>
            <Input
              placeholder="Event title"
              value={title}
              onChange={e => setTitle(e.target.value)}
              onKeyDown={e => e.key === 'Enter' && handleSave()}
              autoFocus
            />
          </div>
          <div className="flex items-center justify-between rounded-md border px-3 py-2">
            <Label htmlFor="quick-allday">All day</Label>
            <Switch
              id="quick-allday"
              checked={allDay}
              onCheckedChange={(v) => {
                const sDate = (startAt || '').slice(0, 10)
                const eDate = (endAt || '').slice(0, 10)
                setAllDay(v)
                if (v) { setStartAt(sDate); setEndAt(eDate) }
                else   { setStartAt(`${sDate}T09:00`); setEndAt(`${eDate}T10:00`) }
              }}
            />
          </div>
          <div className="space-y-1">
            <Label>Repeat</Label>
            <select
              value={recurrence}
              onChange={e => setRecurrence(e.target.value)}
              className="block w-full rounded-md border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            >
              <option value="">Does not repeat</option>
              <option value="FREQ=DAILY">Daily</option>
              <option value="FREQ=WEEKLY">Weekly</option>
              <option value="FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR">Every weekday (Mon-Fri)</option>
              <option value="FREQ=MONTHLY">Monthly</option>
              <option value="FREQ=YEARLY">Annually</option>
              <option value="CUSTOM">Custom...</option>
            </select>
            {recurrence === 'CUSTOM' && (
              <div className="mt-2 space-y-2 rounded-md border bg-muted/30 p-3">
                <div className="flex items-center gap-2">
                  <span className="text-sm text-muted-foreground">Every</span>
                  <Input
                    type="number" min={1}
                    value={cInterval}
                    onChange={e => setCInterval(Math.max(1, parseInt(e.target.value || '1', 10) || 1))}
                    className="w-16"
                  />
                  <select
                    value={cFreq}
                    onChange={e => setCFreq(e.target.value as typeof cFreq)}
                    className="rounded-md border border-gray-300 px-2 py-2 text-sm"
                  >
                    <option value="DAILY">day{cInterval > 1 ? 's' : ''}</option>
                    <option value="WEEKLY">week{cInterval > 1 ? 's' : ''}</option>
                    <option value="MONTHLY">month{cInterval > 1 ? 's' : ''}</option>
                    <option value="YEARLY">year{cInterval > 1 ? 's' : ''}</option>
                  </select>
                </div>

                {cFreq === 'WEEKLY' && (
                  <div className="flex flex-wrap gap-1">
                    {WEEKDAY_CODES.map((code, i) => (
                      <button
                        key={code}
                        type="button"
                        onClick={() => toggleByday(code)}
                        className={cn(
                          'h-8 w-8 rounded-full border text-xs font-medium transition-colors',
                          cByday.has(code)
                            ? 'border-blue-600 bg-blue-600 text-white'
                            : 'border-gray-300 text-muted-foreground hover:bg-muted',
                        )}
                      >
                        {WEEKDAY_LABELS[i]}
                      </button>
                    ))}
                  </div>
                )}

                <div className="space-y-1">
                  <span className="text-sm text-muted-foreground">Ends</span>
                  <div className="flex flex-col gap-1.5 text-sm">
                    <label className="flex items-center gap-2">
                      <input type="radio" name="cEnd" checked={cEndMode === 'never'} onChange={() => setCEndMode('never')} />
                      Never
                    </label>
                    <label className="flex items-center gap-2">
                      <input type="radio" name="cEnd" checked={cEndMode === 'until'} onChange={() => setCEndMode('until')} />
                      On
                      <Input
                        type="date"
                        value={cUntil}
                        onChange={e => { setCUntil(e.target.value); setCEndMode('until') }}
                        className="h-8 w-40"
                      />
                    </label>
                    <label className="flex items-center gap-2">
                      <input type="radio" name="cEnd" checked={cEndMode === 'count'} onChange={() => setCEndMode('count')} />
                      After
                      <Input
                        type="number" min={1}
                        value={cCount}
                        onChange={e => { setCCount(Math.max(1, parseInt(e.target.value || '1', 10) || 1)); setCEndMode('count') }}
                        className="h-8 w-20"
                      />
                      occurrences
                    </label>
                  </div>
                </div>
              </div>
            )}
            {effectiveRecurrence && (
              <p className="mt-1 text-xs text-muted-foreground">{rruleSummary(effectiveRecurrence)}</p>
            )}
          </div>

          {/* 3-1 More options */}
          <button
            type="button"
            onClick={() => setShowMore(v => !v)}
            className="text-sm text-blue-600 hover:underline"
          >
            {showMore ? 'Fewer options' : 'More options'}
          </button>
          {showMore && (
            <div className="space-y-3 rounded-md border bg-muted/20 p-3">
              <div className="space-y-1">
                <Label>Location</Label>
                <Input placeholder="Where" value={location} onChange={e => setLocation(e.target.value)} />
              </div>
              <div className="space-y-1">
                <Label>Meeting link</Label>
                <Input placeholder="https://… (Zoom / Teams / Meet)" value={meetingUrl} onChange={e => setMeetingUrl(e.target.value)} />
              </div>
              <div className="space-y-1">
                <Label>Description</Label>
                <textarea
                  rows={3}
                  placeholder="Notes / agenda"
                  value={description}
                  onChange={e => setDescription(e.target.value)}
                  className="block w-full rounded-md border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                />
              </div>
            </div>
          )}
          <div className="grid grid-cols-2 gap-2">
            <div className="space-y-1">
              <Label>Start</Label>
              <Input type={allDay ? 'date' : 'datetime-local'} value={allDay ? startAt.slice(0, 10) : startAt} onChange={e => setStartAt(e.target.value)} />
            </div>
            <div className="space-y-1">
              <Label>End</Label>
              <Input type={allDay ? 'date' : 'datetime-local'} value={allDay ? endAt.slice(0, 10) : endAt} onChange={e => setEndAt(e.target.value)} />
            </div>
          </div>
        </div>
        <div className="flex justify-between gap-2 pt-1">
          <Button variant="outline" size="sm" onClick={onClose}>Cancel</Button>
          <Button
            size="sm"
            className="bg-blue-600 hover:bg-blue-700 text-white"
            onClick={handleSave}
            disabled={saving || !title.trim()}
          >
            {saving ? 'Saving...' : 'Save'}
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  )
}

// --------------------------------------------------
// Item Detail Popup
// --------------------------------------------------

// Phase 2: human-readable summary of an RRULE string for the read-only popup.
function rruleSummary(rr: string | null | undefined): string {
  const v = (rr || '').trim().toUpperCase().replace(/^RRULE:/, '')
  if (!v) return ''
  if (v === 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR') return 'Every weekday'

  const m: Record<string, string> = {}
  for (const p of v.split(';')) {
    const [k, val] = p.split('=')
    if (k && val) m[k] = val
  }
  const freq = m.FREQ
  if (!freq) return 'Custom'

  const interval = parseInt(m.INTERVAL || '1', 10) || 1
  const unitWord: Record<string, string> = { DAILY: 'day', WEEKLY: 'week', MONTHLY: 'month', YEARLY: 'year' }
  const oneWord:  Record<string, string> = { DAILY: 'Daily', WEEKLY: 'Weekly', MONTHLY: 'Monthly', YEARLY: 'Annually' }
  let text = interval === 1
    ? (oneWord[freq] || 'Custom')
    : `Every ${interval} ${unitWord[freq] || 'time'}s`

  if (freq === 'WEEKLY' && m.BYDAY) {
    const names: Record<string, string> = { SU: 'Sun', MO: 'Mon', TU: 'Tue', WE: 'Wed', TH: 'Thu', FR: 'Fri', SA: 'Sat' }
    const order = ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA']
    const picked = m.BYDAY.split(',').map((d) => d.replace(/^[+-]?\d+/, ''))
    const labels = order.filter((d) => picked.includes(d)).map((d) => names[d])
    if (labels.length) text += ` on ${labels.join(', ')}`
  }

  if (m.UNTIL) {
    const u = m.UNTIL.replace(/[^0-9]/g, '')
    if (u.length >= 8) text += `, until ${u.slice(0, 4)}-${u.slice(4, 6)}-${u.slice(6, 8)}`
  } else if (m.COUNT) {
    text += `, ${m.COUNT} times`
  }
  return text
}

function ItemDetailPopup({
  item, onClose, onEdit, onEmail,
}: {
  item: CalendarItem | null
  onClose: () => void
  onEdit: (item: CalendarItem) => void
  onEmail: (item: CalendarItem) => void
}) {
  const router = useRouter()
  const [deleting, setDeleting] = useState(false)
  if (!item) return null

  const isEvent    = item.type === 'event'
  const isExternal = item.source === 'google' || item.source === 'microsoft'
  // Expanded recurrence occurrences carry a synthetic id (`${baseId}__${ymd}`);
  // edit/delete must target the real app.calendar_events row.
  const realId     = item.source_event_id ?? item.id

  const typeLabel: Record<string, string> = {
    meeting: 'Meeting', event: 'Event', task: 'Task', communication: 'Communication',
    todo: 'To-Do', milestone: 'Milestone',
  }

  async function handleDelete() {
    if (!item) return
    const msg = isExternal
      ? 'Delete this event? It will be hidden locally but may reappear on the next sync from your external calendar.'
      : 'Delete this event? This cannot be undone.'
    if (!window.confirm(msg)) return
    setDeleting(true)
    try {
      await deleteCalendarEvent(realId, item.source ?? 'internal')
      router.refresh()
      onClose()
    } finally {
      setDeleting(false)
    }
  }

  return (
    <Dialog open={!!item} onOpenChange={v => !v && onClose()}>
      {/* DialogContent renders its own close (X) at top-right; edit/delete sit to its left via pr-8 */}
      <DialogContent className="max-w-sm">
        <div className="flex items-start justify-between gap-2 pr-8">
          <DialogTitle className="text-base font-semibold leading-snug break-words min-w-0">
            {item.title}
          </DialogTitle>
          {isEvent && (
            <div className="flex items-center gap-0.5 shrink-0">
              <button
                type="button"
                title="Email attendees"
                className="p-1.5 rounded-md text-muted-foreground hover:text-foreground hover:bg-muted"
                onClick={() => onEmail(item)}
              >
                <Mail className="w-4 h-4" />
              </button>
              <button
                type="button"
                title="Edit"
                className="p-1.5 rounded-md text-muted-foreground hover:text-foreground hover:bg-muted"
                onClick={() => onEdit({ ...item, id: realId })}
              >
                <Pencil className="w-4 h-4" />
              </button>
              <button
                type="button"
                title="Delete"
                className="p-1.5 rounded-md text-muted-foreground hover:text-red-600 hover:bg-red-50 disabled:opacity-50"
                onClick={handleDelete}
                disabled={deleting}
              >
                <Trash2 className="w-4 h-4" />
              </button>
            </div>
          )}
        </div>

        <div className="space-y-2 text-sm">
          <div className="text-muted-foreground">
            {typeLabel[item.type]}
            {item.source && ` ${'\u00b7'} ${item.source}`}
          </div>
          <div>
            {new Date(item.start_at).toLocaleString('en-US')}
            {!item.is_all_day && ` - ${new Date(item.end_at).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })}`}
          </div>
          {item.party_name && (
            <div className="text-muted-foreground">Party: {item.party_name}</div>
          )}
          {item.location && (
            <div className="text-muted-foreground">Location: {item.location}</div>
          )}
          {isEvent && item.recurrence_rule && (
            <div className="text-muted-foreground">Repeats: {rruleSummary(item.recurrence_rule)}</div>
          )}
          {isEvent && Array.isArray(item.reminders) && item.reminders.length > 0 && (
            <div className="text-muted-foreground">
              Reminders: {item.reminders.length}
            </div>
          )}
          {item.meeting_url && (
            <a
              href={item.meeting_url}
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center gap-1 text-blue-600 hover:underline"
            >
              <ExternalLink className="w-3.5 h-3.5" />
              Meeting link
            </a>
          )}
        </div>

        {item.type === 'meeting' && (
          <div className="flex justify-end pt-2">
            <Button variant="outline" size="sm" asChild>
              <a href={`/meetings/${item.id}`}>View details</a>
            </Button>
          </div>
        )}
      </DialogContent>
    </Dialog>
  )
}

// --------------------------------------------------
// Page
// --------------------------------------------------

export default function CalendarPage() {
  const [items,       setItems]       = useState<CalendarItem[]>([])
  const [loading,     setLoading]     = useState(true)
  const [createDate,  setCreateDate]  = useState<Date | null>(null)
  const [createMode,  setCreateMode]  = useState<'event' | 'meeting'>('event')
  const [detailItem,  setDetailItem]  = useState<CalendarItem | null>(null)
  const [editItem,    setEditItem]    = useState<CalendarItem | null>(null)
  const [emailItem,   setEmailItem]   = useState<CalendarItem | null>(null)

  // Source visibility filter (close-date milestones default OFF per CALENDAR_FEED_META)
  const [visibleSources, setVisibleSources] = useState<Set<CalendarFeedSource>>(
    () => new Set(CALENDAR_FEED_SOURCES.filter((s) => CALENDAR_FEED_META[s].defaultVisible)),
  )
  const toggleSource = (s: CalendarFeedSource) =>
    setVisibleSources((prev) => {
      const next = new Set(prev)
      if (next.has(s)) next.delete(s); else next.add(s)
      return next
    })
  const visibleItems = items.filter((it) => !it.feed_source || visibleSources.has(it.feed_source))

  // Initial load - current month
  useEffect(() => {
    const now = new Date()
    const start = new Date(now.getFullYear(), now.getMonth() - 1, 1).toISOString()
    const end   = new Date(now.getFullYear(), now.getMonth() + 2, 0).toISOString()
    loadItems(start, end)
  }, [])

  async function loadItems(start: string, end: string) {
    setLoading(true)
    try {
      const data = await getCalendarFeed(start, end)
      setItems(data)
    } finally {
      setLoading(false)
    }
  }

  function handleCreateEvent(date: Date) {
    setCreateDate(date)
    setCreateMode('event')
  }

  return (
    <div className="flex flex-col h-[calc(100vh-64px)]">
      {/* Header */}
      <div className="flex items-center justify-between px-6 py-3 border-b border-border shrink-0">
        <h1 className="text-lg font-semibold">Calendar</h1>
        <div className="flex gap-2">
          <Button
            variant="outline" size="sm"
            onClick={() => { setCreateDate(new Date()); setCreateMode('meeting') }}
          >
            + Meeting
          </Button>
          <Button
            size="sm"
            className="bg-blue-600 hover:bg-blue-700 text-white"
            onClick={() => { setCreateDate(new Date()); setCreateMode('event') }}
          >
            + Event
          </Button>
        </div>
      </div>

      {/* Source filter (todo_v2) */}
      <div className="flex flex-wrap items-center gap-1.5 px-6 py-2 border-b border-border shrink-0">
        {CALENDAR_FEED_SOURCES.map((s) => {
          const on = visibleSources.has(s)
          const meta = CALENDAR_FEED_META[s]
          return (
            <button
              key={s}
              type="button"
              onClick={() => toggleSource(s)}
              aria-pressed={on}
              className={cn(
                'inline-flex items-center gap-1.5 rounded-full border px-2.5 py-1 text-xs transition-colors',
                on
                  ? 'border-border bg-muted/50 text-foreground'
                  : 'border-transparent text-muted-foreground opacity-60 hover:opacity-100',
              )}
            >
              <span
                className="h-2 w-2 rounded-full"
                style={{ backgroundColor: meta.color, opacity: on ? 1 : 0.4 }}
                aria-hidden
              />
              {meta.label}
            </button>
          )
        })}
      </div>

      {loading ? (
        <div className="flex-1 flex items-center justify-center text-muted-foreground text-sm">
          Loading...
        </div>
      ) : (
        <CalendarView
          items={visibleItems}
          onCreateEvent={handleCreateEvent}
          onItemClick={setDetailItem}
          onRangeChange={loadItems as never}
        />
      )}

      {/* Quick Event Modal */}
      {createDate && createMode === 'event' && (
        <QuickEventModal
          open
          defaultDate={createDate}
          onClose={() => setCreateDate(null)}
        />
      )}

      {/* Meeting Create Modal */}
      {createDate && createMode === 'meeting' && (
        <MeetingCreateModal
          open
          defaultDate={createDate}
          onClose={() => setCreateDate(null)}
        />
      )}

      {/* Item Detail */}
      <ItemDetailPopup
        item={detailItem}
        onClose={() => setDetailItem(null)}
        onEdit={(it) => { setDetailItem(null); setEditItem(it) }}
        onEmail={(it) => { setDetailItem(null); setEmailItem(it) }}
      />

      {/* Edit Event Modal (Phase 1) */}
      <EditEventModal
        item={editItem}
        onClose={() => setEditItem(null)}
      />

      {/* Email Attendees Modal (Phase 3) */}
      <EmailAttendeesModal
        item={emailItem}
        onClose={() => setEmailItem(null)}
      />
    </div>
  )
}
