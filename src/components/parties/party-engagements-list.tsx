'use client';

import Link from 'next/link';
import { useTranslations } from 'next-intl';
import { ArrowRight, Plus } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { RelativeTime } from '@/components/common/relative-time';
import type { PartyEngagement } from '@/types/party-detail';
import type { PartyTypeCode } from '@/types/ai';
import { cn } from '@/lib/utils';

interface Props {
  engagements: readonly PartyEngagement[];
  /** for the "+ Add Engagement" deep link */
  partyId: string;
  partyType: PartyTypeCode;
}

const STATUS_COLORS: Record<string, string> = {
  open: 'text-blue-600 dark:text-blue-400',
  in_progress: 'text-amber-600 dark:text-amber-400',
  closed_won: 'text-emerald-600 dark:text-emerald-400',
  closed_lost: 'text-muted-foreground',
  abandoned: 'text-muted-foreground',
  won: 'text-emerald-600 dark:text-emerald-400',
  lost: 'text-muted-foreground',
  on_hold: 'text-yellow-600 dark:text-yellow-400',
  archived: 'text-muted-foreground',
};

export function PartyEngagementsList({ engagements, partyId, partyType: module }: Props) {
  const t = useTranslations('partyDetail.engagements');

  return (
    <Card>
      <CardHeader className="pb-3 flex flex-row items-center justify-between space-y-0">
        <CardTitle className="text-sm">{t('title')}</CardTitle>
        <Button
          asChild
          size="sm"
          className="gap-1 bg-blue-600 hover:bg-blue-700 text-white"
          aria-label={t('addEngagement')}
        >
          <Link href={`/${module}/engagements/new?partyId=${partyId}`}>
            <Plus className="h-4 w-4" />
            <span className="text-xs">Add</span>
          </Link>
        </Button>
      </CardHeader>
      <CardContent>
        {engagements.length === 0 ? (
          <p className="text-xs text-muted-foreground italic">{t('empty')}</p>
        ) : (
          <ul className="space-y-2">
            {engagements.map((e) => (
              <li key={e.id}>
                <Link
                  href={`/engagements/${e.id}`}
                  className="block p-2 rounded hover:bg-muted/40 transition-colors"
                >
                  <div className="flex items-start gap-2">
                    <div className="flex-1 min-w-0">
                      <p className="font-medium text-sm truncate">{e.name}</p>
                      <div className="flex items-center gap-2 mt-0.5 text-xs">
                        <span
                          className={cn(
                            STATUS_COLORS[e.status] ?? 'text-muted-foreground',
                          )}
                        >
                          {e.status}
                        </span>
                        {e.stage && (
                          <>
                            <span className="text-muted-foreground">·</span>
                            <span className="text-muted-foreground">
                              {e.stage}
                            </span>
                          </>
                        )}
                        {e.valueAmount != null && (
                          <>
                            <span className="text-muted-foreground">·</span>
                            <span className="font-medium tabular-nums">
                              {e.valueCurrency}{' '}
                              {e.valueAmount.toLocaleString()}
                            </span>
                          </>
                        )}
                      </div>
                      <RelativeTime
                        date={e.updatedAt}
                        className="text-xs text-muted-foreground mt-0.5 block"
                        live={false}
                      />
                    </div>
                    <ArrowRight className="h-4 w-4 text-muted-foreground mt-0.5 shrink-0" />
                  </div>
                </Link>
              </li>
            ))}
          </ul>
        )}
      </CardContent>
    </Card>
  );
}
