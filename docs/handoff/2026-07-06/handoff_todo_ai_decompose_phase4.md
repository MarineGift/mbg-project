# Handoff — To-do Phase 4: AI 태스크 분해 (2026-07-06)

## 이번 세션 완료 내용
Phase 4 **AI 태스크 분해** 구현. 정석 방식(기존 ClaudeClient/에이전트 프레임워크 확장)으로, 새 에이전트 role `task_decomposer`를 추가해 기존 예산 체크·PII 마스킹·코스트 로깅(ai.runs)을 그대로 상속.

태스크(목표)를 열어 **"AI decompose"** 버튼 → 목표를 3~8개 구체적 서브태스크로 분해 → 각 서브태스크를 `parent_item_id`로 목표에 연결해 삽입. 예: "딜 클로징 준비" → ["텀시트 검토", "법률 자문 확인", "원페이저 최종화", ...].

## 아키텍처 (기존 프레임워크 재활용)
- **에이전트**: 새 role `task_decomposer`, model=Haiku(가벼운 구조화 출력), output_format=json, PII 마스킹 OFF(입력이 고객 데이터 아닌 내부 목표). org당 1개 활성 행.
- **호출**: `new ClaudeClient(supabase, orgId).complete({ agentRole:'task_decomposer', outputFormat:'json', inboundMessage: goalText })` — 이메일 reply-drafter와 동일 경로.
- **삽입**: 기존 `createItem`에 `parentItemId` 추가해 서브태스크를 목표의 자식으로.
- **인증**: `requireAuth()` → organizationId (drafts 액션과 동일 패턴).

## 스키마 변경
- `ai.agents.role` enum(USER-DEFINED)에 `task_decomposer` 라벨 추가.
- `ai.agents`에 org당 `task_decomposer` 시드 행 1개 (실측 probe 27컬럼 스키마에 정확히 맞춤: name, model, system_prompt, output_format='json', temperature=0.30, max_tokens=1024, applicable_party_types, require_pii_masking=false 등).
- 시스템 프롬프트: 목표를 3~8개 구체적 명령형 서브태스크로 분해, 목표 언어 매칭(한국어→한국어), 선택적 priority/due_offset_days, STRICT JSON 출력.

## 앱 변경
**A) `src/types/ai.ts`** — `AgentRole`에 `task_decomposer` 추가.
**B) `src/lib/tasks/actions.ts`** — `createItem`이 `parentItemId` 받음.
**C) `src/components/tasks/task-board-view.tsx`** — TaskModal(edit)에 "AI decompose" 버튼 + 핸들러(decomposeTask 호출 → 성공 시 모달 닫고 보드 새로고침 → 서브태스크 표시), 에러 메시지 표시.
**D) `src/lib/tasks/decompose-actions.ts`** (신규) — `decomposeTask(goalItemId)` 서버 액션. 목표 로드 → 보드 첫 미완료 status 확인 → AI 호출 → JSON 방어적 파싱(malformed면 에러, 부분 삽입 안 함) → 서브태스크 삽입.

## 검증
- **마이그레이션 (실 Postgres 16)**: enum 라벨 추가 + org당 시드 1행(2 org → 2행), model/output_format/is_active 정확. 재실행 idempotent(enum guard + NOT EXISTS → 0 insert, 중복 없음).
- **패치**: 8개 앵커(A1, B1-B2, C1-C4) 전부 현재 리포 파일에서 유일 매칭. 4파일(ai/actions/board-view/decompose-actions) 전부 esbuild 컴파일 통과.
- **방어적 파싱**: subtasks 배열 아니거나 title 없으면 스킵, priority는 유효값만, due_offset_days는 정수>=0만, 12개 하드캡.

## 파일 (4개)

