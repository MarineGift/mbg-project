'use client'
// src/components/layout/mail-folder-nav.tsx
//
// 2026-09-15 - pinned party mail folders, rendered under the Inbox sub-items.
// Each folder links to /inbox?folder=<id>, which the inbox page resolves into
// a party (+ extra sender domains) filter. Counts are unread/total inbound.

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { usePathname, useSearchParams } from 'next/navigation'
import { FolderOpen, Settings2 } from 'lucide-react'
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

  useEffect(() => {
    let cancelled = false
    listMailFoldersWithCountsAction()
      .then((res) => {
        if (cancelled) return
        if (res.ok) setFolders(res.data)
      })
      .catch(() => { /* sidebar must never break navigation */ })
      .finally(() => { if (!cancelled) setLoaded(true) })
    return () => { cancelled = true }
  }, [pathname])

  // Nothing pinned yet: keep the sidebar quiet, but leave a way in.
  if (loaded && folders.length === 0) {
    return (
      <li>
        <ul className="mt-0.5">
          <li>
            <Link
              href="/inbox/folders"
              onClick={onNavigate}
              className="flex items-center gap-2 rounded-md py-1.5 pl-9 pr-2 text-xs text-muted-foreground hover:bg-accent hover:text-foreground"
            >
              <Settings2 className="h-3 w-3" />
              <span className="truncate">Add mail folder</span>
            </Link>
          </li>
        </ul>
      </li>
    )
  }

  if (!loaded) return null

  return (
    <li>
      <ul className="mt-0.5 space-y-0.5">
        <li className="pl-9 pr-2 pt-1 text-[10px] font-medium uppercase tracking-wide text-muted-foreground/70">
          Folders
        </li>

        {folders.map((f) => {
          const active = pathname === '/inbox' && activeId === f.id
          return (
            <li key={f.id}>
              <Link
                href={`/inbox?folder=${f.id}`}
                onClick={onNavigate}
                className={cn(
                  'flex items-center gap-2 rounded-md py-1.5 pl-9 pr-2 text-sm transition-colors',
                  active
                    ? 'bg-accent text-accent-foreground font-medium'
                    : 'text-muted-foreground hover:bg-accent hover:text-foreground',
                )}
                aria-current={active ? 'page' : undefined}
                title={f.partyName}
              >
                {f.color ? (
                  <span
                    className="h-2 w-2 shrink-0 rounded-full"
                    style={{ backgroundColor: f.color }}
                  />
                ) : (
                  <FolderOpen className="h-3.5 w-3.5 shrink-0" />
                )}
                <span className="flex-1 truncate">{f.name}</span>
                {f.total > 0 && (
                  <span className="tabular-nums text-xs text-muted-foreground">
                    {f.unread}/{f.total}
                  </span>
                )}
              </Link>
            </li>
          )
        })}

        <li>
          <Link
            href="/inbox/folders"
            onClick={onNavigate}
            className="flex items-center gap-2 rounded-md py-1.5 pl-9 pr-2 text-xs text-muted-foreground hover:bg-accent hover:text-foreground"
          >
            <Settings2 className="h-3 w-3" />
            <span className="truncate">Manage folders</span>
          </Link>
        </li>
      </ul>
    </li>
  )
}
