# 다음 세션 시작 — 핸드오프 v5.2

> **v5.1 → v5.2 세션 종료 시점**: Phase 6 (industry detail 섹션) 완료. Sappi에서 Mill Operations 매트릭스 (Somerset Mill의 6개 supplier match + Cloquet/Westbrook의 likely intel) 정상 표시 확인. Omya에서 Supply Footprint (16개 region linkage) 정상 표시 확인. 동시에 **비즈니스 모델 재정의** — 영업 단위가 paper company (HQ)가 아닌 **paper mill plant**임이 명확해짐. Phase 7-a (3-tier 스키마) SQL 마이그레이션 완료. 다음 작업: Phase 7-b TypeScript cascade + plant-level promotion.

---

## 첫 메시지 (그대로 복사해서 새 채팅에 붙여넣기)

```
Phase 6 (industry detail 섹션) 완료.
- IndustryPaperSection: Mill Operations 매트릭스 + likely intel fallback 정상 작동
- IndustryFillerSection: Mill-Specific 거래 / Footprint Coverage 분리 표시
- Sappi (8262f16e...) — 3 mill, Somerset에 6개 supplier 매치 확인
- 데이터 본질 발견: assessment_scope 텍스트가 아닌 paper_mill_id IS NOT NULL이 진짜 mill-specific 기준 (47.4%, V11.4 통계와 일치)

비즈니스 모델 재정의:
- 영업 단위는 paper company HQ가 아닌 paper mill plant
- 3-tier 계층 (group_hq → country_entity → plant) 필요
- 두 진입 경로 (Mill direct / Filler direct)
- plant ↔ plant 매칭이 영업 핵심 데이터

Phase 7-a 완료:
- parent_party_id (self-FK) + party_level enum 컬럼 추가
- app.plant_supply_links 테이블 신설 (filler_plant_id NULL 허용 = 미정 상태)
- party_level 기본값 backfill 'country_entity'

다음 작업 (Phase 7-b): TS cascade (buyer → paper_mill, 17개 파일) +
paper_mills 552개를 plant-level로 promotion + Omya/Sappi 3-tier 재구조화.
핸드오프 v5.2 첨부합니다.
```

문서 첨부 (이 PROGRESS-NEXT-SESSION-v5.2.md).

---

## 프로젝트 컨텍스트

- **Repo**: https://github.com/MarineGift/mbg-project
- **Branch**: marinebiogroup
- **Local**: C:\dev\mbg-project
- **Org ID**: b25de8f2-1020-482f-9012-183f63883169
- **User ID**: 551fc4a0-b365-47eb-bf2f-0c3f594001c0
- **Stack**: Next.js 14.2, Supabase, Anthropic SDK, TABS Mailer, MailCarrier
- **언어**: 한국어 응답
- **마지막 commit (v5.1 시점)**: `85ca025 feat(filler): integrate filler module across app`
- **v5.2 commits 예정**: Phase 6 코드 + Phase 7-a 스키마 (이번 세션은 commit 안 함, 다음 세션에서 정리 권장)

---

## 🎯 비즈니스 모델 (v5.2에서 정밀화)

> **핵심 명제 (1줄)**: 영업 활동은 **Paper Mill 全곳 + Filler Company 全곳**에 정보 송부, 계약은 **Filler Company만**.

```
[YunYoung — Filler 공급 비즈니스 (라이선스/공급 계약)]
       │
       │ 영업 = 정보 송부 (양측 모두)
       │ 계약 = Filler Company만
       ▼
경로 ①: Paper Mill 직접 (정보 풀)
   YunYoung ──기술 정보──▶ Paper Mill Plant
                              │
                              │ "이 충전제 좋네, 누구한테 받지?"
                              ▼
                          Filler Company Plant ──생산·공급──▶ Paper Mill Plant
                              │
                              │ 라이선스/공급 계약
                              ▼
                          YunYoung (revenue)

경로 ②: Filler Company 직접 (B2B)
   YunYoung ──기술 정보──▶ Filler Company Plant
                              │
                              │ Filler가 Paper Mill 자체 영업 (YunYoung 개입 X)
                              ▼
                          Paper Mill Plant
```

### 3-tier 계층 (양측 동일 구조)

