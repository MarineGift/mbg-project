# Phase 2-b 가시성 패치 — 적용 가이드

> **목적**: 워커 polling loop가 실제로 도는지 확인할 수 있도록 명시적 로그 추가 + `break` 제거 + process 레벨 진단 핸들러 추가.
>
> **사전 준비**: 다른 랩탑 Outlook + 스마트폰의 `yunyoung.heo@`, `ceo@` IMAP **sync 비활성화** (계정 삭제 아님). 메일은 서버에 그대로 남음. → 이 가이드 끝부분 "Multi-client IMAP 처리" 참조.

---

## 패치 1: `src/lib/email/mailcarrier.ts` — `runPollingLoop` 교체

### 적용 위치

`mailcarrier.ts` 파일 내 `runPollingLoop` private 메서드 전체 (대략 line 270-295 부근).

### 현재 코드 (참고용)

```typescript
private async runPollingLoop(onMessage: InboundHandler): Promise<void> {
  let iterations = 0;
  while (this.isRunning) {
    try {
      await this.fetchAndProcessNew(onMessage);
    } catch (err) {
      console.error(`[mailcarrier:${this.kind}] polling iteration error:`, err);
      break;  // ← 이거 제거
    }
    await new Promise((r) =>
      setTimeout(r, env.MAILCARRIER_POLL_INTERVAL_SECONDS * 1000),
    );
  }
}
```

### 교체 후 코드

```typescript
private async runPollingLoop(onMessage: InboundHandler): Promise<void> {
  let iterations = 0;
  let consecutiveErrors = 0;

  console.log(
    `[mailcarrier:${this.kind}] polling loop start ` +
    `(interval=${env.MAILCARRIER_POLL_INTERVAL_SECONDS}s, isRunning=${this.isRunning})`,
  );

  while (this.isRunning) {
    iterations += 1;
    const tickStart = Date.now();
    console.log(
      `[mailcarrier:${this.kind}] polling tick #${iterations} — searching UNSEEN`,
    );

    try {
      await this.fetchAndProcessNew(onMessage);
      const elapsed = Date.now() - tickStart;
      console.log(
        `[mailcarrier:${this.kind}] polling tick #${iterations} done (${elapsed}ms)`,
      );
      consecutiveErrors = 0;
    } catch (err) {
      consecutiveErrors += 1;
      const elapsed = Date.now() - tickStart;
      console.error(
        `[mailcarrier:${this.kind}] polling iteration #${iterations} error ` +
        `after ${elapsed}ms (consecutive=${consecutiveErrors}):`,
        err,
      );
      // break 제거: 다음 iteration에서 재시도
      // 단, 연속 10회 실패 시 loop 종료 (영구 인증 실패 등 영구적 에러 가드)
      if (consecutiveErrors >= 10) {
        console.error(
          `[mailcarrier:${this.kind}] aborting polling loop after ${consecutiveErrors} consecutive errors`,
        );
        break;
      }
    }

    await new Promise((r) =>
      setTimeout(r, env.MAILCARRIER_POLL_INTERVAL_SECONDS * 1000),
    );
  }

  console.log(
    `[mailcarrier:${this.kind}] polling loop exited ` +
    `(isRunning=${this.isRunning}, iterations=${iterations})`,
  );
}
```

### 핵심 변경 사항

- `iterations` 카운터를 실제 사용 → tick 시작/완료 로그
- **`break` 제거** — 단일 iteration 에러가 loop를 영구 종료시키지 않음
- **연속 10회 에러 가드** — 인증 실패 같은 영구적 에러는 무한 로그를 막기 위해 종료
- 소요시간(`elapsed` ms) 추적 → fetch가 느린지 즉시 죽었는지 판별
- loop 종료 시 이유 명시 로그

---

## 패치 2: `src/workers/mailcarrier-worker.ts` — process 핸들러 추가

### 적용 위치

`mailcarrier-worker.ts` 파일 **최상단** (import문 직후, 메인 로직 위).

### 추가할 코드

```typescript
// ─── Process-level diagnostics ─────────────────────────────────────────────
process.on('uncaughtException', (err) => {
  console.error('[worker] uncaughtException:', err);
  // 진단 단계: 의도적으로 exit 안 함 — 어떤 에러가 워커를 죽이려 하는지 보기 위함
  // 운영 단계로 가면 process.exit(1)로 바꿔야 함
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('[worker] unhandledRejection at:', promise, 'reason:', reason);
});

