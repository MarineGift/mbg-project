# 다음 세션 시작 — 핸드오프 v5.1

> **v5 → v5.1 세션 종료 시점**: Phase 5 (Industry ↔ app.parties 통합) 완료. v5의 시나리오 A/B와 별개로, 사용자가 **F-4 (industry ↔ communications 연계)** 작업을 우선순위로 결정. 23개 파일 / 414 insertions / 40 deletions / 3 commits 정리 + push 완료. v5 미해결 (C/B/D/E/F-3) 전체 그대로 이월. 신규 Phase 6 (industry detail 섹션) 진입점 설정.

---

## 첫 메시지 (그대로 복사해서 새 채팅에 붙여넣기)

```
Phase 5 (Industry ↔ app.parties 통합) 완료.
- 'filler' module enum 신설 + app.parties에 industry FK 컬럼 2개 추가
- 423 paper → buyer, 281 filler suppliers → filler 일괄 promotion
- 23개 파일에 filler module 통합 (sidebar, types, zod schemas, i18n 등)
- 3 commits push 완료 (24c6958 / 0827eb4 / 85ca025)
- Omya / Sappi detail 페이지 작동 확인 — 기본 영업 도구 사용 가능

다음 작업 (Phase 6): industry detail 섹션 추가 — paper company 페이지에
mill 리스트 + 각 mill의 supplier 매트릭스, filler supplier 페이지에
공급 중인 mill 매트릭스 표시. 핸드오프 v5.1 첨부합니다.
```

문서 첨부 (이 PROGRESS-NEXT-SESSION-v5.1.md).

---

## 프로젝트 컨텍스트

- **Repo**: https://github.com/MarineGift/mbg-project
- **Branch**: marinebiogroup
- **Local**: C:\dev\mbg-project
- **Org ID**: b25de8f2-1020-482f-9012-183f63883169
- **User ID**: 551fc4a0-b365-47eb-bf2f-0c3f594001c0
- **Stack**: Next.js 14.2, Supabase, Anthropic SDK, TABS Mailer, MailCarrier
- **언어**: 한국어 응답
- **마지막 commit**: `85ca025 feat(filler): integrate filler module across app`
- **사용자 비즈니스 모델**:
  - 제지사(paper company) = 정보·기술 소개 대상 (demand pull)
  - 충전제 공급사(filler supplier) = 직접 계약 대상 (revenue)
  - 한 제지사가 여러 mill(plant) 보유, 각 mill이 여러 supplier와 거래 가능 (N:N)
  - 핵심 영업 정보: **어느 mill이 어떤 supplier와 거래 중인지** = `supplier_mill_linkages`

---

## ✅ 이번 세션에서 완성된 사항

### Phase 5-a — Schema 확장 (`sql/021_industry_app_link.sql`)

1. **`app.module_type` enum에 `'filler'` 추가** — `ALTER TYPE ... ADD VALUE IF NOT EXISTS 'filler'`
2. **`app.parties`에 industry FK 컬럼 2개 추가**:
   - `industry_paper_company_id bigint REFERENCES industry.paper_companies(id) ON DELETE SET NULL`
   - `industry_filler_supplier_id bigint REFERENCES industry.filler_suppliers(id) ON DELETE SET NULL`
3. **CHECK 제약**: `chk_parties_industry_exclusive` — 한 party는 두 industry 테이블 중 하나로만 매핑 가능
4. **`app.engagements`에 `mill_id bigint` 추가** (FK to `industry.paper_mills`) — 향후 mill-level 계약 추적용
5. 파셜 인덱스 + 컬럼 코멘트

### Phase 5-b — Supabase Dashboard

V5에서 `industry` schema는 이미 exposed에 추가됨. 이번 세션에서 추가 작업 없음. 

### Phase 5-c — 일괄 Promotion (`sql/022_industry_promotion.sql`)

핵심 매핑 로직 (모두 idempotent, ON CONFLICT 제거 → WHERE NOT EXISTS 패턴):

```
industry.paper_companies (423 + 660 auto-stubs) 
  → app.parties (module='buyer', industry_paper_company_id=link)
  → 1083 total, 434 real (non-stub), 649 stub

industry.filler_suppliers (281 + 80 auto-stubs)
  → app.parties (module='filler', industry_filler_supplier_id=link)
  → 361 total, 281 real, 80 stub
```

