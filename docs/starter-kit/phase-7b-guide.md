# Phase 7-b 완성 가이드

## 파일 배치

```
src/
├── lib/party/
│   └── tier-cascade.ts              ← 교체
├── app/actions/
│   └── party.ts                     ← 교체
└── components/industry/
    ├── PromoteMillButton.tsx         ← 교체
    ├── PromoteCompanyButton.tsx      ← 신규
    └── LinkedMillSection.tsx         ← 신규
```

---

## 7-b-3: party detail 페이지 연동

`src/app/(app)/paper_mill/parties/[id]/page.tsx` 에서 아래 추가:

```tsx
import { LinkedMillSection } from '@/components/industry/LinkedMillSection'

// 페이지 함수 안에서 party 조회 후:
const party = ... // 기존 party 조회 코드

// JSX 안에:
{party.industry_paper_mill_id && (
  <LinkedMillSection industryPaperMillId={party.industry_paper_mill_id} />
)}
```

---

## paper_companies detail 페이지 연동

`src/app/(app)/industry/paper-companies/[id]/page.tsx` 에서 아래 추가:

```tsx
import { getPartyByCompanyId } from '@/app/actions/party'
import { PromoteCompanyButton } from '@/components/industry/PromoteCompanyButton'

// return 직전:
const linkedParty = await getPartyByCompanyId(id)

// JSX 헤더 우측:
<PromoteCompanyButton
  companyId={id}
  companyName={company.name}
  existingPartyId={linkedParty?.id ?? null}
  existingPartyName={linkedParty?.name ?? null}
/>
```

---

## party_level 값 체계 (DB constraint 기준)

| DB 값           | 의미             | 해당 tier_role                        |
|-----------------|------------------|---------------------------------------|
| `group_hq`      | 그룹 본사/HQ     | HQ, Regional_HQ, Country_HQ          |
| `country_entity`| 국가 법인        | Country, Subsidiary, JV, Associate, Branch |
| `plant`         | 공장/제지소      | 승격된 paper_mill                     |

## cascade 흐름

```
parent 없음         → tier_1 / group_hq
parent group_hq     → tier_2 / country_entity
parent country_entity → tier_3 / plant
parent plant        → tier_4 / plant
```

---

## 수정 이력 (이번 세션)

- `tier-cascade.ts`: party_level 값 DB constraint에 맞게 전면 교체
- `party.ts`: `.schema('app' as never)` 추가, 기본값 수정, `promoteCompanyToParty` 추가
- `PromoteMillButton.tsx`: 오류 처리 정리
- `PromoteCompanyButton.tsx`: 신규 (paper_companies 페이지용)
- `LinkedMillSection.tsx`: 신규 (party detail에서 industry 데이터 표시)
