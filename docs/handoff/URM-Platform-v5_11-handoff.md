# URM Platform v5.11 작업 재개 - 핸드오프

## 환경
- Project: marinebiogroup 브랜치, C:\dev\mbg-project
- Stack: Next.js 14.2 + TypeScript + Supabase
- Supabase project: ogenmrgxwhpbfepeldqx
- Organization ID: b25de8f2-1020-482f-9012-183f63883169 (MBG Project)
- 사용자: YunYoung, 한국어-혼합 스타일, "너가 판단해서 진행" 자율 모드
- OS: Windows PowerShell

---

## v5.11 완료 (현재 세션, Git tag: v5.11-party-system-db-enrichment)

### Phase 7-b: CRM Party 관리 시스템

#### 신규 파일
| 파일 | 경로 | 내용 |
|------|------|------|
| `tier-cascade.ts` | `src/lib/party/` | party_level/tier 자동 계산 유틸리티 |
| `party.ts` | `src/app/actions/` | Server Actions (create/update/promote/query) |
| `PromoteMillButton.tsx` | `src/components/industry/` | paper_mill detail → CRM party 승격 버튼 |
| `PromoteCompanyButton.tsx` | `src/components/industry/` | paper_companies detail → CRM party 승격 버튼 |
| `LinkedMillSection.tsx` | `src/components/industry/` | party detail에서 industry mill 데이터 표시 (7-b-3) |

#### 수정 파일
- `src/app/(app)/industry/paper-mills/[id]/page.tsx` — PromoteMillButton 연동
- `src/app/(app)/industry/paper-companies/[id]/page.tsx` — PromoteCompanyButton 연동

#### 핵심 설계 결정사항
- `app.parties` 스키마 (app schema, NOT public)
- `party_level` DB constraint: `'group_hq' | 'country_entity' | 'plant'` (3값만 허용)
- `tier_level` enum: `tier_1` ~ `tier_5`
- Supabase client: `createSupabaseServerClient()` (NOT createClient)
- schema 접근: `.schema('app' as never)` for parties, `.schema('industry' as never)` for industry
- `industry.paper_mills` 컬럼: `mill_name` (name 아님), `market_code` (country_code 아님)
- `evidence_level`: `character(1)` — 'A', 'B', 'C', 'P' 한 글자만

#### cascade 흐름
```
parent 없음          → tier_1 / group_hq
parent group_hq      → tier_2 / country_entity
parent country_entity → tier_3 / plant
parent plant         → tier_4 / plant
```

#### industry tier_role → party_level 매핑
```
HQ / Regional_HQ / Country_HQ → group_hq (tier_1/2)
Country / Subsidiary / JV / Associate / Branch → country_entity (tier_3/4)
paper_mill (promote) → plant (tier_4)
```

### Industry DB 업데이트

#### 데이터 정합성
- MTI (`Minerals Technologies (MTI) / Specialty Minerals`) → `Specialty Minerals (MTI)` 전면 통합
  - europe_composite 중복 (ID 5) 삭제
  - ID 6, 16, 22, 31, 34, 38 이름 변경
- `Artemyn (formerly Imerys / Flacks Group)` 리브랜딩 반영 (Jul 2024)
- APP ILIKE 버그 수정: `ILIKE '%APP%'`가 Sappi/Kappa/Pappel/APPM 등에 잘못 매칭 → 전체 정정

#### 업데이트된 필드
- `notes`: HFCC 전략 노트 + 포지션 설명 (V0_7_2 Master FINAL 기준)
- `main_products`: 상세 제품군/용량/최신 정보
- `evidence_level`: char(1) A/B/C/P

