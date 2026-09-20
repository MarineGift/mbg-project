'use client'
// src/components/layout/mail-folder-nav.tsx
//
// 2026-09-15 - pinned mail folders under Inbox, nested groups.
//
//   Partners
//     Greentown Labs Houston
//   Business
//     Omya
//       Omya (Korea)
//       Omya (USA)
//     Specialty Minerals
//       Specialty Minerals Inc
//
// Clicking any row opens that folder AND everything below it. Counts come from
// app.mail_folder_counts(), which counts each message once per subtree - so a
// group is never the naive sum of its children.
//
// Depth is capped at 3 in the sidebar; anything deeper still opens from
// /inbox/folders. A folder whose parent was deleted renders at the top level
// so it can never go missing.
//
// 2026-09-15b - "new arrival" signal.
// Most inbound mail is never marked read, so a coloured unread/total pill was
// lit on almost every folder and said nothing about what just arrived. Now:
//   - each browser keeps a per-folder snapshot of `total` (localStorage) taken
//     the last time that folder was opened
//   - fresh = total - snapshot  -> blue row tint + pulsing dot + "+N" pill
//   - opening a folder clears it (and its sub-folders, and the matching part of
//     its parent groups)
//   - the realtime provider fires `urm:mail-arrived` on every inbound insert,
//     so the sidebar refreshes immediately instead of waiting for the timer
// First visit on a browser just records a baseline (no false "+N" storm).

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { usePathname, useSearchParams } from 'next/navigation'
import { ChevronDown, ChevronRight, Settings2 } from 'lucide-react'
import { cn } from '@/lib/utils'
import {
  listMailFoldersWithCountsAction,
  type MailFolderWithCounts,
} from '@/app/actions/mail-folders'

const INDENT = ['pl-9', 'pl-11', 'pl-[3.25rem]', 'pl-[3.75rem]']

export const MAIL_ARRIVED_EVENT = 'urm:mail-arrived'
const SEEN_KEY = 'urm.mailFolderSeen.v1'
type SeenMap = Record<string, number>

function readSeen(): SeenMap {
  try {
    const raw = window.localStorage.getItem(SEEN_KEY)
    const v = raw ? (JSON.parse(raw) as unknown) : null
    return v && typeof v === 'object' ? (v as SeenMap) : {}
  } catch {
    return {}
  }
}

function writeSeen(m: SeenMap) {
  try { window.localStorage.setItem(SEEN_KEY, JSON.stringify(m)) } catch { /* private mode */ }
}

// Ordering inside every level, two stages:
//   1. folders that actually receive mail come first
//   2. then alphabetically (locale aware, so numbers sort naturally)
// Manual sort_order is ignored on purpose - with ~30 subsidiaries a curated
// order is unmaintainable, and an empty folder at the top is just noise.
export function compareFolders(
  a: { total: number; name: string },
  b: { total: number; name: string },
): number {
  const aHas = a.total > 0 ? 0 : 1
  const bHas = b.total > 0 ? 0 : 1
  if (aHas !== bHas) return aHas - bHas
  return a.name.localeCompare(b.name, undefined, {
    numeric: true,
    sensitivity: 'base',
  })
}

