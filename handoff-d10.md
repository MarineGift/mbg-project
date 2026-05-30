# HANDOFF D10 — Calendar Sync 완전 복구 (Google + Microsoft)

> 작성 시점 기준: 이번 세션에서 캘린더 양방향 동기화(Google + Microsoft)를 end-to-end로 복구 완료.
> 다음 세션 목표: **데이터 정리(data cleanup)**.

---

## 0. 프로젝트 컨텍스트 (불변)

- **mbg-project** — B2B 종이/펄프 CRM. Next.js 14.2.35 / React 19 / Supabase multi-schema (public, app, ai).
- GitHub: `MarineGift/mbg-project`, 기본 브랜치 **`marinebiogroup`** (main/master 아님), 로컬 `C:\dev\mbg-project`.
- Supabase project `ogenmrgxwhpbfepeldqx`, org `b25de8f2-1020-482f-9012-183f63883169` ("MBG Project").
- admin user `551fc4a0-b365-47eb-bf2f-0c3f594001c0` (marinegift4u@gmail.com, "YunYoung, HEO").
- Windows/PowerShell, **ASCII-only 콘솔**. **응답은 한국어.**

---

## 1. 이번 세션 성과 — Calendar Sync 완전 복구 ✅

### 최종 상태 (검증 완료)
- **Google Calendar (marinegift4u@gmail.com)**: 109개 이벤트 동기화 + 화면 표시 ✓
- **Microsoft Outlook (ceo@marinebiogroup.com)**: OAuth 연결 + 동기화 작동 확인 ✓
  - ceo는 **조직(M365 work/school) 계정** (m365.cloud.microsoft 로그인 정상). 개인 계정 아님 → `/common/` 엔드포인트 정상.
  - 테스트: ceo Outlook 웹에서 6/1 일정 생성 → URL 앱 sync → URM 캘린더에 보라색으로 표시됨(검증 완료).
- URM `/calendar` 화면에 Google(초록) + Microsoft(보라) + communications(회색 이메일) + meetings/tasks 통합 표시.

### 근본 원인 체인 (순서대로 해결한 것)
1. **`Error 401: invalid_client`** → `.env.local`에서 `GOOGLE_CALENDAR_CLIENT_ID` 줄이 `#`로 주석 처리돼 있었음 → 주석 해제. (이후 `# `만 제거하는 .NET WriteAllLines 사용)
2. **연결됨인데 동기화 0** → OAuth 콜백이 `app.google_calendar_tokens`(평문, 간소판)에 저장하는데, sync-engine은 `app.calendar_connections`(암호화, 정본)를 읽음 → **테이블 불일치**. 콜백을 `saveCalendarConnection({...})`(token-crypto.ts, `upsert_calendar_connection` RPC로 암호화 upsert) 호출로 재배선.
3. **`?google=noorg`** → 새 콜백이 `user.app_metadata.organization_id`를 요구하는데 JWT에 org 클레임이 없었음.
   - **진짜 원인**: `public.custom_access_token_hook`(STABLE SECURITY DEFINER)이 토큰 발급 시 org를 주입하는데, 이 hook은 **`app.users.organization_id`**를 읽음 (auth.users.raw_app_meta_data 아님). hook은 Supabase Dashboard → Auth Hooks에서 **ENABLED** 상태였고, `app.users`에 admin 행(org=b25de8f2, is_owner=true, is_active=true)도 정상 존재 → 데이터/함수 모두 OK였음.
   - 해결: **완전 로그아웃 + 재로그인** (app_metadata는 토큰 발급 시점에만 구워짐). 재로그인 후 `?google=connected` 성공.
