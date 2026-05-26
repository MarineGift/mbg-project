'use client';
import { useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { Button } from '@/components/ui/button';

interface Props {
  taskId: string;
  status: string;
  current: string;
  label: string;
}

export function TaskStatusButton({ taskId, status, current, label }: Props) {
  const [pending, startTransition] = useTransition();
  const router = useRouter();

  function handleClick() {
    startTransition(async () => {
      await fetch('/api/tasks/' + taskId + '/status', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status }),
      });
      router.refresh();
    });
  }

  return (
    <Button
      size="sm"
      variant={current === status ? 'default' : 'outline'}
      className="h-7 text-xs"
      disabled={pending || current === status}
      onClick={handleClick}
    >
      {pending ? '...' : label}
    </Button>
  );
}