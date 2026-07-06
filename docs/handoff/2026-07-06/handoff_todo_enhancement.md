# Handoff -- 다음 세션: URM To-do 리스트 기능 보강 검토 (2026-07-06)

## 세션 목표
상용 To-do 앱(Todoist, TickTick, Things 3, Microsoft To Do 등)에서 가장 많이 쓰이는 기능을 조사하고, **URM task 엔진에 도입 가능한지 검토 -> 우선순위화 -> 실제 구현**까지 진행. 이 문서는 그 출발점(현황 + gap 분석 + 착수 지점)이다.

## URM 현재 task 엔진 현황 (2026-07-06 소스 확인)
이미 상당히 갖춰져 있음. 새로 만드는 게 아니라 **보강**이 맞다.

**데이터 모델** (`src/lib/tasks/types.ts`):
- `TaskBoard` (kind: todo/pipeline), `TaskStatusOption` (커스텀 상태+색상+is_done), `TaskGroup`, `TaskItem`, `TaskUpdate` (comment/status_change/system), `TaskDependency` (finish_to_start 등)
- `TaskItem` 필드: title, description, status, **priority**(low/med/high/urgent), assignee_user_id, **start_date/due_date**, position, **party_id/contact_id/communication_id**(CRM 연동), **parent_item_id**(서브태스크), custom(JSON), archived_at

**UI/뷰** (`src/components/tasks/task-board-view.tsx`, `/todo`, `/tasks`):
- **Kanban / Calendar / Gantt** 3-뷰 전환 (이미 있음)
- 칸반 컬럼 헤더에서 quick-add (title only)
- task-form-dialog, task-detail-client, task-activity-timeline (댓글/활동 로그)

**서버 액션** (`src/lib/tasks/actions.ts`): listBoards, listBoard, createItem, moveItem, updateItem, deleteItem, addUpdate

**즉, 이미 있는 것**: 보드/그룹/커스텀 상태, 우선순위, 담당자, 시작/마감일, 서브태스크, 의존성, CRM 링크(party/contact/comm), 코멘트/활동로그, 칸반/캘린더/간트.

## 상용 앱 핵심 기능 -> URM gap 분석
2026년 리서치(Todoist/TickTick/Things/MS To Do) 기준, "스틱하는 앱"이 공통으로 잘하는 것 + URM에 없는 것:

| 기능 | 상용 근거 | URM 현황 | 도입 난이도 |
|---|---|---|---|
| **빠른 캡처 + 자연어 입력(NLP)** | "가장 큰 QoL 기능" -- "call dentist tomorrow 3pm p1" 한 줄로 날짜/시간/우선순위/프로젝트 파싱 (Todoist 대표 강점) | quick-add는 title only, 파싱 없음 | **중** -- 파서 1개 + createItem 확장. **최우선 후보** |
| **반복 작업(recurring)** | MS To Do/Todoist/TickTick 전부 기본 | 없음 (단발 due_date만) | 중 -- RRULE 필드 + 완료 시 다음 인스턴스 생성 워커 |
| **다중/스마트 리마인더** | 시간·위치 기반, persistent nag (TickTick) | 없음 | 중 -- 기존 이메일/Slack 알림 인프라 재활용 가능 |
| **My Day / Today 계획 뷰** | MS "My Day", 오늘 할 일 집중 | `/today` 라우트 존재 -- 내용 점검 필요 | 하~중 |
| **자연어 필터/저장된 뷰** | "Filter Assist" 평문->쿼리 (Todoist) | 없음 | 중 |
| **AI 태스크 분해/음성-태스크** | Todoist Assist(목표->스텝), Ramble(음성), TickTick AI Mode | 없음 (단, URM은 이미 Anthropic API 연동됨 -- 이메일 AI로) | 중 -- generateAIEmail과 동일 패턴 재사용 가능 |
| **MCP 연동** | TickTick 8.x가 Claude/ChatGPT를 task 데이터에 직접 연결 | 없음 | 상 -- 후순위 |
| **캘린더 드래그 리스케줄** | TickTick 강점, 시간대 배치 | Calendar 뷰 있으나 드래그 리스케줄 여부 확인 필요 | 중 |
| **습관 트래커 / 포모도로 / 아이젠하워** | TickTick 번들 | 없음 | -- B2B CRM 성격상 **도입 보류 권장**(개인 생산성 기능, URM 목적과 거리) |

## 이 CRM 맥락에서의 판단
URM은 **개인 To-do 앱이 아니라 B2B 투자자 관계 CRM**이다. 그래서:
- **도입 가치 높음**: 자연어 quick-add, 반복 작업, 리마인더, Today 뷰, AI 태스크 분해 -- 전부 **CRM 워크플로우(팔로우업, 미팅 준비, 딜 넥스트스텝)를 가속**. 특히 task가 이미 party/contact/communication/deal에 링크되므로, "Pangaea 팔로업 목요일" 같은 자연어가 딜에 자동 연결되면 강력.
- **도입 보류**: 습관 트래커, 포모도로, 화이트노이즈, 아이젠하워 매트릭스 -- 개인 생산성 앱 기능이라 CRM 목적과 어긋남. 검토는 하되 우선순위 최하.

## 추천 착수 순서 (다음 세션에서 결정)
1. **자연어 quick-add (NLP 파서)** -- ROI 최고, 위험 낮음. 기존 createItem에 파싱 레이어만. "Pangaea 팔로업 next Thu p1" -> due_date+priority+party 자동. 한국어/영어 병행 파싱 필요(메모리의 언어 규약).
2. **반복 작업(recurring)** -- CRM 정기 팔로업에 실용적.
3. **AI 태스크 분해** -- generateAIEmail과 동일한 Anthropic 패턴. "딜 클로징 준비" -> 체크리스트 자동 생성.
4. **Today/My Day 뷰 강화** -- 이미 있는 `/today` 확장.

## 다음 세션 시작 방법 (프롬프트)
> "URM To-do 기능 보강을 시작하자. handoff_todo_enhancement.md의 gap 분석을 기준으로, 먼저 [자연어 quick-add / 반복 작업 / AI 태스크 분해 / Today 뷰] 중 하나를 골라 상용 앱(Todoist/TickTick) 동작을 조사하고, URM task 엔진(src/lib/tasks/)에 도입 가능한지 검토한 뒤 구현 패치를 만들어줘. 현재 스키마와 충돌 없는지 FK/컬럼부터 확인하고, 언제나처럼 idempotent PowerShell 패치 + inline fallback + handoff로 마무리."

## 착수 전 필수 확인 (다음 세션 첫 스텝)
- `src/app/(app)/today/page.tsx` 실제 내용 (My Day 뷰 현황)
- task 테이블의 실제 DB 스키마 (types.ts는 hand-written -- 실제 컬럼과 대조 필요. `sql/`에 task 마이그레이션이 안 보였음 -> 별도 마이그레이션이거나 앱에서 생성됐을 수 있음. FK probe로 확인)
- Calendar 뷰의 드래그 리스케줄 지원 여부
- 반복/리마인더용으로 재활용할 기존 워커: email sequence drip worker, scheduled send (메모리에 존재)

## 오늘까지의 완료 상태 (참고)
- Paper Mill 3쌍 병합, 9c 이메일(확정 21), Pangaea 발송(+열람), 이메일 패치 2건(첨부/reply + AI 지시창) 전부 커밋·push 완료. 워킹 트리 clean.
- 수요일 7/8 9:30 PT Pangaea 미팅 대기 중.
