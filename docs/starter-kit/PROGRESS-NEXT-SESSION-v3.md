# 다음 세션 시작 — 핸드오프 v3

> **이전 세션(v2 → v3) 종료 시점**: Phase 2-b (워커 안정성) + Phase 2-c (UID 추적) 완성. End-to-end 파이프라인 동작 확인 + TypeScript 컴파일 클린(0 errors). 다음 세션은 **운영 준비 단계**.

---

## 첫 메시지 (그대로 복사해서 새 채팅에 붙여넣기)

```
Phase 2-b/2-c 완성. IMAP 수신 → DB persist → draft 생성 end-to-end 작동 중.
TypeScript 컴파일 클린(0 errors). 다음 단계는 OpenAI quota 확보 + prompt 튜닝 +
운영 준비. 이전 세션 핸드오프 v3 문서 첨부합니다.
```

문서 첨부 (이 PROGRESS-NEXT-SESSION-v3.md).

---

## 프로젝트 컨텍스트

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

## ✅ 이번 세션에서 완성된 사항

### Phase 2-b — 워커 안정성

1. **Polling tick 가시성 로그** — `runPollingLoop`에 `polling tick #N — searching` / `tick #N done (Xms)` 로그 추가
2. **Process-level 진단 핸들러** — `mailcarrier-worker.ts`에 `uncaughtException`, `unhandledRejection`, `SIGTERM`, `SIGINT`, `exit`, `beforeExit` 핸들러
3. **ImapFlow socketTimeout 단축** — 5분 → 60초로 fail-fast
4. **Connection-level 자동 재연결** — `NoConnection`/`ETIMEOUT`/`ECONNRESET`/`ECONNREFUSED` 감지 시 `handleReconnect()` 호출, 카운터 리셋
5. **연속 10회 에러 가드** — 영구적 인증/네트워크 에러 보호 (loop abort)

### Phase 2-c — UID 기반 추적 (영구 해결)

자체 호스팅 IMAP 서버가 `messageFlagsAdd(\Seen)`에 응답하지 않아 60초 hang을 유발하던 문제. UID 기반으로 코드 측에서 우회.

1. **SQL 테이블**: `sql/020_mailcarrier_state.sql` 적용 완료
   ```
   PK: (organization_id, kind, username)
   컬럼: last_processed_uid BIGINT, uid_validity BIGINT (미사용), updated_at TIMESTAMPTZ
   ```
2. **`IImapClient` 인터페이스 확장**: `fetch()` 시그니처에 세 번째 인자 `queryOptions?: { uid?: boolean }` 추가
3. **MailCarrierClient 새 메서드**:
   - `loadLastProcessedUid()` — DB SELECT
   - `saveLastProcessedUid(uid)` — DB UPSERT
4. **`fetchAndProcessNew` 재작성**:
   - `{ seen: false }` UNSEEN search → `${lastUid+1}:*` UID range
   - `messageFlagsAdd(\Seen)` 호출 완전 제거
   - 처리 완료 시 lastUidProcessed 갱신, finally 직전에 saveLastProcessedUid 호출
   - 단건 실패 시 break (sequential 보장)
5. **부수 효과**: 메일이 IMAP 서버에서 영원히 unseen으로 남음. Outlook/WebAccess에서는 unread로 보임. 의도된 동작.

### 코드 정리

- `mailcarrier.ts` 깨끗이 정리: 패치 마커 주석 제거, 마크다운 펜스 잔재 제거, 들여쓰기 일관성 복원 (875 lines)
- `withCommandTimeout` 헬퍼는 유지 (Phase 2-c에서 미사용, 향후 활용)

### TypeScript 컴파일 클린 (11 → 0)

- `src/lib/auth.ts:41` + `src/lib/actions/auth.ts:41` — `parts[1]` undefined 가드 추가
- `src/scripts/simulate-inbound.ts:175-183` — 기존 cast 변수 `d` 활용 (draft → d 9곳 교체)

### 보안 (이전 세션 보안 노출 사고 처리)

이전 세션 후반에 ANTHROPIC/OPENAI/SUPABASE 키와 DB/메일 비밀번호가 채팅에 노출됨. rotation 완료:
- Anthropic API key
- OpenAI API key
- Supabase service role key
- Supabase DB password
- 메일서버 3개 계정 비밀번호 (`yunyoung.heo@`, `ceo@`, `contact@`)
- `.env.local`의 6개 변수 업데이트 완료

---

## 🚧 남은 미해결 항목 (다음 세션 우선순위)