process.on('SIGTERM', () => {
  console.warn('[worker] SIGTERM received — exiting');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.warn('[worker] SIGINT received — exiting');
  process.exit(0);
});

process.on('exit', (code) => {
  console.warn(`[worker] process.on('exit') code=${code}`);
});

process.on('beforeExit', (code) => {
  console.warn(
    `[worker] beforeExit code=${code} — event loop empty, ` +
    `no more work scheduled (this means polling loop has exited)`,
  );
});
// ───────────────────────────────────────────────────────────────────────────
```

### 핵심 변경 사항

- `uncaughtException` / `unhandledRejection` → 비동기 에러가 워커를 죽이려 하면 로그로 잡힘
- `SIGTERM` / `SIGINT` → 외부에서 종료시키는 경우(Windows Task Scheduler, Defender, 사용자 등) 식별
- `exit` → 종료 코드 기록
- **`beforeExit` ← 가장 중요**: 이 로그가 뜨면 event loop가 비었다는 것 = polling loop가 모두 종료된 결정적 신호. 핸드오프의 가설 (B-1) 확정 진단

---

## 검증 절차

### Step 1: 컴파일

```powershell
cd C:\dev\mbg-project
npx tsc --noEmit
```

기존 known 11개 에러 외 새 에러 없어야 함.

### Step 2: 다른 IMAP 클라이언트 sync 끄기

진단 명확성을 위해 다음을 임시 비활성화 (변수 제거):

- 다른 랩탑 Outlook: `yunyoung.heo@`, `ceo@` 계정의 send/receive 비활성화 (또는 Outlook 종료)
- 스마트폰 Outlook: 두 계정 메일 동기화 끔
- WebAccess: 모든 탭/창 닫음
- 이 PC의 Outlook (만약 ceo@ 사용 중이면): 닫음

> 계정 자체를 삭제하지 마세요. sync만 끄면 됩니다. 메일은 서버에 그대로.

### Step 3: 워커 재시작 + 90초 관찰 (tick #3까지)

```powershell
npm run worker:mailcarrier
```

**기대 로그 (정상 동작 시)**:

```
[mailcarrier-worker:personal] connecting...
[mailcarrier-worker:personal] connected (folder=INBOX, mode=POLL)
... (3 inbox 모두 연결) ...
[mailcarrier-worker] listening on 3 inbox(es)...

[mailcarrier:personal] polling loop start (interval=30s, isRunning=true)
[mailcarrier:role] polling loop start (interval=30s, isRunning=true)
[mailcarrier:shared] polling loop start (interval=30s, isRunning=true)

[mailcarrier:personal] polling tick #1 — searching UNSEEN
[mailcarrier:personal] polling tick #1 done (123ms)
[mailcarrier:role] polling tick #1 — searching UNSEEN
[mailcarrier:role] polling tick #1 done (98ms)
[mailcarrier:shared] polling tick #1 — searching UNSEEN
[mailcarrier:shared] polling tick #1 done (104ms)

... (약 30초 후) ...

[mailcarrier:personal] polling tick #2 — searching UNSEEN
[mailcarrier:personal] polling tick #2 done (87ms)
...

... (약 60초 후) ...

[mailcarrier:personal] polling tick #3 — searching UNSEEN
...
```

### Step 4: 진단 분기

| 관찰된 로그 | 진단 | 다음 액션 |
|---|---|---|
| tick #1/2/3 정상 + 새 메일 처리 0건 | **(B-2) `\Seen` 충돌 확정** | Gmail → `personal` 새 메일 발송 후 DB 확인 (Step 5). 잡히면 multi-client가 원인 → 영구 해결은 UID 기반 추적으로 변경 |
| tick #1만 뜨고 tick #2 안 뜸 + `beforeExit` 로그 있음 | **(B-1) polling loop가 silent하게 종료** | `fetchAndProcessNew` 안에 추가 로그 (`persistInbound` 진입/완료, processor 호출 등) |
| tick #1만 뜨고 tick #2 안 뜸 + `beforeExit` 없음 | **`fetchAndProcessNew` 안에서 hang (promise pending)** | 같은 진단 + OpenAI/Anthropic API timeout 의심. 핸드오프의 "OpenAI quota 확보" 작업 미해결과 연관 |
| `uncaughtException` / `unhandledRejection` 로그 뜸 | 비동기 에러가 polling을 죽임 | 해당 에러부터 fix |
| `SIGTERM` / `SIGINT` 로그 뜸 | 외부에서 종료 | Task Scheduler, Defender, 또는 사용자가 닫음 — 워커 자체 문제 아님 |
| `consecutive errors` 카운트 증가 후 abort | 영구적 에러 (인증/네트워크) | 에러 메시지로 원인 확인 후 fix |

### Step 5: 새 메일 발송 + DB 검증

워커 라이브 상태에서:

1. Gmail → `yunyoung.heo@marinebiogroup.com` 으로 한 통 발송
2. 60초 대기
3. 워커 로그에서 `polling tick #N — searching UNSEEN` 와 `new inbound` 라인 확인
4. DB 쿼리:

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

