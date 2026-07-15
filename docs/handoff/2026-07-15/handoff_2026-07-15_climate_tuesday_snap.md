# Handoff — 2026-07-15 (3) G3 적용 / 화요일 09:00 스냅 적용 / A-4 종결

`handoff_2026-07-15_sequence_status_guard.md`의 후속이자 **이 세션의 정본**.
커밋 `a100c9a`(G3) → `6d8d8fd`(스냅) → `fed8f5a` → `0944553` → **이 문서(rev3, 통째 교체)**.

> ## 상태: 전부 적용·검증 완료. **미해명 0건.**
> **① [G3] 시퀀스 status 가드** — `has_g3 = true`, 무회귀(P2 0행) 확인.
> **② 화요일 09:00 PT 스냅** — 적용·검증됨. **step 2 = 40건 @ 7/21 화 09:00 PT**, step 3 = 27건 @ 7/28 화 09:00 PT.
> **③ 7/20 드리프트** — 가설 → 측정으로 **확인** → 스냅으로 해소. 7/20은 발송일이 아니다.
> **④ A-4 "68건 한 트랜잭션" — 종결.** 코호트 4개로 산술이 닫혔다.
> **⑤ A-4 "잔여 1건 미해명"(Planet A) — 종결.** 자동화가 생기기 **18시간 전에 사람이 손으로** 은퇴시켰다. **조치 자체는 옳았다.** PART C-2.

---

## PART A — [G3] 검증 (실측)

| 항목 | 실측 | |
|---|---|---|
| P0 enum | `draft/active/paused/archived` | ✅ |
| P1 시퀀스 status별 active enrollment | `active / Climate / **67**` (비-active 시퀀스 0) | ✅ |
| P2 G3가 침묵시키는 것 | **0행** | ✅ 순수 no-op |
| 함수 가드 | `has_g3 = true` | ✅ |
| 헬스 뷰 | `ok 62 + do_not_send_party 5 = **67**`, `sequence_inactive` **0** | ✅ 불변식 2개 성립 |

이전 문서의 "Climate 62 active"는 **`ok`가 62**라는 뜻이었다. 실제 active는 **67** = 40(step 2) + 27(step 3), 그중 5건이 `do_not_send_party` → 실발송 62. "7/27 22통"과 맞는다 (`27 − 5 = 22`).

**남는 효과**: UI 일시정지/아카이브가 이제 실제로 발송을 멈춘다. **단 영구 정지는 여전히 enrollment cancel이 정본** — status만 되돌리면 밀린 물량이 한꺼번에 나간다.

---

## PART B — 드리프트: 확인 → 해소

### B-1. 측정 (판정 규칙을 미리 적어뒀었다)

```
next_step_order   n    earliest_pt            latest_pt
      2          40   2026-07-20 Mon 15:27   2026-07-20 Mon 15:56
      3          27   2026-07-27 Mon 14:06   2026-07-27 Mon 14:06
```

규칙은 `Tue 09:00` → 폐기 / `Mon 14:06` → 확인이었고, 나온 값은 **`Mon 15:27`** = **확인**.

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

## PART C — A-4 종결

### C-1. "68건 한 트랜잭션" — 틀렸다. 코호트가 4개다.

`enrolled_at` 실측 (비활성 포함):

| `enrolled_at` (UTC) | status | step | n | 출처 |
|---|---|---|---|---|
| `07-13 21:06:34.112619` | **failed** | 2 | **1** | `20260713140000` create+enroll |
| `07-13 21:06:34.112619` | active | 3 | **27** | 〃 |
| `07-13 22:27:21.117647` | active | 2 | **13** | `20260713160000` |
| `07-13 22:54:14.174079` | active | 2 | **5** | `20260713180000` |
| `07-13 22:56:17.308063` | active | 2 | **22** | `20260713190000` |

`next_send_at = enrolled_at + offset`이라 **마이크로초가 지문 노릇**을 했다.

