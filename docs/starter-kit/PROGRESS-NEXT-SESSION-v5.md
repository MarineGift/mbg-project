# 다음 세션 시작 — 핸드오프 v5

> **이전 세션(v4 → v5) 종료 시점**: Phase 4 (Industry Master DB 신설 + FK 보강 + Git 정리 + Push) 완료. v4 작업 메뉴 A(Git)와 신규 작업 F(Industry DB)를 한 세션에 완료. v4의 C(`search_knowledge` RPC) / B(personal inbox) / D(env.ts) / E(운영 준비)는 다음 세션으로 이월.

---

## 첫 메시지 (그대로 복사해서 새 채팅에 붙여넣기)

```
Phase 4 (Industry Master DB 신설 + Git 정리) 완료.
industry schema 7개 테이블 + ~3,200 rows 로딩 완료 (paper_mills 100% FK, 
linkages supplier/company 100% / mill 47%). 8개 commit으로 정리 후 push 완료
(df862d7 → b00645b), build 통과. 다음은 search_knowledge RPC (C) 또는 
market_findings 임베딩 (F-3). 핸드오프 v5 문서 첨부합니다.
```

문서 첨부 (이 PROGRESS-NEXT-SESSION-v5.md).

---

## 프로젝트 컨텍스트

- **Repo**: https://github.com/MarineGift/mbg-project
- **Branch**: marinebiogroup
- **Local**: C:\dev\mbg-project
- **Org ID**: b25de8f2-1020-482f-9012-183f63883169
- **User ID**: 551fc4a0-b365-47eb-bf2f-0c3f594001c0
- **Stack**: Next.js 14.2.13, Supabase, Anthropic SDK, TABS Mailer, MailCarrier
- **언어**: 한국어 응답
- **메일서버**: mail.marinebiogroup.com (자체 호스팅, IMAP 143 STARTTLS, SMTP 587 평문)
- **3개 계정**: personal (yunyoung.heo@), role (ceo@), shared (contact@)
- **신규 schema**: `industry.*` (V11.4 paper/filler master DB)
- **마지막 commit**: `b00645b feat(industry): master DB schema and V11.4 Excel loader`

---

## ✅ 이번 세션에서 완성된 사항

### Phase 4-a — Industry Master DB schema 신설

신규 `industry.*` schema에 7개 테이블 생성. 기존 `app.*` (CRM 운영) / `ai.*` (에이전트)와 격리.

**파일**: `sql/020_industry_schema.sql` (317줄, idempotent)

```
industry.markets                 (45 markets seed — Asia/Europe/Americas/MEA/Oceania)
industry.paper_companies         (V11.4 시트 1:1 대응)
industry.paper_mills             (paper_company_id FK, _raw fallback columns 포함)
industry.filler_suppliers
industry.supplier_mill_linkages  (FK × 3: supplier/company/mill, M:N)
industry.market_findings         (vector(3072) — text-embedding-3-large 호환)
industry.verification_queue
```

특징:
- `IF NOT EXISTS` 전체 적용 — 재실행 안전
- `(market_code, legacy_id)` UNIQUE — 엑셀 원본 ID 보존
- `updated_at` 자동 트리거 (`industry.touch_updated_at()`)
- `_raw` 컬럼 (`company_name_raw`, `supplier_name_raw`, `mill_site_raw`) — FK 매칭 실패해도 데이터 손실 없음
- `vector(3072)` 인덱스 없음 (pgvector ivfflat/hnsw 2000 dim 제한, ~459 rows는 시퀀셜 스캔이 instant)
- service_role + authenticated 권한 명시

**적용 경로**: Supabase SQL Editor → 파일 전체 paste → `Success. No rows returned`.

### Phase 4-b — Supabase Dashboard에 industry schema 노출

PostgREST가 기본적으로 `public` 외 schema는 REST API에 노출 안 함. 첫 로더 실행 시 `Invalid schema: industry` 에러.

