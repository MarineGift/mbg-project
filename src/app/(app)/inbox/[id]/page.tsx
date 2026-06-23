// t9c: thread merged view
import { notFound } from 'next/navigation';
import Link from 'next/link';
import { ArrowLeft } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { fetchCommunicationDetailV2, fetchMessagesInThread } from '@/lib/queries/communication-detail-v2';
import { listEmailTemplates } from '@/lib/queries/email-templates';
import { fetchOpenStatuses } from '@/lib/queries/open-status';
import { fetchCurrentUserProfile } from '@/lib/queries/user-profile';
import { DEFAULT_TIMEZONE } from '@/lib/constants/timezones';
import { CommunicationDetailView } from '@/components/inbox/communication-detail-view';
import { MarkThreadRead } from '@/components/inbox/mark-thread-read';

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

  const typed = messages as ReadonlyArray<{ id: string; direction: string }>;
  // Mark every inbound message in this thread read on view (client effect; the
  // server action filters to inbound + unread, so outbound/read ids are no-ops).
  const threadIds = typed.map((m) => m.id);
  // Outbound messages get open/read tracking ("Read time") from email_tracking.
  const outboundIds = typed.filter((m) => m.direction === 'outbound').map((m) => m.id);

  const [templates, openStatuses, profile] = await Promise.all([
    listEmailTemplates(),
    fetchOpenStatuses(outboundIds),
    fetchCurrentUserProfile(),
  ]);
  const timeZone = profile?.timezone ?? DEFAULT_TIMEZONE;

  return (
    <div className="p-4 sm:p-6 space-y-4">
      <MarkThreadRead ids={threadIds} />
      <Button variant="ghost" size="sm" asChild>
        <Link href="/inbox">
          <ArrowLeft className="h-4 w-4 mr-1" />
          Back
        </Link>
      </Button>
      <CommunicationDetailView
        thread={messages}
        rootId={id}
        templates={templates}
        openStatuses={openStatuses}
        timeZone={timeZone}
      />
    </div>
  );
}
