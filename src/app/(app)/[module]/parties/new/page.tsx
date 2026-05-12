import { notFound } from 'next/navigation';
import { PartyForm } from '@/components/parties/party-form';
import type { ModuleType } from '@/types/ai';

const PHASE_1_MODULES: readonly ModuleType[] = [
  'investor',
  'buyer',
  'partner',
  'customer',
] as const;

interface PageProps {
  params: Promise<{ module: string }>;
}

export default async function NewPartyPage({ params }: PageProps) {
  const { module } = await params;
  if (!(PHASE_1_MODULES as readonly string[]).includes(module)) {
    notFound();
  }
  return (
    <div className="p-6 max-w-3xl mx-auto">
      <PartyForm mode="create" initialModule={module as ModuleType} existing={null} />
    </div>
  );
}
