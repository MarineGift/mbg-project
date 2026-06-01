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

  return (
    <div className="p-6 max-w-3xl mx-auto">
      <PartyForm mode="create" initialPartyType={module} />
    </div>
  );
}
