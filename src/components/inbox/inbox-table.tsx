'use client';

import { useEffect, useState, useTransition } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import {
  Sparkles,
  Paperclip,
  Trash2,
  Loader2,
  AlertTriangle,
  Eye,
  Send,
  Ban,
  Globe,
} from 'lucide-react';
import { toast } from 'sonner';
import { ChannelDirectionIcon } from './channel-direction-icon';
import { InboxDeleteButton } from './inbox-delete-button';
import { addBlocklistEntry } from '@/lib/actions/email-blocklist';
import { PartyTypeBadge } from '@/components/common/party-type-badge';
import { RelativeTime } from '@/components/common/relative-time';
import { Checkbox } from '@/components/ui/checkbox';
import { Button } from '@/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { deleteCommunicationsBulk } from '@/app/actions/delete-communication';
import type { InboxRow } from '@/types/inbox';
import { cn } from '@/lib/utils';

/**
 * Open/read tracking map keyed by communication id.
 * Shape mirrors OpenStatus from @/lib/queries/open-status, declared locally so
 * this client component never imports the server-only module.
 */
type OpenStatusMap = Record<
  string,
  { firstOpenedAt: string | null; openCount: number }
>;

/**
 * Absolute time in the viewer's configured timeZone, 24h, no seconds: "2026-06-02 06:05".
 * Uses Intl.DateTimeFormat so the timestamp reflects the user's chosen IANA timezone
 * (app.users.timezone) rather than the browser's local zone. When timeZone is
 * undefined, the runtime default zone is used.
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

/**
 * Read/Sent indicator for an outbound row.
 *
 * Always shows an absolute timestamp in the viewer's timezone:
 *   - not opened  -> "Sent · <sent time>"   (the time we reliably know)
 *   - opened      -> "Read · <opened time>" (only when the tracking pixel loaded;
 *                    many webmail clients block pixels, so absence != not received)
 *
 * The timestamp renders only after mount to keep server markup (UTC) and client
 * markup (timezone-formatted) in agreement — no hydration mismatch.
 */
function ReadIndicator({
  sentAt,
  openedAt,
  openCount,
  timeZone,
}: {
  sentAt: string;
  openedAt: string | null;
  openCount: number;
  timeZone?: string;
}) {
  const [mounted, setMounted] = useState(false);
  useEffect(() => setMounted(true), []);

  const opened = openCount > 0 && !!openedAt;

  if (!opened) {
    return (
      <span className="inline-flex items-center gap-1 text-xs text-muted-foreground">
        <Send className="h-3 w-3" />
        Sent
        {mounted && sentAt && (
          <span className="font-normal">· {formatAbsolute(sentAt, timeZone)}</span>
        )}
      </span>
    );
  }

  return (
    <span className="inline-flex items-center gap-1 text-xs text-emerald-600 dark:text-emerald-400">
      <Eye className="h-3 w-3" />
      Read
      {mounted && openedAt && (
        <span className="text-muted-foreground font-normal">
          · {formatAbsolute(openedAt, timeZone)}
        </span>
      )}
    </span>
  );
}

/**
 * Blocking one of these by domain would cut off every other sender on the
 * same host, so a domain block is refused for them and reported instead.
 */
const FREE_MAIL = new Set([
  'gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com', 'icloud.com',
  'naver.com', 'daum.net', 'kakao.com', 'qq.com', '163.com', 'hanmail.net',
]);

type BlockKind = 'domain' | 'address';

interface Props {
  rows: readonly InboxRow[];
  /** Optional: read tracking per communication id. When provided, outbound rows show a Read/Sent indicator. */
  openStatuses?: OpenStatusMap;
  /** Viewer's configured display timezone (IANA). Falls back to runtime default when unset. */
  timeZone?: string;
}