4. **scopes 글자분해 (n_scopes=193)** → 콜백에서 `[...GOOGLE_SCOPES]`로 spread했는데 `GOOGLE_SCOPES`는 `.join(' ')`된 **문자열**(google-client.ts:13)이라 글자 단위로 펼쳐짐 → `GOOGLE_SCOPES.split(' ')`로 수정 + 기존 행 UPDATE로 4개로 교정.
5. **화면 0행 + 42501 (insufficient_privilege)** ← **진짜 마지막 범인**. `fetchCalendarItems`(lib/queries/calendar.ts)의 4개 쿼리가 `parties ( name )`로 임베드하는데, **parties에는 `name`이 없고 `party_name`만 있음** → PostgREST 쿼리 전체 실패 → 0행, 에러가 42501로 표면화. → `parties ( name:party_name )` **alias**로 수정(매핑 코드 `.name`은 그대로 둠). 화면에 이벤트 정상 표시.
6. **Microsoft Graph 400 (`$top` not supported)** → `microsoft-client.ts`의 `calendarView/delta` 호출이 URL params에 `$top: '999'`를 넣었는데, CalendarView delta는 `$top` 금지(Prefer 헤더 써야 함). `Prefer: odata.maxpagesize=999` 헤더는 이미 있었음 → **`$top` 라인만 제거**.
7. **Microsoft eventsSynced=0 (에러 없음)** → `calendar_connections.delta_link`가 저장돼 있어 **증분(delta) 모드**라 변경분 0개만 봄 → `UPDATE app.calendar_connections SET delta_link=NULL, sync_token=NULL WHERE provider='microsoft'`로 풀 동기화 강제. (단 ceo 캘린더 자체가 비어있어서, 실제 검증은 ceo에 테스트 일정 생성 후 동기화로 확인.)

### 커밋 (origin/marinebiogroup에 push 완료)
- `e7b0b83` fix(calendar): rewire google OAuth callback to calendar_connections via saveCalendarConnection (encrypted), enabling sync-engine; fix scopes split
- `f12fae9` fix(calendar): render events under RLS (parties alias name:party_name) + fix MS Graph sync (drop unsupported $top, use Prefer maxpagesize)
- **(이번 세션 마지막) microsoft-client.ts의 `$top` 제거가 f12fae9에 포함됨. MS_AUTH_BASE는 `/common/` 유지(변경 안 함 — ceo가 조직 계정이라 `/consumers/`로 바꾸지 않았음).**

> **주의**: 이번 세션 막바지에 `delta_link=NULL` 리셋은 **DB 데이터 변경**이라 git과 무관. 코드 변경은 위 2개 커밋에 모두 반영됨. 추가 미커밋 코드 변경 없음 (확인 필요 시 `git status`).

---

## 2. 캘린더 운영 방식 (확정)

- **Google (marinegift4u@gmail.com)**: 일상 캘린더, 109개 동기화 유지. fetch 범위 = now ±365일 (google-client.ts:137 부근, timeMin 기본값).
- **Microsoft (ceo@marinebiogroup.com)**: 앞으로 **ceo 캘린더에 만드는 일정**이 동기화 대상. ceo는 조직 M365 계정. ceo Outlook 웹(outlook.office.com 또는 PWA)에서 일정 생성 → URM 동기화.
  - moreworld@marinebio.kr(별도 IMAP 계정)의 기존 일정은 ceo로 **안 옮김** (사용자 결정: "현재 있는 일정 외 앞으로는 ceo 사용").
- **메일 수신(IMAP, TABS_MAILER_*)과 캘린더(OAuth)는 완전 별개 채널** — 데스크톱 Outlook 계정 설정과 무관하게 동작.

### Calendar 화면 동작 (참고)
- 초기 로드 범위 = now 기준 ±1~2개월 (calendar/page.tsx:177-179). 과거 달로 이동하면 `onRangeChange`로 그 달을 다시 조회. 이벤트가 2025-06~2026-07에 분산돼 있어, 빈 달(예: 2025-05, 2026-05 일부)은 정상적으로 비어 보임.
- 월별 분포(google 109개): 2025-06:31, 07:14, 08:6, 09:14, 10:11, 11:10, 12:7, 2026-01:5, 02:1, 03:4, 04:3, 05:2, 07:1.

---

## 3. DB/스키마 핵심 사실 (이번 세션 확인)

