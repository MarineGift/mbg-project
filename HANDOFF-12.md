# HANDOFF-12 — mbg-project (클라우드 메일 수·발신 완성 / 다음 세션 = 발송 보안 + 잔여 정리)

작성: 2026-06-02. 이번 세션 = **클라우드 발송·수신 양방향 작동 완료** + Sent Read 컬럼/타임존 설정 + 바운스 노이즈 차단.
막힌 곳 없음. 다음 세션 = 평문 발송 보안(SPF/DKIM·STARTTLS)과 잔여 정리 항목들.

## 0. 프로젝트 좌표 (변경 없음)
- repo: MarineGift/mbg-project, branch: marinebiogroup, local: C:\dev\mbg-project
- stack: Next.js 14.2 / Supabase (project ogenmrgxwhpbfepeldqx), app 스키마
- 환경: Windows PowerShell 5.x. 한국어 대화 / 코드·SQL·콘솔은 영어.
- org_id: b25de8f2-1020-482f-9012-183f63883169
- 인프라: Railway project "joyful-celebration" / env "production". **현재 Pro 플랜.**
  - service **mbg-project** (web): 도메인 **https://urm.marinebiogroup.com** (커스텀), start = `npm run start`
  - service **lucky-patience** (worker): start = `npx tsx src/workers/mailcarrier-worker.ts`. Unexposed.

## 1. 이번 세션 핵심 결과 (전부 커밋·배포됨)

### 1-1. 클라우드 발송 복구 (가장 큰 건)
- 증상: 클라우드에서 발송 시 `Connection timeout`. 로컬은 정상.
- 원인 1 (egress): **Railway는 Pro 미만 플랜에서 outbound SMTP(25/465/587)를 차단.** Hobby였음 → **Pro 업그레이드 + 재배포**로 해제.
- 원인 2 (TLS, 진짜 범인): mail.marinebiogroup.com(**TABS Mail Server**)이 **STARTTLS를 지원하지 않음.** 587 EHLO capability에 STARTTLS 없음 → 코드의 `requireTLS:true`가 STARTTLS 강제 → `503 5.5.1 Bad sequence of commands`. 465(implicit TLS)는 **timeout**(미개방).
- 해결: **587 평문 + STARTTLS 미전송.** env `TABS_MAILER_PORT=587`, `TABS_MAILER_USE_TLS=false`.
  - 코드 로직(`tabs-mailer.ts` `baseSmtpOptions`): `ignoreTLS = !USE_TLS`. 즉 USE_TLS=false → ignoreTLS=true → STARTTLS 안 보냄. **이 서버는 이게 정답.**
  - 진리표: 587+USE_TLS=true=STARTTLS(이 서버 거부), 587+USE_TLS=false=평문(정답), 465+true=implicit(서버 미개방=timeout).
- ⚠️ **이건 평문 발송**임. AUTH 자격증명·본문이 비암호화로 외부 인터넷 통과 → 다음 세션 보안 과제.

### 1-2. 커스텀 도메인
- web 서비스에 `urm.marinebiogroup.com` 연결.
- GoDaddy DNS: CNAME `urm` → `v7cr6h8k.up.railway.app` + TXT `_railway-verify.urm` = railway-verify=... (Railway가 둘 다 요구).
- Railway가 Let's Encrypt 자동 발급. `@`(52.37.165.222 Readdy)·`www`는 별개로 그대로 둠 — `urm` 서브도메인이라 충돌 없음.
- 후속: web `NEXT_PUBLIC_APP_URL`을 `https://urm.marinebiogroup.com`으로 두면 픽셀·절대URL이 새 도메인 사용(빌드타임 인라인 → 변경 시 재빌드).

