'use client'
// src/components/calendar/calendar-event-chip.tsx
import type { CalendarItem } from '@/lib/queries/calendar'
import { cn } from '@/lib/utils'

interface Props {
  item:      CalendarItem
  compact?:  boolean
  onClick?:  () => void
}

// Deterministic color by source/feed (source always wins so Google/URM/To-Do/etc.
// are visually distinct regardless of any stored per-event color).
const CHIP_STYLES: Record<string, string> = {
  event_internal:  'bg-violet-500 text-white',   // URM-created event
  event_google:    'bg-emerald-500 text-white',  // Google
  event_microsoft: 'bg-indigo-500 text-white',   // Microsoft
  meeting:             'bg-blue-600 text-white',
  deal_task:           'bg-orange-500 text-white',
  communication:       'bg-slate-400 text-white',
  todo:                'bg-cyan-600 text-white',
  milestone_next_step: 'bg-amber-500 text-white',
  milestone_close:     'bg-rose-600 text-white',
}

const SOURCE_ICON: Record<string, string> = { google: '🟢', microsoft: '🔵', internal: '🟣' }
const FEED_ICON: Record<string, string> = {
  meeting: '📅', deal_task: '✓', communication: '✉', todo: '📝',
  milestone_next_step: '🎯', milestone_close: '🏁', task: '✓',
}

function isEventLike(item: CalendarItem): boolean {
  return item.feed_source === 'event' || item.type === 'event'
}

function chipClass(item: CalendarItem): string {
  if (isEventLike(item)) {
    return CHIP_STYLES[`event_${item.source ?? 'internal'}`] ?? CHIP_STYLES.event_internal!
  }
  const fs = item.feed_source
  if (fs && CHIP_STYLES[fs]) return CHIP_STYLES[fs]!
  if (item.type === 'task') return CHIP_STYLES.deal_task!
  if (item.type === 'meeting') return CHIP_STYLES.meeting!
  if (item.type === 'communication') return CHIP_STYLES.communication!
  return 'bg-gray-400 text-white'
}

function chipIcon(item: CalendarItem): string {
  if (isEventLike(item)) return SOURCE_ICON[item.source ?? 'internal'] ?? '🟣'
  return FEED_ICON[item.feed_source ?? ''] ?? FEED_ICON[item.type] ?? ''
}

export function CalendarEventChip({ item, compact, onClick }: Props) {
  const icon = chipIcon(item)
  const timeStr = item.is_all_day
    ? null
    : new Date(item.start_at).toLocaleTimeString('ko-KR', { hour: '2-digit', minute: '2-digit', hour12: false })

  return (
    <button
      onClick={onClick}
      className={cn(
        'w-full text-left rounded px-1.5 py-0.5 text-xs font-medium truncate',
        'hover:opacity-90 transition-opacity cursor-pointer',
        chipClass(item),
        compact && 'py-0'
      )}
      title={`${item.title}${item.party_name ? ` · ${item.party_name}` : ''}`}
    >
      <span className="opacity-75 mr-0.5">{icon}</span>
      {!compact && timeStr && (<span className="opacity-80 mr-1">{timeStr}</span>)}
      <span className="truncate">{item.title}</span>
    </button>
  )
}
