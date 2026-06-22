# HANDOFF — Calendar Recurrence (Google-style "More options")

> 이 문서 하나로 새 세션에서 바로 이어서 작업할 수 있게 만든 핸드오프입니다.
> 작성 시점: 2026-06-22 세션 종료 시. 대상: mbg-project 캘린더 반복 일정 기능.

---

## 0. 한 줄 요약

Quick add event에 기본 반복(Repeat) select까지는 완료/푸시됨. 다음은 구글 캘린더처럼
**(1) "옵션 더보기" 전체 이벤트 편집, (2) 맞춤 반복 UI, (3) 반복 전개 표시**를 만드는 것.
이 중 (3) 반복 전개 표시가 가장 중요하고 가장 큰 작업.

---

## 1. 환경 / 컨벤션 (그대로 따를 것)

- Repo: `MarineGift/mbg-project` (public), branch `marinebiogroup`, 로컬 `C:\dev\mbg-project` (Windows).
- 배포: Railway 자동 (push = 웹 배포). web 서비스 `mbg-project`, worker `lucky-patience`.
- DB: Supabase, schema `app`. 멀티테넌트 — insert 시 `organization_id` 필수(NOT NULL).
  인증/조직: `import { requireAuth } from '@/lib/auth'` → `auth.organizationId`, `auth.userId`.
- 언어: 사용자와는 한국어. 코드/SQL/식별자는 영어.
- 파일 전달: 수정본을 `/mnt/user-data/outputs/`에 고유 이름으로 저장 → present_files →
  사용자가 `$env:USERPROFILE\Downloads`로 받음 → PowerShell mover로 레포 경로에 복사.
  - mover는 **ASCII만** (PS 5.x가 UTF-8 no-BOM을 CP949로 깨뜨림). 한글은 .md(UTF-8 BOM)에만.
  - 브라켓/괄호 경로(`(app)`, `[partyType]`, `[id]`)는 `[System.IO.File]::Copy($s,$d,$true)` 리터럴 복사 필수.
  - `Unblock-File -LiteralPath` 먼저.
- Finish block: mover → `git add "<명시 경로들>"` → `git commit` → `git pull --rebase origin marinebiogroup`
  → `git push origin marinebiogroup`. 절대 `git add -A` 금지.
- 레포 파일 읽기: `https://raw.githubusercontent.com/MarineGift/mbg-project/marinebiogroup/<path>`
  (괄호 URL 인코딩: `(app)`→`%28app%29`, `[partyType]`→`%5BpartyType%5D`, `[id]`→`%5Bid%5D`).
  raw/API 둘 다 429 잦음 → 호출 사이 16~22초 sleep.
- 빌드는 type-check/lint 건너뜀(import 에러만 빌드 실패). 그래도 괄호 균형/백틱 검증 후 전달.
- 모든 수정은 outputs에 저장 후, 균형 체크:
  `python3 -c "s=open(F).read(); print({k:s.count(a)-s.count(b) for k,(a,b) in {'()':('(',')'),'{}':('{','}'),'[]':('[',']')}.items()})"`

---

## 2. 이번 세션에서 완료(푸시 완료)된 것

커밋 체인(최근): `5ba7ac5`(inbox HTML iframe) 이후 캘린더/미팅 작업이 이어짐.

1. 템플릿 party_type+stage 편집 UI, 답장 시 deal `current_stage`로 Template stage 자동선택.
2. inbox 메일 본문: `bodyHtml` 있으면 sandbox iframe 렌더(`<base target="_blank">`, 스크립트 차단),
   없으면 plain text를 URL linkify. 파일: `src/components/inbox/communication-detail-view.tsx`.
3. 미팅 저장 버그 3단계 수정:
   - `createMeeting` insert에 `organization_id` + organizer `user_id` 추가 (`src/lib/queries/meetings.ts`).
   - `createMeetingAction`이 throw 대신 `{ok,error}` 반환 → 모달에 실제 DB 에러 노출
     (`src/app/actions/create-meeting.ts`, `src/components/meetings/meeting-create-modal.tsx`).
   - **근본 원인**: Party 필드가 자유 텍스트라 이메일이 `party_id`(uuid)로 들어가 `22P02`.
     → party 이름 검색 드롭다운으로 교체, 선택 시 UUID 세팅.
     새 액션 `src/app/actions/search-parties.ts` (`searchPartiesForMeeting`).
