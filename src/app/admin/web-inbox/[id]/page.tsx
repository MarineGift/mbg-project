import { createServerComponentClient } from '@supabase/auth-helpers-nextjs'
import { cookies } from 'next/headers'
import { notFound, redirect } from 'next/navigation'
import Link from 'next/link'
import { replyToSubmission } from '@/src/components/web/actions'
import { use, useTransition } from 'react'

async function submitReply(submissionId: string, formData: FormData) {
  'use server'
  const subject = formData.get('subject') as string
  const body = formData.get('body') as string

  await replyToSubmission({
    submission_id: submissionId,
    subject,
    body,
    sent_by: 'admin',
  })
  
  redirect(`/admin/web-inbox/${submissionId}`)
}

function ReplyForm({ submissionId }: { submissionId: string }) {
  const [isPending, startTransition] = useTransition()

  return (
    <form
      action={(formData) => startTransition(() => submitReply(submissionId, formData))}
      className="space-y-4"
    >
      <div>
        <label className="block text-sm font-medium text-slate-900">
          Subject
        </label>
        <input
          type="text"
          name="subject"
          placeholder="Re: ..."
          required
          disabled={isPending}
          className="mt-2 w-full rounded border border-slate-300 px-3 py-2 text-slate-900 placeholder-slate-400 focus:border-teal-500 focus:ring-teal-500 disabled:bg-slate-100"
        />
      </div>

      <div>
        <label className="block text-sm font-medium text-slate-900">
          Message
        </label>
        <textarea
          name="body"
          rows={6}
          placeholder="Your reply..."
          required
          disabled={isPending}
          className="mt-2 w-full rounded border border-slate-300 px-3 py-2 text-slate-900 placeholder-slate-400 focus:border-teal-500 focus:ring-teal-500 disabled:bg-slate-100"
        />
      </div>

      <div className="flex gap-3 pt-4">
        <button
          type="submit"
          disabled={isPending}
          className="rounded-lg bg-teal-600 px-4 py-2 text-sm font-semibold text-white hover:bg-teal-700 disabled:bg-slate-400"
        >
          {isPending ? '발송 중...' : 'Send Reply'}
        </button>
      </div>
    </form>
  )
}

export const revalidate = 0

interface Submission {
  id: string
  form_type: string
  site_id: string
  page_id?: string
  name: string
  email: string
  phone?: string
  company?: string
  interest?: string
  message: string
  data?: Record<string, unknown>
  status: 'new' | 'read' | 'replied' | 'archived' | 'spam'
  assigned_to?: string
  linked_party_id?: string
  source_host: string
  ip?: string
  user_agent?: string
  created_at: string
  updated_at?: string
}

interface Reply {
  id: string
  body: string
  subject: string
  sent_by: string
  email_message_id?: string
  status: string
  created_at: string
}

