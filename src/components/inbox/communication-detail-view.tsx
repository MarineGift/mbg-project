'use client';

import Link from 'next/link';
import { useTranslations } from 'next-intl';
import { Sparkles, ArrowRight, AlertCircle } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { ChannelDirectionIcon } from './channel-direction-icon';
import { ModuleBadge } from '@/components/common/module-badge';
import { RelativeTime } from '@/components/common/relative-time';
import { StatusBadge } from '@/components/common/status-badge';
import { ConfidenceBar } from '@/components/common/confidence-bar';
import type { CommunicationDetail } from '@/types/communication-detail';
import type { DraftStatus } from '@/types/ai';

interface Props {
  comm: CommunicationDetail;
}

export function CommunicationDetailView({ comm }: Props) {
  const t = useTranslations('inbox.detail');
  const tCat = useTranslations('classificationCategory');

  return (
    <div className="space-y-4">
      {/* Header card */}
      <Card>
        <CardHeader className="pb-3">
          <div className="flex items-center gap-3 mb-2">
            <ChannelDirectionIcon channel={comm.channel} direction={comm.direction} />
            <span className="text-xs text-muted-foreground uppercase tracking-wide">
              {comm.channel} · {comm.direction}
            </span>
            {comm.party && <ModuleBadge partyType={comm.party.partyType} size="sm" />}
            {comm.status === 'failed' && (
              <span className="inline-flex items-center gap-1 text-xs text-destructive">
                <AlertCircle className="h-3 w-3" />
                {t('failed')}
              </span>
            )}
          </div>
          <CardTitle className="text-base">
            {comm.subject ?? <span className="italic text-muted-foreground">{t('noSubject')}</span>}
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <div className="grid grid-cols-[auto_1fr] gap-x-3 gap-y-1 text-xs">
            <span className="text-muted-foreground">{t('from')}</span>
            <span className="font-mono truncate">
              {comm.fromName ? `${comm.fromName} <${comm.fromAddress ?? ''}>` : comm.fromAddress ?? '—'}
            </span>
            <span className="text-muted-foreground">{t('to')}</span>
            <span className="font-mono truncate">{comm.toAddresses.join(', ') || '—'}</span>
            {comm.ccAddresses.length > 0 && (
              <>
                <span className="text-muted-foreground">{t('cc')}</span>
                <span className="font-mono truncate">{comm.ccAddresses.join(', ')}</span>
              </>
            )}
            <span className="text-muted-foreground">{t('when')}</span>
            <RelativeTime date={comm.occurredAt} className="font-medium" live={false} />
            {comm.party && (
              <>
                <span className="text-muted-foreground">{t('party')}</span>
                <Link
                  href={`/${comm.party.partyType}/parties/${comm.party.id}`}
                  className="text-primary hover:underline truncate"
                >
                  {comm.party.name}
                </Link>
              </>
            )}
            {comm.messageId && (
              <>
                <span className="text-muted-foreground">{t('messageId')}</span>
                <span className="font-mono text-[10px] truncate" title={comm.messageId}>
                  {comm.messageId}
                </span>
              </>
            )}
            {comm.threadId && (
              <>
                <span className="text-muted-foreground">{t('threadId')}</span>
                <span className="font-mono text-[10px] truncate">{comm.threadId}</span>
              </>
            )}
            {comm.errorMessage && (
              <>
                <span className="text-muted-foreground">Error</span>
                <span className="text-destructive">{comm.errorMessage}</span>
              </>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Body */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-sm">{t('body')}</CardTitle>
        </CardHeader>
        <CardContent>
          {comm.bodyPlain ? (
            <div className="rounded-md bg-muted/30 p-3 text-sm whitespace-pre-wrap font-mono leading-relaxed max-h-[500px] overflow-y-auto scrollbar-thin">
              {comm.bodyPlain}
            </div>
          ) : (
            <p className="text-sm text-muted-foreground italic">{t('noBody')}</p>
          )}
        </CardContent>
      </Card>

      {/* Related AI drafts (inbound case) */}
      {comm.direction === 'inbound' && comm.generatedDrafts.length > 0 && (
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-sm flex items-center gap-2">
              <Sparkles className="h-4 w-4 text-purple-600" />
              {t('generatedDrafts')}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <ul className="space-y-2">
              {comm.generatedDrafts.map((d) => (
                <li key={d.id}>
                  <Link
                    href={`/drafts/${d.id}`}
                    className="flex items-center gap-2 p-2 rounded hover:bg-muted/40 transition-colors"
                  >
                    <StatusBadge status={d.status as DraftStatus} size="sm" />
                    {d.classificationCategory && (
                      <span className="text-xs text-muted-foreground">
                        {tCat(d.classificationCategory as Parameters<typeof tCat>[0])}
                      </span>
                    )}
                    {d.confidenceScore != null && (
                      <ConfidenceBar value={d.confidenceScore} className="w-24" />
                    )}
                    <ArrowRight className="h-4 w-4 text-muted-foreground ml-auto" />
                  </Link>
                </li>
              ))}
            </ul>
          </CardContent>
        </Card>
      )}

      {/* AI-generated outbound info */}
      {comm.direction === 'outbound' && comm.aiDraftId && (
        <Card>
          <CardContent className="pt-6">
            <Button asChild variant="outline" size="sm">
              <Link href={`/drafts/${comm.aiDraftId}`}>
                <Sparkles className="h-4 w-4" />
                {t('viewSourceDraft')}
                <ArrowRight className="h-4 w-4" />
              </Link>
            </Button>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
