# Handoff — 시퀀스 발송 가드 부재 발견 + 스키마 정본화 (2026-07-14 저녁 세션)

앞 세션(`handoff_2026-07-14_pm_form_prep.md`) 미결 처리로 시작했으나, **오후 핸드오프의 핵심 전제가 틀렸다는 것을 발견**하면서 성격이 바뀐 세션.

> ## ⚠️ 최우선 — 7/20 발송 전 필수
> **`get_due_enrollments()`에 do-not-send 가드가 없다.** 시퀀스 경로는 폼 제출/답장/거절/수신거부를 **전혀 거르지 않는다.**
> `sql/migration_20260714235600_guard_get_due_enrollments.sql`을 **적용해야 7/20 발송이 안전하다.** (아직 DB 미적용)

---

## PART A — 오후 핸드오프의 오류 정정 (중요)

### A-1. "시퀀스 발송 경로는 이 뷰를 가드로 쓴다" → **거짓**
오후 핸드오프 §1의 전제다. 검증 결과 `has_dns_guard = false`:

```sql
SELECT n.nspname, p.proname,
       pg_get_functiondef(p.oid) ILIKE '%v_email_do_not_send%' AS has_dns_guard
FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE p.prokind = 'f' AND p.proname ILIKE '%due_enrollment%';
```

- 워커 = `src/lib/utils/sequence-processor.ts` → `rpc(supabase, 'get_due_enrollments')` → 반환된 `contact_email`로 `sendOutboundEmail()` 호출. `contact_email`이 null이면 `advance_enrollment(status='skipped')`
- `get_due_enrollments()`의 WHERE = **`status='active' AND next_send_at <= now()`가 전부**
- `sendOutboundEmail`이 강제하는 건 `app.email_blocklist`뿐 (뷰 아님)
- `grep -r v_email_do_not_send src/ sql/` → **bulk-mail.ts(오늘 추가분) + sql 파일들뿐. 워커 경로 0건**

**결론: 어제 뷰를 확장한 작업(폼 제출 자동 제외)은 시퀀스에 아무 효력이 없었다.** 아이러니하게 오늘 "우선순위 낮음"으로 붙인 bulk-mail이 유일하게 가드된 경로가 됐다.

### A-2. 발송 주소 해석은 **3단 COALESCE** → preflight가 검사한 건 2번째뿐
`get_due_enrollments()` 실제 정의:

```sql
COALESCE(NULLIF(e.recipient_email, ''), ct.email, p.email) AS contact_email
--        1) enrollment            2) contacts   3) parties.email
```

- **`app.email_sequence_enrollments.recipient_email`** — enrollment 자체 이메일. 등록 시 `p_recipient_email` RPC 파라미터로 pin됨. **최우선**
- **`app.parties.email`** — 파티 HQ 이메일. **3차 폴백**
- `ct`는 LATERAL: `party_id` 일치 + `deleted_at IS NULL` + `email IS NOT NULL` + (`e.contact_id IS NULL` 이면 아무 컨택이나) → `contact_id` 일치 > `is_primary` > `created_at` 순 1건

오후 preflight Part 1/2는 **`contacts.email`만** 봤다. 따라서:
- **"bad_email 1건", "clean 66/67", "clean 67/67" 전부 근거 없는 숫자** — 1·3번 경로로 실제 발송되는 건을 못 봤고, 반대로 멀쩡한 걸 bad로 찍었을 수 있음
- preflight Part 2(do-not-send 크로스체크)도 `c.email`로 조인 → 다른 경로로 해석되는 주소는 **크로스체크 자체를 못 함**. 애초에 워커에 가드가 없으니 무의미했지만

### A-3. Material Impact 조치는 결과적으로 유효, 근거는 재확인 필요
- Seed enrollment: `recipient_email=null`, `contact_email=info@materialimpact.com`(오늘 주입), 7/20 step 3, active
- 오늘 `contact_id`를 `0831477d`로 연결했으므로 LATERAL이 그 컨택을 잡아 **info@로 발송된다** → 조치는 유효
- 단 **조치 전에도 `parties.email`이 있었다면 발송됐을 것** — "no contact linked = 발송 불가"는 틀린 추론이었음. `v_enrollment_send_health`로 재확인할 것
- 파일: `sql/20260714230000_fix_material_impact_contact.sql` — **DB 적용됨**, 커밋 `849f810`

### A-4. World Fund는 "무해"가 아니다 — 7/27 3번째 발송 예정
세션 중 "email null이라 스킵되니 무해"라고 판단했으나 **오답**. `contacts.email`만 보고 내린 결론이었다.

