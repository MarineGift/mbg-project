import { createServerComponentClient } from '@supabase/auth-helpers-nextjs'
import { cookies } from 'next/headers'
import Link from 'next/link'
import { ReactNode } from 'react'

export const revalidate = 0

interface Submission {
  id: string
  form_type: string
  name: string
  email: string
  company?: string
  interest?: string
  message: string
  status: 'new' | 'read' | 'replied' | 'archived' | 'spam'
  created_at: string
  source_host: string
}

const statusColors: Record<string, { bg: string; text: string }> = {
  new: { bg: 'bg-blue-100', text: 'text-blue-800' },
  read: { bg: 'bg-gray-100', text: 'text-gray-800' },
  replied: { bg: 'bg-green-100', text: 'text-green-800' },
  archived: { bg: 'bg-slate-100', text: 'text-slate-600' },
  spam: { bg: 'bg-red-100', text: 'text-red-800' },
}

const statusLabel: Record<string, string> = {
  new: '미읽음',
  read: '읽음',
  replied: '답변됨',
  archived: '보관됨',
  spam: '스팸',
}

export default async function WebInboxPage({
  searchParams,
}: {
  searchParams: { status?: string }
}) {
  const supabase = createServerComponentClient({ cookies })
  const status = searchParams.status || 'new'

  const { data: submissions } = await supabase
    .schema('web')
    .from('submissions')
    .select('*')
    .eq('status', status === 'all' ? undefined : status)
    .order('created_at', { ascending: false })
    .limit(50)

  const { data: counts } = await supabase
    .schema('web')
    .from('submissions')
    .select('status', { count: 'exact', head: true })

  // count by status (simple client-side for now)
  const countByStatus = {
    new: submissions?.filter(s => s.status === 'new').length || 0,
    read: submissions?.filter(s => s.status === 'read').length || 0,
    replied: submissions?.filter(s => s.status === 'replied').length || 0,
    all: submissions?.length || 0,
  }

  return (
    <div className="min-h-screen bg-slate-50 p-8">
      <div className="mx-auto max-w-6xl">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-4xl font-bold text-slate-900">웹사이트 제출 관리</h1>
          <p className="mt-2 text-slate-600">
            마린비오 그룹 공개 웹사이트에서 들어온 모든 폼 제출을 한 곳에서 관리합니다.
          </p>
        </div>

        {/* Filter Tabs */}
        <div className="mb-6 flex gap-2 border-b border-slate-200">
          {['new', 'read', 'replied', 'all'].map(tab => (
            <Link
              key={tab}
              href={`/admin/web-inbox?status=${tab}`}
              className={`px-4 py-2 text-sm font-medium ${
                status === tab
                  ? 'border-b-2 border-teal-500 text-teal-600'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              {tab === 'all' ? '전체' : statusLabel[tab]}
              {' '}({countByStatus[tab as keyof typeof countByStatus]})
            </Link>
          ))}
        </div>

        {/* Submissions List */}
        {submissions && submissions.length > 0 ? (
          <div className="space-y-3">
            {submissions.map((sub: Submission) => (
              <Link
                key={sub.id}
                href={`/admin/web-inbox/${sub.id}`}
                className="block rounded-lg border border-slate-200 bg-white p-4 hover:border-teal-300 hover:shadow-md transition"
              >
                <div className="flex items-start justify-between gap-4">
                  {/* Main Content */}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-3 mb-2">
                      {sub.status === 'new' && (
                        <span className="inline-block h-2 w-2 rounded-full bg-blue-500" />
                      )}
                      <h3 className="font-semibold text-slate-900 truncate">
                        {sub.name} {sub.company ? `(${sub.company})` : ''}
                      </h3>
                    </div>
                    <p className="text-sm text-slate-600 line-clamp-2">
                      {sub.message}
                    </p>
                    <div className="mt-2 flex flex-wrap gap-2 text-xs text-slate-500">
                      <span>{sub.email}</span>
                      {sub.interest && <span>•</span>}
                      {sub.interest && <span>{sub.interest}</span>}
                      <span>•</span>
                      <span>{new Date(sub.created_at).toLocaleDateString('ko-KR')}</span>
                    </div>
                  </div>

                  {/* Status Badge */}
                  <div className="flex flex-col items-end gap-2">
                    <span
                      className={`inline-block px-2.5 py-1 rounded text-xs font-medium ${
                        statusColors[sub.status].bg
                      } ${statusColors[sub.status].text}`}
                    >
                      {statusLabel[sub.status]}
                    </span>
                    <span className="text-xs text-slate-400">{sub.form_type}</span>
                  </div>
                </div>
              </Link>
            ))}
          </div>
        ) : (
          <div className="rounded-lg border border-dashed border-slate-300 bg-slate-50 p-8 text-center">
            <p className="text-slate-600">해당하는 제출이 없습니다.</p>
          </div>
        )}
      </div>
    </div>
  )
}
