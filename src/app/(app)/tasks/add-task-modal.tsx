// src/app/(app)/tasks/add-task-modal.tsx
'use client'

import { useEffect, useRef, useState, useTransition } from 'react'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import {
  addTask,
  searchDeals,
  searchContacts,
  type DealHit,
  type ContactHit,
} from './actions'

const PRIORITIES: { value: 'low' | 'medium' | 'high'; label: string; cls: string }[] = [
  { value: 'low', label: 'Low', cls: 'data-[on=true]:bg-slate-100 data-[on=true]:text-slate-700 data-[on=true]:ring-slate-400' },
  { value: 'medium', label: 'Medium', cls: 'data-[on=true]:bg-amber-50 data-[on=true]:text-amber-700 data-[on=true]:ring-amber-500' },
  { value: 'high', label: 'High', cls: 'data-[on=true]:bg-red-50 data-[on=true]:text-red-700 data-[on=true]:ring-red-500' },
]

function contactLabel(c: ContactHit): string {
  const name =
    c.full_name?.trim() ||
    [c.given_name, c.family_name].filter(Boolean).join(' ').trim()
  if (name) return name
  const firm = c.firm?.party_name?.trim()
  if (c.title_text && firm) return `${c.title_text} at ${firm}`
  return c.title_text?.trim() || firm || 'Contact'
}

