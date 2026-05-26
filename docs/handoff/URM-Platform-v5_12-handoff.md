# URM Platform v5.12 작업 재개 - 핸드오프

## 환경
- Project: marinebiogroup 브랜치, C:\dev\mbg-project
- Stack: Next.js 14.2 + TypeScript + Supabase
- Supabase project: ogenmrgxwhpbfepeldqx
- Organization ID: b25de8f2-1020-482f-9012-183f63883169 (MBG Project)
- 사용자: YunYoung, 한국어-혼합 스타일, "너가 판단해서 진행" 자율 모드
- OS: Windows PowerShell

---

## v5.12 완료 (현재 세션, Git tag 권장: v5.12-phase8-9-i18n)

### Phase 7-b-3: LinkedMillSection 연동
- `src/app/(app)/[module]/parties/[id]/page.tsx`
  - `LinkedMillSection` import + `industryPaperMillId` 조건부 렌더 추가

### Phase 8: Party 목록 계층 트리
- `src/app/(app)/[module]/parties/page.tsx`
  - `parent_party_id` / `party_level` SELECT 추가
  - `buildTree` + `flattenTree` 헬퍼 함수
  - depth 인덴트 (`└` 연결 문자) + HQ/Entity/Plant 배지
  - 헤더에 "계층 구조 표시 중" 표기

### Phase 9: Engagement 생성 시 party 연결 강화
- `src/lib/actions/engagements.ts`
  - `createEngagement`: party의 `industry_paper_mill_id` 조회 → `mill_id` 자동 설정
  - `primaryContactId` 필드 추가 (create/update 모두)
- `src/components/engagements/engagement-form.tsx`
  - `contacts?: ContactOption[]` prop 추가
  - "담당 연락처" select UI (contacts 있을 때만 표시)
- `src/app/(app)/[module]/engagements/new/page.tsx`
  - `full.contacts` → `ContactOption[]` 변환 (fullName/jobTitle camelCase)
  - `contacts={contacts}` EngagementForm에 전달

### i18n: 3개 언어 전환 (EN/한국어/日本語)
- `src/i18n/routing.ts` — locale 목록 + normalizeLocale + language-toggle 호환 export
  - `locales`, `localeCookieName`, `localeDisplayNames`, `Locale` type
- `src/i18n/request.ts` — next-intl 서버 설정 (정적 import, NEXT_LOCALE 쿠키)
- `src/i18n/messages/ko.json` — 한국어 전체 번역 (20 namespaces)
- `src/i18n/messages/ja.json` — 일본어 전체 번역 (20 namespaces)
- `src/components/layout/sidebar.tsx` — `LanguageToggle` 하단 추가
- `src/app/actions/locale.ts` — Server Action (선택적, language-toggle이 직접 cookie 세팅)
- `src/components/language-switcher.tsx` — 대체 switcher (미사용, 참고용)

---

## v5.12까지 전체 완성 상태

### 작동 중인 기능
1. **5개 module Kanban** — /investor, /paper_mill, /partner, /customer, /filler engagements
2. **Pipeline Stages Admin** — /settings/pipelines
3. **Industry detail pages** — /industry/paper-companies/[id], paper-mills/[id], filler-suppliers/[id]
4. **CRM Party 승격** — industry mill/company → app.parties
5. **tier cascade** — parent_party_id 기반 tier/party_level 자동 계산
6. **Party 목록 계층 트리** — HQ/Entity/Plant 배지 + depth 인덴트
7. **LinkedMillSection** — party detail에서 industry mill 데이터 표시
8. **Engagement 생성** — mill_id 자동 설정 + 담당 연락처 선택
9. **3개 언어 전환** — EN/한국어/日本語 (사이드바 🌐 토글)
10. **Sample engagements 21개** — [SAMPLE] prefix, 5 modules
11. **Global Paper Filler Master Database** — P&W/CWF/Specialty/Paperboard/Tissue/Wallcovering

### DB 스키마 핵심
```
app.parties:
  - party_level: text (group_hq | country_entity | plant)
  - tier: app.tier_level (tier_1~5)
  - parent_party_id: uuid
  - industry_paper_company_id: bigint
  - industry_paper_mill_id: bigint
  - industry_filler_supplier_id: bigint
  - module: USER-DEFINED
  - organization_id: uuid NOT NULL

app.engagements:
  - party_id: uuid
  - mill_id: bigint  ← Phase 9에서 자동 설정
  - primary_contact_id: uuid  ← Phase 9에서 추가
  - pipeline_definition_id: uuid
  - current_stage_id: uuid
  - status: USER-DEFINED (open/in_progress/on_hold/won/lost/archived)

app.contacts:
  - party_id: uuid
  - full_name: text
  - title: text  (직함)
  - email: text
  - phone: text
  - is_primary: boolean
  ※ fetchPartyDetail의 mapContact가 camelCase 변환:
     full_name → fullName, title → jobTitle

industry.paper_mills:
  - mill_name (name 아님)
  - market_code (country_code 아님)
```

### i18n 핵심
```
messages 위치: src/i18n/messages/{en|ko|ja}.json
쿠키명: NEXT_LOCALE
next-intl 설정: src/i18n/request.ts (정적 import)
언어 전환 컴포넌트: src/components/layout/language-toggle.tsx
  - locales, localeCookieName, localeDisplayNames를 @/i18n/routing에서 import
```

---

## 다음 작업: Phase 10 — Contact CRUD

### 목표
party detail 페이지(`/[module]/parties/[id]`)에서 연락처 추가/편집/삭제.

### 현재 상태
- `PartyContactsList` 컴포넌트가 contacts를 표시하고 "Add Contact" 버튼이 있음
- `contactForm` i18n namespace 존재 (createTitle, editTitle, fullName, title, email, phone, isPrimary, notes...)
- `app.contacts` 스키마: id, party_id, full_name, title, email, phone, is_primary, notes, created_at

### 필요한 파일 (새 창에서 첨부 요청)
1. `src/components/parties/party-contacts-list.tsx`
2. `src/lib/actions/contacts.ts` (없으면 신규 생성)

---

## 중요 교훈 (누적)

1. **ILIKE '%APP%' 절대 금지** — Sappi/Kappa/Pappel 등 오매칭
2. **evidence_level = character(1)** — 'A'만 허용
3. **tier_role enum에 'Subsidiary' 없음** — HQ 사용
4. **app.parties는 app schema** — `.schema('app' as never)` 필수
5. **industry.paper_mills**: `mill_name` / `market_code`
6. **fetchPartyDetail contacts**: camelCase — `fullName` / `jobTitle` (DB는 full_name / title)
7. **next-intl 동적 import 금지** — webpack 빌드 오류, 정적 import 사용
8. **i18n messages 위치**: `src/i18n/messages/` (프로젝트 루트 messages/ 아님)

---

## 새 창 시작 시 체크리스트

1. 이 핸드오프 문서 첨부
2. `src/components/parties/party-contacts-list.tsx` 첨부
3. "Phase 10 시작" 한 마디로 작업 개시