export default async function SubmissionDetailPage({
  params,
}: {
  params: { id: string }
}) {
  const supabase = createServerComponentClient({ cookies })

  // Fetch submission
  const { data: submission, error } = await supabase
    .schema('web')
    .from('submissions')
    .select('*')
    .eq('id', params.id)
    .single()

  if (error || !submission) notFound()

  // Fetch replies
  const { data: replies } = await supabase
    .schema('web')
    .from('submission_replies')
    .select('*')
    .eq('submission_id', params.id)
    .order('created_at', { ascending: true })

  // Mark as read if new
  if (submission.status === 'new') {
    await supabase
      .schema('web')
      .from('submissions')
      .update({ status: 'read' })
      .eq('id', params.id)
  }

  const statusColors: Record<string, string> = {
    new: 'bg-blue-100 text-blue-800',
    read: 'bg-gray-100 text-gray-800',
    replied: 'bg-green-100 text-green-800',
    archived: 'bg-slate-100 text-slate-600',
    spam: 'bg-red-100 text-red-800',
  }

  const statusLabel: Record<string, string> = {
    new: '미읽음',
    read: '읽음',
    replied: '답변됨',
    archived: '보관됨',
    spam: '스팸',
  }

  return (
    <div className="min-h-screen bg-slate-50 p-8">
      <div className="mx-auto max-w-4xl">
        {/* Header */}
        <div className="mb-8 flex items-center justify-between">
          <div>
            <Link
              href="/admin/web-inbox"
              className="text-sm text-teal-600 hover:text-teal-700 mb-4 inline-block"
            >
              ← 목록으로 돌아가기
            </Link>
            <h1 className="text-3xl font-bold text-slate-900">{submission.name}</h1>
            <p className="mt-1 text-slate-600">{submission.email}</p>
          </div>
          <span
            className={`inline-block px-3 py-1 rounded-full text-sm font-medium ${
              statusColors[submission.status]
            }`}
          >
            {statusLabel[submission.status]}
          </span>
        </div>

        {/* Submission Info */}
        <div className="mb-8 rounded-lg border border-slate-200 bg-white p-6">
          <div className="grid gap-6">
            {/* Key Fields */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-semibold text-slate-500 uppercase">
                  Form Type
                </label>
                <p className="mt-1 text-slate-900">{submission.form_type}</p>
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-500 uppercase">
                  Website
                </label>
                <p className="mt-1 text-slate-900">{submission.source_host}</p>
              </div>
              {submission.company && (
                <div>
                  <label className="block text-xs font-semibold text-slate-500 uppercase">
                    Company
                  </label>
                  <p className="mt-1 text-slate-900">{submission.company}</p>
                </div>
              )}
              {submission.phone && (
                <div>
                  <label className="block text-xs font-semibold text-slate-500 uppercase">
                    Phone
                  </label>
                  <p className="mt-1 text-slate-900">{submission.phone}</p>
                </div>
              )}
              {submission.interest && (
                <div className="col-span-2">
                  <label className="block text-xs font-semibold text-slate-500 uppercase">
                    Interest
                  </label>
                  <p className="mt-1 text-slate-900">{submission.interest}</p>
                </div>
              )}
            </div>

            {/* Message */}
            <div>
              <label className="block text-xs font-semibold text-slate-500 uppercase">
                Message
              </label>
              <p className="mt-2 whitespace-pre-wrap rounded bg-slate-50 p-4 text-slate-900">
                {submission.message}
              </p>
            </div>

            {/* Metadata */}
            <div className="border-t border-slate-200 pt-4 text-xs text-slate-500">
              <div className="grid grid-cols-3 gap-4">
                <div>
                  <span className="font-semibold">Submitted</span>
                  <p className="mt-1">
                    {new Date(submission.created_at).toLocaleString('ko-KR')}
                  </p>
                </div>
                {submission.ip && (
                  <div>
                    <span className="font-semibold">IP</span>
                    <p className="mt-1 font-mono text-xs">{submission.ip}</p>
                  </div>
                )}
                {submission.linked_party_id && (
                  <div>
                    <span className="font-semibold">CRM Party</span>
                    <p className="mt-1 font-mono text-xs truncate">
                      {submission.linked_party_id}
                    </p>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>

        {/* Timeline + Reply Form */}
        <div className="rounded-lg border border-slate-200 bg-white">
          {/* Existing Replies */}
          {replies && replies.length > 0 && (
            <div className="border-b border-slate-200 p-6">
              <h2 className="mb-6 text-lg font-semibold text-slate-900">답변 이력</h2>
              <div className="space-y-6">
                {replies.map((reply: Reply, idx: number) => (
                  <div key={reply.id}>
                    {idx > 0 && <div className="my-4 border-t border-slate-200" />}
                    <div className="flex gap-4">
                      <div className="flex h-10 w-10 items-center justify-center rounded-full bg-teal-100 flex-shrink-0">
                        <span className="text-sm font-semibold text-teal-700">
                          {reply.sent_by.charAt(0).toUpperCase()}
                        </span>
                      </div>
                      <div className="flex-1">
                        <div className="flex items-center gap-2">
                          <p className="font-semibold text-slate-900">
                            {reply.sent_by}
                          </p>
                          <time className="text-xs text-slate-500">
                            {new Date(reply.created_at).toLocaleString('ko-KR')}
                          </time>
                        </div>
                        <p className="mt-1 text-sm font-medium text-slate-700">
                          {reply.subject}
                        </p>
                        <p className="mt-2 whitespace-pre-wrap text-slate-700">
                          {reply.body}
                        </p>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Reply Form */}
          <div className="p-6">
            <h2 className="mb-6 text-lg font-semibold text-slate-900">
              {replies?.length ? '추가 답변' : '답변 작성'}
            </h2>
            <ReplyForm submissionId={params.id} />
          </div>
        </div>
      </div>
    </div>
  )
}
