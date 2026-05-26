// src/lib/queries/communications.ts 에 아래 함수 추가
// (기존 파일 하단에 append)
// ─────────────────────────────────────────────────────────────────────
// fetchCommunicationDetail: inbox 상세 조회
// ─────────────────────────────────────────────────────────────────────

import { createServerComponentClient } from "@supabase/auth-helpers-nextjs";
import { cookies } from "next/headers";

/**
 * 특정 communication 상세 조회 (party, contact join 포함)
 * 서버 컴포넌트 또는 server action에서 호출 가능
 */
export async function fetchCommunicationDetail(id: string) {
  const supabase = createServerComponentClient({ cookies });

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
    console.error("[fetchCommunicationDetail]", error);
    return null;
  }

  return data;
}

// ─────────────────────────────────────────────────────────────────────
// 주의: 위 함수가 Client Component(inbox/[id]/page.tsx)에서 호출된다면
// "use server" action으로 래핑해야 합니다.
//
// 아래처럼 src/lib/actions/communications-actions.ts 에 별도 server action 생성:
// ─────────────────────────────────────────────────────────────────────

// src/lib/actions/communications-actions.ts (새 파일)
// "use server";
//
// import { createServerActionClient } from "@supabase/auth-helpers-nextjs";
// import { cookies } from "next/headers";
//
// export async function fetchCommunicationDetailAction(id: string) {
//   const supabase = createServerActionClient({ cookies });
//
//   const { data, error } = await supabase
//     .from("communications")
//     .select(`
//       *,
//       party:parties(id, name),
//       contact:contacts(id, given_name, family_name, email)
//     `)
//     .eq("id", id)
//     .single();
//
//   if (error) {
//     console.error("[fetchCommunicationDetailAction]", error);
//     return null;
//   }
//
//   return data;
// }
//
// ─────────────────────────────────────────────────────────────────────
// inbox/[id]/page.tsx 에서 import:
// import { fetchCommunicationDetailAction } from "@/lib/actions/communications-actions"
// const result = await fetchCommunicationDetailAction(id)
// ─────────────────────────────────────────────────────────────────────
