'use client';

import Link from 'next/link';
import { ArrowLeft, Globe, MapPin, Building2, Pencil } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { ModuleBadge } from '@/components/common/module-badge';
import type { PartyDetail } from '@/types/party-detail';
import { cn } from '@/lib/utils';

interface Props {
  party: PartyDetail;
}

const TIER_LABELS: Record<NonNullable<PartyDetail['tier']>, string> = {
  tier_1: 'Tier 1',
  tier_2: 'Tier 2',
  tier_3: 'Tier 3',
  cold: 'Cold',
};

const TIER_COLORS: Record<NonNullable<PartyDetail['tier']>, string> = {
  tier_1: 'bg-amber-500 text-amber-50',
  tier_2: 'bg-slate-500 text-slate-50',
  tier_3: 'bg-stone-400 text-stone-50',
  cold: 'bg-muted text-muted-foreground',
};

const STATUS_COLORS: Record<PartyDetail['status'], string> = {
  active: 'text-emerald-600 dark:text-emerald-400',
  paused: 'text-amber-600 dark:text-amber-400',
  closed_won: 'text-blue-600 dark:text-blue-400',
  closed_lost: 'text-muted-foreground',
  archived: 'text-muted-foreground',
};

export function PartyHeader({ party }: Props) {
  // 서브타이틀: 산업 태그를 ' · '로 조인 (예: "Venture Capital · Growth Equity")
  const industryLine = party.industryTags.join(' · ');
  const hasAnyTag =
    party.industryTags.length > 0 || party.interestTags.length > 0;

  return (
    <header className="border-b bg-background">
      <div className="px-6 py-3 border-b flex items-center gap-3">
        <Button asChild variant="ghost" size="icon" className="h-8 w-8">
          <Link href={`/${party.module}/parties`} aria-label="Back">
            <ArrowLeft className="h-4 w-4" />
          </Link>
        </Button>
        <ModuleBadge module={party.module} size="sm" />
        {party.tier && (
          <span
            className={cn(
              'inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium',
              TIER_COLORS[party.tier],
            )}
          >
            {TIER_LABELS[party.tier]}
          </span>
        )}
        <span
          className={cn(
            'text-xs font-medium uppercase tracking-wide',
            STATUS_COLORS[party.status],
          )}
        >
          {party.status}
        </span>
        <Button asChild variant="outline" size="sm" className="ml-auto">
          <Link href={`/${party.module}/parties/${party.id}/edit`}>
            <Pencil className="h-3.5 w-3.5" />
            Edit
          </Link>
        </Button>
      </div>

      <div className="px-6 py-4">
        <h1 className="text-2xl font-semibold flex items-center gap-2">
          <Building2 className="h-6 w-6 text-muted-foreground" />
          {party.name}
        </h1>
        <div className="flex flex-wrap items-center gap-4 mt-2 text-sm text-muted-foreground">
          {industryLine && <span>{industryLine}</span>}
          {party.countryCode && (
            <span className="inline-flex items-center gap-1">
              <MapPin className="h-3 w-3" />
              {party.countryCode}
            </span>
          )}
          {party.website && (
            <a
              href={party.website}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-1 hover:text-foreground hover:underline"
            >
              <Globe className="h-3 w-3" />
              {party.website.replace(/^https?:\/\//, '')}
            </a>
          )}
        </div>
        {hasAnyTag && (
          <div className="flex flex-wrap gap-1 mt-2">
            {/* 산업 태그 — 회색 + 테두리 */}
            {party.industryTags.map((tag) => (
              <span
                key={`industry-${tag}`}
                className="inline-flex items-center rounded-full bg-muted text-muted-foreground border border-border px-2 py-0.5 text-xs"
                title="Industry"
              >
                {tag}
              </span>
            ))}
            {/* 관심 태그 — 파랑 */}
            {party.interestTags.map((tag) => (
              <span
                key={`interest-${tag}`}
                className="inline-flex items-center rounded-full bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300 px-2 py-0.5 text-xs"
                title="Interest"
              >
                {tag}
              </span>
            ))}
          </div>
        )}
      </div>
    </header>
  );
}
