import Link from 'next/link';
import { ArrowLeft } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { ModuleBadge } from '@/components/common/module-badge';
import type { EngagementDetail } from '@/types/engagement';
import { cn } from '@/lib/utils';

interface Props {
  engagement: EngagementDetail;
}

const STATUS_COLORS: Record<EngagementDetail['status'], string> = {
  open: 'bg-blue-500 text-blue-50',
  in_progress: 'bg-amber-500 text-amber-50',
  on_hold: 'bg-stone-500 text-stone-50',
  won: 'bg-emerald-500 text-emerald-50',
  lost: 'bg-muted text-muted-foreground',
  archived: 'bg-muted text-muted-foreground',
};

export function EngagementDetailHeader({ engagement }: Props) {
  return (
    <header className="border-b bg-background sticky top-0 z-20">
      <div className="px-6 py-3 border-b flex items-center gap-3">
        <Button asChild variant="ghost" size="icon" className="h-8 w-8">
          <Link
            href={`/${engagement.module}/engagements`}
            aria-label="Back to kanban"
          >
            <ArrowLeft className="h-4 w-4" />
          </Link>
        </Button>
        <ModuleBadge module={engagement.module} size="sm" />
        <span
          className={cn(
            'inline-flex items-center rounded-full px-2.5 py-1 text-xs font-medium',
            STATUS_COLORS[engagement.status],
          )}
        >
          {engagement.status}
        </span>
        {engagement.currentStageName && (
          <span
            className="inline-flex items-center rounded-full px-2.5 py-1 text-xs font-medium border"
            style={
              engagement.currentStageColor
                ? {
                    borderColor: engagement.currentStageColor,
                    color: engagement.currentStageColor,
                  }
                : undefined
            }
          >
            {engagement.currentStageName}
          </span>
        )}
      </div>
      <div className="px-6 py-4">
        <h1 className="text-2xl font-semibold truncate">{engagement.name}</h1>
        <p className="text-sm text-muted-foreground mt-1">
          <Link
            href={`/${engagement.partyModule}/parties/${engagement.partyId}`}
            className="hover:underline"
          >
            {engagement.partyName}
          </Link>
          {engagement.primaryContactName && (
            <span> · {engagement.primaryContactName}</span>
          )}
        </p>
      </div>
    </header>
  );
}
