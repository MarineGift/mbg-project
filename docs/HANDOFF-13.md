# HANDOFF-13 — mbg-project / marinebiogroup

작성: 2026-06-02 (KST 기준 야간 세션)
브랜치: `marinebiogroup` / 로컬: `C:\dev\mbg-project`
Supabase: `ogenmrgxwhpbfepeldqx` / org: `b25de8f2-1020-482f-9012-183f63883169`
Railway: web=`mbg-project` (urm.marinebiogroup.com), worker=`lucky-patience`, project=`joyful-celebration`

---

## TL;DR — 이번 세션 결과

HANDOFF-12 백로그(3절)를 전부 처리했고, **세션 최대 사건은 "커밋은 했으나 push 누락"** 이었다.
이번 세션 코드 5커밋이 GitHub에 안 올라가 있어서 Railway(web+worker)가 옛 코드만 빌드 →
"코드는 고쳤는데 증상 그대로"가 한참 이어졌다. `git push` + 누락 2파일 커밋 후 전부 해소.

**그린(완료·검증):** B(PII), A(Gmail 552), E(host undefined), C(Sent 시각), 2(상세뷰 시각), 1(Security Advisor), F(NEXT_PUBLIC_APP_URL)
**다음 세션 1순위:** 2주/1주 수신 동기화 (DB 토대만 깔림, worker 코드 미구현)
**보류:** 3(TABS 전달추적, MS SQL 접근 대기)

---

## 가장 중요한 교훈 (반드시 기억)

1. **커밋 != 배포.** `git commit` 후 **반드시 `git push origin marinebiogroup`.**
   이번에 5커밋이 미푸시 상태(`ahead by 5`)였고, Railway는 GitHub만 보므로 옛 커밋(`e0fc31f` HANDOFF-12)만 빌드했다.
   증상: worker 로그 `IMAP undefined:143`, 신규 inbound에 `{{PII_xxx}}` 재출현, 상세뷰 시각 안 뜸 — 전부 "옛 코드" 증상.
   진단법: `git status`의 `Your branch is ahead of 'origin/...' by N commits` + `git log origin/marinebiogroup --oneline`.

2. **worker(lucky-patience)는 web과 별도 배포.** mailcarrier.ts / processor.ts / send-outbound.ts / email-tracking utils / tabs-mailer.ts 는 전부 worker 코드.
   web만 배포되면 이들 변경은 0 효과. push하면 Railway가 두 서비스 다 재빌드하지만, **worker 재빌드/Active 커밋을 Deployments에서 눈으로 확인**할 것.

3. **mover가 파일을 덮어써도 git add/commit은 별개.** 이번에 mailcarrier.ts/processor.ts가 "modified but not committed"로 남아 있었다(E host fix + processor PartyTypeCode). mover 실행 후 `git status`로 누락 없는지 확인.

4. **배포 검증 3종 세트:**
   - worker 로그 첫 줄에 **실제 IMAP host** (NOT `undefined:143`)
   - 새 Gmail 1통 → `select ...,(body_plain ~ '\{\{PII_[0-9]{3}\}\}') as has_tokens ...` → **false**
   - 상세뷰 OUTBOUND에 `Sent · <시각>` / `Read · <시각>` 표시

---

## 완료 항목 상세

### B — PII 토큰 누출 (검증 완료)
- 원인: mailcarrier가 inbound 본문을 **저장 시점에 maskPii** 하고 토큰맵을 버려, 마스킹된 `{{PII_001}}`가 canonical `body_plain`으로 저장됨. processor가 이미 마스킹된 텍스트를 AI에 다시 넣어 토큰이 draft→실제 발송 메일까지 새어나감.
- 조치: **저장은 raw**(body_plain=raw, pii_masked=false). 마스킹은 AI 호출 시점에만 transient. 발송 전 `hasUnrestoredTokens` 가드로 토큰 잔존 시 send 차단(errorCode `pii_tokens_present`).
- 데이터: `pii_remediation_v2.sql` — inbound 146건 중 113건 body_html에서 복원, 33건은 html 없는 plain-only(복원 불가, postmaster 등 포함). token draft 1건 삭제 + communications.ai_draft_id null화.
- 커밋: `ab7fcc6`
- **검증:** 재배포 후 신규 inbound 3건(18:24/18:29/18:41) 전부 `has_tokens=false`.
- 잔여: `mailcarrier.test.ts` 136/151이 OLD 마스킹 동작을 단언 → 실패할 것. **테스트 갱신 PENDING.**

