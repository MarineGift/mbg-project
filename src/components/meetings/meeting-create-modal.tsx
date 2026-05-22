'use client'
// src/components/meetings/meeting-create-modal.tsx
//
// Stage 26 (2026-05-21):
// party → engagement → stage cascading selector.
// - engagement_id, stage_id 둘 다 optional (DB 도 nullable)
// - active engagement (open / in_progress / on_hold) 만 노출
// - terminal stage (won / lost) 는 visual marker
// - 의존: src/lib/actions/meeting-form.ts (server action wrapper)
//
// 기존 Stage 24 의 channel + meetings.ts API 위에 cascading 만 얹는 형태.

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
import { createMeeting } from '@/lib/queries/meetings'
import { MeetingType, MeetingChannel } from '@/lib/queries/meetings'
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
  { value: 'discovery',   label: '발견 미팅' },
  { value: 'demo',        label: '데모' },
  { value: 'proposal',    label: '제안' },
  { value: 'negotiation', label: '협상' },
  { value: 'follow_up',   label: '팔로업' },
  { value: 'check_in',    label: '정기 체크인' },
  { value: 'internal',    label: '사내 미팅' },
  { value: 'other',       label: '기타' },
]

const MEETING_CHANNELS: { value: MeetingChannel; label: string; icon: string }[] = [
  { value: 'video_call', label: '영상 통화', icon: '🎥' },
  { value: 'phone_call', label: '전화',     icon: '📞' },
  { value: 'in_person',  label: '대면 미팅', icon: '🏢' },
  { value: 'hybrid',     label: '하이브리드', icon: '🔀' },
]

// engagement filter — modal 에는 active 상태만 (won/lost/archived 숨김)
const ACTIVE_ENGAGEMENT_STATUSES = new Set(['open', 'in_progress', 'on_hold'])

function todayAt(h: number, m = 0): string {
  const d = new Date()
  d.setHours(h, m, 0, 0)
  return d.toISOString().slice(0, 16)   // "YYYY-MM-DDTHH:MM"
}

// Select 의 "선택 안 함" 의 sentinel value (Radix Select 는 empty string 불가)
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

  // Effect 1: partyId 변경 → engagement 후보 로드 (cascading 리셋)
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
        // active engagement 만 노출
        setEngagements(cards.filter(c => ACTIVE_ENGAGEMENT_STATUSES.has(c.status)))
      })
      .catch(() => { if (!cancelled) setEngagements([]) })
      .finally(() => { if (!cancelled) setLoadingEngagements(false) })

    return () => { cancelled = true }
  }, [partyId])

  // Effect 2: engagementId 변경 → engagement 의 pipeline stage 로드
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
        // engagement 의 current stage 가 있으면 preselect
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
    if (!title.trim()) { setError('제목을 입력해주세요'); return }
    if (!partyId)      { setError('Party를 선택해주세요 (필수)'); return }

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
          <DialogTitle>새 미팅</DialogTitle>
        </DialogHeader>

        <div className="space-y-4 py-2">
          {/* Title */}
          <div className="space-y-1">
            <Label htmlFor="mtg-title">미팅 제목 *</Label>
            <Input
              id="mtg-title"
              placeholder="예: ABC Corp 제안 미팅"
              value={title}
              onChange={e => setTitle(e.target.value)}
            />
          </div>

          {/* Party — 간단한 텍스트 입력 (실제로는 Party 검색 컴포넌트로 교체) */}
          <div className="space-y-1">
            <Label htmlFor="mtg-party">Party *</Label>
            <Input
              id="mtg-party"
              placeholder="Party ID 입력 (Party 검색 UI 연동 필요)"
              value={partyId}
              onChange={e => setPartyId(e.target.value)}
            />
            <p className="text-xs text-muted-foreground">
              TODO: PartySearchCombobox로 교체
            </p>
          </div>

          {/* Stage 26 — Engagement (optional, partyId 선택 후 노출) */}
          {partyId && (
            <div className="space-y-1">
              <Label htmlFor="mtg-engagement">관련 Engagement (선택)</Label>
              {loadingEngagements ? (
                <p className="text-xs text-muted-foreground">불러오는 중...</p>
              ) : engagements.length === 0 ? (
                <p className="text-xs text-muted-foreground">
                  진행 중인 engagement 없음 (engagement 없이도 미팅 등록 가능)
                </p>
              ) : (
                <Select
                  value={engagementId ?? NONE}
                  onValueChange={v => setEngagementId(v === NONE ? null : v)}
                >
                  <SelectTrigger id="mtg-engagement">
                    <SelectValue placeholder="engagement 선택" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value={NONE}>— 연결 안 함 —</SelectItem>
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

          {/* Stage 26 — Stage (optional, engagementId 선택 후 노출) */}
          {engagementId && (
            <div className="space-y-1">
              <Label htmlFor="mtg-stage">단계 (선택)</Label>
              {loadingStages ? (
                <p className="text-xs text-muted-foreground">불러오는 중...</p>
              ) : stages.length === 0 ? (
                <p className="text-xs text-muted-foreground">
                  pipeline stage 없음
                </p>
              ) : (
                <Select
                  value={stageId ?? NONE}
                  onValueChange={v => setStageId(v === NONE ? null : v)}
                >
                  <SelectTrigger id="mtg-stage">
                    <SelectValue placeholder="단계 선택" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value={NONE}>— 미지정 —</SelectItem>
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
              <Label htmlFor="mtg-dt">일시 *</Label>
              <Input
                id="mtg-dt"
                type="datetime-local"
                value={scheduledAt}
                onChange={e => setScheduledAt(e.target.value)}
              />
            </div>
            <div className="space-y-1">
              <Label htmlFor="mtg-dur">소요 시간(분)</Label>
              <Select
                value={String(duration)}
                onValueChange={v => setDuration(Number(v))}
              >
                <SelectTrigger id="mtg-dur">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {[15, 30, 45, 60, 90, 120].map(d => (
                    <SelectItem key={d} value={String(d)}>{d}분</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          {/* Meeting Type + Mode */}
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1">
              <Label>미팅 유형</Label>
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
              <Label>미팅 방식</Label>
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
              <Label htmlFor="mtg-url">회의 링크</Label>
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
            <Label htmlFor="mtg-agenda">안건 (선택)</Label>
            <Textarea
              id="mtg-agenda"
              placeholder="회의의 주요 안건을 입력하세요"
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
            취소
          </Button>
          <Button
            onClick={handleSubmit}
            disabled={isPending}
            className="bg-blue-600 hover:bg-blue-700 text-white"
          >
            {isPending ? '저장 중...' : '미팅 생성'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
