# Phase 7-b 통합 가이드

## 파일 배치

```
src/
├── lib/
│   └── party/
│       └── tier-cascade.ts          ← 신규 (tier-cascade.ts)
├── app/
│   └── actions/
│       └── party.ts                 ← 신규 (party.ts)
└── components/
    └── industry/
        └── PromoteMillButton.tsx    ← 신규 (PromoteMillButton.tsx)
```

---

## industry detail page에 버튼 붙이기

`src/app/industry/paper-mills/[id]/page.tsx` 에서:

```tsx
import { getPartyByMillId } from '@/app/actions/party'
import { PromoteMillButton } from '@/components/industry/PromoteMillButton'

export default async function PaperMillDetailPage({ params }: { params: { id: string } }) {
  const millId = Number(params.id)

  // 기존 mill 데이터 fetch ...

  // CRM party 연결 여부 확인 (서버에서 pre-fetch)
  const linkedParty = await getPartyByMillId(millId)

  return (
    <div>
      {/* ... 기존 mill 상세 UI ... */}

      {/* Phase 7-b: CRM 연결 섹션 */}
      <section className="mt-6 border-t pt-6">
        <h3 className="mb-3 text-sm font-semibold text-slate-500 uppercase tracking-wide">
          CRM 연결
        </h3>
        <PromoteMillButton
          millId={millId}
          millName={mill.name}
          existingPartyId={linkedParty?.id ?? null}
          existingPartyName={linkedParty?.name ?? null}
        />
      </section>
    </div>
  )
}
```

---

## tier cascade 흐름 정리

```
parent 없음          → tier_1 / party_level: "HQ"
parent tier_1        → tier_2 / party_level: "Regional HQ"
parent tier_2        → tier_3 / party_level: "Country"
parent tier_3        → tier_4 / party_level: "Subsidiary" or "Plant"
parent tier_4        → tier_5 / party_level: "Plant"
```

industry tier_role과 매핑:
```
HQ           → tier_1
Regional_HQ  → tier_2
Country_HQ   → tier_2
Country      → tier_3
Subsidiary   → tier_3  
JV           → tier_3
Associate    → tier_4
Branch       → tier_4
Mill(promote)→ tier_4 (parent 없을 때)
```

---

## promoteMillToParty 동작 흐름

1. `industry_paper_mill_id = millId` 인 party 존재 여부 확인 (중복 방지)
2. `industry.paper_mills` 에서 name, country_code, city, paper_company_id 조회
3. `paper_company_id` → `app.parties.industry_paper_company_id` 로 parent party 탐색
4. parent 있으면 `cascadeTier(parent.tier)`, 없으면 `tier_4`
5. `app.parties` INSERT (module='paper_mill', party_level='Plant')
6. revalidatePath 호출

---

## 다음 단계 (7-b-3 나머지)

- [ ] party detail 페이지에서 `getChildParties(partyId)` 로 하위 parties 표시
- [ ] paper_companies detail 페이지에 연결된 CRM party 표시 (`getPartyByCompanyId`)
- [ ] party 생성 폼에 parent_party_id 선택 UI (optional)
