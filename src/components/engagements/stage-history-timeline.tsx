'use client';

import { useTranslations } from 'next-intl';
import { ArrowRight, Clock } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { RelativeTime } from '@/components/common/relative-time';
import type { EngagementStageHistoryItem } from '@/types/engagement';

interface Props {
  history: readonly EngagementStageHistoryItem[];
}

export function StageHistoryTimeline({ history }: Props) {
  const t = useTranslations('engagements.detail.history');

  if (history.length === 0) {
    return (
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-sm">{t('title')}</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-xs text-muted-foreground italic">{t('empty')}</p>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="text-sm">{t('title')}</CardTitle>
      </CardHeader>
      <CardContent>
        <ul className="relative space-y-3">
          <span
            aria-hidden
            className="absolute left-[10px] top-2 bottom-2 w-px bg-border"
          />
          {history.map((h) => (
            <li key={h.id} className="relative pl-7">
              <span
                aria-hidden
                className="absolute left-[6px] top-2 h-2 w-2 rounded-full bg-blue-500"
              />
              <div className="flex items-center gap-2 text-sm">
                <span className="text-muted-foreground">
                  {h.fromStageName ?? t('initial')}
                </span>
                <ArrowRight className="h-3 w-3 text-muted-foreground" />
                <span className="font-medium">{h.toStageName}</span>
              </div>
              <div className="flex items-center gap-2 mt-0.5 text-xs text-muted-foreground">
                <RelativeTime date={h.movedAt} live={false} />
                {h.durationSeconds != null && h.durationSeconds > 0 && (
                  <>
                    <span>·</span>
                    <span className="inline-flex items-center gap-1">
                      <Clock className="h-3 w-3" />
                      {formatDuration(h.durationSeconds)}
                    </span>
                  </>
                )}
              </div>
              {h.reason && (
                <p className="text-xs text-muted-foreground mt-1 italic">
                  {h.reason}
                </p>
              )}
            </li>
          ))}
        </ul>
      </CardContent>
    </Card>
  );
}

function formatDuration(seconds: number): string {
  if (seconds < 60) return `${seconds}s`;
  if (seconds < 3600) return `${Math.round(seconds / 60)}m`;
  if (seconds < 86_400) return `${Math.round(seconds / 3600)}h`;
  return `${Math.round(seconds / 86_400)}d`;
}