**매핑 함수 신설** (`industry.market_to_iso`, `industry.evidence_to_tier`, `industry.url_to_domain`):

| Industry 필드 | app.parties 필드 |
|---|---|
| `name` | `name` (UNIQUE 없음, 중복 OK) |
| `market_code` (45개) | `country_code` (ISO 2-letter) + `region` ('Europe' for composite) |
| `source_url` | `website` + `domain_normalized` (정규표현식 추출) |
| `evidence_level` (A/B/C) | `tier` ('tier_1'/'tier_2'/'tier_3') |
| `known_filler_types` / `relevant_filler_types` 배열 | `industry_tags` (lowercase + hyphenated) + base tag |
| 전체 V11.4 메타데이터 | `module_data` jsonb (evidence_level, intensity, products, HQ, footprint 등) |

기존 14 buyer 중 paper company 마스터와 이름 일치하는 것 (UPM-Kymmene, Sappi 등) 자동 link.

### Phase 5-d — Filler module 전면 통합 (19개 파일, 61+/40-)

새 module `filler`를 코드베이스 전체에 안전하게 통합. TypeScript의 exhaustiveness check가 모든 누락 지점을 컴파일 에러로 알려줘서 한 번에 잡음:

| 영역 | 파일 | 변경 내용 |
|---|---|---|
| **Type** | `src/types/ai.ts` | `ModuleType` union에 `'filler'` 추가 |
| **사이드바** | `src/components/layout/sidebar.tsx` | `PHASE_1_ACTIVE_MODULES`에 filler 추가, ModuleDot에 `bg-amber-500` (임시 tailwind, 추후 `module-filler` 토큰 정의 권장) |
| **Module badge** | `src/components/common/module-badge.tsx` | `MODULE_STYLES.filler = 'bg-amber-100 text-amber-700'` |
| **List page** | `src/app/(app)/[module]/parties/page.tsx` | `PHASE_1_MODULES` + `MODULE_LABELS.filler='충전제 공급사'` + **stub 제외 기본 필터** (`?include_stubs=1` 토글) |
| **Detail/Edit/New parties + Engagements list/new** | 5개 page.tsx | `PHASE_1_MODULES`에 filler 추가 |
| **Zod schemas** | `actions/engagements.ts`, `actions/parties.ts`, `actions/tasks.ts`, `queries/drafts.ts`, `queries/tasks.ts`, `components/parties/party-form.tsx`, `__tests__/step4/action-schemas.test.ts` | `z.enum([..., 'sales', 'filler'])` 일괄 추가 (PowerShell regex `'sales',? → 'sales', 'filler',?`) |
| **i18n** | `ko.json` / `en.json` / `ja.json` | `modules.filler = "충전제 공급사" / "Filler Suppliers" / "充填剤サプライヤー"` |

### Phase 5-e — UI 검증

- `/filler/parties` → 281개 (stub 제외) 표시 ✅
- `/buyer/parties` → 434개 (real only) 표시 ✅
- `?include_stubs=1` 토글로 전체 1083 표시
- **Omya detail** 페이지: Tier 1, 위치 (CH), 5개 태그, V11.4 notes 전체 노출 ✅
- **Sappi detail** 페이지: Tier 1, 위치 (ZA), 6개 태그, 한글 notes ✅

### Phase 5-f — Git 정리

3개 commit 분리:
```
85ca025 feat(filler): integrate filler module across app           (19 files)
0827eb4 feat(industry): link app.parties to industry master DB     (2 SQL files, 353+)
24c6958 chore: gitignore backups-* patch folders                   (1 file)
```

Push: `531e337..85ca025` (51 objects, 9.25 KiB).

---

## 🚧 남은 미해결 항목 (v5에서 그대로 이월 + Phase 5 잔여)

### 1. ⭐ **Phase 6 — Industry detail 섹션 추가** (다음 세션 최우선)

진짜 영업 가치 만드는 부분. 4개 파일 / 약 500줄 / 한 세션에 완료 가능.

#### A. `src/lib/queries/industry-link.ts` (신규)

