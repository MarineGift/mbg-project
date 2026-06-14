# URM CRM 작업 핸드오프 (추가) - 2026-06-14 오후

대상: YunYoung / mbg-project (Next.js 14.2 + Supabase `app` schema)
레포: MarineGift/mbg-project, 브랜치 `marinebiogroup` (push = urm.marinebiogroup.com 자동 배포)

> 이 섹션은 같은 날 오후 추가 세션의 기록이다. 아래 오전 핸드오프 내용은 그대로 보존.

---

## 운영 메모 (중요) - 레포가 PUBLIC 이다

- `MarineGift/mbg-project`는 **public 저장소**다. 다음 세션부터는 파일을 복사/업로드시키지 말고 **raw.githubusercontent.com에서 직접 읽어라.**
  - 형식: `https://raw.githubusercontent.com/MarineGift/mbg-project/marinebiogroup/<경로>`
  - 라우트 그룹 괄호는 URL 인코딩: `(app)` -> `%28app%29` (또는 curl에서는 따옴표로 감싸 그대로 사용).
  - 예) `curl -fsSL "https://raw.githubusercontent.com/MarineGift/mbg-project/marinebiogroup/src/lib/actions/drafts.ts"`
- 이렇게 하면 디스커버리/대조 작업에서 사용자가 파일을 일일이 떠 줄 필요가 없다.

---

## 이번(오후) 세션에서 완료한 것

### 5. AI Draft 발송 시 Dashboard 카운트 미갱신 버그 - 원인 규명 + 패처 제작

- **증상:** AI Draft로 메일을 보냈는데 Dashboard(`/`)의 Inbox 카드 Outbound 수 / AI Drafts pending 수가 갱신되지 않음. compose(수동 작성)로 보내면 정상 반영됨.
- **점검:** Supabase에서 `app.communications` 덤프 -> 발송된 AI Draft 행은 정상이었음
  (`direction='outbound'`, `status='sent'`, `sent_at` 채워짐, `organization_id` 정확). 즉 데이터/발송 행 문제 아님.
  - 참고: 점검 쿼리는 컬럼명이 `organization_id`다(`org_id` 아님 -> 42703 에러 났던 것).
- **근본 원인 (Next.js 캐시 무효화 누락):**
  - compose/수동 경로 `src/lib/actions/communications.ts` (약 238-240행)는 발송 후
    `revalidatePath('/inbox')` + `revalidatePath('/', 'layout')`로 대시보드까지 갱신한다.
  - 그러나 AI Draft 경로 `src/lib/actions/drafts.ts`의 `approveDraft` / `sendApprovedDraft` 및
    `rejectDraft` / `bulkApproveDrafts` / `bulkRejectDrafts`는 `revalidatePath('/drafts')`(+ 상세)만 호출하고
    `/`(대시보드)와 `/inbox`는 무효화하지 않았다.
  - 결과: AI Draft 발송 후 outbound 행은 쌓이고 드래프트도 `status='sent'`로 바뀌지만,
    대시보드 라우트 캐시가 무효화되지 않아 카운트가 stale.
- **수정 방침:** drafts.ts의 5개 변이 액션 각 return 경로에 `revalidatePath('/', 'layout')` 한 줄씩 추가
  (compose 경로와 동일 컨벤션). `'/', 'layout'` 하나로 `/`·`/inbox`·`/drafts` 동시 갱신.
  - 적용 위치: `approveDraft`(approve-only [B], sent [C] 양쪽), `rejectDraft`, `bulkApproveDrafts`, `bulkRejectDrafts`.
- **산출물:** `patch-draft-dashboard-revalidate.ps1`
  - ASCII PowerShell. 앵커 count==1 가드(5개), 멱등 마커 체크(`revalidatePath('/', 'layout')` 이미 있으면 SKIP),
    불일치 시 무변경 abort, LF + UTF-8(no BOM) 기록. 대상은 in-place `C:\dev\mbg-project\src\lib\actions\drafts.ts`.
  - 적용 후 `npx tsc --noEmit` 0 errors 확인 -> commit -> `git push origin marinebiogroup`.

### 참고: compose 경로의 부분 한계 (선택 후속)

- `communications.ts`의 `revalidatePath('/', 'layout')`는 **`if (parsed.data.partyId)` 조건부**다.
  즉 partyId 없이 수동 발송하면 대시보드 갱신이 안 될 수 있다. 필요 시 이 조건을 제거(무조건 호출)하면
  수동 경로도 항상 대시보드 갱신. (이번 버그의 핵심은 AI Draft 경로라 우선순위 낮음.)

---

## 다음 세션 후보 (오후 추가분)

