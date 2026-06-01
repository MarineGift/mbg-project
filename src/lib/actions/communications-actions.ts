// src/lib/actions/communications-actions.ts
// Phase 22b: communications 愿??server actions
// (a "use server" wrapper callable directly from a Client Component)
"use server";

import { createSupabaseServerClient } from "@/lib/supabase/server";
import { cookies } from "next/headers";

/**
 * Fetch a single communication detail (includes party, contact joins)
 * Called from inbox/[id]/page.tsx inside a useEffect
 */
export async function fetchCommunicationDetailAction(id: string) {
  const supabase = await createSupabaseServerClient();

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