- **코호트 A** = 28 (`21:06:34.112619`) → Part 2가 7/20 → 7/14로 당김 → **27곳이 19시간 간격 2통 = 사고**
- **코호트 B** = 13 + 5 + 22 = **40** (`22:27~22:56`) → 자기 스크립트가 `next Tuesday 09:00 PT`를 박아둠 → **7/14 step 1은 예정대로.** Part 2와 무관
- **68 = 28 + 40.** step 1 = 28(7/13 21:07) + 40(7/14 09:01 PT) = **68** ✓ / step 2 = **27** = 28 − 1(Planet A) ✓

**"68 = 27 + 41이 안 맞는다"는 두 코호트를 한 덩어리로 본 착시였다.** 근본 원인 결론(Part 2의 무조건 `next_send_at` 덮어쓰기)은 그대로 유효.

### C-2. Planet A — **종결. 사람이 손으로 은퇴시켰다.**

> **정정 이력**: `fed8f5a`는 *"`20260714100000` PART 3a가 했다"*고 단언했다 → **틀렸다**(`updated_at`이 7/13, contact 조인 null). `0944553`은 미해명으로 되돌렸다. **이 rev3가 종결한다.**

**확정된 사실** (전부 실측):

| 항목 | 값 |
|---|---|
| `party_name` | Planet A Ventures |
| `contact_id` | **null** |
| `recipient_email` / `party_email` | `startups@planet-a.com` |
| `status` / `next_step_order` | `failed` / **2** |
| `updated_at` (마지막 쓰기) | **`07-13 22:27:00.788780`** |
| sends 로그 | **`step 1, sent, 07-13 21:07:44.884274` 한 줄뿐** |

**타임라인** (UTC. git 시각은 CDT −0500이라 환산):

| UTC | 사건 | 근거 |
|---|---|---|
| `07-13 21:06:34.112619` | 코호트 A 28건 등록 | `enrolled_at` |
| `07-13 21:07:22` | 커밋 `da9f35d` — climate 시퀀스 스크립트 | git |
| `07-13 21:07:42` | **NDR 도착** — `<startups@planet-a.com>` 배달 불가 | `communications` |
| `07-13 21:07:44.884274` | Planet A step 1 `sent` 기록 | `email_sequence_sends` |
| **`07-13 22:27:00.788780`** | **Planet A enrollment → `failed`** ← **리포 밖** | `updated_at` |
| `07-13 22:27:21.117647` | 코호트 B 13건 등록 (`20260713160000` 실행) | `enrolled_at` |
| `07-13 22:28:25` | 커밋 `80110a5` — 그 enroll_more 스크립트를 담음 | git |
| `07-14 16:32` | `outcome-recorder.ts` / `email-outcomes.ts` **최초 등장** (`c9da241`) | git |
| `07-14 17:06` | `20260714100000_record_send_outcomes_batch1` **최초 등장** (`9b5c99c`) | git |

> NDR의 `occurred_at`(21:07:42)이 `sent_at`(21:07:44.88)보다 2초 빠른 건 **메일 자체의 Date 헤더 vs 우리 로그 기록 시각**의 차이다. 발송 즉시 반송됐다는 뜻.

**소거로 확정한 것 — `git`이 답을 줬다:**

1. **사건 직전 커밋(`80110a5`) 트리를 통째로 grep** → `email_sequence_enrollments`를 건드리면서 `failed`를 쓰는 코드가 **없다.** 걸린 건 `sequence-processor.ts`(→ `advance_enrollment`만 호출, 그건 enrollment status를 안 건드린다)와 `database.ts`(타입 정의)뿐
2. **자동 경로 3개는 전부 사건 뒤에 태어났다** — `git log --diff-filter=A` 기준 **18시간 이상 뒤**
3. `contact_id`가 **null**이라, 나중에 생긴 그 경로들은 (`.in('contact_id', ...)` 매칭) **앞으로도 이 행을 절대 못 잡는다**

**→ 7/13 22:27:00에 리포 안의 어떤 코드도 이 행을 쓸 수 없었다. 쓰기는 리포 밖에서 왔다 = 수동.**

