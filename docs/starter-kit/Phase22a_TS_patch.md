# Phase 22a — TS 파일 두 곳 한 줄씩 수정

## 1. `src/lib/utils/sequence-processor.ts` (Phase 22a sequence-processor v7)

찾기: `ai_processing_status: "idle",`

바꾸기: `ai_processing_status: "skipped",`

위치: communications insert 객체 안 (약 100번째 줄 부근). outbound 시퀀스 발송이므로 AI 분류 필요 없음 → `'skipped'`.

## 2. `src/lib/actions/email-compose.ts` (Phase 22a actions)

이 파일에서 `classifyInboundEmail` 함수 안에:

찾기:
```typescript
ai_processing_status: "complete",
```

바꾸기:
```typescript
ai_processing_status: "completed",
```

또한 `/api/communications/classify/route.ts`의 batch 처리 시 `'processing'` 마킹 부분은 이미 정확함 (`'processing'`은 허용 값).

---

## PowerShell 한 줄 자동 수정

```powershell
cd C:\dev\mbg-project

# sequence-processor.ts: idle → skipped
(Get-Content src\lib\utils\sequence-processor.ts) `
  -replace 'ai_processing_status: "idle"', 'ai_processing_status: "skipped"' `
| Set-Content src\lib\utils\sequence-processor.ts

# email-compose.ts: complete → completed (in classifyInboundEmail's final update)
(Get-Content src\lib\actions\email-compose.ts) `
  -replace 'ai_processing_status: "complete"', 'ai_processing_status: "completed"' `
| Set-Content src\lib\actions\email-compose.ts

Write-Host "✓ Patched both files" -ForegroundColor Green
```

수정 후 Next.js가 자동 재컴파일.