```
World Fund / Climate Investor Cold Outreach -- FCC
  status = active | recipient_email = brightfuture@worldfund.vc
  next_send_at = 2026-07-27 21:06 UTC | next_step_order = 3
```

`recipient_email`이 최우선이므로 **7/27에 3번째 메일이 나간다.**

---

## PART B — 완료된 것

### 1. "Brightfuture 회신" = World Fund 오토리스폰더 (완료 ✓)
**Brightfuture는 회사가 아니다.** `brightfuture@worldfund.vc` = World Fund 접수 주소, 회신은 `brightfuture+noreply@worldfund.vc`(플러스 서브어드레싱)에서 온 정형 자동응답. **2건**(7/13 21:08, 7/14 16:01), 본문 동일.

**판정: reply/rejected로 기록 금지.** 기록하면 `v_email_do_not_send`가 World Fund를 영구 차단 → 로봇 때문에 리드가 죽는다.

올바른 어휘가 CHECK 제약에 이미 있음:
- `outcome = 'auto_reply'` (OOO / automated acknowledgement)
- `next_action = 'resend_later'` + `resend_not_before` → 뷰가 `resend_not_before > CURRENT_DATE` 동안만 차단 → **자동 만료되는 쿨다운**

조치 파일: `sql/fix_20260714235700_world_fund_auto_reply_cooldown.sql` (쿨다운 2026-08-04) — **미적용**. **가드(235600) 적용이 선행돼야 효력 있음.**

### 2. bulk-mail 경로에 do-not-send 뷰 연결 (완료 ✓ — 배포됨)
`src/lib/queries/bulk-mail.ts`. 9곳 패치, `npx tsc --noEmit` 기준 이 파일 에러 0. 커밋 `95043b8` → Railway 배포됨.
- `BulkExcludeReason`에 `'do_not_send'`, `counts.doNotSend` 신설
- 5d 섹션: 뷰 로드 → `dnsEmails`(email_lower) + `dnsParties`(party_id)
- **party 단위 차단** 포함
- 우선순위: **blocklist > do_not_send > 파생 바운스**
- 파일: `tools/patches/patch_bulk_mail_do_not_send.ps1`

### 3. 스키마 정본 생성 (완료 ✓)
`docs/schema/app_schema_reference.md` — **테이블 118 + 뷰 8**, 전 컬럼 타입/NOT NULL/default. `information_schema.columns` 전수 덤프 기반.
- 이번 세션에 42703이 **2회**(`contacts.title`, `communications.body_text`) 발생 → 추측 금지, 이 파일 확인 후 작성
- PART A에 사고 기록 + 조용한 함정(에러 없이 결과만 틀리는 것들) 수록
- PART D에 재생성 쿼리 (에디터 100행 제한 회피 2편 구성)

---

## PART C — 파일 실행 순서 (⚠️ 순서 중요)

| # | 파일 | 성격 | DB 상태 |
|---|---|---|---|
| 1 | `migration_20260714235500_v_enrollment_send_health.sql` | VIEW | **미적용** — 먼저 적용(읽기 전용, 무해) |
| 2 | *(아래 헬스 점검 쿼리 → 무엇이 차단될지 확인)* | 조회 | — |
| 3 | `migration_20260714235600_guard_get_due_enrollments.sql` | FUNCTION | **미적용** — **7/20 전 필수** |
| 4 | `fix_20260714235700_world_fund_auto_reply_cooldown.sql` | INSERT | **미적용** — 3번 이후 |
| 5 | *(헬스 재점검)* | 조회 | — |
| — | `20260714230000_fix_material_impact_contact.sql` | UPDATE | **적용됨** (커밋 `849f810`) |

### 2번 / 5번 헬스 점검 (단일 SELECT)

```sql
SELECT sequence_name, party_name, resolved_email, email_source, send_status, next_send_at
FROM app.v_enrollment_send_health
WHERE enrollment_status = 'active'
ORDER BY (send_status <> 'ok') DESC, sequence_name, party_name;
```

Seed 카운트만 볼 때:

```sql
SELECT send_status, count(*)
FROM app.v_enrollment_send_health
WHERE enrollment_status = 'active'
  AND sequence_name = 'Investor Cold Outreach - FCC Seed'
GROUP BY send_status;
```

