# =====================================================================
# patch_handoff_20260715_correct_root_cause.ps1
#
# Corrects docs/handoff/2026-07-15/handoff_2026-07-15_session.md, committed
# in d64ea33 with a WRONG root cause.
#
# What was wrong
#   PART A-4 claimed the duplicate sends that cost us an investor were caused
#   by advance_enrollment anchoring next_send_at on enrolled_at, and cited the
#   Climate 19-hour case as evidence. That is false.
#
#   The real cause, found by reading sql/20260713150000_climate_sequence_tuesday_9am_pt.sql:
#     Part 2 does an UNCONDITIONAL bulk reschedule --
#       UPDATE app.email_sequence_enrollments SET next_send_at = v_next_send
#        WHERE sequence_id = v_seq_id AND status = 'active' AND next_send_at IS NOT NULL
#     -- with no GREATEST. It dragged 28 enrollments that had already advanced
#     to step 2 (due 07-20) BACK to 07-14 09:00 PT. They fired 19 hours after
#     step 1.
#
#   The anchor fix (migration_20260715001000) is still a real robustness
#   improvement and stays applied -- it just was not this incident.
#
#   quiet_hours {start 10:00, end 09:00} is NOT inverted either. The 09:00-10:00
#   PT window is deliberate -- see the same migration, "Tuesday 9am PT window".
#   The blocked-window semantics were already documented in
#   docs/handoff/HANDOFF-2026-06-29-mailing-sequence-session.md line 70.
#
# Leaving a wrong root cause in a committed handoff is worse than leaving a
# gap -- the next session will believe it.
#
# Idempotent: guarded on a marker. ASCII output only.
# =====================================================================

$ErrorActionPreference = 'Stop'
$f = 'C:\dev\mbg-project\docs\handoff\2026-07-15\handoff_2026-07-15_session.md'

if (-not (Test-Path $f)) { throw "NOT FOUND: $f" }

$t = [System.IO.File]::ReadAllText($f).Replace("`r`n", "`n")

if ($t -match 'A-4\. 중복 발송 근본 원인 — 벌크 리스케줄') {
  Write-Output 'SKIP: handoff already corrected'
  exit 0
}

# ---- [1] header figures: 104 -> 97 -----------------------------------
$old = @'
> ## 7/20 발송: **104통** — 리스크 전부 닫힘
> Climate 40 + Seed 64. 가드·중복차단·거절차단 모두 적용·검증 완료.
'@.Replace("`r`n", "`n")
$new = @'
> ## 7/20 발송: **97통** — 리스크 전부 닫힘
> Climate 40 + Seed 57 (7/27 Climate 22). 가드·중복차단·거절차단·바운스차단 모두 적용·검증 완료.
> 헬스 뷰 실측: **ok 119 / do_not_send_party 8 / do_not_send_email 7**.
'@.Replace("`r`n", "`n")
if ($t -notlike "*$old*") { throw 'ANCHOR 1 not found' }
$t = $t.Replace($old, $new)

# ---- [2] A-4: replace the wrong root cause ---------------------------
$old = @'
### A-4. 중복 발송 근본 원인 — `advance_enrollment` 앵커

```sql
-- 이전
next_send_at = v_enrolled_at + (v_next_day_offset || ' days')::INTERVAL
```

**`enrolled_at` 기준. 직전 발송이 아니라.** `day_offset`이 "메일 간 간격"이 아니라 **등록 시점에 고정된 절대 캘린더**. step N이 늦으면 step N+1은 이미 due → 다음 실행에서 즉시 발송.
'@.Replace("`r`n", "`n")
$new = @'
### A-4. 중복 발송 근본 원인 — **벌크 리스케줄의 무조건 덮어쓰기** (정정됨)

> **정정 이력**: 이 문서의 최초판(커밋 `d64ea33`)은 원인을 `advance_enrollment` 앵커라고 적었다. **틀렸다.** 진짜 원인은 아래다. 앵커 수정(`migration_20260715001000`)은 그 자체로 옳은 견고성 개선이고 적용 상태를 유지하지만, **이번 사고의 원인이 아니다.**

`sql/20260713150000_climate_sequence_tuesday_9am_pt.sql` **Part 2**:

