# Phase 22a — 설치 가이드

> **이번 패치로 구현되는 것:**
> 1. Per-Party Communications Timeline (게시판 스타일 스레드 뷰)
> 2. 3-Mode Compose Dialog (직접 작성 / 템플릿 / AI)
> 3. AI Reply + AI Compose (Anthropic SDK, 클릭 시에만)
> 4. Outbound 발송 시 message_id/thread_id 자동 채움
> 5. IMAP 회신 자동 매칭 트리거 (in_reply_to → outbound replied_at)
> 6. AI 회신 sentiment 자동 분류 (저비용, 모든 inbound)

---

## 1. SQL 적용 (Supabase Dashboard)

```bash
# Supabase SQL Editor에 phase22a_communications_timeline.sql 붙여넣고 실행
```

검증:
```sql
SELECT proname FROM pg_proc
WHERE proname IN (
  'get_party_communications_timeline',
  'get_contact_communications_timeline',
  'get_thread_context',
  'list_templates_for_compose',
  'save_manual_email',
  'get_communications_stats_per_party',
  'fn_auto_link_inbound_reply'
);
-- 7 rows 나와야 함

SELECT tgname FROM pg_trigger WHERE tgname = 'trg_auto_link_inbound_reply';
-- 1 row 나와야 함
```

---

## 2. 파일 설치

PowerShell:

```powershell
cd C:\dev\mbg-project

# 다운로드한 파일들을 적절한 위치로 복사
Copy-Item phase22a_types.ts                        src\types\phase22a.ts
Copy-Item phase22a_communications_queries.ts       src\lib\queries\communications.ts
Copy-Item phase22a_email_compose_actions.ts        src\lib\actions\email-compose.ts
Copy-Item phase22a_sequence_processor_v7.ts        src\lib\utils\sequence-processor.ts -Force
Copy-Item phase22a_compose_email_dialog.tsx        src\components\email\compose-email-dialog.tsx
Copy-Item phase22a_party_communications_timeline.tsx  src\components\parties\party-communications-timeline.tsx
```

`src\components\email\` 폴더가 없으면 먼저 생성:
```powershell
New-Item -ItemType Directory -Path src\components\email -Force
```

---

## 3. 환경 변수 확인 (.env.local)

```bash
# 기존 (이미 있음)
TABS_MAILER_HOST=...
TABS_MAILER_PORT=587
TABS_MAILER_USERNAME=contact@marinebiogroup.com
TABS_MAILER_PASSWORD=...
NEXT_PUBLIC_APP_URL=https://...
NEXT_PUBLIC_DEFAULT_ORG_ID=b25de8f2-1020-482f-9012-183f63883169

# Phase 22a 새 추가
ANTHROPIC_API_KEY=sk-ant-...
TABS_MAILER_FROM_NAME=URM    # 발신자명 (선택)
```

---

## 4. Anthropic SDK 설치

```powershell
npm install @anthropic-ai/sdk
```

---

## 5. Party 상세 페이지에 통합

`src/app/(app)/[module]/parties/[id]/page.tsx` 수정 (기존 파일에 추가):

```typescript
import {
  getPartyCommunicationsTimeline,
  getPartyCommunicationStats,
  listTemplatesForCompose,
} from "@/lib/queries/communications";
import { PartyCommunicationsTimeline } from "@/components/parties/party-communications-timeline";

// page 함수 안에서:
const orgId = process.env.NEXT_PUBLIC_DEFAULT_ORG_ID!;
const [commTimeline, commStats, templates] = await Promise.all([
  getPartyCommunicationsTimeline(party.id, 100),
  getPartyCommunicationStats(party.id),
  listTemplatesForCompose(orgId, params.module),
]);

// 기본 contact (primary contact)
const defaultContact = contacts?.find((c) => c.is_primary) || contacts?.[0] || null;

// 렌더에 추가:
<PartyCommunicationsTimeline
  partyId={party.id}
  partyName={party.name}
  defaultContactEmail={defaultContact?.email ?? null}
  defaultContactId={defaultContact?.id ?? null}
  defaultContactName={
    defaultContact
      ? `${defaultContact.given_name || ""} ${defaultContact.family_name || ""}`.trim() || null
      : null
  }
  items={commTimeline}
  stats={commStats}
  templates={templates}
  orgId={orgId}
/>
```

---

## 6. IMAP 수신 핸들러에 sentiment 분류 호출 추가

기존 IMAP 수신 핸들러 (`src/app/api/email/ingest/route.ts` 같은 곳)에서, communications 행 insert 후:

```typescript
import { classifyInboundEmail } from "@/lib/actions/email-compose";

