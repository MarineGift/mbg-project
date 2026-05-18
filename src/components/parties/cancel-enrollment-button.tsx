'use client';
// src/components/parties/cancel-enrollment-button.tsx

import { useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { cancelEnrollment } from '@/lib/actions/email-sequences';

interface Props {
  enrollmentId: string;
  partyId:      string;
}

export function CancelEnrollmentButton({ enrollmentId, partyId }: Props) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();

  function handleCancel() {
    if (!confirm('Cancel this sequence enrollment? No further steps will be sent.')) return;
    startTransition(async () => {
      await cancelEnrollment(enrollmentId, partyId);
      router.refresh();
    });
  }

  return (
    <button
      onClick={handleCancel}
      disabled={isPending}
      className="text-xs text-gray-400 hover:text-red-500 disabled:opacity-50"
    >
      {isPending ? '…' : 'Cancel'}
    </button>
  );
}