기대: `imap_kind=personal`, `imap_user=yunyoung.heo@marinebiogroup.com` 인 row 1건.

---

## Multi-client IMAP 처리 (배경 설명)

### 왜 다른 디바이스 Outlook이 문제가 될 수 있는가

IMAP의 `\Seen` 플래그는 **서버에 저장되어 모든 연결된 클라이언트가 공유**합니다. 다른 디바이스의 Outlook이 같은 IMAP 계정으로 접속해 있고 메일을 fetch하면:

1. Outlook이 새 메일을 `FETCH BODY[]` (또는 자동 sync)
2. 서버에서 해당 메일의 `\Seen` 플래그 set
3. 워커가 30초 후 `SEARCH UNSEEN` 실행
4. 이미 `\Seen` set된 메일은 결과에 안 나옴 → 워커가 새 메일을 놓침

핸드오프의 가설 **(B-2)** 가 바로 이 시나리오입니다.

### 진단 단계 (지금): sync 끄기

목적은 변수 제거. 메일을 잃지 않습니다.

| 디바이스 | 방법 |
|---|---|
| 다른 랩탑 Outlook | 파일 → 계정 설정 → 해당 계정 선택 → "변경" → 자동 send/receive 끔. 또는 그냥 Outlook 종료 |
| 스마트폰 Outlook | 설정 → 계정 → 해당 계정 → "메일 동기화" 토글 끔 |
| WebAccess | 모든 브라우저 탭/창 닫음 |

`shared` (contact@)도 같이 끄면 변수가 깔끔해집니다. `contact@`는 운영 환경에서 사람이 직접 보는 inbox가 아닌 자동화 전용이어야 합니다.

### 영구 해결 (Phase 2-b 끝나면): 코드 변경

`\Seen` 플래그 기반이 아닌 다음 두 가지 방식으로 변경:

1. **UID 기반 추적** — DB 또는 메모리에 `last_processed_uid` 저장, `SEARCH UID <last_uid+1>:*` 로 fetch. `\Seen` 무관하게 새 메일 추적.
2. **`BODY.PEEK[]` 사용** — `BODY[]`는 자동으로 `\Seen` set, `BODY.PEEK[]`는 안 set. 단, 이건 워커가 fetch한 메일이 다른 클라이언트에서 unread로 남는다는 부수 효과. UID 기반과 함께 쓰면 robust.

이 변경 후에는 다른 디바이스 Outlook을 그대로 두고 사용해도 됩니다.

---

## 환경변수 현재 상태 (참고)

```dotenv
MAILCARRIER_HOST=mail.marinebiogroup.com
MAILCARRIER_PORT=143
MAILCARRIER_USERNAME=contact@marinebiogroup.com   # fallback (env.ts required)
MAILCARRIER_PASSWORD=...                          # fallback (env.ts required)
MAILCARRIER_USE_IDLE=false
MAILCARRIER_INBOX_FOLDER=INBOX
MAILCARRIER_POLL_INTERVAL_SECONDS=30
MAILCARRIER_TLS_REJECT_UNAUTHORIZED=false
MAILCARRIER_POLL_KINDS=personal,role,shared

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

---

## 적용 후 다음 액션

1. 패치 1·2 적용 → 컴파일 확인 → 다른 클라이언트 sync 끔 → 워커 재시작
2. 90초 동안 로그 관찰 (tick #1, #2, #3 까지)
3. 로그를 새 세션에 붙여넣고 위 분기표로 진단
4. 분기 결과에 따라:
   - (B-2) 확정 → UID 기반 추적으로 코드 변경
   - (B-1) 확정 → `fetchAndProcessNew` 추가 진단 로그
   - 그 외 → 해당 에러부터 fix
