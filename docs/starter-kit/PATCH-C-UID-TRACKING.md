# 패치 C — UID 기반 추적 (영구 해결)

> **목적**: `messageFlagsAdd(\Seen)` 호출을 완전히 제거. 자체 호스팅 IMAP 서버가 이 명령에 응답하지 않는 문제를 코드 측에서 우회. UID 기반으로 새 메시지를 추적하므로 `\Seen` 플래그와 무관.
>
> **부수 효과**: 메일이 IMAP 서버에서 영원히 unseen으로 남음. Outlook이나 WebAccess에서는 unread로 보임. 이건 의도된 동작 — 워커는 DB의 `last_processed_uid`로 새 메시지 여부를 판단하므로 IMAP flag와 무관.

---

## Step 1: SQL 마이그레이션

### 파일 생성

`sql/020_mailcarrier_state.sql` (또는 기존 SQL 파일 번호 체계에 맞게 다른 번호로):

```sql
-- =============================================================================
-- mailcarrier_state
-- =============================================================================
-- IMAP UID 기반 추적: 각 (organization, kind, username) 조합마다
-- 마지막으로 처리한 UID 저장. \Seen flag 의존성 제거.
-- =============================================================================

CREATE TABLE IF NOT EXISTS app.mailcarrier_state (
  organization_id UUID NOT NULL,
  kind TEXT NOT NULL,
  username TEXT NOT NULL,
  last_processed_uid BIGINT NOT NULL DEFAULT 0,
  uid_validity BIGINT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (organization_id, kind, username)
);

COMMENT ON TABLE app.mailcarrier_state IS
  'IMAP UID 기반 추적: 각 inbox마다 마지막으로 처리한 UID 저장. \\Seen flag 의존성 제거.';
COMMENT ON COLUMN app.mailcarrier_state.last_processed_uid IS
  '마지막으로 성공적으로 처리(persist 또는 명시적 skip)한 메시지의 IMAP UID. 다음 fetch는 (this+1):* 로 진행.';
COMMENT ON COLUMN app.mailcarrier_state.uid_validity IS
  'IMAP UIDVALIDITY. 변경되면 mailbox가 reset된 것이므로 last_processed_uid도 reset 필요. Phase 2-c에서는 미사용, 향후 확장용.';
```

### 적용 방법

**옵션 A**: Supabase Dashboard → SQL Editor → 위 SQL 붙여넣고 RUN.

**옵션 B**: 로컬에서 직접 적용:
```powershell
# psql 또는 supabase CLI 사용
# 또는 Supabase Studio에서 위 SQL 실행
```

**적용 확인**:
```sql
SELECT * FROM app.mailcarrier_state;
-- 0 rows 반환되면 OK (초기 상태)
```

---

## Step 2: `IImapClient` 인터페이스 확장

**위치**: `mailcarrier.ts` 안의 `IImapClient` 인터페이스 (line 70-83 부근).

### 현재
```typescript
fetch(
  range: { seen?: boolean } | string,
  options: { source: boolean; envelope?: boolean; uid?: boolean },
): AsyncIterable<FetchMessageObject>;
```

### 교체
```typescript
fetch(
  range: { seen?: boolean } | string,
  options: { source: boolean; envelope?: boolean; uid?: boolean },
  queryOptions?: { uid?: boolean },
): AsyncIterable<FetchMessageObject>;
```

(세 번째 옵셔널 인자 추가. imapflow의 실제 API에 맞춤. `{ uid: true }`를 주면 첫 번째 인자를 UID 범위로 해석.)

---

## Step 3: `MailCarrierClient` — 메서드 추가 + `fetchAndProcessNew` 재작성

### 3-1. UID load/save 메서드 추가

`fetchAndProcessNew` 메서드 **바로 위**에 두 private 메서드 추가:

