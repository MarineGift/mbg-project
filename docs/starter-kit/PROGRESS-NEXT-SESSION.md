# 다음 세션 시작 — 핸드오프

> 이전 세션 종료 시점: Phase 2-b (IMAP 3 box polling) 코드 적용 + 컴파일 통과까지 완료, 워커 재시작 + 검증 대기.

---

## 첫 메시지 (그대로 복사해서 새 채팅에 붙여넣기)

```
Phase 2-b (IMAP 3 box polling) 진행 중. 
mailcarrier.ts + mailcarrier-worker.ts 새 버전 적용, env.ts에 MAILCARRIER_POLL_KINDS 추가, 
npx tsc --noEmit 통과(기존 known 11개만). 

남은 작업:
1. .env.local에 MAILCARRIER_POLL_KINDS=personal,role,shared 추가 확인
2. 워커 재시작 → 3 inbox 연결 로그 확인
3. 각 계정으로 테스트 메일 → 큐 검증
4. Outlook IDLE 충돌 가능성 (ceo@) 대응

이전 세션 핸드오프 문서 첨부합니다.
```

문서를 첨부 (이 PROGRESS-NEXT-SESSION.md 파일).

---

## 프로젝트 컨텍스트 (필수)

- **Repo**: https://github.com/MarineGift/mbg-project
- **Branch**: marinebiogroup
- **Local**: C:\dev\mbg-project
- **Org ID**: b25de8f2-1020-482f-9012-183f63883169 (MBG Project)
- **User ID**: 551fc4a0-b365-47eb-bf2f-0c3f594001c0 (marinegift4u@gmail.com)
- **Stack**: Next.js 14.2.13, Supabase, Anthropic SDK (Opus 4.7/Haiku 4.5/Sonnet 4.6), TABS Mailer, MailCarrier
- **언어**: 한국어 응답
- **메일서버**: mail.marinebiogroup.com (자체 호스팅)
  - IMAP: 143 (STARTTLS, self-signed cert 허용)
  - SMTP: 587 (평문)

---

## 3개 계정

| Kind | Username | Display Name |
|------|----------|--------------|
| personal | yunyoung.heo@marinebiogroup.com | YunYoung Heo |
| role | ceo@marinebiogroup.com | CEO |
| shared | contact@marinebiogroup.com | Marinebio Group |

---

## 완료된 작업 (참고)

### Phase 1 — 다중 발신 주소 SMTP ✅ E2E 검증 통과
- DB 014: app.users에 email_personal/role/shared
- env.ts: MAIL_*_USERNAME/PASSWORD/DISPLAY_NAME × 3
- types/email.ts: SendingAddressKind, sendingAddressKind?
- lib/email/tabs-mailer.ts: kind별 transporter Map 캐시 + verifyAll
- lib/actions/drafts.ts: approveDraft에 sendingAddressKind 전달
- components/drafts/approve-draft-dialog.tsx: select box
- 검증: contact@ inbox 수신 → AI 처리 → /drafts → Approve → kind 선택 → 발송 → Gmail 도착 (From=contact@marinebiogroup.com)

### Phase 2-a — 화이트리스트 ✅ 검증 통과
- DB 015: app.email_whitelist 테이블 + MBG 초기 시드 2건
  - marinebiogroup.com (domain) — 자기 도메인
  - marinegift4u@gmail.com (address) — 테스트용 외부 주소
- lib/email/whitelist.ts: isFromAllowedSender(supabase, organizationId, fromAddress)
- lib/email/mailcarrier.ts: persistInbound 진입점에 화이트리스트 체크
- 검증: 본인 Gmail 메일 통과, 광고 메일 자동 차단
- 기존 큐 정리: 5개 외부 마케팅 메일 일괄 rejected 처리

### Phase 2-b — IMAP 3 box polling ⏳ 코드 완성, 검증 대기
- env.ts: MAILCARRIER_POLL_KINDS 추가 (zod transform으로 ['personal','role','shared'] 배열 파싱)
- lib/email/mailcarrier.ts: 생성자 kind? 옵션, resolveCredentials(kind), kind 식별자
- workers/mailcarrier-worker.ts: kinds 길이만큼 MailCarrierClient 인스턴스 병렬 IDLE
- npx tsc --noEmit: 기존 known 11개만 (auth.ts × 2, simulate-inbound.ts × 9)
- **다음 단계: 워커 재시작 + 3 inbox 검증**

---

## 다음 세션 첫 작업 — 워커 검증

### Step 1: .env.local 확인

```powershell
Select-String -Path ".env.local" -Pattern "MAILCARRIER_POLL_KINDS"
```

기대: `MAILCARRIER_POLL_KINDS=personal,role,shared` 한 줄.

없으면 .env.local에 추가:
```dotenv
# Phase 2: 3 box polling
MAILCARRIER_POLL_KINDS=personal,role,shared
```

### Step 2: 워커 재시작

```powershell
# 기존 워커 터미널 Ctrl+C → 다시 실행
npm run worker:mailcarrier
```

