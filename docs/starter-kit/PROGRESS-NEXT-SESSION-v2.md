# 다음 세션 시작 — 핸드오프 v2

> **이전 세션 종료 시점**: Phase 2-b 검증 시도 → 워커가 IMAP 연결은 정상이지만 새 메일을 못 잡음. 코드 가시성 부족으로 원인 단정 불가. 다음 세션에서 가시성 패치 3건 적용 후 재검증.

---

## 첫 메시지 (그대로 복사해서 새 채팅에 붙여넣기)

```
Phase 2-b 검증 진행 중. 환경 설정 + IMAP 연결 + 코드의 kind 저장 로직 모두 정상 확인했지만,
워커가 polling 모드에서도 새 메일을 처리하지 못하는 상태. 
다음 세션에서 mailcarrier.ts polling loop에 가시성 패치 적용 후 재검증 예정.

이전 세션 핸드오프 문서 첨부합니다.
```

문서 첨부 (이 PROGRESS-NEXT-SESSION-v2.md).

---

## 프로젝트 컨텍스트 (이전 세션과 동일)

- **Repo**: https://github.com/MarineGift/mbg-project
- **Branch**: marinebiogroup
- **Local**: C:\dev\mbg-project
- **Org ID**: b25de8f2-1020-482f-9012-183f63883169
- **User ID**: 551fc4a0-b365-47eb-bf2f-0c3f594001c0
- **Stack**: Next.js 14.2.13, Supabase, Anthropic SDK, TABS Mailer, MailCarrier
- **언어**: 한국어 응답
- **메일서버**: mail.marinebiogroup.com (자체 호스팅, IMAP 143 STARTTLS, SMTP 587 평문)

## 3개 계정

| Kind | Username |
|------|----------|
| personal | yunyoung.heo@marinebiogroup.com |
| role | ceo@marinebiogroup.com |
| shared | contact@marinebiogroup.com |

---

## 이번 세션에서 검증된 사실

### ✅ 정상 동작 확인됨

1. **`.env.local` 설정 완료** — `MAILCARRIER_POLL_KINDS=personal,role,shared` 정상 적용
2. **3 inbox IMAP 연결 정상** — IDLE 모드, POLL 모드 둘 다 connected 로그 확인
3. **워커 startup 시 1회 fetch 정상 동작** — promotions@amtrakvacations.com 화이트리스트 차단 정상 (kind 식별자 `[mailcarrier:personal]` 로그에 정확히 표시됨)
4. **`mailcarrier.ts:438-444`의 `external_data`에 kind 저장 코드 존재 확인**:
   ```typescript
   external_data: {
     ...
     mailcarrier_account_kind: this.kind,
     mailcarrier_account_username: this.username,
     ...
   }
   ```
5. **`runPollingLoop` 구조도 정상** — `while (this.isRunning)`, `MAILCARRIER_POLL_INTERVAL_SECONDS` 사용, setTimeout 대기

### ❌ 확인된 문제

1. **IDLE 모드 ECONNRESET / ETIMEDOUT 크래시**
   - `code: 'ETIMEDOUT'` (첫 시도)
   - `code: 'ECONNRESET'` (두 번째 시도)
   - 워커에 `'error'` 이벤트 핸들러 없음 → process 전체 죽음

2. **POLL 모드에서도 새 메일 처리 0건**
   - 워커는 살아있음 (Get-Process node에서 확인)
   - WebAccess INBOX에는 새 메일 9건 unread 표시
   - 하지만 워커는 startup 직후 promotions@ 메일 1건만 처리하고 그 후 침묵
   - DB에 UTC 21:00 이후 새 inbound row 0건

3. **`mailcarrier.ts:289`에 catch break 의심점**
   - polling iteration 에러 시 break → loop 영구 종료
   - 그러나 `polling iteration error` 로그가 안 떴으므로 break 안 한 것으로 추정
   - 하지만 코드 가시성 부족으로 단정 불가

### 결정적 의문 — 다음 세션에서 풀어야 할 것

**워커가 살아있는데 30초 polling 사이클이 실제로 도는지 확인할 방법이 없다.**

가능성 2가지:
- **(B-1)** Polling loop가 silent하게 멈춤 — `break`, `isRunning=false`, 또는 hung promise
- **(B-2)** 메일서버 또는 다른 IMAP 클라이언트(WebAccess 자동 fetch? Outlook ceo@? sieve filter?)가 자동으로 새 메일을 \Seen 처리 → SEARCH UNSEEN에 안 잡힘

---

## 다음 세션 액션 — 가시성 패치 3건

### 패치 1: `mailcarrier.ts` runPollingLoop에 명시적 tick 로그

