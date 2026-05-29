// src/app/(app)/tasks/tasks-list-client.tsx
'use client'

import { useEffect, useMemo, useState, useTransition } from 'react'
import { usePathname, useRouter, useSearchParams } from 'next/navigation'
import Link from 'next/link'
import { AlertTriangle, Check } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { toggleTaskStatus } from './actions'
import AddTaskModal from './add-task-modal'

export type TaskRow = {
  id: string
  title: string
  status: string
  priority: string
  due_at: string | null
  completed_at: string | null
  assigned_to_user_id: string | null
  deal_id: string | null
  deal: {
    id: string
    deal_name: string
    pipeline: { code: string; name: string } | null
  } | null
  assignee: {
    id: string
    full_name: string | null
    given_name: string | null
    family_name: string | null
    title_text: string | null
    firm: { party_name: string | null } | null
  } | null
}

type StatusFilter = 'open' | 'completed' | 'all'

// Shared label helper (handoff: contactLabel fallback chain). If you already export
// one from '@/lib/contact-label', import that instead and delete this.
function contactLabel(c: TaskRow['assignee']): string {
  if (!c) return 'Unassigned'
  const name =
    c.full_name?.trim() ||
    [c.given_name, c.family_name].filter(Boolean).join(' ').trim()
  if (name) return name
  const firm = c.firm?.party_name?.trim()
  if (c.title_text && firm) return `${c.title_text} at ${firm}`
  return c.title_text?.trim() || firm || 'Contact'
}

// ---- date bucketing (due_at stored as UTC noon -> calendar date is tz-safe) ----
type Bucket = 'overdue' | 'today' | 'week' | 'later' | 'none'

function startOfLocalDay(d: Date): number {
  const x = new Date(d)
  x.setHours(0, 0, 0, 0)
  return x.getTime()
}

function bucketFor(due: string | null): Bucket {
  if (!due) return 'none'
  const today = startOfLocalDay(new Date())
  const dueDay = startOfLocalDay(new Date(due))
  const diffDays = Math.round((dueDay - today) / 86400000)
  if (diffDays < 0) return 'overdue'
  if (diffDays === 0) return 'today'
  if (diffDays <= 7) return 'week'
  return 'later'
}

function relativeDue(due: string | null): string {
  if (!due) return 'No due date'
  const today = startOfLocalDay(new Date())
  const dueDay = startOfLocalDay(new Date(due))
  const diffDays = Math.round((dueDay - today) / 86400000)
  if (diffDays === 0) return 'Due today'
  if (diffDays === 1) return 'Due tomorrow'
  if (diffDays === -1) return 'Due 1d ago'
  if (diffDays < 0) return `Due ${Math.abs(diffDays)}d ago`
  return `Due in ${diffDays}d`
}

const PRIORITY_STYLES: Record<string, string> = {
  high: 'bg-red-50 text-red-700 ring-red-600/20',
  medium: 'bg-amber-50 text-amber-700 ring-amber-600/20',
  low: 'bg-slate-100 text-slate-600 ring-slate-500/20',
}

function priorityBadge(priority: string) {
  const cls = PRIORITY_STYLES[priority] ?? PRIORITY_STYLES.low
  const label = priority.charAt(0).toUpperCase() + priority.slice(1)
  return (
    <span
      className={`inline-flex items-center rounded-md px-1.5 py-0.5 text-xs font-medium ring-1 ring-inset ${cls}`}
    >
      {label}
    </span>
  )
}

const BUCKET_ORDER: { key: Bucket; label: string }[] = [
  { key: 'overdue', label: 'Overdue' },
  { key: 'today', label: 'Today' },
  { key: 'week', label: 'This week' },
  { key: 'later', label: 'Later' },
  { key: 'none', label: 'No due date' },
]