| Level | Filler 측 (직접 계약) | Paper Mill 측 (정보 송부) |
|---|---|---|
| **L1: group_hq** | Omya Inc. (Switzerland) | Oji Holdings (Japan), Sappi Limited (ZA) |
| **L2: country_entity** | Omya Korea, Omya Australia | Oji 일본 region, Sappi USA |
| **L3: plant** | Omya Korea Plant #1, #2 | Tomakomai mill, Cloquet mill |

영업 액션은 **L3 plant ↔ L3 plant 매칭**. L2/L1은 정책·관계·검색 그룹화 용도.

### plant_supply_links — 영업 핵심 테이블

```
paper_mill_plant_id ─┐
                     ├──▶ link (supply_status, filler_type, source_channel)
filler_plant_id ─────┘     filler_plant_id NULL = "미정" 상태 정식 표현
```

영업 패턴:
1. Paper Mill 미팅 → filler 미정 → `INSERT (paper_mill_plant_id, NULL, 'inquiry')`
2. 추후 Filler 결정 → 마스터에 없으면 새 Filler Plant party INSERT → `UPDATE filler_plant_id`
3. 시험·검증 → `supply_status` 점진 변경 (`qualification` → `qualified` → `active`)

---

## ✅ 이번 세션에서 완성된 사항

### Phase 6-a — Types + Queries (4 파일)

| 파일 | 용도 | 크기 |
|---|---|---|
| `src/types/industry-link.ts` (신규) | PaperCompanyIntel, FillerSupplierIntel 도메인 타입 | ~130줄 |
| `src/lib/queries/industry-link.ts` (신규) | getPaperCompanyIntel, getFillerSupplierIntel | ~470줄 |
| `src/types/party-detail.ts` (수정) | industryPaperCompanyId / industryFillerSupplierId 필드 추가 | +5줄 |
| `src/lib/queries/party-detail.ts` (수정) | SELECT + RawPartyRow + mapping에 FK 컬럼 통합 | +6줄 |

핵심 설계:
- Cross-schema FK 캐시 이슈 회피 → nested join 안 씀, 별도 쿼리 + JS merge
- `paper_mill_id IS NOT NULL` 기준으로 Mill-Specific 판정 (V11.4 47% 매칭율과 정합)
- `paper_mills.likely_filler_types` 등 fallback intel 컬럼으로 53% unmatched mill에도 영업 가치 표시

### Phase 6-b — UI Components (4 파일)

| 파일 | 용도 |
|---|---|
| `src/components/parties/industry-shared.tsx` (신규) | Meta / StatCell / EvidenceBadge / ConfidenceBadge / truncate 공통 헬퍼 |
| `src/components/parties/industry-paper-section.tsx` (신규) | Mill Operations 카드 (메타 + 4-stat strip + mill 테이블 with likely intel + supplier 요약) |
| `src/components/parties/industry-filler-section.tsx` (신규) | Supply Footprint 카드 (메타 + 5-stat strip + Mill-Specific 테이블 + region별 footprint 그룹) |
| `src/app/(app)/[module]/parties/[id]/page.tsx` (수정) | industry FK 있으면 풀 너비로 조건부 렌더 |

UX: Tailwind 기반 plain div + 공통 amber/emerald accent. 추후 디자인 시스템 다듬을 여지 있음.

### Phase 6-c — 검증 (캡쳐로 확인)

- **Sappi (`8262f16e-4a91-4d13-8548-9d18ad54eb18`)**: 3 mill (Cloquet, Somerset, Westbrook), Somerset에 6개 supplier match (Omya, MTI/Specialty Minerals, Imerys, Mississippi Lime, Thiele Kaolin, IMI Fabi), Cloquet/Westbrook는 likely intel만 표시
- **Omya (`27bfdf49-6a8d-4c3c-9a88-af0ebb90eb5c` = europe_composite)**: 16 footprint linkage (Spain/Italy, Sweden, Finland, Poland 등 region별 그룹화)

### Phase 6-d — 데이터 본질 발견

진단 결과 (`assessment_scope`로 필터 시 mill_specific=0 미스터리):

```sql
SELECT total_linkages, with_mill_fk, with_company_fk, mill_fk_pct
FROM industry.supplier_mill_linkages_stats;
-- total: 817, with_mill_fk: 387, mill_fk_pct: 47.4
```