### 1. **OpenAI quota 확보** ⚠️ 최우선

```
[prompt-renderer] embedding failed, continuing without RAG: 
  EmbeddingError: 429 You exceeded your current quota
  code: 'insufficient_quota'
```

현재 graceful degradation으로 작동 중(draft 생성됨, classifier/drafter는 fallback). 하지만:
- RAG 미사용 → 분류 정확도 저하
- classifier output validation 실패 → 'other' 카테고리로 force
- reply drafter output invalid → `body_plain_missing_or_empty,risk_flags_not_array`

**액션**: OpenAI 결제/플랜 업그레이드 (platform.openai.com → Billing). 결제 후 새 키 발급 필요할 수도 있음.

### 2. **Prompt 튜닝**

OpenAI quota 회복 후 진행. classifier/drafter output이 expected schema에 맞도록 prompt 튜닝.

현재 관찰된 validation 실패:
- `classifier output invalid: not_an_object`
- `classifier output invalid: invalid_sentiment:undefined,requires_human_not_boolean,risk_flags_not_array,invalid_detected_language:undefined`
- `reply drafter output invalid: body_plain_missing_or_empty,risk_flags_not_array,requires_human_approval_not_boolean`

**의심**: RAG 컨텍스트 없이는 schema 가이드가 부족. embedding 복구 후 다시 검증할 것.

### 3. **env.ts conditional schema**

`.env.local`에 `MAILCARRIER_USERNAME`/`MAILCARRIER_PASSWORD`가 여전히 required로 되어 있어 fallback용 2줄 (`contact@` 값) 필요. `MAILCARRIER_POLL_KINDS` 있으면 옵셔널로 만들기:

```typescript
// env.ts에서 (대략적)
MAILCARRIER_USERNAME: z.string().optional(),
MAILCARRIER_PASSWORD: z.string().optional(),
// .refine() 로 POLL_KINDS 비어있으면 둘 다 required 검증
```

### 4. **운영 준비 작업**

- `sql/010_rls_policies.sql` 적용 (현재 service_role 우회 중)
- SMTP STARTTLS 활성화 (현재 평문 587)
- 첨부 발송 기능 구현
- `uncaughtException` 핸들러에서 `process.exit(1)` 으로 변경 (운영 단계 진입 시)

### 5. **메일서버 측 점검 (선택, 낮은 우선순위)**

`\Seen` 명령에 응답 안 하는 자체 호스팅 IMAP 서버 이슈는 Phase 2-c에서 코드 측 우회로 해결됨. 메일서버를 직접 고치고 싶으면:
- 메일서버 SW 종류 확인 (Dovecot? Cyrus? Postfix?)
- IMAP timeouts/locking 설정 확인
- 다중 client 동시 접속 시 lock 정책

지금은 코드가 IMAP flag와 무관하게 동작하므로 필수 아님.

---

## ✅ 현재 상태 — 워커 동작 확인

### 마지막 정상 동작 로그 (요약)

```
[mailcarrier-worker:personal] connected (folder=INBOX, mode=POLL)
[mailcarrier-worker:role] connected (folder=INBOX, mode=POLL)
[mailcarrier-worker:shared] connected (folder=INBOX, mode=POLL)
[mailcarrier-worker] listening on 3 inbox(es)…

[mailcarrier:shared] fetch: range=1:* (last_uid=0)
[mailcarrier:shared] fetch: msg #1 received uid=1 (+1054ms)
[mailcarrier:shared] skip — not in whitelist: pjazelpantoja@gmail.com
...
[mailcarrier:shared] fetch: msg #7 persistInbound done (event=yes) (+373ms)
[mailcarrier-worker:shared:4251c158] new inbound — from=contact@marinebiogroup.com
[mailcarrier-worker:shared:4251c158] processed → draft.id=a90d5600-89d5-43c4-a046-b305c4fd4f67
```

**메시지당 처리 시간**: 100~400ms (이전 10초 hang에서 대폭 단축).

### DB 검증 쿼리 (운영 모니터링용)

```sql
-- 1. UID 추적 상태 확인
SELECT kind, username, last_processed_uid, updated_at
FROM app.mailcarrier_state
ORDER BY kind;

-- 2. 최근 inbound 메일 확인
SELECT id, from_address, subject,
  external_data->>'mailcarrier_account_kind' AS imap_kind,
  ai_processing_status,
  created_at
FROM app.communications
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND direction = 'inbound'
  AND created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 20;

-- 3. 최근 draft 확인
SELECT d.id, d.classification_category, d.confidence_score, 
  d.status, d.requires_human_approval, d.auto_send_eligible,
  c.subject, c.from_address
FROM ai.drafts d
JOIN app.communications c ON c.id = d.inbound_communication_id
WHERE c.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND d.created_at > NOW() - INTERVAL '1 hour'
ORDER BY d.created_at DESC
LIMIT 20;
```

