# Handoff — 2026-07-15 (3) G3 적용 / 화요일 09:00 스냅 적용 / A-4 완전 종결

`handoff_2026-07-15_sequence_status_guard.md`의 후속이자 **이 세션의 정본**.
커밋 `a100c9a`(G3) → `6d8d8fd`(스냅) → 이 문서(정정본, 통째 교체).

> ## 상태: **전부 적용·검증 완료. 미해명 0건.**
> **① [G3] 시퀀스 status 가드** — `has_g3 = true`, 무회귀(P2 0행) 확인.
> **② 화요일 09:00 PT 스냅** — 적용됨. **step 2 = 40건 @ 7/21 화 09:00 PT**, step 3 = 27건 @ 7/28 화 09:00 PT.
> **③ 7/20 드리프트** — 가설 → 측정으로 확인 → 스냅으로 해소. 7/20은 이제 발송일이 아니다.
> **④ 이전 핸드오프 A-4의 "68건 한 트랜잭션"과 "잔여 1건 미해명" — 둘 다 종결.** PART C.

---

## PART A — [G3] 검증 (실측)

| 항목 | 실측 | |
|---|---|---|
| P0 enum | `draft/active/paused/archived` | ✅ |
| P1 시퀀스 status별 active enrollment | `active / Climate / **67**` (비-active 시퀀스 0) | ✅ |
| P2 G3가 침묵시키는 것 | **0행** | ✅ 순수 no-op |
| 함수 가드 | `has_g3 = true` | ✅ |
| 헬스 뷰 | `ok 62 + do_not_send_party 5 = **67**`, `sequence_inactive` **0** | ✅ 불변식 2개 성립 |

**무회귀 확정.** 이전 문서의 "Climate 62 active"는 **`ok`가 62**라는 뜻이었다. 실제 active는 **67** = 40(step 2) + 27(step 3), 그중 5건이 `do_not_send_party` → 실발송 62. "7/27 22통"과 정확히 맞는다 (`27 − 5 = 22`).

**남는 효과**: 앞으로 UI 일시정지/아카이브가 실제로 발송을 멈춘다. **단 영구 정지는 여전히 enrollment cancel이 정본** — status만 되돌리면 밀린 물량이 한꺼번에 나간다.

---

## PART B — 드리프트: 확인 → 해소

### B-1. 측정 (판정 규칙은 미리 적어뒀었다)

```
next_step_order   n    earliest_pt            latest_pt
      2          40   2026-07-20 Mon 15:27   2026-07-20 Mon 15:56
      3          27   2026-07-27 Mon 14:06   2026-07-27 Mon 14:06
```

규칙은 `Tue 09:00` → 폐기 / `Mon 14:06` → 확인이었고, 나온 값은 **`Mon 15:27`** = **확인**. 허용 창(평일 09:00–10:00 PT) 밖.

### B-2. 안 고쳤다면

`quiet-hours.ts`에 실측값을 넣고 돌린 결과 — **7/20에 0통**, 40통은 7/27(월) 09:00, 27통은 8/3(월) 09:00. 각 +6일, 잘못된 요일.

```
Mon 15:27 blocked(quiet)   -> Tue 15:57   (오후엔 now +1일 +30분)
... 하루 +30분씩 ... -> Sat
Sat       blocked(weekend) -> Mon 02:00   (weekend 분기는 09:00 **UTC** = 02:00 PT 절대값)
Mon 02:00 -> +30분씩 (오전엔 +1일 없음)   -> Mon 09:00 PT -> 발송
```

### B-3. 원인 — "화요일"은 스키마 어디에도 없었다

`quiet_hours`는 **시각과 주말만** 안다. 요일 개념이 없다. "화요일 9시"는 **일회성 `UPDATE` 4개의 잔상**이었다 — `20260713150000` Part 2(사고를 낸 그 문장) + `160000`/`180000`/`190000`(각각 `next_send_at = next Tuesday 09:00 PT`를 명시 INSERT). 첫 발송 직후 `advance_enrollment`가 앵커를 `enrolled_at + day_offset`(= **월요일 오후**)으로 되돌리며 정렬이 풀렸다.

---

## PART C — A-4 정정 및 **완전 종결**

> A-4 원문:
> *"7/13 21:06:34 | **68건 등록 생성. 한 트랜잭션** — `enrolled_at`이 마이크로초까지 동일"*
> *"**잔여 1건 미해명**: Planet A는 step 1을 받았는데 7/14에 step 2를 안 받았다. 68 = 27 + 41로 딱 맞지 않는다"*