**유력 경로: Supabase SQL Editor 세션.** 근거는 21초 간격과 반복된 지문:

```
21:06:34 SQL 실행 -> 21:07:22 커밋   (48초)
22:27:21 SQL 실행 -> 22:28:25 커밋   (64초)
22:27:00 은퇴      = 22:27:21 실행보다 21초 앞  -> 같은 에디터 세션 안
```

`contact_id`가 null인 행을 잡으려면 party나 `recipient_email`로 매칭해야 하는데, **그게 바로 나중에 커밋된 코드들이 못 하는 방식**이다. 손으로 쓴 문장의 서명이다.

**그리고 그 조치는 옳았다.** `startups@planet-a.com`은 하드 바운스(`550 inactive`)였고, D-1이 하루 뒤 **같은 일을 체계화**했다(죽은 주소 11개). 자동화가 없던 시점에 사람이 정확히 옳은 일을 손으로 한 것 — **버그가 아니라 공백이었다.**

**정확한 문장은 복구 불가** (에디터 히스토리에만 존재). 궁금하면 Supabase SQL Editor 스니펫 히스토리의 `07-13 22:27` 근처를 보면 된다. **선택 사항 — 결론은 소거로 이미 닫혔다.**

**A-4 산술 결론과도 정합**: `next_step_order = 2`(`advance_enrollment`는 실패해도 무조건 `+1`) → step 2는 시도조차 안 됐고, 7/14 16:00에 `active`가 아니라 후보가 아니었다 → **28이 아니라 27** ✓

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

> **프리뷰의 `all_forward = false`는 정상이다.** 프리뷰가 적용 **후에** 실행돼(`before == after`) 움직일 행이 없다는 뜻 — **멱등성 서명**이지 실패가 아니다. `all_forward = t` 규칙은 **사전 게이트**용이었다. 최종 상태는 D-1로 독립 검증됐다.

### D-2. **한 번으로 끝난다** — 매주 반복 아님

`migration_20260715001000`(앵커 수정)이 이미 (아래는 **표현식 발췌** — 실행용 아님):

