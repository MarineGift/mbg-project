/**
 * app/(app)/engagements/[id]/edit/page.tsx
 *
 * Engagement edit page.
 *
 * Design decision: like the detail page (/engagements/[id]), accessed directly without
 * a module segment. existing.module is passed to the form, and partyId/partyName are also extracted from existing.
 */

import { notFound } from 'next/navigation';
import { EngagementForm } from '@/components/engagements/engagement-form';
import { fetchEngagementDetail } from '@/lib/queries/engagements';
import { requireAuthOrRedirect } from '@/lib/auth';

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function EditEngagementPage({ params }: PageProps) {
  const { id } = await params;

  // validate UUID format
  if (!/^[0-9a-f-]{36}$/i.test(id)) {
    notFound();
  }

  // authentication
  await requireAuthOrRedirect();

  // load engagement (RLS blocks -> null if missing or in another organization)
  const engagement = await fetchEngagementDetail(id);
  if (!engagement) {
    notFound();
  }

  return (
    <div className="p-6 max-w-3xl mx-auto">
      <EngagementForm
        mode="edit"
        partyType={engagement.partyType}
        existing={engagement}
      />
    </div>
  );
}
