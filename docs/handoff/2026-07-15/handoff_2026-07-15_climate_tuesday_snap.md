# Handoff — 2026-07-15 (3) G3 적용 완료 / 드리프트 **확인** / 화요일 09:00 스냅

`handoff_2026-07-15_sequence_status_guard.md`의 후속. 커밋 `a100c9a`로 G3는 배포·적용·검증 완료.

> ## 이번 세션의 결론
> **① [G3] 적용됨** — `has_g3 = true`, 오늘 기준 순수 no-op(무회귀), 앞으로의 일시정지/아카이브만 실효화.
> **② 7/20 드리프트 가설 = 확인됨.** 측정값 `2026-07-20 Mon 15:27 PT`. **7/20에 0통 나간다.**
> **③ 대기 중**: `fix_20260715020000_climate_snap_next_send_to_tuesday_9am.sql` — 프리뷰 후 적용.
> **④ 이전 핸드오프 A-4 타임라인에 오류** — "68건 한 트랜잭션"은 틀렸다. PART C.

---

## PART A — [G3] 검증 완료 (전부 실측)

| 항목 | 기대 | 실측 | |
|---|---|---|---|
| P0 enum | `draft/active/paused/archived` | 동일 | ✅ |
| P1 시퀀스 status별 active enrollment | Climate만 | `active / Climate / **67**` | ✅ |
| P2 G3가 침묵시키는 것 | 0행 | **0행** (P1에 비-active 시퀀스 없음) | ✅ 순수 no-op |
| 함수 가드 | `has_g3 = true` | `true` | ✅ |
| 헬스 뷰 | 합 == P1, `sequence_inactive` == P2 | `ok 62 + do_not_send_party 5 = **67**`, `sequence_inactive` **0** | ✅ 불변식 2개 다 성립 |

**무회귀 확정.** 이전 핸드오프의 "Climate 62 active"는 **`ok`가 62**라는 뜻이었다. 실제 active enrollment는 **67** = 40(step 2) + 27(step 3)이고, 그중 5건이 `do_not_send_party`로 막혀 실발송 62. 앞 문서의 "7/20 40통 / 7/27 22통"과 정확히 맞는다 (`27 - 5 = 22`).

---

## PART B — 드리프트 **확인**. 가설이 아니라 측정이다

### B-1. 판정

```
sequence_name                          next_step_order   n    earliest_pt          latest_pt
Climate Investor Cold Outreach -- FCC        2          40   2026-07-20 Mon 15:27  2026-07-20 Mon 15:56
Climate Investor Cold Outreach -- FCC        3          27   2026-07-27 Mon 14:06  2026-07-27 Mon 14:06
```

판정 규칙은 `Tue 09:00` → 폐기 / `Mon 14:06` → 확인이었다. 나온 값은 **`Mon 15:27`** — **확인**이다. 두 그룹 다 **월요일 오후**, 허용 창(평일 09:00–10:00 PT) 밖.

### B-2. `quiet-hours.ts`에 실측값을 넣고 돌린 결과

| 그룹 | 예정 | 실제 | 지연 |
|---|---|---|---|
| step 2 (40) | 7/20 Mon 15:27 | **7/27 Mon 09:00 PT** | +6일 |
| step 3 (27) | 7/27 Mon 14:06 | **8/3 Mon 09:00 PT** | +6일 |

경로 (양쪽 동일):
```
Mon 15:27 blocked(quiet)   -> Tue 15:57   (오후엔 now +1일 +30분)
Tue 15:57 -> Wed 16:27 -> Thu 16:57 -> Fri 17:27 -> Sat 17:57
Sat 17:57 blocked(weekend) -> Mon 02:00   (weekend 분기는 09:00 **UTC** = 02:00 PT 절대값)
Mon 02:00 -> +30분씩 (오전엔 +1일이 없음) -> Mon 09:00 PT -> 발송
```

**→ 7/20에 0통.** 사고가 아니라 **조용한 일주일 슬립 + 잘못된 요일**. 손실은 없다. 안 고쳐도 결국 나가긴 한다.

### B-3. 왜 이렇게 됐나 — "화요일"은 스키마 어디에도 없다

`quiet_hours`는 **시각과 주말만** 안다. 요일 개념이 없다.
"화요일 9시"는 **일회성 `UPDATE` 3개의 잔상**이었다:
- `20260713150000` **Part 2** — 사고를 낸 그 문장
- `20260713160000` / `180000` / `190000` — 각각 `next_send_at = next Tuesday 09:00 PT`를 **명시로 INSERT**

