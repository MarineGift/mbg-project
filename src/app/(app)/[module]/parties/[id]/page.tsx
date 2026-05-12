/**
 * app/(app)/[module]/parties/[id]/page.tsx
 *
 * 거래처 상세 (Phase 1 read-only).
 *
 * URL의 module 세그먼트가 4 priority 모듈이 아니면 404.
 * URL module과 party.module이 다르면 정확한 모듈 URL로 redirect.
 */

import { notFound, redirect } from 'next/navigation';
import { fetchPartyDetail } from '@/lib/queries/party-detail';
import { PartyHeader } from '@/components/parties/party-header';
import { PartyStatsGrid } from '@/components/parties/party-stats-grid';
import { PartyContactsList } from '@/components/parties/party-contacts-list';
import { PartyEngagementsList } from '@/components/parties/party-engagements-list';
import { PartyTasksList } from '@/components/parties/party-tasks-list';
import { PartyNotesCard } from '@/components/parties/party-notes-card';
import { ActivityTimeline } from '@/components/parties/activity-timeline';
import type { ModuleType } from '@/types/ai';

const PHASE_1_MODULES: readonly ModuleType[] = [
  'investor',
  'buyer',
  'partner',
  'customer',
] as const;

interface PageProps {
  params: Promise<{ module: string; id: string }>;
}

export default async function PartyDetailPage({ params }: PageProps) {
  const { module: urlModule, id } = await params;

  // URL의 module 세그먼트 검증
  if (!(PHASE_1_MODULES as readonly string[]).includes(urlModule)) {
    notFound();
  }

  const full = await fetchPartyDetail(id);
  if (!full) {
    notFound();
  }

  // URL module과 party.module 불일치 시 정확한 URL로 redirect
  if (full.party.module !== urlModule) {
    redirect(`/${full.party.module}/parties/${id}`);
  }

  return (
    <div className="flex flex-col h-full">
      <PartyHeader party={full.party} />

      <div className="flex-1 overflow-y-auto p-6">
        <div className="max-w-7xl mx-auto space-y-6">
          <PartyStatsGrid party={full.party} />

          <div className="grid gap-4 lg:grid-cols-[1.4fr_1fr]">
            {/* Left: activity timeline + notes */}
            <div className="space-y-4">
              <ActivityTimeline items={full.timeline} />
              <PartyNotesCard notes={full.party.notes} />
            </div>

            {/* Right: contacts + engagements + tasks */}
            <div className="space-y-4">
              <PartyContactsList contacts={full.contacts} />
              <PartyEngagementsList engagements={full.engagements} />
              <PartyTasksList tasks={full.tasks} />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