**진짜 mill-specific 기준은 `paper_mill_id IS NOT NULL`이며 V11.4의 47% 통계와 일치**. `assessment_scope` 텍스트 컬럼은 별개의 자유 텍스트(보조 정보). 

수정된 query (Phase 7-c에서 한 줄 patch로 이미 반영 가능):
```typescript
// industry-link.ts의 getFillerSupplierIntel 안에서
const scope: AssessmentScope = l.paper_mill_id != null 
  ? 'Mill-Specific' 
  : 'Supplier Footprint';
// (기존 toAssessmentScope(l.assessment_scope) 대체)
```

### Phase 7-a — 3-tier 스키마 (SQL)

이번 세션에서 Supabase에 적용 완료:

```sql
-- 1. parties 3-tier 컬럼
ALTER TABLE app.parties ADD COLUMN parent_party_id uuid 
  REFERENCES app.parties(id) ON DELETE SET NULL;
ALTER TABLE app.parties ADD COLUMN party_level text 
  CHECK (party_level IN ('group_hq', 'country_entity', 'plant'));

-- 2. plant_supply_links 신설
CREATE TABLE app.plant_supply_links (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL,
  paper_mill_plant_id uuid NOT NULL REFERENCES app.parties(id),
  filler_plant_id uuid REFERENCES app.parties(id),  -- NULL 허용
  filler_type text,
  supply_status text CHECK (supply_status IN (
    'inquiry', 'qualification', 'qualified', 'active', 'dormant', 'terminated'
  )),
  source_channel text CHECK (source_channel IN (
    'mill_first', 'filler_first', 'industry_master'
  )),
  notes text,
  first_contact_at timestamptz,
  contracted_at timestamptz,
  confidence_grade char(1),
  created_at timestamptz DEFAULT NOW(),
  updated_at timestamptz DEFAULT NOW()
);

-- 3. 인덱스 + RLS
CREATE INDEX idx_psl_paper_mill ON app.plant_supply_links(paper_mill_plant_id);
CREATE INDEX idx_psl_filler ON app.plant_supply_links(filler_plant_id);
CREATE INDEX idx_psl_status ON app.plant_supply_links(supply_status) 
  WHERE supply_status IN ('inquiry', 'qualification', 'active');
CREATE INDEX idx_psl_org ON app.plant_supply_links(organization_id);
ALTER TABLE app.plant_supply_links ENABLE ROW LEVEL SECURITY;
CREATE POLICY plant_supply_links_org_isolation ON app.plant_supply_links
  USING (organization_id = (auth.jwt() ->> 'organization_id')::uuid);

-- 4. party_level backfill (모두 country_entity로 우선)
UPDATE app.parties
SET party_level = 'country_entity'
WHERE party_level IS NULL
  AND module IN ('buyer', 'filler')
  AND organization_id = 'b25de8f2-1020-482f-9012-183f63883169';
```

⚠️ **`buyer` → `paper_mill` enum rename 보류** — TS 코드가 아직 `'buyer'` 문자열로 박혀 있어 rename 시 즉시 UI 깨짐. Phase 7-b의 TS cascade와 함께 한 트랜잭션으로 처리.

---

## 🚧 Phase 7 작업 분할 (다음 세션부터)

### Phase 7-b — TypeScript cascade + buyer rename (1세션, ~3시간)

순서:
1. **PowerShell로 영향 받는 파일 17개 백업** (변경 다 끝나기 전 dev 안 띄움)
   ```powershell
   Get-ChildItem -Path src -Recurse -Include "*.ts","*.tsx" |
     Select-String -Pattern "'buyer'" -List | Select-Object Path
   ```
   결과 (v5.2 시점):
   ```
   app/(app)/[module]/engagements/new/page.tsx
   app/(app)/[module]/engagements/page.tsx
   app/(app)/[module]/parties/new/page.tsx
   app/(app)/[module]/parties/[id]/edit/page.tsx
   app/(app)/[module]/parties/[id]/page.tsx
   app/(app)/[module]/parties/page.tsx
   components/drafts/draft-queue-filters.tsx
   components/layout/sidebar.tsx
   components/parties/party-form.tsx
   lib/actions/engagements.ts
   lib/actions/parties.ts
   lib/actions/tasks.ts
   lib/queries/drafts.ts
   lib/queries/tasks.ts
   scripts/simulate-inbound.ts
   types/ai.ts
   __tests__/ai/claude-client.test.ts
   __tests__/email/auto-send-gate.test.ts
   __tests__/email/processor.test.ts
   __tests__/step4/action-schemas.test.ts
   ```