첫 발송 직후 `advance_enrollment`가 앵커를 `enrolled_at + day_offset`으로 되돌리면서 정렬이 풀렸다. `enrolled_at`이 **월요일 오후**라서 이후 모든 스텝이 월요일 오후에 떨어진다.

---

## PART C — ⚠️ 이전 핸드오프 A-4 타임라인 정정

> A-4는 이렇게 적혀 있다:
> *"7/13 21:06:34 | 시퀀스·스텝·**68건 등록 생성. 한 트랜잭션** — `enrolled_at`이 마이크로초까지 동일"*
> *"7/14 16:01:19~16:02:41 | **나머지 40건** step 1 발송"*
> *"**잔여 1건 미해명**: 68 = 27(step2) + 41(step1)로 딱 맞지 않는다"*

**틀렸다. 한 트랜잭션이 아니라 코호트가 둘이다.** `next_send_at`이 `enrolled_at + offset`이라 마이크로초로 역산된다:

| 코호트 | `enrolled_at` (UTC) | 출처 | 건수 | 지금 |
|---|---|---|---|---|
| **A** | `07-13 21:06:34.112619` | `20260713140000` create+enroll | **28** | step 3 대기 27 (`+14d` = `07-27 21:06:34.112619` ✓) |
| **B** | `07-13 22:27:21.117647` ~ `22:56` | `160000`/`180000`/`190000` | **40** | step 2 대기 40 (`+7d` = `07-20 22:27:21.117647` ✓) |

**산술이 닫힌다: 68 = 28 + 40.** 그리고 미해명이 풀린다:

- step 1 = **68** = 28(7/13 21:07, 코호트 A) + 40(7/14 09:01 PT, 코호트 B)
- **코호트 B의 7/14 step 1은 사고가 아니라 "예정대로"다.** 자기 스크립트가 `next Tuesday 09:00 PT`를 박아뒀고 정확히 그때 나갔다. Part 2와 무관
- step 2 = **27** = 28 − 1(Planet A). **"41" 같은 숫자는 없었다** — 두 코호트를 한 덩어리로 본 데서 나온 착시
- 현재 active 67 = 40(B) + 27(A) → Planet A는 코호트 A 28건 중 비활성 1건

**사고의 근본 원인 결론은 그대로 유효하다.** Part 2가 무조건 덮어써서 7/20을 기다리던 **코호트 A**를 7/14로 당겼고, 그래서 27곳이 19시간 간격 2통을 받았다. 바뀌는 건 **코호트 B(40건)는 이 사고와 무관**하다는 것뿐이다.

**확인 쿼리** (비활성 포함 — Planet A를 잡기 위해):
```sql
SELECT to_char(e.enrolled_at, 'MM-DD HH24:MI:SS.US') AS enrolled_at_utc,
       e.status::text AS enrollment_status,
       e.next_step_order,
       count(*) AS n
FROM app.email_sequence_enrollments e
JOIN app.email_sequences s ON s.id = e.sequence_id
WHERE s.name = 'Climate Investor Cold Outreach -- FCC'
GROUP BY 1, 2, 3
ORDER BY 1, 3;
```
→ 기대: `21:06:34.112619` 계열 28건, `22:27:21.117647`~`22:56` 계열 40건.

---

## PART D — 수정: 화요일 09:00 PT 스냅

`fix_20260715020000_climate_snap_next_send_to_tuesday_9am.sql`

각 행의 `next_send_at` **이상**인 **첫 화요일 09:00 PT**로 스냅. 구조상 앞으로만 간다.

### D-1. 프리뷰 — **필수. 단독 실행.**

