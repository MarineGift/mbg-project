// t9c: thread merged view
'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useTranslations } from 'next-intl';
import {
  Sparkles, ArrowRight, AlertCircle,
  PenLine, FileText, ChevronDown, ChevronRight, Eye, Send,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';
import { ChannelDirectionIcon } from './channel-direction-icon';
import { PartyTypeBadge } from '@/components/common/party-type-badge';
import { RelativeTime } from '@/components/common/relative-time';
import { StatusBadge } from '@/components/common/status-badge';
import { ConfidenceBar } from '@/components/common/confidence-bar';
import { ComposeEmailDialog } from '@/components/email/compose-email-dialog';
import type { CommunicationDetail } from '@/types/communication-detail';
import type { DraftStatus } from '@/types/ai';

/**
 * Absolute time in the viewer's configured timeZone, 24h, no seconds: "2026-06-02 06:05".
 * Deterministic across server/client because the IANA timeZone is explicit, so it is
 * safe to render directly (no hydration mismatch) as long as timeZone is provided.
 */
function formatAbsolute(iso: string, timeZone?: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return '';
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(d);
  const get = (t: string) => parts.find((p) => p.type === t)?.value ?? '';
  return `${get('year')}-${get('month')}-${get('day')} ${get('hour')}:${get('minute')}`;
}

interface Props {
  /** All messages in the thread, sorted by occurredAt ASC. */
  thread: CommunicationDetail[];
  /** ID of the originally clicked message (default-expanded along with latest). */
  rootId: string;
  templates?: unknown[];
  /** Per-communication open/read tracking (outbound only), keyed by message id. */
  openStatuses?: Record<string, { firstOpenedAt: string | null; openCount: number }>;
  /** Viewer's configured display timezone (IANA). Falls back to runtime default when unset. */
  timeZone?: string;
}

export function CommunicationDetailView({ thread, rootId, templates, openStatuses, timeZone }: Props) {
  const t = useTranslations('inbox.detail');
  const tCat = useTranslations('classificationCategory');

  // Latest message (last in ASC-sorted list)
  const latest = thread[thread.length - 1];
  const root = thread[0];

  // Default-expand: rootId (clicked entry) + latest message
  const [expanded, setExpanded] = useState<Set<string>>(() => {
    const s = new Set<string>();
    if (rootId) s.add(rootId);
    if (latest) s.add(latest.id);
    return s;
  });

  function toggle(id: string) {
    setExpanded((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }

  // Reply dialog state
  const [dialogOpen, setDialogOpen] = useState(false);
  const [initialTab, setInitialTab] = useState<'direct' | 'template' | 'ai'>('direct');
  function openReply(tab: 'direct' | 'template' | 'ai') {
    setInitialTab(tab);
    setDialogOpen(true);
  }

  // Thread-level context
  const partyContext = root?.party ?? latest?.party ?? null;
  const threadSubject = root?.subject ?? latest?.subject ?? '';
  const replyTarget = [...thread].reverse().find((m) => m.direction === 'inbound') ?? null;
  const isReplyable = replyTarget != null;

  return (
    <div className="space-y-3">
      {/* Thread header */}
      <div className="px-1 pb-1">
        <h1 className="text-lg font-semibold truncate">
          {threadSubject || <span className="italic text-muted-foreground">{t('noSubject')}</span>}
        </h1>
        <div className="flex items-center gap-2 mt-1 text-xs text-muted-foreground flex-wrap">
          {partyContext && <PartyTypeBadge partyType={partyContext.partyType} size="sm" />}
          {partyContext && (
            <Link
              href={`/${partyContext.partyType}/parties/${partyContext.id}`}
              className="hover:underline truncate text-primary"
            >
              {partyContext.name}
            </Link>
          )}
          <span className="ml-auto">
            {thread.length} {thread.length === 1 ? 'message' : 'messages'}
          </span>
        </div>
      </div>

      {/* Messages */}
      {thread.map((msg) => (
        <ThreadMessageCard
          key={msg.id}
          msg={msg}
          expanded={expanded.has(msg.id)}
          onToggle={() => toggle(msg.id)}
          openStatus={openStatuses?.[msg.id]}
          timeZone={timeZone}
        />
      ))}

      {/* Reply card (inbound latest only) */}
      {isReplyable && (
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-sm">Reply</CardTitle>
          </CardHeader>
          <CardContent className="flex flex-wrap gap-2 items-center">
            <Button onClick={() => openReply('direct')} variant="default" size="sm">
              <PenLine className="h-4 w-4 mr-1" />
              Write manually
            </Button>
            <Button onClick={() => openReply('ai')} variant="secondary" size="sm">
              <Sparkles className="h-4 w-4 mr-1" />
              Use AI draft
            </Button>
            <Button onClick={() => openReply('template')} variant="outline" size="sm">
              <FileText className="h-4 w-4 mr-1" />
              Use template
            </Button>
            {!replyTarget.party && (
              <span className="text-xs text-muted-foreground ml-1">
                Sender is not a registered party.
              </span>
            )}
          </CardContent>
        </Card>
      )}

      {/* Reply dialog mount (always; partyId optional) */}
      {isReplyable && (
        <ComposeEmailDialog
          open={dialogOpen}
          onOpenChange={setDialogOpen}
          mode="reply"
          initialTab={initialTab}
          partyId={replyTarget.party?.id ?? null}
          defaultTo={replyTarget.fromAddress ?? ''}
          defaultSubject={
            replyTarget.subject
              ? replyTarget.subject.toLowerCase().startsWith('re:')
                ? replyTarget.subject
                : `Re: ${replyTarget.subject}`
              : ''
          }
          replyToMessageId={replyTarget.messageId ?? undefined}
          threadId={replyTarget.threadId ?? undefined}
          originalCommunicationId={replyTarget.id}
          templates={templates ?? []}
        />
      )}
    </div>
  );
}

/* ============================================================
 * ThreadMessageCard - single collapsible message in the thread
 * ============================================================ */

interface ThreadMessageCardProps {
  msg: CommunicationDetail;
  expanded: boolean;
  onToggle: () => void;
  openStatus?: { firstOpenedAt: string | null; openCount: number };
  timeZone?: string;
}

function ThreadMessageCard({ msg, expanded, onToggle, openStatus, timeZone }: ThreadMessageCardProps) {
  const t = useTranslations('inbox.detail');
  const tCat = useTranslations('classificationCategory');
  const hasDrafts = msg.generatedDrafts && msg.generatedDrafts.length > 0;

  const previewText = (msg.bodyPlain ?? '').replace(/\s+/g, ' ').slice(0, 180);

  const opened = !!openStatus && openStatus.openCount > 0 && !!openStatus.firstOpenedAt;

  return (
    <Card className={cn(!expanded && 'hover:bg-muted/20 transition-colors')}>
      {/* Always-visible header (clickable to toggle) */}
      <button type="button" onClick={onToggle} className="w-full text-left block">
        <CardHeader className="pb-3">
          <div className="flex items-start gap-2">
            {expanded ? (
              <ChevronDown className="h-4 w-4 text-muted-foreground mt-0.5 shrink-0" />
            ) : (
              <ChevronRight className="h-4 w-4 text-muted-foreground mt-0.5 shrink-0" />
            )}
            <ChannelDirectionIcon channel={msg.channel} direction={msg.direction} />
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2 text-xs text-muted-foreground uppercase tracking-wide">
                <span>{msg.direction}</span>
                {msg.status === 'failed' && (
                  <span className="inline-flex items-center gap-1 text-destructive normal-case tracking-normal">
                    <AlertCircle className="h-3 w-3" />
                    {t('failed')}
                  </span>
                )}
                {/* Outbound: always show an absolute timestamp in the viewer timezone.
                    Opened (pixel loaded) -> Read . <opened time>, else -> Sent . <sent time>. */}
                {msg.direction === 'outbound' && (
                  opened ? (
                    <span className="inline-flex items-center gap-1 text-emerald-600 normal-case tracking-normal">
                      <Eye className="h-3 w-3" />
                      Read · {formatAbsolute(openStatus!.firstOpenedAt!, timeZone)}
                    </span>
                  ) : (
                    <span className="inline-flex items-center gap-1 normal-case tracking-normal">
                      <Send className="h-3 w-3" />
                      Sent · {formatAbsolute(msg.occurredAt, timeZone)}
                    </span>
                  )
                )}
                <span className="ml-auto normal-case tracking-normal">
                  <RelativeTime date={msg.occurredAt} live={false} />
                </span>
              </div>
              <div className="text-sm truncate mt-0.5">
                <span className="text-muted-foreground">
                  {msg.direction === 'inbound' ? t('from') : t('to')}:
                </span>{' '}
                <span className="font-mono">
                  {msg.direction === 'inbound'
                    ? (msg.fromName ? `${msg.fromName} <${msg.fromAddress ?? ''}>` : msg.fromAddress ?? '?')
                    : (msg.toAddresses.join(', ') || '?')}
                </span>
              </div>
              {!expanded && previewText && (
                <div className="text-xs text-muted-foreground truncate mt-0.5">
                  {previewText}
                </div>
              )}
            </div>
          </div>
        </CardHeader>
      </button>

      {/* Expanded content */}
      {expanded && (
        <CardContent className="space-y-3 pt-0">
          {/* Metadata grid */}
          <div className="grid grid-cols-[auto_1fr] gap-x-3 gap-y-1 text-xs">
            {msg.toAddresses.length > 0 && (
              <>
                <span className="text-muted-foreground">{t('to')}</span>
                <span className="font-mono truncate">{msg.toAddresses.join(', ')}</span>
              </>
            )}
            {msg.ccAddresses.length > 0 && (
              <>
                <span className="text-muted-foreground">{t('cc')}</span>
                <span className="font-mono truncate">{msg.ccAddresses.join(', ')}</span>
              </>
            )}
            {msg.messageId && (
              <>
                <span className="text-muted-foreground">{t('messageId')}</span>
                <span className="font-mono text-[10px] truncate" title={msg.messageId}>{msg.messageId}</span>
              </>
            )}
            {/* Outbound: explicit absolute sent time (always known). */}
            {msg.direction === 'outbound' && (
              <>
                <span className="text-muted-foreground">Sent</span>
                <span>{formatAbsolute(msg.occurredAt, timeZone)}</span>
              </>
            )}
            {msg.direction === 'outbound' && openStatus && (
              <>
                <span className="text-muted-foreground">Opened</span>
                <span>
                  {openStatus.openCount > 0 ? (
                    <span className="inline-flex items-center gap-1.5">
                      <Eye className="h-3.5 w-3.5 text-emerald-600" />
                      {openStatus.firstOpenedAt ? (
                        <span>{formatAbsolute(openStatus.firstOpenedAt, timeZone)}</span>
                      ) : (
                        <span>opened</span>
                      )}
                      <span className="text-muted-foreground">
                        ({openStatus.openCount} {openStatus.openCount === 1 ? 'open' : 'opens'})
                      </span>
                    </span>
                  ) : (
                    <span className="text-muted-foreground">Not opened yet</span>
                  )}
                </span>
              </>
            )}
            {msg.errorMessage && (
              <>
                <span className="text-muted-foreground">Error</span>
                <span className="text-destructive">{msg.errorMessage}</span>
              </>
            )}
          </div>

          {/* Body */}
          {msg.bodyPlain ? (
            <div className="rounded-md bg-muted/30 p-3 text-sm whitespace-pre-wrap font-mono leading-relaxed max-h-[500px] overflow-y-auto scrollbar-thin">
              {msg.bodyPlain}
            </div>
          ) : (
            <p className="text-sm text-muted-foreground italic">{t('noBody')}</p>
          )}

          {/* AI Drafts (inbound only) */}
          {msg.direction === 'inbound' && hasDrafts && (
            <div className="pt-2 border-t">
              <div className="text-xs font-medium mb-2 flex items-center gap-2">
                <Sparkles className="h-3.5 w-3.5 text-purple-600" />
                {t('generatedDrafts')}
              </div>
              <ul className="space-y-1">
                {msg.generatedDrafts.map((d) => (
                  <li key={d.id}>
                    <Link
                      href={`/drafts/${d.id}`}
                      className="flex items-center gap-2 p-1.5 rounded hover:bg-muted/40 transition-colors text-xs"
                    >
                      <StatusBadge status={d.status as DraftStatus} size="sm" />
                      {d.classificationCategory && (
                        <span className="text-muted-foreground">
                          {tCat(d.classificationCategory as Parameters<typeof tCat>[0])}
                        </span>
                      )}
                      {d.confidenceScore != null && (
                        <ConfidenceBar value={d.confidenceScore} className="w-24" />
                      )}
                      <ArrowRight className="h-3.5 w-3.5 text-muted-foreground ml-auto" />
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          )}

          {/* Outbound source draft link */}
          {msg.direction === 'outbound' && msg.aiDraftId && (
            <div className="pt-2 border-t">
              <Button asChild variant="outline" size="sm">
                <Link href={`/drafts/${msg.aiDraftId}`}>
                  <Sparkles className="h-3.5 w-3.5 mr-1" />
                  {t('viewSourceDraft')}
                  <ArrowRight className="h-3.5 w-3.5 ml-1" />
                </Link>
              </Button>
            </div>
          )}
        </CardContent>
      )}
    </Card>
  );
}
