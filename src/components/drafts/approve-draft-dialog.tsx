'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { Loader2, Send } from 'lucide-react';
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
import type { SendingAddressKind } from '@/types/email';

interface Props {
  draft: DraftDetail;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

/** Option label - for display. The actual address comes from the user's email_personal/role/shared. */
const KIND_OPTIONS: Array<{ value: SendingAddressKind; label: string; hint: string }> = [
  { value: 'personal', label: 'Personal email', hint: 'Personal' },
  { value: 'role', label: 'Role email (CEO, etc.)', hint: 'Role' },
  { value: 'shared', label: 'Shared/team email', hint: 'Shared' },
];

export function ApproveDraftDialog({ draft, open, onOpenChange }: Props) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const [sendImmediately, setSendImmediately] = useState(true);
  const [sendingAddressKind, setSendingAddressKind] =
    useState<SendingAddressKind>('personal');

  const hasInbound = draft.inbound != null;

  const handleConfirm = () => {
    startTransition(async () => {
      const result = await approveDraft({
        draftId: draft.id,
        sendImmediately: sendImmediately && hasInbound,
        sendingAddressKind: sendImmediately && hasInbound ? sendingAddressKind : undefined,
      });
      if (result.ok) {
        toast.success(
          result.data?.sent
            ? `Approved and sent (from: ${sendingAddressKind})`
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
            The draft will be marked as approved and{' '}
            {sendImmediately && hasInbound ? 'sent immediately' : 'queued for later send'}.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-3">
          body preview
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

          send-immediately checkbox
          {hasInbound ? (
            <div className="flex items-center gap-2">
              <Checkbox
                id="send-immediately"
                checked={sendImmediately}
                onCheckedChange={(checked) => setSendImmediately(checked === true)}
              />
              <Label htmlFor="send-immediately" className="text-sm cursor-pointer">
                Send immediately after approval
              </Label>
            </div>
          ) : (
            <p className="text-xs text-muted-foreground">
              No inbound message linked — this draft will be marked approved only.
            </p>
          )}

          from-address selector - enabled only when sending immediately
          {sendImmediately && hasInbound && (
            <div className="space-y-1.5">
              <Label htmlFor="sending-kind" className="text-sm">
                Send From
              </Label>
              <select
                id="sending-kind"
                value={sendingAddressKind}
                onChange={(e) => setSendingAddressKind(e.target.value as SendingAddressKind)}
                disabled={isPending}
                className="flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50"
              >
                {KIND_OPTIONS.map((opt) => (
                  <option key={opt.value} value={opt.value}>
                    {opt.label}
                  </option>
                ))}
              </select>
              <p className="text-xs text-muted-foreground">
                Defaults to your personal email. The reply is sent from the selected account after SMTP authentication.
              </p>
            </div>
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
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                Processing...
              </>
            ) : (
              <>
                <Send className="mr-2 h-4 w-4" />
                {sendImmediately && hasInbound ? 'Approve & Send' : 'Approve'}
              </>
            )}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
