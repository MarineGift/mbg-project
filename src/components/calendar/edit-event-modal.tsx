'use client'
// src/components/calendar/edit-event-modal.tsx
// Phase 2 - Google-style edit modal for calendar_events (type==='event').
// Phase 1: title/all-day/time/location/description/visibility/attendees + delete.
// Phase 2 adds: color picker, repeat (recurrence_rule via RRULE presets + custom),
//               reminders (multiple, minutes-before), show-as (busy/free transparency).
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
import { AlertTriangle, Trash2, Plus, X } from 'lucide-react'
import { cn } from '@/lib/utils'

const pad = (n: number) => String(n).padStart(2, '0')

// ISO timestamp -> value for <input type="date" | "datetime-local"> in local time.
function toLocalInput(iso: string | undefined, allDay: boolean): string {
  if (!iso) return ''
  const d = new Date(iso)
  if (Number.isNaN(d.getTime())) return ''
  const base = `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
  return allDay ? base : `${base}T${pad(d.getHours())}:${pad(d.getMinutes())}`
}

// ─────────────────────────────────────────────
// Phase 2 option tables
// ─────────────────────────────────────────────

const COLOR_OPTIONS: { hex: string; name: string }[] = [
  { hex: '',        name: 'Default' },
  { hex: '#7986cb', name: 'Lavender' },
  { hex: '#33b679', name: 'Sage' },
  { hex: '#039be5', name: 'Peacock' },
  { hex: '#3f51b5', name: 'Blueberry' },
  { hex: '#8e24aa', name: 'Grape' },
  { hex: '#e67c73', name: 'Flamingo' },
  { hex: '#f6bf26', name: 'Banana' },
  { hex: '#f4511e', name: 'Tangerine' },
  { hex: '#d50000', name: 'Tomato' },
  { hex: '#0b8043', name: 'Basil' },
  { hex: '#616161', name: 'Graphite' },
]

const REMINDER_OPTIONS: { v: number; label: string }[] = [
  { v: 0,    label: 'At time of event' },
  { v: 5,    label: '5 minutes before' },
  { v: 10,   label: '10 minutes before' },
  { v: 15,   label: '15 minutes before' },
  { v: 30,   label: '30 minutes before' },
  { v: 60,   label: '1 hour before' },
  { v: 120,  label: '2 hours before' },
  { v: 1440, label: '1 day before' },
]

type RecurrencePreset =
  | 'none' | 'daily' | 'weekly' | 'monthly' | 'yearly' | 'weekday' | 'custom'

const RRULE_BY_PRESET: Record<
  Exclude<RecurrencePreset, 'none' | 'custom'>, string
> = {
  daily:   'FREQ=DAILY',
  weekly:  'FREQ=WEEKLY',
  monthly: 'FREQ=MONTHLY',
  yearly:  'FREQ=YEARLY',
  weekday: 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR',
}

function normalizeRrule(rr: string): string {
  return (rr || '').trim().toUpperCase().replace(/^RRULE:/, '')
}

function rruleToPreset(rr: string): RecurrencePreset {
  const v = normalizeRrule(rr)
  if (!v) return 'none'
  for (const [k, val] of Object.entries(RRULE_BY_PRESET)) {
    if (val === v) return k as RecurrencePreset
  }
  return 'custom'
}

function presetToRrule(preset: RecurrencePreset, custom: string): string | null {
  if (preset === 'none') return null
  if (preset === 'custom') {
    const c = (custom || '').trim().replace(/^RRULE:/i, '')
    return c ? c : null
  }
  return RRULE_BY_PRESET[preset]
}

// ─────────────────────────────────────────────
// Component
// ─────────────────────────────────────────────

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
  // Phase 2 state
  const [color,         setColor]         = useState('')
  const [recurrence,    setRecurrence]    = useState<RecurrencePreset>('none')
  const [customRrule,   setCustomRrule]   = useState('')
  const [reminders,     setReminders]     = useState<{ minutes: number }[]>([])
  const [transparency,  setTransparency]  = useState('opaque')
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
    // Phase 2 init
    setColor(item.color ?? '')
    const rr = item.recurrence_rule ?? ''
    const preset = rruleToPreset(rr)
    setRecurrence(preset)
    setCustomRrule(preset === 'custom' ? normalizeRrule(rr) : '')
    setReminders(
      Array.isArray(item.reminders)
        ? item.reminders
            .map(r => ({ minutes: Number((r as { minutes?: unknown }).minutes) || 0 }))
        : []
    )
    setTransparency(item.transparency || 'opaque')
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
        title:           title.trim(),
        location:        location.trim() || null,
        description:     description.trim() || null,
        start_at:        new Date(allDay ? `${startAt}T00:00:00` : startAt).toISOString(),
        end_at:          new Date(allDay ? `${endAt}T23:59:59`   : endAt).toISOString(),
        is_all_day:      allDay,
        visibility,
        attendees,
        // Phase 2
        color:           color || null,
        recurrence_rule: presetToRrule(recurrence, customRrule),
        reminders,
        transparency,
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
      <DialogContent className="max-w-md max-h-[90vh] overflow-y-auto">
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
            <Label>Repeat</Label>
            <Select value={recurrence} onValueChange={v => setRecurrence(v as RecurrencePreset)}>
              <SelectTrigger><SelectValue /></SelectTrigger>
              <SelectContent>
                <SelectItem value="none">Does not repeat</SelectItem>
                <SelectItem value="daily">Daily</SelectItem>
                <SelectItem value="weekly">Weekly</SelectItem>
                <SelectItem value="monthly">Monthly</SelectItem>
                <SelectItem value="yearly">Annually</SelectItem>
                <SelectItem value="weekday">Every weekday (Mon-Fri)</SelectItem>
                <SelectItem value="custom">Custom (RRULE)</SelectItem>
              </SelectContent>
            </Select>
            {recurrence === 'custom' && (
              <Input
                className="mt-1 font-mono text-xs"
                placeholder="FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE"
                value={customRrule}
                onChange={e => setCustomRrule(e.target.value)}
              />
            )}
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
            <Label>Color</Label>
            <div className="flex flex-wrap gap-1.5">
              {COLOR_OPTIONS.map(c => {
                const selected = (color || '') === c.hex
                return (
                  <button
                    key={c.hex || 'default'}
                    type="button"
                    title={c.name}
                    onClick={() => setColor(c.hex)}
                    className={cn(
                      'flex h-6 w-6 items-center justify-center rounded-full border transition',
                      selected ? 'ring-2 ring-offset-1 ring-blue-500' : 'hover:scale-110',
                      !c.hex && 'bg-white'
                    )}
                    style={c.hex ? { backgroundColor: c.hex } : undefined}
                  >
                    {!c.hex && <span className="text-[10px] text-muted-foreground">x</span>}
                  </button>
                )
              })}
            </div>
          </div>

          <div className="space-y-1">
            <Label>Reminders</Label>
            <div className="space-y-1.5">
              {reminders.map((r, idx) => (
                <div key={idx} className="flex items-center gap-2">
                  <Select
                    value={String(r.minutes)}
                    onValueChange={val =>
                      setReminders(rs => rs.map((x, i) => (i === idx ? { minutes: Number(val) } : x)))
                    }
                  >
                    <SelectTrigger className="flex-1"><SelectValue /></SelectTrigger>
                    <SelectContent>
                      {REMINDER_OPTIONS.map(o => (
                        <SelectItem key={o.v} value={String(o.v)}>{o.label}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    className="px-2"
                    onClick={() => setReminders(rs => rs.filter((_, i) => i !== idx))}
                  >
                    <X className="w-4 h-4" />
                  </Button>
                </div>
              ))}
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={() => setReminders(rs => [...rs, { minutes: 10 }])}
              >
                <Plus className="w-4 h-4 mr-1" /> Add reminder
              </Button>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-2">
            <div className="space-y-1">
              <Label>Show as</Label>
              <Select value={transparency} onValueChange={setTransparency}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="opaque">Busy</SelectItem>
                  <SelectItem value="transparent">Free</SelectItem>
                </SelectContent>
              </Select>
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
