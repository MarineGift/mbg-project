'use client'
// src/components/calendar/calendar-view.tsx
import { useState, useMemo, useTransition } from 'react'
import type { CalendarItem } from '@/lib/queries/calendar'
import { CalendarEventChip } from './calendar-event-chip'
import { CALENDAR_FEED_META, CALENDAR_FEED_SOURCES } from '@/lib/queries/calendar-meta'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { ChevronLeft, ChevronRight, RefreshCw, Plus } from 'lucide-react'
import { cn } from '@/lib/utils'
import { triggerCalendarSync } from '@/app/actions/calendar-sync'
import { useRouter } from 'next/navigation'

type ViewMode = 'month' | 'week' | 'day'

interface Props {
  items:             CalendarItem[]
  onCreateEvent?:    (date: Date) => void
  onItemClick?:      (item: CalendarItem) => void
  onRangeChange?:    (start: Date, end: Date) => void
}

const WEEKDAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
const MAX_CHIPS_PER_DAY = 3
const MAX_WEEK_ALLDAY = 4

// CRM-internal item types that are hidden by default (toggle to show)
const CRM_TYPES: ReadonlyArray<CalendarItem['type']> = ['task', 'communication']

function isCrmItem(item: CalendarItem): boolean {
  return CRM_TYPES.includes(item.type)
}

// ─────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────

function startOfDay(d: Date) {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate())
}

function isSameDay(a: Date, b: Date) {
  return a.getFullYear() === b.getFullYear()
      && a.getMonth()    === b.getMonth()
      && a.getDate()     === b.getDate()
}

// Canonical feed-source priority (legend order): event, meeting, deal_task,
// communication, todo, milestone_next_step, milestone_close. Used to order the
// capped chips in a day cell so important items (events/meetings) surface first
// instead of being buried under all-day milestones that sort earlier by time.
const FEED_RANK: Record<string, number> = Object.fromEntries(
  CALENDAR_FEED_SOURCES.map((s, i) => [s, i]),
)
function feedRank(item: CalendarItem): number {
  const r = FEED_RANK[item.feed_source ?? 'event']
  return r === undefined ? 99 : r
}
function compareByFeedThenTime(a: CalendarItem, b: CalendarItem): number {
  const fr = feedRank(a) - feedRank(b)
  if (fr !== 0) return fr
  return new Date(a.start_at).getTime() - new Date(b.start_at).getTime()
}

function itemsForDay(items: CalendarItem[], day: Date): CalendarItem[] {
  return items
    .filter(item => {
      const s = startOfDay(new Date(item.start_at))
      return isSameDay(s, day)
    })
    .sort(compareByFeedThenTime)
}

// ─────────────────────────────────────────────
// Month View
// ─────────────────────────────────────────────

function MonthGrid({
  year, month, items, today,
  onDayClick, onItemClick,
}: {
  year: number; month: number
  items: CalendarItem[]
  today: Date
  onDayClick: (d: Date) => void
  onItemClick: (item: CalendarItem) => void
}) {
  // Build 6-week grid
  const firstDay  = new Date(year, month, 1)
  const startDay  = new Date(firstDay)
  startDay.setDate(startDay.getDate() - firstDay.getDay())  // Sunday

  const days: Date[] = []
  for (let i = 0; i < 42; i++) {
    const d = new Date(startDay)
    d.setDate(d.getDate() + i)
    days.push(d)
  }

  return (
    <div className="flex-1 grid grid-cols-7 border-l border-t border-border overflow-auto">
      {/* Headers */}
      {WEEKDAYS.map(d => (
        <div
          key={d}
          className={cn(
            'border-r border-b border-border py-1 text-center text-xs font-medium text-muted-foreground',
            d === 'Sun' && 'text-red-500',
            d === 'Sat' && 'text-blue-500',
          )}
        >
          {d}
        </div>
      ))}

      {/* Day cells */}
      {days.map((day, idx) => {
        const isToday      = isSameDay(day, today)
        const isOtherMonth = day.getMonth() !== month
        const dayItems     = itemsForDay(items, day)
        const overflow     = dayItems.length - MAX_CHIPS_PER_DAY

        return (
          <div
            key={idx}
            onClick={() => onDayClick(day)}
            className={cn(
              'border-r border-b border-border p-1 min-h-[80px] cursor-pointer',
              'hover:bg-accent/30 transition-colors group',
              isOtherMonth && 'bg-muted/30',
            )}
          >
            <div className="flex items-center justify-between mb-0.5">
              <span
                className={cn(
                  'text-xs font-medium w-5 h-5 flex items-center justify-center rounded-full',
                  isToday && 'bg-blue-600 text-white',
                  !isToday && isOtherMonth && 'text-muted-foreground',
                  !isToday && !isOtherMonth && day.getDay() === 0 && 'text-red-500',
                  !isToday && !isOtherMonth && day.getDay() === 6 && 'text-blue-500',
                )}
              >
                {day.getDate()}
              </span>
              <Plus className="w-3 h-3 text-muted-foreground opacity-0 group-hover:opacity-100" />
            </div>
            <div className="space-y-0.5">
              {dayItems.slice(0, MAX_CHIPS_PER_DAY).map(item => (
                <CalendarEventChip
                  key={item.id}
                  item={item}
                  compact
                  onClick={((e: any) => { (e as any).stopPropagation?.(); onItemClick(item) }) as never}
                />
              ))}
              {overflow > 0 && (
                <div className="text-xs text-muted-foreground pl-1">
                  +{overflow} more
                </div>
              )}
            </div>
          </div>
        )
      })}
    </div>
  )
}

