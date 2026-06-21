# HANDOFF (신규 세션) - URM To-Do/Task 고도화 (인기 to-do 앱 벤치마크 반영)

> 목적: URM의 기존 Task/To-Do 기능에 인기 to-do 앱(Todoist/TickTick/Things/MS To Do)의 검증된 기능을 **중복 없이** 추가.
> 이 문서는 2026-06-21 시장 조사 + URM 현행 진단 결과를 담은 **다음 세션 구현 착수용** 핸드오프.

---

## 0. 컨텍스트 (필독)

- repo: `MarineGift/mbg-project`, branch `marinebiogroup`. 로컬 `C:\dev\mbg-project` (Samsung SS_LAPTOP-HEO / Lenovo).
- Supabase project `ogenmrgxwhpbfepeldqx`, schema `app`. 데이터/RPC는 SQL Editor 실행으로 반영(push는 파일 이력만).
- 웹 `mbg-project`(push 자동배포), 워커 `lucky-patience`(`src/workers/all-workers.ts`).
- 컨벤션: 마이그레이션 `YYYYMMDDHHMMSS_*.sql`, ASCII `.sql`/`.ps1`, 한글은 UTF-8 BOM `.md`. 파일은 다운로드 후 PS mover로 repo 이동. in-place 수정은 PS 패치(ReadAllText->Replace->WriteAllText, CRLF->LF). finish block은 `git push origin marinebiogroup`로 끝.
- 직전 세션 핸드오프: `docs/research/HANDOFF_2026-06-21_email_sequence_live_outreach.md` (commit `56aa145`).

---

## 1. URM 현행 Task/To-Do 진단 (이미 있는 것 = 다시 만들지 말 것)

`app.tasks` 컬럼:
`id, organization_id, deal_id(NOT NULL), title, description, notes, status, priority,
 due_at, started_at, completed_at, estimated_minutes, actual_minutes,
 assigned_to_user_id, assigned_to_contact_id, checklist_id, created_by, updated_by,
 deleted_at, extra_data, created_at, updated_at`

이미 구현된 UI/로직:
- `src/app/(app)/tasks/` (page, list-client, add-task-modal, actions, [id] 상세, loading)
- `src/app/(app)/todo/page.tsx`
- `src/components/tasks/` : `task-board-view.tsx`(Kanban), `task-detail-client.tsx`, `task-form-dialog.tsx`, `task-activity-timeline.tsx`
- `src/components/parties/party-tasks-list.tsx` (party별 태스크)
- `src/lib/actions/tasks.ts`, `src/app/(app)/tasks/actions.ts`, `src/app/api/tasks/[id]/status/route.ts`
- playbook 체크리스트 -> 태스크 생성 (마이그레이션 `20260614_playbook_tasks_require_checklist.sql` 등)
- 마이그레이션 `20260603145353_rename_task_to_todo.sql`

**구조적 한계(개선 포인트):**
1. `deal_id`가 **NOT NULL** -> deal에 안 묶인 순수 개인 to-do 불가.
2. **자연어 quick-add 없음** (폼 입력만).
3. **반복(recurring) 없음** (recurrence 컬럼 없음).
4. **리마인더 알림 경로 불명확** (due_at은 있으나 알림 잡 미확인).
5. **Today 콕핏/스마트 리스트(Overdue/This Week/Waiting For) 약함.**

---

## 2. 시장 조사 요약 (2026)

- **Todoist** - 최고의 종합. 업계 최고 자연어 입력, 전 플랫폼, 80+ 연동. 무료 5프로젝트 제한.
- **TickTick** - 가성비 최고. Pomodoro 타이머 + 캘린더 + 습관 + Eisenhower 매트릭스 한 앱에.
- **Things 3** - 디자인/속도 최고(Apple 전용, $49.99).
- **Microsoft To Do** - 무료, Outlook 이메일 플래그 -> 자동 태스크.
- **Motion/Sunsama** - AI 자동 스케줄링/일일 계획.

**리뷰 공통 핵심:** (1) 5초 캡처 = 자연어 quick-add가 1순위. (2) 캘린더 양방향/시간블로킹. (3) Today 뷰 일일 콕핏(5~7개 집중). (4) 'Waiting For' 위임 추적. (5) Pomodoro->소요시간, Eisenhower 매트릭스. (6) 다단계 의존성 프로젝트는 PM 영역 -> URM은 파이프라인/playbook이 담당, To-Do는 "가볍고 빠른 개인/후속"에 집중.

