'use client';

import Link from 'next/link';
import { useTranslations } from 'next-intl';
import { Sparkles, Paperclip } from 'lucide-react';
import { ChannelDirectionIcon } from './channel-direction-icon';
import { InboxDeleteButton } from './inbox-delete-button';
import { ModuleBadge } from '@/components/common/module-badge';
import { RelativeTime } from '@/components/common/relative-time';
import type { InboxRow } from '@/types/inbox';
import { cn } from '@/lib/utils';

interface Props {
  rows: readonly InboxRow[];
}

export function InboxTable({ rows }: Props) {
  const t = useTranslations('inbox');
  const tPreview = useTranslations('drafts.preview');

  return (
    <ul className="divide-y" aria-label={t('queueTitle')}>
      {rows.map((row) => (
        <li key={row.id} className="relative group">
          <Link
            href={`/inbox/${row.id}`}
            className="block hover:bg-muted/40 transition-colors pr-10"
          >
            <div className="flex items-start gap-3 px-4 py-3">
              <ChannelDirectionIcon
                channel={row.channel}
                direction={row.direction}
                className="mt-0.5"
              />

              <div className="flex-1 min-w-0">
                <div className="flex items-start gap-2 mb-0.5">
                  <p className="font-medium text-sm truncate flex-1">
                    {row.partyName ??
                      row.fromName ??
                      row.fromAddress ??
                      tPreview('noParty')}
                  </p>
                  {row.partyModule && (
                    <ModuleBadge module={row.partyModule} size="sm" />
                  )}
                  <RelativeTime
                    date={row.occurredAt}
                    className="text-xs text-muted-foreground whitespace-nowrap"
                  />
                </div>
                <p
                  className={cn(
                    'text-sm truncate',
                    row.subject ? 'font-medium' : 'text-muted-foreground italic',
                  )}
                >
                  {row.subject ?? t('noSubject')}
                </p>
                {row.bodyPreview && (
                  <p className="text-xs text-muted-foreground line-clamp-1 mt-0.5">
                    {row.bodyPreview}
                  </p>
                )}

                <div className="flex items-center gap-2 mt-1">
                  {row.hasDraft && (
                    <span
                      className="inline-flex items-center gap-1 text-xs text-purple-600 dark:text-purple-400"
                      title="AI draft generated"
                    >
                      <Sparkles className="h-3 w-3" />
                      {t('aiDraft')}
                    </span>
                  )}
                  {row.aiGenerated && row.direction === 'outbound' && (
                    <span
                      className="inline-flex items-center gap-1 text-xs text-emerald-600 dark:text-emerald-400"
                      title="AI-generated outbound"
                    >
                      <Sparkles className="h-3 w-3" />
                      {t('aiSent')}
                    </span>
                  )}
                  {row.attachmentCount > 0 && (
                    <span
                      className="inline-flex items-center gap-1 text-xs text-muted-foreground"
                      title={`${row.attachmentCount} attachments`}
                    >
                      <Paperclip className="h-3 w-3" />
                      {row.attachmentCount}
                    </span>
                  )}
                </div>
              </div>
            </div>
          </Link>

          {/* 삭제 버튼 — Link 바깥 절대 위치, hover 시 표시 */}
          <div className="absolute top-2.5 right-2">
            <InboxDeleteButton
              id={row.id}
              subject={row.subject}
              direction={row.direction}
            />
          </div>
        </li>
      ))}
    </ul>
  );
}
