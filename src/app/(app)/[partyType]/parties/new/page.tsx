/**
 * app/(app)/[module]/parties/new/page.tsx
 *
 * 거래처 생성 페이지 (Phase 2 write).
 *
 * URL의 module 세그먼트가 Phase 1 모듈이 아니면 404.
 * PartyForm을 'create' 모드로 렌더링.
 */

import { notFound } from 'next/navigation';
import { PartyForm } from '@/components/parties/party-form';
import { requireAuthOrRedirect } from '@/lib/auth';
import type { ModuleType } from '@/types/ai';

const PHASE_1_MODULES: readonly ModuleType[] = [
  'investor',
  'paper_mill',
  'partner',
  'customer',
  'filler_supplier',
] as const;

interface PageProps {
  params: Promise<{ partyType: string }>;
}

export default async function NewPartyPage({ params }: PageProps) {
  const { partyType: moduleParam } = await params;

  // URL의 module 세그먼트 검증
  if (!(PHASE_1_MODULES as readonly string[]).includes(moduleParam)) {
    notFound();
  }
  const module = moduleParam as ModuleType;

  // 인증 검증 (미인증 시 /login으로 redirect)
  await requireAuthOrRedirect();

  return (
    <div className="p-6 max-w-3xl mx-auto">
      <PartyForm mode="create" initialModule={module} />
    </div>
  );
}
