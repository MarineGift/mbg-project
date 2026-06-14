// src/lib/actions/reply-recipients.ts
// Returns the original message's sender/recipients so the compose dialog can
// build a "Reply" (sender only) or "Reply all" To/Cc without the parent having
// to pass the data in. Read-only; org-scoped.
"use server";

import { createSupabaseServerClient } from "@/lib/supabase/server";
import { requireAuth } from "@/lib/auth";

export interface ReplyRecipients {
  /** original sender; becomes the To address on reply */
  from: string | null;
  /** original To recipients */
  to: string[];
  /** original Cc recipients */
  cc: string[];
}

export async function getReplyRecipients(
  communicationId: string,
): Promise<{ ok: boolean; data?: ReplyRecipients; error?: string }> {
  if (!communicationId) return { ok: false, error: "Missing communication id" };

  const supabase = await createSupabaseServerClient();
  const auth = await requireAuth();
  const orgId = auth.organizationId;

  const { data, error } = await supabase
    .schema("app")
    .from("communications" as never)
    .select("from_address, to_addresses, cc_addresses")
    .eq("id", communicationId)
    .eq("organization_id", orgId)
    .single();

  if (error || !data) {
    return { ok: false, error: error?.message ?? "Original message not found." };
  }

  const row = data as {
    from_address: string | null;
    to_addresses: string[] | null;
    cc_addresses: string[] | null;
  };

  return {
    ok: true,
    data: {
      from: row.from_address ?? null,
      to: Array.isArray(row.to_addresses) ? row.to_addresses : [],
      cc: Array.isArray(row.cc_addresses) ? row.cc_addresses : [],
    },
  };
}
