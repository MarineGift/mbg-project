// src/components/inbox/inbox-compose-button.tsx
//
// Multi-Account Mail Hub Step 4 (2026-06-12)
// Client launcher for composing a new email from the Inbox header.
// The inbox page is a server component, so this small client component
// hosts the (client) ComposeEmailDialog and its trigger button.
//
// No partyId/contactId -> the dialog uses the manual outbound path, which
// supports a null party. From defaults to the is_default mail account.
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { PenSquare } from "lucide-react";
import { Button } from "@/components/ui/button";
import { ComposeEmailDialog } from "@/components/email/compose-email-dialog";

export function InboxComposeButton() {
  const [open, setOpen] = useState(false);
  const router = useRouter();

  return (
    <>
      <Button onClick={() => setOpen(true)} className="gap-2">
        <PenSquare className="h-4 w-4" />
        New Email
      </Button>
      <ComposeEmailDialog
        open={open}
        onOpenChange={setOpen}
        mode="new"
        // Refresh the inbox so a Sent row appears without a manual reload.
        onSent={() => router.refresh()}
      />
    </>
  );
}
