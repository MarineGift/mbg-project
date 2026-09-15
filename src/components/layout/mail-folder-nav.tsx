'use client'
// src/components/layout/mail-folder-nav.tsx
//
// 2026-09-15 - pinned party mail folders under Inbox, one level of grouping.
//
//   Partners            <- group row (is_group), aggregates its children
//     Greentown Labs
//   Business
//     Omya
//     Specialty Minerals
//
// Clicking a group opens every child party's mail at once. Groups collapse.
// A folder whose parent was deleted falls back to the top level so it can
// never go missing from the sidebar.

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { usePathname, useSearchParams } from 'next/navigation'
import { ChevronDown, ChevronRight, FolderOpen, Settings2 } from 'lucide-react'
import { cn } from '@/lib/utils'
import {
  listMailFoldersWithCountsAction,
  type MailFolderWithCounts,
} from '@/app/actions/mail-folders'

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

  const groups = folders.filter((f) => f.isGroup)
  const groupIds = new Set(groups.map((g) => g.id))
  const childrenOf = (id: string) =>
    folders.filter((f) => !f.isGroup && f.parentId === id)
  const loose = folders.filter(
    (f) => !f.isGroup && (!f.parentId || !groupIds.has(f.parentId)),
  )

  if (folders.length === 0) {
    return (
      <li>
        <ul className="mt-0.5">
          <li>
            <ManageLink onNavigate={onNavigate} label="Add mail folder" />
          </li>
        </ul>
      </li>
    )
  }

  return (
    <li>
      <ul className="mt-0.5 space-y-0.5">
        <li className="pl-9 pr-2 pt-1 text-[10px] font-medium uppercase tracking-wide text-muted-foreground/70">
          Folders
        </li>

        {groups.map((g) => {
          const kids = childrenOf(g.id)
          const isCollapsed = collapsed[g.id] ?? false
          const active = pathname === '/inbox' && activeId === g.id
          return (
            <li key={g.id}>
              <div className="flex items-center">
                <button
                  type="button"
                  aria-label={isCollapsed ? 'Expand' : 'Collapse'}
                  onClick={() => setCollapsed((c) => ({ ...c, [g.id]: !isCollapsed }))}
                  className="ml-6 rounded p-0.5 text-muted-foreground hover:bg-accent hover:text-foreground"
                >
                  {isCollapsed ? (
                    <ChevronRight className="h-3.5 w-3.5" />
                  ) : (
                    <ChevronDown className="h-3.5 w-3.5" />
                  )}
                </button>
                <Link
                  href={`/inbox?folder=${g.id}`}
                  onClick={onNavigate}
                  className={cn(
                    'flex flex-1 items-center gap-2 rounded-md py-1.5 pl-1.5 pr-2 text-sm transition-colors',
                    active
                      ? 'bg-accent text-accent-foreground font-medium'
                      : 'text-muted-foreground hover:bg-accent hover:text-foreground',
                  )}
                  aria-current={active ? 'page' : undefined}
                >
                  <span className="flex-1 truncate font-medium">{g.name}</span>
                  {g.total > 0 && (
                    <span className="tabular-nums text-xs text-muted-foreground">
                      {g.unread}/{g.total}
                    </span>
                  )}
                </Link>
              </div>

              {!isCollapsed && kids.length > 0 && (
                <ul className="space-y-0.5">
                  {kids.map((f) => (
                    <li key={f.id}>
                      <FolderLink
                        folder={f}
                        active={pathname === '/inbox' && activeId === f.id}
                        indent="pl-[3.25rem]"
                        onNavigate={onNavigate}
                      />
                    </li>
                  ))}
                </ul>
              )}
            </li>
          )
        })}

        {loose.map((f) => (
          <li key={f.id}>
            <FolderLink
              folder={f}
              active={pathname === '/inbox' && activeId === f.id}
              indent="pl-9"
              onNavigate={onNavigate}
            />
          </li>
        ))}

        <li>
          <ManageLink onNavigate={onNavigate} label="Manage folders" />
        </li>
      </ul>
    </li>
  )
}

function FolderLink({
  folder, active, indent, onNavigate,
}: {
  folder: MailFolderWithCounts
  active: boolean
  indent: string
  onNavigate?: () => void
}) {
  return (
    <Link
      href={`/inbox?folder=${folder.id}`}
      onClick={onNavigate}
      className={cn(
        'flex items-center gap-2 rounded-md py-1.5 pr-2 text-sm transition-colors',
        indent,
        active
          ? 'bg-accent text-accent-foreground font-medium'
          : 'text-muted-foreground hover:bg-accent hover:text-foreground',
      )}
      aria-current={active ? 'page' : undefined}
      title={folder.partyName}
    >
      {folder.color ? (
        <span
          className="h-2 w-2 shrink-0 rounded-full"
          style={{ backgroundColor: folder.color }}
        />
      ) : (
        <FolderOpen className="h-3.5 w-3.5 shrink-0" />
      )}
      <span className="flex-1 truncate">{folder.name}</span>
      {folder.total > 0 && (
        <span className="tabular-nums text-xs text-muted-foreground">
          {folder.unread}/{folder.total}
        </span>
      )}
    </Link>
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
