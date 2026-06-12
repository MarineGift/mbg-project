# HANDOFF — Multi-Account Mail Hub (Step 1 완료, Step 2~5 남음)

작성: 2026-06-12 (집 삼성 랩탑 SS_LAPTOP-HEO)
목표: 본인 소유 메일 계정 N개(현재 6, 10+ 예정)를 테이블에 등록해 송·수신 모두 URM에서 처리. 외부 메일 클라이언트(Outlook) 불필요.
참고 설계서: docs/DESIGN_multi_account_mail_2026-06-12.md (전체 5-step 설계)

## 확정 사항 (사용자)
- 모든 계정 IMAP(수신) + SMTP(발신) 정보 등록. 계정 = 송수신 단위 (Outlook 방식).
- 수신 IMAP: 포트 143, TLS 없음 (도메인 메일). Gmail/Naver는 imap.gmail.com / imap.naver.com:143.
- 발신 SMTP: mail.<도메인>:587, **STARTTLS 미사용 (smtp_use_tls=false)**. Gmail/Naver는 smtp.gmail.com / smtp.naver.com:587.
- SMTP 비밀번호 = IMAP 비밀번호 (같은 계정). 암호값 재사용.
- 기본 발신 계정(is_default): yunyoung.heo@marinebiogroup.com.
- 발신 From 규칙: (1) 회신 → 원래 받은 계정 자동선택 [기본], (2) 신규 → is_default, (3) 둘 다 발신 직전 수동 변경 가능.

## Step 1 — 스키마 (완료, DB 반영됨, 코드 변경 없음)
SQL: step1_mail_accounts_schema_2026-06-12.sql (+ 후속 STARTTLS off UPDATE)
- app.inbound_mailboxes 컬럼 추가: display_name, imap_username, smtp_host, smtp_port, smtp_use_tls, smtp_username, smtp_password_encrypted, smtp_auth_method('login'), is_default.
- 부분 unique index uq_inbound_mailboxes_default (org당 is_default 1개).
- app.communications.mail_account_id uuid + FK fk_communications_mail_account → inbound_mailboxes(id) ON DELETE SET NULL + index ix_communications_mail_account.
- 6계정 backfill 완료: smtp_username=address, smtp_host=mail.<domain>(gmail/naver는 provider), smtp_port=587, smtp_use_tls=false, smtp_password_encrypted=password_encrypted 복사.
- POST-CHECK 통과: accounts_smtp_ready=6, default=yunyoung.heo@marinebiogroup.com, mail_account_fk=1.

현재 6계정:
| address | imap | smtp | default |
|---|---|---|---|
| yunyoung.heo@marinebiogroup.com | mail.marinebiogroup.com:143 no-tls | mail.marinebiogroup.com:587 no-tls | YES |
| ceo@marinebiogroup.com | :143 tls | :587 no-tls | |
| contact@marinebiogroup.com | :143 no-tls | :587 no-tls | |
| ceo@marinepad.com | mail.marinepad.com:143 tls | :587 no-tls | |
| marinegift4u@gmail.com | imap.gmail.com:143 tls | smtp.gmail.com:587 no-tls | |
| marinepad@naver.com | imap.naver.com:143 tls | smtp.naver.com:587 no-tls | |

## 암호화 방식 (Step 3에서 SMTP 복호화에 필요)
- 키: env CALENDAR_TOKEN_ENCRYPTION_KEY (calendar 토큰과 공용).
- 복호화 RPC: app.decrypt_inbound_mailbox_password({ encrypted, enc_key }).
- mailcarrier.ts decryptAccountPassword()가 IMAP password_encrypted에 이미 사용 중.
- SMTP는 같은 암호값 재사용이라 같은 RPC로 복호화 가능 (또는 smtp 전용 RPC 추가 불필요).

## 남은 작업 (Step 2~5, 다음 세션) — 마이그레이션 외 모두 코드

