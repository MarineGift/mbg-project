\xef\xbb\xbf# handoff_20260917_ai_reply_only (v2) — AI는 "AI 답장" 버튼에서만 (OpenAI). 나머지 AI 전부 제거

> 저장소가 Public이므로 키/비밀번호/외부인 연락처를 적지 않는다.

## 1. 원칙 (사용자 결정, 2026-09-17)
- AI 호출은 **받은 메일에 답장할 때 "Generate AI reply" 버튼을 누를 때만**. 제공자는 OpenAI.
- 자동으로 AI를 부르는 기능은 만들지 않는다 (자동 초안, 자동 분류, 자동 전략 등 금지).
- 이 문서 작성 전 원인: mailcarrier 워커가 수신 메일마다 분류 + 답장 초안을 자동 생성 → 9/16 약 $51, 9/17 01시까지 약 $8.

## 2. 변경 (커밋 be2b2dc 기준)
| 구분 | 파일 | 내용 |
|---|---|---|
| 유지(AI) | `src/lib/ai/openai-chat.ts` | 앱의 유일한 AI 호출 `generateReply()`. 모델 `OPENAI_REPLY_MODEL`(기본 gpt-5-mini) |
| 유지(AI) | `src/lib/actions/email-compose.ts` | `generateAIReply`만 남김. 새 메일 AI 작성(`generateAIEmail`) 삭제 |
| UI | `src/components/email/compose-email-dialog.tsx` | "AI Draft" 탭은 답장 모드에서만 표시, 버튼은 "Generate AI reply"만 |
| UI | `src/components/tasks/task-board-view.tsx` | "AI decompose" 버튼 삭제 |
| 수신 | `src/lib/email/processor.ts` | **AI 없음.** 규칙 분류만 → `communications.ai_classification` 저장. 초안 생성 없음. `external_data`는 병합 저장(수신 헤더 보존) |
| 수신 | `src/lib/email/rule-classifier.ts` (신규) | 헤더/발신자/키워드 규칙 분류기 (영/한/일) |
| 수신 | `src/lib/email/header-parser.ts` | 자동메일 판정용 헤더 4개 추가 저장 |
| 수신 | `src/workers/mailcarrier-worker.ts` | 로그: `classified (rules, no AI)` |
| 삭제 | `src/lib/ai/claude-client.ts`, `cost-tracker.ts`, `prompt-renderer.ts` | 자동 AI 파이프라인 |
| 삭제 | `src/workers/consultation-worker.ts` | 상담 → AI 전략 생성 워커 (all-workers에는 없었음) |
| 삭제 | `src/lib/tasks/decompose-actions.ts` | 할 일 AI 분해 |
| 삭제 | `src/scripts/simulate-inbound.ts` | AI 파이프라인 시뮬레이터 |
| 환경 | `src/lib/env.ts` | `ANTHROPIC_*`, `OPENAI_MODEL_*`, `OPENAI_EMBEDDING_MODEL`, `MAX_*_AI_COST_USD` 제거. `OPENAI_API_KEY`는 선택값, `OPENAI_REPLY_MODEL` 추가 |
| 기타 | `package.json` | `worker:consultation` 스크립트 삭제 (의존성/lockfile 변경 없음) |
| 테스트 | processor/rule-classifier 테스트 교체, AI 테스트 2개 삭제 | 신규 테스트 통과. 남은 실패 11건은 변경 전부터 있던 것(mailcarrier, i18n, url-parsers, auto-send-gate, header-parser) |

- **DB 변경 없음.** 기존 `ai.drafts` 행은 그대로 남음(새로 생성되지 않음).
- `scripts/load-industry-db.ts`(수동 1회성, OpenAI 임베딩)는 배포/자동 실행 대상이 아니라 건드리지 않음.
- `next.config.mjs`의 `@anthropic-ai/sdk`, package.json 의존성은 lockfile 보호를 위해 남김(코드에서 미사용).

## 3. 적용

### 0) 즉시 중단 (push 전, 선택)
현재 배포본(be2b2dc)은 아직 수신 메일마다 자동 초안을 만든다. Railway **worker** 변수 `MAX_DAILY_AI_COST_USD=0` → API 호출 전에 차단. 배포 후 변수 삭제.

