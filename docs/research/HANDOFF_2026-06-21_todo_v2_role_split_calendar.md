# HANDOFF (신규 세션) - URM To-Do 고도화 v2 (역할 분리 + 캘린더 통합)

> v1을 대체. v1은 app.tasks만 보고 더 중요한 todo_items 엔진을 놓쳤음 -> 본 v2가 정정본.
> 확정 방향: **대형 프로젝트 = Pipeline(app.deals), 소형 프로젝트 + 메모 = To-Do(todo_items), 통합 보기 = 캘린더.**

---

## 0. 컨텍스트
- repo `MarineGift/mbg-project`, branch `marinebiogroup`, 로컬 `C:\dev\mbg-project`.
- Supabase `ogenmrgxwhpbfepeldqx`, schema `app`. RPC/데이터는 SQL Editor 실행. push는 파일 이력만.
- 웹 `mbg-project`(자동배포), 워커 `lucky-patience`.
- 컨벤션: 마이그레이션 `YYYYMMDDHHMMSS_*.sql`, ASCII `.sql`/`.ps1`, 한글 UTF-8 BOM `.md`, PS mover/패치, finish=`git push origin marinebiogroup`.
- 참고 핸드오프: `HANDOFF_2026-06-21_email_sequence_live_outreach.md`.
- **주의: `src/types/database.ts`는 stale.** deals.next_step / next_step_date / stage_entered_at 등 라이브 컬럼 누락. 신뢰는 live DB.

---

## 1. 현행 아키텍처 (3개 모델 - 이미 분리되어 있음)

| 시스템 | 테이블 | 위치 | 성격 |
|---|---|---|---|
| **A. CRM Deal 파이프라인** | `app.deals` + `app.pipelines` + `app.pipeline_stages` | `/pipelines/[code]` | 대형 프로젝트/영업 단계 칸반 |
| **B. To-Do/보드 엔진** | `app.todo_boards / todo_items / todo_groups / todo_status_options / todo_item_comments / todo_item_dependencies` | `/todo` | 유연 보드(Kanban/Calendar/Gantt), 하위태스크(parent_item_id), 의존성, 그룹, party/contact/communication 링크 |
| **C. Deal 태스크** | `app.tasks` (`deal_id` NOT NULL) | `/tasks`, party 태스크, playbook | deal 종속 태스크 |

`todo_items` 주요 컬럼: id, board_id, group_id, parent_item_id, title, status, assignee_user_id, party_id, contact_id, communication_id, **start_date('YYYY-MM-DD')**, **due_date('YYYY-MM-DD')**, position, archived_at.
`app.deals` 마일스톤 컬럼: **next_step_date**, **expected_close_date** (그 외 actual_close_date, last_activity_at).
`app.tasks` 날짜: **due_at(timestamp)**.

---

## 2. 확정된 설계 결정 (사용자 승인 완료)

1. **To-Do(B) = todo_items 만 사용.** 대형 프로젝트는 Pipeline(A)으로 만들고, **소형 프로젝트 + 단순 메모만 To-Do.**
2. **To-Do에 deal_id 추가하지 않음.** 순수 메모/소형 전용 -> deal 종속 불필요. (todo_items에 deal_id 없음 = 현 구조 그대로 OK)
3. **C(app.tasks)는 Pipeline/deal 전용으로 유지.** todo_items로 수렴(리팩터) 안 함 -> 역할 분리.
4. **통합은 "캘린더 읽기-통합(read-model)"으로 달성.** 데이터는 각자 테이블, **캘린더 뷰가 합쳐서 표시.**
5. 캘린더에 합칠 소스: **To-Do(todo_items) + Deal 태스크(app.tasks) + Deal 마일스톤(app.deals)** ( + 기존 캘린더 이벤트).

> "Deal 마일스톤" = app.deals의 next_step_date / expected_close_date 같은 일정 포인트 (별도 테이블 아님).

---

## 3. 작업 범위