```typescript
// paper company id → mills + 각 mill의 linkages
export async function getPaperCompanyIntel(paperCompanyId: number): Promise<{
  company: IndustryPaperCompany;
  mills: Array<IndustryMill & { 
    suppliers: Array<{ supplier_name: string; confidence: string; supply_structure: string }> 
  }>;
  supplier_summary: Array<{ supplier_name: string; mill_count: number; avg_confidence: string }>;
}>;

// filler supplier id → 공급 중인 mill + paper company 리스트
export async function getFillerSupplierIntel(fillerSupplierId: number): Promise<{
  supplier: IndustryFillerSupplier;
  linkages: Array<{
    paper_company_name: string;
    mill_name: string | null;
    market_code: string;
    filler_type: string;
    supply_structure: string;
    confidence_grade: string;
    assessment_scope: string;  // 'Mill-Specific' vs 'Supplier Footprint'
  }>;
  stats: {
    total_links: number;
    mill_specific_links: number;
    footprint_links: number;
    paper_company_count: number;
    avg_confidence: string;
  };
}>;
```

#### B. `src/components/parties/industry-paper-section.tsx` (신규)

회사 메타데이터 + Mill 운영 현황 테이블:

```
┌─ Mill Operations (V11.4) ────────────────────────────────────┐
│  보유 mill: 8개  |  Filler intensity: High  |  Evidence: A     │
│                                                              │
│  ┌──────────────┬─────────┬──────────┬──────────────────┐   │
│  │ Mill         │ City    │ Products │ Known Suppliers  │   │
│  ├──────────────┼─────────┼──────────┼──────────────────┤   │
│  │ Gratkorn     │ AT      │ CWF      │ Omya, Imerys     │   │
│  │ Kirkniemi    │ FI      │ Coated   │ Nordkalk         │   │
│  │ ...          │         │          │                  │   │
│  └──────────────┴─────────┴──────────┴──────────────────┘   │
│                                                              │
│  Supplier Summary (8개 mill 기준):                            │
│  ▌ Omya: 5 mills (A grade)                                   │
│  ▌ Imerys: 2 mills (B grade)                                 │
│  ▌ Nordkalk: 1 mill (A grade)                                │
└──────────────────────────────────────────────────────────────┘
```

#### C. `src/components/parties/industry-filler-section.tsx` (신규)

```
┌─ Supply Footprint (V11.4 verified) ─────────────────────────┐
│  공급 mill: 47개 (mill-specific 23 / footprint 24)            │
│  Paper companies: 18개  |  Avg confidence: B                  │
│                                                              │
│  Mill-Specific 거래 (테이블)                                  │
│  ┌────────────┬──────────────┬──────────┬───────────┐       │
│  │ Paper Co.  │ Mill         │ Filler   │ Confidence│       │
│  ├────────────┼──────────────┼──────────┼───────────┤       │
│  │ Sappi      │ Gratkorn (AT)│ PCC,GCC  │ A         │       │
│  │ Stora Enso │ Skoghall (SE)│ GCC      │ B         │       │
│  │ ...        │              │          │           │       │
│  └────────────┴──────────────┴──────────┴───────────┘       │
│                                                              │
│  Footprint Coverage (mill 단위 미확인, 지역 단위만)            │
│  ▌ Brazil: São Paulo / Mato Grosso do Sul (B grade)          │
└──────────────────────────────────────────────────────────────┘
```

#### D. `src/app/(app)/[module]/parties/[id]/page.tsx` 수정

`full.party.industry_paper_company_id` 있으면 `<IndustryPaperSection>`, `industry_filler_supplier_id` 있으면 `<IndustryFillerSection>` 조건부 렌더.

### 2. ⚠️ **module-filler tailwind 토큰 추가** (작은 정리)

현재 임시로 `bg-amber-500`, `bg-amber-100` 사용. `tailwind.config.ts`에 다음 추가 권장:
```typescript
'module-filler': '...',
'module-filler-foreground': '...',
```
다른 모듈과 일관성 유지. 5분 작업.

### 3. **`search_knowledge` RPC 함수 생성** (v4부터 이월)

