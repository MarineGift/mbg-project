/**
 * app/(app)/inbox/[id]/page.tsx
 *
 * 단일 communication 상세.
 */

import Link from 'next/link';
import { notFound } from 'next/navigation';
import { ArrowLeft } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { fetchCommunicationDetail } from '@/lib/queries/communications';
import { CommunicationDetailView } from '@/components/inbox/communication-detail-view';

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function CommunicationDetailPage({ params }: PageProps) {
  const { id } = await params;
  const comm = await fetchCommunicationDetail(id);
  if (!comm) {
    notFound();
  }

  return (
    <div className="flex flex-col h-full">
      <header className="border-b bg-background sticky top-0 z-20 flex items-center gap-3 px-6 py-3">
        <Button asChild variant="ghost" size="icon" className="h-8 w-8">
          <Link href="/inbox" aria-label="Back to inbox">
            <ArrowLeft className="h-4 w-4" />
          </Link>
        </Button>
        <h1 className="text-lg font-semibold truncate">
          {comm.subject ?? '(no subject)'}
        </h1>
      </header>

      <div className="flex-1 overflow-y-auto p-6">
        <div className="max-w-4xl mx-auto">
          <CommunicationDetailView comm={comm} />
        </div>
      </div>
    </div>
  );
}
