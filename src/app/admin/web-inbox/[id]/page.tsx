'use client'

import { createClient } from '@supabase/supabase-js'
import Link from 'next/link'
import { useEffect, useState, useTransition } from 'react'
import { replyToSubmission } from '@/components/web/actions'

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

function webClient() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  )
}

export default function SubmissionDetailPage({
  params,
}: {
  params: { id: string }
}) {
  const [submission, setSubmission] = useState<Submission | null>(null)
  const [replies, setReplies] = useState<Reply[]>([])
  const [loading, setLoading] = useState(true)
  const [isPending, startTransition] = useTransition()

  useEffect(() => {
    const loadData = async () => {
      try {
        const sb = webClient()

        // Fetch submission
        const { data: sub } = await sb
          .schema('web')
          .from('submissions')
          .select('*')
          .eq('id', params.id)
          .single()

        // Fetch replies
        const { data: reps } = await sb
          .schema('web')
          .from('submission_replies')
          .select('*')
          .eq('submission_id', params.id)
          .order('created_at', { ascending: true })

        setSubmission(sub as Submission)
        setReplies(reps as Reply[])
      } catch (error) {
        console.error('Failed to load submission:', error)
      } finally {
        setLoading(false)
      }
    }

    loadData()
  }, [params.id])

  if (loading) {
    return (
      <div className="min-h-screen bg-slate-50 p-8 flex items-center justify-center">
        <p className="text-slate-600">로딩 중...</p>
      </div>
    )
  }

  if (!submission) {
    return (
      <div className="min-h-screen bg-slate-50 p-8">
        <div className="mx-auto max-w-4xl">
          <Link
            href="/admin/web-inbox"
            className="text-sm text-teal-600 hover:text-teal-700"
          >
            ← 목록으로
          </Link>
          <p className="mt-4 text-slate-600">제출을 찾을 수 없습니다.</p>
        </div>
      </div>
    )
  }

  const handleSubmitReply = async (formData: FormData) => {
    startTransition(async () => {
      try {
        await replyToSubmission({
          submission_id: params.id,
          subject: formData.get('subject') as string,
          body: formData.get('body') as string,
          sent_by: 'admin',
        })
        // Refresh replies
        const sb = webClient()
        const { data: reps } = await sb
          .schema('web')
          .from('submission_replies')
          .select('*')
          .eq('submission_id', params.id)
          .order('created_at', { ascending: true })
        setReplies(reps as Reply[])
        
        // Reset form
        const form = document.getElementById('reply-form') as HTMLFormElement
        form?.reset()
      } catch (error) {
        console.error('Failed to send reply:', error)
      }
    })
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
              </div>
            </div>
          </div>
        </div>

        {/* Timeline + Reply Form */}
        <div className="rounded-lg border border-slate-200 bg-white">
          {/* Existing Replies */}
          {replies.length > 0 && (
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
              {replies.length ? '추가 답변' : '답변 작성'}
            </h2>
            <form id="reply-form" action={handleSubmitReply} className="space-y-4">
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
          </div>
        </div>
      </div>
    </div>
  )
}