- **3번 적용 전**에 돌려서 `do_not_send_*`로 찍히는 것들을 확인 → 가드 적용 시 7/20 대상에서 빠질 애들이다. 예상 밖으로 많이 빠지면 멈추고 검토
- **이제부터 preflight는 이 뷰 하나다.** 시퀀스별 임시 SQL 재작성 금지 — 그게 이번 사고의 원인

### 가드 설계상의 판단 (리뷰 필요)
- **party 단위 차단이 넓다**: `v_email_do_not_send`에 party_id가 있는 행 하나면 그 party의 **모든** enrollment가 멈춘다. 콜드 아웃리치에선 의도된 동작(폼 냈거나 답한 회사엔 콜드 안 보냄)이고 bulk-mail과 semantics가 일치한다. 다르게 가려면 두 경로를 같이 바꿀 것
- `resend_later`는 날짜 지나면 뷰에서 빠져 **자동 재개**된다. 수동 해제 불필요

---

## PART D — 미결 사항 (우선순위)

1. **[7/20 전 · 최우선] 가드 적용** — PART C 1→2→3→4→5 순서대로
2. **[7/20 전] 헬스 뷰로 Seed 실측 재검증** — "clean 67/67"은 무효. 뷰가 내는 숫자가 최초의 근거 있는 수치
3. **`sendOutboundEmail`에도 뷰 가드 검토** — 현재 `email_blocklist`만 강제. 이 함수에 넣으면 모든 경로(시퀀스/벌크/수동/AI 초안)가 한 번에 커버됨. 지금은 경로마다 따로 가드 = 새 경로 생기면 또 뚫림. **구조적 해법은 이쪽**
4. **`template_id = null` 발송의 dedup 우회** — bulk-mail `already_sent`는 template_id 키. World Fund 아웃바운드 2건 모두 `template_id=null`이라 dedup이 성립 안 됨 → 수동/애드혹 발송은 dedup을 통째로 우회. 2주 새 2번 접촉의 원인
5. **Lowercarbon 이중 노출 대응** (이월) — $5M 구버전 + 민감 IP 둘 다 submitted. 스레드 재개 시:
   > Quick update since our submission: we've since finalized the round at **$3M on a $27M pre-money** (previously $5M/$30M), with use of funds evenly split $1M each across applied R&D, IP, and operations.
   >
   > (2문장째는 상황 판단 — 민감 IP 제출을 먼저 상기시키는 게 역효과일 수 있음. 상대가 IP를 물으면 그때 데이터룸으로: *"the IP assignment details in our form referenced internal specifics we normally share under NDA — happy to walk through the full structure in a data-room session."*)
6. **tsc 선행 에러 15건 / 5파일** — 이번 패치와 무관(bulk-mail.ts 0건). `applications-list-client.tsx`(badge undefined ×2), `parties.ts`(sectorFocus ×2), `decompose-actions.ts`(SbClient 'app' vs 'public'), `fill-application.ts`(×9), `inspect-form.ts`(×1). 배포는 통과 중 → Railway 로그로 `ignoreBuildErrors` 여부 확인
7. Material Impact 파트너 직송 업그레이드 (백로그) — Carmichael Roberts / Adam Sharkawy 개인 이메일 비공개. LinkedIn 웜 인트로 후보. Planet A / Eclipse 발굴 건과 묶어서
8. 신규 익명화 2건(advisory/valuation) nda_only 미보관 (이월, 낮음)
9. 기후펀드 백필 70개 (이월)

---

## PART E — 컨벤션 (기존 + 이번 세션 추가분)
- 소통 한국어 + 코드/SQL 영어. 콘솔 ASCII-only, 한국어 .md UTF-8 BOM
- Supabase SQL Editor: 문자열 내 세미콜론/`into` 금지, self-contained 문장, enum 캐스트
  - **[추가] 주석 안의 세미콜론과 어퍼스트로피도 피할 것** — 나이브 스플리터가 건드림
  - **[추가] 함수 본문($function$) 안에 세미콜론 0개로 작성** — `language sql`은 끝 세미콜론 없어도 됨
  - **[추가] `pg_get_functiondef`는 집계함수에서 42809** → `p.prokind = 'f'` 필수
  - **[추가] 에디터 결과 100행 제한** — 전수 덤프는 테이블당 1행으로 접고(`string_agg`) 커서(`table_name > '...'`)로 분할
