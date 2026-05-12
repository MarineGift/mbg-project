'use client';

import { useTranslations } from 'next-intl';
import { Calendar, DollarSign, TrendingUp, Tag } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { RelativeTime } from '@/components/common/relative-time';
import type { EngagementDetail } from '@/types/engagement';

interface Props {
  engagement: EngagementDetail;
}

export function EngagementInfoCard({ engagement }: Props) {
  const t = useTranslations('engagements.detail');

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="text-sm">{t('info')}</CardTitle>
      </CardHeader>
      <CardContent className="space-y-3 text-sm">
        <div className="grid grid-cols-2 gap-4">
          <Stat
            icon={<DollarSign className="h-3.5 w-3.5" />}
            label={t('value')}
            value={
              engagement.valueAmount != null
                ? `${engagement.valueCurrency} ${engagement.valueAmount.toLocaleString()}`
                : '—'
            }
          />
          <Stat
            icon={<TrendingUp className="h-3.5 w-3.5" />}
            label={t('probability')}
            value={`${engagement.probabilityPct}%`}
          />
          {engagement.weightedAmount != null && (
            <Stat
              icon={<DollarSign className="h-3.5 w-3.5" />}
              label={t('weighted')}
              value={`${engagement.valueCurrency} ${Math.round(engagement.weightedAmount).toLocaleString()}`}
            />
          )}
          {engagement.expectedCloseDate && (
            <Stat
              icon={<Calendar className="h-3.5 w-3.5" />}
              label={t('expectedClose')}
              value={new Date(engagement.expectedCloseDate).toLocaleDateString()}
            />
          )}
          {engagement.actualCloseDate && (
            <Stat
              icon={<Calendar className="h-3.5 w-3.5" />}
              label={t('actualClose')}
              value={new Date(engagement.actualCloseDate).toLocaleDateString()}
            />
          )}
          {engagement.source && (
            <Stat
              icon={<Tag className="h-3.5 w-3.5" />}
              label={t('source')}
              value={engagement.source}
            />
          )}
        </div>

        {engagement.description && (
          <div className="pt-3 border-t">
            <p className="text-xs text-muted-foreground mb-1">{t('description')}</p>
            <p className="text-sm whitespace-pre-wrap leading-relaxed">
              {engagement.description}
            </p>
          </div>
        )}

        {engagement.wonLostReason && (
          <div className="pt-3 border-t">
            <p className="text-xs text-muted-foreground mb-1">{t('wonLostReason')}</p>
            <p className="text-sm whitespace-pre-wrap leading-relaxed">
              {engagement.wonLostReason}
            </p>
          </div>
        )}

        <div className="pt-3 border-t text-xs text-muted-foreground">
          <span>{t('updatedAt')}: </span>
          <RelativeTime date={engagement.updatedAt} live={false} className="font-medium" />
        </div>
      </CardContent>
    </Card>
  );
}

function Stat({
  icon,
  label,
  value,
}: {
  icon: React.ReactNode;
  label: string;
  value: string;
}) {
  return (
    <div>
      <p className="text-xs text-muted-foreground flex items-center gap-1 mb-0.5">
        {icon}
        {label}
      </p>
      <p className="font-medium tabular-nums">{value}</p>
    </div>
  );
}
