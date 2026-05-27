// t9c: thread merged view
import { notFound } from 'next/navigation';
import Link from 'next/link';
import { ArrowLeft } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { fetchCommunicationDetailV2, fetchMessagesInThread } from '@/lib/queries/communication-detail-v2';
import { listEmailTemplates } from '@/lib/queries/email-templates';
import { CommunicationDetailView } from '@/components/inbox/communication-detail-view';

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function InboxDetailPage({ params }: PageProps) {
  const { id } = await params;
  const root = await fetchCommunicationDetailV2(id);
  if (!root) notFound();

  // t9c: fetch all messages in the same thread (if threaded). Falls back to [root] if no thread_id.
  const thread = root.threadId
    ? await fetchMessagesInThread(root.threadId)
    : [root];

  // Defensive: if thread fetch returned empty (shouldn't happen, but be safe), use [root].
  const messages = thread.length > 0 ? thread : [root];

  const templates = await listEmailTemplates();

  return (
    <div className="p-6 max-w-4xl mx-auto space-y-4">
      <Button variant="ghost" size="sm" asChild>
        <Link href="/inbox">
          <ArrowLeft className="h-4 w-4 mr-1" />
          Back
        </Link>
      </Button>
      <CommunicationDetailView thread={messages} rootId={id} templates={templates} />
    </div>
  );
}