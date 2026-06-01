'use client';

import { useState, useTransition } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { Sparkles, Paperclip, Trash2, Loader2, AlertTriangle } from 'lucide-react';
import { toast } from 'sonner';
import { ChannelDirectionIcon } from './channel-direction-icon';
import { InboxDeleteButton } from './inbox-delete-button';
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

interface Props {
  rows: readonly InboxRow[];
}

export function InboxTable({ rows }: Props) {
  const t = useTranslations('inbox');
  const tPreview = useTranslations('drafts.preview');

  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [bulkDialogOpen, setBulkDialogOpen] = useState(false);
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
