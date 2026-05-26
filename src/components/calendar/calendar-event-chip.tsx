'use client'
// src/components/calendar/calendar-event-chip.tsx
import type { CalendarItem } from '@/lib/queries/calendar'
import { cn } from '@/lib/utils'

interface Props {
  item:      CalendarItem
  compact?:  boolean
  onClick?:  () => void
}

// ─────────────────────────────────────────────
// 색상 매핑
// ─────────────────────────────────────────────

const CHIP_STYLES: Record<string, string> = {
  // type
  meeting:       'bg-blue-600 text-white',
  task:          'bg-orange-500 text-white',
  communication: 'bg-slate-400 text-white',
  // event by source
  event_internal:  'bg-violet-500 text-white',
  event_google:    'bg-emerald-500 text-white',
  event_microsoft: 'bg-indigo-500 text-white',
}

// source prefix 아이콘
const SOURCE_ICON: Record<string, string> = {
  google:    '🟢',
  microsoft: '🔵',
  internal:  '🟣',
}

const TYPE_ICON: Record<string, string> = {
  meeting:       '📅',
  task:          '✓',
  communication: '✉',
}

function chipStyle(item: CalendarItem): string {
  if (item.type === 'event') {
    return CHIP_STYLES[`event_${item.source ?? 'internal'}`] ?? CHIP_STYLES.event_internal!!
  }
  return CHIP_STYLES[item.type] ?? 'bg-gray-400 text-white'
}

// ─────────────────────────────────────────────
// Component
// ─────────────────────────────────────────────

export function CalendarEventChip({ item, compact, onClick }: Props) {
  const icon = item.type === 'event'
    ? SOURCE_ICON[item.source ?? 'internal']
    : TYPE_ICON[item.type]

  const timeStr = item.is_all_day
    ? null
    : new Date(item.start_at).toLocaleTimeString('ko-KR', {
        hour:   '2-digit',
        minute: '2-digit',
        hour12: false,
      })

  return (
    <button
      onClick={onClick}
      className={cn(
        'w-full text-left rounded px-1.5 py-0.5 text-xs font-medium truncate',
        'hover:opacity-90 transition-opacity cursor-pointer',
        chipStyle(item),
        compact && 'py-0'
      )}
      title={`${item.title}${item.party_name ? ` · ${item.party_name}` : ''}`}
    >
      <span className="opacity-75 mr-0.5">{icon}</span>
      {!compact && timeStr && (
        <span className="opacity-80 mr-1">{timeStr}</span>
      )}
      <span className="truncate">{item.title}</span>
    </button>
  )
}