**위치**: `src/lib/email/mailcarrier.ts` line 274 부근

**현재 코드 (요약)**:
```typescript
private async runPollingLoop(onMessage: InboundHandler): Promise<void> {
  let iterations = 0;
  while (this.isRunning) {
    try {
      await this.fetchAndProcessNew(onMessage);
    } catch (err) {
      console.error(`[mailcarrier:${this.kind}] polling iteration error:`, err);
      break;  // ← 이거 제거 필요
    }
    await new Promise((r) =>
      setTimeout(r, env.MAILCARRIER_POLL_INTERVAL_SECONDS * 1000),
    );
  }
}
```

**패치 후**:
```typescript
private async runPollingLoop(onMessage: InboundHandler): Promise<void> {
  let iterations = 0;
  while (this.isRunning) {
    iterations += 1;
    console.log(`[mailcarrier:${this.kind}] polling tick #${iterations} — searching UNSEEN`);
    try {
      await this.fetchAndProcessNew(onMessage);
      console.log(`[mailcarrier:${this.kind}] polling tick #${iterations} done`);
    } catch (err) {
      console.error(`[mailcarrier:${this.kind}] polling iteration #${iterations} error:`, err);
      // break 제거 — 다음 iteration 시도
    }
    await new Promise((r) =>
      setTimeout(r, env.MAILCARRIER_POLL_INTERVAL_SECONDS * 1000),
    );
  }
  console.log(`[mailcarrier:${this.kind}] polling loop exited (isRunning=${this.isRunning})`);
}
```

### 패치 2: `mailcarrier-worker.ts` process error handler

**위치**: `src/workers/mailcarrier-worker.ts` 최상단

**추가 코드**:
```typescript
process.on('uncaughtException', (err) => {
  console.error('[worker] uncaughtException:', err);
});
process.on('unhandledRejection', (reason) => {
  console.error('[worker] unhandledRejection:', reason);
});
```

### 패치 3 (선택, 패치 1·2 결과 보고 결정): IMAP client error 이벤트 핸들러 + 재연결

**위치**: 각 client 인스턴스 생성 후

**추가 코드 (예시)**:
```typescript
client.on('error', async (err) => {
  console.error(`[mailcarrier:${kind}] client error:`, err);
  // 5초 후 재연결 시도
  setTimeout(() => this.reconnect(), 5000);
});
client.on('close', () => {
  console.warn(`[mailcarrier:${kind}] connection closed`);
});
```

이건 ECONNRESET / ETIMEDOUT 자동 복구용. 핸드오프 문서의 "안정성" 작업과 합쳐서 처리.

---

## 다음 세션 검증 절차

### Step 1: 패치 1·2 적용 후 컴파일 확인

```powershell
npx tsc --noEmit
```

기존 known 11개 외 새 에러 없어야 함.

### Step 2: 워커 재시작 + 30초 관찰

```powershell
npm run worker:mailcarrier
```

**기대 로그**:
```
[mailcarrier-worker:personal] connecting...
[mailcarrier-worker:personal] connected (folder=INBOX, mode=POLL)
... (3 inbox 연결)
[mailcarrier-worker] listening on 3 inbox(es)...
[mailcarrier:personal] polling tick #1 — searching UNSEEN
[mailcarrier:role] polling tick #1 — searching UNSEEN
[mailcarrier:shared] polling tick #1 — searching UNSEEN
[mailcarrier:personal] skip — not in whitelist: promotions@amtrakvacations.com  (있다면)
[mailcarrier:personal] polling tick #1 done
[mailcarrier:role] polling tick #1 done
[mailcarrier:shared] polling tick #1 done
```

**30초 후**:
```
[mailcarrier:personal] polling tick #2 — searching UNSEEN
[mailcarrier:personal] polling tick #2 done
...
```

### Step 3: 분기

**A. tick #2 이상이 정상적으로 떴다** → polling은 도는 것 확정. 새 메일이 안 잡히면 (B-2) 가설 확정 → 다음 작업:
- WebAccess 닫고 새 메일 발송 후 검증
- 또는 last_processed_uid 추적 방식으로 코드 변경 (UID 기반, \Seen 무관)

**B. tick #1 이후 tick #2가 안 뜬다** → polling loop가 진짜 멈춰있음. fetchAndProcessNew 안에서 hang 또는 isRunning=false.
- fetchAndProcessNew의 각 단계(persistInbound 진입/완료, processor 호출 등)에도 로그 추가해서 어디서 stuck인지 확인
- OpenAI quota 의심 (핸드오프 문서의 "OpenAI quota 확보" 미해결 작업)

### Step 4: 새 메일 발송 + DB 검증

워커 라이브 상태에서:
- Gmail → yunyoung.heo@marinebiogroup.com 한 통
- 60초 대기
- 워커 로그에서 `new inbound` 라인 + tick #N 로그 확인
- DB 쿼리:
  ```sql
  SELECT 
    id, from_address, subject,
    external_data->>'mailcarrier_account_kind' AS imap_kind,
    external_data->>'mailcarrier_account_username' AS imap_user,
    created_at
  FROM app.communications
  WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
    AND direction = 'inbound'
    AND created_at > NOW() - INTERVAL '5 minutes'
  ORDER BY created_at DESC;
  ```

기대: `imap_kind=personal`, `imap_user=yunyoung.heo@marinebiogroup.com`인 새 row 1건.

---

## 추가 의심 사항 (다음 세션에서 확인)

### Outlook ceo@ 상태

이번 세션에서 ceo@ Outlook 사용 여부 확인 못함. 

- ⓐ Outlook IMAP로 ceo@ 연결 중이면 → ECONNRESET 원인 가능성 높음
- ⓑ Outlook 닫혀 있음 또는 다른 계정 사용 → 다른 원인

다음 세션에서 명확히 물어볼 것.

### WebAccess가 \Seen 처리하는지

가설 (B-2)와 직접 관련. WebAccess 열어보기만 했는데 IMAP \Seen 플래그가 set 되는지 확인 필요. 검증 방법:

1. WebAccess 완전히 닫음 (모든 탭, 브라우저까지)
2. SSH 또는 외부 IMAP 클라이언트로 직접 LIST UNSEEN 결과 확인
3. 또는 패치 1·2 적용 후 워커가 잡는지로 간접 확인

---

## 환경변수 현재 상태

```dotenv
MAILCARRIER_HOST=mail.marinebiogroup.com
MAILCARRIER_PORT=143
MAILCARRIER_USERNAME=contact@marinebiogroup.com   # fallback (env.ts required)
MAILCARRIER_PASSWORD=!hyypik1024U                 # fallback (env.ts required)
MAILCARRIER_USE_IDLE=false                        # ← 이번 세션에서 false로 변경
MAILCARRIER_INBOX_FOLDER=INBOX
MAILCARRIER_POLL_INTERVAL_SECONDS=30
MAILCARRIER_TLS_REJECT_UNAUTHORIZED=false
MAILCARRIER_POLL_KINDS=personal,role,shared       # ← Phase 2 핵심