### 1-3. Sent 목록 Read 컬럼 + 절대시각 + 타임존 설정
- `/sent` = `fetchInbox` → `InboxTable` 렌더. `open-status.ts`의 `fetchOpenStatuses(ids)`가 communication_id별 `{firstOpenedAt, openCount}` batch 반환 → 목록에 노출.
- `InboxTable`: outbound 행에 `Read · 2026-06-02 06:05 CDT`(열람) / `Sent`(미열람). `Intl.DateTimeFormat`에 명시 timeZone → 서버/클라 동일(하이드레이션 안전).
- **타임존 설정**: `app.users.timezone text not null default 'America/Chicago'` 컬럼 추가(SQL 적용 완료). Settings → Profile에 드롭다운(US Central 기본, NY/LA/Seoul/Tokyo/London/UTC). 공유 상수 `src/lib/constants/timezones.ts`로 검증·옵션 단일화. `sent/page.tsx`가 프로필 timezone 읽어 `<InboxTable timeZone>`로 전달.
- 커밋 `bf11130`.

### 1-4. 수신 (IMAP MailCarrier) — 정상 확인
- 워커는 **부팅 시 `app.inbound_mailboxes`(active)** 를 읽어 폴링(없으면 env 폴백). 계정 추가/삭제 후 **워커 재시작 필수.**
- IMAP 서버도 발송과 동일: **143 평문, AUTH=PLAIN, STARTTLS 없음.** 993 implicit=timeout.
- 현재 폴링 6계정(모두 active): marinegift4u@gmail.com(imap.gmail.com:993), marinepad@naver.com(imap.naver.com:993), ceo@marinepad.com(mail.marinepad.com:143), contact@/yunyoung.heo@/ceo@marinebiogroup.com(mail.marinebiogroup.com:143).
- **`ceo@marinebiogroup.com`만 IMAP 인증 실패**(`NO Authentication exchange failed`). 나머지 5개 connected. → 비번 재등록 또는 삭제 필요.
- `inbound_mailboxes.password_encrypted`는 **bytea(암호화)**. SQL 직접 INSERT 금지. **Settings → Inbound Mailboxes 화면에서만 등록**(앱이 올바르게 암호화).

### 1-5. Whitelist + 바운스 노이즈 차단
- `app.email_whitelist` 컬럼: `pattern`, `kind`('address'|'domain'), `notes`, `is_active`. 등록 발신자만 inbox 진입(미등록=skip). **설계대로 정상.**
- 현재 등록: domain= gmail.com, naver.com, marinebiogroup.com / address= ceo@marinepad.com, contact@marinebiogroup.com, marinegift4u@gmail.com, marinepad@naver.com.
- 문제였던 것: `postmaster@marinebiogroup.com` 바운스가 marinebiogroup.com 도메인 whitelist로 통과 → inbound마다 AI draft 생성 → AI Drafts/Inbox 폭증. (무한 루프 아님: `AI_AUTO_SEND_ENABLED`=false라 자동 재발송 없음. 백필+바운스 누적이었음.)
- 조치 A: 바운스 18건 soft-delete (`deleted_at=now()`, postmaster@ + '전송 실패').
- 조치 B: **`processor.ts` 가드 추가** — 발신자 postmaster@/mailer-daemon@/no-reply@ 또는 제목 NDR 패턴(전송 실패/반송/Undeliverable/Mail delivery failed/Delivery Status Notification 등)이면 분류·draft·AI 호출 전부 skip, `external_data.ai_processing_status='skipped_system'`. 토큰 0, AI Drafts 안 더럽힘. 커밋 `9fae896`.

## 2. 핵심 교훈 / 함정
- **TABS Mail Server는 SMTP·IMAP 모두 평문 전용**(STARTTLS/implicit TLS 미지원). 발송 587/USE_TLS=false, 수신 143 평문.
- **Railway**: Pro 미만 = outbound SMTP 차단. Static Outbound IP는 Pro 전용(공유 IP 3개). 커스텀 도메인은 CNAME+TXT 둘 다 필요, apex는 CNAME flattening 필요(서브도메인 권장).
- **env `z.union([z.boolean(), z.enum(['true','false'])])` 변수**(`TABS_MAILER_USE_TLS` 등): 값은 **소문자·무따옴표·무공백** 정확 일치. 틀리면 빌드 시 `invalid_union`.
- **PS 5.x `Split-Path`**: `-LiteralPath`와 `-Parent` 동시 사용 불가 → `-Parent`만.
- `inbound_mailboxes` 변경 후 **워커 재시작** 필수(부팅 시 1회 로드). 단 git push로 워커 자동 재배포되면 그게 재시작 역할.