```sql
-- Part 2: Move all pending sends to the next Tuesday 09:00 PT.
UPDATE app.email_sequence_enrollments e
   SET next_send_at = v_next_send,      -- 다음 화요일 09:00 PT
       updated_at   = now()
 WHERE e.sequence_id = v_seq_id
   AND e.status = 'active'
   AND e.next_send_at IS NOT NULL;
```

**`GREATEST`가 없다. 무조건 덮어쓴다.** 이미 step 2로 넘어가 7/20을 기다리던 enrollment까지 **6일 앞으로 끌어당겼다.**

타임라인 (모든 관측치와 일치):

| 시각 | 사건 |
|---|---|
| 7/13 21:06:34 (월 14:06 PT) | 시퀀스·스텝·68건 등록 생성 (한 트랜잭션, `enrolled_at` 마이크로초까지 동일). 전부 즉시 due |
| 7/13 21:07:12~21:08:08 | 워커 실행 — **이 시점엔 `quiet_hours`가 아직 없음.** step 1을 28건 발송 → advance → `next_send_at = enrolled+7 = **7/20**` |
| 7/13 21:08 이후 | **마이그레이션 적용.** Part 1이 `quiet_hours` 설정. **Part 2가 전 active enrollment의 `next_send_at`을 `7/14 09:00 PT = 16:00 UTC`로 덮어씀** — 7/20을 기다리던 28건 포함 |
| 7/14 16:00:19 (화 09:00 PT) | 27건 step 2 발송 ← **step 1로부터 19시간. 여기서 투자자를 잃었다** |
| 7/14 16:01:19~16:02:41 | 나머지 40건 step 1 발송 |

이후 값도 전부 맞는다: step 2 그룹 → `enrolled+14 = 7/27` ✓, step 1 그룹 → `enrolled+7 = 7/20` ✓.

**잔여 1건 미해명**: Planet A Ventures는 7/13 21:07:44에 step 1을 받았는데(28건 중 하나) 7/14에 step 2를 안 받았다. 68 = 27(step2) + 41(step1)로 딱 맞지 않는다. 사고 결론은 안 바뀌지만 기록해 둔다.

### A-4b. 참고 — `advance_enrollment` 앵커 수정 (사고 원인 아님, 견고성 개선)

```sql
-- 이전
next_send_at = v_enrolled_at + (v_next_day_offset || ' days')::INTERVAL
```

`day_offset`이 "메일 간 간격"이 아니라 **등록 시점에 고정된 절대 캘린더**. step N이 늦으면 step N+1이 그 지연을 안 기다린다.
'@.Replace("`r`n", "`n")
if ($t -notlike "*$old*") { throw 'ANCHOR 2 not found' }
$t = $t.Replace($old, $new)

# ---- [3] "왜 2겹" line ------------------------------------------------
$old = '**왜 2겹**: A-4는 *알려진* 원인을 없애고, A-5는 원인이 무엇이든 결과를 불가능하게 만든다.'
$new = @'
**왜 2겹**: A-4b는 *한* 경로를 고치고, A-5는 원인이 무엇이든 결과를 불가능하게 만든다. **A-4의 진짜 원인은 A-4b가 아니라 벌크 리스케줄이었고, 그걸 막은 건 G1이다.** 이번 세션의 판단 중 유일하게 처음부터 옳았던 것 — 원인을 모를 때도 초크포인트에서 결과를 막는다.
'@.Replace("`r`n", "`n")
if ($t -notlike "*$old*") { throw 'ANCHOR 3 not found' }
$t = $t.Replace($old, $new)

# ---- [4] B-2: add the newly refuted hypotheses ------------------------
$old = '| "원본 `15 min`과 `(copy)`가 명단 중복" | 이번 세션 | **겹치지 않음.** climate/deeptech vs life science 섹터 분리 |'
$new = @'
| "원본 `15 min`과 `(copy)`가 명단 중복" | 이번 세션 | **겹치지 않음.** climate/deeptech vs life science 섹터 분리 |
| "`advance_enrollment` 앵커가 근본 원인" | 이번 세션 | 벌크 리스케줄 Part 2였음. `enrolled_at` 동일 |
| "`day_offset`을 나중에 편집했다" | 이번 세션 | 스텝 `created_at = updated_at`, 수정 이력 없음 |
| "`quiet_hours` {10:00,09:00}가 뒤집혔다" | 이번 세션 | **의도된 화요일 9시 창.** 규칙은 6/29 핸드오프 L70에 이미 문서화돼 있었음 |
'@.Replace("`r`n", "`n")
if ($t -notlike "*$old*") { throw 'ANCHOR 4 not found' }
$t = $t.Replace($old, $new)

