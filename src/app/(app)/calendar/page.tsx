// src/app/(app)/calendar/page.tsx
'use client'
import { useState, useEffect, useCallback } from 'react'
import { CalendarView } from '@/components/calendar/calendar-view'
import { MeetingCreateModal } from '@/components/meetings/meeting-create-modal'
import type { CalendarItem } from '@/lib/queries/calendar'
import {
  fetchCalendarItemsAction as fetchCalendarItems,
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

  useEffect(() => {
    if (open) {
      const d = defaultDate
      const base = `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`
      setTitle('')
      setAllDay(false)
      setStartAt(`${base}T09:00`)
      setEndAt(`${base}T10:00`)
    }
  }, [open, defaultDate])

  async function handleSave() {
    if (!title.trim()) return
    setSaving(true)
    try {
      await createCalendarEvent({
        title:    title.trim(),
        start_at: new Date(allDay ? `${startAt}T00:00:00` : startAt).toISOString(),
        end_at:   new Date(allDay ? `${endAt}T23:59:59`   : endAt).toISOString(),
        is_all_day: allDay,
      })
      router.refresh()
      onClose()
    } finally {
      setSaving(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={v => !v && onClose()}>
      <DialogContent className="max-w-sm">
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
  if (v === 'FREQ=DAILY')   return 'Daily'
  if (v === 'FREQ=WEEKLY')  return 'Weekly'
  if (v === 'FREQ=MONTHLY') return 'Monthly'
  if (v === 'FREQ=YEARLY')  return 'Annually'
  return 'Custom'
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

  const typeLabel: Record<string, string> = {
    meeting: 'Meeting', event: 'Event', task: 'Task', communication: 'Communication',
  }

  async function handleDelete() {
    if (!item) return
    const msg = isExternal
      ? 'Delete this event? It will be hidden locally but may reappear on the next sync from your external calendar.'
      : 'Delete this event? This cannot be undone.'
    if (!window.confirm(msg)) return
    setDeleting(true)
    try {
      await deleteCalendarEvent(item.id, item.source ?? 'internal')
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
                onClick={() => onEdit(item)}
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
      const data = await fetchCalendarItems(start, end)
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

      {loading ? (
        <div className="flex-1 flex items-center justify-center text-muted-foreground text-sm">
          Loading...
        </div>
      ) : (
        <CalendarView
          items={items}
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
