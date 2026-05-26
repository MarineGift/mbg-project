// src/app/(app)/[module]/parties/[id]/page.tsx
// Phase 22b: contact_id → ComposeEmailDialog 전달
//
// 기존 파일에서 아래 두 부분을 수정하세요.
// ─────────────────────────────────────────────────────────────────────
// [수정 1] 데이터 페치 쿼리에 primary contact 포함
// ─────────────────────────────────────────────────────────────────────
//
// 기존:
//   const party = await fetchParty(id)
//
// 수정 후 (fetchParty 내부 또는 page에서 직접):
//   party 조회 시 아래 서브쿼리 추가
//
// Supabase query 예시:
// ──────────────────────────────────────────────────────────────────
// const { data: party } = await supabase
//   .from("parties")
//   .select(`
//     *,
//     primary_contact:party_contacts!inner(
//       contact_id,
//       contacts(id, given_name, family_name, email)
//     )
//   `)
//   .eq("id", params.id)
//   .eq("party_contacts.is_primary", true)   // ← primary contact만
//   .maybeSingle()
//
// primary contact_id 추출:
// const primaryContactId = party?.primary_contact?.[0]?.contact_id ?? null
//
// ─────────────────────────────────────────────────────────────────────
// [수정 2] ComposeEmailDialog 호출 시 contactId prop 추가
// ─────────────────────────────────────────────────────────────────────

// 기존 코드 예시 (수정 전):
// <ComposeEmailDialog
//   open={composeOpen}
//   onOpenChange={setComposeOpen}
//   partyId={party.id}
//   mode="new"
//   defaultTo={party.primary_email ?? ""}
// />

// 수정 후:
// <ComposeEmailDialog
//   open={composeOpen}
//   onOpenChange={setComposeOpen}
//   partyId={party.id}
//   contactId={primaryContactId}   // ← 추가
//   mode="new"
//   defaultTo={party.primary_email ?? ""}
// />

// ─────────────────────────────────────────────────────────────────────
// 완전한 page 예시 (서버 컴포넌트 + Client island 패턴)
// 기존 구조가 다를 경우 참고용
// ─────────────────────────────────────────────────────────────────────

import { createServerComponentClient } from "@supabase/auth-helpers-nextjs";
import { cookies } from "next/headers";
import { notFound } from "next/navigation";
import { PartyPageClient } from "./party-page-client"; // 별도 client component

interface Props {
  params: { module: string; id: string };
}

export default async function PartyPage({ params }: Props) {
  const supabase = createServerComponentClient({ cookies });

  // party + primary contact 동시 조회
  const { data: party } = await supabase
    .from("parties")
    .select("*")
    .eq("id", params.id)
    .single();

  if (!party) notFound();

  // primary contact_id 별도 조회
  const { data: primaryContact } = await supabase
    .from("party_contacts")
    .select("contact_id, contacts(id, given_name, family_name, email)")
    .eq("party_id", params.id)
    .eq("is_primary", true)
    .maybeSingle();

  const primaryContactId = primaryContact?.contact_id ?? null;

  return (
    <PartyPageClient
      party={party}
      primaryContactId={primaryContactId}   // ← 전달
      module={params.module}
    />
  );
}

// ─────────────────────────────────────────────────────────────────────
// party-page-client.tsx 에서 (Client Component)
// ─────────────────────────────────────────────────────────────────────
// props에 primaryContactId 받아서 ComposeEmailDialog에 전달:
//
// interface PartyPageClientProps {
//   party: Party
//   primaryContactId: string | null   // ← 추가
//   module: string
// }
//
// export function PartyPageClient({ party, primaryContactId, module }: PartyPageClientProps) {
//   const [composeOpen, setComposeOpen] = useState(false)
//   ...
//   return (
//     <>
//       ...
//       <ComposeEmailDialog
//         open={composeOpen}
//         onOpenChange={setComposeOpen}
//         partyId={party.id}
//         contactId={primaryContactId}   // ← 여기
//         mode="new"
//         defaultTo={party.primary_email ?? ""}
//       />
//     </>
//   )
// }
