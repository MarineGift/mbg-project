'use client'
// src/components/meetings/meeting-create-modal.tsx
//
// Stage 26 (2026-05-21):
// party → engagement → stage cascading selector.
// - engagement_id, stage_id both optional (nullable in the DB too)
// - expose only active engagements (open / in_progress / on_hold)
// - terminal stages (won / lost) get a visual marker
// - depends on: src/lib/actions/meeting-form.ts (server action wrapper)
//
// Layers only cascading on top of the existing Stage 24 channel + meetings.ts API.

import { useState, useTransition, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import {
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter,
} from '@/components/ui/dialog'
import { Button }   from '@/components/ui/button'
import { Input }    from '@/components/ui/input'
import { Label }    from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from '@/components/ui/select'
import { createMeetingAction as createMeeting } from '@/app/actions/create-meeting'
import type { MeetingType, MeetingChannel } from '@/lib/queries/meetings'
import {
  loadPartyEngagementsForForm,
  loadStagesForForm,
} from '@/lib/actions/meeting-form'
import type { KanbanCard, KanbanStage } from '@/types/engagement'
import { cn } from '@/lib/utils'

interface Props {
  open:          boolean
  onClose:       () => void
  defaultDate?:  Date
  defaultPartyId?: string
  defaultPartyName?: string
}

const MEETING_TYPES: { value: MeetingType; label: string }[] = [
  { value: 'discovery',   label: 'Discovery' },
  { value: 'demo',        label: 'Demo' },
  { value: 'proposal',    label: 'Proposal' },
  { value: 'negotiation', label: 'Negotiation' },
  { value: 'follow_up',   label: 'Follow-up' },
  { value: 'check_in',    label: 'Check-in' },
  { value: 'internal',    label: 'Internal' },
  { value: 'other',       label: 'Other' },
]

const MEETING_CHANNELS: { value: MeetingChannel; label: string; icon: string }[] = [
  { value: 'video_call', label: 'Video call', icon: '🎥' },
  { value: 'phone_call', label: 'Phone',     icon: '📞' },
  { value: 'in_person',  label: 'In person', icon: '🏢' },
  { value: 'hybrid',     label: 'Hybrid', icon: '🔀' },
]

// engagement filter - the modal shows only active states (hides won/lost/archived)
const ACTIVE_ENGAGEMENT_STATUSES = new Set(['open', 'in_progress', 'on_hold'])

function todayAt(h: number, m = 0): string {
  const d = new Date()
  d.setHours(h, m, 0, 0)
  return d.toISOString().slice(0, 16)   // "YYYY-MM-DDTHH:MM"
}

// sentinel value for the Select's "None" option (Radix Select can't use an empty string)
const NONE = '__none__'

export function MeetingCreateModal({ open, onClose, defaultDate, defaultPartyId, defaultPartyName }: Props) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [error, setError] = useState<string | null>(null)

  // Form state
  const defaultDt = defaultDate
    ? `${defaultDate.toISOString().slice(0, 10)}T09:00`
    : todayAt(9)

  const [title,        setTitle]       = useState('')
  const [partyId,      setPartyId]     = useState(defaultPartyId ?? '')
  const [partySearch,  setPartySearch] = useState(defaultPartyName ?? '')
  const [scheduledAt,  setScheduledAt] = useState(defaultDt)
  const [duration,     setDuration]    = useState(30)
  const [meetingType,  setMeetingType] = useState<MeetingType>('discovery')
  const [meetingMode,  setMeetingMode] = useState<MeetingChannel>('video_call')
  const [meetingUrl,   setMeetingUrl]  = useState('')
  const [agenda,       setAgenda]      = useState('')

  // Stage 26 — cascading selector state
  const [engagementId, setEngagementId] = useState<string | null>(null)
  const [stageId,      setStageId]      = useState<string | null>(null)
  const [engagements,  setEngagements]  = useState<KanbanCard[]>([])
  const [stages,       setStages]       = useState<KanbanStage[]>([])
  const [loadingEngagements, setLoadingEngagements] = useState(false)
  const [loadingStages,      setLoadingStages]      = useState(false)

  // Effect 1: partyId change -> load engagement candidates (cascading reset)
  useEffect(() => {
    setEngagementId(null)
    setStageId(null)
    setStages([])

    if (!partyId) {
      setEngagements([])
      return
    }

    let cancelled = false
    setLoadingEngagements(true)
    loadPartyEngagementsForForm(partyId)
      .then((cards) => {
        if (cancelled) return
        // expose only active engagements
        setEngagements(cards.filter(c => ACTIVE_ENGAGEMENT_STATUSES.has(c.status)))
      })
      .catch(() => { if (!cancelled) setEngagements([]) })
      .finally(() => { if (!cancelled) setLoadingEngagements(false) })

    return () => { cancelled = true }
  }, [partyId])

  // Effect 2: engagementId change -> load the engagement's pipeline stages
  useEffect(() => {
    setStageId(null)

    if (!engagementId) {
      setStages([])
      return
    }

    const engagement = engagements.find(e => e.id === engagementId)
    if (!engagement?.pipelineDefinitionId) {
      setStages([])
      return
    }

    let cancelled = false
    setLoadingStages(true)
    loadStagesForForm(engagement.pipelineDefinitionId)
      .then((s) => {
        if (cancelled) return
        setStages(s)
        // preselect the engagement's current stage if present
        if (engagement.currentStageId) {
          setStageId(engagement.currentStageId)
        }
      })
      .catch(() => { if (!cancelled) setStages([]) })
      .finally(() => { if (!cancelled) setLoadingStages(false) })

    return () => { cancelled = true }
  }, [engagementId, engagements])

  function reset() {
    setTitle(''); setPartyId(''); setPartySearch('')
    setScheduledAt(defaultDt); setDuration(30)
    setMeetingType('discovery'); setMeetingMode('video_call')
    setMeetingUrl(''); setAgenda(''); setError(null)
    setEngagementId(null); setStageId(null)
    setEngagements([]); setStages([])
  }

  function handleClose() { reset(); onClose() }

  function handleSubmit() {
    if (!title.trim()) { setError('Please enter a title'); return }
    if (!partyId)      { setError('Please select a party (required)'); return }

    startTransition(async () => {
      try {
        await createMeeting({
          title:            title.trim(),
          party_id:         partyId,
          engagement_id:    engagementId ?? undefined,
          stage_id:         stageId ?? undefined,
          scheduled_at:     new Date(scheduledAt).toISOString(),
          duration_min:     duration,
          meeting_type:     meetingType,
          channel:          meetingMode,
          meeting_url:      meetingUrl.trim() || undefined,
          agenda:           agenda.trim() || undefined,
        })
        router.refresh()
        handleClose()
      } catch (e: any) {
        setError(e.message)
      }
    })
  }

  return (
    <Dialog open={open} onOpenChange={v => !v && handleClose()}>
      <DialogContent className="max-w-lg">
        <DialogHeader>
          <DialogTitle>New Meeting</DialogTitle>
        </DialogHeader>

        <div className="space-y-4 py-2">
          {/* Title */}
          <div className="space-y-1">
            <Label htmlFor="mtg-title">Meeting title *</Label>
            <Input
              id="mtg-title"
              placeholder="e.g. ABC Corp proposal meeting"
              value={title}
              onChange={e => setTitle(e.target.value)}
            />
          </div>

          {/* Party - simple text input (to be replaced by a Party search component) */}
          <div className="space-y-1">
            <Label htmlFor="mtg-party">Party *</Label>
            <Input
              id="mtg-party"
              placeholder="Enter Party ID (Party search UI to be wired up)"
              value={partyId}
              onChange={e => setPartyId(e.target.value)}
            />
            <p className="text-xs text-muted-foreground">
              TODO: replace with PartySearchCombobox
            </p>
          </div>

          {/* Stage 26 - Engagement (optional, shown after partyId is selected) */}
          {partyId && (
            <div className="space-y-1">
              <Label htmlFor="mtg-engagement">Related Engagement (optional)</Label>
              {loadingEngagements ? (
                <p className="text-xs text-muted-foreground">Loading...</p>
              ) : engagements.length === 0 ? (
                <p className="text-xs text-muted-foreground">
                  No active engagement (you can still create a meeting without one)
                </p>
              ) : (
                <Select
                  value={engagementId ?? NONE}
                  onValueChange={v => setEngagementId(v === NONE ? null : v)}
                >
                  <SelectTrigger id="mtg-engagement">
                    <SelectValue placeholder="Select engagement" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value={NONE}>— None —</SelectItem>
                    {engagements.map(e => (
                      <SelectItem key={e.id} value={e.id}>
                        {e.name}
                        <span className="ml-1 text-xs text-muted-foreground">
                          ({e.status})
                        </span>
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              )}
            </div>
          )}

          {/* Stage 26 - Stage (optional, shown after engagementId is selected) */}
          {engagementId && (
            <div className="space-y-1">
              <Label htmlFor="mtg-stage">Stage (optional)</Label>
              {loadingStages ? (
                <p className="text-xs text-muted-foreground">Loading...</p>
              ) : stages.length === 0 ? (
                <p className="text-xs text-muted-foreground">
                  No pipeline stages
                </p>
              ) : (
                <Select
                  value={stageId ?? NONE}
                  onValueChange={v => setStageId(v === NONE ? null : v)}
                >
                  <SelectTrigger id="mtg-stage">
                    <SelectValue placeholder="Select stage" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value={NONE}>— Unassigned —</SelectItem>
                    {stages.map(s => (
                      <SelectItem key={s.id} value={s.id}>
                        {s.name}
                        {s.isWon && (
                          <span className="ml-1 text-xs text-green-600">✓ won</span>
                        )}
                        {s.isLost && (
                          <span className="ml-1 text-xs text-red-600">✗ lost</span>
                        )}
                        {s.isTerminal && !s.isWon && !s.isLost && (
                          <span className="ml-1 text-xs text-muted-foreground">● terminal</span>
                        )}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              )}
            </div>
          )}

          {/* Date/Time + Duration */}
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1">
              <Label htmlFor="mtg-dt">Date & time *</Label>
              <Input
                id="mtg-dt"
                type="datetime-local"
                value={scheduledAt}
                onChange={e => setScheduledAt(e.target.value)}
              />
            </div>
            <div className="space-y-1">
              <Label htmlFor="mtg-dur">Duration (min)</Label>
              <Select
                value={String(duration)}
                onValueChange={v => setDuration(Number(v))}
              >
                <SelectTrigger id="mtg-dur">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {[15, 30, 45, 60, 90, 120].map(d => (
                    <SelectItem key={d} value={String(d)}>{d} min</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          {/* Meeting Type + Mode */}
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1">
              <Label>Meeting type</Label>
              <Select value={meetingType} onValueChange={v => setMeetingType(v as MeetingType)}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {MEETING_TYPES.map(t => (
                    <SelectItem key={t.value} value={t.value}>{t.label}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-1">
              <Label>Meeting format</Label>
              <div className="grid grid-cols-2 gap-1">
                {MEETING_CHANNELS.map(m => (
                  <button
                    key={m.value}
                    type="button"
                    onClick={() => setMeetingMode(m.value)}
                    className={cn(
                      'flex items-center gap-1 text-xs px-2 py-1.5 rounded border transition-colors',
                      meetingMode === m.value
                        ? 'bg-blue-600 text-white border-blue-600'
                        : 'border-border hover:bg-accent'
                    )}
                  >
                    <span>{m.icon}</span>
                    <span>{m.label}</span>
                  </button>
                ))}
              </div>
            </div>
          </div>

          {/* Meeting URL */}
          {(meetingMode === 'video_call' || meetingMode === 'hybrid') && (
            <div className="space-y-1">
              <Label htmlFor="mtg-url">Meeting link</Label>
              <Input
                id="mtg-url"
                placeholder="https://meet.google.com/..."
                value={meetingUrl}
                onChange={e => setMeetingUrl(e.target.value)}
              />
            </div>
          )}

          {/* Agenda */}
          <div className="space-y-1">
            <Label htmlFor="mtg-agenda">Agenda (optional)</Label>
            <Textarea
              id="mtg-agenda"
              placeholder="Enter the main agenda items"
              rows={3}
              value={agenda}
              onChange={e => setAgenda(e.target.value)}
            />
          </div>

          {error && (
            <p className="text-sm text-destructive">{error}</p>
          )}
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={handleClose} disabled={isPending}>
            Cancel
          </Button>
          <Button
            onClick={handleSubmit}
            disabled={isPending}
            className="bg-blue-600 hover:bg-blue-700 text-white"
          >
            {isPending ? 'Saving...' : 'Create Meeting'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
