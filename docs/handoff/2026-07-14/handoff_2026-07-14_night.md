# Handoff — 가드 DB 적용 완료 + sendOutboundEmail 구조적 가드 (2026-07-14 야간 세션)

앞 세션(`handoff_2026-07-14_evening.md`)의 최우선 과제(7/20 발송 가드)를 **DB에 적용 완료**하고, 미결 3번(구조적 해법)에 착수한 세션.

> ## ✅ 7/20 발송 안전 확보
> `get_due_enrollments()` `has_dns_guard = true` 확인. Seed **66 ok / 1 차단**.

---

## PART A — 완료: 가드 적용 + 실측

### A-1. 적용 결과 (전부 DB에서 직접 검증)

| # | 파일 | DB 상태 |
|---|---|---|
| 1 | `migration_20260714235500_v_enrollment_send_health.sql` | **적용됨** |
| 2 | `migration_20260714235600_guard_get_due_enrollments.sql` | **적용됨** — `has_dns_guard = true` |
| 3 | `fix_20260714235700_world_fund_auto_reply_cooldown.sql` | **적용됨** — `resend_not_before = 2026-08-04` |

전체 active enrollment: **129 ok / 5 do_not_send_party**. `no_email` / `malformed_email` / `no_matching_step` **0건**.

### A-2. Seed 실측 = **66 / 67** (기존 "clean 67/67"은 무효)

차단 1건 = **First Bight Ventures** (`rejected_stage`, 7/14 15:27 기록). 어제 preflight 이후에 들어온 거절이라, **가드가 없었으면 자기를 거절한 회사에 7/20 후속 콜드가 나갔다.** 가드가 잡은 첫 실적.

### A-3. 차단 5건 근거 (오분류 없음)

| 회사 | outcomes | 성격 |
|---|---|---|
| Azolla Ventures | `form_submitted` (7/10) | 폼 제출 → 의도대로 |
| Energy Transition Ventures | `rejected_sector` | 영구, 정당 |
| Extantia Capital | `rejected_other` | 영구, 정당 |
| First Bight Ventures | `rejected_stage` | 영구, 정당 |
| World Fund | `auto_reply` | 쿨다운 8/4 자동 만료 |

### A-4. ⭐ party 단위 가드는 "넓은" 게 아니라 **필요조건**이었다 (리뷰 종결)

evening 핸드오프 PART C에서 "party 단위 차단이 넓다 — 리뷰 필요"로 남긴 건. **데이터가 정당성을 증명함:**

| 회사 | 차단 근거 주소 | 실제 발송될 주소 | 주소 단위로 잡히나? |
|---|---|---|---|
| Energy Transition Ventures | craig@energytransitionvc.com | info@energytransitionvc.com | ❌ |
| Extantia Capital | jo@extantia.com | inbound@extantia.com | ❌ |
| First Bight Ventures | collin@firstbight.com | info@firstbight.com | ❌ |
| Azolla Ventures | info@azollaventures.com | info@azollaventures.com | ✓ |
| World Fund | brightfuture@worldfund.vc | brightfuture@worldfund.vc | ✓ |

**5건 중 3건은 주소 단위 가드만 있었으면 그대로 뚫렸다.** 거절한 사람은 개인 주소로 답하고, 시퀀스는 접수 주소로 쏜다 — 콜드 아웃리치에선 이게 정상이다. **party 단위는 유지. 이 항목은 리뷰 종결.**

### A-5. 알아둘 동작 — World Fund는 8/4에 즉시 발송

`next_send_at = 7/27`인 채로 8/4까지 차단 → 8/4에 뷰에서 빠지는 순간 `next_send_at`이 과거라 **다음 워커 실행에서 즉시 step 3이 나간다** (7/27이 아니라 8/4). 의도된 설계. 그 전에 사람 답이 오면 outcome 갱신할 것.

---

## PART B — 착수: 구조적 가드 (미결 3번)

### B-1. ⚠️ 앞 세션의 처방을 **정정**한다

evening 핸드오프 PART D 3번: *"sendOutboundEmail에 뷰 가드를 넣으면 모든 경로가 한 번에 커버됨"* — **이대로 하면 안 된다. 보내야 할 메일까지 막는다.**

`send-outbound.ts` 642줄 전체를 읽고 확인한 것:

- **`app.email_blocklist` = 전역 억제.** `[0]` 가드에서 `skipWhitelist`로도 못 뚫게 무조건 강제 중. 주석: *"an unsubscribe / suppression must always win, on every send path"*. 이건 옳다.
- **`app.v_email_do_not_send` = 콜드 아웃리치 억제 리스트.** 성격이 다르다. 내용물이 `form_submitted` / `rejected_*` / `reply_*` / `auto_reply` 쿨다운이다.

무조건 가드로 박으면:
- Azolla(`form_submitted`)가 우리한테 메일 → **컴포즈 답장이 `blocked`로 튕김**
- **`drafts.ts:646` `sendApprovedDraft`는 `to: inbound.from_address` + `inReplyTo` — 답장한 사람에게 AI 답장을 보내는 경로.** 뷰에 `reply_positive`가 있으므로 **긍정 답장에 답장을 못 하게 된다.** 최악의 오작동.

### B-2. `is_follow_up`은 판별자가 아니다

`pg_get_viewdef` 확인:
```
bool_or(o.outcome = 'reply_positive' OR o.next_action = 'follow_up') AS is_follow_up
```
"사람이 직접 후속 연락할 대상"이라는 **UI 힌트**. `form_submitted`는 false인데 직접 메일은 허용해야 하고, `unsubscribe_request`도 false인데 이건 직접도 막아야 한다. **재사용 불가.**

### B-3. 설계: `sendClass` 판별자 + 뷰에 `blocks_direct` 추가

```ts
export type SendClass = 'cold' | 'direct';   // SendOutboundInput.sendClass, default 'cold'
```

| sendClass | 뷰 적용 |
|---|---|
| `cold` | **모든 행이 차단** (party_id 또는 해석된 주소 매치) |
| `direct` | **`blocks_direct = true` 행만 차단** (unsubscribe / suppress) |

- **기본값 `'cold'` = fail-closed.** 새 경로가 선언을 잊으면 가드가 걸린다. 이게 이 작업의 전부다 — 오늘 사고는 "가드가 호출부에 살아서 새 경로가 뚫린" 것이었다
- 실패 방향도 이쪽이 안전: 잘못 막히면 UI 에러로 보이고 복구 가능, 잘못 나가면 조용히 리드가 죽는다
- `skipWhitelist`로 못 뚫는다 (별개 관심사)
- 뷰 조회 실패 → fail-closed. 뷰 부재(42P01/PGRST205) → 경고 후 통과 (blocklist 패턴 그대로)
- **`blocks_direct` 미적용(42703) → 컬럼 없이 재조회.** cold 가드는 계속 동작, direct는 현행 유지 → **배포 순서 사고 없음**

### B-4. 호출부 5곳 전수 (리포 직접 확인)

| 파일 | 함수 | sendClass |
|---|---|---|
| `src/lib/utils/sequence-processor.ts:170` | 시퀀스 워커 | `cold` |
| `src/lib/actions/bulk-mail.ts:230` | `sendBulkMail` | `cold` |
| `src/lib/actions/email-compose.ts:157` | `sendEmail` | `direct` |
| `src/lib/actions/communications.ts:213` | `sendOutboundManual` | `direct` |
| `src/lib/actions/drafts.ts:646` | `sendApprovedDraft` | `direct` |

`send-outbound.ts` 헤더 주석의 "three send sites"는 낡음 — 실제 5곳.

### B-5. `blocks_direct` 컬럼 (뷰 트레일링 추가)

```sql
bool_or(o.outcome = 'unsubscribe_request' OR o.next_action = 'suppress') AS blocks_direct
```
`CREATE OR REPLACE VIEW`는 **끝에 컬럼 추가만** 가능 — 정확히 그것만 함. 기존 소비자는 부분집합만 select하므로 무영향:
- `app.v_enrollment_send_health` → party_id, email_lower
- `public.get_due_enrollments()` → party_id, email_lower
- `src/lib/queries/bulk-mail.ts` → email_lower, party_id

---

## PART C — 실행 순서

### 1. SQL 먼저 (Supabase SQL Editor, 단독 실행)

`sql/migration_20260715000100_v_email_do_not_send_blocks_direct.sql`