```
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

컨테이너에 PostgreSQL 16을 띄워 실측값을 심고 파일을 그대로 실행했다 — 스냅 산술 8케이스(실측 2 + 엣지 6: `Tue 08:59`→당일 / `Tue 09:00`→이동 없음 / `Tue 09:01`→다음 주 / `Sun 23:00` / **PDT→PST**(11월 → `17:00 UTC`)), 67건 실행 후 전부 `Tue 09:00 PT`, 재실행 `UPDATE 0`.

---

## PART E — 다음 발송

**7/21(화) 09:00 PT = 16:00 UTC, Climate step 2, 40통.** 워커 자동 실행(60초 폴링).

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

- **⚠️ `git grep`은 HEAD가 아니라 사건 시점의 커밋에.** Planet A를 세 번 틀린 근본 원인은 이것 하나였다 — **7/15의 트리를 뒤지며 7/13에 일어난 일의 범인을 찾고 있었다.** 범인 후보 3개는 사건 **18시간 뒤에 태어났다.** 도구:
  - `git grep <pattern> <commit> -- <paths>` — 그 시점에 코드가 **존재했는지**
  - `git log --diff-filter=A -- <file>` — 파일의 **생일**
  - `git log --since=... --until=... --date=format:'%m-%d %H:%M %z'` — **타임존 주의.** 커밋은 CDT(−0500), DB는 UTC. 5시간을 안 더하면 타임라인이 통째로 어긋난다
- **"코드의 부재"가 "코드"보다 강한 증거일 때가 있다.** 코드를 읽어 인과를 세우면 틀렸고(7전 7패), *그 시점에 아무도 이걸 쓸 수 없었다*를 증명하자 답이 한 개로 좁혀졌다. **소거는 추론보다 세다**
- **`updated_at`은 알리바이다.** "7/14 파일이 했다"를 `updated_at = 07-13`이 한 줄로 무너뜨렸다. 인과를 적기 전에 **마지막 쓰기 시각**부터 볼 것
- **리포 밖 쓰기를 후보에서 빼지 말 것.** 정답은 SQL Editor의 손으로 쓴 문장이었다. 리포는 실행된 것의 **부분집합**이다. 실행→60~90초 뒤 커밋이라는 지문이 이 프로젝트엔 반복된다
- **가설엔 판정 규칙을 먼저 쓸 것.** 드리프트는 "`Tue 09:00`이면 폐기 / `Mon 14:06`이면 확인"을 미리 적어둬 해석 여지가 없었다. **먼저 측정한 가설은 맞았고, 코드 읽고 세운 가설은 틀렸다.** 이 세션도 같은 패턴
- **grep할 때 캐스트를 가정하지 말 것.** 첫 grep이 `'failed'::app.enrollment_status`를 가정해 `SET status = 'failed'`를 놓칠 뻔했다. **테이블명 AND 값**으로 넓게 훑고 눈으로 거를 것
- **재현 가능하면 로컬 PG에 심어서 돌릴 것.** `apt-get install postgresql-16` → 실측값 심기 → 파일 그대로 실행. DST·멱등·엣지를 실행으로 확인했다
- **마이크로초는 지문이다.** `.112619`/`.117647`/`.174079`/`.308063`로 코호트 4개가 갈렸다
- **"N건이 X했다"를 한 덩어리로 쓰지 말 것.** "68건 한 트랜잭션"이 없는 미스터리를 만들었다
- **벌크 리스케줄엔 gap 프리뷰를.** 행수·전후 시각이 아니라 **직전 실발송으로부터의 gap**이 판정 숫자다
- **프리뷰는 사전 게이트다.** 적용 후에 돌리면 `all_forward = false`(멱등성 서명)만 나온다
- **`ok` 개수 ≠ active enrollment 개수.** "Climate 62 active"는 실은 67 active / 62 ok였다
- **손으로 쓴 타입 유니온을 믿지 말 것 — `src/types/phase21b.ts`는 2개 중 2개가 틀렸다.**
  `:4 SequenceStatus` → `'draft'` 누락 / `:5 EnrollmentStatus` → `'failed'` 누락.
  정본은 생성된 `src/types/database.ts`(`:6999`, `:7017`). 런타임 영향 없음
- **파일 교체(`M`)는 `git pull --rebase`를 mover보다 먼저.** mover가 추적 중인 파일을 고치면 unstaged가 되어 rebase pull이 거부된다. 신규(`??`)만 다룰 땐 안 걸려서 이번에 처음 드러났다
- **```` ```sql ```` 펜스엔 실행 가능한 statement만.** 인용문의 `WHERE ...`를 실행해 `42601: syntax error at or near ".."`가 났다. 생략 부호도, 표현식 조각(`next_send_at = GREATEST(...)`)도 넣지 말 것 — 일반 펜스로 내리고 "발췌"라고 쓸 것. 검사법: 모든 sql 펜스를 `pglast.parse_sql()`에 통과시킬 것

---

## 파일 이동

```powershell
cd C:\dev\mbg-project
git pull --rebase origin marinebiogroup
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

> **기존 문서를 통째로 덮어쓴다.** Downloads를 먼저 비울 것.

## Finish

```powershell
git status -sb
git add docs/
git commit -m "docs: 2026-07-15 handoff (3) rev3 -- close Planet A by elimination (no failed-writer existed in the tree on 07-13; the three candidates were born 18h later). Manual SQL Editor retirement after a hard bounce -- correct action, predating the automation"
git push origin marinebiogroup
```

`M docs/handoff/2026-07-15/handoff_2026-07-15_climate_tuesday_snap.md` 하나만 떠야 정상. **docs만이라 앱·DB 영향 없음.**

---

## 다음 세션 킥오프 (복붙)

```
mbg-project 이어가자. docs/handoff/2026-07-15/handoff_2026-07-15_climate_tuesday_snap.md 기준.
(이전: handoff_2026-07-15_session.md -> handoff_2026-07-15_sequence_status_guard.md -> 이 문서)