### app.calendar_connections 컬럼
id, organization_id, user_id, provider(USER-DEFINED enum calendar_provider), account_email, account_name, **access_token(bytea, NOT NULL)**, **refresh_token(bytea, nullable)**, token_type, expires_at, **scopes(ARRAY, NOT NULL)**, sync_token, delta_link, last_sync_at, last_sync_status(enum), last_error, sync_failures(int), is_active(bool), is_primary(bool), created_at, updated_at.

### 캘린더 관련 테이블 (app schema) + 행수(이번 세션 시점)
- calendar_connections: google(1) + microsoft(1) = 2행 (둘 다 is_active, has_access, has_refresh true)
- calendar_events: google 109 + microsoft (테스트 일정들). `SELECT source, count(*) FROM app.calendar_events GROUP BY source;`로 확인.
- calendar_sync_log: 0
- engagement_meeting_details: 0
- **google_calendar_tokens: 1행 (평문, 구버전 — 이제 안 씀, 드롭 대상)**
- meeting_attendees: 0
- meetings: 0

### 캘린더 관련 함수 (app/public) — 모두 module-free 확인됨
create_meeting_with_host, encrypt/decrypt_calendar_token, sync_calendar_pull, sync_calendar_push_prep, update_calendar_sync_state, update_calendar_tokens, upsert_calendar_connection, fn_detect_calendar_channel, get_upcoming_meetings.

### custom_access_token_hook (public, STABLE SECURITY DEFINER)
- `app.users`에서 organization_id/is_owner/preferred_language 읽어 `event.claims.app_metadata`에 주입.
- `v_organization_id IS NULL`이면 변경 없이 RETURN (조직 미할당 유저는 클레임 없음).
- Dashboard → Authentication → Hooks: **ENABLED**, function=`public.custom_access_token_hook`.

### RLS (calendar_events)
- `pol_calendar_events_select`: `organization_id = app.current_organization_id()`
- `pol_calendar_events_modify` (ALL): `organization_id = current_org() AND user_id = current_user()`
- `app.current_organization_id()`: `current_setting('request.jwt.claims') -> 'app_metadata' ->> 'organization_id'` 읽음.
- RLS 정상 검증: `SET request.jwt.claims='{...org...}'; SET ROLE authenticated; SELECT count(*) FROM app.calendar_events;` → 109 반환.

### app.parties 핵심 (재확인)
- `party_name`(NOT `name`), party_type_id(smallint FK → party_types), interest_tags(jsonb), industry_tag_id. **`name` 컬럼 없음** — PostgREST 임베드 시 `parties ( name:party_name )` alias 필요.

---

## 4. 다음 세션 목표 — 데이터 정리 (DATA CLEANUP)

사용자 지시: "새 세션에서 데이터를 정리하자."

### 정리 후보 (우선순위순, 시작 전 사용자와 범위 합의 권장)
1. **평문 `app.google_calendar_tokens` 테이블 드롭** — calendar_connections로 일원화됨, 1행 잔존, 이제 안 씀. (관련 옛 라우트 `/api/calendar/auth`, `/api/calendar/callback` 잔재도 점검 — google/callback이 이걸 안 쓰게 됐으니 옛 범용 라우트가 dead인지 확인 후 정리.)
2. **샘플/더미 parties·contacts 정리** — paper_mill/filler_supplier/investor 외 샘플 데이터, Auto-created 스텁(`notes ILIKE 'Auto-created%'`) 등. (단 supply-link 117행은 real keep-data — 건드리지 말 것.)
3. **신규 유저 org 클레임 자동 주입 (구조적 — RBAC 선행조건)** — 현재 admin만 `app.users.organization_id` 채워짐. 신규 유저가 가입/멤버십 시 `app.users.organization_id`가 채워져야 custom_access_token_hook이 토큰에 org를 싣고 RLS·캘린더·sync가 작동. 가입 흐름 점검. (auth.users.raw_app_meta_data에 직접 넣은 우회는 hook이 안 보므로 무의미 — 정리 가능.)
4. **module 미관 정리 (배치 2c-2 + 배치 3)** — 기능/런타임/타입 차원 module 제거는 이전 세션에 완료. 남은 건 순수 미관:
   - supply-links-panel의 partyModule→role/linkedRole 식별자
   - ModuleBadge/module-badge.tsx, CSS 토큰 bg-module-*, i18n 'modules' 네임스페이스
   - PARTY_MODULES/PartyModule/MODULE_LABELS consts (app/(app)/page.tsx)
   - email-templates.ts의 `module:party_type` alias + EmailTemplate.module 필드
   - route local var `module`, 주석 (prompt-renderer.ts:289, engagements.ts:122/125)