```sql
WITH tgt AS (
  SELECT e.id, e.next_send_at,
         ( (e.next_send_at AT TIME ZONE 'America/Los_Angeles')::date
           + ( ( 2 - EXTRACT(ISODOW FROM (e.next_send_at AT TIME ZONE 'America/Los_Angeles')::date)::int ) + 7 ) % 7
         ) AS tue_date
  FROM app.email_sequence_enrollments e
  JOIN app.email_sequences s ON s.id = e.sequence_id
  WHERE s.name          = 'Climate Investor Cold Outreach -- FCC'
    AND e.status        = 'active'::app.enrollment_status
    AND e.next_send_at IS NOT NULL
), snapped AS (
  SELECT t.id,
         CASE WHEN ((t.tue_date::text || ' 09:00')::timestamp AT TIME ZONE 'America/Los_Angeles') >= t.next_send_at
              THEN ((t.tue_date::text || ' 09:00')::timestamp AT TIME ZONE 'America/Los_Angeles')
              ELSE (((t.tue_date + 7)::text || ' 09:00')::timestamp AT TIME ZONE 'America/Los_Angeles')
         END AS snap_at
  FROM tgt t
)
SELECT e.next_step_order,
       count(*) AS rows_touched,
       to_char(min(e.next_send_at AT TIME ZONE 'America/Los_Angeles'), 'MM-DD Dy HH24:MI') AS before_earliest,
       to_char(max(e.next_send_at AT TIME ZONE 'America/Los_Angeles'), 'MM-DD Dy HH24:MI') AS before_latest,
       to_char(min(sn.snap_at      AT TIME ZONE 'America/Los_Angeles'), 'MM-DD Dy HH24:MI') AS after_earliest,
       to_char(max(sn.snap_at      AT TIME ZONE 'America/Los_Angeles'), 'MM-DD Dy HH24:MI') AS after_latest,
       bool_and(sn.snap_at > e.next_send_at) AS all_forward,
       round((min(EXTRACT(EPOCH FROM (sn.snap_at - ls.last_at))) / 86400.0)::numeric, 2) AS min_gap_days
FROM app.email_sequence_enrollments e
JOIN snapped sn ON sn.id = e.id
LEFT JOIN LATERAL (
  SELECT max(c.occurred_at) AS last_at
  FROM app.communications c
  WHERE c.party_id                 = e.party_id
    AND c.channel::text            = 'email'
    AND c.direction::text          = 'outbound'
    AND c.external_data->>'source' = 'sequence'
) ls ON TRUE
GROUP BY 1
ORDER BY 1;
```

기대 (로컬 PG 16에 실측값을 심고 실행한 결과와 동일해야 함):

| step | rows | before | after | all_forward | min_gap_days |
|---|---|---|---|---|---|
| 2 | 40 | 07-20 Mon 15:27 | **07-21 Tue 09:00** | `t` | **7.00** |
| 3 | 27 | 07-27 Mon 14:06 | **07-28 Tue 09:00** | `t` | **14.00** |

**판정 규칙 — 하나라도 어긋나면 적용 금지:**
- `all_forward` = **`t`** (하나라도 `f`면 뒤로 당기는 행이 있다는 뜻 = Part 2 재현)
- `min_gap_days` **>= 7** ← **Part 2가 파괴한 바로 그 숫자.** 19시간 = `0.79`였다

### D-2. 적용 → 검증

파일 통째로 SQL Editor에 붙여넣고 실행. → `UPDATE 67` 기대.

```sql
SELECT e.next_step_order,
       count(*) AS n,
       to_char(e.next_send_at AT TIME ZONE 'America/Los_Angeles', 'YYYY-MM-DD Dy HH24:MI') AS pt,
       bool_and(EXTRACT(ISODOW FROM (e.next_send_at AT TIME ZONE 'America/Los_Angeles')) = 2) AS is_tuesday,
       bool_and(EXTRACT(HOUR  FROM (e.next_send_at AT TIME ZONE 'America/Los_Angeles')) = 9) AS in_window
FROM app.email_sequence_enrollments e
JOIN app.email_sequences s ON s.id = e.sequence_id
WHERE s.name   = 'Climate Investor Cold Outreach -- FCC'
  AND e.status = 'active'::app.enrollment_status
GROUP BY 1, 3
ORDER BY 1;
```
→ `is_tuesday = t`, `in_window = t`, step 2 = 40 @ `07-21 Tue 09:00`, step 3 = 27 @ `07-28 Tue 09:00`.

**멱등**: 다시 실행하면 `UPDATE 0`.

### D-3. 검증 방식 (이번엔 코드 추론이 아니라 실행)

컨테이너에 **PostgreSQL 16을 띄워 실측값을 심고 파일을 그대로 돌렸다:**

- 스냅 산술 8케이스: 실측 2 + 엣지 6 (`Tue 08:59` → 당일 / `Tue 09:00` → 이동 없음 / `Tue 09:01` → 다음 주 / `Sun 23:00` / **PDT→PST 전환**(11월 → `17:00 UTC`로 정확히 이동)) — 전부 통과
- 40 + 27건을 심고 파일 실행 → 67행 전부 `Tue 09:00 PT`, `updated_at` 스탬프 확인
- 재실행 → `UPDATE 0` (멱등 확인)
- 프리뷰 쿼리도 같은 DB에서 실행 → `all_forward = t`, `min_gap_days` 7.00 / 14.00

