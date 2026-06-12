# 설계 — Multi-Account Mail Hub (SaaS, Outlook 대체)

작성: 2026-06-12 / 목표: 본인 소유 메일 계정 N개(10+)를 테이블에 등록해 송·수신 모두 URM에서 처리. 외부 메일 클라이언트(Outlook) 불필요.

## 현재 상태 (이미 부분 구현됨 — 이어서 완성)
- `app.inbound_mailboxes` 존재, 6행 등록. IMAP 수신만 테이블화됨.
  - 컬럼: id, organization_id, address, label, imap_host, imap_port, use_tls, password_encrypted(bytea), is_active, created_at, updated_at
  - 워커(mailcarrier.ts) Phase 3 경로: options.account로 DB 계정 IMAP 연결, kind='account', password_encrypted 복호화. 이미 동작.
- 발신은 아직 단일 릴레이 — TABS_MAILER_* env, from은 contact@marinebiogroup.com 하나뿐.
- communications에 수신 계정 FK 없음 (to_addresses 배열, reply_to_address만).
- 기존 6계정:
  - ceo@marinebiogroup.com (mail.marinebiogroup.com:143 tls)
  - contact@marinebiogroup.com (143 no-tls)  ← 현 발신 from
  - yunyoung.heo@marinebiogroup.com (143 no-tls)
  - ceo@marinepad.com (mail.marinepad.com:143 tls, label=marinepad)
  - marinegift4u@gmail.com (imap.gmail.com:143 tls, label=Gmail)
  - marinepad@naver.com (imap.naver.com:143 tls, label=Naver)
- 보안 점검 필요: 포트 143은 IMAP 평문/STARTTLS. 암호화 IMAP은 993이 표준. contact@/yunyoung.heo@는 use_tls=false(평문). Gmail/Naver는 보통 993 IMAPS + 앱비밀번호 필요. 등록 UI에서 포트/TLS 검증 필요.

## 결정 사항 (확정)
- 모든 계정에 IMAP(수신)+SMTP(발신) 정보를 다 입력 (Outlook 방식). 계정 = 송수신 단위.
- 발신 From 규칙:
  1. **회신(reply)**: 원래 메일을 받은 계정으로 자동 선택 (기본 동작, 가장 중요).
  2. **신규 발신**: is_default 계정.
  3. 두 경우 모두 발신 직전 From 드롭다운으로 수동 변경 가능.

## 스키마 설계

### 1) 테이블 확장 — inbound_mailboxes → mail_accounts 로 의미 확장
이름은 `mail_accounts`로 rename 권장(수신 전용 오해 방지). rename이 부담되면 기존 이름 유지하고 컬럼만 추가.

추가 컬럼:
- display_name text         -- From 표시명 (예: "YunYoung Heo")
- imap_username text         -- 보통 address와 같으나 분리 (Gmail 등)
- smtp_host text
- smtp_port int
- smtp_use_tls boolean
- smtp_username text
- smtp_password_encrypted bytea   -- IMAP과 다를 수 있어 별도 (같으면 동일값)
- smtp_auth_method text default 'login'  -- plain/login
- is_default boolean default false
  -- 부분 unique index로 org당 1개만 true 강제:
  -- CREATE UNIQUE INDEX uq_mail_accounts_default ON app.mail_accounts(organization_id) WHERE is_default;

암호화: 기존 password_encrypted가 pgp_sym_encrypt 패턴(calendar_connections와 동일)을 쓰므로 smtp도 같은 키/방식.

### 2) communications에 수신 계정 FK 추가 (회신 자동선택 핵심)
- mail_account_id uuid NULL REFERENCES app.mail_accounts(id)
- 워커가 inbound persist 시 "어느 계정으로 폴링했는지"를 이 컬럼에 기록.
- 회신 작성 시: communications.mail_account_id → 그 계정을 From 기본값으로.
  (FK가 비어있는 과거 메일은 to_addresses에서 우리 계정 주소 역매칭으로 fallback.)

## 코드 변경 범위
1. **마이그레이션** (PRE/POST-CHECK, source 태그): 컬럼 추가 + 부분 unique index + communications.mail_account_id + 기존 6행에 smtp 정보 backfill(도메인 메일은 mail.<domain>:587, gmail은 smtp.gmail.com:587, naver는 smtp.naver.com:587 — 실제 값은 사용자 확인).
2. **워커 (mailcarrier.ts / mailcarrier-worker.ts)**: DB 계정 목록을 폴링 대상으로 (이미 account 경로 있음 — 모든 is_active 계정을 순회하도록 일반화). inbound persist 시 mail_account_id 기록.
3. **발신 (send-outbound.ts)**: 단일 TABS_MAILER → 계정별 SMTP 연결. From 라우팅(reply=수신계정, 신규=default). 계정별 SMTP 자격증명 복호화.
4. **발신 UI (compose-email-dialog.tsx)**: From 드롭다운을 mail_accounts에서 로드. reply면 수신계정 프리셀렉트, 신규면 default.
5. **등록 UI (신규)**: Settings > Mail Accounts. 계정 CRUD (IMAP+SMTP+display_name+is_default). 비밀번호 입력 시 서버에서 암호화 저장. 연결 테스트 버튼(IMAP/SMTP 핸드셰이크) 권장.
6. **env 정리**: MAIL_PERSONAL/ROLE/SHARED, TABS_MAILER 단일 from은 점진 폐기(테이블로 대체). 호환 위해 단계적.

## 단계별 진행 (마이그레이션부터, 안전 우선)
- **Step 1**: 스키마 마이그레이션 (컬럼 추가 + FK + index). 기존 동작 무영향(새 컬럼은 nullable/기본값). 6행 smtp backfill.
- **Step 2**: 워커가 mail_account_id 기록 (수신 측). 화면엔 변화 없지만 회신 자동선택의 데이터 기반 마련.
- **Step 3**: send-outbound 계정별 SMTP + From 라우팅. (이 단계가 가장 위험 — 발신 경로 변경. 기존 contact@ 발신을 default 계정으로 매핑해 동작 보존.)
- **Step 4**: compose UI From 드롭다운 + reply 프리셀렉트.
- **Step 5**: Settings 등록 UI (CRUD + 연결 테스트).
- 각 Step tsc 게이트 통과 + 배포 확인 후 다음 Step.

## 확정 필요 (다음 세션 시작 시 사용자에게)
- 각 계정의 SMTP 정보 (host/port/tls/username). 특히 도메인 메일(mail.marinebiogroup.com)의 발신 포트가 587 STARTTLS인지, Gmail/Naver는 앱 비밀번호 발급 여부.
- IMAP 포트 143 → 993 전환 여부 (보안). 현 평문(use_tls=false) 계정 점검.
- 테이블명 rename(mail_accounts) 진행 여부.