### Step 2 — 워커가 수신 시 mail_account_id 기록 (저위험)
- 파일: src/lib/email/mailcarrier.ts (persistInbound), src/workers/mailcarrier-worker.ts
- 워커는 이미 계정별(kind='account', this.account.id)로 폴링 중. persistInbound 시 현재 계정의 inbound_mailboxes.id를 communications.mail_account_id에 기록하도록 추가.
- 회신 자동선택의 데이터 기반. 화면 변화 없음.

### Step 3 — 계정별 SMTP 발신 + From 라우팅 (★최고위험: 발신 경로 교체)
- 파일: src/lib/email/send-outbound.ts (현재 단일 TABS_MAILER 릴레이, from=contact@marinebiogroup.com만)
- 변경: From 계정 결정 → 그 계정의 inbound_mailboxes row에서 smtp_host/port/use_tls/username + smtp_password_encrypted 복호화 → 계정별 SMTP 연결로 발신.
- From 결정 로직: reply(in_reply_to/thread 존재)면 원본 communications.mail_account_id의 계정, 아니면 is_default 계정. 호출부에서 명시적 accountId 오면 그것 우선.
- 기존 contact@ 단일 발신 동작은 default를 yunyoung.heo로 바꿨으므로 거동이 달라짐 — 발신 테스트 필수.
- ⚠️ Gmail/Naver는 587 STARTTLS/SSL이 사실상 필수 + 앱비밀번호 필요. 평문(use_tls=false) 발신은 provider가 거부할 가능성 큼. 도메인 메일(mail.marinebiogroup.com 등) 먼저 검증하고, gmail/naver는 별도 처리(use_tls=true + 앱비밀번호 재등록).
- TABS_MAILER env 경로는 호환 위해 당분간 유지(폴백), 점진 제거.

### Step 4 — compose UI From 드롭다운 + reply 프리셀렉트 (중위험)
- 파일: src/components/email/compose-email-dialog.tsx
- From 드롭다운을 inbound_mailboxes(is_active) 목록에서 로드. 현재 From은 props.from 하드코딩/단일.
- reply로 열릴 때: 원본 메일의 mail_account_id 계정을 프리셀렉트. 신규면 is_default.
- 발신 시 선택된 accountId를 send-outbound로 전달.

### Step 5 — Settings 계정 등록 UI (CRUD)
- 신규 페이지: Settings > Mail Accounts (기존 email-whitelist 화면 패턴 참고).
- 계정 추가/수정/삭제: address, display_name, imap host/port/tls/username, smtp host/port/tls/username, password(들), is_default.
- 비밀번호는 서버 action에서 pgp_sym_encrypt로 암호화 저장 (RPC 신규: encrypt_*). 입력 후 평문은 응답에 절대 안 실음.
- 연결 테스트 버튼 권장(IMAP/SMTP 핸드셰이크).
- is_default 변경 시 기존 default 해제(부분 unique index가 강제하므로 트랜잭션 처리).

## 진행 원칙
- Step 단위로 tsc --noEmit(exit 0) 확인 후 commit, 그 다음 Step.
- commit 전 반드시 tsc 게이트 (tsc는 git commit을 자동으로 막지 않음).
- 두 머신(집 삼성/회사 Lenovo) — 작업 시작 전 git pull, 끝나고 git push.
- 위험한 Step 3은 도메인 메일로 먼저 발신 검증 후 gmail/naver.

## 보안 부채 (메모)
- 도메인 메일 IMAP 143 + 일부 use_tls=false(평문). SMTP 587 평문. 운영 보안상 추후 암호화 포트(993 IMAPS / 465 SMTPS or STARTTLS) 전환 검토.

## 참고 (오늘 앞선 작업, 이미 배포됨)
- 메일 인입 정상화: communications.module 42703 크래시 루프 수정(9a78ef6), 토큰 치환 회귀(244a8eb), self party + enum 정리(2c28d17), MailCarrier UID 체크포인트 개선(d4d3270).
- org: b25de8f2-1020-482f-9012-183f63883169