5. **RBAC own-scope 통합 테스트** — #3(org 클레임 자동화) 완료 후 진행 가능.
6. **calendar fetch 범위 확장 (선택)** — 2025-05 이전 과거 일정도 원하면 google-client.ts/microsoft-client.ts의 timeMin(-365일)을 늘림.
7. **Microsoft sync 안정화 (선택)** — delta_link 빈 페이지 시 첫 동기화가 0개로 끝나는 케이스 견고화(첫 호출이 nextLink 없이 deltaLink만 줄 때 대비). 현재는 delta 리셋으로 우회 가능.

---

## 5. 확립된 작업 패턴 (계속 적용)

- **SQL**: Supabase SQL Editor에서 단일 `BEGIN..COMMIT` + PRE/POST-CHECK DO 블록. 에디터 100행 캡. temp table 금지(pooler) → inline CTE.
- **Supabase 스키마 쿼리 (Gotcha #45)**: `.schema('app')`(no cast) + `.from('TABLE' as never)`. 단, server.ts의 SbClient는 default 'app' schema.
- **PostgREST 임베드**: 존재하지 않는 컬럼 select 시 쿼리 전체 실패. 컬럼명 정확히(parties는 party_name). alias로 `parties ( name:party_name )` 가능.
- **코드 편집**: 정규식/brace-counting 금지(문자열·mojibake 한글 주석에 속음). grep+line-range 또는 unique-string 1:1 치환(occurrence count 검증). Python 패처는 atomic.
- **PowerShell**: heredoc `<<` 미지원 → `@'...'@` here-string(작은따옴표라 `$`/백틱 보존) + `[System.IO.File]::WriteAllText(path, text, New-Object System.Text.UTF8Encoding($false))`. 읽기 `utf-8-sig`, 쓰기 `utf-8` no-BOM. 다운로드 .ps1은 `$env:USERPROFILE\Downloads`에서 `-ExecutionPolicy Bypass`. **이번 세션에선 패처 .py 다운로드가 안 돼서, .env/.ts 수정을 PowerShell here-string + .NET WriteAllText로 직접 처리함 (이 방식이 더 안정적이었음).**
- **콘솔 ASCII-only**: PS 5.x가 UTF-8 no-BOM을 CP949로 파싱해 한글 깨짐 → 콘솔 출력은 ASCII만, 한글은 .md(UTF-8 BOM)에만.
- **JWT app_metadata는 토큰 발급 시점에만 구워짐** → DB UPDATE 후 반드시 로그아웃+재로그인. 쿠키 클리어 스크립트: `document.cookie.split(';').forEach(c=>{document.cookie=c.split('=')[0].trim()+'=;expires=Thu, 01 Jan 1970 00:00:00 GMT;path=/'});`
- **토큰 위치**: 이 앱은 supabase-ssr → JWT를 **쿠키**(`sb-ogenmrgxwhpbfepeldqx-auth-token`)에 저장(localStorage 아님). 디코드 시 쿠키에서 추출.

---

## 6. 다음 세션 시작 체크리스트

1. `git status` / `git log --oneline -5` 로 마지막 상태 확인 (마지막 커밋 `f12fae9` 이후 미커밋 변경 있는지).
2. 데이터 정리 **범위를 사용자와 먼저 합의** (위 §4 후보 중 무엇부터 / 무엇을 보존).
3. 파괴적 작업(DROP/DELETE) 전 항상 PRE-CHECK + 행수 확인 + 단일 트랜잭션.
4. 캘린더는 작동 상태 — 정리 중 calendar_events/connections를 건드리면 동기화 재확인 필요.
