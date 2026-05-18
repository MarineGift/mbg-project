'use client';

/**
 * src/components/inbox/inbox-delete-button.tsx
 *
 * 단건 삭제 버튼 — 확인 다이얼로그 포함.
 * InboxTable 행(row)에 삽입.
 */

import { useState, useTransition } from 'react';
import { Trash2, Loader2 } from 'lucide-react';
import { toast } from 'sonner';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from '@/components/ui/alert-dialog';
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
    <AlertDialog open={open} onOpenChange={setOpen}>
      <AlertDialogTrigger asChild>
        <Button
          variant="ghost"
          size="icon"
          className="h-7 w-7 text-muted-foreground hover:text-destructive hover:bg-destructive/10 opacity-0 group-hover:opacity-100 transition-opacity"
          aria-label="Delete message"
          onClick={(e) => e.stopPropagation()} // 행 클릭 이벤트 차단
        >
          <Trash2 className="h-4 w-4" />
        </Button>
      </AlertDialogTrigger>

      <AlertDialogContent onClick={(e) => e.stopPropagation()}>
        <AlertDialogHeader>
          <AlertDialogTitle>Delete message?</AlertDialogTitle>
          <AlertDialogDescription>
            {subject && (
              <span className="block font-medium text-foreground mb-1 truncate">
                &ldquo;{subject}&rdquo;
              </span>
            )}
            {isInbound
              ? 'This will permanently delete the message from both the mail server and this platform.'
              : 'This will remove the message from this platform. (Outbound messages are not deleted from the mail server.)'}
            <span className="block mt-2 text-destructive font-medium">
              This action cannot be undone.
            </span>
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel disabled={isPending}>Cancel</AlertDialogCancel>
          <AlertDialogAction
            onClick={handleDelete}
            disabled={isPending}
            className="bg-destructive hover:bg-destructive/90 text-destructive-foreground"
          >
            {isPending ? (
              <>
                <Loader2 className="h-4 w-4 animate-spin mr-2" />
                Deleting…
              </>
            ) : (
              'Delete'
            )}
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
