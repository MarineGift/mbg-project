import { ComposeForm } from '@/components/compose/compose-form';

interface PageProps {
  searchParams: Promise<{
    to?: string;
    subject?: string;
    party?: string;
    contact?: string;
    inReplyTo?: string;
    threadId?: string;
  }>;
}

export default async function ComposePage({ searchParams }: PageProps) {
  const params = await searchParams;
  return (
    <div className="p-6 max-w-3xl mx-auto">
      <ComposeForm
        defaultTo={params.to}
        defaultSubject={params.subject}
        partyId={params.party ?? null}
        contactId={params.contact ?? null}
        inReplyTo={params.inReplyTo ?? null}
        threadId={params.threadId ?? null}
      />
    </div>
  );
}