```typescript
  /* --------------------------------------------------------
   * UID 기반 추적 — load / save
   * -------------------------------------------------------- */

  /**
   * DB에서 마지막 처리한 UID 조회. 레코드 없으면 0 반환 (모든 메시지를 새 것으로 간주).
   */
  private async loadLastProcessedUid(): Promise<number> {
    const { data, error } = await this.supabase
      .schema('app')
      .from('mailcarrier_state')
      .select('last_processed_uid')
      .eq('organization_id', this.organizationId)
      .eq('kind', this.kind)
      .eq('username', this.username)
      .maybeSingle();

    if (error) {
      // eslint-disable-next-line no-console
      console.warn(
        `[mailcarrier:${this.kind}] loadLastProcessedUid failed, defaulting to 0:`,
        error.message,
      );
      return 0;
    }
    return data?.last_processed_uid ?? 0;
  }

  /**
   * 마지막 처리한 UID를 DB에 UPSERT.
   */
  private async saveLastProcessedUid(uid: number): Promise<void> {
    const { error } = await this.supabase
      .schema('app')
      .from('mailcarrier_state')
      .upsert(
        {
          organization_id: this.organizationId,
          kind: this.kind,
          username: this.username,
          last_processed_uid: uid,
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'organization_id,kind,username' },
      );

    if (error) {
      // eslint-disable-next-line no-console
      console.error(
        `[mailcarrier:${this.kind}] saveLastProcessedUid failed for uid=${uid}:`,
        error.message,
      );
      // throw 안 함 — 다음 tick에서 재시도. 최악의 경우 같은 메시지 다시 처리되지만
      // message_id UNIQUE로 중복 INSERT 차단됨.
    }
  }
```

### 3-2. `fetchAndProcessNew` 전체 교체

기존 메서드 본문 통째로 아래로 교체:

```typescript
  /* --------------------------------------------------------
   * fetchAndProcessNew — UID 기반 새 메시지 처리
   *
   * \Seen 플래그 의존성 제거. DB에 저장된 last_processed_uid 기반으로
   * 새 메시지만 fetch.
   * -------------------------------------------------------- */

  async fetchAndProcessNew(onMessage: InboundHandler): Promise<void> {
    const t0 = Date.now();
    // eslint-disable-next-line no-console
    console.log(`[mailcarrier:${this.kind}] fetch: acquiring lock`);

    const lock = await this.client.getMailboxLock(env.MAILCARRIER_INBOX_FOLDER);

    // eslint-disable-next-line no-console
    console.log(
      `[mailcarrier:${this.kind}] fetch: lock acquired (+${Date.now() - t0}ms)`,
    );

    let msgCount = 0;
    let lastUidProcessed: number | undefined;

    try {
      // 1. DB에서 last UID 조회
      const lastUid = await this.loadLastProcessedUid();
      const range = `${lastUid + 1}:*`;
      // eslint-disable-next-line no-console
      console.log(
        `[mailcarrier:${this.kind}] fetch: range=${range} (last_uid=${lastUid})`,
      );

      // 2. UID 기반 fetch (imapflow의 세 번째 인자 { uid: true })
      for await (const message of this.client.fetch(
        range,
        { source: true, envelope: true, uid: true },
        { uid: true },
      )) {
        const uid = Number((message as unknown as { uid?: number | string }).uid);

        // 안전 가드: 이미 처리한 UID는 skip (IMAP 서버가 inclusive로 반환할 수 있음)
        if (!Number.isFinite(uid) || uid <= lastUid) {
          // eslint-disable-next-line no-console
          console.log(
            `[mailcarrier:${this.kind}] fetch: skipping uid=${uid} (<= last_uid=${lastUid})`,
          );
          continue;
        }

        msgCount += 1;
        const msgT0 = Date.now();
        // eslint-disable-next-line no-console
        console.log(
          `[mailcarrier:${this.kind}] fetch: msg #${msgCount} received uid=${uid} (+${Date.now() - t0}ms)`,
        );

        try {
          if (!message.source) {
            // eslint-disable-next-line no-console
            console.log(
              `[mailcarrier:${this.kind}] fetch: msg #${msgCount} no source, marking as processed`,
            );
            lastUidProcessed = uid;
            continue;
          }

          const parsed = await this.parser(message.source);
          const event = await this.persistInbound(parsed);
          // eslint-disable-next-line no-console
          console.log(
            `[mailcarrier:${this.kind}] fetch: msg #${msgCount} persistInbound done ` +
              `(event=${event ? 'yes' : 'null'}) (+${Date.now() - msgT0}ms)`,
          );

          if (event) {
            try {
              await onMessage(event);
              // eslint-disable-next-line no-console
              console.log(
                `[mailcarrier:${this.kind}] fetch: msg #${msgCount} onMessage done (+${Date.now() - msgT0}ms)`,
              );
            } catch (handlerErr) {
              // eslint-disable-next-line no-console
              console.error(
                `[mailcarrier:${this.kind}] fetch: msg #${msgCount} onMessage failed:`,
                handlerErr,
              );
              // onMessage 실패해도 메일 자체는 persist 완료 — UID 갱신 진행
            }
          }

          // 처리 완료 (persist 성공 또는 화이트리스트 skip 모두 포함) → UID 갱신
          lastUidProcessed = uid;
        } catch (err) {
          // eslint-disable-next-line no-console
          console.error(
            `[mailcarrier:${this.kind}] fetch: msg #${msgCount} uid=${uid} processing failed:`,
            err,
          );
          // 단건 실패 시 lastUidProcessed 갱신 안 함 → 다음 tick에서 재시도.
          // 그러나 그 후의 메시지들도 이번 tick에서는 처리 안 함 (sequential 보장).
          break;
        }
      }

      // 3. 처리한 마지막 UID를 DB에 저장
      if (lastUidProcessed !== undefined) {
        await this.saveLastProcessedUid(lastUidProcessed);
        // eslint-disable-next-line no-console
        console.log(
          `[mailcarrier:${this.kind}] fetch: saved last_uid=${lastUidProcessed} ` +
            `(${msgCount} msgs in this tick, total +${Date.now() - t0}ms)`,
        );
      } else {
        // eslint-disable-next-line no-console
        console.log(
          `[mailcarrier:${this.kind}] fetch: no new messages (+${Date.now() - t0}ms)`,
        );
      }
    } finally {
      // eslint-disable-next-line no-console
      console.log(`[mailcarrier:${this.kind}] fetch: releasing lock`);
      try {
        await lock.release();
        // eslint-disable-next-line no-console
        console.log(`[mailcarrier:${this.kind}] fetch: lock released`);
      } catch (releaseErr) {
        // eslint-disable-next-line no-console
        console.warn(
          `[mailcarrier:${this.kind}] fetch: lock release failed:`,
          releaseErr,
        );
      }
    }
  }