검증:
```sql
SELECT email_lower, party_id, outcomes, is_follow_up, blocks_direct
FROM app.v_email_do_not_send
ORDER BY blocks_direct DESC, email_lower;
```
현재 5건은 전부 `blocks_direct = false`가 정상 (unsubscribe/suppress 없음).

기존 소비자 무회귀 확인 (단독 실행):
```sql
SELECT send_status, count(*)
FROM app.v_enrollment_send_health
WHERE enrollment_status = 'active'
GROUP BY send_status;
```
**129 ok / 5 do_not_send_party가 그대로 나와야 한다.** 달라지면 멈출 것.

### 2. 코드 패치

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\patches\patch_send_outbound_send_class.ps1
```
기대 출력: `PATCHED:` 6줄 (core + 5 호출부).

### 3. tsc — **git 체인에 넣지 말 것** (evening 컨벤션)

```powershell
cd C:\dev\mbg-project
npx tsc --noEmit
```
`send-outbound.ts` 및 5개 호출부 **에러 0**이어야 함. 선행 에러 15건/5파일은 이번 건과 무관 (PART D 6번).

### 4. 커밋 + 푸시

---

## PART D — 미결 (우선순위)

1. **[진행중] `sendClass` 가드 배포 후 스모크** — 컴포즈에서 Azolla(폼 제출) 앞으로 수동 발송 → **나가야** 정상 (direct). 시퀀스는 다음 워커 실행에서 66건 유지 확인
2. **`template_id = null` dedup 우회** — evening 4번. **일부 이미 해결돼 있음**: `send-outbound.ts`에 `if (input.merge?.templateId) insertRow.template_id = input.merge.templateId;` 존재. 남은 진짜 구멍은 템플릿 없는 애드혹 발송 → `recently_contacted`(template-agnostic, 현재 opt-in)를 콜드 경로에서 **기본 on**으로 바꾸는 게 답
3. **`unsubscribe_request` → `email_blocklist` 동기화** — `email_send_outcomes`에 수신거부가 들어와도 `blocklist` 행이 자동 생성되진 않음. `blocks_direct`가 임시 방어막이지만, 전역 억제는 blocklist가 정본이어야 함
4. **Lowercarbon 이중 노출 대응** (이월) — $5M 구버전 + 민감 IP 둘 다 submitted. 스레드 재개 시:
   > Quick update since our submission: we've since finalized the round at **$3M on a $27M pre-money** (previously $5M/$30M), with use of funds evenly split $1M each across applied R&D, IP, and operations.
   >
   > (2문장째는 상황 판단 — 민감 IP 제출을 먼저 상기시키는 게 역효과일 수 있음. 상대가 IP를 물으면 그때 데이터룸으로)
5. **tsc 선행 에러 15건 / 5파일** (이월) — `applications-list-client.tsx`(badge undefined ×2), `parties.ts`(sectorFocus ×2), `decompose-actions.ts`(SbClient 'app' vs 'public'), `fill-application.ts`(×9), `inspect-form.ts`(×1). 배포는 통과 중 → Railway 로그로 `ignoreBuildErrors` 확인
6. **World Fund 8/4 재개 감시** (PART A-5)
7. Material Impact 파트너 직송 업그레이드 (백로그) — Carmichael Roberts / Adam Sharkawy 개인 이메일 비공개. LinkedIn 웜 인트로. Planet A / Eclipse 발굴과 묶어서
8. 신규 익명화 2건(advisory/valuation) nda_only 미보관 (이월, 낮음)
9. 기후펀드 백필 70개 (이월)

---

## PART E — 컨벤션 (이번 세션 추가분)

기존 evening PART E 전부 유효. 추가:

- **뷰/함수의 semantics를 이름으로 추측하지 말 것** — `is_follow_up`을 "직접 발송 허용 플래그"로 오독할 뻔했다. `pg_get_viewdef`로 확인 후 설계
- **가드를 넣기 전에 "무엇을 막게 되는지"를 먼저 열거할 것** — `v_email_do_not_send`를 무조건 가드로 박는 처방은 AI 답장 경로를 죽였을 것이다. 억제 리스트는 *어떤 종류의 발송을* 막는지가 semantics의 절반
- **`CREATE OR REPLACE VIEW`는 트레일링 컬럼 추가만 가능** — 중간 삽입/타입 변경 불가. 소비자가 부분집합만 select하면 안전
- **PostgREST 42703은 뷰 버전 스큐 신호** — 마이그레이션 미적용 상태에서 코드가 먼저 배포될 수 있으므로, 새 컬럼 의존 코드는 42703 폴백 경로를 가질 것

---

## 파일 이동

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

3개 파일 전부 라우팅 규칙에 맞음 (`migration_*.sql` → `sql\`, `patch_*.ps1` → `tools\patches\`, `handoff_*.md` → `docs\handoff\<today>\`).

인라인 폴백:

```powershell
$dl = "$env:USERPROFILE\Downloads"
$map = @(
  @{ glob = 'migration_20260715000100_v_email_do_not_send_blocks_direct*.sql'; dest = 'C:\dev\mbg-project\sql';            name = 'migration_20260715000100_v_email_do_not_send_blocks_direct.sql' },
  @{ glob = 'patch_send_outbound_send_class*.ps1';                             dest = 'C:\dev\mbg-project\tools\patches';  name = 'patch_send_outbound_send_class.ps1' },
  @{ glob = 'handoff_2026-07-14_night*.md';                                    dest = 'C:\dev\mbg-project\docs\handoff\2026-07-14'; name = 'handoff_2026-07-14_night.md' }
)
foreach ($m in $map) {
  $src = Get-ChildItem (Join-Path $dl $m.glob) -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if ($src) {
    Unblock-File $src.FullName
    [System.IO.Directory]::CreateDirectory($m.dest) | Out-Null
    [System.IO.File]::Copy($src.FullName, (Join-Path $m.dest $m.name), $true)
    Remove-Item $src.FullName
    Write-Output ("MOVED: " + $m.name)
  } else { Write-Output ("NOT FOUND: " + $m.glob) }
}
```

## Finish

```powershell
cd C:\dev\mbg-project
git pull --rebase origin marinebiogroup
git status -sb
```

**SQL 적용 → 패치 실행 → tsc 통과** 확인 후:

```powershell
git add sql/ tools/ docs/ src/
git commit -m "feat(email): sendClass do-not-send guard in sendOutboundEmail; sql: v_email_do_not_send.blocks_direct"
git push origin marinebiogroup
```

**푸시 = 웹 자동 배포.** 이번 커밋은 `src/` 포함이라 **앱 코드가 실제로 바뀐다** — 발송 경로 전체에 영향. SQL(1번)을 먼저 적용해두는 걸 권장하되, 미적용이어도 42703 폴백이 있어 사고는 안 남.

---

## 다음 세션 킥오프 (복붙)

```
mbg-project 이어가자. docs/handoff/2026-07-14/handoff_2026-07-14_night.md 기준.