### 3-1. 캘린더 통합 (최우선 - "통합 경험"의 핵심)
- 기존 캘린더: `src/app/(app)/calendar/page.tsx`, `src/lib/calendar/sync-engine.ts`, `src/lib/calendar/write-back.ts`, `src/lib/google/client.ts`.
- **새 집계 액션** `getCalendarFeed(rangeStart, rangeEnd)` -> 아래 4소스를 통일 이벤트 형태로 병합:
  - To-Do: `todo_items` where due_date(또는 start_date) in range, archived_at is null. 색=초록, type='todo'. 클릭 -> /todo 항목.
  - Deal 태스크: `app.tasks` where due_at in range, deleted_at is null. 색=파랑, type='deal_task'. 클릭 -> deal.
  - Deal 마일스톤: `app.deals` where next_step_date in range OR expected_close_date in range. 색=보라, type='deal_milestone'(next_step) / 'deal_close'(expected_close). 클릭 -> deal.
  - 기존 동기화 이벤트(Google/MS): 그대로.
- 통일 이벤트 타입: `{ id, source, title, date(or start/end), color, href, meta }`.
- RLS: 모든 쿼리는 org 스코프 자동(`current_organization_id()`); 명시적 `.schema('app')`.
- 출처별 색/아이콘 범례 + 필터 토글(To-Do/Deal태스크/마일스톤/이벤트 on-off).

### 3-2. To-Do(todo_items)에 인기앱 기능 얹기
대상은 모두 **todo_items** (app.tasks 아님). 인기 to-do 앱 벤치마크(2026: Todoist/TickTick/Things/MS To Do) 반영:

| # | 기능 | 구현 요지 | 임팩트/난이도 |
|---|---|---|---|
| 1 | 자연어 quick-add | 기존 Anthropic SDK(AI draft)로 파싱: 입력 "Khosla 다음주 월 p1" -> {title, due_date, priority}. 새 액션 `parseQuickTask`. 실패 시 폼 폴백 | 高/中 |
| 2 | Today 콕핏 + 스마트 리스트 | Today(due<=오늘), Overdue(due<now), This Week, Waiting For(assignee=contact). todo_items 필터 뷰 | 高/低 |
| 3 | 반복(recurring) | `todo_items.recurrence_rule text`(rrule) + 완료 시 다음 인스턴스 생성 | 中/中 |
| 4 | 리마인더 알림 | due_date 기준 워커 잡(reminder-worker) + 기존 메일 인프라 | 中/中 |
| 5 | Eisenhower 매트릭스 뷰 | priority x due 임박도 4분면. 기존 board-view 패턴 재사용 | 低/低 |

> Pomodoro->소요시간은 todo_items에 시간필드 없음(app.tasks엔 actual_minutes 있음). To-Do용으로 원하면 todo_items에 필드 추가 필요 -> 후순위.

---

## 4. Phase 계획
- **Phase 1 (통합 골격, 빠른 가치):** 3-1 캘린더 통합(To-Do+Deal태스크+마일스톤) + 3-2 #2 Today 콕핏.
- **Phase 2:** 3-2 #1 자연어 quick-add + #5 매트릭스 뷰.
- **Phase 3:** 3-2 #3 반복 + #4 리마인더.

---

## 5. 잔여 결정 (다음 세션 착수 시 확인)
1. 캘린더에서 Deal 마일스톤은 next_step_date / expected_close_date **둘 다** 표시? 아니면 하나만?
2. 자연어 quick-add에 Anthropic SDK 사용 OK? (토큰 비용 소량)
3. 리마인더 채널: 이메일 / 인앱 / 둘 다?
4. Today 콕핏을 `/todo` 안 탭으로? 별도 페이지로?

---

## 6. 재개 첫 단계
1. 본 문서 + `src/lib/tasks/actions.ts`(todo 엔진) + `src/app/(app)/calendar/page.tsx` + `src/lib/calendar/sync-engine.ts` 확인.
2. §5 결정 확인.
3. Phase 1: `getCalendarFeed` 집계 액션 작성(4소스 병합) -> 캘린더 뷰에 출처별 색/필터 -> esbuild 검증 -> PS 패치 -> push.
