# HANDOFF-9 — mbg-project Todo Task Engine

repo: C:\dev\mbg-project  | branch: marinebiogroup
stack: Next.js 14.2 / Supabase (multi-schema, app.*) / Anthropic SDK
Supabase project: ogenmrgxwhpbfepeldqx | org id: b25de8f2-1020-482f-9012-183f63883169

## 무엇을 만들고 있나
Monday.com 스타일 **Todo 작업 엔진** (kanban / calendar / gantt).
- 새 엔진 = standalone **Todo** 전용 (app.task_items 계열). 내부 업무용.
- 기존 app.tasks = deal 소속 (deal_id NOT NULL, checklist_id) = **Pipeline/Engagement Task**. 별개. 안 섞음.
- 화면의 기존 "Tasks" 사이드 항목은 engagement Task → 사이드바에서 빼고, deal 상세 안 탭으로 갈 예정.

## DB — 전부 완료 (Supabase SQL Editor에서 적용됨)
app 스키마에 생성: task_boards, task_status_options, task_groups, task_items,
task_updates, task_dependencies (+인덱스, updated_at 트리거, RLS).
- RLS: communications 패턴 모방. SELECT = org match OR is_member; INSERT/UPDATE/DELETE = org match; to authenticated.
- 컬럼 DEFAULT: organization_id = app.current_organization_id(), created_by/author_user_id = auth.uid().
- Todo 보드 시드됨 (컬럼 key: backlog/todo/working/review/done). Pipeline 보드는 제거함(Todo 전용).
- Todo 샘플 4개 적재됨.
- **중요**: SQL Editor는 postgres 역할(JWT 없음)이라 default가 NULL → 시드 시 organization_id를 리터럴로 명시해야 함. 앱 insert는 JWT 있어서 default 정상 동작.

## 앱 코드 — 배치/검증 상태
경로:
- src/lib/tasks/types.ts            (도메인 타입) — 배치됨
- src/lib/tasks/actions.ts          (서버액션) — 배치됨, **수정 완료**
- src/app/(app)/todo/page.tsx       (서버 컴포넌트, Todo 보드 resolve→listBoard→렌더) — 배치됨
- src/components/tasks/task-kanban.tsx (클라 칸반) — 배치됨, **Tailwind 버전 교체 중**

### 핵심 패턴 (확정)
- 서버 클라: `import { createSupabaseServerClient as createClient } from '@/lib/supabase/server'`
  → 반환 타입 SbClient = SupabaseClient<Database,'app'>. **이미 app 스키마 고정.**
- 따라서 **`.schema('app')` 쓰지 말고 `.from('TABLE' as never)` 직접** (Gotcha #45). 쓰기 payload는 `as never` 캐스트.
- page.tsx: export const dynamic = 'force-dynamic' (Realtime 붙기 전까지 항상 fresh).

### 해결한 버그 (이미 고침)
1. import 이름 틀림: createClient → 실제 export는 createSupabaseServerClient. (alias로 해결)
2. 이중 schema: 클라가 이미 app인데 .schema('app') 또 호출 → 제거함.
3. CSS 안 먹음: styled-jsx가 App Router에서 주입 안 됨 → **Tailwind className 버전으로 교체**(앱이 Tailwind 사용 확인).

## 지금 상태 (마지막 확인)
- /todo 에서 **카드 4개 데이터 정상 표시** (읽기 배선 OK). 컬럼 배치 정확.
- CSS만 깨져 있었음(styled-jsx) → Tailwind 버전 만들어 둠. **이걸 적용하고 모양 확인하는 게 다음 첫 작업.**

## 다음 할 일 (순서)
0. [즉시] task-kanban.tsx Tailwind 버전 적용 → /todo 가로 5컬럼 칸반 확인.
   검증 3종: (a) 5컬럼 카드 모양 (b) 드래그→다른 컬럼→새로고침 유지(moveItem) (c) +→Enter→추가(createItem).
1. 사이드바 정리: 기존 "Tasks" 항목 → 라벨 "To-Do", href /tasks→/todo, 배지 제거.
   **/tasks 페이지/라우트는 살려둠** (engagement Task 탭 재활용). nav 파일을 ASCII anchor splice로 패치.
   - nav 파일 위치 찾기: Select-String -Path "src\**\*.tsx" -Pattern "Dashboard" -List
2. Realtime 훅: app.task_items 구독 → 칸반 auto-refresh (inbox realtime과 동일 메커니즘).
3. Calendar / Gantt 탭: 같은 listBoard 데이터에 렌더러 추가.
   - **발견**: app.calendar_connections / calendar_events / calendar_sync_log 이미 존재.
     → Calendar 뷰는 라이브 API 안 거치고 app.calendar_events 읽어서 Google/MS 일정 오버레이 (더 간단).
     먼저 calendar_events 내용 확인 후 결정.
4. Engagement(deal) 상세: Tasks 탭(app.tasks where deal_id) + Checklist 탭(app.deal_checklists) 추가. (기존 데이터 이미 있음. Todo 엔진과 별개.)

## PowerShell 규칙 (매 세션 적용)
- Downloads = $env:USERPROFILE\Downloads (영문 경로).
- .ps1 실행: powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Downloads\xxx.ps1"
- 콘솔 출력 ASCII 전용 (PS 5.x가 UTF-8 no-BOM을 CP949로 파싱→한글 깨짐). 한글은 .md(UTF-8 BOM)만.
- **파일 전달 표준**: repo용 파일 만들 때마다 **이동 스크립트(.ps1) 항상 동봉**.
  Downloads→repo 정확 경로 Move (New-Item -Force, Unblock-File, Move-Item -Force, 영문 콘솔).
  (반복 요청 불필요 — 자동.)

## 마지막 출력물 (outputs/)
- task_kanban.tsx (Tailwind, 173줄) + move_kanban_fix.ps1
- tasks_actions.ts (수정본: import 고침 + .schema 제거) + move_actions_fix.ps1
- tasks_board_page.tsx + move_todo_ui.ps1
- tasks_types.ts + move_tasks_files.ps1
- mbg_tasks_schema_v1_1.sql, mbg_tasks_rls_and_seed.sql (DB, 적용 완료)
- mbg_tasks_app_shell.html (HTML 프로토타입 = 디자인 레퍼런스. 마린 테마: 사이드바 딥틸-네이비, 메인 라이트, 틸 액센트. status색 backlog#5c7884 todo#22c3d6 working#a78bfa review#4ade80 done#14b8a6)