export default function TasksListClient({
  tasks,
  currentUserId,
  initialStatus,
  initialMine,
}: {
  tasks: TaskRow[]
  currentUserId: string | null
  initialStatus: StatusFilter
  initialMine: boolean
}) {
  const router = useRouter()
  const pathname = usePathname()
  const searchParams = useSearchParams()

  const [status, setStatus] = useState<StatusFilter>(initialStatus)
  const [mine, setMine] = useState(initialMine)
  const [dealFilter, setDealFilter] = useState<string>('all')
  const [modalOpen, setModalOpen] = useState(false)
  const [pending, startTransition] = useTransition()

  // keep URL shareable: ?status=open&filter=mine
  useEffect(() => {
    const params = new URLSearchParams(searchParams.toString())
    if (status === 'open') params.delete('status')
    else params.set('status', status)
    if (mine) params.set('filter', 'mine')
    else params.delete('filter')
    const qs = params.toString()
    router.replace(qs ? `${pathname}?${qs}` : pathname, { scroll: false })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [status, mine])

  // distinct deals present, for the "All deals" dropdown
  const dealOptions = useMemo(() => {
    const seen = new Map<string, string>()
    for (const t of tasks) {
      if (t.deal) seen.set(t.deal.id, t.deal.deal_name)
    }
    return Array.from(seen, ([id, name]) => ({ id, name }))
  }, [tasks])

  const filtered = useMemo(() => {
    return tasks.filter((t) => {
      if (mine) {
        if (!currentUserId || t.assigned_to_user_id !== currentUserId) return false
      }
      if (dealFilter !== 'all' && t.deal?.id !== dealFilter) return false
      const isCompleted = t.status === 'completed'
      if (status === 'open' && isCompleted) return false
      if (status === 'completed' && !isCompleted) return false
      return true
    })
  }, [tasks, mine, dealFilter, status, currentUserId])

  const openTasks = filtered.filter((t) => t.status !== 'completed')
  const completedTasks = filtered.filter((t) => t.status === 'completed')

  const grouped = useMemo(() => {
    const map = new Map<Bucket, TaskRow[]>()
    for (const t of openTasks) {
      const b = bucketFor(t.due_at)
      if (!map.has(b)) map.set(b, [])
      map.get(b)!.push(t)
    }
    return map
  }, [openTasks])

  const overdueCount = grouped.get('overdue')?.length ?? 0
  const todayCount = grouped.get('today')?.length ?? 0

  function handleToggle(t: TaskRow) {
    const next = t.status === 'completed' ? 'pending' : 'completed'
    const dealPath = t.deal?.pipeline
      ? `/pipelines/${t.deal.pipeline.code}/deals/${t.deal.id}`
      : undefined
    startTransition(async () => {
      await toggleTaskStatus(t.id, next, dealPath)
      router.refresh()
    })
  }

  return (
    <div className="mx-auto w-full max-w-4xl px-6 py-8">
      {/* Header */}
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold tracking-tight">Tasks</h1>
          {(overdueCount > 0 || todayCount > 0) && (
            <p className="mt-1 text-sm text-muted-foreground">
              {overdueCount > 0 && (
                <span className="text-red-600">{overdueCount} overdue</span>
              )}
              {overdueCount > 0 && todayCount > 0 && (
                <span className="px-1.5 text-muted-foreground">{'\u00b7'}</span>
              )}
              {todayCount > 0 && <span>{todayCount} due today</span>}
            </p>
          )}
        </div>
        <Button onClick={() => setModalOpen(true)}>+ Add task</Button>
      </div>

      {/* Filter bar */}
      <div className="mb-6 flex flex-wrap items-center gap-3">
        <div className="inline-flex rounded-lg border bg-muted/40 p-0.5 text-sm">
          {(['open', 'completed', 'all'] as StatusFilter[]).map((s) => (
            <button
              key={s}
              onClick={() => setStatus(s)}
              className={`rounded-md px-3 py-1 capitalize transition-colors ${
                status === s
                  ? 'bg-background font-medium shadow-sm'
                  : 'text-muted-foreground hover:text-foreground'
              }`}
            >
              {s}
            </button>
          ))}
        </div>

        <select
          value={dealFilter}
          onChange={(e) => setDealFilter(e.target.value)}
          className="rounded-md border bg-background px-2.5 py-1.5 text-sm"
        >
          <option value="all">All deals</option>
          {dealOptions.map((d) => (
            <option key={d.id} value={d.id}>
              {d.name}
            </option>
          ))}
        </select>

        <label className="inline-flex cursor-pointer items-center gap-2 rounded-md border bg-background px-2.5 py-1.5 text-sm">
          <input
            type="checkbox"
            checked={mine}
            onChange={(e) => setMine(e.target.checked)}
            className="h-3.5 w-3.5 accent-current"
          />
          Me only
        </label>
      </div>

      {/* Open task buckets */}
      {status !== 'completed' && (
        <div className="space-y-6">
          {BUCKET_ORDER.map(({ key, label }) => {
            const rows = grouped.get(key)
            if (!rows || rows.length === 0) return null
            return (
              <section key={key}>
                <div className="mb-2 flex items-center gap-2">
                  <h2
                    className={`text-xs font-semibold uppercase tracking-wide ${
                      key === 'overdue' ? 'text-red-600' : 'text-muted-foreground'
                    }`}
                  >
                    {label} ({rows.length})
                  </h2>
                  {key === 'overdue' && (
                    <AlertTriangle className="h-3.5 w-3.5 text-red-600" />
                  )}
                </div>
                <ul className="divide-y rounded-lg border">
                  {rows.map((t) => (
                    <TaskItem
                      key={t.id}
                      task={t}
                      onToggle={handleToggle}
                      disabled={pending}
                    />
                  ))}
                </ul>
              </section>
            )
          })}

          {openTasks.length === 0 && status === 'open' && (
            <div className="rounded-lg border border-dashed py-16 text-center text-sm text-muted-foreground">
              No open tasks. Nice work.
            </div>
          )}
        </div>
      )}

      {/* Completed section */}
      {(status === 'completed' || status === 'all') && completedTasks.length > 0 && (
        <section className={status === 'all' ? 'mt-8' : ''}>
          <h2 className="mb-2 text-xs font-semibold uppercase tracking-wide text-muted-foreground">
            Completed ({completedTasks.length})
          </h2>
          <ul className="divide-y rounded-lg border opacity-70">
            {completedTasks.map((t) => (
              <TaskItem
                key={t.id}
                task={t}
                onToggle={handleToggle}
                disabled={pending}
              />
            ))}
          </ul>
        </section>
      )}

      <AddTaskModal
        open={modalOpen}
        onOpenChange={setModalOpen}
        onCreated={() => router.refresh()}
      />
    </div>
  )

  // ---- row ----
  function TaskItem({
    task,
    onToggle,
    disabled,
  }: {
    task: TaskRow
    onToggle: (t: TaskRow) => void
    disabled: boolean
  }) {
    const done = task.status === 'completed'
    const overdue = !done && bucketFor(task.due_at) === 'overdue'
    return (
      <li className="flex items-start gap-3 px-3 py-2.5">
        <button
          type="button"
          aria-label={done ? 'Mark incomplete' : 'Mark complete'}
          disabled={disabled}
          onClick={() => onToggle(task)}
          className={`mt-0.5 flex h-4 w-4 shrink-0 items-center justify-center rounded border transition-colors ${
            done
              ? 'border-emerald-600 bg-emerald-600 text-white'
              : 'border-muted-foreground/40 hover:border-foreground'
          } disabled:opacity-50`}
        >
          {done && <Check className="h-3 w-3" />}
        </button>

        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-x-2 gap-y-1">
            <span
              className={`text-sm ${done ? 'text-muted-foreground line-through' : 'font-medium'}`}
            >
              {task.title}
            </span>
            {!done && priorityBadge(task.priority)}
            {!done && (
              <span
                className={`text-xs ${overdue ? 'text-red-600' : 'text-muted-foreground'}`}
              >
                {relativeDue(task.due_at)}
              </span>
            )}
          </div>
          <div className="mt-0.5 text-xs text-muted-foreground">
            {task.deal ? (
              <Link
                href={
                  task.deal.pipeline
                    ? `/pipelines/${task.deal.pipeline.code}/deals/${task.deal.id}`
                    : '#'
                }
                className="hover:underline"
              >
                {task.deal.deal_name}
              </Link>
            ) : (
              <span>No deal</span>
            )}
            {task.deal?.pipeline && (
              <>
                <span className="px-1">{'\u2192'}</span>
                <span>{task.deal.pipeline.name}</span>
              </>
            )}
            {task.assignee && (
              <>
                <span className="px-1.5">{'\u00b7'}</span>
                <span>{contactLabel(task.assignee)}</span>
              </>
            )}
          </div>
        </div>
      </li>
    )
  }
}