4. 캘린더 day 모달: Month/Week에서 날짜 클릭 → 그날 전체 일정을 **feed_source 카테고리별**로
   그룹핑한 모달(`DayEventsModal` in `calendar-view.tsx`). 넓힘(max-w-3xl), 카테고리 내 2열, sticky 헤더.
   Week all-day는 4개 + "+N more"로 cap. ("+80 more"에 묻혀 안 보이던 문제 해결)
5. Quick add event 확대(max-w-lg) + **Repeat select** 추가, `recurrence_rule` 저장.
   `CreateCalendarEventInput`에 `recurrence_rule?: string | null` 추가
   (`src/lib/queries/calendar.ts`), QuickEventModal에 select (`src/app/(app)/calendar/page.tsx`).

---

## 3. 다음 작업 (이 세션의 목표)

사용자 요청: "구글 캘린더의 '옵션 더보기'처럼 만들자." 참고 이미지 = 구글 이벤트 편집 화면
(맞춤 반복: 매일/매주 N요일/매월 N번째 요일/매년/주중 매일/맞춤, 종료일·횟수, 참석자, Meet 링크 등).

### 3-1. "옵션 더보기" → 전체 이벤트 편집 (중간 난이도)
- QuickEventModal 하단에 "More options / 옵션 더보기" 링크 추가.
- 누르면 확장 폼(또는 별도 모달)에서: 설명(description), 위치(location),
  미팅 링크(meeting_url, Teams/Zoom/Google), 참석자(이메일 목록), 종료일 등 입력.
- `CreateCalendarEventInput`에는 이미 `description?, location?, meeting_url?, party_id?, engagement_id?` 있음.
  참석자/reminders는 `calendar_events.reminders`(jsonb 추정), 또는 별도 attendees 테이블 확인 필요.
- 저장은 기존 `createCalendarEvent` 재사용(`...input` spread라 필드 추가만으로 저장됨 — 단 컬럼 존재 확인).

### 3-2. 맞춤 반복 UI (RRULE 빌더) (중간 난이도)
- 현재 Repeat select 옵션: '' / FREQ=DAILY / FREQ=WEEKLY / FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR /
  FREQ=MONTHLY / FREQ=YEARLY. (DB에는 prefix 없이 `FREQ=...` 저장.)
- "맞춤..." 선택 시: 간격(INTERVAL), 요일 다중선택(BYDAY), 종료(없음 / 날짜 UNTIL / 횟수 COUNT) UI.
- 결과를 RRULE 문자열로 조립해 `recurrence_rule`에 저장.
- 표시용 요약은 이미 있는 `rruleSummary()` 확장(현재 고정 매핑만 처리).

### 3-3. ★ 반복 전개 표시 (가장 큰 핵심 작업)
- 현재: `recurrence_rule`은 저장되지만 캘린더 격자에 **단일 발생만** 표시됨(반복 안 펼쳐짐).
- 목표: 조회 범위(rangeStart~rangeEnd) 안에서 RRULE을 전개해 매 발생일에 칸을 채움 (구글처럼).
- 구현 지점: `src/lib/queries/calendar.ts`의 `getCalendarFeed` (calendar_events 조회 후 매핑하는 곳,
  대략 라인 70~210 사이; `recurrence_rule`을 매핑하는 줄 ~201 참고).
