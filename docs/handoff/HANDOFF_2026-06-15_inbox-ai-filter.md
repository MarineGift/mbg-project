# URM CRM 핸드오프 - 2026-06-15: 'AI Sent' 클릭 시 AI 발송만 리스트 (inbox ai 필터)

대상: YunYoung / mbg-project. 브랜치 marinebiogroup.

> 'AI Sent' 카운트(대시보드+사이드바)는 이미 동작(communications.ai_generated). 이번엔 그 링크
>   (/inbox?direction=outbound&ai=1)를 누르면 실제로 AI 발송만 목록에 나오게 inbox 필터 구현.

## 이번 수정 (2파일 5편집)
- `src/types/inbox.ts`:
  - InboxFilters에 `aiGenerated: boolean` 추가, DEFAULT_INBOX_FILTERS에 `aiGenerated: false`.
    (DEFAULT_SENT_FILTERS는 spread라 자동 상속.)
- `src/lib/queries/inbox.ts`:
  - parseInboxFilters: `const aiGenerated = single(params.ai) === '1';` + 반환 객체에 추가.
  - fetchInbox: direction 필터 다음에 `if (filters.aiGenerated) query = query.eq('ai_generated', true);`.
    (communications는 from(... as never)라 캐스팅 불필요, select에 ai_generated 이미 포함.)
- 패처: `patch-inbox-ai-filter.ps1` (원자적: 5앵커 count==1 전부 충족 시에만 기록, 멱등, LF/UTF-8 no BOM).

## 동작
- /inbox?direction=outbound&ai=1 -> outbound + ai_generated=true 만 리스트.
- 'AI Sent' 링크(대시보드 카드 / 사이드바 서브항목)가 이 URL을 가리키므로 클릭 시 AI 발송만 보임.
- ai 파라미터 없으면 기존과 동일(전체).

## 검증
1. 패처 적용 -> npx tsc --noEmit 0 errors -> commit/push.
2. 'AI Sent' 클릭 -> 목록에 ai_generated=true 발송(현재 2건)만 표시되는지 확인.

## 남은 선택 후속
- 인박스 상단 탭(InboxTabs)에는 아직 'AI Sent' 탭이 없음(Inbound/Outbound/AI Drafts). 원하면 탭도 추가 가능.
- 인바운드 자동초안 큐(/drafts)는 enum 수정 후 신규 인바운드부터 동작 -> MailCarrier 워커 재시작 확인 권장.