```
[prompt-renderer.loadKnowledgeChunks] {
  code: 'PGRST202',
  message: 'Could not find the function public.search_knowledge(...)'
}
```

RAG의 knowledge_chunks 검색이 미작동. graceful skip이라 워커는 안 죽지만 drafter에 knowledge_chunks 컨텍스트 안 들어감 → 본문 짧음 (~89 chars).

### 4. **market_findings 임베딩 생성 (F-3, v5에서 이월)**

`industry.market_findings` 414 row의 `embedding` NULL. `scripts/embed-industry-findings.ts` 신규 작성, OpenAI `text-embedding-3-large` 사용.

### 5. **personal inbox 복귀** (v4 이월)
- `.env.local`의 `MAILCARRIER_POLL_KINDS=personal,role,shared` 복귀
- `app.mailcarrier_state`에 personal row UPSERT

### 6. **env.ts conditional schema** (v4 이월)
- `MAILCARRIER_USERNAME/PASSWORD` 옵셔널화

### 7. **운영 준비** (v4 이월)
- RLS 적용, SMTP STARTTLS, 첨부 발송, `uncaughtException` 핸들러

### 8. **기술부채 (큰 작업)**: ModuleType single source of truth

현재 8개 파일에 module enum 하드코드 (zod, type union, Record 객체). 새 모듈 추가 때마다 N개 파일 patch 필요 — 비효율. 다음 리팩토링:

```typescript
// src/types/module.ts (신규)
import { z } from 'zod';

export const MODULE_TYPES = [
  'investor', 'buyer', 'partner', 'customer',
  'crowdfunding', 'product_launch', 'sales', 'filler',
] as const;

export const moduleTypeSchema = z.enum(MODULE_TYPES);
export type ModuleType = (typeof MODULE_TYPES)[number];
```

각 사용처에서 `import { moduleTypeSchema, MODULE_TYPES }` 사용. 다음 모듈 추가 시 1줄만 바꾸면 됨.

---

## ✅ 현재 상태 — 시스템 동작 확인

| 컴포넌트 | 상태 |
|---|---|
| Schema (app, ai, industry + 신규 FK) | ✅ 모두 동작 |
| MailCarrier worker (role + shared) | ✅ UID 추적 정상 |
| Classifier + Reply Drafter | ✅ camelCase, 0.92 confidence |
| AI Drafts UI | ✅ |
| RAG (search_knowledge) | ⚠️ PGRST202 (graceful skip) |
| Industry master DB | ✅ ~3,200 rows, FK 100%/100%/47% |
| **app.parties (Phase 5 신규)** | ✅ 1083 buyer + 361 filler + 기존 60 |
| **Filler 메뉴 + detail 페이지** | ✅ Omya/Sappi 작동 확인 |

### 모니터링 쿼리 (v5 + Phase 5 추가)

