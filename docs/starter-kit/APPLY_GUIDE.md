# Phase 22b 패치 적용 가이드
## 적용 순서 & 체크리스트

---

## STEP 1: Supabase SQL 실행 (Dashboard → SQL Editor)

### 1-1. 스키마 패치
파일: `patch-22b-1-schema.sql`
- `app.email_signatures` 테이블 생성
- `app.communications.attachment_paths` 컬럼 추가
- RLS 정책 설정

### 1-2. Storage 버킷 설정
- Supabase Dashboard → Storage → New Bucket
  - 버킷명: `email-attachments`
  - Public: **OFF** (비공개)
  - File size limit: 10MB
- 그 다음 `patch-22b-9-storage-bucket.sql` 실행 (RLS 정책)

---

## STEP 2: 파일 교체/추가

### 2-1. email-compose.ts (전체 교체)
```
src/lib/actions/email-compose.ts
← patch-22b-2-email-compose.ts
```
- ✅ `renderWithContext`: contact_id null 시 primary contact 자동 조회
- ✅ 서명 자동 첨부 (`getDefaultSignature`)
- ✅ 첨부파일 처리 (`resolveAttachments`)
- ✅ 서명 CRUD server actions 추가

### 2-2. compose-email-dialog.tsx (전체 교체)
```
src/components/email/compose-email-dialog.tsx
← patch-22b-3-compose-email-dialog.tsx
```
- ✅ `contactId?: string | null` prop 추가
- ✅ 파일 첨부 UI (Paperclip 버튼 + 목록)
- ✅ Supabase Storage 업로드 인라인 처리
- ✅ 서명 토글 Switch

### 2-3. party page 수정 (수동)
파일: `patch-22b-4-party-page-fix.ts` 참고

**핵심 수정 2곳:**

**(A) 서버 컴포넌트에서 primary contact 조회 추가:**
```typescript
const { data: primaryContact } = await supabase
  .from("party_contacts")
  .select("contact_id")
  .eq("party_id", params.id)
  .eq("is_primary", true)
  .maybeSingle()

const primaryContactId = primaryContact?.contact_id ?? null
```

**(B) ComposeEmailDialog에 contactId prop 전달:**
```tsx
<ComposeEmailDialog
  ...
  contactId={primaryContactId}   {/* ← 이 줄 추가 */}
  ...
/>
```

### 2-4. Inbox 상세 페이지 (전체 교체 or 신규 생성)
```
src/app/(app)/inbox/[id]/page.tsx
← patch-22b-5-inbox-detail-page.tsx
```
- ✅ `fetchCommunicationDetail` 실제 호출
- ✅ 에러 처리 (다시 시도 버튼)
- ✅ 첨부파일 목록 표시
- ✅ 인라인 답장 Dialog

### 2-5. communications.ts 함수 추가
파일: `patch-22b-6-communications-detail.ts` 참고

`src/lib/actions/communications-actions.ts` 파일 신규 생성:
```typescript
"use server"
import { createServerActionClient } from "@supabase/auth-helpers-nextjs"
import { cookies } from "next/headers"

export async function fetchCommunicationDetailAction(id: string) {
  const supabase = createServerActionClient({ cookies })
  const { data, error } = await supabase
    .from("communications")
    .select(`*, party:parties(id, name), contact:contacts(id, given_name, family_name, email)`)
    .eq("id", id)
    .single()
  if (error) return null
  return data
}
```

inbox/[id]/page.tsx에서 import 경로 수정:
```typescript
import { fetchCommunicationDetailAction } from "@/lib/actions/communications-actions"
// fetchCommunicationDetail → fetchCommunicationDetailAction 로 변경
```

### 2-6. 이메일 서명 설정 페이지 (신규)
```
src/app/(app)/settings/email-signatures/page.tsx
← patch-22b-7-signatures-page.tsx

src/components/settings/email-signatures-client.tsx
← patch-22b-8-signatures-client.tsx
```

### 2-7. Settings 사이드바 메뉴에 서명 항목 추가
기존 `settings/email-whitelist` 링크 옆에:
```tsx
<Link href="/settings/email-signatures">이메일 서명</Link>
```

---

## STEP 3: 환경 변수 확인
`.env.local` 에 아래 설정 확인:
```
SMTP_HOST=...
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=ceo@marinepad.com
SMTP_PASS=...
SMTP_FROM_NAME=Marine Bio Group
ANTHROPIC_API_KEY=...
```

---

## STEP 4: 빌드 확인
```powershell
cd C:\dev\mbg-project
npx tsc --noEmit   # 타입 오류 확인
npm run dev        # 개발 서버 시작
```

---

## 검증 체크리스트

| 항목 | 검증 방법 |
|------|-----------|
| ✅ `{{contact.given_name}}` 치환 | 템플릿 이메일 발송 후 수신 메일 확인 |
| ✅ Inbox 상세 클릭 | `/inbox/[id]` 페이지 정상 렌더 |
| ✅ 서명 등록 | Settings → 이메일 서명 → 저장 후 발송 확인 |
| ✅ 파일 첨부 | Compose Dialog에서 파일 선택 → 진행 표시 → 발송 |
| ✅ Storage 업로드 | Supabase Dashboard → Storage → email-attachments 확인 |

---

## 주의사항

1. **party_contacts 테이블 구조 확인**  
   `is_primary` 컬럼이 없다면:
   ```sql
   ALTER TABLE app.party_contacts ADD COLUMN IF NOT EXISTS is_primary BOOLEAN DEFAULT false;
   ```

2. **첨부파일 크기 제한**  
   현재 ComposeEmailDialog는 클라이언트 측 제한 없음. 필요 시 추가:
   ```typescript
   if (item.file.size > 10 * 1024 * 1024) { toast.error("10MB 초과"); continue; }
   ```

3. **fetchCommunicationDetail import 경로**  
   기존 `communications.ts`가 서버 컴포넌트용이면 `"use server"` 없이도 작동하나,  
   Client Component에서 직접 import 불가 → server action wrapper 필수.