2. **PowerShell regex로 일괄 치환** (검증 후):
   ```powershell
   # 일괄 'buyer' → 'paper_mill' (코드 안에서)
   Get-ChildItem -Path src -Recurse -Include "*.ts","*.tsx" |
     ForEach-Object {
       (Get-Content $_.FullName -Raw) -replace "'buyer'", "'paper_mill'" |
         Set-Content $_.FullName -NoNewline
     }
   ```

3. **SQL enum rename**:
   ```sql
   ALTER TYPE app.module_type RENAME VALUE 'buyer' TO 'paper_mill';
   ```

4. **i18n 라벨 변경**:
   - `ko.json`: `"buyer": "구매자"` → `"paper_mill": "제지사 (Paper Mill)"`
   - `en.json`: `"buyer": "Buyers"` → `"paper_mill": "Paper Mills"`
   - `ja.json`: 동일

5. **URL routing**: `/buyer/parties` 경로가 깨짐 → 영업 history에 buyer URL 북마크 같은 게 있다면 308 redirect 미들웨어 임시 추가 권장 (없으면 스킵)

6. **빌드 검증**: `npm run build` 통과 + 검증 시나리오 (Sappi paper mill 페이지 작동)

### Phase 7-c — paper_mills plant-level promotion (1세션)

`industry.paper_mills` 552개 → app.parties (party_level='plant') 일괄 insert:

```sql
-- 027_paper_mill_plant_promotion.sql (작성 예정)
INSERT INTO app.parties (
  organization_id, name, module, party_level, parent_party_id,
  country_code, region, industry_paper_mill_id, ...
)
SELECT
  'b25de8f2-...'::uuid,
  pm.mill_name,  -- 또는 'Sappi — Cloquet Mill' 형식 결정 필요
  'paper_mill'::app.module_type,
  'plant'::text,
  (SELECT p.id FROM app.parties p 
   WHERE p.industry_paper_company_id = pm.paper_company_id LIMIT 1),  -- parent = country_entity
  industry.market_to_iso(pm.market_code),
  pm.region,
  -- industry_paper_mill_id FK 컬럼 신규 추가 필요
  pm.id,
  ...
FROM industry.paper_mills pm
WHERE NOT EXISTS (
  SELECT 1 FROM app.parties WHERE industry_paper_mill_id = pm.id
);
```

**결정 사항 (Phase 7-c 시작 전 정함):**
1. 새 FK 컬럼명: `industry_paper_mill_id` (paper company / filler supplier와 동일 패턴)
2. Mill plant 이름 표기: 옵션 2 (`"Sappi — Cloquet Mill"` 형식, parent 정보 inline)
3. 기존 buyer 423개 (country_entity level) 처리: 유지 + plant 552개가 자식으로 매달림 (parent 관계)

### Phase 7-d — Omya/Sappi 3-tier 재구조화 (0.5세션)

V11.4의 region별 분할 → 진짜 group_hq 단위로 정리:

```sql
-- Omya 케이스 — 30개 region row를 정리
-- 1. Omya Inc. (group_hq, Switzerland) row 신규 생성
-- 2. 기존 30개 (id=1, 2, 33, ...) 를 country_entity로 유지하고 parent_party_id = Omya Inc.로 매달기
-- 3. 사용자 영업 진행에 따라 plant level은 점진적 INSERT

-- Sappi 케이스 — 잘못 매핑된 id=807 (usa, 0 mill) → 진짜 Sappi Limited (ZA)로 재link
-- + Sappi 산하 모든 sub-entity를 country_entity로 정리
```

### Phase 7-e — UI 업데이트 (1세션)

1. `IndustryPaperSection` → `IndustryMillSection`으로 재작성 (mill 자체가 주체)
2. **breadcrumb**: "Sappi > Sappi USA > Cloquet Mill" (parent chain 표시)
3. **plant_supply_links CRUD UI**:
   - 새 link 추가 (filler 미정 → NULL 가능)
   - 추후 filler 결정 시 inline edit
   - supply_status 진행 단계 변경
