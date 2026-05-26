# Phase 22b — 패치 적용 가이드

## 적용 순서

### Step 1 — SQL 마이그레이션 (Supabase Dashboard > SQL Editor)
```
patch3a-email-signature.sql    ← email_signatures 테이블 생성
patch4-attachments.ts 내 SQL   ← storage bucket + RLS 정책
```

### Step 2 — 신규 파일 생성
```
src/lib/queries/email-signatures.ts        (patch3b 섹션 A)
src/lib/actions/upload-attachment.ts       (patch4 섹션 B)
src/components/email/attachment-uploader.tsx (patch4 섹션 C)
src/app/(app)/settings/email-signature/page.tsx (patch3b 섹션 B)
src/components/settings/email-signature-client.tsx (patch3b 섹션 C)
src/app/(app)/inbox/[id]/page.tsx          (patch2 섹션 2)
```

### Step 3 — 기존 파일 수정
```
src/lib/actions/email-compose.ts
  - sendEmail params에 contactId, attachments 추가
  - renderWithContext에 contactId 전달
  - 서명 자동 첨부 (getDefaultSignature)
  - nodemailer attachments 처리

src/components/email/compose-email-dialog.tsx
  - contactId prop 추가
  - attachments state 추가
  - AttachmentUploader 컴포넌트 삽입

src/components/parties/party-communications-timeline.tsx
  - onCompose 콜백 prop 추가

src/app/(app)/[module]/parties/[id]/page.tsx
  - composeContactId state 추가
  - onCompose 콜백으로 contactId 전달

src/lib/queries/communications.ts
  - fetchCommunicationDetail 함수 확인/수정
```

### Step 4 — Settings 네비게이션에 "이메일 서명" 메뉴 추가

---

## 문제별 핵심 수정 포인트 요약

| # | 문제 | 핵심 수정 |
|---|------|-----------|
| 1 | `{{contact.given_name}}` 미치환 | party page → dialog → server action까지 `contactId` prop 체인 |
| 2 | Inbox 상세 "Message not found" | `/inbox/[id]/page.tsx` 생성 + `fetchCommunicationDetail` 연결 |
| 3 | 서명 기능 | `email_signatures` 테이블 + Settings UI + compose 자동 첨부 |
| 4 | 첨부파일 | Storage bucket + `AttachmentUploader` + nodemailer attachments |

---

## Patch 1 디버그 팁
contact_id가 실제로 null인지 확인:
```typescript
// email-compose.ts sendEmail 함수 상단에 일시적으로 추가
console.log('[sendEmail] params.contactId:', params.contactId);
```
→ 서버 터미널에서 null이면 party page의 onCompose 콜백 체인 확인
→ UUID가 찍히면 renderWithContext 내부 supabase 쿼리 확인

## Patch 2 디버그 팁
```typescript
// /inbox/[id]/page.tsx에서
console.log('[InboxDetail] params.id:', params.id);
// → 실제 전달되는 id 값 확인 (UUID vs message-id 헤더)
```

## CSV 데이터 확인 결과
- Contact: Jane / ceo@marinepad.com / id: d6dd44e7-e1bc-4fc1-9041-129ae936d358
- Communications: 3건 모두 contact_id 정상 저장됨
  → DB 저장은 올바름, UI → action 전달 경로 문제 확실
