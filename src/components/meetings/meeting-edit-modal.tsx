'use client'
// src/components/meetings/meeting-edit-modal.tsx
//
// 2026-09-14 — edit/delete for app.meetings (calendar chips of type 'meeting').
// Mirrors EditEventModal (calendar_events) so both item kinds behave the same:
// title/time/duration/place/links/agenda/notes + a destructive Delete.
//
// The modal loads its own row through getMeetingForEditAction, because the
// CalendarItem it is opened from carries only the calendar projection
// (no agenda/notes/status detail).
//
// Radix Select cannot hold an empty string value, so NONE is the sentinel for
// "not set" on the optional enum fields.

import { useEffect, useState } from 'react'
import {
  Dialog, DialogContent, DialogHeader, DialogTitle,
} from '@/components/ui/dialog'
import { Button }   from '@/components/ui/button'
import { Input }    from '@/components/ui/input'
import { Label }    from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import {
  Select, SelectTrigger, SelectValue, SelectContent, SelectItem,
} from '@/components/ui/select'
import { Trash2 } from 'lucide-react'
import {
  getMeetingForEditAction,
  updateMeetingAction,
  deleteMeetingAction,
} from '@/app/actions/meetings'

const NONE = '__none__'

const STATUSES = [
  { value: 'scheduled',   label: 'Scheduled' },
  { value: 'completed',   label: 'Completed' },
  { value: 'cancelled',   label: 'Cancelled' },
  { value: 'no_show',     label: 'No show' },
  { value: 'rescheduled', label: 'Rescheduled' },
]

const MEETING_TYPES = [
  { value: 'discovery',   label: 'Discovery' },
  { value: 'demo',        label: 'Demo' },
  { value: 'proposal',    label: 'Proposal' },
  { value: 'negotiation', label: 'Negotiation' },
  { value: 'follow_up',   label: 'Follow-up' },
  { value: 'check_in',    label: 'Check-in' },
  { value: 'kickoff',     label: 'Kickoff' },
  { value: 'review',      label: 'Review' },
  { value: 'internal',    label: 'Internal' },
  { value: 'other',       label: 'Other' },
]

// subset of app.engagement_channel that is meaningful for a meeting
const CHANNELS = [
  { value: 'video_call',       label: 'Video call' },
  { value: 'video_conference', label: 'Video conference' },
  { value: 'phone_call',       label: 'Phone' },
  { value: 'in_person',        label: 'In person' },
  { value: 'hybrid',           label: 'Hybrid' },
  { value: 'other',            label: 'Other' },
]

const pad = (n: number) => String(n).padStart(2, '0')

// ISO -> value for <input type="datetime-local"> in the browser's local time
function toLocalInput(iso: string | null | undefined): string {
  if (!iso) return ''
  const d = new Date(iso)
  if (Number.isNaN(d.getTime())) return ''
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
       + `T${pad(d.getHours())}:${pad(d.getMinutes())}`
}

interface Props {
  meetingId:   string | null
  onClose:     () => void
  onSaved?:    () => void
  onDeleted?:  () => void
}