**해결**: Supabase Dashboard → Project Settings → API → Data API Settings → **Exposed schemas** 에 `industry` 추가. (메뉴 위치는 Supabase UI 개편에 따라 변동 가능)

### Phase 4-c — Excel → DB 로더 작성 및 실행

**파일**: `scripts/load-industry-db.ts` (407줄, 6단계 phased loader)

```typescript
// 핵심 패턴
import { config as loadEnv } from 'dotenv';
loadEnv({ path: '.env.local' });
loadEnv({ path: '.env' });

import * as XLSXNS from 'xlsx';
const XLSX: any = (XLSXNS as any).default ?? XLSXNS;  // ESM/CJS interop

const SUPABASE_URL =
  process.env.SUPABASE_URL ||
  process.env.NEXT_PUBLIC_SUPABASE_URL ||
  // fallback: SUPABASE_DB_URL에서 ref 추출
  (() => {
    const db = process.env.SUPABASE_DB_URL || process.env.DATABASE_URL;
    const m = db?.match(/@(?:db\.)?([^.]+)\.(?:supabase\.co|pooler\.supabase\.com)/);
    return m ? `https://${m[1]}.supabase.co` : undefined;
  })();
```

**실행 결과**:

| Phase | Rows | 비고 |
|---|---|---|
| markets | 45 | seed |
| paper_companies | 423 → 423 + α | mills FK 보강 단계에서 stub 추가됨 |
| filler_suppliers | 281 → 281 + α | linkages FK 보강 단계에서 stub 추가됨 |
| paper_mills | 552 / 552 (100%) | FK 보강 후 |
| supplier_mill_linkages | 817 (sup 100% / comp 100% / mill 47%) | mill 47%는 구조적 정상 |
| market_findings | 414 (embedding NULL) | delete-and-reload 전략 |
| verification_queue | 340 (sup FK 67%) | |

전체 ~3,200 rows.

### Phase 4-d — FK 보강 (Path A: missing companies 자동 생성)

mills 시트의 회사명 380개가 paper_companies와 매칭 안 됨. 원인 진단 결과: cross-market 표기 차이가 아니라 **paper_companies 시트에 아예 없는 경우**가 압도적.

**전략**: mills의 미매칭 회사를 자동으로 paper_companies에 추가 (notes에 'Auto-created from paper_mills' 플래그).

**SQL** (적용 완료):

```sql
-- ① mills의 미매칭 회사를 companies로 promotion
WITH missing_companies AS (
  SELECT DISTINCT 
    pm.company_name_raw AS name,
    pm.market_code,
    MAX(pm.evidence_level) AS evidence_level
  FROM industry.paper_mills pm
  WHERE pm.paper_company_id IS NULL
    AND pm.company_name_raw IS NOT NULL
    AND NOT EXISTS (
      SELECT 1 FROM industry.paper_companies pc 
      WHERE LOWER(pc.name) = LOWER(pm.company_name_raw) 
        AND pc.market_code = pm.market_code
    )
  GROUP BY pm.company_name_raw, pm.market_code
)
INSERT INTO industry.paper_companies 
  (market_code, name, evidence_level, notes)
SELECT market_code, name, evidence_level,
  'Auto-created from paper_mills (no legacy companies entry)'
FROM missing_companies;

-- ② mills FK 재매칭
UPDATE industry.paper_mills pm
SET paper_company_id = pc.id
FROM industry.paper_companies pc
WHERE pm.paper_company_id IS NULL
  AND pm.company_name_raw IS NOT NULL
  AND LOWER(pc.name) = LOWER(pm.company_name_raw)
  AND pc.market_code = pm.market_code;
```

결과: paper_mills FK 매칭률 31.3% → **100% (552/552)**.

**Linkages도 같은 Path A 확장** (suppliers + companies stub 생성 + 재매칭):

```sql
-- linkages 미매칭 companies 자동 생성
INSERT INTO industry.paper_companies (market_code, name, notes)
SELECT DISTINCT l.market_code, l.paper_company_name_raw,
  'Auto-created from supplier_mill_linkages'
