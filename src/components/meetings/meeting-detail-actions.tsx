'use client'
// src/components/meetings/meeting-detail-actions.tsx
//
// 2026-09-14 — Edit / Delete controls for /meetings/[id].
// The detail page is a server component; this island owns the modal state.
// After a save it refreshes the RSC payload; after a delete it navigates back
// to the calendar (the row is soft-deleted, so the page would 404).

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Pencil, Trash2 } from 'lucide-react'
import { MeetingEditModal } from '@/components/meetings/meeting-edit-modal'
import { deleteMeetingAction } from '@/app/actions/meetings'

export function MeetingDetailActions({ meetingId }: { meetingId: string }) {
  const router = useRouter()
  const [editing,  setEditing]  = useState(false)
  const [deleting, setDeleting] = useState(false)
  const [error,    setError]    = useState<string | null>(null)

  async function handleDelete() {
    if (!window.confirm('Delete this meeting? It will be removed from the calendar and Today.')) return
    setDeleting(true)
    setError(null)
    try {
      const res = await deleteMeetingAction(meetingId)
      if (!res.ok) { setError(res.error); return }
      router.push('/calendar')
      router.refresh()
    } finally {
      setDeleting(false)
    }
  }

  return (
    <div className="flex items-center gap-2">
      <button
        type="button"
        onClick={() => setEditing(true)}
        className="inline-flex items-center gap-1 rounded-md border px-2.5 py-1 text-xs text-muted-foreground hover:bg-muted hover:text-foreground"
      >
        <Pencil className="h-3 w-3" />
        Edit
      </button>
      <button
        type="button"
        onClick={handleDelete}
        disabled={deleting}
        className="inline-flex items-center gap-1 rounded-md border px-2.5 py-1 text-xs text-muted-foreground hover:bg-red-50 hover:text-red-600 disabled:opacity-50"
      >
        <Trash2 className="h-3 w-3" />
        {deleting ? 'Deleting...' : 'Delete'}
      </button>
      {error && <span className="text-xs text-red-600">{error}</span>}

      <MeetingEditModal
        meetingId={editing ? meetingId : null}
        onClose={() => setEditing(false)}
        onSaved={() => router.refresh()}
        onDeleted={() => { router.push('/calendar'); router.refresh() }}
      />
    </div>
  )
}
