# URM Platform v5.10 작업 재개 - 핸드오프

## 환경
- Project: marinebiogroup 브랜치, C:\dev\mbg-project
- Stack: Next.js 14.2 + TypeScript + Supabase
- Supabase project: ogenmrgxwhpbfepeldqx
- Organization ID: b25de8f2-1020-482f-9012-183f63883169 (MBG Project)
- 사용자: YunYoung, 한국어-혼합 스타일, "너가 판단해서 진행" 자율 모드
- OS: Windows PowerShell

---

## v5.10 완료 (현재 세션, Git tag: v5.10-stages-flow-families)

### DB 마이그레이션 전체 완료
- **E1** stages 한국어→영어 UPDATE ✅
- **E2** pipeline definitions 이름 영어화 ✅
- **F1** paper_mill sales flow stages (Contact→Spec Review→Sample/NDA→Mill Trial→Quote→Contract→Won/Lost) ✅
- **H1** Klabin family migration ✅
- **H2** Lee & Man family migration ✅
- **H3** Nippon Paper Industries family (HQ + 6 Country + 8 mills) ✅
- **H4** APP Sinar Mas family (HQ + 5 subsidiaries + 6 mills) ✅
- **H5** APRIL Group family (HQ + 2 Country + 3 mills) ✅
- **H6** Fedrigoni family (HQ + 5 Country) ✅
- **H7** Resolute Forest Products + Domtar family (3 HQ + 4 Country + 13 mills) ✅
- **H8** Sappi Limited family (HQ + 4 Country + 12 mills) ✅

### 중복 데이터 정리
- H1/H2 중복 발생 (다중 실행) → supplier_mill_linkages FK 리매핑 후 제거 ✅
- 모든 company/mill 항목 cnt=1 확인 ✅

### 알려진 데이터 노트 (비블로커)
- Sappi Europe / Sappi North America mills가 신규 Country 엔티티 대신
  기존 Regional 엔티티(europe_composite, usa)에 연결됨
  → 데이터 정상 존재, 기능 작동. 추후 cleanup 패치 필요 시 별도 처리

### Git
- Branch: marinebiogroup
- Tag: v5.10-stages-flow-families (pushed)
- Tag: v5.9-pipeline-stages-complete (함께 push됨)

---

## v5.10까지 전체 완성 상태 요약

### 작동 중인 기능
1. **5개 module Kanban** — /investor, /paper_mill, /partner, /customer, /filler engagements
2. **Pipeline Stages Admin** — /settings/pipelines (createStage, updateStage, deleteStage, moveUp, moveDown)
3. **Industry detail pages** — /industry/paper-companies/[id], paper-mills/[id], filler-suppliers/[id]
4. **Sample engagements 21개** — [SAMPLE] prefix, 5 modules
5. **Sidebar i18n** — paper_mill = "Paper Companies"
6. **Global Paper Filler Master Database** — 대형 회사군 family 구조 완성
   - Nippon Paper, APP/Sinar Mas, APRIL Group, Fedrigoni, Resolute/Domtar, Sappi, Klabin, Lee & Man 포함

### DB 스키마 핵심
- `public.tier_role` enum (HQ / Regional_HQ / Country_HQ / Country / Subsidiary / JV / Associate / Branch)
- `industry.paper_companies` — tier_role 컬럼
- `industry.paper_mills` — paper_company_id FK
- `industry.supplier_mill_linkages` — filler_supplier ↔ paper_mill 연결
- `app.pipeline_definitions` + `app.pipeline_stages` — 5개 module pipeline
- `app.engagements` — Kanban 데이터

---

## 다음 작업: Phase 7-b

### 목표
CRM party 관리 시스템의 3-tier 계층 구조 완성

### 세부 작업

#### 7-b-1: TypeScript cascade (tier 자동 계산)
- party 생성/수정 시 parent_id 기반으로 tier 자동 산출
- 예: HQ 하위 → Country, Country 하위 → Subsidiary
- 관련 파일 예상:
  - `src/lib/party/tier-cascade.ts` (신규)
  - `src/app/actions/party.ts` (수정)

#### 7-b-2: Plant-level party promotion
- 현재 paper_mills가 industry DB에만 존재
- CRM party로 "승격(promote)" 기능 구현
  - industry.paper_mills → app.parties 연결
  - promote 버튼 UI (industry detail page)
  - promotion 시 party 자동 생성 + mill_id 연결

#### 7-b-3: 연결 UI
- party detail에서 연결된 mill/company 표시
- industry detail에서 연결된 CRM party 표시 (양방향)

### 관련 스키마 (확인 필요)
```sql
-- app.parties 테이블 구조 확인
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_schema = 'app' AND table_name = 'parties'
ORDER BY ordinal_position;
```

---

## 새 창 시작 시 체크리스트

1. 이 핸드오프 문서 첨부
2. 필요 시 현재 `src/app/actions/party.ts` 파일 첨부
3. 필요 시 `app.parties` 스키마 CSV 첨부 (위 SQL 실행)
4. "Phase 7-b 시작" 한 마디로 작업 개시

---

## 참고: tier_role enum 위치
- ✅ `public.tier_role` (industry 스키마 아님)
- H3~H8 파일에서 `::tier_role` cast로 사용 (industry.tier_role 아님)