# ---- [5] C-1: solved --------------------------------------------------
$oldStart = '### C-1. ⚠️ Climate 27건이 step 2를 **6일 일찍** 받았다'
$oldEnd   = 'step 2의 `updated_at`이 7/14 16:0x 근처면 확정. **G1이 결과를 막고 있어 급하진 않지만 미해명으로 두면 안 된다.**'
$i = $t.IndexOf($oldStart)
$j = $t.IndexOf($oldEnd)
if ($i -lt 0 -or $j -lt 0) { throw 'ANCHOR 5 not found' }
$block = $t.Substring($i, ($j + $oldEnd.Length) - $i)
$new = @'
### C-1. ✅ Climate 27건 step 2 조기 발송 — **해결됨. PART A-4 참조.**

`sql/20260713150000_climate_sequence_tuesday_9am_pt.sql` Part 2의 무조건 `UPDATE ... SET next_send_at = v_next_send`가 원인. 잔여 미해명은 Planet A 1건뿐.
'@.Replace("`r`n", "`n")
$t = $t.Replace($block, $new)

# ---- [6] D-1 applied --------------------------------------------------
$old = '### D-1. 하드 바운스 기록 — `fix_20260715003000_record_hard_bounces.sql` (**미적용**)'
$new = @'
### D-1. 하드 바운스 기록 — `fix_20260715003000_record_hard_bounces.sql` (**✅ 적용됨**)

> 결과: 죽은 주소 **11개** 기록(13건 중 Chevron/`test@test.com` 제외). 헬스 뷰 `ok 126 → 119`, `do_not_send_email 0 → 7` — **활성 enrollment 7건이 죽은 주소를 향하고 있었다.** Seed 7/20 배치가 64 → 57로 감소.
'@.Replace("`r`n", "`n")
if ($t -notlike "*$old*") { throw 'ANCHOR 6 not found' }
$t = $t.Replace($old, $new)

# ---- [7] PART F: add the lesson ---------------------------------------
$old = '- **차단 범위를 사유에 맞출 것**'
$new = @'
- **`next_send_at`은 앞으로만 밀 수 있다.** 이 컬럼을 쓰는 모든 코드는 `GREATEST(next_send_at, new_value)`여야 한다. 무조건 덮어쓰는 곳이 둘 있었다 — `20260713150000` Part 2(**사고 원인**)와 `sequence-processor.ts`의 quiet-hours 분기(`.update({next_send_at: nextAt})`, 비교 없음, `updated_at`도 안 찍어 원장에 안 남음). 후자는 미수정
- **벌크 리스케줄은 재앙 반경이 크다.** 한 문장이 68건의 일정을 6일 당겼다. `WHERE`에 "아직 안 나간 것만" 조건이 있어야 했다
- **핸드오프에 틀린 근본 원인을 남기지 말 것.** 공백보다 나쁘다 — 다음 세션이 믿는다. 확정 못 했으면 미해명으로 적을 것
- **차단 범위를 사유에 맞출 것**
'@.Replace("`r`n", "`n")
if ($t -notlike "*$old*") { throw 'ANCHOR 7 not found' }
$t = $t.Replace($old, $new)

# ---- [8] kickoff ------------------------------------------------------
$old = '상태: 7/20 발송 104통 (Climate 40 + Seed 64). 리스크 전부 닫힘.'
$new = @'
상태: 7/20 발송 97통 (Climate 40 + Seed 57), 7/27 Climate 22. 헬스 ok 119/party 8/email 7.
'@.Replace("`r`n", "`n").TrimEnd("`n")
if ($t -notlike "*$old*") { throw 'ANCHOR 8 not found' }
$t = $t.Replace($old, $new)

[System.IO.File]::WriteAllText($f, $t, (New-Object System.Text.UTF8Encoding($true)))
Write-Output 'PATCHED: docs\handoff\2026-07-15\handoff_2026-07-15_session.md'
Write-Output '  - A-4 root cause corrected (bulk reschedule, not the anchor)'
Write-Output '  - C-1 marked solved'
Write-Output '  - figures 104 -> 97, ok 119 / party 8 / email 7'
Write-Output '  - D-1 marked applied'
Write-Output '  - 3 more refuted hypotheses + 3 conventions recorded'
