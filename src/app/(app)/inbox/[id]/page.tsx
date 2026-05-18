// src/app/(app)/inbox/[id]/page.tsx
import { notFound } from 'next/navigation';
import Link from 'next/link';
import { ArrowLeft } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { fetchCommunicationDetail } from '@/lib/queries/communications';
import { CommunicationDetailView } from '@/components/inbox/communication-detail-view';

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function InboxDetailPage({ params }: PageProps) {
  const { id } = await params;
  const comm = await fetchCommunicationDetail(id);
  if (!comm) notFound();
  return (
    <div className="p-6 max-w-4xl mx-auto space-y-4">
      <Button variant="ghost" size="sm" asChild>
        <Link href="/inbox">
          <ArrowLeft className="h-4 w-4 mr-1" />
          Back
        </Link>
      </Button>
      <CommunicationDetailView comm={comm!} />
    </div>
  );
}