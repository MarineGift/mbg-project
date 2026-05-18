// src/lib/actions/communications-actions.ts
// Phase 22b: communications 愿??server actions
// (Client Component?먯꽌 吏곸젒 ?몄텧 媛?ν븳 "use server" wrapper)
"use server";

import { createServerActionClient } from "@supabase/auth-helpers-nextjs";
import { cookies } from "next/headers";

/**
 * ?뱀젙 communication ?곸꽭 議고쉶 (party, contact join ?ы븿)
 * inbox/[id]/page.tsx ?먯꽌 useEffect ???몄텧
 */
export async function fetchCommunicationDetailAction(id: string) {
  const supabase = createServerActionClient({ cookies });

  const { data, error } = await supabase
    .from("communications")
    .select(`
      *,
      party:parties(id, name),
      contact:contacts(id, given_name, family_name, email)
    `)
    .eq("id", id)
    .single();

  if (error) {
    console.error("[fetchCommunicationDetailAction]", error);
    return null;
  }

  return data;
}
