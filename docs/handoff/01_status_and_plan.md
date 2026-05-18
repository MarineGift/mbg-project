# mbg-project 복원 및 캘린더 통합 핸드오프 문서

작성: 2026-05-18  
대상: 다음 세션의 Claude (또는 YunYoung 직접 작업 시)  
현재 GitHub 브랜치: `fix/missing-modules-stubs`

---

## 1. 이전 세션에서 한 일

### 빌드 통과를 위한 stub 생성 (10개 파일)

**완성도 높음 (그대로 유지)**
- `src/components/ui/switch.tsx` — shadcn 표준 Switch (Radix `@radix-ui/react-switch` 사용)
- `src/components/ui/tabs.tsx` — shadcn 표준 Tabs (Radix `@radix-ui/react-tabs` 사용)
- `src/lib/utils/merge-fields.ts` — `renderMergeFields`, `extractMergeFields` 실제 로직 포함

**DB 테이블 필요 (현재 빈 결과 반환하는 stub)**
- `src/lib/queries/lead-score.ts` — `app.lead_scores` 테이블 부재
- `src/lib/queries/saved-views.ts` — `app.saved_views` 테이블 부재
- `src/lib/queries/meetings.ts` — 미팅 전용 테이블 부재 (engagements 활용 검토)

**UI 표시는 OK, 동작 로직 보강 필요**
- `src/components/common/lead-score-badge.tsx` — 0~100 색상 매핑, 정상
- `src/components/common/pagination-bar.tsx` — URL 쿼리 기반 prev/next, 정상
- `src/components/common/saved-views-dropdown.tsx` — 표시만, 클릭 시 뷰 적용 로직 없음
- `src/components/parties/party-meetings-list.tsx` — 표시만, 정상

### 코드 패치
- `src/components/email/compose-email-dialog.tsx` — deprecated `@supabase/auth-helpers-nextjs` → `@/lib/supabase/client` 표준으로 교체
- `src/app/(app)/[module]/parties/page.tsx` — 중복된 `countryData` / `distinctCountries` 블록 제거 (line 194~203, 총 392자)

### 백업
- 모든 수정된 원본 파일은 `.bak` 확장자로 보존됨
- `.gitignore`에 `*.bak` 추가됨
- GitHub: `fix/missing-modules-stubs` 브랜치에 push 완료

---

## 2. 현재 안고 있는 stub들의 실제 의미

업로드된 SQL 파일들(`001_core_infrastructure`, `010_rls_policies` 등)을 분석한 결과:

### 2.1 `lead_scores` — 신규 테이블 필요
- 마이그레이션 SQL 미작성
- 권장 구조: `(party_id, score 0-100, factors jsonb, computed_at)` + RLS

### 2.2 `saved_views` — 신규 테이블 필요  
- 마이그레이션 SQL 미작성
- 권장 구조: `(user_id, entity_type, module, name, filters jsonb, is_default, is_shared)` + RLS

### 2.3 `meetings` — 캘린더 통합으로 통합 처리 권장
- 기존 `app.engagements`에 미팅 시간 컬럼 없음
- `app.meeting_mode`, `app.meeting_type` ENUM은 이미 정의됨 (001 SQL)
- **결론: 별도 `app.meetings` 테이블 생성 + 캘린더 통합 모듈과 연결**

---

## 3. 우선순위 작업 순서

### Phase A: 빌드 안정화 (남은 stub 정리) — 2~3시간

1. **A-1. DB 마이그레이션 적용**
   - `025_lead_scores.sql` 작성 후 Supabase에 적용
   - `026_saved_views.sql` 작성 후 적용
   - 두 파일은 이번 핸드오프 패키지에 포함됨

2. **A-2. Stub query 실제 구현으로 교체**
   - `lib/queries/lead-score.ts` — 실제 SELECT 쿼리
   - `lib/queries/saved-views.ts` — 실제 SELECT 쿼리

3. **A-3. UI 보강**
   - `saved-views-dropdown.tsx` — 클릭 시 URL 쿼리 적용 + "현재 필터 저장" 버튼

4. **A-4. 전체 페이지 회귀 테스트**
   - 모든 모듈의 parties / detail / inbox / settings 페이지 점검

5. **A-5. main 브랜치 merge + 태그**
   - `marinebiogroup` 브랜치에 merge
   - `v5.12-build-restored` 태그

