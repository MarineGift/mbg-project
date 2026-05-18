'use client';

/**
 * src/components/tasks/task-delete-button.tsx
 * Inbox와 동일 패턴: hover 시 표시 + confirm dialog
 */

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
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
import { deleteTask } from '@/app/actions/delete-task';

interface Props {
  id: string;
  title?: string | null;
}

export function TaskDeleteButton({ id, title }: Props) {
  const [open, setOpen] = useState(false);
  const [isPending, startTransition] = useTransition();
  const router = useRouter();

  function handleDelete() {
    startTransition(async () => {
      const result = await deleteTask(id);
      if (result.success) {
        toast.success('Task deleted');
        setOpen(false);
        router.refresh();
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
          aria-label="Delete task"
          onClick={(e: React.MouseEvent) => e.stopPropagation()}
        >
          <Trash2 className="h-4 w-4" />
        </Button>
      </DialogTrigger>

      <DialogContent onClick={(e: React.MouseEvent) => e.stopPropagation()}>
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <AlertTriangle className="h-5 w-5 text-destructive" />
            Delete task?
          </DialogTitle>
          <DialogDescription asChild>
            <div>
              {title && (
                <span className="block font-medium text-foreground mb-2 truncate">
                  &ldquo;{title}&rdquo;
                </span>
              )}
              <span className="block text-sm">
                This will permanently delete the task.
              </span>
              <span className="block mt-2 text-sm text-destructive font-medium">
                This action cannot be undone.
              </span>
            </div>
          </DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <Button variant="outline" onClick={() => setOpen(false)} disabled={isPending}>
            Cancel
          </Button>
          <Button variant="destructive" onClick={handleDelete} disabled={isPending}>
            {isPending ? (
              <><Loader2 className="h-4 w-4 animate-spin mr-2" />Deleting…</>
            ) : 'Delete'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