export function MeetingEditModal({ meetingId, onClose, onSaved, onDeleted }: Props) {
  const [loading,  setLoading]  = useState(false)
  const [saving,   setSaving]   = useState(false)
  const [deleting, setDeleting] = useState(false)
  const [error,    setError]    = useState<string | null>(null)

  const [title,       setTitle]       = useState('')
  const [status,      setStatus]      = useState('scheduled')
  const [meetingType, setMeetingType] = useState(NONE)
  const [channel,     setChannel]     = useState(NONE)
  const [scheduledAt, setScheduledAt] = useState('')
  const [duration,    setDuration]    = useState('30')
  const [location,    setLocation]    = useState('')
  const [meetingUrl,  setMeetingUrl]  = useState('')
  const [agenda,      setAgenda]      = useState('')
  const [notes,       setNotes]       = useState('')

  useEffect(() => {
    if (!meetingId) return
    let cancelled = false
    setLoading(true)
    setError(null)
    getMeetingForEditAction(meetingId)
      .then(res => {
        if (cancelled) return
        if (!res.ok) { setError(res.error); return }
        const m = res.data
        setTitle(m.title ?? '')
        setStatus(m.status || 'scheduled')
        setMeetingType(m.meeting_type || NONE)
        setChannel(m.channel || NONE)
        setScheduledAt(toLocalInput(m.scheduled_at ?? m.occurred_at))
        setDuration(String(m.duration_min ?? 30))
        setLocation(m.location ?? '')
        setMeetingUrl(m.meeting_url ?? '')
        setAgenda(m.agenda ?? '')
        setNotes(m.notes ?? '')
      })
      .catch(e => { if (!cancelled) setError(e instanceof Error ? e.message : String(e)) })
      .finally(() => { if (!cancelled) setLoading(false) })
    return () => { cancelled = true }
  }, [meetingId])

  if (!meetingId) return null

  async function handleSave() {
    if (!meetingId) return
    if (!title.trim()) { setError('Title is required'); return }
    setSaving(true)
    setError(null)
    try {
      const minutes = parseInt(duration, 10)
      const res = await updateMeetingAction(meetingId, {
        title:        title.trim(),
        status,
        meeting_type: meetingType === NONE ? null : meetingType,
        channel:      channel === NONE ? null : channel,
        scheduled_at: scheduledAt ? new Date(scheduledAt).toISOString() : null,
        duration_min: Number.isFinite(minutes) && minutes > 0 ? minutes : 30,
        location:     location.trim() || null,
        meeting_url:  meetingUrl.trim() || null,
        agenda:       agenda.trim() || null,
        notes:        notes.trim() || null,
      })
      if (!res.ok) { setError(res.error); return }
      onSaved?.()
      onClose()
    } finally {
      setSaving(false)
    }
  }

  async function handleDelete() {
    if (!meetingId) return
    if (!window.confirm('Delete this meeting? It will be removed from the calendar and Today. This cannot be undone from the UI.')) return
    setDeleting(true)
    setError(null)
    try {
      const res = await deleteMeetingAction(meetingId)
      if (!res.ok) { setError(res.error); return }
      onDeleted?.()
      onClose()
    } finally {
      setDeleting(false)
    }
  }

  return (
    <Dialog open={!!meetingId} onOpenChange={v => !v && onClose()}>
      <DialogContent className="max-w-md max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Edit meeting</DialogTitle>
        </DialogHeader>

        {loading ? (
          <div className="py-8 text-center text-sm text-muted-foreground">Loading...</div>
        ) : (
          <div className="space-y-3 py-1">
            <div className="space-y-1">
              <Label>Title</Label>
              <Input value={title} onChange={e => setTitle(e.target.value)} autoFocus />
            </div>

            <div className="grid grid-cols-2 gap-2">
              <div className="space-y-1">
                <Label>Start</Label>
                <Input
                  type="datetime-local"
                  value={scheduledAt}
                  onChange={e => setScheduledAt(e.target.value)}
                />
              </div>
              <div className="space-y-1">
                <Label>Duration (min)</Label>
                <Input
                  type="number"
                  min={5}
                  step={5}
                  value={duration}
                  onChange={e => setDuration(e.target.value)}
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-2">
              <div className="space-y-1">
                <Label>Status</Label>
                <Select value={status} onValueChange={setStatus}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    {STATUSES.map(s => (
                      <SelectItem key={s.value} value={s.value}>{s.label}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-1">
                <Label>Type</Label>
                <Select value={meetingType} onValueChange={setMeetingType}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value={NONE}>Not set</SelectItem>
                    {MEETING_TYPES.map(t => (
                      <SelectItem key={t.value} value={t.value}>{t.label}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="space-y-1">
              <Label>Channel</Label>
              <Select value={channel} onValueChange={setChannel}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value={NONE}>Not set</SelectItem>
                  {CHANNELS.map(c => (
                    <SelectItem key={c.value} value={c.value}>{c.label}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-1">
              <Label>Location</Label>
              <Input value={location} onChange={e => setLocation(e.target.value)} />
            </div>

            <div className="space-y-1">
              <Label>Meeting URL</Label>
              <Input
                placeholder="https://..."
                value={meetingUrl}
                onChange={e => setMeetingUrl(e.target.value)}
              />
            </div>

            <div className="space-y-1">
              <Label>Agenda</Label>
              <Textarea rows={4} value={agenda} onChange={e => setAgenda(e.target.value)} />
            </div>

            <div className="space-y-1">
              <Label>Notes</Label>
              <Textarea rows={3} value={notes} onChange={e => setNotes(e.target.value)} />
            </div>

            {error && <p className="text-xs text-red-600">{error}</p>}
          </div>
        )}

        <div className="flex items-center justify-between gap-2 pt-1">
          <Button
            variant="ghost"
            size="sm"
            className="text-red-600 hover:text-red-700 hover:bg-red-50"
            onClick={handleDelete}
            disabled={deleting || saving || loading}
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
              disabled={saving || deleting || loading || !title.trim()}
            >
              {saving ? 'Saving...' : 'Save'}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}