// ─────────────────────────────────────────────
// Week View
// ─────────────────────────────────────────────

const HOURS = Array.from({ length: 24 }, (_, i) => i)

function WeekGrid({
  weekStart, items, today,
  onSlotClick, onItemClick, onDayClick,
}: {
  weekStart: Date
  items: CalendarItem[]
  today: Date
  onSlotClick: (d: Date) => void
  onItemClick: (item: CalendarItem) => void
  onDayClick: (d: Date) => void
}) {
  const days: Date[] = []
  for (let i = 0; i < 7; i++) {
    const d = new Date(weekStart)
    d.setDate(d.getDate() + i)
    days.push(d)
  }

  const allDayItems  = items.filter(i => i.is_all_day)
  const timedItems   = items.filter(i => !i.is_all_day)

  function timedForDay(day: Date) {
    return timedItems.filter(i => isSameDay(new Date(i.start_at), day))
  }

  function topPercent(isoTime: string): number {
    const d = new Date(isoTime)
    return ((d.getHours() * 60 + d.getMinutes()) / (24 * 60)) * 100
  }

  function heightPercent(start: string, end: string): number {
    const diff = new Date(end).getTime() - new Date(start).getTime()
    const mins = diff / 60_000
    return Math.max((mins / (24 * 60)) * 100, 1.5)
  }

  return (
    <div className="flex-1 flex flex-col overflow-hidden">
      {/* Day header (weekday + date) */}
      <div className="grid grid-cols-[48px_repeat(7,1fr)] border-b border-border">
        <div />
        {days.map((day, i) => {
          const dh = isSameDay(day, today)
          return (
            <div
              key={i}
              onClick={() => onDayClick(day)}
              className="cursor-pointer border-l border-border px-1 py-1 text-center hover:bg-muted/50"
            >
              <div className={cn(
                'text-[11px] uppercase',
                day.getDay() === 0 ? 'text-red-500'
                  : day.getDay() === 6 ? 'text-blue-500'
                  : 'text-muted-foreground',
              )}>
                {WEEKDAYS[day.getDay()]}
              </div>
              <div className={cn(
                'mx-auto mt-0.5 flex h-6 w-6 items-center justify-center rounded-full text-sm',
                dh ? 'bg-blue-600 text-white font-semibold' : 'text-foreground',
              )}>
                {day.getDate()}
              </div>
            </div>
          )
        })}
      </div>

      {/* All-day row */}
      <div className="grid grid-cols-[48px_repeat(7,1fr)] border-b border-border">
        <div className="text-xs text-muted-foreground p-1 pt-2">All day</div>
        {days.map((day, i) => {
          const dayAll = allDayItems
            .filter(item => isSameDay(new Date(item.start_at), day))
            .sort(compareByFeedThenTime)
          const shown  = dayAll.slice(0, MAX_WEEK_ALLDAY)
          const extra  = dayAll.length - shown.length
          return (
            <div key={i} className="border-l border-border min-h-[28px] p-0.5 space-y-0.5">
              {shown.map(item => (
                <CalendarEventChip key={item.id} item={item} compact onClick={() => onItemClick(item)} />
              ))}
              {extra > 0 && (
                <button
                  type="button"
                  onClick={() => onDayClick(day)}
                  className="w-full rounded px-1 py-0.5 text-left text-[11px] text-muted-foreground hover:bg-muted"
                >
                  +{extra} more
                </button>
              )}
            </div>
          )
        })}
      </div>

      {/* Timed grid */}
      <div className="flex-1 overflow-y-auto">
        <div className="grid grid-cols-[48px_repeat(7,1fr)] relative" style={{ height: '1440px' }}>
          {/* Hour labels */}
          <div className="relative">
            {HOURS.map(h => (
              <div
                key={h}
                className="absolute w-full text-right pr-1 text-xs text-muted-foreground"
                style={{ top: `${(h / 24) * 100}%` }}
              >
                {h === 0 ? '' : `${h}:00`}
              </div>
            ))}
          </div>

          {/* Day columns */}
          {days.map((day, di) => (
            <div
              key={di}
              className={cn(
                'border-l border-border relative',
                isSameDay(day, today) && 'bg-blue-50/30 dark:bg-blue-900/10'
              )}
              onClick={() => onSlotClick(day)}
            >
              {/* Hour grid lines */}
              {HOURS.map(h => (
                <div
                  key={h}
                  className="absolute w-full border-t border-border/40"
                  style={{ top: `${(h / 24) * 100}%` }}
                />
              ))}

              {/* Events */}
              {timedForDay(day).map(item => (
                <div
                  key={item.id}
                  className="absolute left-0.5 right-0.5 z-10"
                  style={{
                    top:    `${topPercent(item.start_at)}%`,
                    height: `${heightPercent(item.start_at, item.end_at)}%`,
                  }}
                  onClick={e => { e.stopPropagation(); onItemClick(item) }}
                >
                  <CalendarEventChip item={item} />
                </div>
              ))}
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

// ─────────────────────────────────────────────
// Main CalendarView
// ─────────────────────────────────────────────

export function CalendarView({ items, onCreateEvent, onItemClick, onRangeChange }: Props) {
  const today  = useMemo(() => startOfDay(new Date()), [])
  const router = useRouter()
  const [isPending, startTransition] = useTransition()

  const [view,  setView]  = useState<ViewMode>('month')
  const [dayModal, setDayModal] = useState<Date | null>(null)
  const [pivot, setPivot] = useState(startOfDay(new Date()))   // current month/week anchor
  const [showCrm, setShowCrm] = useState(false)                // tasks + communications hidden by default

  // ── Filtered items (hide CRM items unless toggled) ──
  const visibleItems = useMemo(
    () => (showCrm ? items : items.filter(i => !isCrmItem(i))),
    [items, showCrm],
  )

  const crmCount = useMemo(
    () => items.filter(isCrmItem).length,
    [items],
  )

  // ── Navigation ──────────────────────────
  function navigate(dir: 1 | -1) {
    setPivot(prev => {
      const d = new Date(prev)
      if (view === 'month') {
        d.setMonth(d.getMonth() + dir)
      } else if (view === 'week') {
        d.setDate(d.getDate() + dir * 7)
      } else {
        d.setDate(d.getDate() + dir)
      }
      return d
    })
  }

  // ── Title ────────────────────────────────
  const title = useMemo(() => {
    if (view === 'month') {
      return pivot.toLocaleDateString('ko-KR', { year: 'numeric', month: 'long' })
    }
    if (view === 'day') {
      return pivot.toLocaleDateString('ko-KR', { month: 'long', day: 'numeric', weekday: 'short' })
    }
    const weekEnd = new Date(pivot)
    weekEnd.setDate(weekEnd.getDate() + 6)
    return `${pivot.toLocaleDateString('ko-KR', { month: 'short', day: 'numeric' })} – ${weekEnd.toLocaleDateString('ko-KR', { month: 'short', day: 'numeric' })}`
  }, [view, pivot])

  // ── Week start (Sunday of pivot week) ────
  const weekStart = useMemo(() => {
    const d = new Date(pivot)
    d.setDate(d.getDate() - d.getDay())
    return d
  }, [pivot])

  // ── Sync button ──────────────────────────
  function handleSync() {
    startTransition(async () => {
      await triggerCalendarSync()
      router.refresh()
    })
  }

  return (
    <div className="flex flex-col h-full select-none">
      {/* ── Toolbar ── */}
      <div className="flex items-center gap-2 px-4 py-2 border-b border-border shrink-0">
        <Button
          variant="outline" size="sm"
          onClick={() => setPivot(startOfDay(new Date()))}
        >
          Today
        </Button>

        <div className="flex items-center">
          <Button variant="ghost" size="icon" className="h-7 w-7" onClick={() => navigate(-1)}>
            <ChevronLeft className="h-4 w-4" />
          </Button>
          <span className="text-sm font-semibold w-44 text-center">{title}</span>
          <Button variant="ghost" size="icon" className="h-7 w-7" onClick={() => navigate(1)}>
            <ChevronRight className="h-4 w-4" />
          </Button>
        </div>

        <div className="ml-auto flex items-center gap-2">
          {/* Tasks / Communications toggle */}
          <label className="flex items-center gap-1.5 text-xs text-muted-foreground cursor-pointer select-none">
            <input
              type="checkbox"
              className="h-3.5 w-3.5 rounded border-border accent-blue-600"
              checked={showCrm}
              onChange={e => setShowCrm(e.target.checked)}
            />
            Tasks &amp; logs
            {crmCount > 0 && (
              <span className="text-muted-foreground/70">({crmCount})</span>
            )}
          </label>

          {/* Sync */}
          <Button
            variant="outline" size="sm"
            onClick={handleSync}
            disabled={isPending}
            className="gap-1"
          >
            <RefreshCw className={cn('h-3.5 w-3.5', isPending && 'animate-spin')} />
            {isPending ? 'Syncing...' : 'Sync'}
          </Button>

          {/* View toggle */}
          <div className="flex rounded-md border border-border overflow-hidden">
            {(['month', 'week', 'day'] as ViewMode[]).map(v => (
              <button
                key={v}
                onClick={() => setView(v)}
                className={cn(
                  'px-3 py-1 text-xs font-medium transition-colors',
                  view === v
                    ? 'bg-foreground text-background'
                    : 'bg-background text-muted-foreground hover:bg-accent'
                )}
              >
                {v === 'month' ? 'Month' : v === 'week' ? 'Week' : 'Day'}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* ── Grid ── */}
      {view === 'month' ? (
        <MonthGrid
          year={pivot.getFullYear()}
          month={pivot.getMonth()}
          items={visibleItems}
          today={today}
          onDayClick={d => setDayModal(d)}
          onItemClick={item => onItemClick?.(item)}
        />
      ) : view === 'week' ? (
        <WeekGrid
          weekStart={weekStart}
          items={visibleItems}
          today={today}
          onSlotClick={d => onCreateEvent?.(d)}
          onItemClick={item => onItemClick?.(item)}
          onDayClick={d => setDayModal(d)}
        />
      ) : (
        <DayBoard
          date={pivot}
          items={visibleItems}
          onItemClick={item => onItemClick?.(item)}
          onCreateEvent={d => onCreateEvent?.(d)}
        />
      )}

      {dayModal && (
        <DayEventsModal
          date={dayModal}
          items={itemsForDay(visibleItems, dayModal)}
          onClose={() => setDayModal(null)}
          onItemClick={item => { setDayModal(null); onItemClick?.(item) }}
          onCreateEvent={d => { setDayModal(null); onCreateEvent?.(d) }}
        />
      )}
    </div>
  )
}


/**
 * DayBoard - single-day kanban: all 7 feed sources as columns (canonical order),
 * shown for `date`. Changes as the date navigates. Desktop fits all columns;
 * mobile scroll-snaps one column at a time. Chips link via onItemClick.
 */
function DayBoard({
  date,
  items,
  onItemClick,
  onCreateEvent,
}: {
  date: Date
  items: CalendarItem[]
  onItemClick: (item: CalendarItem) => void
  onCreateEvent: (date: Date) => void
}) {
  const dayItems = itemsForDay(items, date)   // already feed-rank + time sorted
  const columns = CALENDAR_FEED_SOURCES.map((src) => ({
    src,
    meta: CALENDAR_FEED_META[src],
    list: dayItems.filter((it) => (it.feed_source ?? 'event') === src),
  }))
  const dateLabel = date.toLocaleDateString('ko-KR', {
    year: 'numeric', month: 'long', day: 'numeric', weekday: 'long',
  })
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <div className="flex shrink-0 items-center gap-2 border-b border-border px-4 py-2">
        <span className="text-sm font-medium">{dateLabel}</span>
        <span className="text-xs text-muted-foreground">{dayItems.length} items</span>
        <button
          type="button"
          onClick={() => onCreateEvent(date)}
          className="ml-auto rounded-md border px-2 py-1 text-xs hover:bg-muted"
        >
          + Add on this day
        </button>
      </div>
      <div className="flex min-h-0 flex-1 gap-3 overflow-x-auto snap-x snap-mandatory p-3 md:snap-none md:overflow-x-hidden">
        {columns.map((col) => (
          <section
            key={col.src}
            className="flex shrink-0 basis-[88vw] snap-start flex-col rounded-lg border bg-card md:min-h-0 md:min-w-0 md:shrink md:basis-0 md:flex-1"
          >
            <header className="flex shrink-0 items-center gap-2 border-b px-3 py-2">
              <span
                className="inline-block h-2.5 w-2.5 shrink-0 rounded-full"
                style={{ backgroundColor: col.meta.color }}
              />
              <span className="truncate text-sm font-semibold">{col.meta.label}</span>
              <span className="ml-auto shrink-0 text-xs text-muted-foreground">{col.list.length}</span>
            </header>
            <div className="flex min-h-0 flex-1 flex-col gap-1 overflow-y-auto p-2">
              {col.list.length === 0 ? (
                <p className="px-1 py-4 text-center text-xs text-muted-foreground">—</p>
              ) : (
                col.list.map((item) => (
                  <CalendarEventChip
                    key={item.id}
                    item={item}
                    onClick={(() => onItemClick(item)) as never}
                  />
                ))
              )}
            </div>
          </section>
        ))}
      </div>
    </div>
  )
}


/**
 * DayEventsModal - full list of items for a single day.
 * Opened when a calendar day cell is clicked (overflow beyond MAX_CHIPS_PER_DAY).
 */
function DayEventsModal({
  date,
  items,
  onClose,
  onItemClick,
  onCreateEvent,
}: {
  date: Date
  items: CalendarItem[]
  onClose: () => void
  onItemClick: (item: CalendarItem) => void
  onCreateEvent: (date: Date) => void
}) {
  const sorted = [...items].sort(
    (a, b) => new Date(a.start_at).getTime() - new Date(b.start_at).getTime(),
  )
  const dateLabel = date.toLocaleDateString('ko-KR', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    weekday: 'long',
  })
  // Group by feed source, in the canonical legend order.
  const groups = CALENDAR_FEED_SOURCES
    .map((src) => ({
      src,
      meta: CALENDAR_FEED_META[src],
      list: sorted.filter((it) => (it.feed_source ?? 'event') === src),
    }))
    .filter((g) => g.list.length > 0)
  return (
    <Dialog open onOpenChange={v => !v && onClose()}>
      <DialogContent className="max-w-3xl">
        <DialogHeader>
          <DialogTitle>{dateLabel}</DialogTitle>
        </DialogHeader>
        <div className="flex items-center gap-2 pb-1">
          <button
            type="button"
            onClick={() => onCreateEvent(date)}
            className="rounded-md border px-2 py-1 text-xs hover:bg-muted"
          >
            + Add on this day
          </button>
          <span className="ml-auto text-xs text-muted-foreground">
            {sorted.length} items
          </span>
        </div>
        <div className="max-h-[68vh] space-y-4 overflow-y-auto pr-1">
          {groups.length === 0 ? (
            <p className="py-6 text-center text-sm text-muted-foreground">
              No items on this day.
            </p>
          ) : (
            groups.map((g) => (
              <div key={g.src} className="space-y-1">
                <div className="sticky top-0 z-10 flex items-center gap-2 bg-background py-1">
                  <span
                    className="inline-block h-2.5 w-2.5 rounded-full"
                    style={{ backgroundColor: g.meta.color }}
                  />
                  <span className="text-sm font-semibold">{g.meta.label}</span>
                  <span className="text-xs text-muted-foreground">{g.list.length}</span>
                </div>
                <div className="grid grid-cols-1 gap-1 sm:grid-cols-2">
                  {g.list.map((item) => (
                    <CalendarEventChip
                      key={item.id}
                      item={item}
                      onClick={(() => onItemClick(item)) as never}
                    />
                  ))}
                </div>
              </div>
            ))
          )}
        </div>
      </DialogContent>
    </Dialog>
  )
}