export default function AddTaskModal({
  open,
  onOpenChange,
  onCreated,
}: {
  open: boolean
  onOpenChange: (v: boolean) => void
  onCreated?: () => void
}) {
  const [title, setTitle] = useState('')
  const [dueDate, setDueDate] = useState('')
  const [priority, setPriority] = useState<'low' | 'medium' | 'high'>('medium')
  const [description, setDescription] = useState('')
  const [deal, setDeal] = useState<DealHit | null>(null)
  const [assignee, setAssignee] = useState<ContactHit | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [pending, startTransition] = useTransition()

  function reset() {
    setTitle('')
    setDueDate('')
    setPriority('medium')
    setDescription('')
    setDeal(null)
    setAssignee(null)
    setError(null)
  }

  function handleClose(v: boolean) {
    if (!v) reset()
    onOpenChange(v)
  }

  function handleSubmit() {
    setError(null)
    if (!title.trim()) return setError('Title is required.')
    if (!deal) return setError('Pick a deal for this task.')
    startTransition(async () => {
      const res = await addTask({
        title,
        dealId: deal.id,
        dueDate: dueDate || null,
        priority,
        assigneeContactId: assignee?.id ?? null,
        description: description || null,
      })
      if (!res.ok) {
        setError(res.error)
        return
      }
      handleClose(false)
      onCreated?.()
    })
  }

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-[460px]">
        <DialogHeader>
          <DialogTitle>Add task</DialogTitle>
        </DialogHeader>

        <div className="space-y-4 py-1">
          {/* Title */}
          <div className="space-y-1.5">
            <label className="text-sm font-medium">Title</label>
            <input
              autoFocus
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="What needs doing?"
              className="w-full rounded-md border bg-background px-3 py-2 text-sm"
            />
          </div>

          {/* Deal (cross-deal page needs this) */}
          <div className="space-y-1.5">
            <label className="text-sm font-medium">Deal</label>
            <DealSearchInput value={deal} onChange={setDeal} />
          </div>

          {/* Due + priority row */}
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1.5">
              <label className="text-sm font-medium">Due date</label>
              <input
                type="date"
                value={dueDate}
                onChange={(e) => setDueDate(e.target.value)}
                className="w-full rounded-md border bg-background px-3 py-2 text-sm"
              />
            </div>
            <div className="space-y-1.5">
              <label className="text-sm font-medium">Priority</label>
              <div className="flex gap-1">
                {PRIORITIES.map((p) => (
                  <button
                    key={p.value}
                    type="button"
                    data-on={priority === p.value}
                    onClick={() => setPriority(p.value)}
                    className={`flex-1 rounded-md border px-2 py-2 text-xs ring-inset data-[on=true]:ring-1 ${p.cls} ${
                      priority === p.value ? '' : 'text-muted-foreground'
                    }`}
                  >
                    {p.label}
                  </button>
                ))}
              </div>
            </div>
          </div>

          {/* Assignee */}
          <div className="space-y-1.5">
            <label className="text-sm font-medium">Assignee</label>
            <ContactSearchInput value={assignee} onChange={setAssignee} />
          </div>

          {/* Description */}
          <div className="space-y-1.5">
            <label className="text-sm font-medium">Description</label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              rows={2}
              placeholder="Optional details"
              className="w-full resize-none rounded-md border bg-background px-3 py-2 text-sm"
            />
          </div>

          {error && <p className="text-sm text-red-600">{error}</p>}
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={() => handleClose(false)} disabled={pending}>
            Cancel
          </Button>
          <Button onClick={handleSubmit} disabled={pending}>
            {pending ? 'Saving...' : 'Add task'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

/* ------------------------------------------------------------------ */
/* DealSearchInput — server-side debounced search across all deals     */
/* Rules of Hooks: ALL hooks declared before any conditional return.   */
/* ------------------------------------------------------------------ */
function DealSearchInput({
  value,
  onChange,
}: {
  value: DealHit | null
  onChange: (d: DealHit | null) => void
}) {
  const [query, setQuery] = useState('')
  const [hits, setHits] = useState<DealHit[]>([])
  const [openList, setOpenList] = useState(false)
  const boxRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const q = query.trim()
    if (q.length < 1) {
      setHits([])
      return
    }
    const t = setTimeout(async () => {
      setHits(await searchDeals(q))
      setOpenList(true)
    }, 250)
    return () => clearTimeout(t)
  }, [query])

  useEffect(() => {
    function onDoc(e: MouseEvent) {
      if (boxRef.current && !boxRef.current.contains(e.target as Node)) {
        setOpenList(false)
      }
    }
    document.addEventListener('mousedown', onDoc)
    return () => document.removeEventListener('mousedown', onDoc)
  }, [])

  // selected vs unselected branch AFTER the click-outside effect (handoff note)
  if (value) {
    return (
      <div className="flex items-center justify-between rounded-md border bg-muted/40 px-3 py-2 text-sm">
        <span className="truncate">
          {value.deal_name}
          {value.pipeline && (
            <span className="ml-1.5 text-xs text-muted-foreground">
              {value.pipeline.name}
            </span>
          )}
        </span>
        <button
          type="button"
          onClick={() => onChange(null)}
          className="text-xs text-muted-foreground hover:text-foreground"
        >
          Change
        </button>
      </div>
    )
  }

  return (
    <div ref={boxRef} className="relative">
      <input
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        onFocus={() => hits.length > 0 && setOpenList(true)}
        placeholder="Search deals..."
        className="w-full rounded-md border bg-background px-3 py-2 text-sm"
      />
      {openList && hits.length > 0 && (
        <ul className="absolute z-50 mt-1 max-h-56 w-full overflow-auto rounded-md border bg-popover shadow-md">
          {hits.map((d) => (
            <li key={d.id}>
              <button
                type="button"
                onClick={() => {
                  onChange(d)
                  setOpenList(false)
                  setQuery('')
                }}
                className="flex w-full flex-col items-start px-3 py-2 text-left text-sm hover:bg-accent"
              >
                <span>{d.deal_name}</span>
                {d.pipeline && (
                  <span className="text-xs text-muted-foreground">{d.pipeline.name}</span>
                )}
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}

/* ------------------------------------------------------------------ */
/* ContactSearchInput — server-side debounced search, name fallback    */
/* ------------------------------------------------------------------ */
function ContactSearchInput({
  value,
  onChange,
}: {
  value: ContactHit | null
  onChange: (c: ContactHit | null) => void
}) {
  const [query, setQuery] = useState('')
  const [hits, setHits] = useState<ContactHit[]>([])
  const [openList, setOpenList] = useState(false)
  const boxRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const q = query.trim()
    if (q.length < 1) {
      setHits([])
      return
    }
    const t = setTimeout(async () => {
      setHits(await searchContacts(q))
      setOpenList(true)
    }, 250)
    return () => clearTimeout(t)
  }, [query])

  useEffect(() => {
    function onDoc(e: MouseEvent) {
      if (boxRef.current && !boxRef.current.contains(e.target as Node)) {
        setOpenList(false)
      }
    }
    document.addEventListener('mousedown', onDoc)
    return () => document.removeEventListener('mousedown', onDoc)
  }, [])

  if (value) {
    return (
      <div className="flex items-center justify-between rounded-md border bg-muted/40 px-3 py-2 text-sm">
        <span className="truncate">{contactLabel(value)}</span>
        <button
          type="button"
          onClick={() => onChange(null)}
          className="text-xs text-muted-foreground hover:text-foreground"
        >
          Change
        </button>
      </div>
    )
  }

  return (
    <div ref={boxRef} className="relative">
      <input
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        onFocus={() => hits.length > 0 && setOpenList(true)}
        placeholder="Search contacts... (optional)"
        className="w-full rounded-md border bg-background px-3 py-2 text-sm"
      />
      {openList && hits.length > 0 && (
        <ul className="absolute z-50 mt-1 max-h-56 w-full overflow-auto rounded-md border bg-popover shadow-md">
          {hits.map((c) => (
            <li key={c.id}>
              <button
                type="button"
                onClick={() => {
                  onChange(c)
                  setOpenList(false)
                  setQuery('')
                }}
                className="w-full px-3 py-2 text-left text-sm hover:bg-accent"
              >
                {contactLabel(c)}
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}
