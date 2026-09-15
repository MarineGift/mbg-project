// src/app/(app)/inbox/folders/page.tsx
//
// 2026-09-15 - management screen for pinned party mail folders.

import Link from 'next/link'
import { MailFolderManager } from '@/components/inbox/mail-folder-manager'

export default function MailFoldersPage() {
  return (
    <div className="flex h-full flex-col">
      <header className="border-b bg-background px-6 py-5">
        <Link href="/inbox" className="text-xs text-muted-foreground hover:underline">
          &lsaquo; Inbox
        </Link>
        <h1 className="mt-1 text-xl font-semibold">Mail folders</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Pin the parties that matter - Greentown Labs, Omya, Moorim - and their mail
          gets its own folder under Inbox in the sidebar.
        </p>
      </header>

      <div className="flex-1 overflow-y-auto px-6 py-6">
        <MailFolderManager />
      </div>
    </div>
  )
}
