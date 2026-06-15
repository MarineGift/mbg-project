# URM CRM 핸드오프 - 2026-06-15: 'AI sent' 배지가 모든 AI 발송 행에 뜨도록 (thread OR-집계)

대상: YunYoung / mbg-project. 브랜치 marinebiogroup.

## 증상
- Sent 화면에서 AI로 보낸 건이 2건인데 한 행(Omya)만 초록 'AI sent' 배지가 보이고 다른 행엔 안 보임.

## 원인
- 배지(`src/components/inbox/inbox-table.tsx:285`, 조건 `row.aiGenerated && direction==='outbound'`)는 이미 구현됨.
- 리스트는 thread별로 그룹화하고 대표(최신) 메시지에서만 aiGenerated를 가져옴(`src/lib/queries/inbox.ts`).
- 스레드에 AI 발송이 있어도 그 스레드의 최신 메시지가 AI가 아니면 대표 행 aiGenerated=false -> 배지 누락.
  (hasDraft는 이미 anyHasDraft로 OR-집계하지만 aiGenerated는 안 하고 있었음.)

## 수정 (1파일 4편집, queries/inbox.ts)
- threadMap 값 타입에 anyAiGenerated 추가.
- 루프: `if (row.aiGenerated) existing.anyAiGenerated = true;` (anyHasDraft와 동일 패턴).
- 신규 스레드 init: anyAiGenerated: row.aiGenerated.
- rows 매핑: anyAiGenerated 구조분해 + `aiGenerated: anyAiGenerated`로 대표 행 덮어쓰기.
- 패처: `patch-inbox-ai-badge-thread.ps1` (원자적 4앵커 count==1, 멱등, LF/UTF-8 no BOM).

## 결과
- 스레드에 AI 발송이 하나라도 있으면 대표 행에 'AI sent' 배지 표시.
- ai_generated는 발송(outbound)에만 찍히므로 의미상 안전.

## 검증
- 패처 적용 -> npx tsc --noEmit 0 errors -> commit/push.
- Sent 화면에서 AI 발송 2건이 모두 'AI sent' 배지로 표시되는지 확인.

## 참고 (지금까지의 AI Sent 작업 전체)
- 저장: communications.ai_generated (AI Draft 탭 발송 시 true) — commit b136483 이전 단계.
- 표시: 대시보드 카드 + 사이드바 'AI Sent' 카운트(outbound ai_generated=true).
- 필터: /inbox?ai=1 -> AI 발송만 리스트 (commit e92e86b).
- 배지: 이번 수정으로 Sent 행 배지가 thread 전체 기준으로 일관되게 표시.
- 선택 후속: Inbox 상단 탭(InboxTabs: Inbound/Outbound/AI Drafts)에 'AI Sent' 탭 추가(미구현).
