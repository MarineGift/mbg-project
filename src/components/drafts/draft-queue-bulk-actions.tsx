'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { Check, X, XCircle, Loader2 } from 'lucide-react';
import { toast } from 'sonner';
import { Button } from '@/components/ui/button';
import { BulkRejectDialog } from './bulk-reject-dialog';
import { useUiStore } from '@/lib/stores/ui-store';
import { bulkApproveDrafts } from '@/lib/actions/drafts';
import { cn } from '@/lib/utils';

interface DraftQueueBulkActionsProps {
  /** all selectable draft ids visible on screen */
  allVisibleIds: readonly string[];
  /** ids to exclude from bulk actions because they're being edited (final_body_plain present) */
  editingIds: readonly string[];
  className?: string;
}

/**
 * Bulk action toolbar - shown only when at least one row is selected.
 *
 * Behavior:
 *   - Approve: calls bulkApproveDrafts. status='approved' only, does not send (safety).
 *   - Reject:  opens BulkRejectDialog -> bulkRejectDrafts.
 *   - rows being edited are auto-excluded + the user is notified.
 */
export function DraftQueueBulkActions({
  allVisibleIds,
  editingIds,
  className,
}: DraftQueueBulkActionsProps) {
  const t = useTranslations('drafts.bulk');
  const router = useRouter();
  const selectedIds = useUiStore((s) => s.selectedDraftIds);
  const clear = useUiStore((s) => s.clearDraftSelection);
  const [isApproving, startApprove] = useTransition();
  const [rejectOpen, setRejectOpen] = useState(false);

  const count = selectedIds.size;
  if (count === 0) return null;

  // set of ids being edited
  const editingSet = new Set(editingIds);
  // bulk action targets = selected ones that are not being edited
  const targetIds = Array.from(selectedIds).filter((id) => !editingSet.has(id));
  const hasEditingInSelection = Array.from(selectedIds).some((id) =>
    editingSet.has(id),
  );

  const handleApprove = () => {
    if (targetIds.length === 0) return;
    startApprove(async () => {
      const result = await bulkApproveDrafts(targetIds);
      const total = targetIds.length;
      const ok = result.succeeded.length;
      const failed = result.failed.length;

      if (ok > 0 && failed === 0) {
        toast.success(`Approved ${ok} of ${total}`);
      } else if (ok > 0 && failed > 0) {
        toast.warning(`Approved ${ok} of ${total} (${failed} skipped)`);
      } else {
        toast.error(`Approve failed. Already processed?`);
      }
      clear();
      router.refresh();
    });
  };

  return (
    <>
      <div
        className={cn(
          'sticky top-14 z-20 flex flex-wrap items-center gap-2 px-4 py-2 border-b bg-accent text-accent-foreground shadow-sm',
          className,
        )}
        role="region"
        aria-label="Bulk actions toolbar"
      >
        <span className="text-sm font-medium">
          {t('selected', { count })}
        </span>

        <div className="flex gap-2 ml-auto">
          <Button
            size="sm"
            onClick={handleApprove}
            disabled={targetIds.length === 0 || isApproving}
            title={hasEditingInSelection ? t('approveNote') : undefined}
          >
            {isApproving ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <Check className="h-4 w-4" />
            )}
            {t('approveSelected')}
          </Button>

          <Button
            size="sm"
            variant="destructive"
            onClick={() => setRejectOpen(true)}
            disabled={isApproving}
          >
            <X className="h-4 w-4" />
            {t('rejectSelected')}
          </Button>

          <Button
            size="sm"
            variant="ghost"
            onClick={clear}
            disabled={isApproving}
          >
            <XCircle className="h-4 w-4" />
            {t('clear')}
          </Button>
        </div>

        {hasEditingInSelection && (
          <p className="basis-full text-xs text-muted-foreground">
            {t('approveNote')}
          </p>
        )}

        {/* avoid unused warning */}
        <span hidden>{allVisibleIds.length}</span>
      </div>

      <BulkRejectDialog
        draftIds={Array.from(selectedIds)}
        open={rejectOpen}
        onOpenChange={setRejectOpen}
      />
    </>
  );
}