### D-4. **왜 한 번이면 되나** — 매주 반복 작업이 아니다

`migration_20260715001000`(앵커 수정)이 이미 이렇게 바꿔놨다:

```sql
next_send_at = GREATEST(enrolled_at + next_offset, now() + gap)
```

Climate의 gap은 **전부 정확히 7일**. 한 스텝이 화요일 09:0x 창 안에 들어가면 `now() + 7d`는 **같은 요일 같은 시각**이고, 낡은 `enrolled_at + offset`(월요일 오후)보다 **항상 늦다** → `GREATEST`가 계속 정렬된 쪽을 고른다.

```
코호트 B  step 2 Tue 07-21 -> step 3 Tue 07-28 -> step 4 Tue 08-04
코호트 A  step 3 Tue 07-28 -> step 4 Tue 08-04
```

**앵커 수정은 "사고 원인이 아니라 견고성 개선"이라고 분류됐었다. 두 판단 다 맞았고, 덤으로 이 일회성 스냅을 영구적으로 만들어 준다.** 7/28과 8/4엔 두 코호트가 같은 날 나간다(62통). party가 서로 달라 G1은 안 잡는다.

### D-5. 안 고치면?

7/20에 0통 → 40통은 7/27(월) 09:00, 27통은 8/3(월) 09:00에 나간다. **메일이 사라지진 않는다.** 일주일 늦고 요일이 틀릴 뿐. 스냅은 선택이지 응급이 아니다 — 다만 **7/20 15:27 PT 전에** 넣어야 드리프트가 시작되지 않는다.

---

## PART E — 컨벤션 추가분

- **가설을 세웠으면 판정 규칙을 먼저 쓸 것.** "`Tue 09:00`이면 폐기 / `Mon 14:06`이면 확인"을 미리 적어둬서 결과가 나왔을 때 해석 여지가 없었다. 이번엔 가설이 **맞았지만**, 그건 규칙을 미리 적은 것과 무관하다
- **재현 가능하면 로컬 PG에 심어서 돌릴 것.** `apt-get install postgresql-16` → 실측값 심기 → 파일 그대로 실행. DST·멱등·엣지를 추론이 아니라 실행으로 확인했다. 스키마 mock은 몇 줄이면 된다
- **마이크로초는 지문이다.** `next_send_at = enrolled_at + offset`이라 `.112619` / `.117647`로 코호트가 갈렸다. 핸드오프의 "한 트랜잭션" 주장을 이걸로 반증했다
- **"N건이 X했다"를 한 덩어리로 쓰지 말 것.** A-4의 "68건 한 트랜잭션"이 없는 미스터리("잔여 1건")를 만들어냈다. 코호트를 나누자 산술이 닫혔다
- **벌크 리스케줄엔 gap 프리뷰를 붙일 것.** 행수·전후 시각이 아니라 **직전 실발송으로부터의 gap**이 판정 숫자다. Part 2는 그걸 0.79일로 만들었다
- **`ok` 개수와 active enrollment 개수는 다른 숫자다.** "Climate 62 active"는 실은 67 active / 62 ok였다. 헬스 뷰를 인용할 땐 어느 쪽인지 쓸 것

---

## 파일 이동

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

인라인 폴백:

```powershell
$dl = "$env:USERPROFILE\Downloads"
$map = @(
  @{ glob = 'fix_20260715020000_climate_snap_next_send_to_tuesday_9am*.sql'; dest = 'C:\dev\mbg-project\sql'; name = 'fix_20260715020000_climate_snap_next_send_to_tuesday_9am.sql' },
  @{ glob = 'handoff_2026-07-15_climate_tuesday_snap*.md';                   dest = 'C:\dev\mbg-project\docs\handoff\2026-07-15'; name = 'handoff_2026-07-15_climate_tuesday_snap.md' }
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

> 지난번처럼 mover가 `(1).md` 중복본을 먼저 집어갈 수 있다. **Downloads를 먼저 비울 것.**

## Finish

```powershell
cd C:\dev\mbg-project
git pull --rebase origin marinebiogroup
git status -sb
git add sql/ docs/
git commit -m "sql: snap Climate next_send_at forward to Tuesday 09:00 PT (quiet-hours drift); docs: 2026-07-15 handoff (3) + A-4 cohort correction"
git push origin marinebiogroup
```

푸시 = 웹 자동 배포. **sql/docs만이라 앱 코드 영향 없음** — DB 반영은 SQL Editor 실행이 정본이다.

---

## 다음 세션 킥오프 (복붙)

```
mbg-project 이어가자. docs/handoff/2026-07-15/handoff_2026-07-15_climate_tuesday_snap.md 기준.
(이전: handoff_2026-07-15_session.md -> handoff_2026-07-15_sequence_status_guard.md -> 이 문서)

