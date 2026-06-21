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
  emptyText: string
}) {
  const { title, icon: Icon, accent, items, emptyText } = props
  const hot = !!accent && items.length > 0
  return (
    <Card className={cn(hot && 'border-destructive/40')}>
      <CardHeader className="pb-3">
        <CardTitle className="flex items-center gap-2 text-base">
          <Icon className={cn('h-4 w-4', accent ? 'text-destructive' : 'text-muted-foreground')} />
          <span>{title}</span>
          <Badge variant={hot ? 'destructive' : 'secondary'} className="ml-auto">
            {items.length}
          </Badge>
        </CardTitle>
      </CardHeader>
      <CardContent className="pt-0">
        {items.length === 0 ? (
          <p className="py-6 text-center text-sm text-muted-foreground">{emptyText}</p>
        ) : (
          <div className="flex flex-col divide-y divide-border">
            {items.map((it) => (
              <ItemRow key={`${it.source}:${it.id}`} item={it} />
            ))}
          </div>
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
    <div className="mx-auto w-full max-w-app space-y-6 p-4 md:p-6">
      <header className="flex flex-wrap items-end justify-between gap-3">
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

      <div className="grid gap-4 md:grid-cols-3">
        <Lane title="Overdue" icon={AlertTriangle} accent items={cockpit.overdue}
          emptyText="Nothing overdue. Nice." />
        <Lane title="This Week" icon={CalendarRange} items={cockpit.thisWeek}
          emptyText="No deadlines in the next 7 days." />
        <Lane title="Waiting For" icon={Hourglass} items={cockpit.waitingFor}
          emptyText="Nothing blocked or waiting." />
      </div>
    </div>
  )
}