```sql
-- ============================================
-- v5 운영용 (유지)
-- ============================================

-- 1. UID 추적
SELECT kind, username, last_processed_uid, updated_at
FROM app.mailcarrier_state ORDER BY kind;

-- 2. 최근 1시간 inbound + draft 결과
SELECT 
  d.classification_category, d.confidence_score, d.requires_human_approval,
  d.status, c.subject, c.from_address, d.created_at
FROM ai.drafts d
JOIN app.communications c ON c.id = d.inbound_communication_id
WHERE c.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND d.created_at > NOW() - INTERVAL '1 hour'
ORDER BY d.created_at DESC LIMIT 20;

-- ============================================
-- Phase 5 신규 — Industry ↔ app.parties
-- ============================================

-- 3. Module별 분포 (real vs stub)
SELECT 
  module,
  COUNT(*) AS total,
  COUNT(*) FILTER (WHERE notes ILIKE 'Auto-created%') AS stub,
  COUNT(*) FILTER (WHERE notes NOT ILIKE 'Auto-created%' OR notes IS NULL) AS real
FROM app.parties
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND deleted_at IS NULL
GROUP BY module ORDER BY module;

-- 기대 (Phase 5 종료 시점):
--   buyer    : 1083 total / 649 stub / 434 real
--   filler   : 361 total / 80 stub / 281 real
--   investor : 32 (기존)
--   partner  : 14 (기존)
--   customer : 14 (기존)

-- 4. Industry link 매핑 통계
SELECT 
  COUNT(*) FILTER (WHERE industry_paper_company_id IS NOT NULL) AS linked_to_paper,
  COUNT(*) FILTER (WHERE industry_filler_supplier_id IS NOT NULL) AS linked_to_filler,
  COUNT(*) FILTER (WHERE industry_paper_company_id IS NULL 
                   AND industry_filler_supplier_id IS NULL) AS manual_only
FROM app.parties
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND deleted_at IS NULL;

-- 5. Top mill 보유 제지사 (industry 측 — v5 유지)
SELECT pc.name, pc.market_code, COUNT(pm.id) AS mills
FROM industry.paper_companies pc
LEFT JOIN industry.paper_mills pm ON pm.paper_company_id = pc.id
GROUP BY pc.id, pc.name, pc.market_code
HAVING COUNT(pm.id) > 0
ORDER BY mills DESC LIMIT 10;

-- 6. Phase 6 작업 가능 검증 — Sappi (buyer) → mills + supplier matrix
SELECT 
  pm.mill_name, pm.city, pm.main_products,
  STRING_AGG(DISTINCT fs.name, ', ') AS suppliers
FROM app.parties p
JOIN industry.paper_companies pc ON pc.id = p.industry_paper_company_id
JOIN industry.paper_mills pm ON pm.paper_company_id = pc.id
LEFT JOIN industry.supplier_mill_linkages sml ON sml.paper_mill_id = pm.id
LEFT JOIN industry.filler_suppliers fs ON fs.id = sml.filler_supplier_id
WHERE p.module = 'buyer' AND LOWER(p.name) = 'sappi'
GROUP BY pm.id, pm.mill_name, pm.city, pm.main_products
ORDER BY pm.mill_name;

-- 7. Phase 6 — Omya 공급 footprint
SELECT 
  COALESCE(pc.name, sml.paper_company_name_raw) AS paper_company,
  COALESCE(pm.mill_name, sml.mill_site_raw, '(footprint)') AS mill,
  sml.market_code, sml.filler_type, sml.confidence_grade, sml.assessment_scope
FROM app.parties p
JOIN industry.filler_suppliers fs ON fs.id = p.industry_filler_supplier_id
JOIN industry.supplier_mill_linkages sml ON sml.filler_supplier_id = fs.id
LEFT JOIN industry.paper_companies pc ON pc.id = sml.paper_company_id
LEFT JOIN industry.paper_mills pm ON pm.id = sml.paper_mill_id
WHERE p.module = 'filler' AND LOWER(p.name) = 'omya'
LIMIT 20;
```

---

## 환경변수 현재 상태 (v5 유지, 변경 없음)

`.env.local` 핵심 항목:
- `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` (41자 sb_secret_ 신 포맷)
- `SUPABASE_DB_URL`, `SUPABASE_STORAGE_BUCKET_ATTACHMENTS`
- `MAILCARRIER_*`, `MAIL_PERSONAL_*` / `MAIL_ROLE_*` / `MAIL_SHARED_*`
- `MAILCARRIER_POLL_KINDS=role,shared` (personal 비활성 — 다음 세션 복귀)
- `ANTHROPIC_*`, `OPENAI_*`

---

## 이번 세션의 교훈

### 신규 (Phase 5 작업에서 습득)

1. **Module enum 확장은 cross-cutting concern**. `ModuleType` 같은 코어 enum에 값 하나 추가하려면:
   - Type definition (1곳)
   - Zod schemas (5~8곳)
   - Record<ModuleType, ...> 객체 (3~5곳)
   - Route-level whitelist (PHASE_1_MODULES, 6곳)
   - i18n labels (3곳)
   - Tailwind 색상 토큰 (1곳, optional)
   
   결국 19개 파일 patch 필요했음. TypeScript exhaustiveness check가 누락 위치를 컴파일 에러로 알려줘서 한 번에 잡을 수 있었음 — 이게 strict 타입의 진가. 다음번엔 **`MODULE_TYPES` const array를 single source of truth로 만들어 cascade 줄이는 리팩토링** 권장 (위 잔여 항목 8번).

