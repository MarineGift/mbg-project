/**
 * app/(app)/[module]/parties/[id]/edit/page.tsx
 *
 * Party edit page (Phase 2 write).
 *
 * 404 if the URL module segment is not a Phase 1 module.
 * 404 if the party does not exist or belongs to another organization (blocked by RLS).
 * If the URL module differs from party.module, redirect to the correct module URL.
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
  const { partyType: urlModule, id } = (await params) as unknown as { partyType: string; id: string };

  // validate the URL module segment
  if (!(PHASE_1_MODULES as readonly string[]).includes(urlModule)) {
    notFound();
  }

  // auth check (redirect to /login if not authenticated)
  await requireAuthOrRedirect();

  // party fetch - RLS auto-applies organization isolation
  const full = await fetchPartyDetail(id);
  if (!full) {
    notFound();
  }

  // if URL module and party.partyType mismatch, redirect to the correct URL
  if (full.party.partyType !== urlModule) {
    redirect(`/${full.party.partyType}/parties/${id}/edit`);
  }

  return (
    <div className="p-6 max-w-3xl mx-auto">
      <PartyForm
        mode="edit"
        initialPartyType={full.party.partyType}
        existing={full.party}
      />
    </div>
  );
}