| 파일 | 종류 | 목적지 |
|---|---|---|
| `migration_todo_ai_decompose_phase4.sql` | 마이그레이션 | `sql\` |
| `decompose-actions.ts` | 신규 소스 | `src\lib\tasks\decompose-actions.ts` |
| `patch_todo_ai_decompose_p4.ps1` | 패치(idempotent) | `tools\patches\` |
| `handoff_todo_ai_decompose_phase4.md` | 이 문서 | `docs\handoff\2026-07-06\` |

## 적용 순서

### ① 유니버설 무버
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

### ② 소스 인라인 무버 (`.ts`는 유니버설 무버 대상 아님)
```powershell
$src = Get-ChildItem "$env:USERPROFILE\Downloads\decompose-actions*.ts" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($src) {
  Unblock-File $src.FullName
  $d = 'C:\dev\mbg-project\src\lib\tasks'
  [System.IO.Directory]::CreateDirectory($d) | Out-Null
  [System.IO.File]::Copy($src.FullName, (Join-Path $d 'decompose-actions.ts'), $true)
  Remove-Item $src.FullName
  Write-Host 'MOVED: decompose-actions.ts -> src\lib\tasks\'
} else { Write-Host 'decompose-actions.ts NOT FOUND' }
```

### ③ 패치 실행
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\patches\patch_todo_ai_decompose_p4.ps1
```

### ④ Supabase SQL Editor에서 마이그레이션 실행
`migration_todo_ai_decompose_phase4.sql` 전체 실행. VERIFY가 org별 `task_decomposer` 행(model=haiku, output_format=json, is_active=t)을 반환하면 성공.

**주의**: enum 라벨 추가 do-block과 시드 INSERT가 한 파일에 있음. 일부 PG에서 "새 enum 값은 같은 트랜잭션에서 못 씀" 이슈가 있으나, Supabase 에디터는 statement별로 커밋하므로 정상. 만약 INSERT에서 enum 관련 에러가 나면, **do-block만 먼저 실행 → 그다음 INSERT부터 재실행**하면 됨.

### ⑤ 빌드
```powershell
cd C:\dev\mbg-project
npm run build
```

## 동작 테스트
`/todo` → 태스크 클릭(edit 모달) → **"AI decompose"** 버튼 → 잠시 후 모달 닫히고 보드에 서브태스크들이 첫 컬럼에 생성. 목표가 한국어면 서브태스크도 한국어. AI 예산 초과/에러 시 모달에 빨간 메시지.

## 마무리 (푸시해야 웹에 반영됨)
```powershell
cd C:\dev\mbg-project
git status -sb
git add sql\migration_todo_ai_decompose_phase4.sql src\lib\tasks\decompose-actions.ts src\types\ai.ts src\lib\tasks\actions.ts src\components\tasks\task-board-view.tsx tools\patches\patch_todo_ai_decompose_p4.ps1 docs\handoff\2026-07-06\handoff_todo_ai_decompose_phase4.md
git commit -m "feat(todo): AI task decomposition (Phase 4) - task_decomposer agent + decompose action + modal button"
git push origin marinebiogroup
```

## 오늘 To-do 보강 세션 전체 (Phase 1~4 완료)
1. Phase 1 — 자연어 quick-add (`9f3efa1`)
2. Phase 2 — 반복 작업 DB 트리거 (`1963fa9`)
3. Fix — 반복 트리거 org_id null (`b82d04b`에 포함)
4. Phase 2b — 반복 지정 UI (`b82d04b`)
5. Phase 3 — 태스크 리마인더 Slack+이메일 (`977b6a1`) + RPC users 조인 fix
6. Phase 4 — AI 태스크 분해 (이번)

## 미해결 (이월)
- Phase 3 리마인더 실제 발송: cron 등록 필요(vercel.json 또는 Railway curl). 엔드포인트·워커·DB 전부 준비됨.
- Calendar 뷰 드래그 리스케줄 지원 여부.
- `migration_campaign_rename_trigger.sql` (별건, 미적용 시 실행).
- 확장 아이디어: quick-add에서 바로 AI 분해(`매주 딜준비 --ai`), 서브태스크 생성 시 toast로 개수 표시, 목표 완료 시 미완료 서브태스크 경고.
