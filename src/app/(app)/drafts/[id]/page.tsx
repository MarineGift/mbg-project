/**
 * app/(app)/drafts/[id]/page.tsx
 *
 * AI 초안 상세·편집 화면.
 *
 * Server Component:
 *   1. fetchDraftDetail로 모든 데이터 fetch (404 처리)
 *   2. 왼쪽 컬럼: 분류·자동발송·메타·원본 메일
 *   3. 오른쪽 컬럼: 편집기 + sticky 액션 바
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
        <div className="grid gap-4 lg:grid-cols-[1fr_1.4fr] max-w-7xl mx-auto">
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