### Phase B: 캘린더 통합 MVP — 2~3주

상세는 `02_calendar_integration_design.md` 참고.

핵심:
- Google Calendar OAuth + Microsoft Graph OAuth
- `app.calendar_connections`, `app.calendar_events`, `app.meetings` 테이블
- FullCalendar React 컴포넌트로 통합 뷰
- mbg-project의 party/engagement과 미팅 자동 매핑

### Phase C: 캘린더 + AI 통합 — 추가 2주

- 미팅 종료 후 자동 follow-up task 생성 (`app.tasks` 활용)
- AI 미팅 요약 (이미 있는 `ai.agents` 인프라 활용)
- 미팅 추천 (engagement stage 기반)

---

## 4. 새 세션 시작 시 이어받기 가이드

새 Claude 세션을 시작하면 이렇게 안내하세요:

> "GitHub `MarineGift/mbg-project` 프로젝트의 빌드 안정화 + 캘린더 통합 작업을 이어서 진행한다. 이전 세션 핸드오프 문서가 `docs/handoff/` 폴더에 있으니 먼저 읽고 시작해줘. 현재 브랜치는 `fix/missing-modules-stubs`다."

새 세션 Claude가 확인해야 할 파일:
- `docs/handoff/01_status_and_plan.md` (이 문서)
- `docs/handoff/02_calendar_integration_design.md` (캘린더 설계)
- `docs/handoff/03_next_session_checklist.md` (다음 작업 체크리스트)
- `supabase/migrations/025_lead_scores.sql`
- `supabase/migrations/026_saved_views.sql`
- `supabase/migrations/030_calendar_integration.sql`

---

## 5. 주의사항 (이전 세션에서 겪은 함정)

### 5.1 PowerShell here-string의 `<` 손상 문제
TypeScript generic (`React.forwardRef<...>`)을 PowerShell `@'...'@`에 paste하면 `<`를 redirect 연산자로 해석해서 깨짐. **반드시 Base64로 인코딩한 후 `[System.Convert]::FromBase64String` + `WriteAllBytes`로 작성**.

### 5.2 `[module]` 폴더의 대괄호 와일드카드 문제
PowerShell `Test-Path`/`Remove-Item` 등이 `[module]`을 와일드카드 패턴으로 해석함. `-LiteralPath` 옵션 또는 `[System.IO.File]::Exists()` 사용.

### 5.3 한글 PowerShell 스크립트 인코딩
UTF-8 BOM 없으면 콘솔이 깨진 문자로 표시 → 파서가 토큰 인식 실패. **PowerShell 스크립트는 UTF-16 LE with BOM, 또는 ASCII-only 본문 + 한글은 출력 메시지에만 최소화**.

### 5.4 브라우저 캐시 문제
같은 파일명으로 재다운로드하면 브라우저가 이전 캐시 제공. 새 파일명 사용하거나 PowerShell 명령 직접 paste.

### 5.5 Multi-line string에 비-ASCII 문자
`&nbsp;` 등을 Base64에 포함시키면 깨진 UTF-8 바이트가 들어가서 Next.js compile 실패. **JSX 안의 공백은 일반 콤마+공백으로 처리**.

---

## 6. 환경 정보

- Windows + PowerShell
- 프로젝트 경로: `C:\dev\mbg-project`
- Node, npm 정상 동작 (Next.js 14.2.35 — outdated 알림 있음, 추후 14.2.x 최신 또는 15.x 업그레이드 검토)
- Supabase 연결: `.env.local`에 keys 있음 (백업 필수)
- 14 vulnerabilities 알림 (1 low, 7 moderate, 6 high) — `npm audit` 추후 점검

---

## 7. 다음 세션이 가장 먼저 할 일

```powershell
# 1. 최신 상태 pull
cd C:\dev\mbg-project
git status
git pull

# 2. 핸드오프 문서 읽기
Get-Content docs\handoff\01_status_and_plan.md
Get-Content docs\handoff\02_calendar_integration_design.md
Get-Content docs\handoff\03_next_session_checklist.md

# 3. 새 마이그레이션 적용
# (Supabase 대시보드에서 SQL 실행)
#   supabase/migrations/025_lead_scores.sql
#   supabase/migrations/026_saved_views.sql

# 4. dev 서버 켜기
npm run dev

# 5. Phase A 작업 시작 (03_next_session_checklist.md 따라서)
```