FROM industry.supplier_mill_linkages l
WHERE l.paper_company_id IS NULL
  AND l.paper_company_name_raw IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM industry.paper_companies pc 
    WHERE LOWER(pc.name) = LOWER(l.paper_company_name_raw) 
      AND pc.market_code = l.market_code
  );

-- 동일 패턴으로 suppliers stub 생성
INSERT INTO industry.filler_suppliers (market_code, name, notes)
SELECT DISTINCT l.market_code, l.supplier_name_raw,
  'Auto-created from supplier_mill_linkages'
FROM industry.supplier_mill_linkages l
WHERE l.filler_supplier_id IS NULL
  AND l.supplier_name_raw IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM industry.filler_suppliers fs 
    WHERE LOWER(fs.name) = LOWER(l.supplier_name_raw) 
      AND fs.market_code = l.market_code
  );

-- 그 후 linkages.company / linkages.supplier FK 재매칭 UPDATE
```

결과:

| FK | 1차 (단순 매칭) | Path A 확장 후 |
|---|---|---|
| supplier | 559 (68.4%) | **817 (100%)** ✅ |
| company | 361 (44.2%) | **817 (100%)** ✅ |
| mill | 387 (47.4%) | 387 (47.4%) — 변동 없음 |

**mill 47%는 V11.4 데이터 구조의 정상 상태**입니다:

- `All_Reverse_Matrix` 시트는 두 가지 `Assessment Scope`가 섞임:
  - **"Mill-Specific Assessment"** — 실제 특정 mill 명시 (예: "Ban Pong Mill")
  - **"Supplier Footprint"** — region/state 단위 (예: "São Paulo / Mato Grosso do Sul")
- 후자는 paper_mills와 JOIN할 의미 없음. 47.4% 매칭이 데이터의 실제 mill-specific 비율.

### Phase 4-e — Git 정리 + Push

직전 commit `e15d9cc` 이후 누적된 **1,668 insertions / 367 deletions / 31 files**를 8개 의미 단위 commit으로 분리:

```
b00645b feat(industry): master DB schema and V11.4 Excel loader
e54ce53 chore(i18n): translations for engagements, drafts, inbox
c04345f chore(ui): inbox filters, party engagements list, detail tweaks
55bb76e feat(engagements): expanded form with zod refinements and i18n alignment
27905a9 feat(drafts): AI draft pipeline UI and queries
02358bb feat(mail): multi-account IMAP with UID tracking and whitelist
cc9b095 chore(deps): add xlsx and dotenv for industry loader
df862d7 chore: clean up gitignore (data/, worker logs)
```

이 중 핸드오프 v4에 명시된 작업은 02358bb (Phase 2-a/b/c + 3-b), 27905a9 (Phase 3 drafts), 그 안의 `draft-queue-table.tsx` 한 줄 fix (Phase 3-g). 55bb76e (engagements) / c04345f (inbox/parties) 는 핸드오프 미언급이었으나 spot check 결과 명백한 의도 작업으로 확인.

**검증**:
- `git status --short` → clean ✅
- `npm run build` → 21개 라우트 build 통과 ✅
- `git push origin marinebiogroup` → 155 objects, 729 KiB, 정상 동기화 ✅

---

## 🚧 남은 미해결 항목 (다음 세션 우선순위)

### 1. **`search_knowledge` RPC 함수 생성** ⚠️ 최우선 (v4에서 이월)

```
[prompt-renderer.loadKnowledgeChunks] {
  code: 'PGRST202',
  message: 'Could not find the function public.search_knowledge(p_collection, p_limit, p_min_similarity, p_organization_id, p_query_embedding)'
}
```

RAG의 knowledge_chunks 검색이 미작동. graceful skip이라 워커는 안 죽지만:
- drafter에 knowledge_chunks 컨텍스트 안 들어감 → 본문 짧음 (~89 chars)
- brand_voice 비어있을 가능성

**작업 내용**:
- Supabase에 `vector` extension 확인 (이미 industry 작업에서 활성화됨)
- `ai.knowledge_chunks` 테이블 스키마 확인
- `public.search_knowledge` RPC 함수 정의 (parameters: `p_collection, p_limit, p_min_similarity, p_organization_id, p_query_embedding`)
- 결과: `id`, `content`, `metadata`, `similarity` 컬럼 반환
- ivfflat 또는 hnsw 인덱스 (collection별, embedding이 1536 dim이면 인덱스 사용 가능, 3072면 시퀀셜)

### 2. **🆕 market_findings 임베딩 생성 (F-3)**

`industry.market_findings` 414 row의 `embedding` 컬럼이 모두 NULL.

**작업 내용**:
- `scripts/embed-industry-findings.ts` 신규 작성
- OpenAI `text-embedding-3-large` API 사용 (env에 `OPENAI_API_KEY`, `OPENAI_EMBEDDING_MODEL` 이미 있음)
- 배치 처리 (100 row/call, rate limit 고려)
- `embedded_at` 컬럼 갱신
- 임베딩 후 `ai.knowledge_chunks` 테이블에 컨버전하거나, `industry.market_findings` 자체를 RAG 코퍼스로 활용

옵션 결정 필요: market_findings를 별도 schema에서 그대로 RAG 검색 vs `ai.knowledge_chunks`로 통합.

### 3. **🆕 app.communications ↔ industry 연계 (F-4)**

inbound 메일이 paper company / supplier로부터 오면 자동 태깅. 활용:

- Classifier prompt에 "이 메일은 검증된 A-grade 제지사 Sappi Europe (8 mills, 유럽 전역) 로부터" 같은 컨텍스트 주입
- Reply Drafter가 회사별 filler 사용 패턴을 알고 답장 작성
- 미해결 verification_queue 항목 자동 우선순위 조정

**구현**:
- `app.communications` 또는 `app.contacts`에 `industry_paper_company_id` 컬럼 추가
- 발신자 이메일 도메인 → `industry.paper_companies.name` 매칭 로직 (fuzzy)
- prompt-renderer에 새 컨텍스트 블록 추가

### 4. **personal inbox 복귀** (v4 미해결)

- `.env.local`에서 `MAILCARRIER_POLL_KINDS=personal,role,shared` 복귀
- `app.mailcarrier_state`에 personal row UPSERT (uid=9999)
- 워커 재시작 후 30초 후 로그에서 `[mailcarrier:personal] fetch: range=10000:*` 확인

### 5. **env.ts conditional schema** (v4 미해결)

- `MAILCARRIER_USERNAME/PASSWORD` 옵셔널화
- `.refine()` 로 POLL_KINDS 없으면 둘 다 required 검증
- `.env.local`에서 fallback 2줄 제거 가능

### 6. **운영 준비 작업** (v4 미해결, 별도 큰 작업)

- `sql/010_rls_policies.sql` 적용 (현재 service_role 우회 중)
- SMTP STARTTLS 활성화 (현재 평문 587)
- 첨부 발송 기능 구현
- `uncaughtException` 핸들러에서 `process.exit(1)` 으로 변경
- Reply Drafter 본문 길이 문제 — search_knowledge 복구 후 자동 개선 기대

---

## ✅ 현재 상태 — 시스템 동작 확인

### 인프라

| 컴포넌트 | 상태 |
|---|---|
| Schema (app, ai, industry) | ✅ 모두 동작 |
| MailCarrier worker (role + shared) | ✅ UID 추적 정상 |
| Classifier + Reply Drafter | ✅ camelCase, 0.92 confidence |
| AI Drafts UI | ✅ sticky header 제거됨 |
| RAG (search_knowledge) | ⚠️ PGRST202 (graceful skip) |
| Industry master DB | ✅ ~3,200 rows, FK 100%/100%/47% |

### 모니터링 쿼리 (v4 + industry 추가)

```sql
-- ============================================
-- 운영용 (v4 유지)
-- ============================================

