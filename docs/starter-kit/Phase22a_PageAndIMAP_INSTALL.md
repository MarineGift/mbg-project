# Phase 22a — page.tsx 수정 + IMAP Sentiment 통합

## 1️⃣ page.tsx 수정

```powershell
cd C:\dev\mbg-project
Copy-Item phase22a_party_detail_page.tsx "src\app\(app)\[module]\parties\[id]\page.tsx" -Force
```

또는 다운로드 폴더에 있다면:
```powershell
Copy-Item "$env:USERPROFILE\Downloads\phase22a_party_detail_page.tsx" "C:\dev\mbg-project\src\app\(app)\[module]\parties\[id]\page.tsx" -Force
```

**변경 요약:**
- 새 import 3개 (`getPartyCommunicationsTimeline`, `getPartyCommunicationStats`, `listTemplatesForCompose`)
- `PartyCommunicationsTimeline` 컴포넌트 import
- `Promise.all`로 timeline + stats + templates 병렬 조회
- `defaultContact` 추출 (이메일 있는 첫 contact)
- `<PartyCommunicationsTimeline>` 좌측 컬럼에 ActivityTimeline 바로 아래 배치

배치 순서 (좌측 컬럼):
```
ActivityTimeline (기존)
↓
PartyCommunicationsTimeline (Phase 22a 신규)  ← 메일 양방향 + AI 회신 버튼
↓
PartyNotesCard (기존)
↓
PartyMeetingsList (기존)
↓
PartySequencePanel (Phase 21b)
```

---

## 2️⃣ IMAP Sentiment 분류 — Cron 기반 (권장)

**왜 Cron 기반?**
- 스키마에 `idx_communications_pending_classification` 인덱스 이미 존재 → 원래 cron 패턴이 의도됨
- IMAP 코드 수정 불필요 → 어떤 구현이든 그대로 작동
- AI 호출 실패해도 IMAP 수신은 계속됨
- 부하 조절 쉬움 (BATCH_SIZE 20개씩)

### 2-1. API Route 설치

```powershell
New-Item -ItemType Directory -Path "src\app\api\communications\classify" -Force
Copy-Item phase22a_classify_inbound_route.ts "src\app\api\communications\classify\route.ts" -Force
```

### 2-2. 헬스체크

```powershell
# 서버 띄우고
npm run dev

# 다른 터미널에서
curl -X GET http://localhost:3000/api/communications/classify `
  -H "x-cron-secret: urm-seq-2026"
```

기대 응답:
```json
{
  "ok": true,
  "pending": 2,
  "classified_last_24h": 0
}
```

### 2-3. 수동 일괄 분류 (테스트)

```powershell
curl -X POST http://localhost:3000/api/communications/classify `
  -H "x-cron-secret: urm-seq-2026"
```

기대 응답:
```json
{
  "ok": true,
  "mode": "batch",
  "processed": 2,
  "succeeded": 2,
  "failed": 0
}
```

DB 확인:
```sql
SELECT id, subject, ai_classification, ai_processing_status
FROM app.communications
WHERE direction = 'inbound'
ORDER BY occurred_at DESC
LIMIT 5;
```

`ai_classification` 컬럼에 `{intent, confidence, summary, language, sentiment, ...}` JSON이 채워져야 함.

### 2-4. Cron 등록 (자동 실행)

#### Windows 작업 스케줄러
```powershell
# 1분마다 실행
$action = New-ScheduledTaskAction `
  -Execute 'curl.exe' `
  -Argument '-X POST http://localhost:3000/api/communications/classify -H "x-cron-secret: urm-seq-2026"'

$trigger = New-ScheduledTaskTrigger `
  -Once -At (Get-Date) `
  -RepetitionInterval (New-TimeSpan -Minutes 1)

Register-ScheduledTask `
  -TaskName "URM_AI_Classify" `
  -Action $action `
  -Trigger $trigger `
  -Description "URM Phase 22a inbound AI classification"
```

#### Vercel Cron (배포 시)
`vercel.json`:
```json
{
  "crons": [
    {
      "path": "/api/communications/classify",
      "schedule": "*/2 * * * *"
    }
  ]
}
```
(2분마다 실행)

#### GitHub Actions (선택)
`.github/workflows/cron-classify.yml`:
```yaml
name: AI Classify Cron
on:
  schedule:
    - cron: '*/2 * * * *'
jobs:
  classify:
    runs-on: ubuntu-latest
    steps:
      - run: |
          curl -X POST https://your-domain.com/api/communications/classify \
            -H "x-cron-secret: ${{ secrets.CRON_SECRET }}"
