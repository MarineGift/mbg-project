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
import { rejectDraft } from '@/lib/actions/drafts';
import { REJECT_REASONS } from '@/types/draft-detail';
import type { RejectReason } from '@/types/draft-detail';

interface Props {
  draftId: string;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

const REASON_LABELS: Record<RejectReason, string> = {
  outdated_request: 'Outdated / no longer relevant',
  off_topic: 'Off-topic for this contact',
  wrong_tone: 'Wrong tone / register',
  incorrect_info: 'Contains incorrect information',
  other: 'Other (specify below)',
};

export function RejectDraftDialog({ draftId, open, onOpenChange }: Props) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const [reason, setReason] = useState<RejectReason>('outdated_request');
  const [notes, setNotes] = useState('');

  const handleConfirm = () => {
    startTransition(async () => {
      const result = await rejectDraft({
        draftId,
        reason,
        notes: notes.trim() || undefined,
      });
      if (result.ok) {
        toast.success('Draft rejected');
        onOpenChange(false);
        router.refresh();
      } else {
        toast.error(result.errorMessage ?? 'Reject failed');
      }
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
          <DialogTitle>Reject this draft?</DialogTitle>
          <DialogDescription>
            The draft will be marked rejected. The original inbound message remains in your inbox for manual reply.
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
                  <RadioGroupItem value={r} id={`reject-${r}`} />
                  <Label
                    htmlFor={`reject-${r}`}
                    className="cursor-pointer text-sm font-normal"
                  >
                    {REASON_LABELS[r]}
                  </Label>
                </div>
              ))}
            </RadioGroup>
          </div>

          <div className="space-y-2">
            <Label htmlFor="reject-notes" className="text-sm">
              Notes {needsNotes && <span className="text-destructive">*</span>}
            </Label>
            <Textarea
              id="reject-notes"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder={needsNotes ? 'Please describe...' : 'Optional details for future tuning...'}
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
            Reject
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
