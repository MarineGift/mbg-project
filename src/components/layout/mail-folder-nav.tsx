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
import { ChevronDown, ChevronRight, FolderOpen, Settings2 } from 'lucide-react'
import { cn } from '@/lib/utils'
import {
  listMailFoldersWithCountsAction,
  type MailFolderWithCounts,
} from '@/app/actions/mail-folders'

const INDENT = ['pl-9', 'pl-[3.25rem]', 'pl-[4.25rem]', 'pl-[5rem]']

export function MailFolderNav({ onNavigate }: { onNavigate?: () => void }) {
  const pathname = usePathname()
  const searchParams = useSearchParams()
  const activeId = searchParams.get('folder')

  const [folders, setFolders] = useState<MailFolderWithCounts[]>([])
  const [loaded, setLoaded] = useState(false)
  const [collapsed, setCollapsed] = useState<Record<string, boolean>>({})

  useEffect(() => {
    let cancelled = false
    listMailFoldersWithCountsAction()
      .then((res) => {
        if (cancelled) return
        if (res.ok) setFolders(res.data)
      })
      .catch(() => { /* the sidebar must never break navigation */ })
      .finally(() => { if (!cancelled) setLoaded(true) })
    return () => { cancelled = true }
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
    folders.filter((f) =>
      id === null ? !f.parentId || !ids.has(f.parentId) : f.parentId === id,
    )

  const renderRows = (parentId: string | null, depth: number): React.ReactNode[] =>
    childrenOf(parentId).flatMap((f) => {
      const kids = childrenOf(f.id)
      const isCollapsed = collapsed[f.id] ?? false
      const active = pathname === '/inbox' && activeId === f.id
      const indent = INDENT[Math.min(depth, INDENT.length - 1)] as string

      return [
        <li key={f.id}>
          <div className="flex items-center">
            {kids.length > 0 ? (
              <button
                type="button"
                aria-label={isCollapsed ? 'Expand' : 'Collapse'}
                onClick={() => setCollapsed((c) => ({ ...c, [f.id]: !isCollapsed }))}
                className={cn(
                  'rounded p-0.5 text-muted-foreground hover:bg-accent hover:text-foreground',
                  depth === 0 ? 'ml-6' : depth === 1 ? 'ml-10' : 'ml-14',
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
                'flex flex-1 items-center gap-2 rounded-md py-1.5 pr-2 text-sm transition-colors',
                kids.length > 0 ? 'pl-1.5' : indent,
                active
                  ? 'bg-accent text-accent-foreground font-medium'
                  : 'text-muted-foreground hover:bg-accent hover:text-foreground',
              )}
              aria-current={active ? 'page' : undefined}
              title={f.isGroup ? f.name : f.partyName}
            >
              {f.isGroup ? null : f.color ? (
                <span
                  className="h-2 w-2 shrink-0 rounded-full"
                  style={{ backgroundColor: f.color }}
                />
              ) : (
                <FolderOpen className="h-3.5 w-3.5 shrink-0" />
              )}
              <span className={cn('flex-1 truncate', f.isGroup && 'font-medium')}>
                {f.name}
              </span>
              {f.total > 0 && (
                <span className="tabular-nums text-xs text-muted-foreground">
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

  return (
    <li>
      <ul className="mt-0.5 space-y-0.5">
        <li className="pl-9 pr-2 pt-1 text-[10px] font-medium uppercase tracking-wide text-muted-foreground/70">
          Folders
        </li>
        {renderRows(null, 0)}
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