**둘 다 틀렸다.** `enrolled_at` 실측 (비활성 포함):

| `enrolled_at` (UTC) | status | step | n | 출처 |
|---|---|---|---|---|
| `07-13 21:06:34.112619` | **failed** | 2 | **1** | `20260713140000` create+enroll |
| `07-13 21:06:34.112619` | active | 3 | **27** | 〃 |
| `07-13 22:27:21.117647` | active | 2 | **13** | `20260713160000` |
| `07-13 22:54:14.174079` | active | 2 | **5** | `20260713180000` |
| `07-13 22:56:17.308063` | active | 2 | **22** | `20260713190000` |

**한 트랜잭션이 아니라 코호트가 4개다** (A 1개 + B 3개). `next_send_at = enrolled_at + offset`이라 마이크로초가 지문 노릇을 했다.

- **코호트 A** = 28 (`21:06:34.112619`) → Part 2가 7/20 → 7/14로 당김 → **27곳이 19시간 간격 2통 = 사고**
- **코호트 B** = 13 + 5 + 22 = **40** (`22:27~22:56`) → 자기 스크립트가 `next Tuesday 09:00 PT`를 박아둠 → **7/14 step 1은 예정대로.** Part 2와 무관
- **68 = 28 + 40.** step 1 = 28(7/13 21:07) + 40(7/14 09:01 PT) = **68** ✓ / step 2 = **27** ✓

### C-1. "잔여 1건" = Planet A — **미해명이 아니라 정상 동작이었다**

`sql/20260714100000_record_send_outcomes_batch1.sql` **PART 3a**가 이름을 직접 박아놨다:

```sql
-- 3a. bounced addresses -> 'failed'
UPDATE app.email_sequence_enrollments e
SET status = 'failed'::app.enrollment_status, updated_at = now()
FROM app.contacts c
WHERE c.id = e.contact_id
  AND e.status = 'active'::app.enrollment_status
  AND lower(c.email) IN ('startups@planet-a.com', 'admin@eclipse.capital')
```

`startups@planet-a.com`은 하드 바운스(`550 inactive`, D-1 죽은 주소 11개 중 하나). **7/14 10:00에 이 파일이 enrollment를 `failed`로 은퇴시켰고, 16:00 워커의 `get_due_enrollments`는 `status = 'active'`만 집으므로 애초에 후보가 아니었다.** 그래서 28이 아니라 27이 나갔다.

**"step 2를 안 받았다"가 아니라 "6시간 전에 정상적으로 제외됐다".** 실측이 이를 확증한다 — 그 1건은 `failed` / `next_step_order = 2`로 멈춰 있다. `advance_enrollment`는 실패해도 `next_step_order`를 **무조건 +1** 하므로(그리고 enrollment status를 건드리지 않는다 — `p_status`는 `email_sequence_sends`에만 들어간다), **step 2가 시도조차 되지 않았다는 증거다.**

**A-4의 미해명 0건. 이 사고는 전부 설명됐다.**

---

## PART D — 스냅: 적용 완료

`fix_20260715020000_climate_snap_next_send_to_tuesday_9am.sql` (커밋 `6d8d8fd`)

### D-1. 검증 결과 (실측)

```
next_step_order   n    pt                      is_tuesday   in_window
      2          40   2026-07-21 Tue 09:00      true         true
      3          27   2026-07-28 Tue 09:00      true         true
```

**67건 전부 화요일 09:00 PT 허용 창 안.** `min_gap_days` = **7.00 / 14.00** — 의도한 케이던스 그대로이고, Part 2가 `0.79`(19시간)로 파괴했던 바로 그 숫자다.

> **프리뷰의 `all_forward = false`는 정상이다.** 프리뷰가 적용 **후에** 실행돼(`before == after == Tue 09:00`) 움직일 행이 없다는 뜻 — **멱등성 서명**이지 실패가 아니다. `all_forward = t` 규칙은 **사전 게이트**용이었다. 최종 상태는 D-1로 독립 검증됐으므로 결과에 문제 없음.

### D-2. **한 번으로 끝난다** — 매주 반복 아님

`migration_20260715001000`(앵커 수정)이 이미:

```sql
next_send_at = GREATEST(enrolled_at + next_offset, now() + gap)
```

Climate의 gap은 **전부 정확히 7일**. 화요일 09:0x 창 안에서 발송되면 `now() + 7d`는 **같은 요일 같은 시각**이고, 낡은 `enrolled_at + offset`(월요일 오후)보다 **항상 늦다** → `GREATEST`가 계속 정렬된 쪽을 고른다.