2. **Supabase SQL Editor의 multi-statement 동작 + dotenvx interleaving**. PowerShell 명령에 SQL 주석(`-- ...`) 혹은 SQL에 JS 코드 일부를 잘못 붙여 실행하면 syntax error 발생. 한 도구의 코드를 다른 도구로 잘못 보내는 사고가 여러 번 있었음. **에디터/도구별 syntax를 명확히 구분하는 명시적 라벨링 필요**.

3. **`ALTER TYPE ADD VALUE`의 트랜잭션 제약**. PG 12+에서 트랜잭션 내부 가능하지만 같은 트랜잭션에서 즉시 사용 불가. Supabase SQL Editor는 ';' 단위 auto-commit이므로 다음 statement에서 사용 가능하지만, 안전을 위해 **schema migration (021)과 data migration (022)을 별도 파일로 분리**하는 게 정답.

4. **stub vs real 구분의 가치**. Path A로 자동 생성된 ~660개 stub paper_companies를 promotion했지만, UI에서는 `notes ILIKE 'Auto-created%'` 필터로 기본 제외. 사용자가 `?include_stubs=1` 토글로 reference 접근 가능. **데이터 품질과 사용성의 분리**가 좋은 패턴이었음.

5. **PowerShell regex 치환의 한계 — 한 줄 단순 패턴 vs 멀티라인 블록**. 단순한 `'sales',? → 'sales', 'filler',?` 같은 한 줄 patch는 PowerShell이 깔끔하지만, `PHASE_1_MODULES` 같은 6줄 블록 매칭은 lookahead/lookbehind 복잡도 ↑ + 한 파일이 매치 실패하면 디버깅 어려움. **VS Code Find & Replace의 multi-line regex + 결과 미리보기**가 더 안전. 다만 이번처럼 빌드+TS exhaustiveness가 누락을 잡아주는 경우엔 PowerShell도 OK.

6. **VS Code Find & Replace UI 사용 시 미리보기를 반드시 확인**. 잘못된 regex로 이미 patched된 코드를 "또 patch"하면 중복 추가 사고 발생 가능. Replace All 누르기 전에 결과 미리보기에서 실제 적용될 텍스트 확인 필수.

7. **Supabase enum 값과 코드 enum 값의 형식 일치**. enum은 단수형 (`buyer`, `filler`)이지만 라벨/UI는 복수형 (`Buyers`, `Filler Suppliers`)으로 분리. Supabase SQL에 `'buyers'` 같은 잘못된 단어 넣으면 `invalid input value for enum` 에러. **i18n key는 enum 그대로, label은 별도**가 정답 패턴.

### v4 + v5에서 이월
8. dotenvx 충돌 우회 (PowerShell env 직접 주입)
9. Supabase exposed schemas 필수
10. ESM/CJS XLSX interop (`default` unwrap)
11. Path A trade-off (stub 자동 생성)
12. V11.4 Assessment Scope (Mill-Specific vs Supplier Footprint) — 47% mill 매칭 구조적 정상

---

## 다음 세션 추천 시작 순서

### 🎯 추천: **Phase 6 (Industry detail 섹션) — 1세션 완료**

가장 큰 영업 가치 + 사용자 비즈니스 모델 직접 구현. v5의 시나리오 A(RAG)는 모델/데이터 준비는 됐지만 UI 가치 작음. Phase 6이 plant-level intelligence를 즉시 사용 가능한 형태로 제공.

작업 분할 (한 세션 / ~4시간):

1. **queries** (`src/lib/queries/industry-link.ts`) — 신규 ~150줄
2. **paper section component** (`src/components/parties/industry-paper-section.tsx`) — 신규 ~120줄
3. **filler section component** (`src/components/parties/industry-filler-section.tsx`) — 신규 ~120줄
4. **detail page integration** (`src/app/(app)/[module]/parties/[id]/page.tsx`) — 수정 2~3줄
5. **i18n labels** — 5~10 keys × 3 언어
6. **(optional) tailwind module-filler 토큰** — 5분

검증 시나리오:
- Sappi detail → "Mill Operations" 섹션에 8개 mill + 각 mill의 supplier 표시
- Omya detail → "Supply Footprint" 섹션에 47개 mill + 18개 paper company 표시
- Mill-Specific vs Footprint 구분 명확히