- 접근:
  1. recurrence_rule 없는 이벤트는 그대로 1개 item.
  2. recurrence_rule 있는 이벤트는 base start/end의 (시:분, 기간) 유지하면서 range 내 발생일 계산:
     - DAILY: INTERVAL 간격으로 +N일.
     - WEEKLY: BYDAY 있으면 해당 요일들, 없으면 start 요일. INTERVAL 주 단위.
     - MONTHLY: 같은 일(day-of-month) 또는 BYDAY=2FR 식(N번째 요일).
     - YEARLY: 같은 월/일.
     - UNTIL/COUNT로 종료.
  3. 각 발생을 개별 CalendarItem으로 펼쳐 반환(id는 `${baseId}:${occurrenceDate}` 식으로 유니크,
     클릭 시 원본 이벤트로 매핑되게 baseId 보존 필드 추가 권장).
  4. 라이브러리: `rrule` npm 패키지 사용 가능(설치 `npm i rrule`). 또는 직접 구현(범위가 월/주라 가벼움).
     - npm 설치는 네트워크 허용됨(registry.npmjs.org). 단 번들 영향 고려.
  5. 성능: range가 month/week로 좁아 전개량 적음. 단 무한 반복(UNTIL/COUNT 없음)은 range 끝까지만.
- 주의: 전개된 가짜 발생은 수정/삭제 시 원본을 가리켜야 함(또는 read-only로 시작).
  처음엔 표시 전용(클릭 시 원본 상세)만 해도 충분.

---

## 4. 핵심 파일 맵 (새 세션에서 바로 열 것)

### `src/app/(app)/calendar/page.tsx`  (client; 캘린더 페이지 + 모달들)
- `QuickEventModal` (함수 ~라인 30~): state title/startAt/endAt/allDay/saving/**recurrence**,
  `handleSave`가 `createCalendarEvent({title,start_at,end_at,is_all_day,recurrence_rule})` 호출.
  DialogContent `max-w-lg`. Repeat `<select>` 있음. → 여기에 "More options" 확장 추가.
- `rruleSummary(rr)` (~132~142): RRULE → 사람이 읽는 문자열. 맞춤 반복 추가 시 여기 확장.
- `ItemDetailPopup` (~144~): 이벤트 상세(반복 요약 표시). 전개 발생 클릭 시 원본 표시 처리 지점.
- 메인 CalendarPage 컴포넌트(~270~): state `items/createDate/createMode/detailItem/editItem/...`,
  `<CalendarView ... onItemClick={setDetailItem} />` (onDayClick은 CalendarView 내부에서 처리),
  `<QuickEventModal>`(createMode==='event'), `<MeetingCreateModal>`(createMode==='meeting').
  import alias: `createCalendarEventAction as createCalendarEvent` from `@/app/actions/calendar`.

### `src/lib/queries/calendar.ts`  ('server-only'; 피드 + CRUD)
- `getCalendarFeed` (대략 70~335): calendar_events + meetings + tasks + communications + milestones를
  합쳐 CalendarItem[] 반환. **반복 전개는 여기 calendar_events 매핑부에 추가**.
  - calendar_events select에 `recurrence_rule` 포함(라인 ~78), 매핑 `recurrence_rule: e.recurrence_rule ?? null` (~201).
- `CreateCalendarEventInput` (~353): title/description?/location?/meeting_url?/start_at/end_at/
  is_all_day?/**recurrence_rule?**/party_id?/engagement_id?.
- `createCalendarEvent` (~365): `requireAuth()` → insert `{...input, source:'internal',
  is_all_day, organization_id, user_id}`. spread라 input 필드 추가 시 자동 저장(컬럼 존재 시).
- `updateCalendarEvent` / `deleteCalendarEvent` (~385~): 편집/삭제. attendeeSchema/reminderSchema 존재(~389~).

### `src/components/calendar/calendar-view.tsx`  (client; 격자 + day 모달)
- `CalendarView` (~291): Props `items/onCreateEvent/onItemClick/onRangeChange`. 내부 state
  `view`(month/week), `pivot`, `dayModal`. MonthGrid/WeekGrid 분기. `visibleItems`(필터됨).
  `onRangeChange`로 부모가 range fetch (전개 표시 시 range 중요).