4. mill detail 페이지 — 이 mill의 모든 plant_supply_links 표시

### Phase 7-f — Phase 5 회고 + commit/push (0.5세션)

1. `022_industry_promotion.sql`의 Sappi LIKE 매칭 실패 원인 분석:
   - `LOWER(TRIM(p.name)) = LOWER(TRIM(ipc.name))` 정확 일치였는데 매칭 안 됨
   - 가설: 기존 buyer "Sappi"와 industry "Sappi" 사이 어딘가에 trim되지 않는 공백/제어문자
   - 검증 SQL:
     ```sql
     SELECT LENGTH(name), name, ENCODE(name::bytea, 'hex')
     FROM app.parties WHERE LOWER(name) LIKE 'sappi%' AND module = 'buyer';
     SELECT LENGTH(name), name, ENCODE(name::bytea, 'hex')
     FROM industry.paper_companies WHERE LOWER(name) LIKE 'sappi%';
     ```

2. commit/push:
   - `feat(industry): plant-level promotion + 3-tier hierarchy` (Phase 7 모든 작업 한 묶음)
   - `chore(deprecated): rename buyer module to paper_mill`
   - `feat(supply): plant_supply_links table + UI`

총 Phase 7 = 약 4세션.

---

## 미해결 항목 (v5/v5.1에서 이월, Phase 7 외)

1. **search_knowledge RPC 함수 생성** (v4 이월) — RAG knowledge_chunks 검색 미작동, graceful skip 중
2. **market_findings 임베딩 생성 (F-3, v5 이월)** — `industry.market_findings` 414 row의 `embedding` NULL
3. **personal inbox 복귀** (v4 이월) — `MAILCARRIER_POLL_KINDS=personal,role,shared`
4. **env.ts conditional schema** (v4 이월)
5. **운영 준비** (v4 이월) — RLS 적용, SMTP STARTTLS, 첨부 발송, uncaughtException 핸들러
6. **`tailwind.config.ts`에 `module-filler` 토큰 정의** (v5.1 이월) — 현재 amber-* 직접 사용
7. **ModuleType single source of truth 리팩토링** (v5.1 이월) — `MODULE_TYPES` const array

---

## ✅ 현재 상태 — 시스템 동작 확인

| 컴포넌트 | 상태 |
|---|---|
| Schema (app, ai, industry + 3-tier FK + plant_supply_links) | ✅ Phase 7-a 적용 |
| MailCarrier worker (role + shared) | ✅ |
| Classifier + Reply Drafter | ✅ |
| AI Drafts UI | ✅ |
| RAG (search_knowledge) | ⚠️ PGRST202 (graceful skip) |
| Industry master DB | ✅ ~3,200 rows, FK 100%/100%/47% |
| app.parties (Phase 5 + 6) | ✅ 1083 buyer + 361 filler |
| **app.plant_supply_links** | ✅ 신설, 0 row (영업 시작 전) |
| **IndustryPaperSection / IndustryFillerSection** | ✅ Sappi/Omya로 작동 확인 |
| `buyer` enum value | ⚠️ Phase 7-b에서 `paper_mill`로 rename 예정 |

### 모니터링 쿼리 (v5.2 추가)

