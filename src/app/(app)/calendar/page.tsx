// src/app/(app)/calendar/page.tsx
'use client'
import { useState, useEffect, useCallback } from 'react'
import { CalendarView } from '@/components/calendar/calendar-view'
import { MeetingCreateModal } from '@/components/meetings/meeting-create-modal'
import type { CalendarItem } from '@/lib/queries/calendar'
import { 
  fetchCalendarItemsAction as fetchCalendarItems,
  createCalendarEventAction as createCalendarEvent,
} from '@/app/actions/calendar'
import {
  Dialog, DialogContent, DialogHeader, DialogTitle,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input }  from '@/components/ui/input'
import { Label }  from '@/components/ui/label'
import { ExternalLink } from 'lucide-react'
import { useRouter } from 'next/navigation'

// ─────────────────────────────────────────────
// Quick Event Create (non-meeting)
// ─────────────────────────────────────────────

function QuickEventModal({
  open, defaultDate, onClose,
}: {
  open: boolean; defaultDate: Date; onClose: () => void
}) {
  const router = useRouter()
  const [title,    setTitle]   = useState('')
  const [startAt,  setStartAt] = useState('')
  const [endAt,    setEndAt]   = useState('')
  const [saving,   setSaving]  = useState(false)

  useEffect(() => {
    if (open) {
      const d = defaultDate
      const base = `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`
      setTitle('')
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
        start_at: new Date(startAt).toISOString(),
        end_at:   new Date(endAt).toISOString(),
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
          <DialogTitle>빠른 이벤트 추가</DialogTitle>
        </DialogHeader>
        <div className="space-y-3 py-2">
          <div className="space-y-1">
            <Label>제목</Label>
            <Input
              placeholder="이벤트 제목"
              value={title}
              onChange={e => setTitle(e.target.value)}
              onKeyDown={e => e.key === 'Enter' && handleSave()}
              autoFocus
            />
          </div>
          <div className="grid grid-cols-2 gap-2">
            <div className="space-y-1">
              <Label>시작</Label>
              <Input type="datetime-local" value={startAt} onChange={e => setStartAt(e.target.value)} />
            </div>
            <div className="space-y-1">
              <Label>종료</Label>
              <Input type="datetime-local" value={endAt} onChange={e => setEndAt(e.target.value)} />
            </div>
          </div>
        </div>
        <div className="flex justify-between gap-2 pt-1">
          <Button variant="outline" size="sm" onClick={onClose}>취소</Button>
          <Button
            size="sm"
            className="bg-blue-600 hover:bg-blue-700 text-white"
            onClick={handleSave}
            disabled={saving || !title.trim()}
          >
            {saving ? '저장 중…' : '저장'}
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  )
}

// ─────────────────────────────────────────────
// Item Detail Popup
// ─────────────────────────────────────────────

function ItemDetailPopup({
  item, onClose,
}: { item: CalendarItem | null; onClose: () => void }) {
  if (!item) return null

  const typeLabel: Record<string, string> = {
    meeting: '미팅', event: '이벤트', task: '할일', communication: '커뮤니케이션',
  }

  return (
    <Dialog open={!!item} onOpenChange={v => !v && onClose()}>
      <DialogContent className="max-w-sm">
        <DialogHeader>
          <DialogTitle className="text-base">{item.title}</DialogTitle>
        </DialogHeader>
        <div className="space-y-2 text-sm">
          <div className="text-muted-foreground">
            {typeLabel[item.type]}
            {item.source && ` · ${item.source}`}
          </div>
          <div>
            {new Date(item.start_at).toLocaleString('ko-KR')}
            {!item.is_all_day && ` – ${new Date(item.end_at).toLocaleTimeString('ko-KR', { hour: '2-digit', minute: '2-digit' })}`}
          </div>
          {item.party_name && (
            <div className="text-muted-foreground">Party: {item.party_name}</div>
          )}
          {item.location && (
            <div className="text-muted-foreground">📍 {item.location}</div>
          )}
          {item.meeting_url && (
            <a
              href={item.meeting_url}
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center gap-1 text-blue-600 hover:underline"
            >
              <ExternalLink className="w-3.5 h-3.5" />
              미팅 링크
            </a>
          )}
        </div>
        <div className="flex justify-end gap-2 pt-2">
          {item.type === 'meeting' && (
            <Button variant="outline" size="sm" asChild>
              <a href={`/meetings/${item.id}`}>상세 보기</a>
            </Button>
          )}
          <Button variant="outline" size="sm" onClick={onClose}>닫기</Button>
        </div>
      </DialogContent>
    </Dialog>
  )
}

// ─────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────

export default function CalendarPage() {
  const [items,       setItems]       = useState<CalendarItem[]>([])
  const [loading,     setLoading]     = useState(true)
  const [createDate,  setCreateDate]  = useState<Date | null>(null)
  const [createMode,  setCreateMode]  = useState<'event' | 'meeting'>('event')
  const [detailItem,  setDetailItem]  = useState<CalendarItem | null>(null)

  // Initial load — current month
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
        <h1 className="text-lg font-semibold">캘린더</h1>
        <div className="flex gap-2">
          <Button
            variant="outline" size="sm"
            onClick={() => { setCreateDate(new Date()); setCreateMode('meeting') }}
          >
            + 미팅
          </Button>
          <Button
            size="sm"
            className="bg-blue-600 hover:bg-blue-700 text-white"
            onClick={() => { setCreateDate(new Date()); setCreateMode('event') }}
          >
            + 이벤트
          </Button>
        </div>
      </div>

      {loading ? (
        <div className="flex-1 flex items-center justify-center text-muted-foreground text-sm">
          불러오는 중…
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
      />
    </div>
  )
}
