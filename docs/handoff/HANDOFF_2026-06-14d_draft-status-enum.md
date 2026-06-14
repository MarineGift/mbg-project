# URM CRM 핸드오프 - 2026-06-14 심야: ai.drafts 빈 테이블 진짜 원인(enum 위반) 수정

대상: YunYoung / mbg-project. 레포 MarineGift/mbg-project, 브랜치 marinebiogroup.

> "AI Drafts로 보냈는데 ai.drafts가 0건"의 **근본 원인**을 코드/enum/마이그레이션으로 확정하고 수정.

## 진짜 원인 (확정)
- `ai.drafts.status`는 Postgres ENUM `ai.draft_status` 이고, 허용값은
  **pending_review | approved | sent | rejected | expired | auto_sent** 뿐. **'draft'는 없음.**
- 그런데 `src/lib/email/processor.ts`의 `insertDraft()`가 `status: 'draft'`로 INSERT.
  -> 인바운드 메일마다 INSERT가 **enum 위반으로 매번 실패**.
- MailCarrier 워커는 `processInbound` 에러를 catch+log만 하므로(워커 line ~284):
  인바운드 communications 행은 저장되지만(그래서 CSV에 inbound 존재) **드래프트는 한 건도 안 남음**.
- 결과적으로 `ai.drafts`는 전 org/전 기간 0건 -> AI Drafts 큐/사이드바/대시보드 카운트 0.

## 부수 확인
- ai.drafts 삭제 코드/삭제 트리거 없음(유일 트리거는 edit_distance update). expire 워커도 status='expired' 업데이트.
  => "보내서 사라진" 게 아니라 "생성 자체가 실패"였음.
- 인바운드 행이 존재 = MailCarrier 워커는 이미 작동 중이고 Claude 분류/초안 생성도 수행됨. **마지막 INSERT만** 깨졌던 것.
- 사용자의 발송은 작성창/회신(경로 B) -> app.communications에만 기록(ai_generated=false), ai.drafts 무관.

## 수정 (이번)
- `processor.ts` insertDraft: `status: 'draft'` -> `status: 'pending_review'`.
  (consumers 전부 pending_review 기대: 사이드바/대시보드 `.eq('status','pending_review')`,
   approveDraft 전제조건, draft-queue 기본필터, processor.test.ts 기대값.)
- 패처: `patch-processor-draft-status.ps1` (앵커 count==1, 멱등, 무변경 abort, LF/UTF-8 no BOM).

## 검증 절차
1. 패처 적용 -> `npx tsc --noEmit` 0 errors.
2. (로컬 즉시 증명) `npm run sim:inbound` — `.env.local`에 실제 ANTHROPIC_API_KEY 필요.
   수정 전: 드래프트 INSERT 단계에서 enum 에러. 수정 후: pending_review 드래프트 1건 생성.
   확인: `select status, count(*) from ai.drafts group by status;` -> pending_review 행 등장.
3. commit + push -> Railway 재배포. **MailCarrier 워커 서비스가 패치된 코드로 재시작**되는지 확인(워커는 별도 프로세스).
   이후 들어오는 신규 인바운드부터 pending_review 드래프트 생성 -> /inbox?hasDraft=1 + 사이드바 AI Drafts 카운트 채워짐.

## 주의
- 과거에 실패한 인바운드는 소급 생성 안 됨(이미 에러 로그로 흘러감). **배포 후 신규 수신분**부터 생성.
  (원하면 기존 인바운드에 대해 force로 processInbound 재실행하는 sim 변형으로 백필 가능.)
- 워커가 Railway에서 자동 재배포되지 않는 구성이면 수동 재시작 필요(안 그러면 워커는 옛 코드로 계속 실패).