-- 1. UID 추적 상태
SELECT kind, username, last_processed_uid, updated_at
FROM app.mailcarrier_state ORDER BY kind;

-- 2. 최근 inbound + draft 결과
SELECT 
  d.classification_category, d.confidence_score, d.requires_human_approval,
  d.status, c.subject, c.from_address, d.created_at
FROM ai.drafts d
JOIN app.communications c ON c.id = d.inbound_communication_id
WHERE c.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND d.created_at > NOW() - INTERVAL '1 hour'
ORDER BY d.created_at DESC LIMIT 20;

-- 3. agent prompt camelCase 검증
SELECT name, LENGTH(system_prompt) AS len,
  (LENGTH(system_prompt) - LENGTH(REPLACE(system_prompt, '"body_plain"', ''))) / LENGTH('"body_plain"') AS body_plain_count,
  (LENGTH(system_prompt) - LENGTH(REPLACE(system_prompt, '"risk_flags"', ''))) / LENGTH('"risk_flags"') AS risk_flags_count
FROM ai.agents
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
ORDER BY role, name;

-- ============================================
-- Industry DB sanity (신규)
-- ============================================

-- 4. Industry 테이블 row 수
SELECT 'paper_companies' AS t, COUNT(*) FROM industry.paper_companies
UNION ALL SELECT 'paper_mills', COUNT(*) FROM industry.paper_mills
UNION ALL SELECT 'filler_suppliers', COUNT(*) FROM industry.filler_suppliers
UNION ALL SELECT 'supplier_mill_linkages', COUNT(*) FROM industry.supplier_mill_linkages
UNION ALL SELECT 'market_findings', COUNT(*) FROM industry.market_findings
UNION ALL SELECT 'verification_queue', COUNT(*) FROM industry.verification_queue;

