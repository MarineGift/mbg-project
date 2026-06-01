/**
 * app/(app)/[module]/engagements/new/page.tsx
 *
 * New engagement creation page.
 *
 * Requirements:
 *   - 404 if the URL module segment is not a Phase 1 module
 *   - ?partyId=... query param required (an engagement must belong to a party)
 *   - the partyId's party must exist and its module must match the URL module
 *   - 404 if any of the above conditions fail
 *
 * Usage example:
 *   /buyer/engagements/new?partyId=22f9d3dd-6691-4cbf-80d5-adff7b8bec45
 *   -> form to add a new engagement to UPM-Kymmene
 */

import { notFound } from 'next/navigation';
import { EngagementForm } from '@/components/engagements/engagement-form';
import { fetchPartyDetail } from '@/lib/queries/party-detail';
import { requireAuthOrRedirect } from '@/lib/auth';
import type { PartyTypeCode } from '@/types/ai';

const PHASE_1_MODULES: readonly PartyTypeCode[] = [
  'investor',
  'paper_mill',
  'partner',
  'customer',
  'filler_supplier',
] as const;

interface PageProps {
  params: Promise<{ partyType: string }>;
  searchParams: Promise<{ partyId?: string }>;
}

export default async function NewEngagementPage({
  params,
  searchParams,
}: PageProps) {
  // 1. validate URL module
  const { partyType: urlModule } = await params;
  if (!(PHASE_1_MODULES as readonly string[]).includes(urlModule)) {
    notFound();
  }
  const module = urlModule as PartyTypeCode;

  // 2. authentication
  await requireAuthOrRedirect();

  // 3. validate partyId query param
  const { partyId } = await searchParams;
  if (!partyId || !/^[0-9a-f-]{36}$/i.test(partyId)) {
    notFound();
  }

  // 4. verify party exists + module matches
  const full = await fetchPartyDetail(partyId);
  if (!full || full.party.partyType !== module) {
    notFound();
  }

  return (
    <div className="p-6 max-w-3xl mx-auto">
      <EngagementForm
        mode="create"
        partyType={module}
        partyId={full.party.id}
        partyName={full.party.name}
        existing={null}
      />
    </div>
  );
}
