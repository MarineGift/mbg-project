'use client';

/**
 * src/components/inbox/inbox-delete-button.tsx
 */

import { useState, useTransition } from 'react';
import { Trash2, Loader2, AlertTriangle } from 'lucide-react';
import { toast } from 'sonner';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { deleteCommunication } from '@/app/actions/delete-communication';

interface Props {
  id: string;
  subject?: string | null;
  direction: string;
}

export function InboxDeleteButton({ id, subject, direction }: Props) {
  const [open, setOpen] = useState(false);
  const [isPending, startTransition] = useTransition();

  const isInbound = direction === 'inbound';

  function handleDelete() {
    startTransition(async () => {
      const result = await deleteCommunication(id);
      if (result.success) {
        toast.success('Message deleted');
        setOpen(false);
      } else {
        toast.error(`Delete failed: ${result.error}`);
      }
    });
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button
          variant="ghost"
          size="icon"
          className="h-7 w-7 text-muted-foreground hover:text-destructive hover:bg-destructive/10 opacity-0 group-hover:opacity-100 transition-opacity"
          aria-label="Delete message"
          onClick={(e: React.MouseEvent) => e.stopPropagation()}
        >
          <Trash2 className="h-4 w-4" />
        </Button>
      </DialogTrigger>

      <DialogContent onClick={(e: React.MouseEvent) => e.stopPropagation()}>
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <AlertTriangle className="h-5 w-5 text-destructive" />
            Delete message?
          </DialogTitle>
          <DialogDescription asChild>
            <div>
              {subject && (
                <span className="block font-medium text-foreground mb-2 truncate">
                  &ldquo;{subject}&rdquo;
                </span>
              )}
              <span className="block text-sm">
                {isInbound
                  ? 'This will permanently delete the message from both the mail server and this platform.'
                  : 'This will remove the message from this platform. Outbound messages are not deleted from the mail server.'}
              </span>
              <span className="block mt-2 text-sm text-destructive font-medium">
                This action cannot be undone.
              </span>
            </div>
          </DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <Button
            variant="outline"
            onClick={() => setOpen(false)}
            disabled={isPending}
          >
            Cancel
          </Button>
          <Button
            variant="destructive"
            onClick={handleDelete}
            disabled={isPending}
          >
            {isPending ? (
              <>
                <Loader2 className="h-4 w-4 animate-spin mr-2" />
                Deleting…
              </>
            ) : (
              'Delete'
            )}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
