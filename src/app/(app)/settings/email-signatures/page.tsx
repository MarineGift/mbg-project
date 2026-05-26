// src/app/(app)/settings/email-signatures/page.tsx
// Phase 22b: Email Signatures settings page
import { EmailSignaturesClient } from "@/components/settings/email-signatures-client";
export default function EmailSignaturesPage() {
  return (
    <div className="p-6 max-w-3xl">
      <div className="mb-6">
        <h1 className="text-2xl font-semibold">Email Signatures</h1>
        <p className="text-sm text-muted-foreground mt-1">
          Manage HTML signatures automatically attached when sending emails.
        </p>
      </div>
      <EmailSignaturesClient />
    </div>
  );
}