완료된 것 (전부 DB 검증):
- get_due_enrollments() 가드 적용됨. has_dns_guard=true. 7/20 발송 안전 확보
- Seed 실측 66 ok / 1 차단(First Bight, rejected_stage). "clean 67/67"은 무효였음
- 전체 129 ok / 5 do_not_send_party. no_email/malformed/no_step 0건
- World Fund 쿨다운 8/4 적용됨. 단 next_send_at=7/27이 과거라 8/4에 즉시 step3 발송됨
- party 단위 가드 정당성 입증: 5건 중 3건은 주소 단위였으면 뚫렸음
  (craig@ vs info@, jo@ vs inbound@, collin@ vs info@) -> 리뷰 종결, 유지

진행중 (PART B/C):
- sendClass 'cold'|'direct' 판별자를 sendOutboundEmail에 추가, default 'cold' (fail-closed)
  cold=모든 do-not-send 행 차단, direct=blocks_direct(unsubscribe/suppress) 행만 차단
- 이유: v_email_do_not_send는 콜드 억제 리스트지 전역 억제가 아님. 무조건 가드로 박으면
  drafts.ts:646 sendApprovedDraft(답장한 사람에게 AI 답장)가 reply_positive에 막힘
- is_follow_up은 판별자 아님 (reply_positive OR next_action=follow_up = UI 힌트)
- 호출부 5곳: sequence-processor:170/bulk-mail:230=cold, email-compose:157/
  communications:213/drafts:646=direct
- 순서: SQL(migration_20260715000100) -> patch ps1 -> npx tsc --noEmit(단독) -> commit+push

다음: 배포 후 스모크 (Azolla 앞 수동 발송이 나가야 정상), 그 다음 template_id dedup(D-2)
```