-- 5. 자동 생성 stub 비율 (Path A trade-off 모니터링)
SELECT 
  (notes LIKE 'Auto-created%') AS is_stub,
  COUNT(*)
FROM industry.paper_companies
GROUP BY 1;

-- 6. Linkages FK 매칭 통계
SELECT 
  COUNT(*) AS total,
  ROUND(100.0*COUNT(filler_supplier_id)/COUNT(*), 1) AS sup_pct,   -- 기대: 100.0
  ROUND(100.0*COUNT(paper_company_id)/COUNT(*), 1) AS comp_pct,    -- 기대: 100.0
  ROUND(100.0*COUNT(paper_mill_id)/COUNT(*), 1) AS mill_pct        -- 기대: 47.4 (구조적)
FROM industry.supplier_mill_linkages;

-- 7. Top 제지사 (mill 보유 기준)
SELECT pc.name, pc.market_code, COUNT(pm.id) AS mills
FROM industry.paper_companies pc
LEFT JOIN industry.paper_mills pm ON pm.paper_company_id = pc.id
GROUP BY pc.id, pc.name, pc.market_code
HAVING COUNT(pm.id) > 0
ORDER BY mills DESC LIMIT 10;

-- 8. Omya가 공급하는 mill 예시
SELECT pm.mill_name, pm.market_code, l.supply_structure, l.confidence_grade
FROM industry.supplier_mill_linkages l
JOIN industry.filler_suppliers fs ON fs.id = l.filler_supplier_id
LEFT JOIN industry.paper_mills pm ON pm.id = l.paper_mill_id
WHERE fs.name ILIKE 'Omya%' LIMIT 20;

-- 9. market_findings 임베딩 진행률 (다음 세션 F-3 작업 후)
SELECT 
  COUNT(*) AS total,
  COUNT(embedding) AS embedded,
  ROUND(100.0*COUNT(embedding)/COUNT(*), 1) AS pct