---

## 3. 추가 추천 (중복 없는 것만, 우선순위순)

| # | 기능 | URL 재사용 / 스키마 델타 | 임팩트/난이도 |
|---|---|---|---|
| 1 | 자연어 quick-add ("Khosla 다음주 월 3pm p1") | 기존 Anthropic SDK(AI draft)로 파싱 -> 새 액션 `parseQuickTask` + add 액션 호출 | 高/中 |
| 2 | 반복 태스크 | `tasks.recurrence_rule text`(rrule) + 완료 시 다음 인스턴스 생성(액션/워커) | 高/中 |
| 3 | Today 콕핏 + 스마트 리스트(Overdue/This Week/Waiting For) | 기존 due_at/assignee 필터 뷰만 추가 | 高/低 |
| 4 | standalone 태스크(deal 없이) + Inbox | `deal_id` nullable 마이그레이션 + UI에서 deal 선택 옵션화 | 中/中 |
| 5 | 리마인더 알림(이메일/인앱) | due_at 기준 워커 잡(`reminder-worker`) + 메일 인프라 재사용 | 中/中 |
| 6 | 캘린더에 due 태스크 노출/시간블로킹 | 기존 Google/MS 캘린더 동기화에 task due 표시 | 中/中 |
| 7 | Pomodoro -> actual_minutes | 타이머 UI -> 기존 actual_minutes 필드 채움 | 中/低 |
| 8 | Eisenhower 매트릭스 뷰 | 기존 priority 재사용, 4분면 뷰 추가 | 低/低 |

**제안 단계 계획:**
- **Phase 1 (빠른 가치, 스키마 변경 최소):** #1 자연어 quick-add + #3 Today/스마트 리스트 + #8 매트릭스 뷰.
- **Phase 2:** #2 반복 + #5 리마인더 + #4 standalone(deal_id nullable).
- **Phase 3:** #6 캘린더 노출 + #7 Pomodoro.

---

## 4. Phase 1 구현 가이드 (착수용)

### 4-1. 자연어 quick-add
- 새 서버 액션 `parseQuickTask(text)` -> Anthropic SDK 호출(기존 AI draft 클라이언트 재사용), JSON only 응답:
  `{ title, due_at(ISO|null), priority('low'|'medium'|'high'|null), assignee_hint(string|null) }`.
- 프롬프트는 한국어/영어 혼용 입력 처리, 현재시각 기준 상대표현("다음주 월 3pm") 해석. 결과를 add-task 액션에 매핑.
- UI: `/todo` 또는 `/tasks` 상단에 단일 입력창 + Enter. 파싱 실패 시 폼으로 폴백.
- deal_id 필수 문제 회피 위해 Phase 2의 nullable 전까지는 "General/Inbox" 더미 deal 또는 선택된 deal 컨텍스트 사용.

### 4-2. Today 콕핏 + 스마트 리스트
- 새 뷰/탭: Today(due_at <= 오늘 끝 & 미완료), Overdue(due_at < now & 미완료), This Week, Waiting For(assigned_to_contact_id != null & 미완료).
- 기존 `tasks-list-client.tsx` 필터 확장 or 새 `today-view.tsx`. 서버 액션에 필터 파라미터 추가.

### 4-3. Eisenhower 매트릭스 뷰
- 4분면(긴급x중요). 축: priority(중요) x due 임박도(긴급, due_at 기준). 기존 board-view 패턴 재사용.

---

## 5. 결정 필요 (사용자 확인 사항)

1. Phase 1 스코프(자연어+Today+매트릭스) 이대로 진행? 아니면 우선순위 조정?
2. 자연어 파싱에 Anthropic SDK 사용 OK? (토큰 비용 소량 발생)
3. `deal_id` nullable 전환(Phase 2)을 Phase 1로 당길지? (standalone 태스크가 급하면)
4. 리마인더 채널: 이메일 / 인앱 / 둘 다?

---

## 6. 재개 첫 단계 (다음 세션)
1. 이 문서 + `src/lib/actions/tasks.ts` + `src/app/(app)/tasks/` 확인.
2. 사용자에게 §5 결정 확인.
3. Phase 1 #1(자연어 quick-add)부터: `parseQuickTask` 액션 -> add-task 매핑 -> 입력창 UI. esbuild 검증 -> PS 패치 -> push.
