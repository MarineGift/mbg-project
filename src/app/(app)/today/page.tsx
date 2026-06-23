// src/app/(app)/today/page.tsx
// todo_v2 Phase 1.5 - Today as a source-typed kanban board.
// Seven columns in canonical order (event -> meeting -> deal_task ->
// communication -> todo -> next_step -> close) over getTodayBoard().
// Every row is a link to the relevant page.
import Link from 'next/link'
import { Badge } from '@/components/ui/badge'
import { cn } from '@/lib/utils'
import {
  getTodayBoard,
  type BoardItem,
  type BoardSource,
} from '@/lib/queries/today'

export const dynamic = 'force-dynamic'

const SOURCE_META: Record<BoardSource, { label: string; dot: string }> = {
  event:               { label: 'Calendar events', dot: 'bg-indigo-500' },
  meeting:             { label: 'Meetings',         dot: 'bg-violet-500' },
  deal_task:           { label: 'Deal tasks',       dot: 'bg-sky-500' },
  communication:       { label: 'Communications',   dot: 'bg-slate-500' },
  todo:                { label: 'To-Do',            dot: 'bg-emerald-500' },
  milestone_next_step: { label: 'Deal: next step',  dot: 'bg-amber-500' },
  milestone_close:     { label: 'Deal: close',      dot: 'bg-rose-500' },
}

function fmtWhen(when: string | null): string {
  if (!when) return ''
  return new Date(`${when}T00:00:00`).toLocaleDateString(undefined, { month: 'short', day: 'numeric' })
}

function ItemRow({ item }: { item: BoardItem }) {
  return (
    <Link
      href={item.href}
      className="block rounded-md border bg-background px-3 py-2 transition-colors hover:bg-muted"
    >
      <div className="flex items-start justify-between gap-2">
        <span className="min-w-0 flex-1 truncate text-sm font-medium text-foreground">
          {item.title}
        </span>
        {item.when && (
          <span
            className={cn(
              'shrink-0 text-xs tabular-nums',
              item.overdue ? 'font-medium text-destructive' : 'text-muted-foreground',
            )}
          >
            {fmtWhen(item.when)}
          </span>
        )}
      </div>
      {item.context && (
        <span className="mt-0.5 block truncate text-xs text-muted-foreground">{item.context}</span>
      )}
    </Link>
  )
}

function Column({
  source, items, total,
}: { source: BoardSource; items: BoardItem[]; total: number }) {
  const meta = SOURCE_META[source]
  const more = total - items.length
  return (
    <section className="flex w-80 shrink-0 flex-col rounded-lg border bg-card md:min-h-0">
      <header className="flex shrink-0 items-center gap-2 border-b px-3 py-2.5">
        <span className={cn('h-2.5 w-2.5 rounded-full', meta.dot)} aria-hidden />
        <span className="text-sm font-semibold text-foreground">{meta.label}</span>
        <Badge variant="secondary" className="ml-auto">{total}</Badge>
      </header>
      <div className="flex max-h-[70vh] flex-col gap-2 overflow-y-auto p-2 md:max-h-none md:min-h-0 md:flex-1">
        {items.length === 0 ? (
          <p className="px-1 py-6 text-center text-xs text-muted-foreground">Nothing here.</p>
        ) : (
          items.map((it) => <ItemRow key={`${it.source}:${it.id}`} item={it} />)
        )}
        {more > 0 && (
          <p className="px-1 pt-1 text-xs text-muted-foreground">+{more} more</p>
        )}
      </div>
    </section>
  )
}

export default async function TodayPage() {
  const board = await getTodayBoard()
  const todayLabel = new Date(`${board.today}T00:00:00`).toLocaleDateString(undefined, {
    weekday: 'long', month: 'long', day: 'numeric',
  })

  return (
    <div className="flex w-full flex-col gap-4 p-4 md:h-[calc(100vh-64px)] md:overflow-hidden md:p-6">
      <header className="shrink-0">
        <h1 className="text-2xl font-semibold tracking-tight text-foreground">Today</h1>
        <p className="text-sm text-muted-foreground">{todayLabel}</p>
      </header>

      <div className="flex gap-4 overflow-x-auto pb-2 md:min-h-0 md:flex-1">
        {board.columns.map((col) => (
          <Column key={col.source} source={col.source} items={col.items} total={col.total} />
        ))}
      </div>
    </div>
  )
}
