# URM Platform Handoff v5.7

**날짜**: 2026-05-15
**이전**: v5.6 (2026-05-15)
**다음**: v5.8 (사이드바 + family 정리 / #27 + Step A-2)

---

## v5.6 → v5.7 변경점

### 핵심 성과 — Industry 3페이지 완성 🎉

v5.6에서 paper-mills만 작동하던 상태에서, v5.7에서 paper-companies + filler-suppliers 두 페이지 추가 paste + 시각 검증 완료. **IndustryTabs 3 tab 모두 활성 페이지 연결 (404 0개)**.

추가로 본 세션 초반에 shadcn CLI가 silently 기존 컴포넌트를 Tailwind v4 syntax로 덮어쓰는 함정 발견 + revert. paper-mills 검색 OR에서 paper_company.name 누락 발견 + 2-stage pre-fetch 패턴으로 fix.

### 본 세션 commit 5개

| SHA | Step | 작업 |
|---|---|---|
| `19e4ec4` | v5.6 본작업 잔여 | feat: paper-mills 552 mill listing |
| `3e674f1` | v5.7 Step 0 | chore: shadcn components.json (style: new-york, v3-safe) |
| `05c04e2` | v5.7 Step 1 | fix: paper_company.name 검색 포함 (Sappi NA 누락 해결) |
| `61d9d8b` | v5.7 Step 2 | feat: paper-companies 1054 company + Tier + Evidence |
| `2818fb2` | v5.7 Step 3 | feat: filler-suppliers 361 supplier + Type/Role + Filler Types ARRAY |

5 commit 모두 `origin/marinebiogroup` 반영 완료.

### Industry UI 최종 파일 트리

```
src/app/(app)/industry/
├── layout.tsx                          ✅ IndustryTabs wrapper
├── IndustryTabs.tsx                    ✅ 3 tabs (모두 활성 페이지 연결)
├── page.tsx                            ✅ redirect → paper-mills
├── paper-mills/
│   ├── page.tsx                        ✅ 552 mills + paper_company embed (검색 OR fix)
│   └── PaperMillsTable.tsx             ✅ TierRoleBadge
├── paper-companies/
│   ├── page.tsx                        ✅ 1054 companies + tier 필터
│   └── PaperCompaniesTable.tsx         ✅ Tier + Evidence 배지
└── filler-suppliers/
    ├── page.tsx                        ✅ 361 suppliers
    └── FillerSuppliersTable.tsx        ✅ Type/Role 스택 + Filler Types Badge ARRAY
```

### Sappi family 시각 검증 결과 (paper-companies)

검색 `sappi` → **8 row 출력** (기대 6 + 2):

| ID | Name | Tier | Market |
|---|---|---|---|
| 1 | Sappi Europe | 🔵 Regional | europe_composite |
| 54 | Sappi North America | 🔵 Regional | usa |
| 204 | Sappi Limited | 🟣 HQ | south_africa |
| 370 | Sappi Italy | 🟢 Country | italy |
| 396 | Sappi Portugal | 🟢 Country | portugal |
| 404 | Crown Van Gelder / Sappi UK closures | — | united_kingdom |
| 446 | [Sappi closed UK mills] | — | united_kingdom |
| 1018 | Sappi Finland | 🟢 Country | finland |

**4 tier_role 색깔 모두 한 화면**: HQ × 1 + Regional × 2 + Country × 3 + NULL × 2.

### Sappi family 시각 검증 결과 (paper-mills, fix 적용 후)

검색 `sappi` → **13 row 출력** (10 → 13 증가, NA 3 mill 추가됨):
- 🟣 HQ × 4 (Sappi Limited 산하 south_africa)
- 🟢 Country × 1 (Sappi Finland)
- 🔵 Regional × 6 (Sappi Europe 3 + Sappi NA 3)
- — × 2 (Sector + Closed UK)

---

## v5.7 lessons (#19~#23)

### Lesson #19: shadcn `style: "radix-nova"`는 Tailwind v3 환경에 치명적

신규 shadcn CLI는 `radix-nova` 스타일을 기본으로 제시. v3 프로젝트에선 components.json `"style": "new-york"` 명시 필수.

증상 (반전된 후 인지):
- globals.css에 `oklch(...)` 색공간 + `@import "tw-animate-css"` (미설치) 주입
- button.tsx에 `[a]:hover:`, `not-aria-[haspopup]:`, `has-data-[icon=inline-end]:` 같은 v4 전용 selector
- `import { Slot } from "radix-ui"` (monorepo 메타 패키지) — v3 프로젝트는 `@radix-ui/react-slot` 개별 설치

복구: `git restore` 4 파일 + components.json `"style"` 필드만 안전한 값으로 교체.

```powershell
# 안전한 components.json 작성
$json = @'
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "new-york",
  ...
}
'@
Set-Content components.json $json
```

### Lesson #20: `shadcn add <comp>`는 기존 button/input/select/globals.css까지 silently 덮어씀

`npx shadcn add badge table` 호출 시 의도한 새 컴포넌트만 추가되는 게 아니라:
- 기존 button.tsx / input.tsx / select.tsx 통째 교체
- globals.css 색 변수 + import 라인 교체  
- src/lib/utils.ts cn 함수 cosmetic 덮어쓰기
- components.json 신규 생성 (`radix-nova` style)

**대책**:
1. `shadcn add` 호출 전: `git status` clean state 확인
2. `shadcn add` 호출 후: 즉시 `git diff` 변경분 검토
3. 의도 외 변경 발견 시 `git restore` 즉시 revert
4. components.json은 `style` 필드 확정 후 commit (재발 차단)

### Lesson #21: tier_role은 paper_companies에만, paper_mills는 FK로 연결

화면 표시 tier 배지는:
```typescript
<TierRoleBadge tier={mill.paper_company?.tier_role ?? null} />
```

즉 mill의 tier는 mill이 소속된 paper_company의 tier_role을 그대로 읽음. **paper_mills.tier_role 컬럼 자체가 없음** (SQL `column does not exist` 에러로 확인).

설계 의미:
- mill은 "물리적 plant" 사실 → 안정
- tier_role은 "조직 구조" 사실 → 변경 가능
- mill의 모회사가 바뀌면 paper_company_id만 갈아끼우면 됨
- paper_company의 tier_role을 바꾸면 해당 회사 산하 모든 mill의 표시 tier가 동시에 갱신

v5.5의 옵션 B (paper_mills 단일 정본) 설계와 일관.

### Lesson #22: Supabase nested OR 미지원 — 2-stage pre-fetch 패턴

`millsQuery.or('mill_name.ilike.X,paper_company.name.ilike.X')` 같은 nested table OR 검색은 Supabase JS client에서 작동 안 함. **2-stage 패턴**:

```typescript
// Stage 1: paper_company.name 매치하는 ID 먼저 조회
const { data: matchingCompanies } = await supabase
  .schema('industry' as never)
  .from('paper_companies')
  .select('id')
  .ilike('name', `%${q}%`)

const companyIds = (matchingCompanies ?? []).map(c => c.id)

// Stage 2: OR 조건에 paper_company_id.in.(...) 추가
const orParts = [
  `mill_name.ilike.%${q}%`,
  `city.ilike.%${q}%`,
  `main_products.ilike.%${q}%`,
]
if (companyIds.length > 0) {
  orParts.push(`paper_company_id.in.(${companyIds.join(',')})`)
}
millsQuery = millsQuery.or(orParts.join(','))
```

ARRAY 컬럼 검색(relevant_filler_types)도 동일 패턴 필요 → #37로 등록.

### Lesson #23: VS Code Explorer 캐시 stale

새 폴더(filler-suppliers) 생성 후 인접 폴더(paper-mills)의 파일 일부가 Explorer 트리에서 안 보이는 현상 발생. 파일 자체는 디스크에 존재 (`Get-ChildItem`으로 검증). 

**대책**:
- `Ctrl+Shift+P` → "Reload Window"
- 또는 폴더 우클릭 → Refresh
- 또는 VS Code 검색창 비우기

증상 발견 시 PowerShell `Get-ChildItem`으로 디스크 진실 확인 우선.

---

## 미해결 항목 (v5.8+ 작업)

### v5.6에서 그대로 유지

- **#8**: Supabase 타입 재생성 (`.schema('industry' as never)` 캐스팅 + 새 컬럼 반영)
- **#9**: i18n 라벨 cosmetic
- **#12**: 3-tier 운영화 (parent_party_id backfill)
- **#15**: compound entity 정책 (12 family에 일반화)
- **#18**: 옵션 B paper_mills 단일 정본 — 12 family 반복
- **#19**: `app.parties.tier` (tier_level ENUM) 의미 파악
- **#20**: `paper_mills.mill_name` 정규화 (Sappi 화면에서 KwaZulu-Natal 중복 확인됨)
- **#21**: `paper_companies` → `app.parties` 022 promotion script bug audit
- **#22**: `app.parties.party_level` ↔ `industry.tier_role` 정합성
- **#23**: `paper_mills` multi-region rollup split (8+)
- **#24**: `industry.market_findings`, `industry.verification_queue` 정체 파악

### v5.6 신규 (v5.7에서 #25, #26, #28 해결)

- ✅ #25: /industry/paper-companies 페이지 — **해결됨 (commit 61d9d8b)**
- ✅ #26: /industry/filler-suppliers 페이지 — **해결됨 (commit 2818fb2)**
- ⏸ **#27**: 사이드바 Industry 메뉴 — v5.8 Step 4
- ✅ #28: Sappi 시각 검증 — **해결됨 (8 row 4 tier 색깔 확인)**
- ⏸ **#29**: globals.css `--font-sans` ↔ `--font-geist-sans` alias 점검 — 현재 동작 정상이라 우선순위 낮음

### v5.7 신규 (#30~#43)

**v5.7 작업 중 발견한 데이터/구조 이슈**:

- **#30**: PaperMillsTable.tsx의 일부 fallback 문자열이 한국어 콘솔 출력에서 `'??}`로 깨져 보임 — 실제 파일은 `'—'` (em-dash) 정상 저장된 것으로 추정. 확인 audit 항목
- **#31**: paper_mills 화면에서 Sappi Limited 산하 4 row의 mill_name이 광역주 단위 (`KwaZulu-Natal` 2회 중복) — #20 (paper_mills.mill_name 정규화)에 통합
- **#32**: paper_companies 1054 > paper_mills 552 — 회사가 mill보다 2배. 0-mill orphan companies audit 필요
- **#33**: Sappi Limited `headquarters` 필드가 `"Public — JSE-listed"` (회사 성격 메모). 실제 HQ는 Johannesburg/South Africa여야 함 → data fix
- **#34**: Crown Van Gelder는 네덜란드 회사인데 `[Sappi closed UK mills]` 라벨 하에 분류 → 라벨 정정
- **#35**: Sappi NA `main_products`에 한국어 리서치 메모 (`"미국 mill 3개: Cloquet MN ..."`) → 별도 `notes` 컬럼 이동
- **#36**: Evidence 컬럼 대부분 비어 있음 (Sappi 8 row 중 1 row만 B) → Sappi family evidence_level audit 필요
- **#37**: ARRAY 컬럼 검색 (relevant_filler_types) — 2-stage pre-fetch (`.contains()` 또는 RPC) 패턴 필요
- **#38**: filler_suppliers 동일명 split (Omya×2, Imerys×2, MTI×2 등) — Step B 작업, v5.5의 paper-side와 같은 패턴
- **#39**: paper_companies의 main_product_category + main_products를 filler-suppliers처럼 2-라인 스택으로 표시 일관성 검토
- **#40**: filler_suppliers 전체 361 row tier_role NULL — Step B 정리 진입 후 일괄 채움
- **#41**: filler_plants 0 row — 데이터 채워질 때까지 페이지 보류
- **#42**: Sappi family 외 11 family (Mondi 43, Stora Enso 24, UPM 26, Smurfit 26, Metsä 8, Fedrigoni 9 등) 정리 미진행 — Step A-2 핵심 작업
- **#43**: 핸드오프 v5.6 #19 (paper_companies → app.parties 022 promotion script) 점검 미진행

---

## v5.8+ Step 재정의

### Step 4 — 사이드바 Industry 메뉴 (#27)

- 사이드바 컴포넌트 위치 파악 먼저 (`src/components/` 트리 점검)
- "Industry" 섹션 추가 + 하위 "Paper Mills / Companies / Fillers" 링크 3개
- i18n 라벨 (한국어/영어) 추가
- 현재 사이드바: Dashboard / AI Drafts (52) / Inbox / Tasks / Parties (5) / Engagements (5) / Settings — 이 사이에 Industry 끼워넣기

### Step A-2 — 다음 family 정리 (가장 시간 소요, autonomous Claude 작업 후보)

**우선순위 추천**:
1. **Mondi 43 mill** — 가장 큰 family, Sappi와 유사 패턴 (Limited + Europe + 다수 country)
2. **Stora Enso 24** — Finnish + Swedish, country/regional tier 활발
3. **UPM 26** — Finnish, paper + biofuels
4. **Smurfit 26** — packaging focus (Smurfit Westrock 합병 영향 반영)
5. **Metsä 8** — Finnish, 소규모 빠른 정리
6. **Fedrigoni 9** — Italian specialty, 소규모 빠른 정리

각 family당 작업:
- paper_companies tier_role 할당 (HQ/Regional/Country)
- paper_mills.paper_company_id 재할당
- mill_name 정규화 (#20)
- multi-region rollup split (#23)
- compound entity policy 적용 (#15)
- evidence_level 채움 (#36 일반화)

### Step B — Filler side 정리

- Omya 31, Imerys 38, Artemyn 39, MTI 34 동일명 split (#38)
- Artemyn ↔ Imerys (former assets) 통합 정책
- MTI ↔ Specialty Minerals (모자회사) 정책
- filler_suppliers tier_role 일괄 채움 (#40)
- ARRAY 검색 구현 (#37)

### Step C — paper_mills 측 정리

- mill_name 정규화 (#20: 광역주/country 이름 → 도시 단위)
- multi-region rollup split (#23: 8+ row)
- paper_mills 전체 audit으로 dirty row 추가 발견

### UI Phase 3 — 향후 페이지 확장 (v5.9+)

- mill 상세 페이지 (`/industry/paper-mills/[id]`)
- company 상세 페이지 (`/industry/paper-companies/[id]`)
- supplier 상세 페이지 (`/industry/filler-suppliers/[id]`)
- filler_plants 활성화 (데이터 입력 후)

---

## Phase 7-c 진입 조건 + 현재 상태

- ✅ Schema 발견 완료 (v5.4 18+ audit + v5.5 추가 발견)
- ✅ industry.filler_plants 신설 (0 row, 비활성)
- ✅ 명명 컨벤션 (3-info 모델 + 4 role)
- ✅ #17 옵션 A 적용 (tier_role ENUM)
- ✅ #18 옵션 B 진입 (paper_mills 단일 정본)
- ✅ Sappi family 첫 정리 (8 row, 시각 검증 완료)
- ✅ app.parties.industry_paper_mill_id 컬럼 + FK + 인덱스
- ✅ RLS 4 테이블 enable + SELECT policy
- ✅ UI Phase A + B 완료 (v5.6)
- ✅ **UI Phase 2 완료 — Industry 3페이지 작동 (v5.7)**
- ⏸ 사이드바 Industry 메뉴 (#27, v5.8 Step 4)
- ⏸ 12 multinational family 정리 (Step A-2, v5.8+ 핵심 작업)
- ⏸ filler side 정리 (Step B, v5.8+)
- ⏸ paper_mills 정리 (Step C, #20 + #23)
- ⏸ data fix 다수 (#33~#36, #41)
- ⏸ ARRAY 검색 (#37)

---

## v5.7 끝나는 시점 정확한 상태

### 본인 환경

```
Stack:               Next.js 14.2.35, TypeScript strict, Supabase, shadcn/ui (style: new-york), Tailwind v3
프로젝트 경로:        C:/dev/mbg-project
Branch:              marinebiogroup (origin 동기 완료)
Route group:         (app)/industry/ — 3 페이지 모두 호스트
Supabase:            ogenmrgxwhpbfepeldqx (mbg-project)
함수:                createSupabaseServerClient (src/lib/supabase/server.ts)
Schema 호출:          .schema('industry' as never) (#8 미해결)
Geist 폰트:          geist npm package (v5.6 결정 유지)
shadcn style:        new-york (v5.7 Step 0에서 radix-nova → new-york 교체, v3-safe)
```

### 즉시 이어받을 작업 (v5.8 시작점)

**Step 4 — 사이드바 Industry 메뉴 (#27)**:
1. 사이드바 컴포넌트 위치 파악: `Get-ChildItem src/components -Recurse -Filter "*idebar*"`
2. 현재 라벨 패턴 확인 (Dashboard / AI Drafts / Inbox 등)
3. "Industry" 섹션 추가 + 3 하위 링크
4. i18n 라벨 등록

**Step A-2 — 다음 family 정리** (autonomous Claude 작업 강력 추천):
- Mondi 43 → Stora Enso 24 + UPM 26 → Smurfit 26 + Metsä 8 + Fedrigoni 9 순서
- 자세한 prompt는 본 문서 하단 참조

### 알려진 미해결 — UI 측

- `.schema('industry' as never)` 캐스팅 (#8)
- `--font-sans` ↔ `--font-geist-sans` 변수명 점검 (#29) — 현재 동작 정상이라 보류
- ARRAY 검색 미구현 (#37)
- 사이드바 메뉴 (#27)

---

## 다음 세션 시작 프롬프트 (template)

### A. v5.8 본 작업 (사이드바 + family 정리)

```
v5.7 핸드오프 첨부합니다. Industry 3페이지 완성 마일스톤 달성
(paper-mills 552 + paper-companies 1054 + filler-suppliers 361 모두 작동).

v5.8에서 이어서:
1. Step 4 사이드바 Industry 메뉴 추가 (#27)
2. Step A-2 다음 family 정리 진입 (Mondi 43 우선)
   또는 Step B filler side 정리 (#37, #38, #40)
   또는 Step C paper_mills 정리 (#20, #23)

체크리스트 처음 진입 시:
- 작업 시작 전 git pull origin marinebiogroup 권장
- shadcn add 사용 시 v5.7 Lesson #19, #20 준수
- VS Code Explorer 새로고침 시 #23 참조
```

### B. Autonomous Claude — Mondi family 연구 (가장 시간 소요 작업)

```
v5.7 핸드오프 첨부. Mondi family 정리 진입.

먼저 Supabase에서 다음 두 쿼리 결과 (CSV) 첨부:

1) 현재 Mondi 관련 paper_companies row:
   select id, name, market_code, headquarters, tier_role, evidence_level,
          main_product_category, main_products, europe_mills_footprint,
          source_url, notes
   from industry.paper_companies
   where lower(name) like '%mondi%'
   order by id;

2) 현재 Mondi family 산하 paper_mills row (~43):
   select pm.id, pm.mill_name, pm.market_code, pm.city, pm.main_products,
          pc.name as paper_company_name, pc.tier_role
   from industry.paper_mills pm
   left join industry.paper_companies pc on pc.id = pm.paper_company_id
   where lower(pc.name) like '%mondi%'
      or lower(pm.mill_name) like '%mondi%'
   order by pm.id;

위 두 결과 받으면 Claude가 다음 작업:
- Mondi family tree 구조 (HQ → Regional → Country) 연구
- 각 mill의 적절한 paper_company 재할당 매핑
- tier_role 일괄 채움 SQL (UPDATE statements)
- 누락된 paper_companies row INSERT SQL (회사 미등록 시)
- mill_name 정규화 후보 (#20 적용)
- multi-region rollup split (#23 적용)
- evidence_level 추천값 + 출처 URL
- 위험 / 주의 항목 메모

산출물: 그대로 Supabase SQL Editor에 paste 가능한 마이그레이션 스크립트
```

### C. Autonomous Claude — Stora Enso + UPM 연구

```
v5.7 핸드오프 첨부. Stora Enso + UPM family 두 개 동시 정리 (Finnish/Swedish 유사 프로파일).

다음 SQL 결과 4개 첨부:

1) Stora Enso paper_companies (보통 ~5-10 row 예상):
   select id, name, market_code, headquarters, tier_role, evidence_level, notes
   from industry.paper_companies
   where lower(name) like '%stora%enso%' or lower(name) like '%stora enso%'
   order by id;

2) Stora Enso paper_mills (~24):
   select pm.id, pm.mill_name, pm.market_code, pm.city, pm.main_products,
          pc.name as paper_company_name, pc.tier_role
   from industry.paper_mills pm
   left join industry.paper_companies pc on pc.id = pm.paper_company_id
   where lower(pc.name) like '%stora%enso%'
      or lower(pm.mill_name) like '%stora%'
   order by pm.id;

3) UPM paper_companies:
   select id, name, market_code, headquarters, tier_role, evidence_level, notes
   from industry.paper_companies
   where lower(name) like '%upm%' or lower(name) like 'upm%'
   order by id;

4) UPM paper_mills (~26):
   select pm.id, pm.mill_name, pm.market_code, pm.city, pm.main_products,
          pc.name as paper_company_name, pc.tier_role
   from industry.paper_mills pm
   left join industry.paper_companies pc on pc.id = pm.paper_company_id
   where lower(pc.name) like '%upm%'
      or lower(pm.mill_name) like '%upm%'
   order by pm.id;

Claude 산출물: 두 family 각각 마이그레이션 스크립트 + 비교 메모
(Finnish 영토 중첩, UPM의 biofuel/paper 분기 영향 등)
```

### D. Autonomous Claude — Smurfit + Metsä + Fedrigoni 연구

```
v5.7 핸드오프 첨부. 소규모 3 family 동시 정리.

다음 SQL 결과 6개 첨부:

1-2) Smurfit (26): paper_companies + paper_mills 쿼리
     - lower(name/mill_name) like any (array['%smurfit%','%westrock%','%smurfit westrock%'])
     - 2024 Smurfit Kappa + WestRock 합병 → 새 구조 반영 주의

3-4) Metsä (8): paper_companies + paper_mills 쿼리
     - lower(name/mill_name) like '%metsä%' or lower(...) like '%metsa%'
     - Metsä Group 산하 Metsä Board / Metsä Tissue / Metsä Fibre 분기

5-6) Fedrigoni (9): paper_companies + paper_mills 쿼리
     - lower(name/mill_name) like '%fedrigoni%'
     - Italian specialty, Arconvert / Cordenons 자회사 포함 가능성

Claude 산출물: 3 family 통합 마이그레이션 + 각 family별 주의 항목 분리
```

---

## 본 세션 성과 요약 (v5.7)

1. ✅ Step 0 — v5.6 결과물 git commit 정리 (paper-mills 5 파일 → 1 commit)
2. ✅ Step 0 — shadcn `radix-nova` 함정 발견 + revert + components.json `new-york` 안전화
3. ✅ Step 1 — Sappi 시각 검증 통과 (배지 색깔 3종 작동) + NA 3 mill 누락 발견
4. ✅ Step 1 fix — page.tsx 검색 OR 2-stage pre-fetch 패턴 도입 → Sappi 10 → 13 row 회복
5. ✅ Step 2 — paper-companies 페이지 paste (74 + 185 line) + Sappi family 8 row 시각 검증
6. ✅ Step 2 — EvidenceBadge 첫 활용 (paper_companies.evidence_level 컬럼 A/B/C 색깔)
7. ✅ Step 2 — Tier dropdown 필터 신규 추가 (paper-mills엔 없는 기능)
8. ✅ Step 3 — filler-suppliers 페이지 paste (73 + 216 line) + 361 row 시각 검증
9. ✅ Step 3 — Type/Role 2-라인 스택 패턴 신규
10. ✅ Step 3 — Filler Types ARRAY → Badge 그룹 + overflow count 패턴 신규
11. ✅ TypeScript strict 컴파일 무에러 통과 (`npx tsc --noEmit`)
12. ✅ 5 commit + 5 push origin 동기 완료
13. ✅ Industry UI Phase 2 완료 — **3페이지 모두 작동 마일스톤 달성**
14. ✅ v5.7 lesson #19~#23 정리 (shadcn 함정 2건 + tier 아키텍처 + 2-stage 검색 + VS Code 캐시)
15. ✅ v5.7 신규 미해결 #30~#43 등록 (data fix 다수, ARRAY 검색, 11 family 정리)
16. ✅ Sappi family 추가 row 발견 (Sappi Italy, Sappi Portugal — paper-mills엔 mill 없지만 회사 측 Country tier 존재)
17. ✅ filler_suppliers compound entity 패턴 확인 (Omya/Imerys/MTI 각 2 row split)
18. ✅ paper_companies 1054 > paper_mills 552 비율 발견 (#32 audit 후보)
19. ⏸ 사이드바 Industry 메뉴 (#27) — v5.8 첫 작업
20. ⏸ 11 family 정리 진입 안 됨 — v5.8+ autonomous Claude 작업으로 권장
