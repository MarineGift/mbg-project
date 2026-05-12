import { notFound } from 'next/navigation';
import { EngagementForm } from '@/components/engagements/engagement-form';
import { fetchEngagementDetail } from '@/lib/queries/engagements';

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function EditEngagementPage({ params }: PageProps) {
  const { id } = await params;
  const eng = await fetchEngagementDetail(id);
  if (!eng) notFound();
  return (
    <div className="p-6 max-w-3xl mx-auto">
      <EngagementForm mode="edit" module={eng.module} existing={eng} />
    </div>
  );
}