### 대안: **search_knowledge RPC + market_findings 임베딩** (RAG 완성)

v4부터 미해결인 RAG 인프라 완성. 1~2시간 작업. drafter 본문 품질 즉시 개선.

추천 순서: **Phase 6 먼저** (즉시 사용 가치) → 그 다음 RAG (장기 가치)

---

## 디버깅 명령 참고 (PowerShell, v5 유지 + Phase 5 추가)

```powershell
# ─── Worker + 로그 (v5 유지) ──────────────────────
Get-Process node -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep -Seconds 3; $log = "worker-$(Get-Date -Format 'HHmmss').log"; npm run worker:mailcarrier 2>&1 | Tee-Object -FilePath $log

Get-Content -Path .\worker.log -Wait -Tail 50

# ─── Env 직접 주입 (dotenv 우회) ──────────────────
Get-Content .env.local | Where-Object { 
  $_ -and $_ -notmatch '^\s*#' -and $_ -match '=' 
} | ForEach-Object {
  $parts = $_ -split '=', 2
  Set-Item -Path "env:$($parts[0].Trim())" -Value $parts[1].Trim().Trim('"').Trim("'") -ErrorAction SilentlyContinue
}

# ─── git --no-pager + CRLF 경고 제거 ──────────────
git --no-pager diff --stat 2>$null
git --no-pager status --short 2>$null
git --no-pager log --oneline -10 2>$null

# ─── 파일 보기 (괄호 경로 안전) ───────────────────
Get-Content -LiteralPath 'src\app\(app)\[module]\parties\[id]\page.tsx' -Encoding UTF8 | Select-Object -First 50

# ─── Industry detail 작업 시 자주 쓸 검색 ─────────
# Module type 하드코드 위치 (Phase 6에서 또 누락 잡을 때)
Get-ChildItem -Path src -Recurse -Include "*.ts","*.tsx" |
  Select-String -Pattern "'investor'.*'buyer'.*'partner'.*'customer'" -List |
  Select Path

# Record<ModuleType, ...> 객체 누락 후보
Get-ChildItem -Path src -Recurse -Include "*.ts*" |
  Select-String -Pattern "Record<ModuleType" -List |
  Select Path

# ─── Dev 서버 ─────────────────────────────────────
npm run dev

# ─── Build 검증 ───────────────────────────────────
npm run build 2>&1 | Select-Object -Last 20
```

---

## 부록 — Phase 5에서 추가된 신규 파일

| 파일 | 용도 | 크기 |
|---|---|---|
| `sql/021_industry_app_link.sql` | Schema 확장 (enum + FK + mill_id) | 95줄 |
| `sql/022_industry_promotion.sql` | 일괄 promotion + helper functions | 258줄 |

Phase 6에서 추가 예정 (v5.2 작성 시):
- `src/lib/queries/industry-link.ts`
- `src/components/parties/industry-paper-section.tsx`
- `src/components/parties/industry-filler-section.tsx`
- (수정) `src/app/(app)/[module]/parties/[id]/page.tsx`

---

## 참고 — 사용자 비즈니스 컨텍스트 (Phase 6 작업 시 반드시 기억)

```
[YunYoung 사업 흐름]
    │
    │ ① 정보·기술 소개 (marketing pull)
    ▼
[제지사 423곳] ─── 구매 요청 ───▶ [충전제 공급사 281곳]
        │                                  │
        │ N:N via mills                    │ ② 계약 (B2B direct sales)
        │                                  ▼
        ▼                              [YunYoung]
[mill 552개]
```

- 제지사 = `app.parties` module='buyer', 정보 소개 대상
- 충전제 공급사 = `app.parties` module='filler', 직접 계약 대상
- 한 제지사가 여러 mill 보유, 각 mill이 여러 supplier와 거래 가능
- 계약 단위는 mill × supplier (engagement.mill_id로 추적 — 이미 컬럼 추가됨)
- Phase 6의 목적: 영업 담당자가 detail 페이지에서 **"이 회사의 어느 mill이 어떤 supplier와 거래 중인지"** 즉시 확인 가능