FROM industry.market_findings;
```

---

## 환경변수 현재 상태

`.env.local` (Next.js 컨벤션, UTF-8 no BOM 확인됨):

```dotenv
# Supabase (Next.js 패턴)
NEXT_PUBLIC_SUPABASE_URL=https://ogenmrgxwhpbfepeldqx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<rotated>
SUPABASE_SERVICE_ROLE_KEY=<rotated, 41 chars (신 포맷 sb_secret_)>
SUPABASE_DB_URL=postgresql://...@aws-0-<region>.pooler.supabase.com:5432/postgres
SUPABASE_STORAGE_BUCKET_ATTACHMENTS=communications-attachments

# IMAP
MAILCARRIER_HOST=mail.marinebiogroup.com
MAILCARRIER_PORT=143
MAILCARRIER_USERNAME=contact@marinebiogroup.com   # fallback (env.ts required, 다음 세션에 옵셔널화)
MAILCARRIER_PASSWORD=<rotated>                    # fallback
MAILCARRIER_USE_IDLE=false
MAILCARRIER_INBOX_FOLDER=INBOX
MAILCARRIER_POLL_INTERVAL_SECONDS=30
MAILCARRIER_TLS_REJECT_UNAUTHORIZED=false
MAILCARRIER_POLL_KINDS=role,shared                # ⚠️ personal 비활성 (다음 세션에서 복귀)

# Multi-account
MAIL_PERSONAL_USERNAME=yunyoung.heo@marinebiogroup.com
MAIL_PERSONAL_PASSWORD=<rotated>
MAIL_PERSONAL_DISPLAY_NAME=YunYoung Heo
MAIL_ROLE_USERNAME=ceo@marinebiogroup.com
MAIL_ROLE_PASSWORD=<rotated>
MAIL_ROLE_DISPLAY_NAME=CEO
MAIL_SHARED_USERNAME=contact@marinebiogroup.com
MAIL_SHARED_PASSWORD=<rotated>
MAIL_SHARED_DISPLAY_NAME=Marinebio Group

