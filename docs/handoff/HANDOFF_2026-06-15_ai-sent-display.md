# URM CRM 핸드오프 - 2026-06-15: AI 발송 메일 표시 (2/2 읽기)

대상: YunYoung / mbg-project. 브랜치 marinebiogroup.

> (1/2 저장)에서 app.communications.ai_generated plumbing 완료·검증됨
>   (AI Draft 탭 발송 'RE: Comments on the 4-Way NDA Draft' 행이 ai_generated=true 확인).
> 이 단계(2/2)는 그 값을 화면에 표시.

## 결정 (확정)
- 새 테이블 없이 app.communications.ai_generated 재사용.
- 'AI Drafts'(인바운드 자동초안 큐, ai.drafts 기반) -> 화면 라벨/카운트를 'AI Sent'로 의미 변경.
  인바운드 자동초안 큐 자체는 /drafts에 그대로 보존(enum 수정으로 신규 인바운드부터 동작).

## 이번 수정 (표시, 2파일 11편집)
- `src/app/(app)/page.tsx` (대시보드 Inbox 카드):
  - 독립 쿼리 aiSent = communications(direction='outbound', ai_generated=true, deleted_at null) head count.
  - 카드 줄 'AI Drafts {draftsPending}/{draftsTotal}' -> 'AI Sent {aiSent}', 링크 /inbox?direction=outbound&ai=1.
- `src/components/layout/sidebar.tsx`:
  - SidebarCounts에 aiSent 추가, 초기값 0, 독립 aiSent 쿼리(comm() 헬퍼, positional Promise.all 미변경), setCounts에 추가.
  - InboxSubItem countKey 유니온 'drafts' -> 'aiSent', subPairs 키/값 동기화.
  - 서브항목 'AI Drafts'(/inbox?hasDraft=1) -> 'AI Sent'(/inbox?direction=outbound&ai=1), 단일 숫자 렌더 분기.
  - Out Bound match에 !sp.get('ai') 추가(활성표시 충돌 방지).
- 패처: `patch-ai-sent-display.ps1` (원자적: 11앵커 count==1 전부 충족 시에만 기록, 멱등, LF/UTF-8 no BOM).
- tsconfig는 strict만(noUnusedLocals 없음) -> 남는 draftsPending/draftsTotal 계산은 tsc 무해.

## 검증
1. 패처 적용 -> npx tsc --noEmit 0 errors -> commit/push.
2. AI Draft 탭으로 한 건 발송(또는 이미 1건 true 있음) -> 대시보드 카드 'AI Sent 1', 사이드바 'AI Sent 1' 표시.
   (페이지 이동 시 [pathname]로 사이드바 갱신.)

## 선택 후속
- /inbox 의 ai=1 필터는 아직 미구현 -> 'AI Sent' 링크는 현재 전체 outbound를 보여줌. 원하면 inbox 쿼리에
  ai_generated 필터 추가해 클릭 시 AI 발송만 리스트되게 가능.
