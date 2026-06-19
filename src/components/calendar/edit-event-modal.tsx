'use client'
// src/components/calendar/edit-event-modal.tsx
// Phase 1 - Google-style edit modal for calendar_events (type==='event').
// UX (B): all events are locally editable/deletable; google/microsoft events
// show a warning banner because local changes may be overwritten on next sync.
import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import type { CalendarItem } from '@/lib/queries/calendar'
import {
  updateCalendarEventAction,
  deleteCalendarEventAction,
} from '@/app/actions/calendar'
import {
  Dialog, DialogContent, DialogHeader, DialogTitle,
} from '@/components/ui/dialog'
import { Button }   from '@/components/ui/button'
import { Input }    from '@/components/ui/input'
import { Label }    from '@/components/ui/label'
import { Switch }   from '@/components/ui/switch'
import { Textarea } from '@/components/ui/textarea'
import {
  Select, SelectTrigger, SelectValue, SelectContent, SelectItem,
} from '@/components/ui/select'
import { AlertTriangle, Trash2 } from 'lucide-react'

const pad = (n: number) => String(n).padStart(2, '0')

// ISO timestamp -> value for <input type="date" | "datetime-local"> in local time.
function toLocalInput(iso: string | undefined, allDay: boolean): string {
  if (!iso) return ''
  const d = new Date(iso)
  if (Number.isNaN(d.getTime())) return ''
  const base = `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
  return allDay ? base : `${base}T${pad(d.getHours())}:${pad(d.getMinutes())}`
}

export function EditEventModal({
  item, onClose,
}: { item: CalendarItem | null; onClose: () => void }) {
  const router = useRouter()
  const [title,         setTitle]         = useState('')
  const [allDay,        setAllDay]        = useState(false)
  const [startAt,       setStartAt]       = useState('')
  const [endAt,         setEndAt]         = useState('')
  const [location,      setLocation]      = useState('')
  const [description,   setDescription]   = useState('')
  const [visibility,    setVisibility]    = useState('default')
  const [attendeesText, setAttendeesText] = useState('')
  const [saving,        setSaving]        = useState(false)
  const [deleting,      setDeleting]      = useState(false)
  const [error,         setError]         = useState<string | null>(null)

  const isExternal = item?.source === 'google' || item?.source === 'microsoft'

  useEffect(() => {
    if (!item) return
    const ad = !!item.is_all_day
    setTitle(item.title ?? '')
    setAllDay(ad)
    setStartAt(toLocalInput(item.start_at, ad))
    setEndAt(toLocalInput(item.end_at, ad))
    setLocation(item.location ?? '')
    setDescription(item.description ?? '')
    setVisibility(item.visibility || 'default')
    setAttendeesText((item.attendees ?? []).map(a => a.email).filter(Boolean).join(', '))
    setError(null)
  }, [item])

  if (!item) return null

  function handleAllDayToggle(v: boolean) {
    const sDate = (startAt || '').slice(0, 10)
    const eDate = (endAt || '').slice(0, 10)
    setAllDay(v)
    if (v) { setStartAt(sDate); setEndAt(eDate) }
    else   { setStartAt(`${sDate}T09:00`); setEndAt(`${eDate}T10:00`) }
  }

  async function handleSave() {
    if (!item) return
    if (!title.trim()) return
    setSaving(true)
    setError(null)
    try {
      const attendees = attendeesText
        .split(',')
        .map(s => s.trim())
        .filter(Boolean)
        .map(email => ({ email }))
      await updateCalendarEventAction(item.id, {
        title:       title.trim(),
        location:    location.trim() || null,
        description: description.trim() || null,
        start_at:    new Date(allDay ? `${startAt}T00:00:00` : startAt).toISOString(),
        end_at:      new Date(allDay ? `${endAt}T23:59:59`   : endAt).toISOString(),
        is_all_day:  allDay,
        visibility,
        attendees,
      })
      router.refresh()
      onClose()
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to save event')
    } finally {
      setSaving(false)
    }
  }

  async function handleDelete() {
    if (!item) return
    const msg = isExternal
      ? 'Delete this event? It will be hidden locally but may reappear on the next sync from your external calendar.'
      : 'Delete this event? This cannot be undone.'
    if (!window.confirm(msg)) return
    setDeleting(true)
    setError(null)
    try {
      await deleteCalendarEventAction(item.id, item.source ?? 'internal')
      router.refresh()
      onClose()
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to delete event')
    } finally {
      setDeleting(false)
    }
  }

  return (
    <Dialog open={!!item} onOpenChange={v => !v && onClose()}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle>Edit event</DialogTitle>
        </DialogHeader>

        {isExternal && (
          <div className="flex gap-2 rounded-md border border-amber-300 bg-amber-50 px-3 py-2 text-xs text-amber-800">
            <AlertTriangle className="w-4 h-4 shrink-0 mt-0.5" />
            <span>
              This is a {item.source} Calendar event. Changes here apply locally
              only and may be overwritten by the original on the next sync.
            </span>
          </div>
        )}

        <div className="space-y-3 py-1">
          <div className="space-y-1">
            <Label>Title</Label>
            <Input value={title} onChange={e => setTitle(e.target.value)} autoFocus />
          </div>

          <div className="flex items-center justify-between rounded-md border px-3 py-2">
            <Label htmlFor="edit-allday">All day</Label>
            <Switch id="edit-allday" checked={allDay} onCheckedChange={handleAllDayToggle} />
          </div>

          <div className="grid grid-cols-2 gap-2">
            <div className="space-y-1">
              <Label>Start</Label>
              <Input
                type={allDay ? 'date' : 'datetime-local'}
                value={allDay ? startAt.slice(0, 10) : startAt}
                onChange={e => setStartAt(e.target.value)}
              />
            </div>
            <div className="space-y-1">
              <Label>End</Label>
              <Input
                type={allDay ? 'date' : 'datetime-local'}
                value={allDay ? endAt.slice(0, 10) : endAt}
                onChange={e => setEndAt(e.target.value)}
              />
            </div>
          </div>

          <div className="space-y-1">
            <Label>Location</Label>
            <Input value={location} onChange={e => setLocation(e.target.value)} />
          </div>

          <div className="space-y-1">
            <Label>Description</Label>
            <Textarea rows={3} value={description} onChange={e => setDescription(e.target.value)} />
          </div>

          <div className="space-y-1">
            <Label>Visibility</Label>
            <Select value={visibility} onValueChange={setVisibility}>
              <SelectTrigger><SelectValue /></SelectTrigger>
              <SelectContent>
                <SelectItem value="default">Default</SelectItem>
                <SelectItem value="public">Public</SelectItem>
                <SelectItem value="private">Private</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-1">
            <Label>Attendees (comma-separated emails)</Label>
            <Input
              placeholder="a@example.com, b@example.com"
              value={attendeesText}
              onChange={e => setAttendeesText(e.target.value)}
            />
          </div>

          {error && <p className="text-xs text-red-600">{error}</p>}
        </div>

        <div className="flex items-center justify-between gap-2 pt-1">
          <Button
            variant="ghost"
            size="sm"
            className="text-red-600 hover:text-red-700 hover:bg-red-50"
            onClick={handleDelete}
            disabled={deleting || saving}
          >
            <Trash2 className="w-4 h-4 mr-1" />
            {deleting ? 'Deleting...' : 'Delete'}
          </Button>
          <div className="flex gap-2">
            <Button variant="outline" size="sm" onClick={onClose} disabled={saving || deleting}>
              Cancel
            </Button>
            <Button
              size="sm"
              className="bg-blue-600 hover:bg-blue-700 text-white"
              onClick={handleSave}
              disabled={saving || deleting || !title.trim()}
            >
              {saving ? 'Saving...' : 'Save'}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}
