'use client';

import { useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { toast } from 'sonner';
import { Checkbox } from '@/components/ui/checkbox';
import { markTaskComplete, markTaskIncomplete } from '@/lib/actions/tasks';
import type { TaskStatus } from '@/types/task';

interface Props {
  taskId: string;
  status: TaskStatus;
}

/**
 * 완료 체크박스 — clicking toggles done <-> todo.
 * Optimistic UI는 router.refresh로 단순 처리.
 */
export function TaskCheckbox({ taskId, status }: Props) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const isDone = status === 'done';

  const handleToggle = () => {
    startTransition(async () => {
      const result = isDone
        ? await markTaskIncomplete({ taskId })
        : await markTaskComplete({ taskId });
      if (result.ok) {
        router.refresh();
      } else {
        toast.error(result.errorMessage ?? 'Update failed');
      }
    });
  };

  return (
    <Checkbox
      checked={isDone}
      onCheckedChange={handleToggle}
      disabled={isPending || status === 'cancelled'}
      aria-label={isDone ? 'Mark as incomplete' : 'Mark as complete'}
      // 클릭 시 부모의 onClick(navigation) 전파 방지
      onClick={(e) => e.stopPropagation()}
    />
  );
}
