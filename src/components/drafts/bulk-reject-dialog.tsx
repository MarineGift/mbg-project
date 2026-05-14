'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { X, Loader2 } from 'lucide-react';
import { toast } from 'sonner';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { bulkRejectDrafts } from '@/lib/actions/drafts';
import { REJECT_REASONS } from '@/types/draft-detail';
import { useUiStore } from '@/lib/stores/ui-store';
import type { RejectReason } from '@/types/draft-detail';

interface Props {
  draftIds: readonly string[];
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

const REASON_LABELS: Record<RejectReason, string> = {
  outdated_request: 'Outdated / no longer relevant',
  off_topic: 'Off-topic for these contacts',
  wrong_tone: 'Wrong tone / register',
  incorrect_info: 'Contains incorrect information',
  other: 'Other (specify below)',
};

export function BulkRejectDialog({ draftIds, open, onOpenChange }: Props) {
  const router = useRouter();
  const clear = useUiStore((s) => s.clearDraftSelection);
  const [isPending, startTransition] = useTransition();
  const [reason, setReason] = useState<RejectReason>('outdated_request');
  const [notes, setNotes] = useState('');

  const handleConfirm = () => {
    startTransition(async () => {
      const result = await bulkRejectDrafts({
        draftIds,
        reason,
        notes: notes.trim() || undefined,
      });
      const totalReq = draftIds.length;
      const succeededCount = result.succeeded.length;
      const failedCount = result.failed.length;

      if (succeededCount > 0 && failedCount === 0) {
        toast.success(`Rejected ${succeededCount} of ${totalReq}`);
      } else if (succeededCount > 0 && failedCount > 0) {
        toast.warning(
          `Rejected ${succeededCount} of ${totalReq} (${failedCount} skipped)`,
        );
      } else {
        toast.error(
          `Reject failed (${failedCount} errors). Already processed?`,
        );
      }
      onOpenChange(false);
      clear();
      router.refresh();
    });
  };

  const needsNotes = reason === 'other';
  const isValid = !needsNotes || notes.trim().length > 0;

  return (
    <Dialog
      open={open}
      onOpenChange={(v) => {
        if (!isPending) onOpenChange(v);
      }}
    >
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Reject {draftIds.length} drafts?</DialogTitle>
          <DialogDescription>
            The same reason will be applied to all selected drafts. Only drafts still in pending_review will be affected.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-3">
          <div className="space-y-2">
            <Label className="text-sm">Reason</Label>
            <RadioGroup
              value={reason}
              onValueChange={(v) => setReason(v as RejectReason)}
              disabled={isPending}
              className="gap-1.5"
            >
              {REJECT_REASONS.map((r) => (
                <div key={r} className="flex items-center gap-2">
                  <RadioGroupItem value={r} id={`bulk-reject-${r}`} />
                  <Label
                    htmlFor={`bulk-reject-${r}`}
                    className="cursor-pointer text-sm font-normal"
                  >
                    {REASON_LABELS[r]}
                  </Label>
                </div>
              ))}
            </RadioGroup>
          </div>

          <div className="space-y-2">
            <Label htmlFor="bulk-reject-notes" className="text-sm">
              Notes {needsNotes && <span className="text-destructive">*</span>}
            </Label>
            <Textarea
              id="bulk-reject-notes"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder={needsNotes ? 'Required...' : 'Optional...'}
              rows={3}
              disabled={isPending}
            />
          </div>
        </div>

        <DialogFooter>
          <Button
            variant="outline"
            onClick={() => onOpenChange(false)}
            disabled={isPending}
          >
            Cancel
          </Button>
          <Button
            onClick={handleConfirm}
            disabled={isPending || !isValid}
            variant="destructive"
          >
            {isPending ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <X className="h-4 w-4" />
            )}
            Reject {draftIds.length}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