# AI
ANTHROPIC_API_KEY=<rotated>
ANTHROPIC_MODEL_OPUS=claude-opus-4-7
ANTHROPIC_MODEL_HAIKU=claude-haiku-4-5-20251001
ANTHROPIC_MODEL_SONNET=claude-sonnet-4-6
OPENAI_API_KEY=<rotated>                          # ✅ quota 결제 완료 (v4)
OPENAI_EMBEDDING_MODEL=text-embedding-3-large
```

⚠️ **`SUPABASE_SERVICE_ROLE_KEY`가 41자 (sb_secret_... 신 포맷)**. supabase-js v2.45+에서 정상 작동. RPC/RLS 작업 시 호환성 이슈 발생하면 supabase-js 버전 확인 (`npm ls @supabase/supabase-js`).

---

## 화이트리스트 (v4 유지)

테이블: `app.email_whitelist` (`015_email_whitelist.sql`)

```sql
SELECT pattern, kind, notes 
FROM app.email_whitelist
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND is_active = true;
```

현재 등록:
- `marinebiogroup.com` (domain) — 자기 도메인
- `marinegift4u@gmail.com` (address) — 테스트용

---

## 이번 세션의 교훈

### 신규 (Phase 4 작업에서 습득)

1. **dotenv vs dotenvx 충돌**. 이 프로젝트는 dotenvx (`◇ injected env (N) from .env.local` 이모지 로그가 hallmark)를 쓰지만, 스크립트가 `import 'dotenv'` 하면 두 라이브러리가 같은 process.env를 두고 경쟁할 수 있음. 가장 안전한 우회: **PowerShell 세션에 직접 env 주입** 후 `npx tsx ...` 실행. 자식 프로세스가 부모 env 상속하므로 어떤 dotenv 라이브러리든 무관.

   ```powershell
   Get-Content .env.local | Where-Object { 
     $_ -and $_ -notmatch '^\s*#' -and $_ -match '=' 
   } | ForEach-Object {
     $parts = $_ -split '=', 2
     Set-Item -Path "env:$($parts[0].Trim())" -Value $parts[1].Trim().Trim('"').Trim("'")
   }
   ```

2. **Supabase non-public schemas는 명시적 노출 필요**. SQL로 `CREATE SCHEMA industry`만 하면 PostgREST API에서 안 보임. Dashboard → Project Settings → API → **Exposed schemas**에 추가해야 supabase-js의 `.schema('industry')` 작동. 적용 후 30초 내 PostgREST 자동 reload.

3. **ESM/CJS XLSX import 호환성**. `xlsx` 패키지는 CommonJS. tsx (ESM) 환경에서 `import * as XLSX from 'xlsx'` 하면 `XLSX.readFile is not a function`. 해결:
   ```typescript
   import * as XLSXNS from 'xlsx';
   const XLSX: any = (XLSXNS as any).default ?? XLSXNS;
   ```
   `XLSXNS.default`로 실제 module.exports가 들어옴. 다른 CJS-only 라이브러리(예: mammoth, papaparse 일부 버전)에도 동일 패턴 적용 가능.

4. **Path A: 자동 stub 생성의 trade-off**. mills 시트에서만 보이는 회사를 paper_companies로 자동 추가하면 FK는 100% 달성하지만, 결과적으로 빈 데이터(이름 + market만 있고 나머지 NULL)가 섞임. `notes` 컬럼에 'Auto-created from...' 플래그로 구분 가능하게 해두고, 분석 쿼리에서 필요 시 필터링. 매칭률 vs 데이터 품질 trade-off는 케이스마다 다름.

5. **V11.4 데이터 구조 이해**. `All_Reverse_Matrix`의 mill 매칭률이 47%인 게 정상인 이유:
   - "Mill-Specific Assessment" rows → 특정 mill 명시, FK 매칭 가능
   - "Supplier Footprint" rows → region/state 단위 ("São Paulo / Mato Grosso do Sul"), 특정 mill 없음, FK 매칭 불가능
   - `Assessment Scope` 컬럼으로 두 그룹 구분 가능. 분석 쿼리 작성 시 이 구분 고려해야 함.

6. **Spot check 없이 git add . 금지**. 1,668 insertions가 누적된 상태였고 핸드오프 미언급 변경(engagements, parties, inbox)도 다수. `git diff <file>`로 의도 확인 후 chunk별 commit이 안전. v4 lesson #7 ("PowerShell regex 치환은 JSX에 위험")의 연장선.

7. **Supabase SQL Editor의 multi-statement 결과 표시 동작**. `SELECT` 여러 개를 한 번에 실행하면 **마지막 SELECT의 결과만** Results 패널에 표시됨. 디버깅 시 의도와 다르게 보일 수 있어서 검증 쿼리는 한 번에 하나씩 또는 UNION ALL로 합치는 게 안전.

### v4에서 이월

8. Schema와 prompt의 case mismatch는 매우 흔한 버그 (v4)
9. Validation 실패 시 fallback이 너무 관대하면 진단이 어려움 (v4)
10. 자체 호스팅 IMAP은 큰 fetch range에 hang (v4)
11. agent prompt가 DB SELECT 매 호출마다 됨 → prompt UPDATE 즉시 반영 (v4)
12. Sticky CSS는 부모 컨테이너 overflow에 민감 (v4)

---

## 다음 세션 추천 시작 순서

이번 세션이 큰 작업을 끝내서 시작 부담이 작습니다. 다음 두 시나리오 추천:

### 시나리오 A — RAG 완성 트랙 (추천)

1. **`search_knowledge` RPC 함수 생성 — 1~2시간**
   - vector extension 확인 (이미 ✅)
   - knowledge_chunks 테이블 스키마 확인
   - RPC 함수 정의 + 인덱스
   - 워커 로그에서 `loadKnowledgeChunks` PGRST202 사라지는지 확인
   - 다음 chitosan 메일 처리 시 body_len 증가 확인 (89 → 200+)

2. **market_findings 임베딩 (F-3) — 30분~1시간**
   - `scripts/embed-industry-findings.ts` 작성
   - OpenAI text-embedding-3-large 배치 호출
   - 414 row 임베딩 완료
   - `ai.knowledge_chunks`로 마이그레이션 옵션 결정

3. **app.communications ↔ industry 연계 (F-4) — 2~3시간** (선택)

이 흐름은 메일 자동화 시스템의 가치가 가장 크게 올라가는 경로.

### 시나리오 B — 운영 안정화 트랙

1. **personal inbox 복귀 — 15분** (v4의 옵션 A)
2. **env.ts conditional schema — 15분**
3. **운영 준비 (RLS 적용, SMTP STARTTLS) — 2~3시간**

운영 단계 진입을 위한 기초.

→ **시나리오 A 우선 권장**. RAG 복구가 v4부터 미해결로 가장 오래 끌렸고, industry DB 작업 후 효과가 극대화됨.

---

## 디버깅 명령 참고 (PowerShell)

```powershell
# ─── 워커 + 로그 (v4 유지) ─────────────────────────
Get-Process node -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep -Seconds 3; $log = "worker-$(Get-Date -Format 'HHmmss').log"; npm run worker:mailcarrier 2>&1 | Tee-Object -FilePath $log