#### 신규 등록 (INSERT)
| 세그먼트 | 수 | 주요 회사 |
|----------|-----|-----------|
| Tissue (Phase 1: AFH/Recycled/JumboRoll) | 5 | WEPA, Cascades, Georgia-Pacific, Metsä Tissue, Kruger |
| Wallcovering (Korea Phase 1) | 5 | LX Hausys★★★, KCC Glass★★★, 신한벽지, 개나리벽지, 현대L&C |
| Wallcovering (US/EU Phase 2) | 6 | Len-Tex★★★, Vescom, MDC, Momentum, A.S.Création, Wolf-Gordon |
| Wallcovering (Japan Phase 3) | 1 | Sangetsu |
| Specialty (미등록) | 7 | Mitsubishi HiTec, Lintec, Jujo Thermal, Koehler, Twin Rivers, Ahlstrom, Gascogne |

---

## v5.11까지 전체 완성 상태 요약

### 작동 중인 기능
1. **5개 module Kanban** — /investor, /paper_mill, /partner, /customer, /filler engagements
2. **Pipeline Stages Admin** — /settings/pipelines
3. **Industry detail pages** — /industry/paper-companies/[id], paper-mills/[id], filler-suppliers/[id]
4. **CRM Party 승격** — industry mill/company → app.parties (PromoteMillButton, PromoteCompanyButton)
5. **tier cascade** — parent_party_id 기반 tier/party_level 자동 계산
6. **Sample engagements 21개** — [SAMPLE] prefix, 5 modules
7. **Global Paper Filler Master Database** — P&W/CWF/Specialty/Paperboard/Tissue/Wallcovering 전체 커버

### DB 스키마 핵심
```
public.tier_role enum: HQ / Regional_HQ / Country_HQ / Country / JV / Associate / Branch
  ※ 'Subsidiary'는 유효하지 않음 — HQ 사용

app.parties 핵심 컬럼:
  - party_level: text (constraint: group_hq | country_entity | plant)
  - tier: app.tier_level (tier_1~5)
  - parent_party_id: uuid
  - industry_paper_company_id: bigint
  - industry_paper_mill_id: bigint
  - industry_filler_supplier_id: bigint
  - module: USER-DEFINED (paper_mill, investor, partner, customer, filler)
  - organization_id: uuid NOT NULL (= b25de8f2-1020-482f-9012-183f63883169)

industry.paper_mills 핵심 컬럼:
  - mill_name (name 아님)
  - market_code (country_code 아님)
  - paper_company_id
```

---

## 다음 작업: Phase 7-b 마무리 + 후속

### 7-b-3 미완료 (LinkedMillSection 연동)
`LinkedMillSection.tsx` 컴포넌트는 생성됐으나 party detail 페이지에 미연동.

연동 대상: `src/app/(app)/paper_mill/parties/[id]/page.tsx`

```tsx
import { LinkedMillSection } from '@/components/industry/LinkedMillSection'

// party 조회 후 JSX에:
{party.industry_paper_mill_id && (
  <LinkedMillSection industryPaperMillId={party.industry_paper_mill_id} />
)}
```

### 이후 후보 작업
- **Phase 8**: Party 목록 페이지 계층 구조 표시 (parent/child 트리)
- **Phase 9**: Engagement 생성 시 party 연결 강화
- **웹 데이터 수집**: 인터넷에서 industry 데이터 자동 업데이트 시스템 (YunYoung 요청)

---

## 새 창 시작 시 체크리스트

1. 이 핸드오프 문서 첨부
2. 필요 시 `src/app/(app)/paper_mill/parties/[id]/page.tsx` 첨부 (7-b-3 연동 시)
3. "Phase 7-b-3 마무리" 또는 "Phase 8 시작" 한 마디로 작업 개시

---

## 중요 교훈 (이번 세션)

1. **ILIKE '%APP%' 절대 금지** — 'Sappi', 'Kappa', 'Pappel', 'APPM', 'Lappeenranta' 등 매칭됨
   → 항상 공백 경계 또는 정확한 이름 사용
2. **evidence_level = character(1)** — 'A/CORR' 같은 복합값 불가, 'A'만
3. **tier_role enum에 'Subsidiary' 없음** — HQ 또는 Country 사용
4. **app.parties는 app schema** — `.schema('app' as never)` 필수
5. **industry.paper_mills 컬럼**: `mill_name` / `market_code` (name/country_code 아님)
