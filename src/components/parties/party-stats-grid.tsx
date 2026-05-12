'use client';

import Link from 'next/link';
import { useTranslations } from 'next-intl';
import { Users, MessageCircle, Sparkles, Briefcase, CheckSquare } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import type { PartyDetail } from '@/types/party-detail';

interface Props {
  party: PartyDetail;
}

interface StatItem {
  key: keyof PartyDetail['counts'];
  labelKey: string;
  icon: typeof Users;
  href?: string;
  emphasized?: boolean;
}

export function PartyStatsGrid({ party }: Props) {
  const t = useTranslations('partyDetail.stats');

  const stats: StatItem[] = [
    { key: 'contacts', labelKey: 'contacts', icon: Users },
    { key: 'communications', labelKey: 'communications', icon: MessageCircle, href: `/inbox?party=${party.id}` },
    { key: 'pendingDrafts', labelKey: 'pendingDrafts', icon: Sparkles, href: `/drafts?party=${party.id}`, emphasized: party.counts.pendingDrafts > 0 },
    { key: 'openEngagements', labelKey: 'openEngagements', icon: Briefcase },
    { key: 'openTasks', labelKey: 'openTasks', icon: CheckSquare },
  ];

  return (
    <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
      {stats.map((s) => {
        const count = party.counts[s.key];
        const content = (
          <Card className={s.emphasized ? 'border-purple-500' : undefined}>
            <CardContent className="p-3">
              <div className="flex items-center gap-2 text-xs text-muted-foreground mb-1">
                <s.icon className="h-3.5 w-3.5" />
                {t(s.labelKey)}
              </div>
              <p className="text-xl font-semibold tabular-nums">{count}</p>
            </CardContent>
          </Card>
        );
        return s.href ? (
          <Link key={s.key} href={s.href} className="hover:opacity-80 transition-opacity">
            {content}
          </Link>
        ) : (
          <div key={s.key}>{content}</div>
        );
      })}
    </div>
  );
}
