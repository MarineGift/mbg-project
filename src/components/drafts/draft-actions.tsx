'use client';

import { useState } from 'react';
import { Check, X } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { ApproveDraftDialog } from './approve-draft-dialog';
import { RejectDraftDialog } from './reject-draft-dialog';
import type { DraftDetail } from '@/types/draft-detail';

interface Props {
  draft: DraftDetail;
}

/**
 * Bottom action bar shown only in the pending_review state.
 * The Approve / Reject buttons each open a dialog to go through a confirmation step.
 */
export function DraftActions({ draft }: Props) {
  const [approveOpen, setApproveOpen] = useState(false);
  const [rejectOpen, setRejectOpen] = useState(false);

  if (draft.status !== 'pending_review') {
    return null;
  }

  return (
    <>
      <div className="sticky bottom-0 z-10 flex items-center justify-end gap-2 px-6 py-3 border-t bg-background shadow-[0_-2px_8px_rgba(0,0,0,0.04)]">
        <Button
          variant="outline"
          onClick={() => setRejectOpen(true)}
          size="sm"
        >
          <X className="h-4 w-4" />
          Reject
        </Button>
        <Button onClick={() => setApproveOpen(true)} size="sm">
          <Check className="h-4 w-4" />
          Approve
        </Button>
      </div>

      <ApproveDraftDialog
        draft={draft}
        open={approveOpen}
        onOpenChange={setApproveOpen}
      />
      <RejectDraftDialog
        draftId={draft.id}
        open={rejectOpen}
        onOpenChange={setRejectOpen}
      />
    </>
  );
}