### A — Gmail 552 바운스 (배포·송수신 확인)
- 원인: `email-tracking.ts injectTracking()`이 링크를 BASE_URL/api/track/click로 재작성(링크 클로킹) → Gmail "552-5.7.0 content ... security issue"(BlockedMessage). 네이버는 정상 → Gmail 전용.
- 조치: **클릭 링크 재작성 OFF, 오픈 픽셀만 유지.** BASE_URL=`NEXT_PUBLIC_APP_URL ?? localhost:3000`.
- DNS: GoDaddy에 DMARC 추가 `v=DMARC1; p=none; rua=mailto:postmaster@marinebiogroup.com; fo=1` (모니터링). SPF=`v=spf1 ip4:49.254.118.167 ~all`. DKIM selector 미발견.
- 커밋: `e9fd355`. Gmail 정상 송수신 확인.

### E — IMAP host=undefined (배포 확인)
- 원인: `mailcarrier.ts`가 DB(`inbound_mailboxes.imap_host`) 대신 미설정 `env.MAILCARRIER_HOST`를 읽어 `undefined:143`.
- 조치: `requireMailcarrierEnv()` 가드로 host/username/password 해석 (fail-fast).
- 커밋: `ab7fcc6` 묶음 + **누락분 별도 커밋**(mailcarrier.ts/processor.ts, push 후 추가 커밋).
- 검증: 재배포 후 토큰 정상화가 새 코드 적용을 방증.

### C — Sent 목록 발송시각 (완료)
- inbox-table.tsx: `Intl.DateTimeFormat('en-CA',{timeZone,hourCycle:'h23'})`로 뷰어 타임존 적용. ReadIndicator: 미열람 `Sent · <time>`, 열람 `Read · <time>`. 커밋 `c3da477`.

### 2 — 상세뷰 시각 (검증 완료)
- `inbox/[id]/page.tsx`: `fetchCurrentUserProfile()`로 timeZone 구해 `CommunicationDetailView`에 전달.
- `communication-detail-view.tsx`: `timeZone` prop + `formatAbsolute`(Intl). OUTBOUND 헤더 `Sent·/Read· <절대시각>`, 펼친 메타에 `Sent` 행 + `Opened` 절대시각.
- 커밋 `170a7f8`. **검증:** 상세뷰에 `Read · 2026-06-02 13:40` 표시 확인.
- 참고: 일부 OUTBOUND "No body"는 별개(그 테스트 발송이 본문 비어 있던 케이스). 계속 빈 채 저장되면 sendOutboundEmail body 저장 점검 필요.

### 1 — Supabase Security Advisor 4건 (완료)
- 진단: entity_types/party_types/partner_seniority_meta = organization_id 없는 전역 참조 테이블(비민감).
- 조치(`security_advisor_fix.sql`): 3테이블 RLS enable + `for select to authenticated using(true)` 정책(service_role은 RLS 우회 → 서버 쓰기/마이그레이션 OK). 뷰 `v_engagement_events` → `security_invoker = on`.
- 검증: 3테이블 rls_enabled=true, 뷰 reloptions=["security_invoker=on"].

### F — NEXT_PUBLIC_APP_URL (확인)
- worker(lucky-patience) Variables에 `NEXT_PUBLIC_APP_URL=https://urm.marinebiogroup.com` 확인.
- **TODO: web(mbg-project) Variables도 동일 값인지 한 번 더 확인.**

---

## 다음 세션 1순위 — 2주/1주 수신 동기화 (DB 토대만 깔림)

### 배경 (정정된 진단)
- worker 로그의 last_uid 16584/30429/71 혼재 = **상태 충돌 아님.** `mailcarrier_state` 키는 `(organization_id, kind, username)`이고 6개 박스가 username으로 정상 분리됨. 혼재는 6박스 동시 폴링의 자연스러운 인터리브.
- "전량 재수신"의 진짜 원인: `fetchAndProcessNew` line ~600 `range = ${lastUid+1}:*`. **lastUid=0(신규/리셋)이면 range=1:* → 메일박스 전체 백필**(craigslist/delta/frontier 수백통). 박스당 1회, 최대 uid 처리 후 "no new messages"로 안정화(이미 가라앉음). 긴급 아님(whitelist로 저장 차단, 신규 inbound는 has_tokens=false).

### 적용 완료된 마이그레이션 (`sync_window_migration.sql`, 추가 전용·안전)
- `app.mailcarrier_state.synced_since timestamptz` — 이 박스가 백필한 가장 과거 날짜 커서.
- `app.inbound_mailboxes.sync_request_weeks integer not null default 0` — 수동 백필 요청(버튼이 +1, worker가 처리 후 0).
- VERIFY: 두 컬럼 생성 확인됨.

