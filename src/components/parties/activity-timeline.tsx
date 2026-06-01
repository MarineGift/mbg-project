'use client';

import Link from 'next/link';
import { useTranslations } from 'next-intl';
import { Plus, Sparkles, AlertCircle } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { ChannelDirectionIcon } from '@/components/inbox/channel-direction-icon';
import { RelativeTime } from '@/components/common/relative-time';
import type { TimelineItem } from '@/types/party-detail';
import { cn } from '@/lib/utils';

interface Props {
  items: readonly TimelineItem[];
}

export function ActivityTimeline({ items }: Props) {
  const t = useTranslations('partyDetail.timeline');

  if (items.length === 0) {
    return (
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-sm">{t('title')}</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-xs text-muted-foreground italic text-center py-6">
            {t('empty')}
          </p>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="text-sm">{t('title')}</CardTitle>
      </CardHeader>
      <CardContent className="space-y-0">
        <ul className="relative">
          vertical line
          <span
            aria-hidden
            className="absolute left-[10px] top-2 bottom-2 w-px bg-border"
          />

          {items.map((item, idx) => (
            <li
              key={`${item.kind}-${item.id}`}
              className={cn(
                'relative pl-7 py-2',
                idx !== items.length - 1 && 'border-b border-border/40',
              )}
            >
              dot (shown on top of the line)
              <span
                aria-hidden
                className={cn(
                  'absolute left-[6px] top-3 h-2 w-2 rounded-full',
                  item.kind === 'communication'
                    ? 'bg-blue-500'
                    : 'bg-amber-500',
                )}
              />

              {item.kind === 'communication' ? (
                <CommunicationTimelineItem item={item} />
              ) : (
                <TaskTimelineItem item={item} />
              )}
            </li>
          ))}
        </ul>
      </CardContent>
    </Card>
  );
}

function CommunicationTimelineItem({
  item,
}: {
  item: Extract<TimelineItem, { kind: 'communication' }>;
}) {
  return (
    <Link
      href={`/inbox/${item.id}`}
      className="block hover:opacity-80 transition-opacity"
    >
      <div className="flex items-start gap-2">
        <ChannelDirectionIcon channel={item.channel} direction={item.direction} />
        <div className="flex-1 min-w-0">
          <p className="text-sm font-medium truncate">
            {item.subject ?? '(no subject)'}
          </p>
          {item.bodyPreview && (
            <p className="text-xs text-muted-foreground line-clamp-1 mt-0.5">
              {item.bodyPreview}
            </p>
          )}
          <div className="flex items-center gap-2 mt-1 text-xs text-muted-foreground">
            <RelativeTime date={item.occurredAt} live={false} />
            {item.aiGenerated && (
              <>
                <span>·</span>
                <span className="inline-flex items-center gap-1 text-emerald-600 dark:text-emerald-400">
                  <Sparkles className="h-3 w-3" />
                  AI
                </span>
              </>
            )}
            {item.status === 'failed' && (
              <span className="inline-flex items-center gap-1 text-destructive">
                <AlertCircle className="h-3 w-3" />
                failed
              </span>
            )}
          </div>
        </div>
      </div>
    </Link>
  );
}

function TaskTimelineItem({
  item,
}: {
  item: Extract<TimelineItem, { kind: 'task' }>;
}) {
  return (
    <div className="flex items-start gap-2">
      <Plus className="h-4 w-4 text-amber-600 dark:text-amber-400 mt-0.5 shrink-0" />
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium truncate">
          Task: {item.title}
        </p>
        <div className="flex items-center gap-2 mt-1 text-xs text-muted-foreground">
          <RelativeTime date={item.occurredAt} live={false} />
          <span>·</span>
          <span>{item.status}</span>
          {item.priority && (
            <>
              <span>·</span>
              <span>{item.priority}</span>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