- [ ] 위 패처 적용 + tsc 0 + push 후, AI Draft 한 건 발송 -> 대시보드 Outbound/AI Drafts 수 즉시 증가/감소 확인.
- [ ] (선택) compose 경로 `revalidatePath('/', 'layout')`의 partyId 조건 제거 검토.
- [ ] 오전 핸드오프의 enrich SQL batch12~22 Supabase 실행 + 점검(미완 시).

---
---

> [!] 아래는 오전 핸드오프 원본 (그대로 보존)

# URM CRM 작업 핸드오프 - 2026-06-14

대상: YunYoung / mbg-project (Next.js 14.2 + Supabase `app` schema)
레포: MarineGift/mbg-project, 브랜치 `marinebiogroup` (push = urm.marinebiogroup.com 자동 배포)
ORG: `b25de8f2-1020-482f-9012-183f63883169`
머신: 홈 Samsung(SS_LAPTOP-HEO) / Lenovo, 둘 다 `C:\dev\mbg-project`

---

## 이번 세션에서 완료한 것 (3건)

### 1. 투자사 공개 연락처 enrich (Q3) - 완료
- 등록 투자사 125곳 전수 점검(AM 49 / DeepTech 22 / LifeSci 54).
- 채택 기준(하이브리드): 자사 일반 inbox(info@/contact@/ir@) 또는 2출처 이상 교차검증된 대표번호만.
- source 태그: 자사확인 `investor_enrich_2026Q3`, 디렉터리출처 `investor_enrich_2026Q3_dir`.
- 신규 적중: DeepTech 2 (Intel Capital, Sutter Hill), AM 6 (Toyota/Chevron/Playground/Emergent/Unilever/Mitsui). LifeSci 100% 반영.
- 순수 모회사 프로그램 6곳 no-public 확정(폼/신청포털만): 3M Ventures, Amazon Climate Pledge Fund, Coca-Cola Ventures, Microsoft Climate Innovation Fund, PepsiCo Greenhouse Accelerator, Walmart Strategic Capital.
- 실행 SQL: LifeSci batch12~batch19(+batch17), DeepTech batch20, AM batch21/batch22. batch22(Unilever/Mitsui) party_name 정확일치 join 주의.

### 2. AI Draft/평문 메일 발송 시 줄바꿈 소실 버그 - 수정/배포 완료 (commit a39fca1)
- 원인: `send-outbound.ts`가 평문 본문을 HTML로 취급 -> `\n`이 공백으로 렌더.
- 수정: 코어에 `[2a]` 추가 - 본문이 비어있지 않고 HTML 태그 없으면 `plainToHtml()` 적용. 단일 코어 수정으로 3경로 동시 해결.
- 잔여(미수정, 영향 적음): text/plain 대체 파트는 여전히 공백 합쳐짐(대부분 클라이언트는 HTML 파트 렌더).

### 3. 회신 범위 선택(Sender only / Reply all) - 수정/검증/배포 완료
- Reply 다이얼로그 "Reply to" 토글 추가. 기본값 Reply all.
- 신규 서버 액션 `src/lib/actions/reply-recipients.ts`가 org 범위로 수신자 읽어옴(자기완결).

### 4. 소스 파일 인코딩 클린업 - 수정/배포 완료 (commit ac66331)
- 한글 주석 깨진 사례 0건. `database.ts`는 UTF-16LE 저장이라 UTF-8 재인코딩. 장식 구분선만 깨진 3파일 ASCII 정리.
- 재발 방지: `database.ts`는 Supabase 타입 생성기 출력 -> 재생성 시 UTF-8 확인.

---

## 패치/배포 컨벤션 (유지)
- 패처: ASCII PowerShell, 앵커 count==1 가드, 불일치 시 무변경 abort, 멱등 마커 체크, LF/UTF-8(no BOM) 기록.
- 기존 파일(비-ASCII 장식 주석 포함)은 전체 재작성 금지 -> 순수 ASCII 라인만 앵커로 surgical 삽입.
- PowerShell 콘솔 출력 ASCII 전용(PS 5.x CP949). Korean은 .md(UTF-8 BOM)만.
- 다운로드 경로 `$env:USERPROFILE\Downloads`, `.ps1`은 zone-block -> `powershell -ExecutionPolicy Bypass -File`.
- 커밋 전 항상 `npx tsc --noEmit` 단독 실행 -> 0 errors 확인. 그다음 `git status -sb`, 커밋, `git push origin marinebiogroup`.

---

## 다음 세션 계획 (오전 작성분)
1. Cc 자기 주소 중복 처리 (결정 필요)
2. 메일 text/plain 대체 파트 줄바꿈 보존(선택)
3. inbound Cc 저장 여부 점검
4. enrich SQL 미실행분 반영 + 검증
5. (선택) UTF-8 BOM 9개 파일 정리