기대 로그 (3 inbox 모두 연결 성공):
```
[mailcarrier-worker:personal] connecting to IMAP mail.marinebiogroup.com:143 (user=yunyoung.heo@marinebiogroup.com)
[mailcarrier-worker:personal] connected (folder=INBOX, mode=IDLE)
[mailcarrier-worker:role] connecting to IMAP mail.marinebiogroup.com:143 (user=ceo@marinebiogroup.com)
[mailcarrier-worker:role] connected (folder=INBOX, mode=IDLE)
[mailcarrier-worker:shared] connecting to IMAP mail.marinebiogroup.com:143 (user=contact@marinebiogroup.com)
[mailcarrier-worker:shared] connected (folder=INBOX, mode=IDLE)
[mailcarrier-worker] listening on 3 inbox(es)… (Ctrl+C to stop)
```

### Step 3: 각 inbox 테스트 메일

본인 Gmail에서 → 각 계정으로 메일 발송:

| 발송 to | 기대 워커 로그 |
|---|---|
| yunyoung.heo@marinebiogroup.com | `[mailcarrier-worker:personal:xxx] new inbound — from=marinegift4u@gmail.com ...` |
| ceo@marinebiogroup.com | `[mailcarrier-worker:role:xxx] new inbound — from=marinegift4u@gmail.com ...` |
| contact@marinebiogroup.com | `[mailcarrier-worker:shared:xxx] new inbound — from=marinegift4u@gmail.com ...` |

3개 모두 `/drafts` 큐에 표시되어야 함.

### Step 4: DB 검증

```sql
SELECT 
  id, from_address, subject,
  external_data->>'mailcarrier_account_kind' AS imap_kind,
  external_data->>'mailcarrier_account_username' AS imap_user,
  created_at
FROM app.communications
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND direction = 'inbound'
ORDER BY created_at DESC
LIMIT 6;
```

기대: 가장 최근 3개 행이 각각 imap_kind=personal/role/shared로 표시.

---

## ⚠️ 알려진 이슈 — Outlook IDLE 충돌 (ceo@)

ceo@를 Outlook으로 사용 중이면 IMAP IDLE 충돌 가능:
- 워커 role 연결 실패 (Authentication failed 또는 hangs)
- 또는 Outlook이 새 메일을 먼저 read 처리 → 워커 못 잡음

### 해결책 (선택)
1. **Outlook에서 ceo@ 계정 제거 또는 비활성화** (가장 깔끔)
2. **Outlook을 POP3로 전환** (IMAP 충돌 없음)
3. **워커를 polling 모드로 전환**: .env.local에서 `MAILCARRIER_USE_IDLE=false`
4. **별도 ceo-bot 계정 만들어 메일서버 측 룰로 ceo→ceo-bot 복제**

---

## Phase 2 끝나면 — 우선순위

1. **prompt 튜닝** — classifier/drafter fallback 모드 탈피 (현재 category='other', confidence=0.3)
   - 위치: ai.agents.system_prompt
   - 작업: validateClassificationOutput 스키마와 일치하도록 system_prompt 수정
   - 예상: 1-2시간

2. **운영 준비**
   - sql/010_rls_policies.sql 적용
   - SMTP STARTTLS 활성화 (현재 평문 587)
   - OpenAI quota 확보 (RAG embedding)
   - 첨부 발송 기능 (단계 A: 받은 첨부 그대로 회신)

3. **TypeScript strict 정리** (낮음)
   - auth.ts:41 × 2
   - simulate-inbound.ts:176 × 9

---

## 환경변수 .env.local 현재 상태

```dotenv
# 메일서버 공통
MAILCARRIER_HOST=mail.marinebiogroup.com
MAILCARRIER_PORT=143
MAILCARRIER_USE_IDLE=true
MAILCARRIER_INBOX_FOLDER=INBOX
MAILCARRIER_TLS_REJECT_UNAUTHORIZED=false
MAILCARRIER_POLL_INTERVAL_SECONDS=30

# Phase 2: 3 box polling
MAILCARRIER_POLL_KINDS=personal,role,shared

# Phase 1 fallback (POLL_KINDS 빈 값 시만 사용)
MAILCARRIER_USERNAME=contact@marinebiogroup.com
MAILCARRIER_PASSWORD=<...>

# SMTP 공통
TABS_MAILER_HOST=mail.marinebiogroup.com
TABS_MAILER_PORT=587
TABS_MAILER_USE_TLS=false
TABS_MAILER_AUTH_METHOD=login
TABS_MAILER_USE_MOCK=false

# SMTP + IMAP 자격증명 (3개 계정 공통 재사용)
MAIL_PERSONAL_USERNAME=yunyoung.heo@marinebiogroup.com
MAIL_PERSONAL_PASSWORD=<...>
MAIL_PERSONAL_DISPLAY_NAME=YunYoung Heo
MAIL_ROLE_USERNAME=ceo@marinebiogroup.com
MAIL_ROLE_PASSWORD=<...>
MAIL_ROLE_DISPLAY_NAME=CEO
MAIL_SHARED_USERNAME=contact@marinebiogroup.com
MAIL_SHARED_PASSWORD=<...>
MAIL_SHARED_DISPLAY_NAME=Marinebio Group
```
