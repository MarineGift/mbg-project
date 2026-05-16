'use client'
// src/components/industry/PromoteMillButton.tsx
// Phase 7-b-2/3: paper_mill industry detail → CRM party 승격 + 양방향 연결

import { useState } from 'react'
import { promoteMillToParty } from '@/app/actions/party'

interface Props {
  millId: number
  millName: string
  existingPartyId?: string | null
  existingPartyName?: string | null
}

export function PromoteMillButton({
  millId,
  millName,
  existingPartyId,
  existingPartyName,
}: Props) {
  const [loading, setLoading]     = useState(false)
  const [partyId, setPartyId]     = useState<string | null>(existingPartyId ?? null)
  const [partyName, setPartyName] = useState<string | null>(existingPartyName ?? null)
  const [error, setError]         = useState<string | null>(null)

  if (partyId) {
    return (
      <div className="flex items-center gap-2 rounded-md border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm dark:border-emerald-800 dark:bg-emerald-950/40">
        <span className="h-2 w-2 rounded-full bg-emerald-500" />
        <span className="text-emerald-700 dark:text-emerald-300">CRM Party 연결됨</span>
        <span className="font-medium text-emerald-600 dark:text-emerald-400">
          {partyName ?? millName}
        </span>
        <a
          href={`/paper_mill/parties/${partyId}`}
          className="ml-auto text-xs text-emerald-600 underline underline-offset-2 hover:text-emerald-800 dark:text-emerald-400"
        >
          Party 보기 →
        </a>
      </div>
    )
  }

  async function handlePromote() {
    setLoading(true)
    setError(null)
    const result = await promoteMillToParty(millId)

    if (result.success) {
      setPartyId(result.data.id)
      setPartyName(result.data.name)
    } else if (result.error === 'already_promoted' && 'party_id' in result) {
      setPartyId(result.party_id as string)
      setPartyName(('party_name' in result ? result.party_name : null) as string | null)
    } else {
      setError(result.error ?? 'Unknown error')
    }
    setLoading(false)
  }

  return (
    <div className="flex flex-col gap-1">
      <button
        onClick={handlePromote}
        disabled={loading}
        className={[
          'inline-flex items-center gap-2 rounded-md px-3 py-2 text-sm font-medium',
          'border border-dashed border-slate-300 text-slate-600',
          'hover:border-blue-400 hover:bg-blue-50 hover:text-blue-700',
          'dark:border-slate-600 dark:text-slate-400',
          'dark:hover:border-blue-500 dark:hover:bg-blue-950/40 dark:hover:text-blue-300',
          'transition-colors duration-150 disabled:cursor-not-allowed disabled:opacity-50',
        ].join(' ')}
      >
        {loading ? (
          <>
            <span className="h-3.5 w-3.5 animate-spin rounded-full border-2 border-current border-t-transparent" />
            승격 중…
          </>
        ) : (
          <>
            <PlusIcon />
            CRM Party로 승격
          </>
        )}
      </button>
      {error && <p className="text-xs text-red-500 dark:text-red-400">오류: {error}</p>}
    </div>
  )
}

function PlusIcon() {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24"
      fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M5 12h14" /><path d="M12 5v14" />
    </svg>
  )
}
