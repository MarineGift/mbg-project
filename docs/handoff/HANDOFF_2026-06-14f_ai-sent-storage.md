# URM CRM 핸드오프 - 2026-06-14: AI 발송 메일 추적 (1/2 저장)

대상: YunYoung / mbg-project. 브랜치 marinebiogroup.

> 결정: "AI로 보낸 메일"을 새 테이블 없이 **app.communications.ai_generated** 재사용으로 추적.
> 사이드바 'AI Drafts'는 'AI Sent'(보낸 AI 메일 수)로 의미 변경 예정. 인바운드 자동초안 큐는 /drafts에 보존.
> 2단계로 진행: (1) 저장 plumbing [이번], (2) 사이드바 'AI Sent' 표시 [다음].

## 왜 새 테이블이 아닌가
- ai.drafts는 '인바운드 자동 답장 초안 큐'라는 다른 용도(enum 버그는 이미 수정).
- app.communications에 ai_generated/ai_draft_id 컬럼이 이미 있고, send-outbound.ts가
  `ai_generated: input.aiGenerated ?? false`로 이미 기록함(코어 무수정).
- 새 테이블은 메일 이중저장 -> 동기화 문제. 단일 소스(communications)가 정답.

## 이번 수정 (저장 plumbing, 3파일 6편집, 전부 additive/optional -> tsc-safe)
- `src/lib/actions/email-compose.ts`: ComposePayload에 `aiGenerated?: boolean` 추가 +
  sendOutboundEmail 호출에 `aiGenerated: payload.aiGenerated ?? false` 전달.
- `src/lib/actions/communications.ts`: composeSchema(zod)에 `aiGenerated: z.boolean().optional()` 추가 +
  sendOutboundEmail 호출에 `aiGenerated: parsed.data.aiGenerated ?? false` 전달.
- `src/components/email/compose-email-dialog.tsx`: 두 발송 경로(party 연결=sendEmail, 미연결=sendOutboundManual)에
  `aiGenerated: activeTab === "ai"` 전달. (컴포즈 'AI Draft' 탭에서 보낼 때만 true.)
- 패처: `patch-ai-sent-storage.ps1` (원자적: 6앵커 count==1 전부 충족 시에만 기록, 멱등, LF/UTF-8 no BOM).

## 검증
1. 패처 적용 -> `npx tsc --noEmit` 0 errors -> commit/push.
2. 컴포즈 다이얼로그 'AI Draft' 탭에서 답장 생성 후 발송.
3. Supabase:
   select created_at, ai_generated, ai_draft_id, subject
   from app.communications where direction='outbound' order by created_at desc limit 5;
   -> 방금 보낸 AI 발송 행이 ai_generated=true 면 저장 OK.
   (직접 탭/수동 발송은 ai_generated=false 유지.)

## 다음 (표시, 2/2)
- 사이드바 'AI Drafts' 서브항목 -> 'AI Sent'로 라벨/링크 변경 + 카운트 = outbound ai_generated=true.
- 주의: 사이드바 카운트가 positional Promise.all 안에 있어, 새 카운트 쿼리는 배열 '끝'에 append + 끝 변수로 구조분해(안전 위치).
  type SidebarCounts에 aiSent 추가, 초기값 0, setCounts에 aiSent 추가, INBOX_SUBITEMS의 'AI Drafts' 항목 수정.