```
코호트 B  step 2 Tue 07-21 -> step 3 Tue 07-28 -> step 4 Tue 08-04
코호트 A                      step 3 Tue 07-28 -> step 4 Tue 08-04
```

7/28·8/4엔 두 코호트가 같은 날 나간다(62통). party가 서로 달라 G1은 안 잡는다.

**앵커 수정은 "사고 원인이 아니라 견고성 개선"으로 분류됐었다. 두 판단 다 맞았고, 덤으로 이 일회성 스냅을 영구적으로 만들어 준다.**

### D-3. 검증 방식

컨테이너에 PostgreSQL 16을 띄워 실측값을 심고 파일을 그대로 실행했다 — 스냅 산술 8케이스(실측 2 + 엣지 6: `Tue 08:59`→당일 / `Tue 09:00`→이동 없음 / `Tue 09:01`→다음 주 / `Sun 23:00` / **PDT→PST**(11월 → `17:00 UTC`)), 67건 실행 후 전부 `Tue 09:00 PT`, 재실행 `UPDATE 0`. **추론이 아니라 실행으로 확인.**

---

## PART E — 다음 발송

**7/21(화) 09:00 PT = 16:00 UTC, Climate step 2, 40통.** 워커 자동 실행(60초 폴링).

가드 5겹 전부 통과 확인:

| 가드 | 상태 |
|---|---|
| do-not-send (party/주소) | 40건 다 `ok` (막힌 5건은 step 3 그룹) |
| [G1] 48h min-gap | 직전 발송 7/14 → **7일** |
| [G2] party당 1건 | 40 distinct party |
| [G3] 시퀀스 status | Climate = `active` |
| quiet_hours | 09:00 PT = 창 **안** (`in_window = true`) |

발송 후 헬스 뷰로 실측할 것.

---

## PART F — 컨벤션 추가분

- **가설엔 판정 규칙을 먼저 쓸 것.** "`Tue 09:00`이면 폐기 / `Mon 14:06`이면 확인"을 미리 적어둬 해석 여지가 없었다
- **재현 가능하면 로컬 PG에 심어서 돌릴 것.** `apt-get install postgresql-16` → 실측값 심기 → 파일 그대로 실행. DST·멱등·엣지를 실행으로 확인했다. mock 스키마는 몇 줄이면 된다
- **마이크로초는 지문이다.** `.112619` / `.117647` / `.174079` / `.308063`로 코호트 4개가 갈렸고 "한 트랜잭션" 주장이 반증됐다
- **"N건이 X했다"를 한 덩어리로 쓰지 말 것.** "68건 한 트랜잭션"이 없는 미스터리("잔여 1건")를 만들었다. 코호트를 나누자 산술이 닫혔다
- **미해명을 적기 전에 `sql/`을 grep할 것.** Planet A의 답은 하루 전 파일에 **주소가 문자열로 박힌 채** 있었다(`20260714100000` PART 3a). 코드를 읽어 추론하기 전에 "누가 이 컬럼에 이 값을 쓰나"를 먼저 검색할 것
- **벌크 리스케줄엔 gap 프리뷰를 붙일 것.** 행수·전후 시각이 아니라 **직전 실발송으로부터의 gap**이 판정 숫자다
- **프리뷰는 사전 게이트다.** 적용 후에 돌리면 `all_forward = false`(멱등성 서명)만 나오고 게이트 역할은 못 한다
- **`ok` 개수 ≠ active enrollment 개수.** "Climate 62 active"는 실은 67 active / 62 ok였다. 헬스 뷰 인용 시 어느 쪽인지 명시
- **손으로 쓴 타입 유니온을 믿지 말 것 — `src/types/phase21b.ts`는 2개 중 2개가 틀렸다.**
  - `:4  SequenceStatus`   → `'draft'` 누락 (DB enum 4개)
  - `:5  EnrollmentStatus` → `'failed'` 누락 (DB enum 5개: active/completed/cancelled/**failed**/paused)
  정본은 생성된 `src/types/database.ts`(`:6999`, `:7017`). 런타임 영향 없음(UI가 그 값을 안 씀)

---

## 파일 이동

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

인라인 폴백:

```powershell
$dl = "$env:USERPROFILE\Downloads"
$map = @(
  @{ glob = 'handoff_2026-07-15_climate_tuesday_snap*.md'; dest = 'C:\dev\mbg-project\docs\handoff\2026-07-15'; name = 'handoff_2026-07-15_climate_tuesday_snap.md' }
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

> **이 파일은 기존 문서를 통째로 덮어쓴다** (한국어 .md는 패치하지 않는 컨벤션). Downloads를 먼저 비울 것 — `(1).md` 중복본을 mover가 먼저 집는다.

## Finish

```powershell
cd C:\dev\mbg-project
git pull --rebase origin marinebiogroup
git status -sb
git add docs/
git commit -m "docs: 2026-07-15 handoff (3) final -- snap applied and verified, A-4 closed (Planet A retired by 20260714100000 PART 3a)"
git push origin marinebiogroup
```

`git status -sb`에 `M docs/handoff/2026-07-15/handoff_2026-07-15_climate_tuesday_snap.md` 하나만 떠야 정상. 푸시 = 웹 자동 배포지만 **docs만이라 앱 영향 없음.**

---

## 다음 세션 킥오프 (복붙)

```
mbg-project 이어가자. docs/handoff/2026-07-15/handoff_2026-07-15_climate_tuesday_snap.md 기준.
(이전: handoff_2026-07-15_session.md -> handoff_2026-07-15_sequence_status_guard.md -> 이 문서)

상태: 2026-07-15 세션은 전부 적용·검증 완료. 미해명 0건.
- [G3] 시퀀스 status 가드 (커밋 a100c9a). has_g3=true, P2 0행 = 무회귀.
  UI 일시정지/아카이브가 이제 실제로 멈춘다. 영구 정지는 여전히 enrollment cancel이 정본.
- 화요일 09:00 PT 스냅 (커밋 6d8d8fd) 적용·검증:
  step 2 = 40건 @ 2026-07-21 Tue 09:00 PT / step 3 = 27건 @ 2026-07-28 Tue 09:00 PT
  is_tuesday=true, in_window=true, min_gap_days 7.00 / 14.00.
  한 번으로 끝 - 앵커 수정의 GREATEST(enrolled+offset, now()+gap)가 gap=7d라 화요일 정렬을 계속 유지.
- 헬스 뷰 실측: active 67 = ok 62 + do_not_send_party 5 (= step2 40 + step3 27, 27-5=22)

다음 발송: 7/21(화) 09:00 PT = 16:00 UTC, Climate step 2, 40통. 워커 자동(60초 폴링).
  가드 5겹 통과 확인됨 (do-not-send / G1 7일 / G2 40 distinct / G3 active / quiet_hours 창 안).
  발송 후 헬스 뷰로 실측할 것. 이후 7/28에 62통(코호트 A step3 22 + B step3 40), 8/4에 62통.
  7/20은 발송일이 아니다 (드리프트 해소됨).

A-4 완전 종결 (이전 핸드오프 정정):
- "68건 한 트랜잭션"은 틀렸다. 코호트 4개. enrolled_at 마이크로초가 지문:
  A 21:06:34.112619 = 28건 (create) -> Part 2가 당김 -> 27곳 19시간 2통 = 사고
  B 22:27:21.117647 / 22:54:14.174079 / 22:56:17.308063 = 13+5+22 = 40건 (160000/180000/190000)
    -> 7/14 step 1은 예정대로. 사고와 무관. 68 = 28 + 40
- "잔여 1건 미해명"(Planet A) = 미해명 아님. sql/20260714100000_record_send_outcomes_batch1.sql
  PART 3a가 7/14 10:00에 startups@planet-a.com 하드바운스로 enrollment를 failed 은퇴시켰고,
  16:00 워커는 active만 집으므로 후보가 아니었다. 그래서 28이 아닌 27. 정상 동작이었다.
- 근본 원인 결론(Part 2의 무조건 next_send_at 덮어쓰기)은 그대로 유효.

미결:
1. 7/21 09:00 PT 발송 관찰 (40통) -> 헬스 뷰로 실측
2. FCC Climate Tech day_offset 0,0 (휴면이지만 지뢰)
3. IP 49.254.118.167 Trend Micro delisting + SPF/DKIM/DMARC
4. 타임존: 09:00 PT가 유럽 18:00 / 도쿄 01:00. app.parties에 country 없음(42703) -> 백필 선행. 백로그
5. src/types/phase21b.ts 유니온 2개 오류 (SequenceStatus 'draft', EnrollmentStatus 'failed' 누락).
   런타임 영향 없음. 정본은 생성된 src/types/database.ts
6. E-3 quiet-hours 무방비 쓰기 = 우선순위 하향 (실동작 버그 아님, 이미 GREATEST와 동치)
7. 시퀀스 이름 중복 / World Fund 8/4 재개 감시 / Lowercarbon 이중 노출 / tsc 15건 5파일
```