상태: DB/리포/문서 정합. 7/15 세션 작업 전부 적용·검증 완료. 미해명 0건.
- [G3] 시퀀스 status 가드 (a100c9a). has_g3=true, P2 0행 = 무회귀.
  UI 일시정지/아카이브가 이제 실제로 멈춘다. 영구 정지는 여전히 enrollment cancel이 정본.
- 화요일 09:00 PT 스냅 (6d8d8fd) 적용·검증:
  step 2 = 40건 @ 2026-07-21 Tue 09:00 PT / step 3 = 27건 @ 2026-07-28 Tue 09:00 PT
  is_tuesday=true, in_window=true, min_gap_days 7.00 / 14.00.
  한 번으로 끝 - 앵커 수정의 GREATEST(enrolled+offset, now()+gap)가 gap=7d라 화요일 정렬을 유지.
- 헬스 뷰 실측: active 67 = ok 62 + do_not_send_party 5 (= step2 40 + step3 27, 27-5=22)

다음 발송: 7/21(화) 09:00 PT = 16:00 UTC, Climate step 2, 40통. 워커 자동(60초 폴링).
  가드 5겹 통과 확인됨. 발송 후 헬스 뷰로 실측할 것.
  이후 7/28에 62통(A step3 22 + B step3 40), 8/4에 62통. 7/20은 발송일 아님.

A-4 완전 종결:
- "68건 한 트랜잭션"은 틀렸다. 코호트 4개. enrolled_at 마이크로초가 지문:
  A 21:06:34.112619 = 28건 (create) -> Part 2가 당김 -> 27곳 19시간 2통 = 사고
  B 22:27:21.117647 / 22:54:14.174079 / 22:56:17.308063 = 13+5+22 = 40건 (160000/180000/190000)
    -> 7/14 step 1은 예정대로, 사고와 무관. 68 = 28 + 40. step2 = 27 = 28 - 1(Planet A).
  근본 원인 결론(Part 2의 무조건 next_send_at 덮어쓰기)은 그대로 유효.
- "잔여 1건"(Planet A) 종결: 07-13 21:07:42 NDR(startups@planet-a.com 배달불가) ->
  07-13 22:27:00.788780 에 사람이 SQL Editor 에서 손으로 enrollment 를 failed 은퇴.
  git 으로 소거 확정: 사건 직전 커밋(80110a5) 트리에 enrollment 를 failed 로 쓰는 코드가 없었고,
  후보 3개(outcome-recorder.ts / email-outcomes.ts / 20260714100000)는 전부 18시간 뒤에 태어났다.
  contact_id 가 null 이라 그 경로들은 앞으로도 이 행을 못 잡는다.
  조치 자체는 옳았다 - 하드바운스였고 D-1 이 하루 뒤 같은 일을 체계화했다. 버그가 아니라 공백이었다.

핵심 교훈 (이번 세션): git grep 은 HEAD 가 아니라 사건 시점 커밋에. 커밋 시각은 CDT(-0500), DB 는 UTC.
  코드 읽고 세운 인과는 또 틀렸고(7전 7패), 먼저 측정한 것과 소거로 좁힌 것만 맞았다.

미결:
1. 7/21 09:00 PT 발송 관찰 (40통) -> 헬스 뷰로 실측
2. FCC Climate Tech day_offset 0,0 (휴면이지만 지뢰)
3. IP 49.254.118.167 Trend Micro delisting + SPF/DKIM/DMARC
4. 타임존: 09:00 PT가 유럽 18:00 / 도쿄 01:00. app.parties에 country 없음(42703) -> 백필 선행. 백로그
5. src/types/phase21b.ts 유니온 2개 오류 (SequenceStatus 'draft', EnrollmentStatus 'failed' 누락)
6. E-3 quiet-hours 무방비 쓰기 = 우선순위 하향 (실동작 버그 아님, 이미 GREATEST와 동치)
7. 시퀀스 이름 중복 / World Fund 8/4 재개 감시 / Lowercarbon 이중 노출 / tsc 15건 5파일
```
