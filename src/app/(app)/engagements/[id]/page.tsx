/**
 * app/(app)/engagements/[id]/page.tsx
 *
 * Engagement detail - accessed directly without a module segment.
 * Module is shown in the header.
 */

import { notFound } from 'next/navigation';
import { fetchEngagementDetail } from '@/lib/queries/engagements';
import { EngagementDetailHeader } from '@/components/engagements/engagement-detail-header';
import { EngagementInfoCard } from '@/components/engagements/engagement-info-card';
import { EngagementStageMover } from '@/components/engagements/engagement-stage-mover';
import { StageHistoryTimeline } from '@/components/engagements/stage-history-timeline';

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function EngagementDetailPage({ params }: PageProps) {
  const { id } = await params;
  const engagement = await fetchEngagementDetail(id);
  if (!engagement) {
    notFound();
  }

  return (
    <div className="flex flex-col h-full">
      <EngagementDetailHeader engagement={engagement} />

      <div className="flex-1 overflow-y-auto p-6">
        <div className="grid gap-4 lg:grid-cols-[1.4fr_1fr] max-w-7xl mx-auto">
          <div className="space-y-4">
            <EngagementInfoCard engagement={engagement} />
            <StageHistoryTimeline history={engagement.stageHistory} />
          </div>
          <div className="space-y-4">
            <EngagementStageMover engagement={engagement} />
          </div>
        </div>
      </div>
    </div>
  );
}
