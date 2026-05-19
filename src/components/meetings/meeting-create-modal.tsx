'use client'
// src/components/meetings/meeting-create-modal.tsx
import { useState, useTransition } from 'react'
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
import { MeetingType, MeetingMode } from '@/lib/queries/meetings'
import { cn } from '@/lib/utils'

interface Props {
  open:          boolean
  onClose:       () => void
  defaultDate?:  Date
  defaultPartyId?: string
  defaultPartyName?: string
}

const MEETING_TYPES: { value: MeetingType; label: string }[] = [
  { value: 'discovery',   label: '발굴 미팅' },
  { value: 'demo',        label: '데모' },
  { value: 'proposal',    label: '제안' },
  { value: 'negotiation', label: '협상' },
  { value: 'follow_up',   label: '팔로업' },
  { value: 'check_in',    label: '정기 체크인' },
  { value: 'internal',    label: '사내 미팅' },
  { value: 'other',       label: '기타' },
]

const MEETING_MODES: { value: MeetingMode; label: string; icon: string }[] = [
  { value: 'video_call', label: '화상 통화',  icon: '🎥' },
  { value: 'phone',      label: '전화',       icon: '📞' },
  { value: 'in_person',  label: '대면 미팅',  icon: '🤝' },
  { value: 'hybrid',     label: '하이브리드', icon: '💻' },
]

function todayAt(h: number, m = 0): string {
  const d = new Date()
  d.setHours(h, m, 0, 0)
  return d.toISOString().slice(0, 16)   // "YYYY-MM-DDTHH:MM"
}

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
  const [meetingMode,  setMeetingMode] = useState<MeetingMode>('video_call')
  const [meetingUrl,   setMeetingUrl]  = useState('')
  const [agenda,       setAgenda]      = useState('')

  function reset() {
    setTitle(''); setPartyId(''); setPartySearch('')
    setScheduledAt(defaultDt); setDuration(30)
    setMeetingType('discovery'); setMeetingMode('video_call')
    setMeetingUrl(''); setAgenda(''); setError(null)
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
          scheduled_at:     new Date(scheduledAt).toISOString(),
          duration_minutes: duration,
          meeting_type:     meetingType,
          meeting_mode:     meetingMode,
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
                {MEETING_MODES.map(m => (
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
              placeholder="논의할 주요 안건을 입력하세요"
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
            {isPending ? '저장 중…' : '미팅 생성'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
