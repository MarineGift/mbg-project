import { notFound } from 'next/navigation';
import { PartyForm } from '@/components/parties/party-form';
import { fetchPartyDetail } from '@/lib/queries/party-detail';
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

export default async function EditPartyPage({ params }: PageProps) {
  const { module, id } = await params;
  if (!(PHASE_1_MODULES as readonly string[]).includes(module)) {
    notFound();
  }
  const full = await fetchPartyDetail(id);
  if (!full) notFound();

  return (
    <div className="p-6 max-w-3xl mx-auto">
      <PartyForm
        mode="edit"
        initialModule={module as ModuleType}
        existing={full.party}
      />
    </div>
  );
}