```

### 핵심 차이

| 기존 (A.1) | 새 버전 (C) |
|---|---|
| `{ seen: false }` (UNSEEN search) | `${lastUid+1}:*` (UID range) |
| `messageFlagsAdd(\\Seen)` 호출 | **제거** — IMAP flag 안 건드림 |
| 매 tick마다 같은 메일 재처리 | last_uid 갱신 → 다음 tick에서 안 fetch |
| 60초 socket timeout 위험 | fetch가 빠르게 끝남 (\Seen 호출 없으니까) |

### `messageFlagsAdd` 제거 — `withCommandTimeout`도 제거?

`withCommandTimeout` 헬퍼는 그대로 유지 권장. 향후 다른 IMAP 명령에 timeout이 필요할 때 활용. 지금은 호출 없지만 lint에서는 declared-but-not-used 경고 없음 (메서드는 class 안에 있으면 정의만 해도 OK).

만약 깨끗하게 정리하고 싶으면 `withCommandTimeout` 메서드도 삭제 가능. 선택사항.

---

## Step 4: 검증 절차

### 4-1. SQL 적용 확인

```sql
SELECT * FROM app.mailcarrier_state;
-- 빈 결과 OK
```

### 4-2. 컴파일

```powershell
cd C:\dev\mbg-project
npx tsc --noEmit
```

기존 known 11개 외 새 에러 없어야 함.

### 4-3. 첫 실행 — initial sync

```powershell
npm run worker:mailcarrier
```

**첫 tick (last_uid=0)**: inbox의 모든 메시지를 fetch함. 메시지 많으면 처리 시간 김. 끝나면 `saved last_uid=NNNN` 로그.

**기대 로그**:
```
[mailcarrier:shared] polling tick #1 — searching UNSEEN
[mailcarrier:shared] fetch: acquiring lock
[mailcarrier:shared] fetch: lock acquired (+5ms)
[mailcarrier:shared] fetch: range=1:* (last_uid=0)
[mailcarrier:shared] fetch: msg #1 received uid=8 (+500ms)
...
[mailcarrier:shared] fetch: msg #6 persistInbound done (event=yes) ...
[mailcarrier:shared] fetch: msg #6 onMessage done ...
[mailcarrier:shared] fetch: saved last_uid=13 (6 msgs in this tick, total +20000ms)
[mailcarrier:shared] polling tick #1 done (20023ms)
```

(60초 hang 없음. \Seen set 안 하므로 빠르게 진행.)

### 4-4. 두 번째 tick — 새 메일 0건이면 즉시 종료

30초 후:
```
[mailcarrier:shared] polling tick #2 — searching UNSEEN
[mailcarrier:shared] fetch: range=14:* (last_uid=13)
[mailcarrier:shared] fetch: no new messages (+200ms)
[mailcarrier:shared] polling tick #2 done (201ms)
```

200ms 안에 완료. **이게 정상 동작**.

### 4-5. 새 메일 발송 + DB 검증

Gmail → `yunyoung.heo@marinebiogroup.com` 또는 `contact@marinebiogroup.com` 으로 새 메일 발송. 30초 대기.

**기대 로그**:
```
[mailcarrier:personal] polling tick #N — searching UNSEEN
[mailcarrier:personal] fetch: range=NNN:* (last_uid=NNN-1)
[mailcarrier:personal] fetch: msg #1 received uid=NNN (+500ms)
[mailcarrier:personal] fetch: msg #1 persistInbound done (event=yes) ...
[mailcarrier-worker:personal:XXXX] new inbound — from=...
[mailcarrier-worker:personal:XXXX] processed → draft.id=...
[mailcarrier:personal] fetch: saved last_uid=NNN (1 msgs in this tick)
```

**DB 검증**:
```sql
-- mailcarrier_state 확인
SELECT organization_id, kind, username, last_processed_uid, updated_at
FROM app.mailcarrier_state
ORDER BY kind;

