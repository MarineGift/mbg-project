import Link from 'next/link';
import { ArrowLeft } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { StatusBadge } from '@/components/common/status-badge';
import { PartyTypeBadge } from '@/components/common/party-type-badge';
import { ExpiryCountdown } from './expiry-countdown';
import type { DraftDetail } from '@/types/draft-detail';

interface Props {
  draft: DraftDetail;
}

export function DraftDetailHeader({ draft }: Props) {
  const title =
    draft.finalSubject ??
    draft.subject ??
    draft.inbound?.subject ??
    '(no subject)';

  return (
    <header className="border-b bg-background sticky top-0 z-20">
      <div className="flex items-center gap-3 px-6 py-3 border-b">
        <Button asChild variant="ghost" size="icon" className="h-8 w-8">
          <Link href="/drafts" aria-label="Back to queue">
            <ArrowLeft className="h-4 w-4" />
          </Link>
        </Button>
        <div className="flex items-center gap-2 flex-1 min-w-0">
          <StatusBadge status={draft.status} size="sm" />
          {draft.partyType && <PartyTypeBadge partyType={draft.partyType} size="sm" />}
          {draft.status === 'pending_review' && (
            <ExpiryCountdown expiresAt={draft.expiresAt} />
          )}
        </div>
      </div>
      <div className="px-6 py-3">
        <h1 className="text-lg font-semibold truncate" title={title}>
          {title}
        </h1>
        {draft.party && (
          <p className="text-sm text-muted-foreground mt-0.5">
            {draft.party.name}
            {draft.engagement && ` · ${draft.engagement.name}`}
          </p>
        )}
      </div>
    </header>
  );
}
