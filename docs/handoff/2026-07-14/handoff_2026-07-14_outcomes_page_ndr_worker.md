# Handoff — /mailing/outcomes 대시보드 + MailCarrier NDR 자동 기록 (2026-07-14)

기준 문서: `docs/handoff/2026-07-14/handoff_2026-07-14_session_end.md` 킥오프 블록.
검증: 클론 repo에 전체 적용 후 `tsc --noEmit` 신규 에러 0, vitest 신규 6건 통과, 기존 테스트 회귀 없음 (기존 12건 실패는 env 미설정으로 원본에서도 동일하게 실패하는 pre-existing).

---

## PART A — 산출물 (Downloads → repo)

| Downloads 파일명 | repo 경로 | 내용 |
|---|---|---|
| `mailing_outcomes_page.tsx` | `src/app/(app)/mailing/outcomes/page.tsx` | 서버 컴포넌트 (force-dynamic) |
| `mailing_outcomes_client.tsx` | `src/app/(app)/mailing/outcomes/outcomes-client.tsx` | 3블록 + 최근 로그 + 수동 입력 폼 |
| `email-outcomes.ts` | `src/lib/actions/email-outcomes.ts` | 'use server' — listOutcomes / addOutcomeEntry(+enrollment 동기화) |
| `email-outcome.ts` | `src/types/email-outcome.ts` | 공유 상수/타입 ('use server' 파일은 async 함수만 export 가능하므로 분리) |
| `ndr-outcome.ts` | `src/lib/email/ndr-outcome.ts` | 순수 NDR 파서 — hard(5xx)/soft(4xx) 분류 |
| `outcome-recorder.ts` | `src/lib/email/outcome-recorder.ts` | outcomes INSERT + dedup + hard bounce 시 enrollment 'failed' |
| `ndr-outcome.test.ts` | `src/__tests__/email/ndr-outcome.test.ts` | vitest 6건 (Planet A 550 5.2.1 / Eclipse / soft 4.2.2 / 한국어 자체통지 등) |
| `patch_mailcarrier_ndr_outcome.ps1` | `tools/patches/` (universal mover 자동 라우팅) | mailcarrier.ts in-place 패치 |
| `migration_20260714120000_email_send_outcomes_page_access.sql` | `sql/` (자동 라우팅) | 페이지용 RLS 정책 + grant + 검증 쿼리 |
| `handoff_2026-07-14_outcomes_page_ndr_worker.md` | `docs/handoff/2026-07-14/` (자동 라우팅) | 이 문서 |

### 페이지 구성 (스펙 대비)
- ① 요약 카드: outcome별 카운트 (Q3) — 최근 500건 기준
- ② 액션 보드: next_action IN (switch_contact, switch_deck, follow_up) (Q5) → Planet A / Eclipse가 여기 표시됨
- ③ 재접근 대기: resend_later, resend_not_before 오름차순 + D-day 배지 (D-n / D-Day / D+n=쿨다운 지남) (Q4) → Extantia(2027-01-15)가 여기 표시됨
- ④ 최근 로그 전체 테이블: party_name 링크(`/{party_type}/parties/{id}`), 배지 색: bounce/send_failure/unsubscribe=red, rejected=orange, reply_positive=green, reply_neutral=blue, auto=gray
- ⑤ 수동 입력 폼: recipient_email / outcome(10종) / reason / next_action(6종) / resend_not_before(resend_later 선택 시 노출). source='manual'로 저장
- 수동 입력 시 enrollment 동기화 (핸드오프 규칙): bounce_hard·send_failure·suppress → active를 'failed', rejected_*·unsubscribe_request → 'cancelled'(+cancelled_at)

### 워커 확장 (NDR 파서)
- 판별: From postmaster/mailer-daemon, 제목 Undeliverable / Delivery Status Notification / 전송 실패 / 배달 실패 / 반송, report-type=delivery-status, DSN 필드
- 파싱: Final-Recipient → RCPT TO → 5xx/4xx 라인 인접 `<email>` → 코드 라인 위의 bare 주소 (Planet A식 `550 5.2.1 addr:` 커버)
- hard(5.x.x/55x) → outcome 'bounce_hard', next_action 'suppress', 해당 주소의 active enrollment 전부 'failed'
- soft(4.x.x/4xx) → outcome 'bounce_soft', next_action 'resend_later', resend_not_before = now+3일. **기존 blocklist 억제 대상 아님** (기존 detectBounce는 5xx 전용이라 soft 로깅을 위해 별도 모듈로 구현, blocklist 경로는 그대로 둠)
- 중복 방지: 동일 lower(recipient_email) + evidence_ref(=인바운드 Message-ID) 존재 시 skip
- 삽입 위치: `autoSuppress()` 안, `detectSuppressions` 호출 **앞** (soft는 suppression signal이 없어 뒤에 두면 early-return에 걸림)
- 주의: `EMAIL_AUTO_SUPPRESS=false`면 autoSuppress 전체가 꺼지므로 outcome 자동 기록도 함께 꺼짐

---

## PART B — 가정 및 사전 확인 (중요)