```sql
-- 1. 3-tier 분포 (Phase 7-d 진행 시 변화)
SELECT party_level, module, COUNT(*) 
FROM app.parties 
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND deleted_at IS NULL
GROUP BY party_level, module
ORDER BY party_level NULLS LAST, module;

-- 2. plant_supply_links 진행 상황 (영업 KPI)
SELECT supply_status, COUNT(*),
  COUNT(filler_plant_id) AS with_filler,
  COUNT(*) FILTER (WHERE filler_plant_id IS NULL) AS pending_filler
FROM app.plant_supply_links
GROUP BY supply_status
ORDER BY supply_status;

-- 3. parent_party_id 매달림 상태 (3-tier 완성도)
SELECT 
  parent.name AS parent_name,
  parent.party_level AS parent_level,
  COUNT(child.id) AS child_count
FROM app.parties parent
LEFT JOIN app.parties child ON child.parent_party_id = parent.id
WHERE parent.deleted_at IS NULL
  AND parent.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
GROUP BY parent.id, parent.name, parent.party_level
HAVING COUNT(child.id) > 0
ORDER BY child_count DESC LIMIT 20;

-- 4. Phase 6 검증 (계속 유효)
-- 어느 supplier가 mill_specific 풍부한지 (paper_mill_id IS NOT NULL 기준)
SELECT fs.name, fs.market_code,
  COUNT(sml.id) FILTER (WHERE sml.paper_mill_id IS NOT NULL) AS mill_specific,
  COUNT(sml.id) FILTER (WHERE sml.paper_mill_id IS NULL) AS footprint
FROM industry.filler_suppliers fs
JOIN industry.supplier_mill_linkages sml ON sml.filler_supplier_id = fs.id
GROUP BY fs.id, fs.name, fs.market_code
HAVING COUNT(sml.id) FILTER (WHERE sml.paper_mill_id IS NOT NULL) > 0
ORDER BY mill_specific DESC LIMIT 10;
```

---

## 환경변수 현재 상태 (v5 유지, 변경 없음)

`.env.local` 핵심 항목:
- `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` (41자 sb_secret_ 신 포맷)
- `SUPABASE_DB_URL`, `SUPABASE_STORAGE_BUCKET_ATTACHMENTS`
- `MAILCARRIER_*`, `MAIL_PERSONAL_*` / `MAIL_ROLE_*` / `MAIL_SHARED_*`
- `MAILCARRIER_POLL_KINDS=role,shared` (personal 비활성)
- `ANTHROPIC_*`, `OPENAI_*`

---

## 이번 세션의 교훈

### 신규 (Phase 6 + 7-a 작업에서)

1. **Cross-schema FK는 PostgREST 캐시에 안정적으로 안 잡힘** — `ai.drafts → app.parties` 케이스에서 이미 알려진 이슈가 `app.parties → industry.*`에도 동일하게 적용. nested join 대신 별도 쿼리 + JS merge가 안전.

2. **Assessment scope 텍스트 컬럼은 FK보다 후순위** — `assessment_scope = 'Mill-Specific'` 같은 텍스트 필터는 데이터 정합성 보장 약함. `paper_mill_id IS NOT NULL`이 같은 의미를 더 강하게 표현 (FK 무결성 + 47% 통계 검증 가능).

3. **데이터 단위가 영업 단위와 일치하지 않으면 UI가 부정직해진다** — Phase 5의 paper_company-level promotion은 사실 한 추상화 위였음. Sappi 1개 row에 3개 mill 정보를 합쳐 표시하다 보니 영업 액션 단위(mill plant) 정보 가시화에 우회로 필요. Phase 7의 3-tier가 정답.

4. **Industry 마스터 데이터의 region별 분할** — V11.4에는 Omya가 30개 region row로 들어가 있음. Phase 5 promotion이 그대로 30개 party로 복제. 이건 마스터 측 정규화 부재 + promotion 측 그룹화 미사용의 복합 문제. Phase 7-d에서 해결.

5. **dev 환경에서 RSC 캐시는 file change 감지 안 함** — `npm run dev`만으로는 server component 변경 hot reload가 일관되지 않음. 큰 변경 후 `Stop-Process node` + `npm run dev` 재시작이 안전.

6. **SQL placeholder를 안 채우면 Supabase Editor가 친절하지 않다** — `<위 결과의 id>` 같은 자리 표시자는 PowerShell처럼 자동 채워지지 않음. CTE/subquery로 self-contained SQL로 짜는 게 사용자 친화적.

### v5/v5.1에서 이월