Get-Content -Path .\worker.log -Encoding UTF8 | Select-String -Pattern "classifier|drafter|invalid|embedding|search_knowledge" | Select-Object -Last 30

Get-Content -Path .\worker.log -Wait -Tail 50

# ─── Env 직접 주입 (dotenv 우회 — 신규) ──────────────
Get-Content .env.local | Where-Object { 
  $_ -and $_ -notmatch '^\s*#' -and $_ -match '=' 
} | ForEach-Object {
  $parts = $_ -split '=', 2
  Set-Item -Path "env:$($parts[0].Trim())" -Value $parts[1].Trim().Trim('"').Trim("'") -ErrorAction SilentlyContinue
}

# ─── Industry 로더 재실행 (V11.5 나오면) ──────────────
# 1) 새 엑셀을 ./data/ 에 두기 (파일명 변경 시 인자로 경로 전달)
# 2) env 주입 후
npx tsx scripts/load-industry-db.ts ./data/Global_Paper_Filler_Master_Database_45_V11_5.xlsx
# 3) FK 보강 SQL 재실행 (위 모니터링 쿼리 §6 결과 보고 결정)

# ─── git --no-pager + CRLF 경고 제거 ────────────────
git --no-pager diff --stat 2>$null
git --no-pager status --short 2>$null

# ─── 파일 일부 보기 ───────────────────────────────
Get-Content -Path .\src\<path> -Encoding UTF8 | Select-Object -Skip <N> -First <M>
```

---

## 참고 — Phase 3 (이전 세션 v4) 정리

Phase 3에서 해결된 classifier + reply_drafter prompt camelCase 수정은 이번 세션에서도 영향 없이 정상 작동 중. 새 메일 들어올 때마다 `category=information_request / confidence=0.92` 형식 유지.

Phase 2-c의 UID 추적 메커니즘도 정상. role inbox는 점진적으로 uid 증가 (마지막 측정 12200대 → 워커 진행 따라 증가).

---

## 부록 — 신규 파일 명세

이번 세션에 추가된 핵심 파일들:

| 파일 | 용도 | 크기 |
|---|---|---|
| `sql/020_industry_schema.sql` | Industry schema 마이그레이션 | 317줄 |
| `scripts/load-industry-db.ts` | V11.4 Excel → DB 로더 | 407줄 |
| `data/Global_Paper_Filler_Master_Database_45_V11_4.xlsx` | V11.4 마스터 데이터 (`.gitignore`로 제외, ~520KB) | — |

다음 세션에서 추가 예상:
- `scripts/embed-industry-findings.ts` (F-3)
- `sql/021_search_knowledge_rpc.sql` (C)
- `sql/022_communications_industry_link.sql` (F-4)
