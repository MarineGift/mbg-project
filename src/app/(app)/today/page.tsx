// src/app/(app)/today/page.tsx
// todo_v2 Phase 1 (2) - Today cockpit. Three lanes (Overdue / This Week /
// Waiting For) over the dedicated getTodayCockpit read-model.
import Link from 'next/link'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { AlertTriangle, CalendarRange, Hourglass } from 'lucide-react'
import { cn } from '@/lib/utils'
import { getTodayCockpit, type CockpitItem, type CockpitSource } from '@/lib/queries/today'

export const dynamic = 'force-dynamic'

const SOURCE_META: Record<CockpitSource, { label: string; dot: string }> = {
  todo:      { label: 'To-Do',     dot: 'bg-emerald-500' },
  deal_task: { label: 'Deal task', dot: 'bg-sky-500' },
  milestone: { label: 'Next step', dot: 'bg-amber-500' },
}

// Canonical cross-app ordering (same as the calendar legend):
// event -> meeting -> deal_task -> communication -> todo -> next_step -> close.
// The Today read-model currently emits only todo / deal_task / milestone(next_step),
// but the full map is kept so ordering stays correct if more sources are added.
const SOURCE_RANK: Record<string, number> = {
  event: 0, meeting: 1, deal_task: 2, communication: 3,
  todo: 4, milestone: 5, milestone_next_step: 5, milestone_close: 6,
}
function rankOf(it: CockpitItem): number {
  const r = SOURCE_RANK[it.source]
  return r === undefined ? 99 : r
}
// Order by source priority, then by due date (nulls last) within each source.
function orderItems(items: CockpitItem[]): CockpitItem[] {
  return [...items].sort((a, b) => {
    const r = rankOf(a) - rankOf(b)
    if (r !== 0) return r
    return (a.due ?? '9999-12-31').localeCompare(b.due ?? '9999-12-31')
  })
}

function fmtDue(due: string | null): string {
  if (!due) return ''
  return new Date(`${due}T00:00:00`).toLocaleDateString(undefined, { month: 'short', day: 'numeric' })
}

function ItemRow({ item }: { item: CockpitItem }) {
  const meta = SOURCE_META[item.source]
  return (
    <Link
      href={item.href}
      className="-mx-2 flex items-start gap-2 rounded-md px-2 py-2 transition-colors hover:bg-muted"
    >
      <span className={cn('mt-1.5 h-2 w-2 shrink-0 rounded-full', meta.dot)} aria-hidden />
      <span className="min-w-0 flex-1">
        <span className="block truncate text-sm text-foreground">{item.title}</span>
        {item.context && (
          <span className="block truncate text-xs text-muted-foreground">{item.context}</span>
        )}
      </span>
      {item.due && (
        <span className="shrink-0 text-xs tabular-nums text-muted-foreground">{fmtDue(item.due)}</span>
      )}
    </Link>
  )
}

function Lane(props: {
  title: string
  icon: typeof AlertTriangle
  accent?: boolean
  items: CockpitItem[]
  total: number
  emptyText: string
}) {
  const { title, icon: Icon, accent, items, total, emptyText } = props
  const hot = !!accent && total > 0
  const more = total - items.length
  const ordered = orderItems(items)
  return (
    <Card className={cn('flex flex-col md:min-h-0', hot && 'border-destructive/40')}>
      <CardHeader className="shrink-0 pb-3">
        <CardTitle className="flex items-center gap-2 text-base">
          <Icon className={cn('h-4 w-4', accent ? 'text-destructive' : 'text-muted-foreground')} />
          <span>{title}</span>
          <Badge variant={hot ? 'destructive' : 'secondary'} className="ml-auto">
            {total}
          </Badge>
        </CardTitle>
      </CardHeader>
      <CardContent className="max-h-[70vh] overflow-y-auto pt-0 md:max-h-none md:min-h-0 md:flex-1">
        {ordered.length === 0 ? (
          <p className="py-6 text-center text-sm text-muted-foreground">{emptyText}</p>
        ) : (
          <div className="flex flex-col divide-y divide-border">
            {ordered.map((it) => (
              <ItemRow key={`${it.source}:${it.id}`} item={it} />
            ))}
          </div>
        )}
        {more > 0 && (
          <p className="pt-2 text-xs text-muted-foreground">+{more} more</p>
        )}
      </CardContent>
    </Card>
  )
}

export default async function TodayPage() {
  const cockpit = await getTodayCockpit()
  const todayLabel = new Date(`${cockpit.today}T00:00:00`).toLocaleDateString(undefined, {
    weekday: 'long', month: 'long', day: 'numeric',
  })

  return (
    <div className="flex w-full flex-col gap-6 p-4 md:h-[calc(100vh-64px)] md:overflow-hidden md:p-6">
      <header className="flex shrink-0 flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="text-2xl font-semibold tracking-tight text-foreground">Today</h1>
          <p className="text-sm text-muted-foreground">{todayLabel}</p>
        </div>
        <div className="flex items-center gap-3 text-xs text-muted-foreground">
          {(Object.keys(SOURCE_META) as CockpitSource[]).map((s) => (
            <span key={s} className="flex items-center gap-1.5">
              <span className={cn('h-2 w-2 rounded-full', SOURCE_META[s].dot)} aria-hidden />
              {SOURCE_META[s].label}
            </span>
          ))}
        </div>
      </header>

      <div className="grid gap-4 md:min-h-0 md:flex-1 md:grid-cols-3">
        <Lane title="Overdue" icon={AlertTriangle} accent items={cockpit.overdue} total={cockpit.counts.overdue}
          emptyText="Nothing overdue. Nice." />
        <Lane title="This Week" icon={CalendarRange} items={cockpit.thisWeek} total={cockpit.counts.thisWeek}
          emptyText="No deadlines in the next 7 days." />
        <Lane title="Waiting For" icon={Hourglass} items={cockpit.waitingFor} total={cockpit.counts.waitingFor}
          emptyText="Nothing blocked or waiting." />
      </div>
    </div>
  )
}