7. Module enum 확장은 cross-cutting concern (Phase 7-b에 동일 패턴 적용 예정)
8. dotenvx 충돌 우회 (PowerShell env 직접 주입)
9. Supabase exposed schemas 필수
10. ESM/CJS XLSX interop (`default` unwrap)
11. V11.4 Assessment Scope — Phase 6에서 본질 재정의됨 (위 #2)

---

## 디버깅 명령 참고 (PowerShell)

```powershell
# ─── 빌드 검증 (Phase 7-b 진행 시 필수) ─────────────
npm run build 2>&1 | Select-Object -Last 30

# ─── 'buyer' 잔존 위치 — Phase 7-b 시작 전/후 비교 ─
Get-ChildItem -Path src -Recurse -Include "*.ts","*.tsx" |
  Select-String -Pattern "'buyer'" -List | Select-Object Path

# ─── Phase 6 식별자 확인 ────────────────────────────
Get-ChildItem -Path src -Recurse -Include "*.ts","*.tsx" |
  Select-String -Pattern "industryPaperCompanyId|industryFillerSupplierId|IndustryPaperSection|IndustryFillerSection" |
  Select-Object Path, LineNumber, Line -First 30

# ─── Worker + 로그 (v5 유지) ──────────────────────
Get-Process node -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep -Seconds 3; $log = "worker-$(Get-Date -Format 'HHmmss').log"; npm run worker:mailcarrier 2>&1 | Tee-Object -FilePath $log

# ─── git --no-pager + CRLF 경고 제거 ──────────────
git --no-pager diff --stat 2>$null
git --no-pager status --short 2>$null
git --no-pager log --oneline -10 2>$null

# ─── Dev 서버 (RSC 캐시 무력화 재시작) ────────────
Get-Process node -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep 2
npm run dev
```

---

## 부록 — 신규 / 수정 파일 인벤토리

### Phase 6 (이번 세션)

| 파일 | 상태 |
|---|---|
| `src/types/industry-link.ts` | 신규 |
| `src/lib/queries/industry-link.ts` | 신규 |
| `src/types/party-detail.ts` | 수정 (+5줄) |
| `src/lib/queries/party-detail.ts` | 수정 (+6줄) |
| `src/components/parties/industry-shared.tsx` | 신규 |
| `src/components/parties/industry-paper-section.tsx` | 신규 |
| `src/components/parties/industry-filler-section.tsx` | 신규 |
| `src/app/(app)/[module]/parties/[id]/page.tsx` | 수정 (+10줄) |

### Phase 7-a (이번 세션, SQL만)

- `sql/023_three_tier_schema.sql` (작성 권장 — 이번 세션에서는 인라인 실행만 함)
- `sql/024_plant_supply_links.sql` (작성 권장)

### Phase 7-b/c/d/e (다음 세션 예정)

- `sql/025_paper_mill_id_fk.sql` — `industry_paper_mill_id` FK 추가
- `sql/026_buyer_rename.sql` — enum rename
- `sql/027_paper_mill_plant_promotion.sql` — 552개 plant promotion
- `sql/028_omya_sappi_three_tier.sql` — 3-tier 재구조화
- `src/components/parties/industry-mill-section.tsx` (신규, IndustryPaperSection 대체)
- `src/components/supply-links/*` (신규, plant_supply_links CRUD UI)
- 17개 TS 파일 cascade (`buyer` → `paper_mill`)

---

## 참고 — 사용자 비즈니스 컨텍스트 (Phase 7 작업 시 반드시 기억)

```
[YunYoung 사업 — 충전제 라이선스/공급]
    │
    │ 정보 송부 + 영업
    ▼
[Paper Mill Plants] ─── 일부는 직접 영업 ──▶ [Filler Company Plants]
                       │                         │
                       │ 일부는 Filler가          │ ② 라이선스/공급 계약
                       │   알아서 영업             ▼
                       │                       [YunYoung] (revenue)
                       │
                       └ Paper Mill이 Filler에 spec 요청 (mill_first 채널)
```

- Paper Mill = `app.parties.module='paper_mill'` (Phase 7-b 후), `party_level='plant'`
- Filler Company = `app.parties.module='filler'`, `party_level='plant'`
- 3-tier: group_hq → country_entity → plant (parent_party_id로 chain)
- 영업 핵심 데이터: `app.plant_supply_links` (mill plant ↔ filler plant 매칭)
- `filler_plant_id NULL` 허용 = "Paper Mill 미팅했는데 충전제 미정" 상태 정식 표현
- `supply_status` 단계: inquiry → qualification → qualified → active

Phase 7의 목적: 영업 담당자가 mill plant detail 페이지에서
**"이 plant가 어느 filler plant로부터 어떤 충전제를 공급받고 있는지 / 받기로 했는지 / 아직 미정인지"**를 1차 정보로 확인하고 즉시 영업 액션 가능.