1. **컬럼명 가정.** `migration_20260714090000_email_send_outcomes.sql`이 아직 repo에 push되어 있지 않아 원문을 못 읽었음. 코드는 핸드오프 기술 기준으로 다음 컬럼을 가정:
   `id, organization_id, party_id, recipient_email, outcome, reason, next_action, resend_not_before, source, evidence_ref, created_at`
   → `migration_20260714120000_..._page_access.sql`의 **VERIFY 1** 결과와 대조. 이름이 다르면 `src/lib/actions/email-outcomes.ts` + `src/lib/email/outcome-recorder.ts`에서 해당 이름만 치환.
2. **오늘 아침 파일 커밋.** `migration_20260714090000`, `20260714100000_record_send_outcomes_batch1`, `20260714110000_outcome_lookup_snippets`가 clone 기준 repo에 없음. Downloads에 남아 있으면 universal mover가 sql/로 옮기니 이번 커밋에 같이 포함시킬 것.
3. **RLS.** 원 마이그레이션에 페이지용(authenticated) 정책이 있는지 불명 → page_access 마이그레이션이 idempotent하게 보장 (drop policy if exists 후 재생성, 워커는 service_role이라 무관).
4. 페이지는 최근 500건만 로드 (요약도 그 범위). 사이드바/탭 링크는 추가하지 않음 — URL 직접 접근 (`/mailing/outcomes`). 원하면 다음 세션에서 mailing-tabs-client에 3번째 탭 추가.

---

## PART C — 실행 순서

```powershell
# 0) 두 머신 사용 - pull 먼저!
cd C:\dev\mbg-project
git pull --rebase origin marinebiogroup

# 1) universal mover (migration_/patch_/handoff_ 프리픽스 자동 라우팅)
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1

# 2) 소스 파일 mover (아래 인라인 블록 붙여넣기)

# 3) mailcarrier.ts 패치
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\patches\patch_mailcarrier_ndr_outcome.ps1

# 4) 검증
npx vitest run src/__tests__/email/ndr-outcome.test.ts
$env:NODE_OPTIONS='--max-old-space-size=6144'
npx tsc --noEmit
```

**Supabase SQL Editor**: `sql/migration_20260714120000_email_send_outcomes_page_access.sql` 실행 → VERIFY 1(컬럼명)·VERIFY 2(오늘 5건) 확인.

### 소스 파일 인라인 mover (2번, 그대로 붙여넣기)

```powershell
$repo = 'C:\dev\mbg-project'
$dl = "$env:USERPROFILE\Downloads"
$map = @(
  @{ g='mailing_outcomes_page*.tsx';   d='src\app\(app)\mailing\outcomes'; n='page.tsx' },
  @{ g='mailing_outcomes_client*.tsx'; d='src\app\(app)\mailing\outcomes'; n='outcomes-client.tsx' },
  @{ g='ndr-outcome.test*.ts';         d='src\__tests__\email';            n='ndr-outcome.test.ts' },
  @{ g='ndr-outcome*.ts';              d='src\lib\email';                  n='ndr-outcome.ts' },
  @{ g='outcome-recorder*.ts';         d='src\lib\email';                  n='outcome-recorder.ts' },
  @{ g='email-outcomes*.ts';           d='src\lib\actions';                n='email-outcomes.ts' },
  @{ g='email-outcome*.ts';            d='src\types';                      n='email-outcome.ts' }
)
foreach ($m in $map) {
  $src = Get-ChildItem -Path (Join-Path $dl $m.g) -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if (-not $src) { Write-Host ("MISSING  " + $m.g); continue }
  Unblock-File -LiteralPath $src.FullName
  $destDir = Join-Path $repo $m.d
  [System.IO.Directory]::CreateDirectory($destDir) | Out-Null
  [System.IO.File]::Copy($src.FullName, (Join-Path $destDir $m.n), $true)
  Remove-Item -LiteralPath $src.FullName
  Write-Host ("MOVED    " + $m.g + " -> " + $m.d + "\" + $m.n)
}
```

주의: 맵 순서 유지 (test → ndr-outcome, email-outcomes → email-outcome 순으로 처리해야 글롭 충돌 없음. 각 파일은 복사 후 Downloads에서 제거됨).

---

## PART D — Finish

```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/ docs/handoff/ tools/patches/ src/
git commit -m "feat: /mailing/outcomes dashboard + MailCarrier NDR outcome recorder (hard/soft)"
git push origin marinebiogroup   # push = urm.marinebiogroup.com 자동 배포
```

**완료 기준**: 배포 후 `urm.marinebiogroup.com/mailing/outcomes`에서
- 요약 카드에 bounce_hard 2 / rejected_other 1 / rejected_sector 1 / rejected_stage 1
- 액션 보드에 Planet A·Eclipse (switch_contact)
- 재접근 대기에 Extantia (2027-01-15, D-{n})
가 표시되면 성공.

## PART E — 다음 세션 후보

1. Brightfuture 회신(7/14 06:07) 본문 확인 → 새 폼으로 outcome 분류 (미결 #1)
2. mailing 탭 3번째 "Outcomes" 탭 or 사이드바 링크
3. NDR 워커 실전 로그 관찰 후 파서 패턴 보강 (특히 O365/Google NDR 변형)
4. 7/20 Seed 발송 전 do-not-send 가드 교차 점검 (미결 #2)