- **[추가] 컬럼 추측 금지** — `docs/schema/app_schema_reference.md` 확인 후 작성. 없으면 `information_schema.columns` 단일 SELECT로 선확인
- **[추가] DB가 정본** — `sql/` 파일과 실제 적용 상태가 다를 수 있음(`plant_supply_links`는 파일엔 있고 DB엔 없음). 함수/뷰는 `pg_get_functiondef` / `pg_get_viewdef`로 확인
- **[추가] `npx tsc --noEmit`을 git 체인 블록에 넣지 말 것** — 이번에 tsc 실패에도 커밋/푸시가 진행됨
- git: 두 머신 → 작업 전 `git pull --rebase origin marinebiogroup` 필수
- 파일 라우팅: `tools\move-downloads.ps1` (프리픽스 규칙). `docs/schema/`는 라우팅 규칙에 없어 인라인 이동 필요
- 여러 result set 스니펫은 마지막 것만 캡처됨 → 확인용은 단일 SELECT로 분리

---

## 파일 이동 + Finish

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

`docs/schema/`는 mover 라우팅 밖이라 인라인:

```powershell
$src = Get-ChildItem "$env:USERPROFILE\Downloads\app_schema_reference*.md" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($src) {
  Unblock-File $src.FullName
  $dest = 'C:\dev\mbg-project\docs\schema'
  [System.IO.Directory]::CreateDirectory($dest) | Out-Null
  [System.IO.File]::Copy($src.FullName, (Join-Path $dest 'app_schema_reference.md'), $true)
  Remove-Item $src.FullName
  Write-Output 'MOVED: docs\schema\app_schema_reference.md'
} else { Write-Output 'NOT FOUND in Downloads' }
```

```powershell
cd C:\dev\mbg-project
git pull --rebase origin marinebiogroup
git status -sb
git add sql/ docs/
git commit -m "sql: sequence do-not-send guard + enrollment send health view; docs: app schema reference"
git push origin marinebiogroup
```

푸시 = 웹 자동 배포. 이 커밋은 sql/docs만이라 앱 코드 영향 없음 (DB 반영은 SQL Editor 실행으로 별도).

---

## 다음 세션 킥오프 (복붙)

```
mbg-project 이어가자. docs/handoff/2026-07-14/handoff_2026-07-14_evening.md 기준.

최우선 (7/20 발송 전):
1. sql/migration_20260714235500_v_enrollment_send_health.sql 적용 (뷰, 무해)
2. 헬스 점검: SELECT sequence_name, party_name, resolved_email, email_source, send_status
   FROM app.v_enrollment_send_health WHERE enrollment_status='active'
   ORDER BY (send_status <> 'ok') DESC   -- 가드 적용 시 빠질 대상 미리 확인
3. sql/migration_20260714235600_guard_get_due_enrollments.sql 적용 <- 7/20 안전의 핵심
4. sql/fix_20260714235700_world_fund_auto_reply_cooldown.sql 적용 (3번 이후여야 효력)
5. 헬스 재점검

확정 사실 (전부 DB에서 직접 검증함):
- get_due_enrollments()에 do-not-send 가드 없음(has_dns_guard=false). 시퀀스 경로는 폼제출/답장/거절을
  안 거름. 오후 핸드오프의 "시퀀스가 뷰를 가드로 쓴다"는 거짓이었음
- 발송 주소 = COALESCE(NULLIF(e.recipient_email,''), ct.email, p.email) 3단.
  preflight는 2번째만 봤음 -> "clean 67/67"은 근거 없는 숫자. 헬스 뷰로 재측정할 것
- 워커 = src/lib/utils/sequence-processor.ts -> get_due_enrollments RPC -> contact_email null이면 skip.
  sendOutboundEmail은 email_blocklist만 강제
- "Brightfuture"는 회사 아님 = World Fund 접수 주소(brightfuture@worldfund.vc)의 오토리스폰더 2건.
  reply로 기록하면 영구 차단되므로 outcome='auto_reply' + next_action='resend_later'(2026-08-04)로 처리
- World Fund Climate enrollment는 recipient_email 살아있어 7/27 3번째 발송 예정 (가드+쿨다운으로 차단)
- bulk-mail.ts는 뷰 연결 완료(커밋 95043b8) -- 현재 유일하게 가드된 경로
- 스키마 정본: docs/schema/app_schema_reference.md (테이블 118 + 뷰 8). 컬럼 추측 금지
- Lowercarbon은 $5M+민감IP 둘 다 이미 submitted (정정 필요)

구조적 과제: sendOutboundEmail 자체에 뷰 가드를 넣으면 모든 경로가 한 번에 커버됨.
지금은 경로별 가드라 새 경로가 생기면 또 뚫림.
```