## 3. 다음 세션 = 잔여 과제 (우선순위순)

### A. 평문 발송 보안 (최우선, 바운스 552의 근본 원인)
- 현재 587 평문 발송 + SPF/DKIM 미흡 → 일부 수신서버가 `552 5.7.0`으로 회신 거부 → postmaster 바운스 발생.
- 택1: (1) **서버측 STARTTLS 또는 465 활성화 요청**(TABS 운영) → 켜지면 `USE_TLS=true`(587 STARTTLS) 또는 `PORT=465`로 되돌려 암호화. (2) **발신 도메인 SPF/DKIM 정비**(marinebiogroup.com). (3) 장기적으로 HTTP-API 발송 서비스(Resend 등).
- 참고: 도메인 DNS = GoDaddy. 현재 SPF `v=spf1 ip4:49.254.118.167 ~all`.

### B. `{{PII_001}}` 머지/마스킹 토큰 본문 미치환
- inbound 표시/AI draft에서 `{{PII_001}}` 토큰이 복원 안 되고 노출. `pii-masker`(processor가 `hasUnrestoredTokens`/`findUnrestoredTokens` 사용) 복원 로직 점검 필요. processor는 미복원 토큰 감지 시 requiresHumanApproval=true로 막지만, **표시 단계**에서 토큰이 그대로 보임.

### C. `ceo@marinebiogroup.com` 메일박스 IMAP 인증 실패
- Settings → Inbound Mailboxes에서 비번 재등록 또는 (안 쓰면) 삭제 → 워커 재시작.

### D. gmail.com / naver.com whitelist 정책 (보류 중)
- 도메인 통째 허용이라 그 메일함 외부/스팸 메일 다 통과(백필 노이즈 주원인). 개별 주소만 받으려면 도메인 행 삭제(개별 주소는 이미 등록됨). 운영 판단 필요.

### E. 워커 로그 `host=undefined` 표기 버그
- DB 경로에서 로그가 `env.MAILCARRIER_HOST`(미사용) 참조 → `connecting to IMAP undefined:143`. 실제 연결은 DB `imap_host`로 정상. 로그 문자열만 수정(account면 mb.host 표시).

### F. 잡정리
- `NEXT_PUBLIC_APP_URL`을 `https://urm.marinebiogroup.com`으로 통일 + 재빌드.
- whitelist `<보낸도메인>` 쓰레기 행 삭제 확인(템플릿 플레이스홀더가 그대로 INSERT됐던 것).
- postmaster@ 등 시스템 발신자 whitelist 제외 여부(가드로 draft는 막았으나 inbound row는 생성됨).
- /sent 화면에서 inbox 대비 대량 누적 시 페이지네이션/정렬 점검.

## 4. 주요 커밋 (이번 세션)
- `bf11130` feat(profile): user timezone setting; sent list read time in selected tz (default US Central)
- `9fae896` feat(processor): skip classification/draft for bounce and system (postmaster/mailer-daemon) mail
- (이전) Sent Read 컬럼 page.tsx/inbox-table.tsx, env 패치 등.

## 5. 다음 세션 시작 지점
1. 배포 상태 확인(lucky-patience / mbg-project 둘 다 ACTIVE), 워커 로그에서 `skipped system/bounce mail` 동작 확인.
2. A(발송 보안) 착수: TABS 운영에 STARTTLS/465 활성 가능 여부 확인 → 가능하면 암호화 발송으로 전환, 아니면 SPF/DKIM 정비.
3. B~F 잔여 정리.
