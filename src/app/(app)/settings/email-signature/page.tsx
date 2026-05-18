// src/app/(app)/settings/email-signature/page.tsx
// Email Signature settings page (English-only, ASCII-clean)
// Uses app.users.organization_id (organization_members table doesn't exist)

import { Suspense } from "react";
import { EmailSignatureClient } from "@/components/settings/email-signature-client";
import { getSignatures } from "@/lib/queries/email-signatures";
import { createSupabaseServerClient } from "@/lib/supabase/server";

async function getOrgId(): Promise<string> {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) throw new Error("Not authenticated");

  // Use app.users.organization_id (this is the project standard)
  const { data, error } = await supabase
    .schema("app")
    .from("users" as never)
    .select("organization_id")
    .eq("id", user.id)
    .maybeSingle();

  if (error) {
    console.error("[email-signature/getOrgId] app.users query error:", error);
    return "";
  }
  return (data as { organization_id?: string } | null)?.organization_id ?? "";
}

export default async function EmailSignaturePage() {
  const orgId = await getOrgId();

  if (!orgId) {
    return (
      <div className="max-w-3xl space-y-6 p-6">
        <h2 className="text-lg font-semibold">Email Signature</h2>
        <p className="text-sm text-destructive">
          Organization not found for current user. Please contact an administrator.
        </p>
      </div>
    );
  }

  const signatures = await getSignatures(orgId);

  return (
    <div className="max-w-3xl space-y-6 p-6">
      <div>
        <h2 className="text-lg font-semibold">Email Signature</h2>
        <p className="text-sm text-muted-foreground">
          Manage HTML signatures automatically attached to outbound emails.
        </p>
      </div>
      <Suspense
        fallback={
          <div className="text-sm text-muted-foreground">Loading...</div>
        }
      >
        <EmailSignatureClient orgId={orgId} initialSignatures={signatures} />
      </Suspense>
    </div>
  );
}