// inbound 메일 insert 직후
await classifyInboundEmail(communicationId);
// 이 호출은 비동기로 처리해도 됨 (waitUntil 등)
// AI 분류 결과는 ai_classification 컬럼에 자동 저장됨
// unsubscribe 의도이면 contact.do_not_contact도 자동으로 true 설정됨
```

---

## 7. 테스트 시나리오

### 7-1. 새 메일 발송 (직접 작성)
1. `npm run dev`
2. http://localhost:3000/seller/parties/{marinepad_party_id}
3. "Communications" 패널 확인 (기존 메일 표시)
4. "+ 새 메일 작성" 버튼 클릭
5. 모드: **✏️ 직접 작성**
6. 제목 입력, 본문 입력
7. **발송** 클릭
8. 즉시 communications 행 추가 + 메일 발송
9. 페이지 새로고침하면 타임라인에 새 메시지 표시됨

### 7-2. 템플릿 사용
1. 컴포즈 다이얼로그 → 모드 **📄 템플릿**
2. 드롭다운에서 템플릿 선택
3. subject/body 자동 채워짐 (편집 가능)
4. 발송

### 7-3. AI 작성 (새 메일)
1. 컴포즈 다이얼로그 → 모드 **✨ AI 작성**
2. "AI 작성 지시"에 입력: `marine-derived PCC 신제품 소개, 미팅 제안`
3. 언어: 자동 감지 (또는 ko/en/ja 선택)
4. **AI 초안 생성** 버튼 (Anthropic 호출, 약 2-3초)
5. subject/body 자동 채워짐 + AI reasoning 표시
6. 편집 후 발송

### 7-4. AI 회신
1. 받은 메일 옆 **↳ 회신** 버튼 클릭
2. 컴포즈 다이얼로그 → 모드 **✨ AI 작성**
3. (선택) 톤 한 줄 입력
4. **AI 초안 생성** — 스레드 전체 컨텍스트 + party/contact 정보 자동 전달
5. 회신 초안 자동 생성 (받은 메일 언어 자동 감지)
6. 검토 후 발송

### 7-5. 회신 자동 매칭
1. URM에서 메일 발송 (Message-ID 자동 부여)
2. 수신자가 회신
3. IMAP이 inbound 메일 fetch → communications insert
4. **트리거 자동 동작:**
   - inbound의 in_reply_to == outbound의 message_id 매칭
   - inbound의 thread_id ← outbound의 thread_id (스레드 묶임)
   - outbound의 replied_at ← inbound의 occurred_at
5. Party 페이지의 Communications 패널에 스레드로 묶여 표시됨

### 7-6. AI Sentiment 분류
1. inbound 메일 도착 직후 `classifyInboundEmail` 자동 호출
2. ai_classification jsonb에 저장:
   ```json
   {
     "intent": "interested",
     "confidence": 0.85,
     "summary": "회사 소개 요청, 카탈로그 요청",
     "language": "ko",
     "sentiment": "positive",
     "suggested_action": "회사 소개서 + 가격표 첨부 회신"
   }
   ```
3. UI에 자동으로 배지 표시 (🟢 관심있음, 💡 제안 액션)
4. unsubscribe로 분류되면 contact.do_not_contact = true

---

## 8. 비용 예상 (Anthropic Claude Sonnet 4.5)

- AI 회신 작성: 1건당 ~$0.005 (500 input + 200 output tokens)
- AI 새 메일 작성: 1건당 ~$0.005
- Inbound sentiment 분류: 1건당 ~$0.001

월 1,000건 inbound + 100건 AI 회신 + 50건 AI 새 메일 = 약 $1.75/월

---

## 9. 알려진 한계

1. **첨부 파일 미지원** (Phase 22b에서 추가 예정)
2. **이메일 서명 자동 추가 없음** (Phase 22b에서 추가)
3. **AI 작성 시 첨부물/링크 미포함** (사용자가 직접 추가)
4. **A/B 테스팅 미적용** (Phase 22b에서 시퀀스에 적용)
5. **회신율 분석 대시보드 없음** (Phase 22b)

---

## 10. 다음 페이즈 (Phase 22b)

- [ ] Sequence Step A/B Testing (variants)
- [ ] Engagement-based Lead Score 자동 업데이트
- [ ] Email Analytics Dashboard (open/click/reply funnel)
- [ ] AI 분류 기반 자동 액션 (interested → hot lead tag, etc)
- [ ] Spintax 지원
- [ ] 첨부 파일 + 서명

URM_Email_Marketing_Roadmap.md 참조.
