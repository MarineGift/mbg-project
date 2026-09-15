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

  // Refresh on navigation, on a 60s timer, and whenever the tab regains focus,
  // so a folder lights up when mail arrives without the user reloading. One
  // RPC call per refresh (app.mail_folder_counts), so this stays cheap.
  useEffect(() => {
    let cancelled = false

    const load = () => {
      listMailFoldersWithCountsAction()
        .then((res) => {
          if (cancelled) return
          if (res.ok) setFolders(res.data)
        })
        .catch(() => { /* the sidebar must never break navigation */ })
        .finally(() => { if (!cancelled) setLoaded(true) })
    }

    load()
    const timer = setInterval(load, 60_000)
    const onFocus = () => { if (document.visibilityState === 'visible') load() }
    window.addEventListener('focus', onFocus)
    document.addEventListener('visibilitychange', onFocus)

    return () => {
      cancelled = true
      clearInterval(timer)
      window.removeEventListener('focus', onFocus)
      document.removeEventListener('visibilitychange', onFocus)
    }
  }, [pathname])

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
      // Unread mail pulls the row out of the muted default and swaps the
      // grey "unread/total" text for a coloured count of what is new.
      const hasNew = f.unread > 0
      const accent = f.color ?? '#2563eb'

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
                    ? 'text-foreground hover:bg-accent'
                    : 'text-muted-foreground hover:bg-accent hover:text-foreground',
              )}
              aria-current={active ? 'page' : undefined}
              title={
                `${f.isGroup ? f.name : f.partyName} \u2014 ` +
                `${f.unread} new / ${f.total} inbound`
              }
            >
              {f.isGroup ? null : (
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
                  (f.isGroup || hasNew) && 'font-medium',
                )}
              >
                {f.name}
              </span>
              {hasNew ? (
                <span
                  className="shrink-0 rounded-full px-1.5 py-0.5 text-[10px] font-semibold leading-none text-white tabular-nums"
                  style={{ backgroundColor: accent }}
                  aria-label={`${f.unread} unread`}
                >
                  {f.unread > 999 ? '999+' : f.unread}
                </span>
              ) : (
                f.total > 0 && (
                  <span className="shrink-0 tabular-nums text-xs text-muted-foreground">
                    {f.total}
                  </span>
                )
              )}
            </Link>
          </div>

          {!isCollapsed && kids.length > 0 && (
            <ul className="space-y-0.5">{renderRows(f.id, depth + 1)}</ul>
          )}
        </li>,
      ]
    })

  return (
    <li className="min-w-0">
      <p className="pl-9 pr-2 pt-1 text-[10px] font-medium uppercase tracking-wide text-muted-foreground/70">
        Folders
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
