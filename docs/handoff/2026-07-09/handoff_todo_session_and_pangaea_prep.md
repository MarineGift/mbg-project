# Handoff — To-do 보강 세션 종합 + Pangaea 미팅 준비 (2026-07-06)

## 이 세션에서 한 일 (To-do 기능 보강 Phase 1~4)
상용 To-do 앱(Todoist/TickTick/Pipedrive/HubSpot) 기능을 검토해 URM `todo_items` 엔진에 도입. 각 단계 실 Postgres 16 / Node 런타임 / esbuild로 검증.

| 단계 | 내용 | 커밋 | 상태 |
|---|---|---|---|
| Phase 1 | 자연어 quick-add (날짜/우선순위/@파티, 한·영) | `9f3efa1` | 배포 |
| Phase 2 | 반복 작업 DB 트리거 (완료 시 다음 인스턴스) | `1963fa9` | 라이브 확인 (↻) |
| Fix | 반복 트리거 org_id null 버그 | `b82d04b` | 검증 |
| Phase 2b | 반복 지정 UI (Repeat 드롭다운 + 카드 ↻ + 파서 토큰) | `b82d04b` | 배포 |
| Phase 3 | 태스크 리마인더 | `977b6a1` → `65420d6` | **롤백** |
| Fix | 리마인더 RPC users 조인 버그 | `977b6a1` | (롤백에 포함) |
| Phase 4 | AI 태스크 분해 (task_decomposer 에이전트) | `7471273` | 라이브 확인 |
| 전환 | ai.agents role enum → lookup 테이블 | `0aaf3ec` | 검증 |
| 정합 | AgentRole 타입 정정 (extractor/translator) | `0aaf3ec` | 배포 |

### Phase 3 롤백 사유 (중요)
Phase 3(리마인더)는 **이미 존재하는 시스템과 중복**이었다. 기존:
- `src/lib/reminders/process.ts` + `src/workers/reminder-worker.ts` ("todo_v2 Phase 1")
- `all-workers.ts`에 배선 → `npm run worker:all`로 프로덕션 실행 중
- 대상: todo_items + 딜 태스크 + 딜 마일스톤 (더 넓음), `app.reminder_log` idempotent
- 설정: `REMINDER_SEND_HOUR`(8), `REMINDER_TZ`(Asia/Seoul) 등

내가 만든 중복분(`src/lib/tasks/reminder-worker.ts`, `/api/tasks/reminders` route, `reminded_at` 컬럼, RPC 2개, 인덱스)은 `rollback_todo_reminders_phase3.sql` + `git rm`으로 제거 완료(`65420d6`). **기존 `src/workers/reminder-worker.ts`는 그대로 살아있음** (이름 같지만 다른 파일).

### 기존 리마인더 상태
`npx tsx --env-file=.env.local src/workers/reminder-worker.ts --force` 실행 → `eligible:true, usersConsidered:0, sent:0` = 워커 정상, 지금 대상 없음. env 미설정 시 기본값 동작. 별도 cron 등록 불필요(워커 루프에 이미 있음).

## DB 최종 상태 (todo_items)
- Phase 1: 변경 없음 (기존 컬럼 사용)
- Phase 2: `recurrence`, `recurrence_ends`, `recurrence_parent_id` + 트리거 `trg_todo_spawn_next_occurrence` + `app.todo_advance_date()`
- Phase 3 롤백: `reminded_at` 제거됨
- Phase 4: `ai.agent_roles` 테이블(role 7개) + `ai.agents.role` text FK + `task_decomposer` 에이전트(org당 1) + enum 타입 제거

## 이월 (다음 세션)
- 기존 리마인더 워커 Railway 실행/env 최종 확인 (동작은 검증됨).
- Calendar 뷰 드래그 리스케줄.
- `migration_campaign_rename_trigger.sql` (세션 시작 시 올라온 별건, 미적용 시 실행).
- (선택) quick-add에서 바로 AI 분해, role 관리 UI(이제 lookup 기반이라 쉬움).

---

# Pangaea Ventures 미팅 준비 (수 7/8 9:30 AM PT)