### 1) 로컬 브랜치를 GitHub와 맞추기 (v1 패치가 섞인 경우 필수)
v1 패치는 `Del` 함수 이름이 PowerShell 내장 별칭(del = Remove-Item)과 겹쳐 중간에 멈췄고, 해당 PC의 로컬 브랜치가 GitHub보다 뒤처져 있어 파일 6개가 WARN, push가 거부됨.
```powershell
cd C:\dev\mbg-project
git fetch origin
git branch -f backup-local-20260917 HEAD
Copy-Item tools\run-sql.mjs "$env:TEMP\run-sql.local-backup.mjs" -ErrorAction SilentlyContinue
git reset --hard origin/marinebiogroup
git branch --set-upstream-to=origin/marinebiogroup marinebiogroup
git log --oneline -1
```
`be2b2dc ai: switch text generation ...`가 보이면 OK. 로컬 커밋은 `backup-local-20260917` 브랜치에 보존. 추적 안 되는 sql/docs 파일은 그대로 남음(`tools/run-sql.mjs`만 GitHub 버전으로 교체, 로컬본은 %TEMP%에 백업).

### 2) 패치 (v2)
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\patches\patch_20260917b_ai_reply_only.ps1
```
정상: `[DEL]` 8줄 + `DONE: ai reply only  ok=21 skip=1 warn=0`.

Fallback (.ps1.txt 로 받았거나 -File 이 조용히 끝날 때):
```powershell
$src = Get-ChildItem "$env:USERPROFILE\Downloads" -File | Where-Object { $_.Name -like 'patch_20260917b_ai_reply_only*.ps1*' } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$dst = 'C:\dev\mbg-project\tools\patches\patch_20260917b_ai_reply_only.ps1'
if ($src) { Unblock-File $src.FullName; [System.IO.Directory]::CreateDirectory('C:\dev\mbg-project\tools\patches') | Out-Null; [System.IO.File]::Copy($src.FullName, $dst, $true); Remove-Item -LiteralPath $src.FullName -Force; Write-Host "moved $($src.Name)" } else { Write-Host 'not in Downloads (already moved?)' }
Invoke-Expression ([System.IO.File]::ReadAllText($dst))
```

## 4. 커밋 / 배포
```powershell
cd C:\dev\mbg-project
git status -sb
git add -A -- src package.json tools/patches/patch_20260917b_ai_reply_only.ps1 docs/handoff/2026-09-16/handoff_20260917_ai_reply_only.md
git commit -m "ai: OpenAI only for the AI reply button; remove all automatic AI"
git push origin marinebiogroup
```
- `git add -A -- src`는 삭제된 파일도 함께 올림. commit 전에 `git status -sb`에 의도하지 않은 src 변경이 없는지 확인.
- handoff 경로는 PC 날짜 폴더 기준(`git status -sb`에 보이는 경로로).
- Public 저장소: `docs/handoff` 폴더 통째로 add 금지 (특허 관련 HANDOFF 파일이 추적 안 된 상태로 있음).
- push = Railway 자동 배포(웹 공개).

## 5. 배포 후 (Railway)
- **worker 서비스**: `OPENAI_API_KEY`, `ANTHROPIC_*`, `OPENAI_MODEL_*`, `AI_*_MODE`, `MAX_*_AI_COST_USD` 모두 삭제 가능.
- **web 서비스**: `OPENAI_API_KEY`만 유지(답장 버튼용). `ANTHROPIC_*` 삭제.
- Anthropic Console에서 키 비활성화(다른 사이트가 같은 키를 쓰는지 먼저 확인).
- 확인: `sql/diag_20260916c_ai_model_cost.sql` — 배포 이후 `ai.runs` 새 행이 0이면 정상(답장 버튼 호출은 `ai.runs`에 기록되지 않음). 버튼 사용 비용은 OpenAI 대시보드 Usage에서 확인.
- worker 로그: `classified (rules, no AI) → category=...`

## 6. 교훈
- PowerShell 패치 함수 이름에 내장 별칭(del, rm, cp, mv, ls, cat, echo, set, sort, ...)을 쓰지 말 것. 별칭이 함수보다 우선.
- 패치 전 `git log --oneline -1`로 로컬이 GitHub 최신인지 확인(PC가 두 대).

## 7. SaaS 표준 (유지)
RLS org-scoping, 엔티티 테이블 `created_by uuid default auth.uid()` + `created_at/updated_at`, `app.users.id = auth.uid()`.
join/link, history, lookup, log, 1:1 상세 테이블에는 `created_by` 없음. 이번 작업은 코드/환경변수만 — 스키마 변경 없음.