- `MonthGrid` (~56): 셀 클릭 → `setDayModal(day)`. `MAX_CHIPS_PER_DAY=3`, 초과분 "+N more".
- `WeekGrid` (~154): day 헤더 클릭 → `onDayClick(day)`(=setDayModal). all-day cap `MAX_WEEK_ALLDAY=4`.
  timed 영역은 topPercent/heightPercent로 절대배치(24h 압축; 자체 스크롤 미적용 — 필요 시 추가).
- `DayEventsModal` (파일 끝): 그날 일정을 `CALENDAR_FEED_SOURCES` 순서로 `feed_source`별 그룹 섹션.
  `CALENDAR_FEED_META[src]` = {label,color}. max-w-3xl, 카테고리 내 2열 그리드.
- `itemsForDay(items, day)` (~45): `item.start_at` 기준 같은 날 필터. (전개 후에도 이게 동작해야 함.)
- `CalendarEventChip` from `./calendar-event-chip` (색은 feed_source 기반).

### `src/lib/queries/calendar-meta.ts`  (타입/메타)
- `CalendarFeedSource`: event | meeting | deal_task | communication | todo |
  milestone_next_step | milestone_close.
- `CALENDAR_FEED_META`: 각 source → {label, color, defaultVisible}.
- `CALENDAR_FEED_SOURCES`: 위 순서 배열.
- `CalendarItem` 인터페이스: `start_at`, `end_at?`, `is_all_day?`, `feed_source?`,
  `recurrence_rule?`, `color?`, `source?`(internal/google/microsoft) 등.

### `src/app/actions/calendar.ts`  (server action wrappers)
- `createCalendarEventAction` / `updateCalendarEventAction` / `deleteCalendarEventAction` /
  `getCalendarFeedAction` / `fetchCalendarItemsAction` — 모두 `@/lib/queries/calendar` 코어를 감쌈.

---

## 5. DB: app.calendar_events 관련 (이미 존재하는 컬럼)

select에서 확인된 컬럼: `start_at, end_at, is_all_day, status, source, color,
recurrence_rule, reminders, transparency` (+ id, organization_id, user_id, title,
description, location, meeting_url, party_id, engagement_id 추정).
- `recurrence_rule` text (RRULE 본문, prefix 'RRULE:' 없이 `FREQ=...` 저장 중).
- `reminders` jsonb 추정, `transparency` 텍스트(busy/free 추정) — 옵션 더보기에서 활용 가능.
- 새 컬럼이 필요하면 Supabase SQL Editor에서 idempotent migration
  (`alter table app.calendar_events add column if not exists ...`).

---

## 6. 주의 / 팁

- 전개 표시(3-3)는 처음엔 **read-only**(표시 + 클릭 시 원본 상세)로 시작 권장. 발생별 편집/예외(EXDATE)는 후속.
- 무한 반복(UNTIL/COUNT 없음)은 반드시 조회 range 끝까지만 전개(무한 루프 방지, 상한 캡 예: 366회).
- 전개 item의 `id`는 유니크해야 React key 충돌 안 남: `${baseId}__${yyyymmdd}`.
  원본 추적용으로 `source_event_id`(또는 baseId) 필드를 CalendarItem에 추가하고 클릭 시 그걸로 상세 조회.
- Google/Microsoft 동기화(`source: google|microsoft`) 이벤트는 그쪽이 이미 전개해 보내줄 수 있으니,
  내부 전개는 `source==='internal' && recurrence_rule` 인 것만 대상으로.
- 시간대: start_at은 ISO(UTC) 저장, all-day는 `YYYY-MM-DDT00:00:00`. 전개 시 날짜 계산은 로컬 날짜 기준 주의.

---

## 7. 시작 멘트 예시 (사용자가 새 세션에서 말할 것)

"캘린더 반복 일정 — 옵션 더보기 + 반복 전개 표시부터 하자. HANDOFF 문서 기준으로."
→ 새 세션 Claude는 먼저 `getCalendarFeed`(calendar.ts ~70-210)와 QuickEventModal(page.tsx ~30-126)을
raw로 읽고 3-3 → 3-1 → 3-2 순서로 진행하면 됨.
