/**
 * app/(app)/[module]/engagements/new/page.tsx
 *
 * 새 engagement 생성 페이지.
 *
 * 요구사항:
 *   - URL의 module 세그먼트가 Phase 1 모듈이 아니면 404
 *   - ?partyId=... query param 필수 (engagement는 반드시 party에 속함)
 *   - partyId의 party가 존재하고 module이 URL module과 일치해야 함
 *   - 위 조건 중 하나라도 실패하면 404
 *
 * 사용 예:
 *   /buyer/engagements/new?partyId=22f9d3dd-6691-4cbf-80d5-adff7b8bec45
 *   → UPM-Kymmene에 새 engagement 추가하는 폼
 */

import { notFound } from 'next/navigation';
import { EngagementForm } from '@/components/engagements/engagement-form';
import { fetchPartyDetail } from '@/lib/queries/party-detail';
import { requireAuthOrRedirect } from '@/lib/auth';
import type { ModuleType } from '@/types/ai';

const PHASE_1_MODULES: readonly ModuleType[] = [
  'investor',
  'buyer',
  'partner',
  'customer',
] as const;

interface PageProps {
  params: Promise<{ module: string }>;
  searchParams: Promise<{ partyId?: string }>;
}

export default async function NewEngagementPage({
  params,
  searchParams,
}: PageProps) {
  // 1. URL module 검증
  const { module: urlModule } = await params;
  if (!(PHASE_1_MODULES as readonly string[]).includes(urlModule)) {
    notFound();
  }
  const module = urlModule as ModuleType;

  // 2. 인증
  await requireAuthOrRedirect();

  // 3. partyId query param 검증
  const { partyId } = await searchParams;
  if (!partyId || !/^[0-9a-f-]{36}$/i.test(partyId)) {
    notFound();
  }

  // 4. party 존재 + module 일치 검증
  const full = await fetchPartyDetail(partyId);
  if (!full || full.party.module !== module) {
    notFound();
  }

  return (
    <div className="p-6 max-w-3xl mx-auto">
      <EngagementForm
        mode="create"
        module={module}
        partyId={full.party.id}
        partyName={full.party.name}
        existing={null}
      />
    </div>
  );
}