### 구현 설계 (worker 코드 — 미구현)
1. **기본 폴링(앞으로 백필 폭주 방지):** `fetchAndProcessNew`에서 `lastUid===0`일 때 `range=1:*` 대신
   `client.search({ since: today-14d }, {uid:true})`로 2주 내 UID만 → 최소 UID부터 fetch. `synced_since`=today-14d 초기화.
   `lastUid>0`(현 6박스)는 `lastUid+1:*` 전진 그대로(현 동작 불변).
2. **수동 "과거 1주 더" 버튼:** 서버액션이 `inbound_mailboxes.sync_request_weeks += 1`.
   worker가 매 tick 시작 시 확인 → >0이면 `syncOlderWindow()`:
   `search({ since: synced_since-7d, before: synced_since })`로 그 1주 구간만 fetch
   (lastUid 가드 무시·전진 안 함, message_id UNIQUE로 중복 차단) → `synced_since -= 7d`, `sync_request_weeks=0`.
3. **핵심 배선:** worker 폴링 루프가 "sync_request 확인 → syncOlderWindow" 분기를 타게 함.

### 구현 시작 전 필요한 파일 (다음 세션에 먼저 확보)
- **worker 진입/폴링 파일** — `using 6 DB mailbox(es) from app.inbound_mailboxes` 로그를 찍고 6박스를 만들어 startListening/폴링하는 파일.
  찾기: `Get-ChildItem -Recurse -LiteralPath 'C:\dev\mbg-project\src' -Include *.ts,*.tsx | Select-String -List 'inbound_mailboxes|using .* DB mailbox|MailCarrierClient' | Select -ExpandProperty Path -Unique`
- **동기화 버튼 UI 위치** — 메일박스/받은편지함 설정 화면(있으면 그 파일).
- `mailcarrier.ts`는 이미 확보(이번 세션 업로드본). `fetchAndProcessNew`/`loadLastProcessedUid`/`saveLastProcessedUid` 위치 파악 완료.

---

## 보류 — 3. TABS 전달추적 (MS SQL 접근 대기)
- 확정 정보: 웹매니저 ~ mail.marinebiogroup.com, 캠페인 GUID 존재, MS SQL `TabsMailer4` 직접 접근 "가능"(단 현재 접속정보·네트워크 미확보).
- 설계 동결: `sendOne`에 `X-TABS-Campaign:{GUID}` 헤더 + communicationId를 msgid로 부착 → `SendMessage` 행과 매칭.
  `getCampaignStats`(현 NotImplementedError)를 MS SQL `SendMessage` 조회(node `mssql` 드라이버)로 구현 → 전달시각을 `communications.external_data`에 기록.
- 착수 전 필요: (1) `SELECT TOP 3 * FROM TabsMailer4.dbo.SendMessage` 컬럼 매핑, (2) 연결정보(host/1433/DB/계정) → Railway worker env `TABS_STATS_MSSQL_*`, (3) Railway worker→MSSQL 네트워크 도달성.

---

## 기타 잔여 TODO
- `mailcarrier.test.ts` 136/151 OLD 마스킹 단언 → 갱신 필요.
- web(mbg-project) Variables `NEXT_PUBLIC_APP_URL` 재확인.
- processor.ts에 CP949 깨진 한글 주석 잔존(빌드 무해) → D7 한글 주석 정리에서 처리.
- D6-6(`urm` schema DROP), D7(한글 주석 cleanup) 여전히 outstanding.
- 백업파일 repo에 남음: `*.bak`(PII/detail/tracking), `*.bak2`(tsc). 정리 가능.

---

## 이번 세션 커밋 (origin/marinebiogroup에 push 완료)
- `ab7fcc6` fix(pii): store inbound body raw + block outbound on unrestored PII tokens
- `7ad8959` fix(tsc): sent-list timezone via Intl + imap-delete host guard (tsc 0)
- `c3da477` feat(sent): always show absolute sent time on outbound rows (timezone-aware)
- `e9fd355` fix(email): disable click-link cloaking (Gmail 552 content block); keep open pixel
- `170a7f8` feat(detail): show absolute sent/read time (viewer timezone) in thread detail
- (+ 누락분 별도 커밋) fix(worker): mailcarrier host guard + processor PartyTypeCode
- 적용 SQL(커밋 외): security_advisor_fix.sql, sync_window_migration.sql, pii_remediation_v2.sql
