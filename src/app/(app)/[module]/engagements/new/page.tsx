import { notFound } from 'next/navigation';
import { EngagementForm } from '@/components/engagements/engagement-form';
import { fetchPartyDetail } from '@/lib/queries/party-detail';
import type { ModuleType } from '@/types/ai';

const PHASE_1_MODULES: readonly ModuleType[] = [
  'investor',
  'buyer',
  'partner',
  'customer',
] as const;

interface PageProps {
  params: Promise<{ module: string }>;
  searchParams: Promise<{ party?: string }>;
}

export default async function NewEngagementPage({ params, searchParams }: PageProps) {
  const { module } = await params;
  const { party: partyIdRaw } = await searchParams;

  if (!(PHASE_1_MODULES as readonly string[]).includes(module)) {
    notFound();
  }

  // party 쿼리가 있으면 거래처 검증 + 이름 표시. 없으면 인플레이스 선택은 향후.
  if (!partyIdRaw || !/^[0-9a-f-]{36}$/i.test(partyIdRaw)) {
    // Phase 1은 party 컨텍스트가 반드시 있어야 함 — 거래처에서 시작
    return (
      <div className="p-6 max-w-2xl mx-auto">
        <p className="text-sm text-muted-foreground">
          Create an engagement from a party page (e.g. <code>/{module}/parties/[id]</code>).
        </p>
      </div>
    );
  }

  const full = await fetchPartyDetail(partyIdRaw);
  if (!full || full.party.module !== module) {
    notFound();
  }

  return (
    <div className="p-6 max-w-3xl mx-auto">
      <EngagementForm
        mode="create"
        partyId={full.party.id}
        partyName={full.party.name}
        module={module as ModuleType}
        existing={null}
      />
    </div>
  );
}
