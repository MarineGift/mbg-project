/**
 * app/(app)/[module]/parties/new/page.tsx
 *
 * Party creation page (Phase 2 write).
 *
 * 404 if the URL module segment is not a Phase 1 module.
 * Renders PartyForm in 'create' mode.
 */

import { notFound } from 'next/navigation';
import { PartyForm } from '@/components/parties/party-form';
import { fetchInvestorTypeOptions } from '@/lib/queries/investor-types';
import { fetchInterestTagOptions } from '@/lib/queries/interest-tags';
import { fetchSectorOptions } from '@/lib/queries/sector-focus';
import { requireAuthOrRedirect } from '@/lib/auth';
import type { PartyTypeCode } from '@/types/ai';

const PHASE_1_MODULES: readonly PartyTypeCode[] = [
  'investor',
  'paper_mill',
  'partner',
  'customer',
  'filler_supplier',
  'self',
] as const;

interface PageProps {
  params: Promise<{ partyType: string }>;
}

export default async function NewPartyPage({ params }: PageProps) {
  const { partyType: moduleParam } = await params;

  // validate the URL module segment
  if (!(PHASE_1_MODULES as readonly string[]).includes(moduleParam)) {
    notFound();
  }
  const module = moduleParam as PartyTypeCode;

  // auth check (redirect to /login if not authenticated)
  await requireAuthOrRedirect();

  const investorTypeOptions =
    module === 'investor' ? await fetchInvestorTypeOptions() : [];
  const interestTagSuggestions = await fetchInterestTagOptions();
  const sectorSuggestions = await fetchSectorOptions();

  return (
    <div className="mx-auto max-w-app p-6">
      <PartyForm
        mode="create"
        initialPartyType={module}
        investorTypeOptions={investorTypeOptions}
        industryTagSuggestions={interestTagSuggestions}
        interestTagSuggestions={interestTagSuggestions}
        sectorSuggestions={sectorSuggestions}
      />
    </div>
  );
}