export function InboxTable({ rows, openStatuses, timeZone }: Props) {
  const t = useTranslations('inbox');
  const tPreview = useTranslations('drafts.preview');

  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [bulkDialogOpen, setBulkDialogOpen] = useState(false);
  const [blockKind, setBlockKind] = useState<BlockKind | null>(null);
  const [isPending, startTransition] = useTransition();
  const router = useRouter();

  const allSelected = rows.length > 0 && selected.size === rows.length;
  const someSelected = selected.size > 0 && !allSelected;

  function toggleRow(id: string) {
    setSelected((prev) => {
      const next = new Set(prev);
      next.has(id) ? next.delete(id) : next.add(id);
      return next;
    });
  }

  function toggleAll() {
    if (allSelected) {
      setSelected(new Set());
    } else {
      setSelected(new Set(rows.map((r) => r.id)));
    }
  }

  /** What would actually be written to the blocklist, for the chosen scope. */
  function blockPatterns(kind: BlockKind): { patterns: string[]; refused: string[] } {
    const patterns = new Set<string>();
    const refused = new Set<string>();
    for (const r of rows) {
      if (!selected.has(r.id)) continue;
      const addr = (r.fromAddress ?? '').trim().toLowerCase();
      if (!addr.includes('@')) continue;
      if (kind === 'address') {
        patterns.add(addr);
        continue;
      }
      const domain = addr.split('@')[1] ?? '';
      if (!domain) continue;
      if (FREE_MAIL.has(domain)) refused.add(domain);
      else patterns.add(domain);
    }
    return {
      patterns: Array.from(patterns).sort(),
      refused: Array.from(refused).sort(),
    };
  }

  function handleBulkDeleteAndBlock() {
    if (!blockKind) return;
    const kind = blockKind;
    const ids = Array.from(selected);
    const { patterns } = blockPatterns(kind);

    startTransition(async () => {
      let blocked = 0;
      const already: string[] = [];
      const failed: string[] = [];
      for (const pattern of patterns) {
        const res = await addBlocklistEntry(pattern, kind, 'Blocked from Inbox');
        if (res.ok) blocked += 1;
        else if (/already/i.test(res.error ?? '')) already.push(pattern);
        else failed.push(pattern);
      }

      const { deleted, errors } = await deleteCommunicationsBulk(ids);
      if (deleted > 0) toast.success(`${deleted} message${deleted > 1 ? 's' : ''} deleted`);
      if (errors.length > 0) toast.error(`${errors.length} failed to delete`);
      if (blocked > 0) {
        toast.success(
          `${blocked} ${kind}${blocked > 1 ? 'es' : ''} blocked`.replace('domaines', 'domains'),
        );
      }
      if (already.length > 0) toast.info(`Already blocked: ${already.join(', ')}`);
      if (failed.length > 0) toast.error(`Could not block: ${failed.join(', ')}`);

      setSelected(new Set());
      setBlockKind(null);
      router.refresh();
    });
  }

  function handleBulkDelete() {
    const ids = Array.from(selected);
    startTransition(async () => {
      const { deleted, errors } = await deleteCommunicationsBulk(ids);
      if (deleted > 0) toast.success(`${deleted} message${deleted > 1 ? 's' : ''} deleted`);
      if (errors.length > 0) toast.error(`${errors.length} failed to delete`);
      setSelected(new Set());
      setBulkDialogOpen(false);
      router.refresh();
    });
  }

  return (
    <>
      {/* selection action bar */}
      {selected.size > 0 && (
        <div className="sticky top-0 z-10 flex flex-wrap items-center gap-2 sm:gap-3 px-3 sm:px-4 py-2 border-b bg-primary/5">
          <Checkbox
            checked={allSelected}
            onCheckedChange={toggleAll}
            aria-label="Select all"
          />
          <span className="text-sm font-medium">{selected.size} selected</span>
          <Button
            variant="destructive"
            size="sm"
            className="gap-1.5 ml-1"
            onClick={() => setBulkDialogOpen(true)}
            disabled={isPending}
          >
            <Trash2 className="h-3.5 w-3.5" />
            Delete Selected
          </Button>
          <Button
            variant="destructive"
            size="sm"
            className="gap-1.5"
            onClick={() => setBlockKind('domain')}
            disabled={isPending}
            title="Delete these messages and block the whole sending domain"
          >
            <Globe className="h-3.5 w-3.5" />
            Delete + block domain
          </Button>
          <Button
            variant="destructive"
            size="sm"
            className="gap-1.5"
            onClick={() => setBlockKind('address')}
            disabled={isPending}
            title="Delete these messages and block only these exact addresses"
          >
            <Ban className="h-3.5 w-3.5" />
            Delete + block address
          </Button>
          <Button variant="ghost" size="sm" onClick={() => setSelected(new Set())} disabled={isPending}>
            Cancel
          </Button>
        </div>
      )}

      {/* header selection row */}
      <div className="flex items-center gap-3 px-3 sm:px-4 py-2 border-b bg-muted/30">
        <Checkbox
          checked={allSelected}
          onCheckedChange={toggleAll}
          aria-label="Select all messages"
          className={someSelected ? 'opacity-50' : ''}
        />
        <span className="text-xs text-muted-foreground">
          {someSelected ? `${selected.size} of ${rows.length} selected` : 'Select all'}
        </span>
      </div>

      {/* message list */}
      <ul className="divide-y" aria-label={t('queueTitle')}>
        {rows.map((row) => {
          const isSelected = selected.has(row.id);
          const unread = row.direction === 'inbound' && !row.isRead;
          return (
            <li
              key={row.id}
              className={cn('relative group flex items-stretch', isSelected && 'bg-primary/5')}
            >
              {/* checkbox area - fully separated from the Link */}
              <div
                className="flex items-center px-3 cursor-pointer shrink-0 hover:bg-muted/30"
                onClick={(e: React.MouseEvent) => {
                  e.preventDefault();
                  e.stopPropagation();
                  toggleRow(row.id);
                }}
              >
                <Checkbox
                  checked={isSelected}
                  onCheckedChange={() => toggleRow(row.id)}
                  aria-label={`Select: ${row.subject ?? 'no subject'}`}
                  onClick={(e: React.MouseEvent) => e.stopPropagation()}
                />
              </div>

              {/* main content - Link */}
              <Link
                href={`/inbox/${row.id}`}
                className="flex-1 block hover:bg-muted/40 transition-colors pr-10 min-w-0"
              >
                <div className="flex items-start gap-3 px-2 py-3">
                  <ChannelDirectionIcon
                    channel={row.channel}
                    direction={row.direction}
                    className="mt-0.5 shrink-0"
                  />
                  <div className="flex-1 min-w-0">
                    <div className="flex flex-wrap items-start gap-2 mb-0.5">
                      {unread && (
                        <span
                          className="mt-1 h-2 w-2 rounded-full bg-purple-500 shrink-0"
                          aria-label="Unread"
                        />
                      )}
                      <p className={cn('text-sm truncate flex-1 min-w-0', unread ? 'font-semibold text-foreground' : 'font-medium')}>
                        {row.partyName ?? row.fromName ?? row.fromAddress ?? tPreview('noParty')}
                      </p>
                      {row.partyTypeCode && <PartyTypeBadge partyType={row.partyTypeCode} size="sm" />}
                      <RelativeTime
                        date={row.occurredAt}
                        className="text-xs text-muted-foreground whitespace-nowrap"
                      />
                    </div>
                    <p className={cn('text-sm truncate', row.subject ? (unread ? 'font-semibold' : 'font-medium') : 'text-muted-foreground italic')}>
                      {row.subject ?? t('noSubject')}
                      {row.threadCount > 1 && (
                        <span className="ml-1.5 text-xs text-muted-foreground font-normal">({row.threadCount})</span>
                      )}
                    </p>
                    {row.bodyPreview && (
                      <p className="text-xs text-muted-foreground line-clamp-1 mt-0.5">{row.bodyPreview}</p>
                    )}
                    <div className="flex items-center gap-2 mt-1">
                      {openStatuses && row.direction === 'outbound' && (
                        <ReadIndicator
                          sentAt={row.occurredAt}
                          openedAt={openStatuses[row.id]?.firstOpenedAt ?? null}
                          openCount={openStatuses[row.id]?.openCount ?? 0}
                          timeZone={timeZone}
                        />
                      )}
                      {row.hasDraft && (
                        <span className="inline-flex items-center gap-1 text-xs text-purple-600 dark:text-purple-400">
                          <Sparkles className="h-3 w-3" />{t('aiDraft')}
                        </span>
                      )}
                      {row.aiGenerated && row.direction === 'outbound' && (
                        <span className="inline-flex items-center gap-1 text-xs text-emerald-600 dark:text-emerald-400">
                          <Sparkles className="h-3 w-3" />{t('aiSent')}
                        </span>
                      )}
                      {row.attachmentCount > 0 && (
                        <span className="inline-flex items-center gap-1 text-xs text-muted-foreground">
                          <Paperclip className="h-3 w-3" />{row.attachmentCount}
                        </span>
                      )}
                    </div>
                  </div>
                </div>
              </Link>

              {/* single delete */}
              <div className="absolute top-2.5 right-2">
                <InboxDeleteButton id={row.id} subject={row.subject} direction={row.direction} />
              </div>
            </li>
          );
        })}
      </ul>

      {/* delete + block confirmation dialog */}
      <Dialog
        open={blockKind !== null}
        onOpenChange={(open) => {
          if (!open) setBlockKind(null);
        }}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Ban className="h-5 w-5 text-destructive" />
              Delete and block by {blockKind === 'domain' ? 'domain' : 'address'}?
            </DialogTitle>
            <DialogDescription asChild>
              <div>
                <span className="block text-sm">
                  Deletes <strong>{selected.size}</strong> message{selected.size > 1 ? 's' : ''} and
                  blocks{' '}
                  {blockKind === 'domain'
                    ? 'everything from these domains'
                    : 'these exact addresses only'}
                  :
                </span>
                {blockKind && (
                  <span className="mt-2 block max-h-40 overflow-y-auto whitespace-pre-wrap rounded-md border bg-muted/30 px-3 py-2 font-mono text-xs">
                    {blockPatterns(blockKind).patterns.length > 0
                      ? blockPatterns(blockKind).patterns.join('\n')
                      : 'nothing to block'}
                  </span>
                )}
                {blockKind === 'domain' && blockPatterns('domain').refused.length > 0 && (
                  <span className="mt-2 block text-sm text-amber-600">
                    Skipped, because blocking these would cut off every other sender on
                    the same host: {blockPatterns('domain').refused.join(', ')}. Use
                    block by address for those.
                  </span>
                )}
                <span className="mt-2 block text-sm text-muted-foreground">
                  Reviewable in Settings, Email blocklist.
                </span>
                <span className="mt-2 block text-sm font-medium text-destructive">
                  The deletion cannot be undone.
                </span>
              </div>
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setBlockKind(null)} disabled={isPending}>
              Cancel
            </Button>
            <Button
              variant="destructive"
              onClick={handleBulkDeleteAndBlock}
              disabled={isPending}
            >
              {isPending ? (
                <><Loader2 className="h-4 w-4 animate-spin mr-2" />Working…</>
              ) : (
                'Delete and block'
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* bulk delete confirmation dialog */}
      <Dialog open={bulkDialogOpen} onOpenChange={setBulkDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <AlertTriangle className="h-5 w-5 text-destructive" />
              Delete {selected.size} message{selected.size > 1 ? 's' : ''}?
            </DialogTitle>
            <DialogDescription asChild>
              <div>
                <span className="block text-sm">
                  Permanently deletes <strong>{selected.size}</strong> message{selected.size > 1 ? 's' : ''}.
                  Inbound messages will also be removed from the mail server.
                </span>
                <span className="block mt-2 text-sm text-destructive font-medium">
                  This action cannot be undone.
                </span>
              </div>
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setBulkDialogOpen(false)} disabled={isPending}>
              Cancel
            </Button>
            <Button variant="destructive" onClick={handleBulkDelete} disabled={isPending}>
              {isPending ? (
                <><Loader2 className="h-4 w-4 animate-spin mr-2" />Deleting…</>
              ) : (
                `Delete ${selected.size}`
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
