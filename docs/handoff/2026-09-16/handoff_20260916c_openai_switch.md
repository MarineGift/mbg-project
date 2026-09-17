\xef\xbb\xbf# handoff_20260916c_openai_switch — AI 텍스트 생성: Anthropic API → OpenAI API

> 저장소가 Public이므로 이 문서에는 키/비밀번호를 적지 않는다.

## 1. 왜
- 직접 쓰지 않아도 Anthropic 비용이 계속 나옴. 원인은 **mailcarrier 워커가 수신 메일마다 자동으로 AI를 호출**하기 때문
  (`processInbound` → classifier(haiku 등급) + drafter(opus 등급) 2회). 9/16 장애 복구 중 밀린 메일 처리로 일일 예산($50)까지 소진.
- 기존 단가표 기준 opus 등급은 $15/$75 (1M 토큰). 이번 변경으로 기본 매핑은 gpt-5-mini $0.25/$2, gpt-5-nano $0.05/$0.40.

## 2. 변경 내용 (커밋 17ecb34 기준)
| 파일 | 변경 |
|---|---|
| `src/lib/ai/openai-chat.ts` (신규) | OpenAI Chat Completions 공용 헬퍼. 등급→모델 매핑, reasoning 모델(gpt-5*, o*)용 파라미터(temperature 제거, `max_completion_tokens`, `reasoning_effort`) |
| `src/lib/ai/claude-client.ts` | Anthropic SDK → OpenAI SDK. 클래스/에러 이름(`ClaudeClient`, `ClaudeApiError` 등)은 **그대로** 유지 → 호출부(processor, consultation-worker, decompose-actions) 수정 없음. `ai.runs.model_used`에 실제 OpenAI 모델명 기록 |
| `src/lib/ai/cost-tracker.ts` | OpenAI 단가 추가. 표에 없는 모델은 0원이 아니라 보수적 단가($5/$30)로 계산(예산 보호) |
| `src/lib/ai/prompt-renderer.ts` | Anthropic 타입 제거 (중립 `ChatMessage`) |
| `src/lib/actions/email-compose.ts` | 답장 초안 / 새 메일 작성(AI) → OpenAI |
| `src/lib/env.ts` | `ANTHROPIC_*` 선택값으로 변경. `OPENAI_MODEL_OPUS/SONNET/HAIKU` 추가 |
| `src/types/ai.ts` | 출력에 `providerModel` 추가 |
| 테스트 / 주석 | `claude-client.test.ts` OpenAI 형태로 교체(10/10 통과), env-setup, 주석 2곳 |

- **DB 변경 없음.** `ai.agents.model`의 `claude-*` 값은 이제 "등급"으로만 쓰이고 코드에서 OpenAI 모델로 바뀜.
- `@anthropic-ai/sdk` 패키지는 package.json에 남겨둠(lockfile 변경 방지, 코드에서는 미사용).
- 검증: tsc — 수정 파일 오류 0 (기존 schedule/parties/relay 오류는 그대로). `processor.test.ts` 6건 실패는 변경 전부터 동일.

### 등급 → 모델 (Railway 변수로 변경 가능, 코드 수정 불필요)
| ai.agents.model | Railway 변수 | 기본값 |
|---|---|---|
| claude-opus-4-7 (초안 작성) | `OPENAI_MODEL_OPUS` | gpt-5-mini |
| claude-sonnet-4-6 (작성/답장 버튼) | `OPENAI_MODEL_SONNET` | gpt-5-mini |
| claude-haiku-4-5-20251001 (분류) | `OPENAI_MODEL_HAIKU` | gpt-5-nano |

초안 품질이 부족하면 `OPENAI_MODEL_OPUS=gpt-5` 로 올리면 됨.

## 3. 적용
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\patches\patch_20260916_openai_llm.ps1
```
마지막 줄 `DONE: openai switch  ok=11 skip=0 warn=0` 확인. 다시 실행하면 `skip=11`.
`[WARN]`이 나오면 해당 파일은 로컬에서 수정된 상태라 건드리지 않음 → `git status -sb` 결과 공유.

### Fallback (patch 파일이 Downloads에 .ps1.txt 로 받아졌거나 -File 이 조용히 끝날 때)
```powershell
$src = Get-ChildItem "$env:USERPROFILE\Downloads" -File | Where-Object { $_.Name -like 'patch_20260916_openai_llm*.ps1*' } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$dst = 'C:\dev\mbg-project\tools\patches\patch_20260916_openai_llm.ps1'
if ($src) { Unblock-File $src.FullName; [System.IO.Directory]::CreateDirectory('C:\dev\mbg-project\tools\patches') | Out-Null; [System.IO.File]::Copy($src.FullName, $dst, $true); Remove-Item -LiteralPath $src.FullName -Force; Write-Host "moved $($src.Name)" } else { Write-Host 'not in Downloads (already moved?)' }
Invoke-Expression ([System.IO.File]::ReadAllText($dst))
```

## 4. 커밋 / 배포
```powershell
cd C:\dev\mbg-project
git status -sb
git add src/lib/ai/openai-chat.ts src/lib/ai/claude-client.ts src/lib/ai/cost-tracker.ts src/lib/ai/prompt-renderer.ts src/lib/env.ts src/lib/actions/email-compose.ts src/types/ai.ts src/scripts/simulate-inbound.ts src/workers/mailcarrier-worker.ts src/__tests__/ai/claude-client.test.ts src/__tests__/setup/env-setup.ts tools/patches/patch_20260916_openai_llm.ps1 sql/diag_20260916c_ai_model_cost.sql docs/handoff/2026-09-16/handoff_20260916c_openai_switch.md
git commit -m "ai: switch text generation from Anthropic to OpenAI (cost)"
git push origin marinebiogroup
```
push = Railway 자동 배포(웹 공개). web + worker 두 서비스 모두 재배포되는지 확인.

## 5. Railway / Anthropic 정리 (배포 확인 후)
1. `OPENAI_API_KEY`는 임베딩용으로 이미 web·worker에 있어야 함 → 두 서비스 모두 있는지 확인.
2. 배포 후 인박스에서 "AI 답장 초안" 한 번 실행 → 정상이면
3. web·worker 양쪽에서 `ANTHROPIC_API_KEY`, `ANTHROPIC_MODEL_*` 삭제.
4. Anthropic Console에서 해당 키 비활성화(다른 프로젝트가 같은 키를 쓰는지 Usage에서 먼저 확인). 이렇게 하면 Anthropic 과금은 0이 보장됨.
5. (권장) `MAX_DAILY_AI_COST_USD`를 50 → 5 정도로 낮추기. 수신 메일 자동 처리 비용의 안전장치.

## 6. 확인
- Supabase SQL Editor: `sql/diag_20260916c_ai_model_cost.sql` → Ctrl+A → Run.
  배포 이후 행의 `model_used`가 gpt-5-mini / gpt-5-nano 여야 함.

## 7. SaaS 표준 (유지)
RLS org-scoping, 엔티티 테이블 `created_by uuid default auth.uid()` + `created_at/updated_at`, `app.users.id = auth.uid()`.
join/link, history, lookup, log, 1:1 상세 테이블에는 `created_by` 없음. 이번 작업은 코드/환경변수만 — 스키마 변경 없음.