```

---

## 3️⃣ (선택) IMAP 핸들러에 즉시 호출 추가

Cron 기반이 더 안전하지만, 빠른 분류가 필요하다면 IMAP 핸들러에서도 호출할 수 있습니다.

### 먼저 IMAP 핸들러 찾기

```powershell
cd C:\dev\mbg-project
# inbound 메일 insert하는 파일 찾기
Get-ChildItem -Recurse -Include *.ts -Path src | `
  Select-String -Pattern "direction.*['\""]inbound['\""]" | `
  Select-Object Path -Unique
```

또는:
```powershell
# IMAP fetch 관련 파일 찾기
Get-ChildItem -Recurse -Include *.ts -Path src | `
  Select-String -Pattern "(imapflow|node-imap|MAILCARRIER)" | `
  Select-Object Path -Unique
```

발견된 파일 (예: `src/lib/workers/mailcarrier-worker.ts`)에 다음 추가:

```typescript
// 기존: inbound 메일을 communications에 insert 한 직후

// fire-and-forget classification call
// (실패해도 IMAP 처리는 계속)
fetch(`${process.env.NEXT_PUBLIC_APP_URL}/api/communications/classify`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'x-cron-secret': process.env.CRON_SECRET!,
  },
  body: JSON.stringify({ communication_id: insertedId }),
}).catch((err) => {
  console.error('[classify fire-and-forget]', err);
  // cron이 나중에 처리해줌
});
```

또는 직접 호출 (workers에서 작동):
```typescript
import { classifyInboundEmail } from '@/lib/actions/email-compose';

// inbound insert 직후
classifyInboundEmail(insertedId).catch((err) => {
  console.error('[classify]', err);
});
```

---

## 4️⃣ 통합 테스트

### 시나리오 A: 신규 inbound 도착 → 자동 분류
1. URM에서 cold mail 발송 (Marinepad)
2. Marinepad 측에서 회신
3. IMAP이 inbound fetch → communications insert
4. (Cron) 1분 내 자동 분류 실행
5. Party 상세 페이지 새로고침 → `🟢 AI: 관심있음 (85%)` 배지 표시

### 시나리오 B: AI 회신 작성
1. Party 상세 페이지 → Communications Timeline
2. inbound 메일 옆 **↳ 회신** 버튼
3. 컴포즈 다이얼로그 → **✨ AI 작성** 모드
4. **AI 초안 생성** → 스레드 컨텍스트 + party/contact 정보 기반 회신 자동 작성
5. 검토 후 **발송**

### 시나리오 C: 회신 자동 매칭
1. URM이 보낸 메일에는 `Message-ID: <uuid.ts@marinebiogroup.com>` 헤더가 자동 포함됨
2. 수신자가 회신 → `In-Reply-To` 헤더에 같은 값 포함
3. IMAP이 inbound 저장 → `trg_auto_link_inbound_reply` 트리거 자동 동작
4. 같은 `thread_id`로 묶임, outbound의 `replied_at` 자동 갱신
5. Communications Timeline에서 스레드로 그룹화되어 표시

---

## 5️⃣ 비용 모니터링

```sql
-- 오늘 분류된 inbound 수
SELECT
  COUNT(*) AS total,
  COUNT(*) FILTER (WHERE ai_classification IS NOT NULL) AS classified,
  COUNT(*) FILTER (WHERE ai_classification->>'intent' = 'interested') AS interested,
  COUNT(*) FILTER (WHERE ai_classification->>'intent' = 'unsubscribe') AS unsubscribed
FROM app.communications
WHERE direction = 'inbound'
  AND occurred_at >= CURRENT_DATE;
```

월 1,000건 inbound 분류 ≈ $1 (Claude Sonnet 4.5)

---

## 6️⃣ 문제 발생 시 진단

### "ANTHROPIC_API_KEY is not configured"
- `.env.local`에 키 확인 → 서버 재시작 (`npm run dev` 다시 실행)

### "AI response was not valid JSON"
- 가끔 Claude가 ```json 코드펜스를 붙임. 코드는 이미 제거 처리하지만, 실패하면 다음 cron에서 재시도됨
- 5번 이상 같은 메일에 실패하면 ai_processing_status = 'failed'로 영구 표시됨

### Communications Timeline이 비어 보임
```sql
-- 실제 데이터 있는지 확인
SELECT direction, COUNT(*) FROM app.communications
WHERE party_id = '<marinepad_party_id>' AND deleted_at IS NULL
GROUP BY direction;
```

### RPC가 없다는 에러 (PGRST202)
- SQL 마이그레이션 미적용. `phase22a_communications_timeline.sql`을 BEGIN부터 COMMIT까지 통째로 실행
- 그 후 검증 쿼리로 7 rows + 1 trigger 확인

---

## 7️⃣ 다음 단계 (Phase 22b)

- A/B 테스팅 (sequence step variants)
- Reply sentiment 기반 자동 액션 (interested → hot lead)
- Engagement-based lead score
- Email analytics dashboard
- 첨부 파일 지원

`URM_Email_Marketing_Roadmap.md` Section 4 참조.
