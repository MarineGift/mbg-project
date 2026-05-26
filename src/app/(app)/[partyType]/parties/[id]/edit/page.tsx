/**
 * app/(app)/[module]/parties/[id]/edit/page.tsx
 *
 * 거래처 수정 페이지 (Phase 2 write).
 *
 * URL의 module 세그먼트가 Phase 1 모듈이 아니면 404.
 * party가 없거나 다른 organization에 속하면 (RLS가 차단) 404.
 * URL module과 party.module이 다르면 정확한 모듈 URL로 redirect.
 */

import { notFound, redirect } from 'next/navigation';
import { fetchPartyDetail } from '@/lib/queries/party-detail';
import { requireAuthOrRedirect } from '@/lib/auth';
import { PartyForm } from '@/components/parties/party-form';
import type { PartyTypeCode } from '@/types/ai';

const PHASE_1_MODULES: readonly PartyTypeCode[] = [
  'investor',
  'paper_mill',
  'partner',
  'customer',
  'filler_supplier',
] as const;

interface PageProps {
  params: Promise<{ module: string; id: string }>;
}

export default async function EditPartyPage({ params }: PageProps) {
  const { partyType: urlModule, id } = (await params) as { partyType: string; id: string };

  // URL의 module 세그먼트 검증
  if (!(PHASE_1_MODULES as readonly string[]).includes(urlModule)) {
    notFound();
  }

  // 인증 검증 (미인증 시 /login으로 redirect)
  await requireAuthOrRedirect();

  // party fetch — RLS가 organization 격리 자동 적용
  const full = await fetchPartyDetail(id);
  if (!full) {
    notFound();
  }

  // URL module과 party.partyType 불일치 시 정확한 URL로 redirect
  if (full.party.partyType !== urlModule) {
    redirect(`/${full.party.partyType}/parties/${id}/edit`);
  }

  return (
    <div className="p-6 max-w-3xl mx-auto">
      <PartyForm
        mode="edit"
        initialModule={full.party.partyType}
        existing={full.party}
      />
    </div>
  );
}
