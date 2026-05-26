# URM Platform Handoff v5.6

**날짜**: 2026-05-15
**이전**: v5.5 (2026-05-15)
**다음**: v5.7 (paper-companies + filler-suppliers 페이지 / Mondi family / #20+#23)

---

## v5.5 → v5.6 변경점

### 핵심 성과 — Industry UI Phase A + B 통째 완료 🎉

v5.5에서 paste 직전 한도 도달했던 4 파일(layout/tabs/page/table)이 본 세션에서 전부 paste + 브라우저 작동까지 완료. `/industry/paper-mills`에서 **552 mill + tier_role 배지 + Supabase embed 정상 동작**.

### 새 결정 — route group: (authenticated) → (app)

원본 UI Phase 1 문서는 `(authenticated)/industry` 경로 가정. 본인 환경 확인 결과:
- `src/app/(app)/`에 이미 7+ 페이지 호스트 (compose, drafts, engagements, inbox, tasks, settings, [module])
- `(app)/layout.tsx`가 이미 인증 처리

→ industry도 `(app)/` 안에 통합. `(authenticated)/`는 auth/login 정도만 있는 별도 그룹으로 추정 (v5.7에 정확한 용도 점검).

### 새 결정 — Geist 폰트 source: next/font/google → geist npm package

Next.js 14.2.35는 `next/font/google`의 `Geist` 폰트 미인식. Vercel 공식 답변 "최신 Next.js로 업그레이드해야 사용 가능". 메이저 업그레이드(15.x) 리스크 회피 위해 `geist` npm 패키지 사용:
- `npm install geist`
- `import { GeistSans } from 'geist/font/sans'`
- 변수명 차이: 원본은 `--font-sans`, 새 코드는 `--font-geist-sans` (필요 시 globals.css alias)

---

## Phase A + B 완료 — paper-mills 작동 흐름

### 파일 트리 (최종)

```
src/app/(app)/industry/
├── layout.tsx                                ✅ industry sub-nav wrapper
├── IndustryTabs.tsx                          ✅ Paper Mills / Companies / Fillers 탭
└── paper-mills/
    ├── page.tsx                              ✅ Server Component (Supabase fetch)
    └── PaperMillsTable.tsx                   ✅ Client Component (filter/pagination)

src/components/industry/
├── TierRoleBadge.tsx                         ✅ HQ/Regional/Country/Plant 색깔 배지
└── EvidenceBadge.tsx                         ✅ A/B/C/D/E 배지 (v5.7+ 사용 예정)

src/components/ui/
├── badge.tsx                                 ✅ shadcn add badge
└── table.tsx                                 ✅ shadcn add table
```

### 환경 반영 변경점 (UI Phase 1 원본 대비)

1. 경로: `(authenticated)/industry` → `(app)/industry`
2. Supabase 함수: `createClient` → `createSupabaseServerClient` (page.tsx)
3. `.schema('industry' as never)` 캐스팅 유지 (#8 미해결)
4. layout.tsx: 미사용 `import Link` 제거 (TS strict 대비)

### 작동 확인 ✅ (브라우저 검증)

- **552 mills** count 정확 (DB 전체 row 수와 일치)
- `paper_company:paper_company_id (...)` Supabase embed 작동 → fallback 불필요
- 마켓 dropdown 45개 표시 정상
- 검색창 + 페이지네이션 정상
- TierRoleBadge 색깔 출력 작동 (Sappi paper_companies tier_role 채워진 row 대상, 시각 검증 #28 미진행)
- next-intl locale 정상 (한국어 + i18n)
- IndustryTabs 3 탭 렌더링 정상 (Paper Companies / Filler Suppliers 클릭 시 404 — 페이지 미생성, 예상된 동작)

---

## v5.6 lessons (#13~#18)

### Lesson #13: Windows 폴더 경로 백슬래시 함정

Windows CLI에서 `mkdir "(authenticated)\industry"` 형태로 만들면 **`(authenticated)\industry`라는 한 폴더**가 생성됨 — Next.js route group 비작동. 두 폴더 의도면 반드시:
- 두 번에 나눠서 `mkdir "(authenticated)"; mkdir "(authenticated)/industry"`
- 또는 슬래시 `/` 사용: `New-Item -ItemType Directory -Path "...(authenticated)/industry" -Force`

### Lesson #14: Windows case-insensitive vs Linux 배포

`Industry/` 대문자 폴더가 Windows에서는 작동(case-insensitive)하지만 **Vercel/Linux 배포 시 깨짐**. Next.js URL 매핑은 폴더 이름 그대로 사용. App Router 폴더는 **항상 소문자**. Git rename 두 단계 필수:

```bash
git mv Industry industry_tmp
git mv industry_tmp industry
```

(한 번에 `git mv Industry industry`는 Windows에서 무시됨)

### Lesson #15: Geist 폰트는 Next.js 14.2.35의 next/font/google에서 미인식

v5.5까지 build/test/deploy 위주로 진행 → dev 서버 첫 실행이 본 세션. `next/font/google`에서 `Geist` import → "Unknown font" 에러. **fix: geist npm 패키지 사용** (메이저 업그레이드 회피).

`GeistSans.variable`은 `--font-geist-sans`로 고정 등록 — 원본 `--font-sans` 변수명 의존 시 globals.css에 alias 추가 필요. tailwind config에서 `font-sans`를 변수 참조하면 끊길 가능 있음 (#29 점검 항목).

`next.config.js`에 `transpilePackages: ['geist']` 추가 필요한 경우도 있음 (검색 결과 사례). 본 세션에서는 추가 없이 작동했으나 다른 환경에서는 필요할 수 있음.

### Lesson #16: v5.5 "파일 생성"의 함정 — 빈 파일 다수

v5.5 핸드오프에 "TierRoleBadge.tsx + EvidenceBadge.tsx 생성"으로 적혔지만 실제로는 **빈 파일만 생성**. shadcn `badge.tsx` + `table.tsx`도 마찬가지 (`shadcn init`만 되고 `add badge`/`add table`은 안 됨).

핸드오프 정확성을 위해 **"파일 생성 ≠ 코드 paste 완료"** 구분 필수. 다음 세션 시작 시 첫 단계로 빈 파일 확인:

```powershell
Get-Content "path/to/file.tsx" | Measure-Object -Line
```

0 줄이면 빈 파일, "Cannot find path"면 폴더 자체 없음.

### Lesson #17: page.tsx 위치 — Next.js App Router 경로 매핑

`industry/page.tsx`와 `industry/paper-mills/page.tsx`는 다른 URL을 잡음:
- `industry/page.tsx` → `/industry`
- `industry/paper-mills/page.tsx` → `/industry/paper-mills`

paste 시 폴더 한 단계 헷갈리면 라우트 깨짐. **`page.tsx`는 반드시 라우트와 매칭되는 폴더 안에 위치.** 본 세션에서 `industry/page.tsx`로 잘못 paste되어 `/industry/paper-mills` 404. `Move-Item` 한 줄로 해결.

### Lesson #18: VS Code Simple Browser localhost intercept

VS Code에서 `localhost:3000` 링크 클릭 → Simple Browser 탭이 가로챔. 외부 브라우저(Chrome) 강제하려면:
- `settings.json`에 `remote.portsAttributes` 설정:
  ```json
  "remote.portsAttributes": {
    "3000": { "onAutoForward": "openBrowser" }
  }
  ```
- 또는 Ports 패널에서 우클릭 "Open in Browser"
- 또는 그냥 Chrome 수동 입력 (가장 간단)

dev/디버깅 효율에 큰 영향. 한 번 설정해두면 끝.

---

## 미해결 항목 (v5.7+ 작업)

### v5.5에서 그대로 유지

- **#8**: Supabase 타입 재생성 (`.schema('industry' as never)` + `app.parties` 새 컬럼 반영)
- **#9**: i18n 라벨 cosmetic
- **#12**: 3-tier 운영화 (parent_party_id backfill)
- **#15**: compound entity 정책 (12 family에 일반화)
- **#18**: 옵션 B paper_mills 단일 정본 — 다른 12 family에 반복
- **#19**: `app.parties.tier` (tier_level ENUM) 의미 파악
- **#20**: `paper_mills.mill_name` 정규화
- **#21**: `paper_companies` → `app.parties` 022 promotion script bug 전수 audit
- **#22**: `app.parties.party_level` ↔ `industry.tier_role` 정합성 정책
- **#23**: `paper_mills` multi-region rollup split (8+)
- **#24**: `industry.market_findings`, `industry.verification_queue` 정체 파악

### v5.6 신규

- **#25**: `/industry/paper-companies` 페이지. UI Phase 1 문서 섹션 6 코드 준비됨. **Sappi 정리 결과(6 row: HQ/Regional/Country) 시각화의 핵심** — paper-mills보다 우선순위 높음
- **#26**: `/industry/filler-suppliers` 페이지. UI Phase 1 문서 섹션 7 코드 준비됨
- **#27**: 사이드바에 "Industry" 섹션 추가. 현재는 직접 URL 입력 필요(`/industry/paper-mills`). 사이드바 컴포넌트 위치 미파악 — v5.7 첫 단계로 점검. `src/components/` 하위 sidebar/nav 관련 파일 추정
- **#28**: Sappi family 11 mill을 화면에서 색깔 배지로 시각 검증 — 본 세션 마지막에 캡처 못 받음. v5.7 시작 시 5초 작업: 검색창에 `sappi` 입력 후 결과 확인
- **#29**: `globals.css`에서 `--font-sans` alias 점검. geist 패키지는 `--font-geist-sans`로 등록 → tailwind config의 `font-sans` 참조와 불일치 시 폰트 깨짐. 폰트 이상 시 한 줄 추가:
  ```css
  :root { --font-sans: var(--font-geist-sans); }
  ```

---

## v5.7+ Step 재정의

### Step A — Paper side 정리 (Sappi 완료, 12 family 남음)

v5.5 그대로:
- A-1 ✅ Sappi 완료
- A-2 다음 family (우선순위 미정):
  - **Mondi 43** — 가장 큰 family, Sappi와 유사 구조 예상
  - **Stora Enso 24** — Finnish + Swedish, country/regional tier 활용
  - **UPM 26** — Finnish, paper + biofuels
  - **Smurfit 26** — packaging focus
  - 또는 row 적은 family부터 (Metsä 8, Fedrigoni 9)

### Step B — Filler side 정리 (시작 안 됨)

v5.4 그대로:
- Omya 31, Imerys 38, Artemyn 39, MTI 34 동일명 split
- Artemyn ↔ Imerys (former assets) 통합 정책
- MTI ↔ Specialty Minerals (모자회사) 정책

### Step C — paper_mills 측 정리 (#20 + #23)

- mill_name 정규화 (광역주/country 수준 이름 → 도시 단위)
- multi-region rollup split (8+ row)
- paper_mills 전체 audit으로 추가 dirty row 발견

### UI Phase 2 — 페이지 확장

- **B-1**: `/industry/paper-companies` 페이지 paste (#25) — **Sappi 6 row 시각화의 핵심**
- **B-2**: `/industry/filler-suppliers` 페이지 paste (#26)
- **B-3**: 사이드바 "Industry" 메뉴 추가 (#27)
- **B-4**: Sappi 시각 검증 (#28)

paste 패턴은 v5.6과 동일:
1. UI Phase 1 문서 섹션 6, 7 코드 사용
2. `(authenticated)` → `(app)` 경로 변경
3. `createClient` → `createSupabaseServerClient`
4. `.schema('industry' as never)` 캐스팅 유지

---

## Phase 7-c 진입 조건 + 현재 상태

- ✅ Schema 발견 완료 (v5.4 18+ audit + v5.5 추가 발견)
- ✅ industry.filler_plants 신설
- ✅ 명명 컨벤션 (3-info 모델 + 4 role)
- ✅ #17 옵션 A 적용 (tier_role ENUM)
- ✅ #18 옵션 B 진입 (paper_mills 단일 정본)
- ✅ Sappi family 첫 정리 (6 row)
- ✅ app.parties.industry_paper_mill_id 컬럼 + FK + 인덱스
- ✅ RLS 4 테이블 enable + SELECT policy
- ✅ **UI Phase A + B 완료** — /industry/paper-mills 작동 (v5.6 본 작업)
- ⏸ 12 multinational family 정리 (v5.7+)
- ⏸ filler side 정리 (Step B, v5.7+)
- ⏸ paper_mills 정리 (#20 + #23)
- ⏸ 022 promotion script audit (#21)
- ⏸ tier/party_level/tier_role 정합 (#19 + #22)
- ⏸ paper-companies + filler-suppliers 페이지 (#25, #26)
- ⏸ 사이드바 Industry 메뉴 (#27)
- ⏸ Sappi 시각 검증 (#28)

---

## v5.6 끝나는 시점 정확한 상태

### 본인 환경 (v5.6 확정)

```
Stack:           Next.js 14.2.35, TypeScript strict, Supabase, shadcn/ui, Tailwind
프로젝트 경로:    C:/dev/mbg-project
Route groups:    (app)/      — 인증 wrapper, 모든 메인 페이지 호스트
                 (authenticated)/ — auth/login 등 (v5.7에 정확한 용도 점검)
Supabase server: src/lib/supabase/server.ts
함수 이름:        createSupabaseServerClient
Geist 폰트:       geist npm package (next/font/google 아님)
                 import { GeistSans } from 'geist/font/sans'
src/components/ui/: avatar, badge ★, button, card, checkbox, dialog, dropdown-menu,
                    input, label, radio-group, select, separator, skeleton,
                    table ★, textarea, tooltip
                    (★ = v5.5/v5.6에서 shadcn add)
```

### 완료된 UI 작업 (v5.5 + v5.6 통합)

```
src/app/(app)/industry/layout.tsx                       ✅ v5.6
src/app/(app)/industry/IndustryTabs.tsx                 ✅ v5.6
src/app/(app)/industry/paper-mills/page.tsx             ✅ v5.6 (createSupabaseServerClient)
src/app/(app)/industry/paper-mills/PaperMillsTable.tsx  ✅ v5.6
src/components/industry/TierRoleBadge.tsx               ✅ v5.5 stub → v5.6 paste
src/components/industry/EvidenceBadge.tsx               ✅ v5.5 stub → v5.6 paste
src/components/ui/badge.tsx                             ✅ v5.6 shadcn add badge
src/components/ui/table.tsx                             ✅ v5.6 shadcn add table
src/app/layout.tsx                                      ✅ v5.6 Geist → GeistSans (geist 패키지)
package.json                                            ✅ v5.6 + geist 패키지 추가
```

### 즉시 이어받을 작업 (v5.7 시작점)

**Step 0 — 본 세션 결과물 commit (아직 안 함)**
```bash
git add src/app/\(app\)/industry/
git add src/components/industry/
git add src/components/ui/badge.tsx src/components/ui/table.tsx
git add src/app/layout.tsx
git add package.json package-lock.json
git commit -m "feat(industry): paper-mills page with tier_role badges (v5.6 UI Phase A+B)"
```

**Step 1 — Sappi 시각 검증** (5초)
- /industry/paper-mills 검색창에 `sappi` 입력
- 11 mill + tier_role 배지 색깔 확인:
  - 🟣 HQ(보라) — Sappi Limited 산하 4 (Springs, Saiccor, Ngodwana, Stanger)
  - 🔵 Regional(파랑) — Sappi Europe 3 (Alfeld, Gratkorn, Multi-region) + Sappi NA 3 (Cloquet, Somerset, Westbrook)
  - 🟢 Country(초록) — Sappi Finland 1

**Step 2 — paper-companies 페이지 paste** (가장 가치 높음)
- UI Phase 1 문서 섹션 6 코드 사용
- 환경 반영 (v5.6 lesson 적용)
- 결과: Sappi 6 row (HQ/Regional/Country) 시각화 가능

**Step 3 — filler-suppliers 페이지 paste**
- UI Phase 1 문서 섹션 7

**Step 4 — 사이드바 Industry 메뉴 추가**
- 사이드바 컴포넌트 위치 파악 먼저 (`src/components/` 트리 점검)
- "Industry" 섹션 추가 + 하위 "Paper Mills / Companies / Fillers" 링크

**Step 5 — 다음 family 정리** (Mondi 43 또는 Metsä 8 추천)
- Sappi 패턴 반복 (Phase 1 + Phase 2)
- paper_mills 단일 정본 + paper_companies tier_role 배지

### 알려진 미해결 — UI 측

- `.schema('industry' as never)` 후 후속 메서드 타입 추론 깨질 가능성 (#8 해결 시 자동)
- `--font-sans` ↔ `--font-geist-sans` 변수명 불일치 점검 필요 (#29)
- IndustryTabs의 Paper Companies / Filler Suppliers 탭 클릭 시 404 — 페이지 미생성 (#25, #26)

---

## 다음 세션 시작 프롬프트 (template)

```
v5.6 핸드오프 첨부합니다. v5.6에서 Industry UI Phase A+B 완료
(/industry/paper-mills에서 552 mill + tier_role 배지 + Supabase embed 정상 작동).

v5.7에서 이어서:
1. (선택) v5.6 결과물 git commit 먼저
2. Sappi 시각 검증 5초 (검색창 `sappi` 입력 후 배지 색깔 확인) — v5.6 #28
3. /industry/paper-companies 페이지 paste — v5.6 #25, UI Phase 1 섹션 6 코드 준비
4. /industry/filler-suppliers 페이지 paste — v5.6 #26, UI Phase 1 섹션 7
5. 사이드바 "Industry" 메뉴 추가 — v5.6 #27
6. 그 후 다음 family 정리 (Mondi 43 / Stora Enso 24 / UPM 26 / Smurfit 26 / Metsä 8 / Fedrigoni 9 중 택)
   또는 paper_mills #20+#23 또는 filler side Step B

체크리스트 처음 진입 시:
- 빈 파일 확인 (`Get-Content | Measure-Object -Line`) — v5.6 lesson #16
- 폴더 case (소문자) 확인 — lesson #14
- (authenticated)/ 그룹 용도 점검 — lesson #13
```

---

## 본 세션 성과 요약 (v5.6)

1. ✅ Route group 결정 — `(authenticated)` → `(app)`, 기존 인증 wrapper 통합
2. ✅ Windows 폴더 백슬래시 함정 발견 + 해결 (`(authenticated)\industry` 정리)
3. ✅ `Industry` → `industry` case rename (Linux 배포 대비, git mv 두 단계)
4. ✅ Geist 폰트 source 교체 — `next/font/google` → `geist` npm 패키지 (Next.js 14.2.35 미인식 회피)
5. ✅ `src/app/layout.tsx` 수정 (import Geist 제거, GeistSans 추가)
6. ✅ shadcn badge + table 컴포넌트 add (v5.5에서 빈 파일이었음 — lesson #16)
7. ✅ `TierRoleBadge.tsx` + `EvidenceBadge.tsx` 코드 paste (v5.5에서 빈 stub이었음)
8. ✅ `industry/layout.tsx` + `IndustryTabs.tsx` paste
9. ✅ `paper-mills/page.tsx` + `PaperMillsTable.tsx` paste (`createSupabaseServerClient` 환경 반영)
10. ✅ `page.tsx` 위치 fix (`industry/` 직속 → `industry/paper-mills/` 안)
11. ✅ `/industry/paper-mills` 작동 확인 — 552 mill + paper_company embed + tier 배지 + 검색/마켓 필터/페이지네이션
12. ✅ Supabase embed 작동 검증 (`paper_company:paper_company_id` 형식, fallback 불필요)
13. ✅ VS Code Simple Browser localhost 가로채기 패턴 인지 + 우회 방법 (lesson #18)
14. ✅ v5.6 lesson #13~#18 추가 (Windows 함정 + 폰트 + 빈 파일 + page.tsx 위치 + Simple Browser)
15. ✅ v5.6 미해결 #25~#29 등록
16. ⏸ git commit 미진행 (v5.7 첫 작업)
17. ⏸ Sappi 시각 검증 미진행 — DB 정합성은 v5.5에서 확인 완료, 화면 색깔 배지 확인은 v5.7 5초 작업 (#28)
