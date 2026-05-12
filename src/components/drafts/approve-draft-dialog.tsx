'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { Check, Loader2, Send } from 'lucide-react';
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
import { Checkbox } from '@/components/ui/checkbox';
import { Label } from '@/components/ui/label';
import { approveDraft } from '@/lib/actions/drafts';
import type { DraftDetail } from '@/types/draft-detail';

interface Props {
  draft: DraftDetail;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function ApproveDraftDialog({ draft, open, onOpenChange }: Props) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const [sendImmediately, setSendImmediately] = useState(true);

  const hasInbound = draft.inbound != null;

  const handleConfirm = () => {
    startTransition(async () => {
      const result = await approveDraft({
        draftId: draft.id,
        sendImmediately: sendImmediately && hasInbound,
      });
      if (result.ok) {
        toast.success(
          result.data?.sent
            ? 'Approved and sent'
            : 'Approved (not sent yet)',
        );
        onOpenChange(false);
        router.refresh();
      } else {
        toast.error(result.errorMessage ?? 'Approval failed');
      }
    });
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Approve this draft?</DialogTitle>
          <DialogDescription>
            The draft will be marked as approved and {sendImmediately && hasInbound ? 'sent immediately' : 'queued for later send'}.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-3">
          <div className="rounded-md bg-muted/40 p-3 text-sm space-y-1">
            <p className="font-medium truncate">
              {draft.finalSubject ?? draft.subject ?? '(no subject)'}
            </p>
            {draft.inbound?.fromAddress && (
              <p className="text-xs text-muted-foreground truncate">
                To: {draft.inbound.fromAddress}
              </p>
            )}
            <p className="text-xs text-muted-foreground line-clamp-2 mt-1">
              {(draft.finalBodyPlain ?? draft.bodyPlain).slice(0, 200)}...
            </p>
          </div>

          {hasInbound ? (
            <div className="flex items-center gap-2">
              <Checkbox
                id="send-immediately"
                checked={sendImmediately}
                onCheckedChange={(v) => setSendImmediately(v === true)}
              />
              <Label htmlFor="send-immediately" className="cursor-pointer">
                Send immediately
              </Label>
            </div>
          ) : (
            <p className="text-xs text-muted-foreground">
              No inbound message linked — send will be skipped.
            </p>
          )}
        </div>

        <DialogFooter>
          <Button
            variant="outline"
            onClick={() => onOpenChange(false)}
            disabled={isPending}
          >
            Cancel
          </Button>
          <Button onClick={handleConfirm} disabled={isPending}>
            {isPending ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : sendImmediately && hasInbound ? (
              <Send className="h-4 w-4" />
            ) : (
              <Check className="h-4 w-4" />
            )}
            {sendImmediately && hasInbound ? 'Approve & Send' : 'Approve'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
