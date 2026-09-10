# HANDOFF — 일과표(Routine Schedule) & 달성률 리포팅

날짜: 2026-09-10 · 대상: URM Platform (`Marinegift/MBG-Project`, Next.js + Supabase `app` schema)

## 무엇을 만들었나
매일 06:00~23:00 반복 일정(운동/영어/업무 등)을 **계획**으로 등록하고,
날짜별로 **실제 수행 여부**(완료/부분/건너뜀)를 체크한 뒤,
**매일·주간·월간·연간·카테고리별 달성률**을 보는 기능.

- 계획 테이블 `app.routine_blocks` (반복 시간블록, 요일 비트마스크)
- 실행 로그 `app.routine_logs` (날짜×블록=1행, unique)
- 리포팅 뷰 6종 (일/주/월/년/카테고리 + 핵심 상태 뷰)
- 화면 3개: `/schedule`(오늘 체크), `/schedule/reports`(리포트), `/schedule/edit`(편집)

## 적용 순서

### 1) DB 마이그레이션 (필수, 먼저)
`sql/20260910_routine_schedule.sql` 을 **Supabase SQL Editor에서 Ctrl+A → RUN**.
- 멱등: 여러 번 실행 안전.
- 시드는 `org_members` 에서 조직 소유자(owner)를 찾아 21개 기본 블록을 주입.
  소유자 판별이 안 되면 시드만 건너뜀(테이블/뷰는 생성됨) → 화면의 "기본 일정표 불러오기" 버튼으로 대체 가능.
- 뷰는 `security_invoker = true` (PG15+, Supabase OK) → 각 사용자가 본인 데이터만 조회.

확인 쿼리(파일 하단 주석):
```sql
select * from app.routine_blocks order by start_time;
select * from app.v_routine_adherence_daily   order by bucket desc;
select * from app.v_routine_adherence_weekly  order by bucket desc;
select * from app.v_routine_adherence_monthly order by bucket desc;
select * from app.v_routine_adherence_yearly  order by bucket desc;
select * from app.v_routine_adherence_category order by adherence_pct;
```

### 2) 프론트엔드 파일 배치
레포 루트 기준 동일 경로에 복사:
```
src/app/(app)/schedule/page.tsx
src/app/(app)/schedule/reports/page.tsx
src/app/(app)/schedule/edit/page.tsx
src/app/actions/schedule.ts
src/components/schedule/constants.ts
src/components/schedule/aggregate.ts
src/components/schedule/schedule-today.tsx
src/components/schedule/schedule-reports.tsx
src/components/schedule/schedule-editor.tsx
src/components/schedule/load-template-button.tsx
```

### 3) 사이드바 메뉴 추가 (2군데)
`src/components/layout/sidebar.tsx`

(a) lucide 아이콘 import 블록(`} from 'lucide-react';` 위쪽)에 한 줄 추가:
```ts
  Clock,
```

(b) `TOP_ITEMS` 배열에서 `/calendar` 줄 **아래**에 추가:
```ts
  { href: '/schedule', labelKey: 'schedule', icon: Clock, label: '일과표' },
```
`label` 을 명시했으므로 next-intl 메시지 파일은 건드릴 필요 없음(To-Do/Today와 동일 패턴).

## 설계 메모
- **계획 vs 실제 분리**: `routine_blocks`(반복 계획)와 `routine_logs`(날짜별 실행)를 분리.
  "미수행(missed)"은 별도 저장 없이 *계획은 있는데 로그가 없는 과거 날짜*로 계산 → 데이터 최소화.
- **요일**: `weekday_mask` 비트마스크 (bit0=일 … bit6=토, 127=매일). 평일=`0b0111110`, 주말=`0b1000001`.
- **달성률 공식**: `(done + 0.5×partial) / 도래한 계획수`. 미래/오늘 미체크(pending/upcoming)는 분모에서 제외(과거 날짜만 due). SQL 뷰와 TS 집계(`aggregate.ts`)가 동일 규칙.
- **시간대**: `constants.ts`의 `APP_TIMEZONE = 'America/Chicago'`(휴스턴). 이전/여행 시 이 값만 변경.
- **타입 안전**: 기존 `Database` 타입 재생성 없이 `.from('routine_blocks' as never)` 패턴 사용(사이드바/레이아웃과 동일) → 프론트 변경 없이 동작.
- RLS는 calendar_events 패턴 그대로(본인 org+user만 전체 권한).

## 검증 상태
- SQL: `pglast.parse_sql()` 구문 통과.
- 프론트: 전 파일 esbuild 구문 통과. `aggregate.ts` 로직 단위테스트 통과
  (오늘 partial→25%, 어제 done1/skip1→50%, 주/월/카테고리 집계 검증).
- 미검증: 실제 Supabase 실행/실제 브라우저 렌더(로컬 `pnpm dev` 또는 배포에서 최종 확인 권장).

## 다음 개선 후보(선택)
- 요일별 다른 일과(예: 주말 루틴) — 이미 weekday_mask로 가능, UI 프리셋만 추가.
- 실제 소요시간(actual_minutes) 입력 UI(스키마엔 이미 있음).
- 대시보드(`/`)에 오늘 달성률 위젯 카드.
- 스트릭(연속 달성 일수) 뱃지.