완료:
- [G3] 시퀀스 status 가드 적용·검증 (커밋 a100c9a). has_g3=true, 오늘 기준 무회귀(P2 0행).
  이제 UI 일시정지/아카이브가 실제로 발송을 멈춘다. 단 영구 정지는 여전히 enrollment cancel이 정본.
- 헬스 뷰 실측: active 67 = ok 62 + do_not_send_party 5. (= step2 40 + step3 27)

확인된 것 (가설 -> 측정으로 확정):
- next_send_at 실측 = step2 40건 @ 07-20 Mon 15:27~15:56 PT / step3 27건 @ 07-27 Mon 14:06 PT
- quiet_hours 허용 창은 평일 09:00-10:00 PT뿐 -> 둘 다 창 밖 -> 7/20에 0통.
  드리프트 시뮬(quiet-hours.ts에 실측값 투입): 40통은 7/27 Mon 09:00, 27통은 8/3 Mon 09:00.
  "화요일"은 스키마 어디에도 없다. 일회성 UPDATE(20260713150000 Part 2 + 160000/180000/190000)의 잔상이었고
  advance_enrollment가 앵커를 enrolled_at(월 오후)으로 되돌리며 정렬이 풀렸다.

이전 핸드오프 A-4 정정: "68건 한 트랜잭션"은 틀렸다. 코호트 2개다.
  A: enrolled 07-13 21:06:34.112619 (28건, create 스크립트) -> Part 2가 당김 -> 27곳 19시간 2통 = 사고
  B: enrolled 07-13 22:27:21.117647~22:56 (40건, 160000/180000/190000) -> 7/14 step 1은 예정대로. 사고와 무관
  68 = 28 + 40. "잔여 1건 미해명(41)"은 두 코호트를 한 덩어리로 본 착시였다. 근본 원인 결론은 그대로 유효.
  Planet A는 코호트 A 28건 중 step 2 미수신 1건으로 여전히 미해명.

대기: fix_20260715020000_climate_snap_next_send_to_tuesday_9am.sql (프리뷰 -> 적용 -> 검증)
  각 행의 next_send_at 이상인 첫 화요일 09:00 PT로 스냅. 구조상 forward-only + GREATEST + WHERE snap>current.
  판정: all_forward=t AND min_gap_days>=7 (Part 2는 이 값을 0.79로 만들었다). 아니면 적용 금지.
  기대: step2 40 -> Tue 07-21 09:00 (gap 7d) / step3 27 -> Tue 07-28 09:00 (gap 14d). 멱등(재실행 UPDATE 0).
  로컬 PG 16에 실측값 심고 파일 그대로 실행해 검증 완료 (DST/엣지/멱등 포함).
  한 번이면 영구: 앵커 수정의 GREATEST(enrolled+offset, now()+gap)가 gap=7d라 화요일 정렬을 계속 유지한다.
  안 고쳐도 메일은 안 사라진다 - 일주일 늦고 월요일에 나갈 뿐. 단 7/20 15:27 PT 전에 넣어야 드리프트가 안 시작된다.

미결 (이전 PART E 승계):
1. 스냅 적용 후 7/21 09:00 PT 발송 관찰 (40통). 헬스 뷰로 실측
2. FCC Climate Tech day_offset 0,0 (휴면이지만 지뢰)
3. IP 49.254.118.167 Trend Micro delisting + SPF/DKIM/DMARC
4. 타임존: 09:00 PT가 유럽 18:00 / 도쿄 01:00. app.parties에 country 없음(42703) -> 백필 선행. 백로그
5. src/types/phase21b.ts:4 SequenceStatus에 'draft' 누락 (DB enum 4개). 런타임 영향 없음
6. E-3 quiet-hours 무방비 쓰기 = 우선순위 하향(실동작 버그 아님, 이미 GREATEST와 동치)
7. 시퀀스 이름 중복 / World Fund 8/4 재개 감시 / Lowercarbon 이중 노출 / tsc 15건
```
