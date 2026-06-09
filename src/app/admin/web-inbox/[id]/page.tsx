import { createServerComponentClient } from '@supabase/auth-helpers-nextjs'
import { cookies } from 'next/headers'
import { notFound } from 'next/navigation'
import { DetailContent } from './detail-content'

export const revalidate = 0

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
  const { data: replies = [] } = await supabase
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

  return <DetailContent submission={submission} replies={replies} submissionId={params.id} />
}