---

## 환경변수 현재 상태

```dotenv
# IMAP
MAILCARRIER_HOST=mail.marinebiogroup.com
MAILCARRIER_PORT=143
MAILCARRIER_USERNAME=contact@marinebiogroup.com   # fallback (env.ts required)
MAILCARRIER_PASSWORD=<rotated>                    # fallback (env.ts required)
MAILCARRIER_USE_IDLE=false
MAILCARRIER_INBOX_FOLDER=INBOX
MAILCARRIER_POLL_INTERVAL_SECONDS=30
MAILCARRIER_TLS_REJECT_UNAUTHORIZED=false
MAILCARRIER_POLL_KINDS=personal,role,shared

# Multi-account credentials
MAIL_PERSONAL_USERNAME=yunyoung.heo@marinebiogroup.com
MAIL_PERSONAL_PASSWORD=<rotated>
MAIL_PERSONAL_DISPLAY_NAME=YunYoung Heo
MAIL_ROLE_USERNAME=ceo@marinebiogroup.com
MAIL_ROLE_PASSWORD=<rotated>
MAIL_ROLE_DISPLAY_NAME=CEO
MAIL_SHARED_USERNAME=contact@marinebiogroup.com
MAIL_SHARED_PASSWORD=<rotated>
MAIL_SHARED_DISPLAY_NAME=Marinebio Group

# AI
ANTHROPIC_API_KEY=<rotated>
ANTHROPIC_MODEL_OPUS=claude-opus-4-7
ANTHROPIC_MODEL_HAIKU=claude-haiku-4-5-20251001
ANTHROPIC_MODEL_SONNET=claude-sonnet-4-6
OPENAI_API_KEY=<rotated, but quota exceeded>
OPENAI_EMBEDDING_MODEL=text-embedding-3-large

# Supabase
SUPABASE_SERVICE_ROLE_KEY=<rotated>
SUPABASE_DB_URL=postgresql://postgres:<rotated>@db.ogenmrgxwhpbfepeldqx.supabase.co:5432/postgres
SUPABASE_STORAGE_BUCKET_ATTACHMENTS=communications-attachments
```

---

## 이번 세션의 교훈

1. **가시성 패치가 진단의 핵심** — Phase 2-b의 tick 로그 + process handlers 추가로 hang 위치를 정확히 짚을 수 있었음. 진단 로그 없이는 추측만 가능.

2. **자체 호스팅 IMAP 서버는 표준 명령 응답 불안정** — `messageFlagsAdd(\Seen)` 5분 socket timeout 패턴이 결정적. 코드 측 우회(UID 추적)가 메일서버 점검보다 더 robust.

3. **AI 파이프라인의 graceful degradation 중요** — OpenAI quota 소진 시에도 워커가 죽지 않고 fallback으로 draft 생성. 운영 환경에서 외부 의존성 장애 대응의 본보기.

4. **보안 사고 대응 절차 확립 필요** — 채팅에 키 노출 시 즉시 rotation. 이번에 5개 secret + DB/메일 password rotation 완료. 향후 환경변수 출력 시 값은 마스킹할 것 (`sk-ant-***` 같이).

5. **TypeScript 컴파일 known errors는 빨리 정리할수록 이득** — 11개를 그대로 두면 새 에러 발견이 어려움. 정리하니 30분에 끝남.

6. **들여쓰기 일관성** — 패치 코드를 들여쓰기 0으로 붙여넣으면 TypeScript는 컴파일하지만 가독성 망함. 클래스 멤버는 2-space로 통일.

---

## 다음 세션 추천 시작 순서

1. **OpenAI 결제/플랜 업그레이드** (실제 결제 필요 — 사용자 액션)
2. 새 OpenAI key 발급 후 `.env.local` 업데이트
3. 워커 재시작 → embedding 정상 동작 확인 (RAG 작동)
4. Prompt 튜닝 — classifier/drafter output validation 통과
5. `env.ts` conditional schema (15분)
6. RLS / SMTP STARTTLS / 첨부 발송 — 운영 준비 (별도 큰 작업)