-- 새 inbound 메일 확인
SELECT id, from_address, subject,
  external_data->>'mailcarrier_account_kind' AS kind,
  created_at
FROM app.communications
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND direction = 'inbound'
  AND created_at > NOW() - INTERVAL '5 minutes'
ORDER BY created_at DESC;
```

기대: 3 row in mailcarrier_state (personal/role/shared), 발송한 새 메일 1건 in communications.

---

## 알려진 제약 사항 (Phase 2-c에서는 미해결)

1. **UIDVALIDITY 미체크**: 메일서버에서 mailbox reset(매우 드문 경우)이 일어나면 UID도 reset됨. 이 경우 last_processed_uid가 의미 없어짐. 향후 `uid_validity` 컬럼 활용으로 처리.
2. **초기 동기화 시 inbox의 모든 unseen 메일 처리**: 첫 실행에서 last_uid=0이므로 모든 메시지를 새 것으로 간주. 많으면 시간 김. 한 번만 일어남. 또는 SQL에서 초기 last_uid를 수동 설정 가능:
   ```sql
   INSERT INTO app.mailcarrier_state (organization_id, kind, username, last_processed_uid)
   VALUES
     ('b25de8f2-1020-482f-9012-183f63883169', 'personal', 'yunyoung.heo@marinebiogroup.com', 100000),
     ('b25de8f2-1020-482f-9012-183f63883169', 'role',     'ceo@marinebiogroup.com',           100000),
     ('b25de8f2-1020-482f-9012-183f63883169', 'shared',   'contact@marinebiogroup.com',       100000);
   ```
   (UID는 메일서버마다 다름. 적당히 큰 값으로 설정하면 그 이전 메일들은 무시됨.)

3. **`\Seen` 영원히 unset**: Outlook이나 WebAccess에서 메일이 unread로 보임. 이건 의도된 동작. 사람이 직접 메일을 읽으면 그때 \Seen이 set됨.

---

## 다음 작업 (Phase 2-c 끝나면)

핸드오프 v2의 미해결 항목:
- OpenAI quota 확보 (결제/플랜 업그레이드)
- prompt 튜닝 (classifier/drafter output validation 통과)
- env.ts conditional schema (POLL_KINDS 있으면 MAILCARRIER_USERNAME 옵셔널)
- TypeScript strict 정리 (낮음, known 11개)
- sql/010_rls_policies.sql 적용
- SMTP STARTTLS 활성화
- 첨부 발송 기능
