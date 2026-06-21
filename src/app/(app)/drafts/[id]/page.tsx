/**
 * app/(app)/drafts/[id]/page.tsx
 *
 * AI draft detail/edit screen.
 *
 * Server Component:
 *   1. fetch all data via fetchDraftDetail (404 handling)
 *   2. left column: classification, auto-send, meta, original email
 *   3. right column: editor + sticky action bar
 */

import { notFound } from 'next/navigation';
import { fetchDraftDetail } from '@/lib/queries/draft-detail';
import { DraftDetailHeader } from '@/components/drafts/draft-detail-header';
import { ClassificationPanel } from '@/components/drafts/classification-panel';
import { AutoSendPanel } from '@/components/drafts/auto-send-panel';
import { MetadataPanel } from '@/components/drafts/metadata-panel';
import { InboundEmailPanel } from '@/components/drafts/inbound-email-panel';
import { DraftEditor } from '@/components/drafts/draft-editor';
import { DraftActions } from '@/components/drafts/draft-actions';

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function DraftDetailPage({ params }: PageProps) {
  const { id } = await params;
  const draft = await fetchDraftDetail(id);
  if (!draft) {
    notFound();
  }

  const readOnly = draft.status !== 'pending_review';

  return (
    <div className="flex flex-col h-full">
      <DraftDetailHeader draft={draft} />

      <div className="flex-1 overflow-y-auto p-6">
        <div className="grid gap-4 lg:grid-cols-[1fr_1.4fr] max-w-app mx-auto">
          {/* Left column — context panels */}
          <div className="space-y-4">
            <ClassificationPanel draft={draft} />
            <AutoSendPanel autoSend={draft.autoSend} />
            <MetadataPanel draft={draft} />
            <InboundEmailPanel inbound={draft.inbound} />
          </div>

          {/* Right column — editor */}
          <div className="space-y-4">
            <DraftEditor draft={draft} readOnly={readOnly} />
            {readOnly && (
              <p className="text-xs text-muted-foreground px-3">
                This draft is {draft.status}; editing is disabled.
              </p>
            )}
          </div>
        </div>
      </div>

      <DraftActions draft={draft} />
    </div>
  );
}
