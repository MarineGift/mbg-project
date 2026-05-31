// src/app/(app)/settings/email-mailboxes/page.tsx
import { listMailboxes } from "@/lib/actions/inbound-mailboxes";
import { InboundMailboxesClient } from "@/components/settings/inbound-mailboxes-client";

export default async function EmailMailboxesPage() {
  const mailboxes = await listMailboxes();
  return (
    <div className="p-6 max-w-4xl mx-auto">
      <InboundMailboxesClient initialMailboxes={mailboxes} />
    </div>
  );
}