## 확정 사실
- **상대**: Andrew Haughian (Partner, Pangaea Ventures, Vancouver). andrew@pangaeaventures.com, +1.604.787.3478. 엔지니어 배경 투자자 → 기술·구조 중심 어젠다가 잘 먹힘.
- **일시**: 2026-07-08(수) 9:30 AM PDT = 11:30 AM Austin(CDT) = 16:30 UTC. 캘린더 30분 슬롯 확인됨.
- **URM 레코드**: Deal "Pangaea Ventures — FCC Seed"(First Meeting stage), Meeting row + attendee 2명 생성 완료.

## 준비물 상태
- **원페이저**: `Marinebio_OnePager_v2.docx` (Ver1.8 덱 수치 일치, placeholder 없음). Bridge/SAFE 프레이밍 v3 반영본 → PDF로 이메일 첨부용 변환됨.
- **pre-meeting 이메일**: "Agenda-setting" 변이 작성됨(권장). 오늘 오전(7/6) 8:30–9:00 PT 발송이 최적 — **이미 발송했는지 확인 필요**(메모리상 발송 단계까지 갔음).

## 핵심 수치 (Ver1.8, 실사에서 흔들리면 안 됨)
- **라운드**: US$1M bridge, SAFE(valuation cap US$20M) 또는 priced equity. Bridge = "매출 직전 마지막 de-risking 구간 진입"으로 프레이밍(약세 신호 아님).
- **자금 사용처**: $500K 특허 이전 / $200K 티슈 테스트 / $300K 운영.
- **트랙션**: 9,000 t/yr 확정 + ~10,000 t/yr in motion (GCC·PCC 양쪽 validated).
- **로열티**: 3–5% on $250–350/ton. 밀 CAPEX 0. (펄프 $600–800/t 대비 FCC $250–350/t → 경제성이 판매를 밈.)
- **매출 전망**: Y1 $2.9M / Y2 $8.2M / Y3 $22.4M.
- **팀**: Heo(CEO) / Seo(CTO) / Lee(CPO).
- **주의**: 로열티는 "targeted to close within 6–12 months"(확정 아님). Series A만 언급(B 제거). SAFE 세부(cap/discount/MFN)는 변호사 검토 영역.

## 어젠다 (30분)
1. FCC 5분 요약 — fiber-mineral bonding이 bulk-vs-strength trade-off 제거, 티슈에서 validated된 첫 필러(~2M t/yr 시장, 기존 업체 진입 불가).
2. 커머셜 상태 — 확정 9,000 + in motion 10,000, GCC·PCC 양쪽, royalty 모델(밀 zero CAPEX).
3. 라운드 구조 + Pangaea 핏.

## 포트폴리오 앵커
**CarbonCure** — 거대 커머디티 산업(콘크리트)에 미네랄 기술 삽입, 생산자 CAPEX 최소. FCC가 같은 논리를 종이에 적용. Andrew에게 이 아날로그가 가장 잘 통함.

## 미팅 전 최종 체크리스트
- [ ] pre-meeting 이메일 실제 발송됐는지 확인 (안 됐으면 오늘 중 발송; 지금은 7/6 오후이므로 화/수 아침 재조정 고려)
- [ ] 원페이저 PDF 최신본이 첨부됐는지
- [ ] `/meetings/[id]` 라우트 — 과거 404 버그. 메모리상 수정됨으로 표시. 미팅 전 URM에서 해당 미팅 열어 확인 권장
- [ ] Q&A 준비 스크립트 리포에 있음(확인)
- [ ] 통화 링크/시간대 재확인 (9:30 PT = 11:30 CDT)

## 예상 Q&A 대비 포인트
- "왜 지금 bridge인가?" → 로열티 계약 체결 직전, 가장 싼 가격에 마지막 리스크 구간 진입.
- "티슈 validation 상태?" → 진행 중, bridge 자금의 $200K가 여기 배정.
- "왜 Pangaea?" → advanced materials 딥테크 + CarbonCure류 커머디티-삽입 모델 경험.
- "경쟁/특허?" → FCC 특허 이전이 자금 사용처 $500K. 기존 필러가 못 가는 티슈 시장.