export function MailFolderNav({ onNavigate }: { onNavigate?: () => void }) {
  const pathname = usePathname()
  const searchParams = useSearchParams()
  const activeId = searchParams.get('folder')

  const [folders, setFolders] = useState<MailFolderWithCounts[]>([])
  const [loaded, setLoaded] = useState(false)
  const [collapsed, setCollapsed] = useState<Record<string, boolean>>({})
  const [seen, setSeen] = useState<SeenMap>({})

  // Refresh on navigation, on a 120s timer (visible tab only), on `urm:mail-arrived`, and whenever the tab regains focus,
  // so a folder lights up when mail arrives without the user reloading. One
  // RPC call per refresh (app.mail_folder_counts), so this stays cheap.
  useEffect(() => {
    let cancelled = false

    const load = () => {
      listMailFoldersWithCountsAction()
        .then((res) => {
          if (cancelled) return
          if (!res.ok) return
          // unreadFirst: folders with unseen mail float to the top, then by
          // unread count, then by the curated sort_order the API returned.
          const unreadFirst = [...res.data].sort((a, b) => {
            const au = a.unread ?? 0
            const bu = b.unread ?? 0
            if (au > 0 !== bu > 0) return bu > 0 ? 1 : -1
            if (au !== bu) return bu - au
            return 0
          })
          setFolders(unreadFirst)
          // First load starts fully collapsed; once the user has toggled
          // anything, collapsed has keys and their choice is kept.
          setCollapsed((prev) =>
            Object.keys(prev).length > 0
              ? prev
              : Object.fromEntries(res.data.map((f) => [f.id, true])),
          )
          // Baseline any folder this browser has never seen, so the first
          // visit does not flag every folder as new.
          const m = readSeen()
          let dirty = false
          for (const f of res.data) {
            if (typeof m[f.id] !== 'number' || m[f.id]! > f.total) { m[f.id] = f.total; dirty = true }
          }
          if (dirty) writeSeen(m)
          setSeen(m)
        })
        .catch(() => { /* the sidebar must never break navigation */ })
        .finally(() => { if (!cancelled) setLoaded(true) })
    }

    load()
    const timer = setInterval(() => { if (document.visibilityState === 'visible') load() }, 120_000)
    const onFocus = () => { if (document.visibilityState === 'visible') load() }
    // small delay: the realtime INSERT can land before the folder-matching
    // columns are filled in by the mail worker
    const onArrived = () => { window.setTimeout(load, 1500) }
    window.addEventListener('focus', onFocus)
    document.addEventListener('visibilitychange', onFocus)
    window.addEventListener(MAIL_ARRIVED_EVENT, onArrived)

    return () => {
      cancelled = true
      clearInterval(timer)
      window.removeEventListener('focus', onFocus)
      document.removeEventListener('visibilitychange', onFocus)
      window.removeEventListener(MAIL_ARRIVED_EVENT, onArrived)
    }
  }, [pathname])

  // Opening a folder marks it (and everything under it) as seen, and takes the
  // same amount off its parent groups so they do not stay lit for mail that was
  // just looked at.
  const openId = pathname === '/inbox' ? activeId : null
  useEffect(() => {
    if (!openId || folders.length === 0) return
    const byId = new Map(folders.map((f) => [f.id, f]))
    const target = byId.get(openId)
    if (!target) return
    const m = readSeen()
    const cleared = Math.max(0, target.total - (m[target.id] ?? target.total))
    const stack = [target.id]
    while (stack.length) {
      const id = stack.pop() as string
      const f = byId.get(id)
      if (f) m[id] = f.total
      for (const c of folders) if (c.parentId === id) stack.push(c.id)
    }
    let up = target.parentId ? byId.get(target.parentId) : undefined
    while (up && cleared > 0) {
      m[up.id] = Math.min(up.total, (m[up.id] ?? up.total) + cleared)
      up = up.parentId ? byId.get(up.parentId) : undefined
    }
    writeSeen(m)
    setSeen(m)
  }, [openId, folders])

  if (!loaded) return null

  if (folders.length === 0) {
    return (
      <li>
        <ul className="mt-0.5">
          <li><ManageLink label="Add mail folder" onNavigate={onNavigate} /></li>
        </ul>
      </li>
    )
  }

  const ids = new Set(folders.map((f) => f.id))
  const childrenOf = (id: string | null) =>
    folders
      .filter((f) =>
        id === null ? !f.parentId || !ids.has(f.parentId) : f.parentId === id,
      )
      .sort(compareFolders)

  const renderRows = (parentId: string | null, depth: number): React.ReactNode[] =>
    childrenOf(parentId).flatMap((f) => {
      const kids = childrenOf(f.id)
      const isCollapsed = collapsed[f.id] ?? false
      const active = pathname === '/inbox' && activeId === f.id
      const indent = INDENT[Math.min(depth, INDENT.length - 1)] as string
      // fresh = arrived since this folder was last opened (see header note).
      // Plain unread only makes the name darker; it no longer lights the row.
      const fresh = active ? 0 : Math.max(0, f.total - (seen[f.id] ?? f.total))
      const hasNew = fresh > 0
      const hasUnread = f.unread > 0

      return [
        <li key={f.id}>
          <div className="flex min-w-0 items-center">
            {kids.length > 0 ? (
              <button
                type="button"
                aria-label={isCollapsed ? 'Expand' : 'Collapse'}
                onClick={() => setCollapsed((c) => ({ ...c, [f.id]: !isCollapsed }))}
                className={cn(
                  'rounded p-0.5 text-muted-foreground hover:bg-accent hover:text-foreground',
                  depth === 0 ? 'ml-6' : depth === 1 ? 'ml-8' : 'ml-10',
                )}
              >
                {isCollapsed
                  ? <ChevronRight className="h-3.5 w-3.5" />
                  : <ChevronDown className="h-3.5 w-3.5" />}
              </button>
            ) : null}

            <Link
              href={`/inbox?folder=${f.id}`}
              onClick={onNavigate}
              className={cn(
                'flex min-w-0 flex-1 items-center gap-2 rounded-md py-1.5 pr-2 text-sm transition-colors',
                kids.length > 0 ? 'pl-1.5' : indent,
                active
                  ? 'bg-accent text-accent-foreground font-medium'
                  : hasNew
                    ? 'bg-blue-50 text-foreground hover:bg-blue-100 dark:bg-blue-950/40 dark:hover:bg-blue-900/40'
                    : hasUnread
                      ? 'text-foreground hover:bg-accent'
                      : 'text-muted-foreground hover:bg-accent hover:text-foreground',
              )}
              aria-current={active ? 'page' : undefined}
              title={
                `${f.isGroup ? f.name : f.partyName} \u2014 ` +
                (hasNew ? `${fresh} new since last opened, ` : '') +
                `${f.unread} unread / ${f.total} inbound`
              }
            >
              {hasNew ? (
                <span className="relative flex h-2 w-2 shrink-0">
                  <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-blue-500 opacity-75" />
                  <span className="relative inline-flex h-2 w-2 rounded-full bg-blue-600" />
                </span>
              ) : f.isGroup ? null : (
                <span
                  className={cn(
                    'h-2 w-2 shrink-0 rounded-full',
                    !f.color && 'bg-muted-foreground/40',
                  )}
                  style={f.color ? { backgroundColor: f.color } : undefined}
                />
              )}
              <span
                className={cn(
                  'min-w-0 flex-1 truncate',
                  hasNew ? 'font-semibold' : (f.isGroup || hasUnread) && 'font-medium',
                )}
              >
                {f.name}
              </span>
              {hasNew && (
                <span
                  className="shrink-0 rounded-full bg-blue-600 px-1.5 py-0.5 text-[10px] font-semibold leading-none text-white tabular-nums"
                  aria-label={`${fresh} new`}
                >
                  +{fresh > 99 ? '99' : fresh}
                </span>
              )}
              {f.total > 0 && (
                <span className="shrink-0 tabular-nums text-xs text-muted-foreground">
                  {f.unread}/{f.total}
                </span>
              )}
            </Link>
          </div>

          {!isCollapsed && kids.length > 0 && (
            <ul className="space-y-0.5">{renderRows(f.id, depth + 1)}</ul>
          )}
        </li>,
      ]
    })

  // top-level rows only, so a message is not counted once per nesting level
  const totalFresh = childrenOf(null).reduce(
    (n, f) => n + Math.max(0, f.total - (seen[f.id] ?? f.total)),
    0,
  )

  return (
    <li className="min-w-0">
      <p className="flex items-center gap-2 pl-9 pr-2 pt-1 text-[10px] font-medium uppercase tracking-wide text-muted-foreground/70">
        Folders
        {totalFresh > 0 && (
          <span className="rounded-full bg-blue-600 px-1.5 py-0.5 normal-case leading-none tracking-normal text-white">
            {totalFresh} new
          </span>
        )}
      </p>
      {/* Own scroll area: with 30+ folders the flat list pushed Sent / To-Do /
          Calendar past the bottom of the sidebar. 45vh leaves room for the rest
          of the nav on a short window; overflow-x-hidden keeps deep rows from
          adding a horizontal scrollbar - widen the sidebar by dragging its
          right edge instead. */}
      <div className="max-h-[45vh] overflow-y-auto overflow-x-hidden overscroll-contain scrollbar-thin">
        <ul className="mt-0.5 space-y-0.5">{renderRows(null, 0)}</ul>
      </div>
      <ul className="mt-0.5">
        <li><ManageLink label="Manage folders" onNavigate={onNavigate} /></li>
      </ul>
    </li>
  )
}

function ManageLink({ label, onNavigate }: { label: string; onNavigate?: () => void }) {
  return (
    <Link
      href="/inbox/folders"
      onClick={onNavigate}
      className="flex items-center gap-2 rounded-md py-1.5 pl-9 pr-2 text-xs text-muted-foreground hover:bg-accent hover:text-foreground"
    >
      <Settings2 className="h-3 w-3" />
      <span className="truncate">{label}</span>
    </Link>
  )
}