MAIL_PERSONAL_USERNAME=yunyoung.heo@marinebiogroup.com
MAIL_PERSONAL_PASSWORD=...
MAIL_PERSONAL_DISPLAY_NAME=YunYoung Heo
MAIL_ROLE_USERNAME=ceo@marinebiogroup.com
MAIL_ROLE_PASSWORD=...
MAIL_ROLE_DISPLAY_NAME=CEO
MAIL_SHARED_USERNAME=contact@marinebiogroup.com
MAIL_SHARED_PASSWORD=...
MAIL_SHARED_DISPLAY_NAME=Marinebio Group
```

> **참고**: env.ts에서 `MAILCARRIER_USERNAME`/`PASSWORD`가 여전히 required로 되어 있어 fallback 두 줄 필요. 추후 conditional schema(POLL_KINDS 있으면 USERNAME/PASSWORD 옵셔널)로 정리할 것.

---

## Phase 2 끝나면 작업 (이전 세션과 동일)

1. **워커 안정성 패치** (이번에 가시성 패치하면서 함께 처리)
   - process error handlers
   - IMAP client `'error'`/`'close'` 핸들러 + reconnect
   - 또는 영구적으로 polling 모드 채택
2. **prompt 튜닝** — classifier/drafter fallback 탈피 (현재 Other/0.3)
3. **운영 준비**
   - sql/010_rls_policies.sql 적용
   - SMTP STARTTLS 활성화
   - OpenAI quota 확보
   - 첨부 발송 기능
4. **env.ts conditional schema** — POLL_KINDS 있으면 MAILCARRIER_USERNAME/PASSWORD 옵셔널
5. **TypeScript strict 정리** (낮음)

---

## 이번 세션의 교훈

1. **검증 시 코드 가시성이 핵심** — polling loop가 도는지 확인할 로그가 없으면 진단 불가능
2. **IDLE 모드는 자체 호스팅 서버에서 불안정** — keep-alive/timeout 이슈 빈번. polling 모드가 안전
3. **WebAccess 같은 추가 IMAP 클라이언트가 \Seen 처리 가능성** — IMAP은 multi-client 환경에서 플래그 충돌 흔함. UID 기반 추적이 더 robust
